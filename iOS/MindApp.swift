import MindKit
import SwiftUI

@main
struct MindApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

struct RootView: View {
    @AppStorage("rootBookmark") private var bookmark: Data?
    @State private var root: URL?
    @State private var path: [URL] = []
    @State private var picking = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let root {
                    FolderScreen(folder: root)
                } else {
                    ContentUnavailableView {
                        Label("No Folder", systemImage: "folder")
                    } description: {
                        Text("Choose the iCloud Drive folder that holds your notes.")
                    } actions: {
                        Button("Choose Folder") { picking = true }
                    }
                }
            }
            .navigationDestination(for: URL.self) { FolderScreen(folder: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Change Folder", systemImage: "folder.badge.gearshape") { picking = true }
                }
            }
        }
        .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result { open(url) }
        }
        .onOpenURL(perform: show)
        .onAppear(perform: restore)
    }

    private func open(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        root?.stopAccessingSecurityScopedResource()
        root = url
        path = []
        bookmark = try? url.bookmarkData()
    }

    private func restore() {
        guard root == nil, let bookmark else { return }
        var stale = false
        if let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &stale) {
            open(url)
            if stale { self.bookmark = try? url.bookmarkData() }
        }
    }

    // A .mind opened from Files: show its folder at its pdf. Works inside the chosen folder.
    private func show(_ package: URL) {
        _ = package.startAccessingSecurityScopedResource()
        let folder = package.deletingLastPathComponent()
        var index = MindFolder.readIndex(folder)
        index.lastOpened = MindPackage.pdf(for: package).lastPathComponent
        try? MindFolder.writeIndex(index, to: folder)
        path.append(folder)
    }
}
