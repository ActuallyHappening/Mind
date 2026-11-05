import Foundation
import ImageIO
import PencilKit
import UniformTypeIdentifiers

// X.mind holds the drawing for X.pdf beside it, in points from the top-left of the pdf's first page.
public enum MindPackage {
    public struct Info: Codable {
        public var formatVersion = 1
        public var created = Date()
    }

    public static func url(for pdf: URL) -> URL { sibling(of: pdf, extension: "mind") }
    public static func pdf(for package: URL) -> URL { sibling(of: package, extension: "pdf") }

    private static func sibling(of url: URL, extension ext: String) -> URL {
        url.deletingLastPathComponent().appending(path: url.deletingPathExtension().lastPathComponent + "." + ext)
    }

    public static func drawing(in package: FileWrapper) throws -> PKDrawing {
        try package.fileWrappers?["Drawing.pkdrawing"]?.regularFileContents.map(PKDrawing.init(data:)) ?? PKDrawing()
    }

    public static func fileWrapper(updating package: FileWrapper?, drawing: PKDrawing, pdf: CGPDFDocument?) throws
        -> FileWrapper
    {
        let package = package ?? FileWrapper(directoryWithFileWrappers: [:])
        if package.fileWrappers?["Info.json"] == nil {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            replace("Info.json", in: package, with: try encoder.encode(Info()))
        }
        replace("Drawing.pkdrawing", in: package, with: drawing.dataRepresentation())
        if let page = pdf?.page(at: 1), let thumbnail = thumbnail(page, drawing) {
            let preview = package.fileWrappers?["Preview"] ?? {
                let folder = FileWrapper(directoryWithFileWrappers: [:])
                folder.preferredFilename = "Preview"
                package.addFileWrapper(folder)
                return folder
            }()
            replace("thumbnail.png", in: preview, with: thumbnail)
        }
        return package
    }

    private static func replace(_ name: String, in folder: FileWrapper, with data: Data) {
        if let old = folder.fileWrappers?[name] { folder.removeFileWrapper(old) }
        let file = FileWrapper(regularFileWithContents: data)
        file.preferredFilename = name
        folder.addFileWrapper(file)
    }

    private static func thumbnail(_ page: CGPDFPage, _ drawing: PKDrawing) -> Data? {
        let size = PDFPages.size(of: page)
        guard let image = PDFPages.image(of: page, in: CGRect(origin: .zero, size: size), with: drawing,
                                         scale: 600 / max(size.width, size.height))
        else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)
        else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination) ? data as Data : nil
    }
}
