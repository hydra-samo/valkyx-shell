pragma Singleton
// VALKYX WallpaperStore — media catalogue for the wallpaper selector (Super+W).
// Scans ~/Pictures/Wallpapers for stills/gifs/videos, lazily materialises ffmpeg
// poster thumbs for animated media, and answers "which thumbnail url".
// Applying goes through ValkyxState.setWallpaper (kind-dispatch lives there).
import QtQuick
import Quickshell.Io

QtObject {
    id: store

    readonly property string wallDir: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/Pictures/Wallpapers"
    readonly property string thumbDir: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/valkyx-wallthumbs"

    // full local catalogue: { path, name, kind }  ("image" | "gif" | "video")
    property var mediaList: []
    property bool scanning: false

    // hue extraction: path -> [hex,...] dominant colors (iNiR-style dots)
    property var hues: ({})
    // favorites: array of paths persisted via valkyx-wallfavs
    property var favs: []

    signal mediaChanged()
    signal posterGenerated(string path)
    signal colorsReady(string path)
    signal favListChanged()

    function kindOf(path) {
        const l = String(path ?? "").toLowerCase()
        if (l.endsWith(".gif")) return "gif"
        if (l.endsWith(".mp4") || l.endsWith(".webm") || l.endsWith(".mkv")
            || l.endsWith(".mov") || l.endsWith(".avi")) return "video"
        return "image"
    }

    function cachedPosterPath(path) {
        // Key by FULL path, not basename: every omarchy theme ships a file called
        // `omarchy.webp`, so basename keys collided onto one shared thumb and the
        // picker showed the same image once per theme.
        return thumbDir + "/" + String(path).replace(/[^A-Za-z0-9._-]/g, "_") + ".jpg"
    }

    function colorsFor(path) { return store.hues[path] || [] }
    function isFav(path) { return store.favs.indexOf(path) >= 0 }

    // toggle + optimistic local update (mirrors the persisted file)
    function toggleFav(path) {
        favProc.command = ["valkyx-wallfavs", "toggle", path]
        favProc.running = true
        const f = store.favs.slice()
        const i = f.indexOf(path)
        if (i >= 0) f.splice(i, 1)
        else f.push(path)
        store.favs = f
        store.favListChanged()
    }

    // Poster URL for a catalogue entry — stills keep the raw file as an
    // instant fallback but prefer the cached thumb; animated media point at
    // the ffmpeg cache (blank until generated).
    function posterFor(path) {
        const kind = kindOf(path)
        const cached = cachedPosterPath(path)
        if (_posterDone[cached]) return "file://" + cached
        ensurePoster(path)
        if (kind === "image") return "file://" + path
        return ""
    }

    // ── scan ──
    property Process scanProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                const list = []
                const images = []
                for (const raw of text.split("\n")) {
                    const p = raw.trim()
                    if (p.length === 0) continue
                    list.push({ path: p, name: p.split("/").pop(), kind: store.kindOf(p) })
                    if (store.kindOf(p) === "image") images.push(p)
                }
                store.mediaList = list
                store.scanning = false
                store.mediaChanged()
                store.scanHues(images)
                // pre-warm: generate missing thumbs for the whole catalogue so the
                // selector opens instantly (thumbs persist on disk between runs)
                for (const m of list) store.ensurePoster(m.path)
            }
        }
    }

    function scan() {
        scanning = true
        scanProc.command = ["sh", "-c",
            "find '" + wallDir + "' -type f \\(" +
            " -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp'" +
            " -o -iname '*.bmp' -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm'" +
            " -o -iname '*.mkv' -o -iname '*.mov' -o -iname '*.avi' \\) -printf '%p\\n' | sort"]
        scanProc.running = true
    }

    // ── hue extraction queue (one at a time, mirrors the poster queue) ──
    property var _hueQueue: []
    property bool _hueBusy: false
    property string _hueSrc: ""

    function scanHues(imagePaths) {
        const next = []
        for (const p of imagePaths) {
            if (!store.hues[p] && !store._hueQueue.some(e => e === p)) next.push(p)
        }
        store._hueQueue = store._hueQueue.concat(next)
        store._runHue()
    }

    function ensureHue(path) {
        if (store.hues[path] || store._hueQueue.some(e => e === path)) return
        store._hueQueue.push(path)
        store._runHue()
    }

    function _runHue() {
        if (_hueBusy || _hueQueue.length === 0) return
        _hueBusy = true
        _hueSrc = _hueQueue.shift()
        hueProc.command = ["valkyx-wallhues", _hueSrc]
        hueProc.running = true
    }

    property Process hueProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                let arr = []
                try { arr = JSON.parse(text) || [] } catch (e) {}
                store.hues[store._hueSrc] = arr
                const done = store._hueSrc
                store._hueBusy = false
                Qt.callLater(function() {
                    store._runHue()
                    store.colorsReady(done)
                })
            }
        }
    }

    // ── favorites file (loaded once at start) ──
    property Process favLoad: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                const list = []
                for (const raw of text.split("\n")) {
                    const p = raw.trim()
                    if (p.length) list.push(p)
                }
                store.favs = list
                store.favListChanged()
            }
        }
    }

    property Process favProc: Process {}

    // ── poster generation queue (one ffmpeg at a time) ──
    property var _posterDone: ({})
    property var _posterQueue: []
    property bool _posterBusy: false
    property string _posterSrc: ""
    property string _posterCached: ""

    // seed _posterDone from thumbs already on disk (survives shell restarts)
    property Process posterSeed: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                const done = {}
                for (const raw of text.split("\n")) {
                    const f = raw.trim()
                    if (f.length) done[thumbDir + "/" + f] = true
                }
                store._posterDone = done
            }
        }
    }

    function ensurePoster(path) {
        const cached = cachedPosterPath(path)
        if (_posterDone[cached] || _posterQueue.some(e => e.cached === cached)) return
        _posterQueue.push({ src: path, cached: cached })
        _runNext()
    }

    function _runNext() {
        if (_posterBusy || _posterQueue.length === 0) return
        _posterBusy = true
        const item = _posterQueue.shift()
        _posterSrc = item.src
        _posterCached = item.cached
        // stills: no -ss (seeks past the only frame); animated: grab frame 0.3s in
        const seek = store.kindOf(item.src) === "image" ? "" : "-ss 0.3 "
        posterProc.command = ["sh", "-c",
            "mkdir -p '" + thumbDir + "' && ffmpeg -y -loglevel error " + seek +
            "-i '" + item.src + "' -frames:v 1 -vf scale=640:-1 -pix_fmt yuvj420p -q:v 4 -f image2 '" + item.cached + "'"]
        posterProc.running = true
    }

    property Process posterProc: Process {
        stdout: StdioCollector {}
        onExited: {
            store._posterDone[store._posterCached] = true
            store._posterBusy = false
            const done = store._posterSrc
            const poster = store._posterCached
            Qt.callLater(function() {
                store._runNext()
                store.posterGenerated(done)
                store.ensureHue(poster)   // hue is computed on the generated thumb
            })
        }
    }

    Component.onCompleted: {
        scan()
        posterSeed.command = ["sh", "-c", "ls '" + thumbDir + "' 2>/dev/null"]
        posterSeed.running = true
        favLoad.command = ["valkyx-wallfavs", "list"]
        favLoad.running = true
    }
}