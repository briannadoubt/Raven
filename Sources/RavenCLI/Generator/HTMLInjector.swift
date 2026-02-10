import Foundation

enum HTMLInjector {
    /// Injects a `<script id="__raven_asset_manifest">...</script>` into the given HTML if not already present.
    static func injectAssetScriptIfNeeded(html: String, script: String) -> String {
        guard !script.isEmpty else { return html }
        if html.contains("id=\"__raven_asset_manifest\"") { return html }

        let tag = "<script id=\"__raven_asset_manifest\">\n\(script)\n</script>\n"

        if let headRange = html.range(of: "<head>") {
            let insertIndex = headRange.upperBound
            return String(html[..<insertIndex]) + "\n" + tag + String(html[insertIndex...])
        }

        if html.contains("</head>") {
            return html.replacingOccurrences(of: "</head>", with: "\(tag)</head>")
        }

        if html.contains("</body>") {
            return html.replacingOccurrences(of: "</body>", with: "\(tag)</body>")
        }

        return tag + html
    }
}

