pragma Singleton
// VALKYX STATE — single reactive source of truth.
// Compositor state from Hyprland event socket (no polling).
// Hardware values encapsulated; UI never shells out directly.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
    id: state

    // ==================== SHELL UI ====================
    property bool panelLeftOpen: false
    property bool panelOpen: false          // right sidebar (ActionCenter)
    onPanelLeftOpenChanged: {
        if (panelLeftOpen) { monitorScan.running = true; netBandGet.running = true; clipScan.running = true; weatherScan.running = true }
    }
    // panelOpen/panelLeftOpen are deliberately NOT persisted: they are transient UI
    // state, and restoring them re-opened the Action Center on every boot.
    property bool settingsOpen: false
    property int settingsPage: 0
    property bool launcherOpen: false
      property bool powerOpen: false          // floating power menu (on-screen popup)
      // Masked password prompt (WiFi join). Transient by design: never persisted,
      // and `passwordTarget` is a tmpfs path the waiting script polls.
      property bool passwordOpen: false
      property string passwordTarget: ""
      property string passwordLabel: ""
      property string passwordText: ""
    property bool wallpaperOpen: false      // Super+W wallpaper/media selector
    property color accent: "#00A86B"        // persisted; shell.qml propagates to ValkyxTheme
    property string themeName: "Valkyx"      // persisted; applies full theme (accent + bg family)
    property string cursorTheme: "Maya-Green" // persisted; xcursor theme matching an accent
    property int cursorSize: 34             // persisted; fixed default (mid-big, visible on all themes)

    // ── reduced motion ────────────────────────────────────────────────────
    // a11y basics are not optional, and this shell animates 36 Behaviors plus
    // the greeting timeline. `auto` honours the desktop preference; the explicit
    // values are a user override that survives because this is persisted.
    property string motionPref: "auto"       // persisted; "auto" | "reduced" | "full"
    readonly property bool reducedMotion: {
        if (motionPref === "reduced") return true
        if (motionPref === "full") return false
        return _desktopReduced
    }
    // Pushed, not read back: ValkyxState already imports ValkyxMotion, so reading
    // the other way round would be a circular singleton dependency.
    property bool _desktopReduced: false
    onReducedMotionChanged: ValkyxMotion.motionScale = reducedMotion ? 0 : 1
    // NOTE: deliberately no Component.onCompleted here — a QtObject honours only
    // the LAST one, and the real poller-start handler lives further down this
    // file. The reduced-motion seed is merged into it; a second handler here
    // would be silently dropped and auto-detection would never fire.
    property Process _prefReader: Process {
        command: ["sh", "-c", "gsettings get org.gnome.desktop.interface enable-animations 2>/dev/null || echo true"]
        stdout: StdioCollector {
            onStreamFinished: state._desktopReduced = text.trim() === "false"
        }
    }
    // accent theme -> matching xcursor theme (Maya Serie + Valkyx recolors)
    property var themeToCursor: {
        "Valkyx": "Maya-Green", "Violet": "Valkyx-Violet", "Ocean": "Maya-Blue24",
        "Ember": "Maya-Red24", "Amber": "Maya-Orange", "Cyan": "Valkyx-Cyan"
    }
    function cursorForTheme(name) { return themeToCursor[name] ? themeToCursor[name] : cursorTheme }

    // Full theme catalog: valkyx's 6 brand presets + the imported omarchy themes
    // (scraped into ~/.config/valkyx/theming, indexed by valkyx-gen-theme). The
    // picker + resolver read this; the keybind cycle stays on the 6 presets so
    // valkyx behavior is unchanged.
    property var catalogThemes: []
    readonly property var allThemes: ValkyxTheme.themes.concat(catalogThemes)

    // The name to KEY icon/glyph theming by. When auto (wallpaper-derived accent),
    // presets are keyed resources (cursor + valkyx-icons) — resolve to the nearest
    // preset hue so cached glyphs + cursor still match. Real preset or catalog
    // theme = itself.
    readonly property string themedName: {
        for (const t of ValkyxTheme.themes) if (t.name === themeName) return themeName
        for (const t of catalogThemes) if (t.name === themeName) return themeName
        return nearestTheme(accent.toString())
    }

    // ==================== PERSISTENCE ====================
    readonly property string _persistPath: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/valkyx/state.json"

    function applyTheme(name) {
        themeName = name
        let entry = null
        for (const t of ValkyxTheme.themes) if (t.name === name) { entry = t; break }
        if (!entry) for (const t of catalogThemes) if (t.name === name) { entry = t; break }
        if (entry) {
            ValkyxTheme.applyEntry(entry)
            accent = entry.accent
        } else {
            ValkyxTheme.applyTheme(name)
        }
        // cursor follows the accent: presets map by name, catalog themes by accent hue.
        cursorTheme = cursorForTheme(themeToCursor[name] ? name : nearestTheme(entry ? entry.accent : accent))
        // Chain cursor + icons into ONE exec so the _runner never drops either.
        // gen-icons is cosmetic (dock/launcher glyphs): run it with `;` so a
        // flaky render never kills the horizontal theme fan-out that follows.
        // valkyx-gen-theme is the omarchy-style single entry point: it re-tints
        // kitty/btop/code-oss + gtk icons + cursor from the one palette.
        exec("valkyx-cursor '" + cursorTheme + "' " + cursorSize + " && " + borderEvalCmd() + "; valkyx-gen-icons '" + name + "' ; valkyx-gen-theme '" + themedName + "'")
        // catalog themes carry their own wallpaper AND their own palette: apply the
        // image but do NOT re-derive the accent (deriveAccent=false) — the theme wins.
        if (entry && entry.wallpaper) setWallpaper(entry.wallpaper, false)
        savePersisted()
    }

    // Advance to the next theme (Super+Shift+T). Uses the same theme list as the
    // settings appearance picker so accent + cursor + all pickers stay in sync.
    function cycleTheme() {
        const list = ValkyxTheme.themes.map(t => t.name)
        let idx = list.indexOf(themeName)
        idx = (idx + 1) % list.length
        applyTheme(list[idx])
        return list[idx]
    }

    // Apply cursor + accent border + GTK ICON theme system-wide in ONE exec (the
    // serialized _runner drops back-to-back execs, so everything is chained in one
    // sh -c). valkyx-cursor seds hyprland.lua which auto-hot-reloads the config and
    // re-reads the static border from 40-windows.conf — the accent border and the
    // icon theme (Thunar + all GTK apps) are chained AFTER it so they always win.
    // Multiple callers for the same reasons: boot restore, wallpaper palette apply,
    // theme pick, setCursor. themedName resolves "Auto" to the nearest preset so the
    // icon override always maps to a real MacTahoe-<Theme>-dark theme.
    function applyCursor() {
        exec("valkyx-cursor '" + cursorTheme + "' " + cursorSize + " && " + borderEvalCmd() + "; valkyx-gen-theme '" + themedName + "'")
    }
    function setCursor(name, size) {
        cursorTheme = name
        cursorSize = size
        applyCursor()
        savePersisted()
    }

    // Build the hyprctl eval that pushes active+inactive borders. ACTIVE = a
    // two-stop gradient (current accent + violet complement) echoing the 6-accent
    // system; INACTIVE = dimmed accent. Table syntax is the valid Lua border form.
    function borderEvalCmd() {
        const a = accent.toString().replace("#", "") + "ee"
        return "hyprctl eval 'hl.config({general = {col = {active_border = {colors = {\"rgba(" + a + ")\", \"rgba(7c4dffaa)\"}, angle = 45}, inactive_border = \"rgba(" + a + "44)\"}}})'"
    }

    // Push the chosen accent to Hyprland so window borders follow the theme.
    // ACTIVE window gets the bright accent; INACTIVE gets a dimmed accent. Runs on the
    // serialized _runner so it orders behind any in-flight exec (esp. the cursor's sed
    // hot-reload) and always lands last.
    function applyAccentBorder() {
        exec(borderEvalCmd())
    }

    // True once state.json has been read (or found missing). A Process is async,
    // so this lands on a LATER event-loop turn than every Component.onCompleted in
    // the tree — anything that must decide from persisted state rather than from
    // defaults has to wait for it, or it reads `false` for a machine that has been
    // running for months. That is exactly the first-run greeting's bug.
    property bool stateLoaded: false

    // True only while the reader is assigning restored fields, so savePersisted()
    // can refuse to write a half-loaded state. See savePersisted().
    property bool restoring: false

    function loadPersisted() {
        _persistReader.command = ["cat", _persistPath]
        _persistReader.running = true
    }    function savePersisted() {
        // Never write from inside the restore. The reader assigns fields one at
        // a time, so a `property → savePersisted()` handler that fires on the
        // FIRST restored field serialises every field after it as its default —
        // and the file it just wrote is what the next boot reads back. That
        // silently reset greetedOnce on every boot, which pinned the greeting
        // to "Welcome" forever. The guard is here, in the shared writer, rather
        // than on each handler, so no future field can reintroduce it.
        if (restoring) return
        const d = { themeName: themeName, accent: accent.toString(), blurEnabled: blurEnabled, greetingEnabled: greetingEnabled, greetedOnce: greetedOnce, fontScale: fontScale, cursorTheme: cursorTheme, cursorSize: cursorSize, motionPref: motionPref, bg: ValkyxTheme.bg.toString(), surface: ValkyxTheme.surface.toString(), field: ValkyxTheme.field.toString(), line: ValkyxTheme.line.toString(), light: ValkyxTheme.lightMode }
        _persistWriter.command = ["sh", "-c", "mkdir -p $(dirname " + _persistPath + ") && echo '" + JSON.stringify(d) + "' > " + _persistPath]
        _persistWriter.running = true
    }

    property Process _persistReader: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                restoring = true
                try {
                    const d = JSON.parse(text.trim())
                    if (d.themeName) { themeName = d.themeName; ValkyxTheme.applyTheme(d.themeName) }
                    if (d.accent) accent = d.accent
                    // Auto (wallpaper) theme persists its full surface family; presets
                    // carry theirs via applyTheme above. Restore whichever applied.
                    if (d.bg) ValkyxTheme.bg = d.bg
                    if (d.surface) ValkyxTheme.surface = d.surface
                    if (d.field) ValkyxTheme.field = d.field
                    if (d.line) ValkyxTheme.line = d.line
                    if (d.light !== undefined) ValkyxTheme.lightMode = d.light
                    if (d.blurEnabled !== undefined) blurEnabled = d.blurEnabled
                    // `=== false` matters, not `!== undefined`: a plain truthiness
                    // test would drop a saved "greet me" = false and greet anyway.
                    if (d.greetingEnabled !== undefined) greetingEnabled = d.greetingEnabled
                    if (d.greetedOnce !== undefined) greetedOnce = d.greetedOnce
                    if (d.fontScale) fontScale = d.fontScale
                    // boot: restore cursor to the saved accent cursor + apply live.
                    // applyCursor() chains the accent border eval AFTER valkyx-cursor's
                    // config-sed hot-reload, so boot cursor+accent+border all land.
                    cursorTheme = d.cursorTheme ? d.cursorTheme : cursorForTheme(themeName)
                    if (d.cursorSize) cursorSize = d.cursorSize
                    if (d.motionPref) motionPref = d.motionPref
                    applyCursor()
                } catch (e) {} // file missing or invalid = use defaults
                // Cleared BEFORE stateLoaded, so a save caused by the load
                // finishing is still allowed — only the assignments themselves
                // must not write.
                restoring = false
                // Set LAST, in both paths: a missing or corrupt file is a loaded
                // state too — the defaults ARE the machine's state on a fresh
                // install, and the first greeting depends on knowing that.
                stateLoaded = true
            }
        }
    }
    property Process _persistWriter: Process {}

    // Omarchy catalog reader: valkyx-gen-theme writes one normalized entry per
    // theme (6 valkyx presets + scraped omarchy themes) so the appearance picker
    // can offer the whole catalog from one place.
    property Process catalogReader: Process {
        command: ["cat", StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/valkyx/theming/catalog-full.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { state.catalogThemes = JSON.parse(text.trim()).themes } catch (e) { state.catalogThemes = [] }
            }
        }
    }

    // active media kind+path cache (read so the picker can badge the current
    // video/gif). Written by setWallpaper; polled with the wallpaper scan.
    property string activeMediaKind: "image"
    property string activeMediaPath: ""
    property Process mediaScan: Process {
        command: ["sh", "-c",
            "cat ~/.cache/valkyx-wallpaper.kind 2>/dev/null || echo image; echo '---P---'; cat ~/.cache/valkyx-wallpaper.path 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("---P---")
                state.activeMediaKind = (parts[0] || "image").trim() || "image"
                state.activeMediaPath = (parts[1] || "").trim()
            }
        }
    }

    Component.onCompleted: { loadPersisted(); stateGet.running = true; sysGet.running = true; wpScan.running = true; lumScan.running = true; caffeineGet.running = true; mediaScan.running = true; audioScan.running = true; audioWatch.running = true; monitorScan.running = true; weatherScan.running = true; catalogReader.running = true; _prefReader.running = true; ValkyxMotion.motionScale = reducedMotion ? 0 : 1 }

    // Dashboard (left sidebar) pollers run ONLY while the panel is open — they
    // feed no always-visible UI, so polling 24/7 burns CPU for nothing.

    // ==================== WALLPAPER ====================
    property var wallpaperList: []
    property int currentWallpaperIdx: 0
    property real fontScale: 1.13

    // Set a wallpaper from the picker: apply it live, persist for boot, and record
    // its basename in the cache so the picker highlight tracks it.
    // kind = "image" | "gif" | "video". STILLS go through the existing awww crossfade
    // chain (apply + persist a copy + record idx + re-derive accent). VIDEO/GIF go to
    // mpvpaper (a dedicated wlroots video layer) and record kind+path for boot restore.
    // ONE sh -c exec: the shared _runner drops back-to-back exec() calls, so the old
    // 3-exec version silently lost the `cp` persist. Chaining keeps apply+persist atomic.
    function setWallpaper(path, deriveAccent) {
        if (deriveAccent === undefined) deriveAccent = true
        const base = path.split("/").pop()
        const kind = WallpaperStore.kindOf(path)
        const dest = StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/share/backgrounds/valkyx-wallpaper.svg"
        if (kind === "image") {
            // apply + persist a copy + record idx + re-derive the accent palette (matugen),
            // and yield any video layer + write the kind cache so boot restores the still.
            // deriveAccent=false (catalog theme apply): the theme palette is authoritative,
            // so skip matugen + the palette timer that would flip themeName to "Auto".
            const pal = deriveAccent ? " && valkyx-palette '" + path + "' >/dev/null" : ""
            exec("pkill -x mpvpaper 2>/dev/null || true; printf image > ~/.cache/valkyx-wallpaper.kind; printf '%s' '" + path + "' > ~/.cache/valkyx-wallpaper.path && awww img --transition-type none '" + path + "' && cp '" + path + "' '" + dest + "' && echo '" + base + "' > ~/.cache/valkyx-wallpaper.idx" + pal)
            // update highlight immediately (don't wait for the 20s wpScan timer)
            for (let i = 0; i < wallpaperList.length; i++) {
                if (wallpaperList[i].split("/").pop() === base) { currentWallpaperIdx = i; break }
            }
            activeMediaPath = path
            if (deriveAccent) _paletteTimer.running = true
        } else {
            // video/gif: stop any old video layer, BLANK the awww still underneath
            // (so the previous still never peeks under the video or flashes on
            // switch-back), start mpvpaper on the chosen file, persist kind+path.
            exec("pkill -x mpvpaper 2>/dev/null || true; awww clear 2>/dev/null; (mpvpaper -o 'loop=inf no-audio no-osc' eDP-1 '" + path + "' >/dev/null 2>&1 &); printf " + kind + " > ~/.cache/valkyx-wallpaper.kind; printf '%s' '" + path + "' > ~/.cache/valkyx-wallpaper.path")
            activeMediaPath = path
        }
    }

    // Download a remote wallpaper to ~/Pictures/Wallpapers, add it to the
    // local list, and set it as active. Uses _runner so it queues behind
    // any in-flight exec() call.
    function downloadAndSetWallpaper(url) {
        const name = url.split("/").pop().split("?")[0]
        const dest = StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/Pictures/Wallpapers/" + name
        const part = dest + ".part"
        // curl into a .part and rename only on success. The old version wrote
        // straight to dest and the poller fired 1.5s in, so on any file bigger
        // than a few MB it applied a HALF-DOWNLOADED image → broken/black
        // wallpaper (the "download crashes" report).
        exec("rm -f '" + part + "'; curl -sL -o '" + part + "' '" + url + "' && mv -f '" + part + "' '" + dest + "' || rm -f '" + part + "'")
        _dlPoll.deadline = Date.now() + 180000
        _dlPoll.data = { dest: dest, url: url }
        _dlPoll.running = true
    }

    property Timer _dlPoll: Timer {
        interval: 1500; repeat: true
        property var data: ({})
        property double deadline: 0
        onTriggered: {
            // never poll forever if the download failed
            if (Date.now() > deadline) { running = false; return }
            if (checkProc.running) return
            const dest = data.dest || ""
            checkProc.command = ["sh", "-c", "/usr/bin/test -s '" + dest + "' && echo ok"]
            checkProc.running = true
        }
    }

    property Process checkProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "ok") {
                    const dest = _dlPoll.data.dest
                    const url = _dlPoll.data.url
                    _dlPoll.running = false
                    setWallpaper(dest)
                    wpScan.running = true
                }
            }
        }
    }

    // ==================== WALLPAPER PALETTE (accent follows wallpaper) ====================
    // Give the setWallpaper chain a beat to finish (awww + cp + matugen ~0.4s), then
    // read the fresh cache and apply the derived accent + surface family live.
    property Timer _paletteTimer: Timer {
        interval: 1400; repeat: false
        onTriggered: {
            _paletteReader.command = ["sh", "-c", "cat ~/.cache/valkyx-palette.json 2>/dev/null || echo '{}'"]
            _paletteReader.running = true
        }
    }

    property Process _paletteReader: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim())
                    if (!d.accent) return
                    // wallpaper picks ALWAYS drive accent+cursor from the palette's
                    // dominant family (snapped to the nearest 6-accent preset).
                    applyWallpaperPalette(d)
                } catch (e) {}
            }
        }
    }

    // Nearest of the 6 named presets to a hex (for cursor + glyph-icon theming,
    // which are keyed by preset name — the accent itself is dynamic on auto).
    function hexRgb(h) {
        h = (h || "").replace("#", "")
        if (h.length === 3) h = h.split("").map(c => c + c).join("")
        return { r: parseInt(h.substring(0, 2), 16), g: parseInt(h.substring(2, 4), 16), b: parseInt(h.substring(4, 6), 16) }
    }
    // hue angle (0-360) of a #rrggbb hex; -1 when achromatic (hue undefined).
    function hueOf(hex) {
        const h = (hex || "").replace("#", "")
        if (h.length < 6) return -1
        const r = parseInt(h.slice(0, 2), 16) / 255.0
        const g = parseInt(h.slice(2, 4), 16) / 255.0
        const b = parseInt(h.slice(4, 6), 16) / 255.0
        const mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn
        if (d < 0.08) return -1                     // grey: no hue to trust
        let hh
        if (mx === r) hh = 60 * (((g - b) / d) % 6)
        else if (mx === g) hh = 60 * ((b - r) / d + 2)
        else hh = 60 * ((r - g) / d + 4)
        return hh < 0 ? hh + 360 : hh
    }
    function hueDist(a, b) { const d = Math.abs(a - b); return Math.min(d, 360 - d) }

    // Nearest of the 6 named presets FOR CURSOR + GLYPH ICON theming. Match the
    // COLOR FAMILY by hue (circular), never raw RGB distance — otherwise a blue or
    // muted wallpaper accent can snap to Valkyx green and drag the cursor + icons
    // off-family. Achromatic accents fall back to Valkyx (the neutral brand default).
    function nearestTheme(hex) {
        const h = hueOf(hex)
        if (h < 0) return "Valkyx"
        let best = "Valkyx", bestD = Infinity
        for (const t of ValkyxTheme.themes) {
            const th = hueOf(t.accent)
            if (th < 0) continue
            const d = hueDist(h, th)
            if (d < bestD) { bestD = d; best = t.name }
        }
        return best
    }

    // Apply a matugen-derived palette as the live theme: dark surface family
    // from the wallpaper, but the ACCENT snaps to the nearest theme preset so it
    // never renders as muddy/olive. Persists as "Auto"; picking a preset
    // re-enters manual mode.
    function applyWallpaperPalette(pal) {
        const n = nearestTheme(pal.dominant || pal.accent)
        themeName = "Auto"
        for (const t of ValkyxTheme.themes) if (t.name === n) { accent = t.accent; break }
        ValkyxTheme.accent = accent
        ValkyxTheme.bg = pal.bg
        ValkyxTheme.surface = pal.surface
        ValkyxTheme.field = pal.field
        ValkyxTheme.line = pal.line
        cursorTheme = cursorForTheme(n)   // cursor + glyphs follow nearest preset hue
        applyCursor()                      // chains the gradient border (uses fresh accent)
        exec("valkyx-gen-icons '" + n + "'")
        savePersisted()
    }

    // ==================== COMPOSITOR (event-driven) ====================
    readonly property string wsName: {
        const n = Hyprland.activeWorkspace?.name ?? ""
        return n !== "" ? n : (states["wsname"] ?? "")
    }
    readonly property int wsId: Hyprland.activeWorkspace?.id ?? 0
    readonly property int activeWsIndex: {
        const n = wsName
        if (!n) return -1
        const m = n.match(/^0?(\d+)/)
        if (m && m[1] >= 1 && m[1] <= 6) return parseInt(m[1], 10)
        return -1
    }
    readonly property string activeClass: Hyprland.activeToplevel?.class ?? ""
    readonly property string activeTitle: Hyprland.activeToplevel?.title ?? ""
    property bool fullscreen: false
    property bool floating: false

    // context: normal | creative | gaming | fullscreen
    readonly property string context: {
        if (wsName.indexOf("game") >= 0) return "gaming"
        if (fullscreen) return "fullscreen"
        const c = activeClass.toLowerCase()
        if (c.indexOf("blender") >= 0 || c.indexOf("resolve") >= 0 ||
            c.indexOf("inkscape") >= 0 || c.indexOf("darktable") >= 0 ||
            c.indexOf("easyeffects") >= 0 || c.indexOf("godot") >= 0) return "creative"
        return "normal"
    }

    // ==================== HARDWARE VALUES ====================
    property var audioSinks: []       // {id,label,default} output devices
    property var audioSources: []     // {id,label,default} input devices
    property string audioProfile: ""
    function refreshAudio() { audioScan.running = true }
    // dedicated audio executor — NEVER touch exec()/_runner here. That serial
    // queue also runs cursor/icons/border chains; a click must not wait on them.
    property Process _audioRunner: Process {
        property string todo: ""
        onTodoChanged: { if (todo.length) { command = ["sh", "-c", todo]; running = true } }
    }
    // instant: flip default + refresh lists locally, fire the switch off-queue.
    function setAudioOutput(id) {
        // applying: the NEED slot stays the active row while the profile switch
        // is in flight (0.6-4.8s retry); a real sink replaces it on the rescan.
        audioSinks = audioSinks.map(s => Object.assign({}, s, { default: s.id === id }))
        _audioRunner.todo = StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/valkyx-audio set-sink '" + id + "'"
        audioRefreshFast.restart()
    }
    function setAudioInput(id) {
        audioSources = audioSources.map(s => Object.assign({}, s, { default: s.id === id }))
        _audioRunner.todo = StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/valkyx-audio set-source '" + id + "'"
        audioRefreshFast.restart()
    }
    property Timer audioRefreshFast: Timer { interval: 300; onTriggered: state.audioScan.running = true }
    property Process audioScan: Process {
        command: [StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/valkyx-audio", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    state.audioProfile = j.profile || ""
                    state.audioSinks = j.sinks || []
                    state.audioSources = j.sources || []
                } catch (e) { /* keep last state */ }
            }
        }
    }

    // Live device hotplug monitor — pactl subscribe streams change events
    // (sink/source/card add+remove+change). Debounced: a profile switch fires
    // 8-10 events in <1s; the timer collapses them into one scan.
    property Timer audioWatchDebounce: Timer { interval: 400; onTriggered: state.audioScan.running = true }
    property Process audioWatch: Process {
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                if (line.indexOf("client") >= 0) return
                if (line.indexOf("sink") >= 0 || line.indexOf("source") >= 0 || line.indexOf("card") >= 0)
                    state.audioWatchDebounce.restart()
            }
        }
    }

    property real volPct: 0
    property real briPct: 50
    property bool micMuted: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property bool mediaPlaying: false
    property real mediaPos: 0
    property real mediaLen: 0
    property string netLine: "…"
    property string wifiSsid: ""
    property int wifiSig: 0
    property bool wifiEnabled: true
    property bool btEnabled: false
    property var wifiList: []
    property var notifList: []
    property real batteryPct: -1
    property bool batteryCharging: false
    property real memPct: -1
    property real cpuPct: -1
    property real diskPct: -1
    property real batWatts: -1
    property string uptimeLine: ""
    property string powerProfile: "performance"     // saved choice (buttons highlight this)
    property string powerProfileLive: "performance" // what the CPU is ACTUALLY running
    property string acSource: "ac"                  // "ac" | "battery"
    property real netUpKbs: 0
    property real netDownKbs: 0

    // ==================== DASHBOARD (valkyx-dash / valkyx-weather) ====================
    property var coreLoads: []           // per-core util %
    property real swapPct: 0
    property var diskMounts: []          // [{mount, pct}]
    property real cpuTemp: 0
    property real pkgTemp: 0
    property string gpuStr: "off"        // "util|temp|memUsed|memTotal" or "off" (no nvidia)
    property real gpuUtil: -1
    property string weatherTemp: "—"
    property string weatherFeels: "—"
    property string weatherDesc: ""
    property int weatherCode: 0          // wttr.in code, 0 = offline
    property string weatherHum: "—"
    property string weatherWind: "—"
    property string mediaArt: ""         // file://… cover path (empty if none)
    property var clipList: []            // [{name, run}] recent clipboard entries
    property Process clipScan: Process {
        command: ["sh", "-c", "valkyx-launch --list-json \"" + ValkyxState.themedName + "\" clip 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { state.clipList = JSON.parse(text) } catch (e) { /* keep last */ }
            }
        }
    }
    property Timer clipTimer: Timer { interval: 10000; running: ValkyxState.panelLeftOpen; repeat: true; onTriggered: clipScan.running = true }
    function copyClip(run) { exec("valkyx-launch --run \"" + run + "\"") }

    property Process monitorScan: Process {
        command: [StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/valkyx-dash"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    text.trim().split("\n").forEach(line => {
                        const i = line.indexOf("=")
                        if (i <= 0) return
                        const k = line.slice(0, i), v = line.slice(i + 1)
                        if (k === "cores") state.coreLoads = v.split(",").map(x => parseInt(x)).filter(x => !isNaN(x))
                        else if (k === "swap") state.swapPct = parseInt(v || "0")
                        else if (k === "mounts") {
                            const out = []
                            v.split(";;").forEach(m => {
                                const p = m.split("|")
                                if (p.length === 2) out.push({ mount: p[0], pct: parseInt(p[1]) })
                            })
                            state.diskMounts = out
                        }
                        else if (k === "cput") state.cpuTemp = parseInt(v || "0")
                        else if (k === "pktt") state.pkgTemp = parseInt(v || "0")
                        else if (k === "gpu") {
                            state.gpuStr = v
                            const p = v.split("|")
                            state.gpuUtil = p.length >= 2 ? parseInt(p[0]) : -1
                        }
                    })
                } catch (e) { /* keep last state */ }
            }
        }
    }
    property Timer monitorTimer: Timer { interval: 2000; running: ValkyxState.panelLeftOpen; repeat: true; onTriggered: monitorScan.running = true }

    property Process weatherScan: Process {
        command: [StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/valkyx-weather"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    text.trim().split("\n").forEach(line => {
                        const i = line.indexOf("=")
                        if (i <= 0) return
                        const k = line.slice(0, i), v = line.slice(i + 1)
                        if (k === "temp") state.weatherTemp = v
                        else if (k === "feels") state.weatherFeels = v
                        else if (k === "desc") state.weatherDesc = v
                        else if (k === "code") state.weatherCode = parseInt(v || "0")
                        else if (k === "hum") state.weatherHum = v
                        else if (k === "wind") state.weatherWind = v
                    })
                } catch (e) { /* keep last state */ }
            }
        }
    }
    property Timer weatherTimer: Timer { interval: 1800000; running: ValkyxState.panelLeftOpen; repeat: true; onTriggered: weatherScan.running = true }

    // ==================== QUICK TOGGLES ====================
    readonly property var toggles: [
        { key: "wifi",  glyph: "\uDB81\uDDA9",
          on: "nmcli radio wifi on",             off: "nmcli radio wifi off" },
        { key: "bt",    glyph: "\uDB80\uDCAF",
          on: "bluetoothctl power on",           off: "bluetoothctl power off" },
        { key: "dnd",   glyph: "\uDB81\uDD94",
          on: "makoctl mode -a do-not-disturb",  off: "makoctl mode -r do-not-disturb" },
        { key: "night", glyph: "󰖨",
          on: "setsid gammastep -O 3500K >/dev/null 2>&1 &", off: "pkill -x gammastep" },
        { key: "caffeine", glyph: "󰅶",
          on: "valkyx-caffeine on", off: "valkyx-caffeine off" }
    ]

    property var states: ({})
    function isOn(key) { return states[key] === "enabled" }
    function toggleKey(key) {
        for (let i = 0; i < toggles.length; i++) {
            if (toggles[i].key === key) {
                const on = isOn(key)
                const target = on ? "disabled" : "enabled"
                states = Object.assign({}, states, { [key]: target })  // optimistic flip → instant pill
                exec(on ? toggles[i].off : toggles[i].on)
                refreshSoon.restart()
                return
            }
        }
    }

    // ==================== OSD ====================
    property string osdMode: ""             // "" | vol | bri | mic | media
    property real osdValue: 0
    property real _prevVol: -1
    property real _prevBri: -1
    onVolPctChanged: {
        if (_prevVol < 0) { _prevVol = volPct; return }
        if (Math.abs(volPct - _prevVol) >= 1 && !panelOpen) {
            osdMode = "vol"; osdValue = volPct; osdHide.restart()
            ValkyxEvents.volumeChanged(volPct)
            ValkyxEvents.osdShown("vol", volPct)
        }
        _prevVol = volPct
    }
    onBriPctChanged: {
        if (_prevBri < 0) { _prevBri = briPct; return }
        if (Math.abs(briPct - _prevBri) >= 1 && !panelOpen) {
            osdMode = "bri"; osdValue = briPct; osdHide.restart()
            ValkyxEvents.brightnessChanged(briPct)
            ValkyxEvents.osdShown("bri", briPct)
        }
        _prevBri = briPct
    }
    onMicMutedChanged: {
        ValkyxEvents.micMuteChanged(micMuted)
        osdMode = "mic"; osdValue = micMuted ? 0 : 1; osdHide.restart()
    }
    onMediaTitleChanged: if (mediaTitle) ValkyxEvents.mediaChanged(mediaTitle)

    property Timer osdHide: Timer {
        interval: ValkyxMotion.osdHold
        onTriggered: { state.osdMode = ""; ValkyxEvents.osdHidden() }
    }

    // ==================== COMMAND RUNNER ====================
    // Serial queue: exec() called while a command is still running used to
    // clobber `todo` and abort the in-flight command (theme fans out 2 execs in a
    // row, so the cursor/border chain silently never applied). Now the in-flight
    // one finishes and the queued ones run after it, in order.
    property int _seq: 0
    property var _execQ: []
    function exec(cmd) {
        _seq++
        const c = cmd + " #seq" + _seq
        if (_runner.running) _execQ.push(c)
        else _runner.todo = c
    }

    // Push the chosen accent to Hyprland so window borders follow the theme.
    // ACTIVE window gets the bright accent; INACTIVE windows get a dimmed accent.
    // Runs on the serialized _runner (see applyAccentBorder/borderEvalCmd above).
    // NOT hooked to onAccentChanged: accent is only ever set inside applyTheme() and
    // loadPersisted(), both of which follow up with applyCursor() (which chains the
    // border eval AFTER valkyx-cursor) — an auto-handler here would double-exec and
    // race within _runner, dropping the final border. DON'T re-add it.

    // valkyx-dispatch is broken on this box (Lua wrapper mangles args) —
    // go through the IPC socket directly with Lua dispatcher syntax.
    function dispatch(cmd) { Hyprland.dispatch(cmd) }

    // semantic workspaces are named (01 studio … 06 game), not numbered
    readonly property var wsNames: ["studio", "create", "code", "research", "personal", "game"]
    function goWorkspace(i) { dispatch('hl.dsp.focus({ workspace = "name:0' + i + ' ' + wsNames[i - 1] + '" })') }

    // ==================== WELCOME ====================
    // welcomePanelOpen is NOT persisted: a panel that re-opens itself on every
    // boot is the panelOpen bug from Sep 26, repeated.
    property bool welcomePanelOpen: false

    // The greeting overlay is currently UNLOADED (see shell.qml) because a
    // fullscreen layershell surface eats the mouse even at opacity 0. These two
    // are kept only so the retained file stays valid if it is ever re-enabled;
    // nothing reads them while it is unloaded, so they are not persisted.
    property bool welcomeOpen: false
    // Greet on every shell start. This is the flag shell.qml's boot trigger reads
    // to mount the greeter, and showGreeter() consumes it so it cannot re-arm
    // itself mid-session. Not persisted: "greet at boot" has to be true on every
    // start, so a retained value would be wrong in both directions.
    property bool greetsOnBoot: true

    // The USER's preference — the on/off switch in the welcome window and in
    // Settings. Deliberately a different property from `greetsOnBoot` above:
    // that one is a per-session latch that showGreeter() consumes, so persisting
    // it (or letting a toggle write it) would make the greeting self-sustaining
    // in whichever direction the user last touched it — the panelOpen bug again.
    // Persisted, because "do not greet me" has to survive a reboot to mean
    // anything.
    property bool greetingEnabled: true
    onGreetingEnabledChanged: savePersisted()

    // Has the greeter ever run on this machine? False until the first login after
    // install, which is the only thing that decides "Welcome" vs "Welcome back".
    // Persisted for the same reason.
    property bool greetedOnce: false

    // Transient, set by shell.qml's boot trigger immediately before it mounts the
    // greeter, and read once by the greeting line. NOT persisted, and deliberately
    // defaulting to false: the preview path (`_test greet`) then shows the normal
    // returning greeting instead of stealing the first-run wording.
    property bool firstGreeting: false

    function openWelcomePanel() { welcomePanelOpen = true }
    function showGreeter() { greetsOnBoot = false; welcomeOpen = true }

    // ==================== SYSTEM FACTS (for the welcome card) ====================
    // One Process, all fields, one shot per open. NOT a poll: the machine does
    // not change identity between logins, and a 5-field card does not justify
    // spawning a shell every second.
    property string userName: ""
    property string hostName: ""
    property string kernelName: ""
    property string hyprVersion: ""
    property string uptimeText: ""

    property Process sysInfo: Process {
        command: ["sh", "-c", "printf 'user=%s\\nhost=%s\\nkernel=%s\\n' \"$(id -un)\" \"$(uname -n)\" \"$(uname -r)\"; printf 'hypr=%s\\n' \"$(hyprctl version 2>/dev/null | sed -n 's/.*v\\([0-9][^ ]*\\).*/\\1/p' | head -1)\"; printf 'up=%s\\n' \"$(uptime -p 2>/dev/null | sed 's/^up //')\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text
                const g = k => { const m = t.match(new RegExp("^" + k + "=(.*)$", "m")); return m ? m[1].trim() : "" }
                state.userName = g("user")
                state.hostName = g("host")
                state.kernelName = g("kernel")
                state.hyprVersion = g("hypr")
                state.uptimeText = g("up")
            }
        }
    }

    // The keybind table on the welcome card. Hand-written, and that is the point:
    // it is the *curated* set (what a new user actually needs), not a dump of all
    // 92 binds. Transcribed from hyprland.lua — Super+ALT+Tab, not Super+Tab,
    // and the language keys are Scroll_Lock / CTRL+Space. `valkyx-welcome` prints
    // the same list so the two can be diffed after any keybind change.
    property var keybindList: [
        { keys: "Super+Return",       what: "new terminal" },
        { keys: "Super+Shift+Return", what: "focus the open terminal" },
        { keys: "Super+Space",        what: "launcher" },
        { keys: "Super+S",            what: "action centre" },
        { keys: "Super+I",            what: "settings" },
        { keys: "Super+Shift+W",      what: "welcome panel" },
        { keys: "Super+W",            what: "wallpaper deck" },
        { keys: "Super+X",            what: "power menu" },
        { keys: "Alt+Tab",            what: "switch windows (MRU)" },
        { keys: "Super+Alt+Tab",      what: "switch windows, other way" },
        { keys: "Scroll_Lock",        what: "language: en / ع" },
        { keys: "Super+Shift+T",      what: "cycle theme" },
        { keys: "Super+Shift+K",      what: "keyboard settings" },
        { keys: "Super+Shift+V",      what: "clipboard" },
        { keys: "Super+Ctrl+Alt+L",   what: "lock" },
        { keys: "Super+Shift+B",      what: "backup" }
    ]

    // ==================== ACTIONS ====================
    function setVolume(v) {
        volPct = Math.round(v)  // optimistic → slider fill stays glued to the pointer
        _volTodo = "pamixer --set-volume " + Math.round(v)
        volTrail.restart()
    }
    function setBrightness(v) {
        briPct = Math.round(v)  // optimistic
        _briTodo = "brightnessctl -q s " + Math.round(v) + "%"
        briTrail.restart()
    }
    property string _volTodo: ""
    property string _briTodo: ""
    property Timer volTrail: Timer { interval: 60; repeat: false; onTriggered: { if (_volTodo.length) { exec(_volTodo); _volTodo = "" } } }
    property Timer briTrail: Timer { interval: 60; repeat: false; onTriggered: { if (_briTodo.length) { exec(_briTodo); _briTodo = "" } } }
    function setPowerProfile(p) {
        // Don't set powerProfile optimistically: if "valkyx-power set" fails the
        // panel would show the choice that was never applied. The 1s state poller
        // reads it back from the saved file and updates once the write landed.
        exec("valkyx-power set " + p)
        refreshStates()
    }
    function toggleMic() { exec("pamixer --default-source -t"); refreshPanelValues() }
    function toggleMedia() { exec("playerctl play-pause"); mediaRePoll.start() }
    function mediaNext() { exec("playerctl next"); mediaRePoll.start() }
    function mediaPrev() { exec("playerctl previous"); mediaRePoll.start() }
    function mediaSeek(pct) { if (mediaLen > 0) { exec("playerctl position " + (mediaLen * pct / 100)); mediaRePoll.start() } }
    function rescanWifi() { exec("nmcli dev wifi rescan"); refreshSoon2.restart() }
    function clearNotifs() { exec("pkill -x mako; setsid mako >/dev/null 2>&1 &"); ValkyxEvents.notificationsCleared(); refreshSoon2.restart() }
    function launch(cmd) { exec("setsid " + cmd + " >/dev/null 2>&1 &") }

    // notification row click → jump to the dir a path in the text points at,
    // else focus/launch the owning app. Path wins over app.
    function openNotification(idx) {
        const n = notifList[idx] || {}
        if (!n.app && !n.summary) return
        const hay = ((n.summary || "") + " " + (n.body || "")).trim()
        // a filesystem path in the text → open it (folders in Files, media/docs via default handler)
        const pm = hay.match(/(?:\/?home\/|\/media\/|\/mnt\/|\/run\/|\/tmp\/|\/var\/|\/opt\/|\/etc\/)[^\s"',;)\]]+/)
        if (pm) {
            const p = pm[0].replace(/'/g, "'\\''")
            if (/[\/\\]$/.test(p) || !/\.(png|jpe?g|gif|webp|bmp|svg|mp4|mkv|webm|mov|avi|mp3|wav|flac|ogg|pdf)$/i.test(p))
                exec("setsid thunar '" + p + "' >/dev/null 2>&1 &")
            else
                exec("setsid xdg-open '" + p + "' >/dev/null 2>&1 &")
            return
        }
        // desktop entry first (correct binary for native AND flatpak apps), else the class map
        const cls = (n.desktopEntry || n.app || "").toLowerCase()
        if (cls) {
            if ((runningWindows || []).indexOf(cls) !== -1) { dispatch('hl.dsp.focus({ window = "class:' + cls + '" })'); return }
            // native AND flatpak: try the launched command first (commandForClass knows
            // flatpak org.* apps → flatpak run, which gtk-launch canNOT resolve), else gtk-launch
            const cmd = commandForClass(cls)
            if (cmd) { launch(cmd); return }
            exec("gtk-launch '" + cls + "' >/dev/null 2>&1 &")
            return
        }
        const cmd = commandForClass((n.app || "").toLowerCase())
        if (cmd) launch(cmd)
    }

    // tailscale up/down (daemon runs as root → sudo NOPASSWD)
    function setTailscale(on) {
        exec(on ? "sudo -n tailscale up" : "sudo -n tailscale down")
        tsGet.running = true
        refreshSoon2.restart()
    }
    function focusOrLaunch(cls, cmd) {
        // Running check uses the ACTUAL running window classes (any app, not just
        // pinned) so non-pinned running apps focus instead of spawning a duplicate
        // or blank-launching. Falls back to launching a new window when not running.
        if ((runningWindows || []).indexOf(cls) !== -1) dispatch('hl.dsp.focus({ window = "class:' + cls + '" })')
        else {
            const resolved = cmd && cmd !== "" ? cmd : commandForClass(cls)
            launch(resolved)
        }
    }

    // friendly display label for a window class (falls back to the bare class)
    function appLabel(cls) {
        const c = cls.toLowerCase()
        const m = {
            kitty: "Terminal", "org.gnome.console": "Terminal", "io.wezterm.wez": "Terminal", alacritty: "Terminal",
            helium: "Browser", "helium-browser": "Browser", firefox: "Firefox", chromium: "Chromium", "google-chrome": "Google Chrome", brave: "Brave",
            thunar: "Files", nautilus: "Files", "org.gnome.nautilus": "Files", dolphin: "Dolphin", "org.gnome.files": "Files",
            "antigravity": "Editor", "antigravity-ide": "Editor", code: "Code", "code-oss": "Code", gedit: "Editor",
            blender: "Blender", resolve: "DaVinci Resolve", inkscape: "Inkscape", gimp: "GIMP",
            obs: "OBS Studio", vlc: "VLC", spotify: "Spotify", darktable: "Darktable", telegram: "Telegram", "org.telegram.desktop": "Telegram",
            "org.gnome.calendar": "Calendar"
        }
        if (m[c]) return m[c]
        if (c.indexOf("chrome-") === 0) return "Browser"
        if (c.indexOf("discord") >= 0) return "Discord"
        if (c.indexOf("slack") >= 0) return "Slack"
        // title-case the bare class as a readable fallback
        return c.split(/[.-]/).map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ")
    }

    // launch command for a running window class (for "New Window" in taskbar menus)
    function commandForClass(cls) {
        const c = cls.toLowerCase()
        const m = {
            kitty: "kitty",
            "org.gnome.console": "kgx",
            "io.wezterm.wez": "wezterm",
            alacritty: "alacritty",
            
            thunar: "thunar",
            dolphin: "dolphin",
            nautilus: "nautilus",
            "org.gnome.nautilus": "nautilus",
            "pcmanfm": "pcmanfm",
            "antigravity": "antigravity",
            "antigravity-ide": "antigravity",
            helium: "helium-browser",
            "helium-browser": "helium-browser",
            firefox: "firefox",
            "firefox-developer-edition": "firefox-devedition",
            chromium: "chromium",
            "google-chrome": "google-chrome",
            code: "code-oss",
            "code-oss": "code-oss",
            blender: "blender",
            resolve: "/opt/resolve/resolve",
            inkscape: "inkscape",
            gimp: "gimp",
            darktable: "darktable",
            obs: "obs",
            "org.gnome.gedit": "gedit",
            telegram: "flatpak run org.telegram.desktop",
            "org.telegram.desktop": "flatpak run org.telegram.desktop",
            vlc: "vlc",
            spotify: "spotify",
            "org.gnome.Calendar": "gnome-calendar",
            "org.gnome.Nautilus": "nautilus"
        }
        // exact-first, then substring fallback for namespaced classes
        if (m[c]) return m[c]
        for (const k in m) { if (c.indexOf(k) >= 0) return m[k] }
        return ""
    }

    // close/quit every window of an app class. valkyx-dispatch is broken under
    // the Lua config — hyprctl eval runs the loop as raw Lua instead.
    // Escapes Lua pattern magic so the class string matches literally.
    function _clsPat(cls) {
        if (cls === "helium") return "chrome%-"  // Helium windows report as chrome-<profile>-Default
        var out = ""
        for (var i = 0; i < cls.length; i++) {
            var c = cls.charAt(i)
            out += ".()+%*-?[]^$".indexOf(c) >= 0 ? "%" + c : c
        }
        return out
    }
    function closeClass(cls) { _winLoop(cls, "close") }
    function quitClass(cls) { _winLoop(cls, "kill") }
    function _winLoop(cls, action) {
        exec("hyprctl eval \"for i,w in pairs(hl.get_windows()) do if w.class:match('" +
             _clsPat(cls) + "') then hl.dispatch(hl.dsp.window." + action +
             "({window = w})) end end\"")
    }

    // ==================== REFRESH ====================
    function refreshPanelValues() { hwGet.running = true; mediaGet.running = true; netGet.running = true; audioScan.running = true }
    function refreshWifi() { wifiScan.running = true }
    function refreshNotifs() { notifGet.running = true }
    function refreshStates() { stateGet.running = true }

    property Timer refreshSoon: Timer { interval: 900; onTriggered: state.refreshStates() }
    property Timer refreshSoon2: Timer { interval: 1600; onTriggered: { state.refreshWifi(); state.refreshNotifs(); state.refreshStates(); state.audioScan.running = true } }

    // ==================== COMPOSITOR EVENTS ====================
    property Connections _hypr: Connections {
        target: Hyprland
        function onRawEvent(e) {
            if (e.name === "fullscreen") {
                state.fullscreen = (e.data === "1")
                ValkyxEvents.fullscreenChanged(state.fullscreen)
            } else if (e.name === "workspace") {
                state.fullscreen = false
                const nm = e.data && e.data.indexOf("name:") === 0 ? e.data.slice(5) : e.data
                state.states = Object.assign({}, state.states, { wsname: nm })
                ValkyxEvents.workspaceChanged(nm)
            } else if (e.name === "activewindow") {
                state.fullscreen = false
                const clsMatch = e.data && e.data.match(/class:\s*(\S+)/)
                if (clsMatch) ValkyxEvents.windowFocused(clsMatch[1], state.activeTitle)
            } else if (e.name === "openwindow" || e.name === "closewindow") {
                // event-driven dock + ws-pill refresh (instant, no poll lag)
                stateGet.running = true
                classIconsGet.running = true
            }
        }
    }
    onContextChanged: {
        ValkyxEvents.contextChanged(context)
        applyBlur()
    }
    onFullscreenChanged: {
        ValkyxEvents.fullscreenChanged(fullscreen)
        applyBlur()
    }
    onWsNameChanged: ValkyxEvents.workspaceChanged(wsName)

    property bool blurEnabled: true

    function applyBlur() {
        const on = !(context === "gaming" || context === "fullscreen") && blurEnabled
        exec("hyprctl eval 'hl.config({ decoration = { blur = { enabled = " + (on ? "true" : "false") + " } } })'")
    }

    function toggleBlur() {
        blurEnabled = !blurEnabled
        applyBlur()
        savePersisted()
    }

    onBlurEnabledChanged: savePersisted()

    // Off means "follow the desktop", not "force full motion" — the toggle binds
    // to the resolved `reducedMotion`, so it reads ON by itself if the desktop
    // disables animations. A third "force full" state would be a control nobody
    // reaches for twice.
    function setMotion(on: bool) {
        motionPref = on ? "reduced" : "auto"
        ValkyxMotion.motionScale = reducedMotion ? 0 : 1
        savePersisted()
    }

    // ==================== ENGINES ====================
    property Process _runner: Process {
        property string todo: ""
        onTodoChanged: { if (todo.length) { command = ["sh", "-c", todo]; running = true } }
        onRunningChanged: {
            if (!running && _execQ.length > 0) todo = _execQ.shift()
        }
    }

    // unified compositor + dock state poller (1s) — instant dock updates
    // Uses hyprctl clients for dock detection (avoids pgrep self-match inside sh -c)
    property Process stateGet: Process {
        command: ["sh", "-c",
            "echo wifi:$(nmcli radio wifi 2>/dev/null)" + "\n" +
            "echo bt:$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo enabled || echo disabled)" + "\n" +
            "echo dnd:$(makoctl mode 2>/dev/null | grep -q dnd && echo enabled || echo disabled)" + "\n" +
            "echo night:$(pgrep -x gammastep >/dev/null && echo enabled || echo disabled)" + "\n" +
            "echo caffeine:$(pgrep -x hypridle >/dev/null && echo disabled || echo enabled)" + "\n" +
            "echo caffeinemin:$(cat ~/.cache/valkyx-caffeine.min 2>/dev/null || echo 0)" + "\n" +
            "echo wsname:$(hyprctl activeworkspace 2>/dev/null | grep -oE '\\([0-9]+[a-z ]*\\)' | tr -d '()')" + "\n" +
            // powerProfile = the user's SAVED choice (what the buttons highlight).
            // powerProfileLive = the profile the daemon is ACTUALLY applying right now.
            // These differ on battery: valkyx-power forces the "battery" pseudo-profile
            // (EPP=balance_power, turbo off, 20/30W) regardless of the saved value, so
            // reading only the file made the panel claim e.g. "balanced" while the CPU
            // was running the battery profile. Derive the live one from the kernel.
            "echo profile:$(cat " + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/valkyx/power-profile 2>/dev/null || echo performance)" + "\n" +
            "ac=$(cat /sys/class/power_supply/ACAD/online 2>/dev/null); epp=$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null); nt=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null); if [ \"$ac\" = 0 ]; then echo proflive:battery; else case \"$epp/$nt\" in performance/0) echo proflive:performance ;; balance_power/0|balance_performance/0) echo proflive:balanced ;; power/1) echo proflive:power-saver ;; *) echo proflive:unknown ;; esac; fi" + "\n" +
            "echo acsrc:$([ \"$ac\" = 0 ] && echo battery || echo ac)" + "\n" +
            "cls=$(hyprctl clients -j 2>/dev/null)" + "\n" +
            "echo dock_terminal:$(echo \"$cls\" | grep -qE 'kitty' && echo on || echo off)" + "\n" +
            "echo dock_web:$(echo \"$cls\" | grep -qE 'helium|chrome-' && echo on || echo off)" + "\n" +
            "echo dock_files:$(echo \"$cls\" | grep -q 'thunar' && echo on || echo off)" + "\n" +
            "echo dock_sandbox:$(echo \"$cls\" | grep -q 'ValkyxSandbox' && echo on || echo off)" + "\n" +
            "echo dock_blender:$(echo \"$cls\" | grep -q 'blender' && echo on || echo off)" + "\n" +
            "echo dock_resolve:$(echo \"$cls\" | grep -q 'resolve' && echo on || echo off)" + "\n" +
            "echo windows:$(echo \"$cls\" | grep -oE '\"class\": \"[^\"]*\"' | sed 's/\"class\": \"//;s/\"//' | sort -u | tr '\\n' ',' | sed 's/,$//')" + "\n" +
            "echo ws_windows:$( " + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/valkyx-ws-windows)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const patch = {}
                const lines = text.trim().split("\n")
                lines.forEach(line => {
                    const i = line.indexOf(":")
                    if (i <= 0) return
                    const k = line.slice(0, i), v = line.slice(i + 1)
                    if (k === "caffeinemin") {
                        const n = parseInt(v)
                        if (!isNaN(n)) state.caffeineMin = n
                    } else if (k === "proflive") {
                        state.powerProfileLive = v || "unknown"
                    } else if (k === "acsrc") {
                        state.acSource = v || "ac"
                    } else if (k === "windows") {
                        state.runningWindows = v ? v.split(",").filter(x => x) : []
                    } else if (k === "ws_windows") {
                        const m = {}
                        v.split("|").forEach(seg => {
                            const c = seg.indexOf(":")
                            if (c > 0) m[seg.slice(0, c)] = seg.slice(c + 1).split(",").filter(x => x)
                        })
                        state.wsWindows = m
                    } else {
                        patch[k] = v
                    }
                })
                state.states = Object.assign({}, state.states, patch)
            }
        }
    }
    property Timer stateTimer: Timer { interval: 3000; running: true; repeat: true; onTriggered: stateGet.running = true }

    // running window classes from hyprctl clients (for dock taskbar)
    property var runningWindows: []

    // workspace id → [classes...] (for workspace pills showing per-ws app icons)
    property var wsWindows: ({})

    // resolved real app icons keyed by window class (kitty → kitty.svg …).
    // Populated by classIconsGet so running apps get their own icon in the dock.
    property var classIcons: ({})

    // Batch icon resolution for every running class (one subprocess per state
    // refresh, not per tile — avoids spawning a shell per dock item).
    property Process classIconsGet: Process {
        command: ["sh", "-c",
            "hyprctl clients -j 2>/dev/null | grep -oE '\"class\": \"[^\"]*\"' | sed 's/\"class\": \"//;s/\"//' | sort -u | while IFS= read -r c; do [ -n \"$c\" ] && echo \"$c=$(" + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/valkyx-class-icon \\\"$c\\\")\"; done"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {}
                text.trim().split("\n").forEach(line => {
                    const i = line.indexOf("=")
                    if (i > 0) m[line.slice(0, i)] = line.slice(i + 1)
                })
                // Only reassign when something actually changed. Assigning a fresh
                // object every 1.2s tore down and rebuilt every dock-icon binding,
                // which is what made the shell visibly blink/flicker.
                const cur = state.classIcons
                const keys = Object.keys(m)
                if (keys.length !== Object.keys(cur).length) { state.classIcons = m; return }
                for (const k of keys) {
                    if (cur[k] !== m[k]) { state.classIcons = m; return }
                }
            }
        }
    }
    property Timer classIconsTimer: Timer {
        interval: 1200; running: true; repeat: true
        onTriggered: { if (ValkyxState.runningWindows.length) classIconsGet.running = true }
    }

    // consolidated vol+bri+mic poller (2s) — replaces 3 separate timers
    property Process hwGet: Process {
        command: ["sh", "-c",
            "echo vol:$(pamixer --get-volume 2>/dev/null || echo 0)" + "\n" +
            "echo bri:$(( $(brightnessctl get 2>/dev/null) * 100 / $(brightnessctl max 2>/dev/null || echo 1) ))" + "\n" +
            "echo mic:$(pamixer --default-source --get-mute 2>/dev/null)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                lines.forEach(line => {
                    const i = line.indexOf(":")
                    if (i <= 0) return
                    const k = line.slice(0, i), v = line.slice(i + 1).trim()
                    if (k === "vol") state.volPct = parseInt(v || "0")
                    else if (k === "bri") state.briPct = parseInt(v || "50")
                    else if (k === "mic") state.micMuted = (v === "true")
                })
            }
        }
    }
    property Timer hwTimer: Timer { interval: 1000; running: true; repeat: true; onTriggered: hwGet.running = true }

    // input method layout (fcitx5) — "us" | "ara". The toggle script reports the
    // new value on stdout, so a topbar click is instant. A *keybind* has no such
    // channel — Hyprland runs the script and the shell only learns via this poll.
    // Hence 200ms: it is what makes Super+Shift+Space flip the label with no
    // visible lag. Polled off the state file, not the script, because the file
    // is written under the same flock as the apply: a 1ms cat instead of a 6ms
    // hyprctl IPC round-trip, ~5 polls/sec for 0.3% of a core instead of 3%.
    property string imLayout: "us"
    property Process imGet: Process {
        command: ["sh", "-c", "cat " + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/valkyx-im-state 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: { const v = text.trim(); if (v) state.imLayout = v }
        }
    }
    property Process imToggle: Process {
        command: ["sh", "-c", StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/valkyx-im toggle"]
        stdout: StdioCollector {
            onStreamFinished: { const v = text.trim(); if (v) state.imLayout = v }
        }
    }
    property Timer imTimer: Timer { interval: 200; running: true; repeat: true; onTriggered: imGet.running = true }

    property Process mediaGet: Process {
        command: ["sh", "-c", "t=$(playerctl metadata title 2>/dev/null); a=$(playerctl metadata artist 2>/dev/null); p=$(playerctl status 2>/dev/null); pos=$(playerctl position 2>/dev/null); len=$(playerctl metadata mpris:length 2>/dev/null); art=$(playerctl metadata mpris:artUrl 2>/dev/null); printf '%s\\n%s\\n%s\\n%s\\n%s\\n%s' \"$t\" \"$a\" \"$p\" \"${pos:-0}\" \"${len:-0}\" \"$art\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                state.mediaTitle = lines[0] || ""
                state.mediaArtist = lines[1] || ""
                state.mediaPlaying = (lines[2] || "").indexOf("Playing") >= 0
                const pos = parseFloat(lines[3] || "0")
                const len = parseFloat(lines[4] || "0") / 1000000
                state.mediaPos = isNaN(pos) ? 0 : pos
                state.mediaLen = isNaN(len) ? 0 : len
                const art = (lines[5] || "").trim()
                if (art !== state._lastArtUrl) {
                    state._lastArtUrl = art
                    if (art.indexOf("http") === 0) {
                        const home = StandardPaths.writableLocation(StandardPaths.HomeLocation)
                    state._artGet.command = ["sh", "-c", "curl -sL --max-time 8 '" + art + "' -o " + home + "/.cache/valkyx-media-art 2>/dev/null && grep -q . " + home + "/.cache/valkyx-media-art && echo ok || rm -f " + home + "/.cache/valkyx-media-art"]
                        state._artGet.running = true
                    } else if (art.indexOf("file://") === 0) {
                        state.mediaArt = art
                    } else {
                        state.mediaArt = ""
                    }
                }
            }
        }
    }
    property string _lastArtUrl: ""
    property Process _artGet: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().indexOf("ok") === 0)
                    state.mediaArt = "file://" + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/valkyx-media-art"
                else
                    state.mediaArt = ""
            }
        }
    }
    property Timer mediaTimer: Timer { interval: 5000; running: true; repeat: true; onTriggered: mediaGet.running = true }

    // smooth the progress bar between 5s polls
    property Timer mediaTick: Timer {
        interval: 1000; repeat: true
        onTriggered: { if (state.mediaPlaying && state.mediaLen > 0) state.mediaPos = Math.min(state.mediaLen, state.mediaPos + 1) }
        Component.onCompleted: running = true
    }

    // instant UI feedback after a media control (toggle/next/prev/seek)
    property Timer mediaRePoll: Timer { interval: 200; repeat: false; onTriggered: mediaGet.running = true }

    // media playback controls (Caelestia-style) — mediaPrev/mediaNext already
    // defined above (line ~560); only the play/pause toggle is new here.
    function mediaTogglePlay() { exec("playerctl play-pause"); mediaRePoll.start() }

    property Process netGet: Process {
        command: ["sh", "-c", "line=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes'); s=$(echo \"$line\" | cut -d: -f2); sig=$(echo \"$line\" | cut -d: -f3); ip=$(hostname -I 2>/dev/null | awk '{print $1}'); printf '%s · %s\\nssid:%s\\nsig:%s' \"${s:-offline}\" \"${ip:-no ip}\" \"${s}\" \"${sig:-0}\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                state.netLine = lines[0] || "…"
                const sid = (lines[1] || "").replace("ssid:", "")
                const sig = parseInt((lines[2] || "").replace("sig:", ""))
                state.wifiSsid = sid
                state.wifiSig = isNaN(sig) ? 0 : sig
            }
        }
    }
    property Timer netTimer: Timer { interval: 10000; running: true; repeat: true; onTriggered: netGet.running = true }

    // tailscale mesh status (valkyx-tailscale-status, 10s poll)
    property bool tsUp: false
    property string tsSelfName: ""
    property string tsSelfIp: ""
    property var tsPeers: []
    property Process tsGet: Process {
        command: [StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/valkyx-tailscale-status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const peers = []
                let up = false, sn = "", si = ""
                lines.forEach(line => {
                    if (line.startsWith("up:")) up = line.slice(3) === "1"
                    else if (line.startsWith("self:")) { const p = line.slice(5).split("|"); sn = p[0] || ""; si = p[1] || "" }
                    else if (line.startsWith("peer:")) { const p = line.slice(5).split("|"); peers.push({ name: p[0] || "", ip: p[1] || "", os: p[2] || "", online: p[3] === "1" }) }
                })
                state.tsUp = up
                state.tsSelfName = sn
                state.tsSelfIp = si
                state.tsPeers = peers
            }
        }
    }
    property Timer tsTimer: Timer { interval: 10000; running: true; repeat: true; onTriggered: tsGet.running = true }

    // network bandwidth up/down (KB/s) — delta over 1s on default-route iface
    property Process netBandGet: Process {
        command: ["sh", "-c",
            "iface=$(ip route 2>/dev/null | awk '/default/{print $5; exit}'); " +
            "r1=$(awk -v i=\"$iface\" '$1 ~ i\":\" {print $2\" \"$10}' /proc/net/dev); sleep 1; " +
            "r2=$(awk -v i=\"$iface\" '$1 ~ i\":\" {print $2\" \"$10}' /proc/net/dev); " +
            "awk -v a=\"$r1\" -v b=\"$r2\" 'BEGIN{split(a,x,\" \");split(b,y,\" \");printf \"%d %d\", (y[1]-x[1])/1024, (y[2]-x[2])/1024}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(" ")
                state.netDownKbs = parseInt(p[0] ?? "0")
                state.netUpKbs = parseInt(p[1] ?? "0")
            }
        }
    }
    property Timer netBandTimer: Timer { interval: 2000; running: ValkyxState.panelLeftOpen; repeat: true; onTriggered: netBandGet.running = true }

    property Process wifiScan: Process {
        command: ["sh", "-c", "nmcli -t -f in-use,ssid,signal,security dev wifi list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                text.trim().split("\n").forEach(line => {
                    const p = line.split(":")
                    if (p.length >= 3 && p[1] !== "") out.push({ use: p[0] === "*", ssid: p[1], sig: parseInt(p[2]), sec: p[3] || "" })
                })
                state.wifiList = out
            }
        }
    }

    // ==================== NETWORK / BT / CAFFEINE drawer data ====================
    // Connect to a wifi ssid (blank password prompt → nmcli asks the user via
    // interactive if needed; we pass the ssid only and let nmcli use saved/ask).
    function connectWifi(ssid) { exec("nmcli dev wifi connect '" + ssid + "'"); refreshSoon2.restart() }

    // arc-fan WiFi strength (Material md-wifi_strength_1..4 = U+F091F/F0922/F0925/F0928).
    // One definition for every wifi surface (topbar pill, popup rows, sidebar drawer).
    function wifiIcon(sig) {
        if (isNaN(sig) || sig <= 0) return "\uDB81\uDDA9"                 // md-wifi (unknown)
        return sig <= 25 ? "\uDB82\uDD1F" : sig <= 50 ? "\uDB82\uDD22"
             : sig <= 75 ? "\uDB82\uDD25" : "\uDB82\uDD28"
    }

    property var btDevices: []     // {mac, name, connected}
    function refreshBt() { btGet.running = true }
    function toggleBtDevice(mac, connected) {
        exec(connected ? "bluetoothctl disconnect " + mac : "bluetoothctl connect " + mac)
        refreshSoon2.restart()
    }

    property Process btGet: Process {
        command: ["sh", "-c",
            "bluetoothctl devices 2>/dev/null | while read -r _ mac name; do " +
            "[ -n \"$mac\" ] || continue; conn=$(bluetoothctl info \"$mac\" 2>/dev/null | grep -q 'Connected: yes' && echo yes || echo no); " +
            "echo \"$mac|$name|$conn\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                text.trim().split("\n").forEach(line => {
                    const p = line.split("|")
                    if (p.length >= 3 && p[0]) out.push({ mac: p[0], name: p[1] || p[0], connected: p[2] === "yes" })
                })
                state.btDevices = out
            }
        }
    }

    // Caffeine: minutes idle is suspended. -1 = on indefinitely, 0 = off. Drawn
    // from the cache so the drawer shows the live state without double-counting.
    property int caffeineMin: 0
    function setCaffeine(min) {
        exec("valkyx-caffeine " + min)
        caffeineMin = min
    }
    property Process caffeineGet: Process {
        command: ["sh", "-c", "cat ~/.cache/valkyx-caffeine.min 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.trim())
                if (!isNaN(v)) state.caffeineMin = v
            }
        }
    }

    property bool gameModeOn: false
    function toggleGameMode() { exec("valkyx-gamemode"); gameModeGet.running = true }
    property Process gameModeGet: Process {
        command: ["sh", "-c", "pgrep -f 'gamemoded -[r]' >/dev/null && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: state.gameModeOn = text.trim() === "on"
        }
    }
    property Timer gameModePoll: Timer {
        interval: 3000; repeat: true; running: true
        onTriggered: gameModeGet.running = true
    }

    property Process notifGet: Process {
        command: ["sh", "-c", "makoctl history 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                const blocks = text.trim().split(/\n(?=Notification )/)
                blocks.forEach(b => {
                    if (!b.startsWith("Notification")) return
                    const first = b.split("\n")[0]
                    const sum = first.replace(/^Notification \d+:\s*/, "")
                    const idm = first.match(/^Notification (\d+):/)
                    const am = b.match(/App name:\s*(.+)/)
                    const dm = b.match(/Desktop entry:\s*(.+)/)
                    const bm = b.match(/\n\s*Body:\s*(.+)/)
                    out.push({
                        id: idm ? parseInt(idm[1]) : 0,
                        app: am ? am[1].trim() : "",
                        summary: sum,
                        desktopEntry: dm ? dm[1].trim() : "",
                        body: bm ? bm[1].trim() : ""
                    })
                })
                if (out.length > 0 && state._lastNotifKey !== "" && out[0].summary !== state._lastNotifKey) {
                        ValkyxEvents.notificationReceived(out[0].summary)
                        state.toastApp = out[0].app
                        state.toastSummary = out[0].summary
                        state.toastGlyph = "\uDB80\uDED9"
                        state.toastVisible = true
                        state.toastHide.restart()
                    }
                if (out.length > 0) state._lastNotifKey = out[0].summary
                state.notifList = out
            }
        }
    }
    property string _lastNotifKey: ""
    property string toastApp: ""
    property string toastSummary: ""
    property string toastGlyph: "\uDB80\uDED9"
    property bool toastVisible: false
    property Timer toastHide: Timer { interval: 4200; onTriggered: state.toastVisible = false }

    // shell-native "connected" toast (nm-applet removed) — arc-fan glyph
    onWifiSsidChanged: {
        if (wifiSsid !== "" && wifiSsid !== "offline") {
            toastGlyph = wifiIcon(wifiSig)
            toastApp = "NETWORK"
            toastSummary = "Connected to " + wifiSsid
            toastVisible = true
            toastHide.restart()
        }
    }

    // battery + memory + cpu + disk + wattage + uptime
    property Process sysGet: Process {
        command: ["sh", "-c",
            "bd=$(ls /sys/class/power_supply/ | grep '^BAT' | head -1); " +
            "bat=$(cat /sys/class/power_supply/$bd/capacity 2>/dev/null || echo -1); " +
            "st=$(cat /sys/class/power_supply/$bd/status 2>/dev/null); " +
            "mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf \"%d\", (t-a)/t*100}' /proc/meminfo); " +
            "c1=$(awk '/^cpu /{print $2\" \"$3\" \"$4\" \"$5\" \"$6}' /proc/stat); sleep 0.4; " +
            "c2=$(awk '/^cpu /{print $2\" \"$3\" \"$4\" \"$5\" \"$6}' /proc/stat); " +
            "cpu=$(awk -v a=\"$c1\" -v b=\"$c2\" 'BEGIN{split(a,x,\" \");split(b,y,\" \");busy=(y[1]-x[1])+(y[2]-x[2])+(y[3]-x[3]);tot=busy+(y[4]-x[4])+(y[5]-x[5]);printf \"%d\",(tot>0?busy/tot*100:0)}'); " +
            "disk=$(df -P / 2>/dev/null | awk 'NR==2{gsub(\"%\",\"\");print $5}'); " +
            "w=$(cat /sys/class/power_supply/$bd/power_now 2>/dev/null | awk '{printf \"%.1f\", $1/1e6}'); " +
            "up=$(awk '{printf \"%dh %02dm\", $1/3600, $1%3600/60}' /proc/uptime); " +
            "echo \"$bat|$st|$mem|$cpu|$disk|$w|$up\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|")
                state.batteryPct = parseFloat(p[0] ?? "-1")
                state.batteryCharging = (p[1] === "Charging")
                state.memPct = parseFloat(p[2] ?? "-1")
                state.cpuPct = parseFloat(p[3] ?? "-1")
                state.diskPct = parseFloat(p[4] ?? "-1")
                state.batWatts = parseFloat(p[5] ?? "-1")
                state.uptimeLine = p[6] ?? ""
            }
        }
    }
    property Timer sysTimer: Timer { interval: 20000; running: true; repeat: true; onTriggered: sysGet.running = true }

    // wallpaper scanner
    property Process wpScan: Process {
        command: ["sh", "-c",
            "ls ~/Pictures/Wallpapers/*.{png,jpg,jpeg,webp} 2>/dev/null" +
            " || true; echo '---IDX---'; cat ~/.cache/valkyx-wallpaper.idx 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("---IDX---")
                const list = (parts[0] || "").trim().split("\n").filter(l => l.length > 0)
                state.wallpaperList = list
                // match current wallpaper by basename against the cache file
                const cur = (parts[1] || "").trim()
                if (cur) {
                    for (let i = 0; i < list.length; i++) {
                        if (list[i].split("/").pop() === cur) {
                            state.currentWallpaperIdx = i
                            return
                        }
                    }
                }
                // fallback: try valkyx-wallpaper
                for (let i = 0; i < list.length; i++) {
                    if (list[i].indexOf("valkyx-wallpaper") >= 0) {
                        state.currentWallpaperIdx = i
                        break
                    }
                }
            }
        }
    }

    // wallpaper luminance → lightMode (adaptive text readability).
    // Samples the blurred wallpaper downscaled to 1px; bright wallpaper ⇒ dark text.
    property bool wallpaperBright: false
    property Process lumScan: Process {
        command: ["sh", "-c",
            "python3 - <<'PY'\n" +
            "from PIL import Image\n" +
            "import os\n" +
            "p = os.path.expanduser('~/.local/share/backgrounds/valkyx-wallpaper.svg')\n" +
            "im = Image.open(p).convert('L').resize((1,1))\n" +
            "print('BRIGHT' if int(im.getpixel((0,0))) >= 140 else 'DARK')\n" +
            "PY"]
        stdout: StdioCollector {
            onStreamFinished: {
                state.wallpaperBright = text.trim().toUpperCase().indexOf("BRIGHT") >= 0
                ValkyxTheme.lightMode = state.wallpaperBright
            }
        }
    }
}
