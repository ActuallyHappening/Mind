import MindKit
import SwiftUI

// A folder with pdfs opens on the canvas; otherwise it lists its subfolders.
struct FolderScreen: View {
    let folder: URL
    @State private var pdfs: [String] = []
    @State private var order: [String] = [] // as stored; only set once the pdfs are reordered by hand
    @State private var folders: [URL] = []
    @State private var selected: String?
    @State private var sidebar = false
    @State private var loaded = false
    @State private var handle = CanvasHandle()

    var body: some View {
        Group {
            if !loaded {
                ProgressView()
            } else if pdfs.isEmpty {
                List(folders, id: \.self) { folder in
                    NavigationLink(value: folder) { Label(folder.lastPathComponent, systemImage: "folder") }
                }
                .overlay {
                    if folders.isEmpty { ContentUnavailableView("No PDFs", systemImage: "doc.richtext") }
                }
            } else {
                notebook
            }
        }
        .navigationTitle(selected.map { ($0 as NSString).deletingPathExtension } ?? folder.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .task { load() }
        .refreshable { load() }
    }

    private var notebook: some View {
        HStack(spacing: 0) {
            if sidebar {
                List(selection: $selected) {
                    Section {
                        ForEach(pdfs, id: \.self) { name in
                            Label((name as NSString).deletingPathExtension, systemImage: "doc.richtext")
                        }
                        .onMove { pdfs.move(fromOffsets: $0, toOffset: $1); order = pdfs; save() }
                    } header: {
                        HStack { Text(folder.lastPathComponent); Spacer(); EditButton() }
                    }
                    if !folders.isEmpty {
                        Section("Folders") {
                            ForEach(folders, id: \.self) { folder in
                                NavigationLink(value: folder) { Label(folder.lastPathComponent, systemImage: "folder") }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                .frame(width: 280)
                .transition(.move(edge: .leading))
                Divider()
            }
            if let selected {
                Canvas(pdf: folder.appending(path: selected), handle: handle)
                    .id(selected)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("PDFs", systemImage: "sidebar.left") { withAnimation { sidebar.toggle() } }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Undo", systemImage: "arrow.uturn.backward") { handle.controller?.canvas.undoManager?.undo() }
                Button("Redo", systemImage: "arrow.uturn.forward") { handle.controller?.canvas.undoManager?.redo() }
            }
        }
        .onChange(of: selected) { save() }
    }

    private func load() {
        let items = MindFolder.listing(folder)
        folders = items.filter { $0.hasDirectoryPath && $0.pathExtension != "mind" }
        let index = MindFolder.readIndex(folder)
        order = index.order
        pdfs = MindFolder.arranged(MindFolder.pdfs(in: folder), by: index)
        selected = index.lastOpened.flatMap { pdfs.contains($0) ? $0 : nil } ?? pdfs.first
        if !loaded { sidebar = !folders.isEmpty } // open at first when there are subfolders to reach
        loaded = true
    }

    private func save() {
        let index = MindFolder.Index(order: order, lastOpened: selected)
        guard index != MindFolder.readIndex(folder) else { return }
        try? MindFolder.writeIndex(index, to: folder)
    }
}
