// WallpaperApi — Wallhaven API client (SFW, no key required).
// Uses curl via Process (matches the codebase pattern; QML XHR proved unreliable here).
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: api

    readonly property string baseUrl: "https://wallhaven.cc/api/v1"
    // Server-side tag exclusions appended to every query (Wallhaven supports
    // `-tag` in the q param; excludeIds is NOT a real API param).
    readonly property string bannedQuery: "-horror -gore -creepy -scary -nightmare -zombie -skull -skeleton -demon -monster -blood -dead -haunted -cursed -satanic -psycho -nude -ecchi -bikini -lingerie -underwear -sleepwear"
    readonly property var bannedTags: [
        // Client-side backstop in case a tag slips through the q filter.
        "horror", "gore", "blood", "skull", "skeleton", "zombie", "ghost",
        "creepy", "scary", "monster", "demon", "satanic", "dark fantasy",
        "clown", "doll", "haunted", "deceased", "corpse", "torture", "dead",
        "nude", "nudity", "ecchi", "bikini", "lingerie", "underwear", "nsfw", "sexy"
    ]
    property var results: []
    property int page: 1
    property bool loading: false
    property string lastQuery: ""
    property bool hasMore: true

    property int _seq: 0

    function search(query) {
        lastQuery = query.trim()
        page = 1
        hasMore = true
        _startFetch(lastQuery, 1)
    }

    function nextPage() {
        if (!loading && hasMore) {
            page++
            _startFetch(lastQuery, page)
        }
    }

    function _startFetch(query, pg) {
        loading = true
        _seq++
        let fq = query.trim()
        if (fq.length > 0) fq += " "
        fq += bannedQuery
        let url = baseUrl + "/search?sorting=toplist&purity=sfw&categories=100&page=" + pg
        url += "&q=" + encodeURIComponent(fq)
        searchProc.command = ["curl", "-s", "--max-time", "15", url]
        searchProc.running = true
    }

    property Process searchProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                const items = []
                try {
                    const json = JSON.parse(text)
                    ;(json.data || []).forEach(function(w) {
                        const tags = (w.tags || []).map(function(t) { return String(t.name || t).toLowerCase() })
                        if (tags.some(function(t) { return api.bannedTags.indexOf(t) >= 0 })) return
                        items.push({
                            id: w.id,
                            thumb: w.thumbs ? w.thumbs.large : "",
                            full: w.path || "",
                            resolution: w.resolution || "",
                            category: w.category || ""
                        })
                    })
                    const meta = json.meta || {}
                    if (page === 1) {
                        api.results = items
                    } else {
                        api.results = api.results.concat(items)
                    }
                    api.hasMore = page < (meta.last_page || 1)
                } catch (e) {
                    if (page === 1) api.results = []
                    api.hasMore = false
                }
                api.loading = false
            }
        }
    }
}
