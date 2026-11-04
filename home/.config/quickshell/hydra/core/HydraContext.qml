pragma Singleton
// VALKYX context engine — workspace+app → UI behavioral rules.
// Components bind to rule() instead of hardcoded context checks.
import QtQuick

QtObject {
    // Per-context UI rules: dock, blur, notifications, hud, osd, sidebar
    readonly property var rules: ({
        "normal":     { dock: true,  blur: true,  notifications: true,  hud: true,  osd: true,  sidebar: true },
        "creative":   { dock: true,  blur: true,  notifications: true,  hud: true,  osd: true,  sidebar: true },
        "gaming":     { dock: false, blur: false, notifications: false, hud: false, osd: true,  sidebar: true },
        "fullscreen": { dock: false, blur: false, notifications: false, hud: false, osd: true,  sidebar: true }
    })

    // Default fallback for unknown contexts
    readonly property var _default: ({ dock: true, blur: true, notifications: true, hud: true, osd: true, sidebar: true })

    // Look up a rule for the given context. Usage: ValkyxContext.rule(ctx, "dock")
    function rule(ctx, key) {
        var r = rules[ctx]
        if (!r) r = _default
        return r[key] !== undefined ? r[key] : _default[key]
    }
}
