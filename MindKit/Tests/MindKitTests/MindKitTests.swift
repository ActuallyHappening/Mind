import Foundation
import PencilKit
import Testing
@testable import MindKit

@Test func solutionsComeLast() {
    let names = ["Q4 Solutions.pdf", "Q4_sol.pdf", "Q4.pdf", "Console.pdf", "SOL.pdf", "Solve.pdf", "q10.pdf", "q2.pdf"]
    #expect(MindFolder.defaultOrder(names) ==
        ["Console.pdf", "q2.pdf", "Q4.pdf", "q10.pdf", "Solve.pdf", "Q4 Solutions.pdf", "Q4_sol.pdf", "SOL.pdf"])
}

@Test func storedOrderFirstThenNewPdfs() {
    let index = MindFolder.Index(order: ["B Solution.pdf", "Gone.pdf", "A.pdf"])
    #expect(MindFolder.arranged(["A.pdf", "B Solution.pdf", "C.pdf", "C sol.pdf"], by: index) ==
        ["B Solution.pdf", "A.pdf", "C.pdf", "C sol.pdf"])
}

@Test func listingHidesDotfilesAndNamesPlaceholders() throws {
    let folder = try temporaryFolder()
    for name in ["A.pdf", ".B.pdf.icloud", ".mind.plist", "..mind.plist.icloud", ".DS_Store", "A.mind", "notes.txt"] {
        try Data().write(to: folder.appending(path: name))
    }
    #expect(MindFolder.listing(folder).map(\.lastPathComponent) == ["A.mind", "A.pdf", "B.pdf", "notes.txt"])
    #expect(MindFolder.pdfs(in: folder) == ["A.pdf", "B.pdf"])
}

@Test func indexRoundTrips() throws {
    let folder = try temporaryFolder()
    #expect(MindFolder.readIndex(folder) == MindFolder.Index())
    let index = MindFolder.Index(order: ["Q.pdf", "S.pdf"], lastOpened: "S.pdf")
    try MindFolder.writeIndex(index, to: folder)
    #expect(MindFolder.readIndex(folder) == index)
}

@Test func packageIsNamedAfterItsPdf() {
    let pdf = URL(filePath: "/notes/Q4 v2.pdf")
    #expect(MindPackage.url(for: pdf).path == "/notes/Q4 v2.mind")
    #expect(MindPackage.pdf(for: URL(filePath: "/notes/Q4 v2.mind/", directoryHint: .isDirectory)).path
        == "/notes/Q4 v2.pdf")
}

@Test func packageRoundTripsDrawingAndMakesThumbnail() throws {
    let point = PKStrokePoint(location: CGPoint(x: 10, y: 10), timeOffset: 0, size: CGSize(width: 4, height: 4),
                              opacity: 1, force: 1, azimuth: 0, altitude: .pi / 2)
    let stroke = PKStroke(ink: PKInk(.pen, color: .black),
                          path: PKStrokePath(controlPoints: [point, point], creationDate: Date()))
    let wrapper = try MindPackage.fileWrapper(
        updating: nil, drawing: PKDrawing(strokes: [stroke]), pdf: onePagePDF())
    let package = try temporaryFolder().appending(path: "Q.mind")
    try wrapper.write(to: package, options: .atomic, originalContentsURL: nil)

    let read = try FileWrapper(url: package)
    #expect(try MindPackage.drawing(in: read).strokes.count == 1)
    #expect(read.fileWrappers?["Info.json"] != nil)
    #expect(read.fileWrappers?["Preview"]?.fileWrappers?["thumbnail.png"]?.regularFileContents?.isEmpty == false)
}

private func temporaryFolder() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func onePagePDF() -> CGPDFDocument {
    let data = NSMutableData()
    var box = CGRect(x: 0, y: 0, width: 200, height: 300)
    let context = CGContext(consumer: CGDataConsumer(data: data)!, mediaBox: &box, nil)!
    context.beginPDFPage(nil)
    context.fill(CGRect(x: 20, y: 20, width: 50, height: 50))
    context.endPDFPage()
    context.closePDF()
    return CGPDFDocument(CGDataProvider(data: data)!)!
}
