import MindKit
import PencilKit
import UIKit

// The X.mind package beside X.pdf.
final class MindDocument: UIDocument {
    var drawing = PKDrawing()
    var pdf: CGPDFDocument? // for the thumbnail
    var onReload: (() -> Void)?
    private var package: FileWrapper?

    override init(fileURL url: URL) {
        super.init(fileURL: url)
        NotificationCenter.default.addObserver(
            self, selector: #selector(stateChanged), name: UIDocument.stateChangedNotification, object: self)
    }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let package = contents as? FileWrapper else { throw CocoaError(.fileReadCorruptFile) }
        drawing = try MindPackage.drawing(in: package)
        self.package = package
        onReload?()
    }

    override func contents(forType typeName: String) throws -> Any {
        package = try MindPackage.fileWrapper(updating: package, drawing: drawing, pdf: pdf)
        return package!
    }

    // Edits from two devices at once: keep this device's version.
    @objc private func stateChanged() {
        guard documentState.contains(.inConflict) else { return }
        try? NSFileVersion.removeOtherVersionsOfItem(at: fileURL)
        NSFileVersion.unresolvedConflictVersionsOfItem(at: fileURL)?.forEach { $0.isResolved = true }
    }
}
