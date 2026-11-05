import CoreGraphics
import PencilKit

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

// A pdf's pages stacked top to bottom, in points, as laid out under the ink.
public enum PDFPages {
    public static let gap: CGFloat = 24

    public static func frames(of pdf: CGPDFDocument) -> [(page: CGPDFPage, frame: CGRect)] {
        var y: CGFloat = 0
        return (0..<pdf.numberOfPages).compactMap { pdf.page(at: $0 + 1) }.map { page in
            let frame = CGRect(origin: CGPoint(x: 0, y: y), size: size(of: page))
            y = frame.maxY + gap
            return (page, frame)
        }
    }

    public static func size(of page: CGPDFPage) -> CGSize {
        let box = page.getBoxRect(.cropBox)
        return page.rotationAngle % 180 == 0 ? box.size : CGSize(width: box.height, height: box.width)
    }

    // For a context whose origin is top-left, y down.
    public static func draw(_ page: CGPDFPage, in rect: CGRect, _ context: CGContext) {
        context.saveGState()
        context.translateBy(x: rect.minX, y: rect.maxY)
        context.scaleBy(x: 1, y: -1)
        drawUpright(page, size: rect.size, context)
        context.restoreGState()
    }

    // The pages and ink inside `region`, on a light grey background.
    public static func image(of pages: [(page: CGPDFPage, frame: CGRect)], in region: CGRect, with drawing: PKDrawing,
                             scale: CGFloat) -> CGImage?
    {
        guard let context = CGContext(
            data: nil, width: Int(region.width * scale), height: Int(region.height * scale), bitsPerComponent: 8,
            bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        context.scaleBy(x: scale, y: scale)
        context.setFillColor(CGColor(gray: 0.95, alpha: 1))
        context.fill(CGRect(origin: .zero, size: region.size))
        for (page, frame) in pages where frame.intersects(region) {
            context.saveGState()
            context.translateBy(x: frame.minX - region.minX, y: region.maxY - frame.maxY)
            drawUpright(page, size: frame.size, context)
            context.restoreGState()
        }
        if let ink = ink(drawing, region, scale) {
            context.draw(ink, in: CGRect(origin: .zero, size: region.size))
        }
        return context.makeImage()
    }

    // For a context whose origin is bottom-left, y up.
    private static func drawUpright(_ page: CGPDFPage, size: CGSize, _ context: CGContext) {
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))
        context.concatenate(page.getDrawingTransform(
            .cropBox, rect: CGRect(origin: .zero, size: size), rotate: 0, preserveAspectRatio: true))
        context.drawPDFPage(page)
    }

    // PencilKit adapts ink colours to dark mode unless rendered as light.
    private static func ink(_ drawing: PKDrawing, _ rect: CGRect, _ scale: CGFloat) -> CGImage? {
        #if canImport(UIKit)
        var image: CGImage?
        UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
            image = drawing.image(from: rect, scale: scale).cgImage
        }
        return image
        #else
        var image: CGImage?
        NSAppearance(named: .aqua)!.performAsCurrentDrawingAppearance {
            image = drawing.image(from: rect, scale: scale).cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
        return image
        #endif
    }
}
