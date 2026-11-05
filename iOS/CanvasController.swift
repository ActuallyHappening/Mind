import MindKit
import PencilKit
import SwiftUI

final class CanvasHandle {
    weak var controller: CanvasController?
}

struct Canvas: UIViewControllerRepresentable {
    let pdf: URL
    let handle: CanvasHandle

    func makeUIViewController(context: Context) -> CanvasController {
        let controller = CanvasController(pdf: pdf)
        handle.controller = controller
        return controller
    }

    func updateUIViewController(_ controller: CanvasController, context: Context) {}
}

// A pdf with its ink. The X.mind package is created on the first stroke.
final class CanvasController: UIViewController, PKCanvasViewDelegate {
    let canvas = PKCanvasView()
    private let pdf: URL
    private let document: MindDocument
    private let toolPicker = PKToolPicker()
    private var pages: PDFPagesView?
    private let origin = CGPoint(x: 1000, y: 1000) // where the pdf's top-left sits on the canvas
    private var applying = false
    private var creating = false
    private var positioned = false

    init(pdf: URL) {
        self.pdf = pdf
        document = MindDocument(fileURL: MindPackage.url(for: pdf))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.clipsToBounds = true
        view.backgroundColor = .secondarySystemBackground
        canvas.frame = view.bounds
        canvas.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.minimumZoomScale = 0.2
        canvas.maximumZoomScale = 10
        canvas.delegate = self

        document.pdf = (try? MindFiles.read(pdf)).flatMap { CGDataProvider(data: $0 as CFData) }
            .flatMap(CGPDFDocument.init)
        if let pdf = document.pdf {
            let pages = PDFPagesView(pdf: pdf)
            view.addSubview(pages)
            self.pages = pages
        }
        view.addSubview(canvas)

        document.onReload = { [weak self] in self?.show() }
        let placeholder = document.fileURL.deletingLastPathComponent()
            .appending(path: ".\(document.fileURL.lastPathComponent).icloud")
        if FileManager.default.fileExists(atPath: document.fileURL.path)
            || FileManager.default.fileExists(atPath: placeholder.path)
        {
            canvas.isUserInteractionEnabled = false
            try? FileManager.default.startDownloadingUbiquitousItem(at: document.fileURL)
            document.open { [weak self] _ in self?.canvas.isUserInteractionEnabled = true }
        }

        toolPicker.stateAutosaveName = "Mind"
        toolPicker.addObserver(canvas)
        toolPicker.setVisible(true, forFirstResponder: canvas)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        canvas.undoManager?.removeAllActions() // undo steps from the previously shown pdf
        canvas.becomeFirstResponder()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !document.documentState.contains(.closed) { document.close() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !positioned, view.bounds.width > 0 else { return }
        positioned = true
        let gap: CGFloat = 40
        canvas.zoomScale = view.bounds.width / ((pages?.bounds.width ?? 800) + 2 * gap)
        updateLayout()
        let zoom = canvas.zoomScale
        canvas.contentOffset = CGPoint(
            x: (origin.x - gap) * zoom, y: (origin.y - gap) * zoom - canvas.adjustedContentInset.top)
    }

    private func show() {
        applying = true
        canvas.drawing = document.drawing.transformed(using: .init(translationX: origin.x, y: origin.y))
        applying = false
        updateLayout()
    }

    // The canvas extends well past the pdf and the ink, so there is always room to draw.
    private func updateLayout() {
        let zoom = canvas.zoomScale
        var area = CGRect(x: 0, y: 0, width: 2 * origin.x + (pages?.bounds.width ?? 0),
                          height: 2 * origin.y + (pages?.bounds.height ?? 0))
        let ink = canvas.drawing.bounds
        if !ink.isNull { area = area.union(ink.insetBy(dx: -1000, dy: -1000)) }
        canvas.contentSize = CGSize(width: area.maxX * zoom, height: area.maxY * zoom)
        placePages()
    }

    // The pages sit behind the transparent canvas and follow its scrolling and zooming.
    private func placePages() {
        let zoom = canvas.zoomScale
        let offset = canvas.contentOffset
        pages?.transform = CGAffineTransform(scaleX: zoom, y: zoom)
        pages?.frame.origin = CGPoint(x: origin.x * zoom - offset.x, y: origin.y * zoom - offset.y)
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard !applying else { return }
        document.drawing = canvas.drawing.transformed(using: .init(translationX: -origin.x, y: -origin.y))
        if !document.documentState.contains(.closed) {
            document.updateChangeCount(.done)
        } else if !creating {
            creating = true
            document.save(to: document.fileURL, for: .forCreating) { [weak self] _ in
                self?.document.updateChangeCount(.done) // strokes made while it was being created
            }
        }
        updateLayout()
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) { placePages() }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { placePages() }
}

// Pages stacked vertically, drawn as vectors so they stay sharp at any zoom.
final class PDFPagesView: UIView {
    override class var layerClass: AnyClass { CATiledLayer.self }
    private let pages: [(page: CGPDFPage, frame: CGRect)]

    init(pdf: CGPDFDocument) {
        pages = PDFPages.frames(of: pdf)
        let bounds = pages.reduce(CGRect.null) { $0.union($1.frame) }
        super.init(frame: bounds.isNull ? .zero : CGRect(origin: .zero, size: bounds.size))
        backgroundColor = .clear
        isUserInteractionEnabled = false
        let tiled = layer as! CATiledLayer
        tiled.levelsOfDetail = 4
        tiled.levelsOfDetailBias = 5
        tiled.tileSize = CGSize(width: 512, height: 512)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        for (page, frame) in pages where frame.intersects(rect) { PDFPages.draw(page, in: frame, context) }
    }
}
