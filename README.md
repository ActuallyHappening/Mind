# Mind

An iPadOS and macOS app for taking Apple Pencil notes on pdfs, stored as plain
files next to the pdfs in iCloud Drive. The successor to YMap (see
OLD-README.md and PORT.md).

## The idea

I prepare a folder of pdfs: a question, its solutions, some notes. On the iPad
I navigate into that folder in Mind and I'm straight on a canvas with the
first pdf, and I write on and around it. A sidebar, hidden by default, lists
the folder's pdfs; I switch between them and drag them into order, questions
first and solutions last.

Everything is file-focussed and Finder-focussed. My notes are already well
organised in iCloud Drive and stay there, with no separate library and no
copies of the pdfs.

## Requirements

### Note taking

- **R1** Notes are taken on iPad with Apple Pencil; Pencil double-tap switches
  to the eraser.
- **R2** A pdf is shown on a canvas I can draw on and around.
- **R3** The iPad UI is the iCloud Drive folders where my notes already are.
  Opening a folder that holds pdfs shows the canvas.
- **R4** A sidebar, hidden by default, lists the folder's pdfs to switch
  between and reorder.
- **R5** Changes sync between Mac and iPad through iCloud.

### Storage

- **R6** A pdf is never copied or changed. Its drawing lives beside it.
- **R7** Drawing data is stored in Apple's own format (PencilKit), with no
  custom conversion.
- **R8** Everything is future-proof as Apple's systems change.

### Opening and the Mac

- **R9** Double-clicking a `.mind` in Finder, or following a link to it, opens
  it straight in Mind on the Mac. This is a top priority.
- **R10** Opening a `.mind` from the Files app on iPad opens it in Mind.
- **R11** The Mac can view drawings. It does not need to edit them.
- **R12** iPad needs never limit the Mac side. The Mac app is designed on its
  own terms.

### This README

- **R13** Requests and decisions are written down here as the project goes.
- Lines are kept to 80 characters.

## Files

```
Q4/
├── .mind.plist          <- hidden: pdf order and last opened pdf
├── Q4.pdf
├── Q4.mind/             <- the ink for Q4.pdf, found by its name
│   ├── Info.json        <- format version, creation date
│   ├── Drawing.pkdrawing  <- PKDrawing.dataRepresentation(), as-is
│   └── Preview/
│       └── thumbnail.png  <- page 1 with ink; safe to delete
├── Q4 Solutions.pdf
└── Q4 Solutions.mind/
```

- `X.mind` is a package (a folder Finder and Files show as one file). It is
  created on the first stroke on `X.pdf`. Renaming a pdf means renaming its
  `.mind` too.
- Drawings are in points from the top-left of the pdf's first page.
- `.mind.plist` is created when the order is changed or a pdf is opened.
  Without it, and for pdfs it doesn't list, the order is by name with names
  containing the word sol, solution or solutions last.

## Layout

- `MindKit/`: Swift package with the file format, shared by both apps.
- `iOS/`, `macOS/`: the apps. `project.yml` generates `Mind.xcodeproj` with
  XcodeGen; the project is not checked in.
