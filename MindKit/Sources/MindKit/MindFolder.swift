import Foundation

// A folder of pdfs, with its hidden .mind.plist.
public enum MindFolder {
    public struct Index: Codable, Equatable {
        public var order: [String] = []
        public var lastOpened: String?
        public init(order: [String] = [], lastOpened: String? = nil) {
            self.order = order
            self.lastOpened = lastOpened
        }
    }

    public static func indexURL(_ folder: URL) -> URL { folder.appending(path: ".mind.plist") }

    // Visible items, with iCloud items not yet downloaded (".Name.pdf.icloud") under their real names.
    public static func listing(_ folder: URL) -> [URL] {
        let found = (try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        return found.compactMap { item in
            let name = item.lastPathComponent
            guard name.hasPrefix(".") else { return item }
            guard name.hasSuffix(".icloud") else { return nil }
            let real = String(name.dropFirst().dropLast(".icloud".count))
            return real.hasPrefix(".") ? nil : folder.appendingPathComponent(real, isDirectory: !real.contains("."))
        }
        .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    public static func pdfs(in folder: URL) -> [String] {
        listing(folder).map(\.lastPathComponent).filter { $0.lowercased().hasSuffix(".pdf") }
    }

    // The index's order for pdfs it lists, then the rest in the default order.
    public static func arranged(_ pdfs: [String], by index: Index) -> [String] {
        let kept = index.order.filter(pdfs.contains)
        return kept + defaultOrder(pdfs.filter { !kept.contains($0) })
    }

    // By name, solutions last.
    public static func defaultOrder(_ names: [String]) -> [String] {
        names.sorted { a, b in
            isSolution(a) == isSolution(b) ? a.localizedStandardCompare(b) == .orderedAscending : isSolution(b)
        }
    }

    static func isSolution(_ name: String) -> Bool {
        (name as NSString).deletingPathExtension.contains(#/(?i)(^|[^a-z])sol(ution)?s?([^a-z]|$)/#)
    }

    public static func readIndex(_ folder: URL) -> Index {
        guard let data = try? MindFiles.read(indexURL(folder)) else { return Index() }
        return (try? PropertyListDecoder().decode(Index.self, from: data)) ?? Index()
    }

    public static func writeIndex(_ index: Index, to folder: URL) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(index)
        try MindFiles.write(indexURL(folder)) { try data.write(to: $0, options: .atomic) }
    }
}

// Coordinated access, which also downloads iCloud files first if needed.
public enum MindFiles {
    public static func read(_ url: URL) throws -> Data {
        var error: NSError?
        var result: Result<Data, Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { url in
            result = Result { try Data(contentsOf: url) }
        }
        if let error { throw error }
        return try result!.get()
    }

    public static func write(_ url: URL, _ write: (URL) throws -> Void) throws {
        var error: NSError?
        var result: Result<Void, Error>?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &error) { url in
            result = Result { try write(url) }
        }
        if let error { throw error }
        try result!.get()
    }
}
