import Foundation

protocol SpotlightSearching {
    /// Returns `.app` bundle URLs reported by Spotlight inside the given roots.
    func applicationBundleURLs(in roots: [URL]) -> [URL]
}

/// Uses the `mdfind` command-line tool to ask Spotlight for application
/// bundles. This supplements the directory scan and does not rely on any
/// private API.
struct SpotlightApplicationSearch: SpotlightSearching {
    func applicationBundleURLs(in roots: [URL]) -> [URL] {
        guard !roots.isEmpty else { return [] }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        var arguments: [String] = []
        for root in roots {
            arguments.append("-onlyin")
            arguments.append(root.path)
        }
        arguments.append("kMDItemContentType == 'com.apple.application-bundle'")
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0,
              let output = String(data: data, encoding: .utf8) else {
            return []
        }

        return output
            .split(separator: "\n")
            .map { URL(fileURLWithPath: String($0)) }
    }
}
