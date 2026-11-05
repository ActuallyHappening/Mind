import MindKit
import PencilKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct MindApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MindFile.self) { file in
            if let url = file.fileURL { Viewer(drawing: file.document.drawing, pdf: MindPackage.pdf(for: url)) }
        }
    }
}

struct MindFile: FileDocument {
    static let readableContentTypes = [UTType(exportedAs: "com.calebyates.mind")]
    let drawing: PKDrawing

    init(configuration: ReadConfiguration) throws {
        drawing = try MindPackage.drawing(in: configuration.file)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.featureUnsupported)
    }
}

// The pdf's pages with the ink, including ink drawn around them, in strips.
struct Viewer: View {
    let drawing: PKDrawing
    let pdf: URL
    @State private var strips: [CGImage] = []
    @State private var width: CGFloat = 0
    @State private var missing = false

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            VStack(spacing: 0) {
                ForEach(strips.indices, id: \.self) { i in
                    Image(decorative: strips[i], scale: 2)
                }
            }
        }
        .overlay { if missing { ContentUnavailableView("\(pdf.lastPathComponent) Not Found", systemImage: "doc") } }
        .frame(minWidth: 500, minHeight: 600)
        .task { render() }
    }

    private func render() {
        guard let data = try? MindFiles.read(pdf), let provider = CGDataProvider(data: data as CFData),
              let document = CGPDFDocument(provider)
        else { missing = true; return }
        let pages = PDFPages.frames(of: document)
        var area = pages.reduce(CGRect.null) { $0.union($1.frame) }
        if !drawing.bounds.isNull { area = area.union(drawing.bounds.insetBy(dx: -20, dy: -20)) }
        let height: CGFloat = 1000
        strips = stride(from: area.minY, to: area.maxY, by: height).compactMap { y in
            let strip = CGRect(x: area.minX, y: y, width: area.width, height: min(height, area.maxY - y))
            return PDFPages.image(of: pages, in: strip, with: drawing, scale: 2)
        }
    }
}
