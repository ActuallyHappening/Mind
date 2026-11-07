# QCAA past papers to one pdf per question

DRAFT: written before any paper was converted (QCAA's site was unreachable
from the cloud session). The first agent to convert a real paper must revise
this file from what it actually did, then the rest follow it.

## Goal

Each QCAA past-paper question becomes its own tightly cropped pdf with a
transparent background, to write on in Mind. Each is tagged with the unit,
topic and syllabus dot points it tests, and its answer is cross-checked
against the marking guide.

## Layout

```
QCAA/
├── qcaa.sty, build.sh, template.tex   <- shared by all subjects
└── <Subject>/
    ├── Source/        <- QCAA's pdfs, renamed as below, never edited
    ├── Syllabus.tex, Syllabus.pdf
    └── Questions/
        ├── 2025 Paper 1 Multiple Choice Question Booklet - Q3.tex
        ├── 2025 Paper 1 Multiple Choice Question Booklet - Q3.pdf
        └── index.tsv  <- file, topic, dot points, answer (from build.sh)
```

Source names: `<year> Paper <n> Multiple Choice Question Booklet.pdf`,
`<year> Paper <n> Question and Response Booklet.pdf`,
`<year> Paper <n> Marking Guide.pdf`, `Syllabus.pdf`, `Formula Book.pdf`.
Question files take the booklet's name plus ` - Q<n>`.

## Syllabus

`Syllabus.tex`: one `\section` per unit, `\subsection` per topic,
`\subsubsection` per subject-matter heading, an `itemize` of dot points,
verbatim. Each dot point gets an id `U<unit>T<topic>-<k>`, k counting from 1
through the whole topic (ignoring subheadings), written as `\item[U3T2-5]`.
The orchestrating agent reads only the section/subsection lines and ids
(`grep -n 'section\|item\[' Syllabus.tex`) to classify questions.

## Converting a question

Start from `QCAA/template.tex`. Rules:

- Text and maths in LaTeX, verbatim, including the marks.
- Diagrams, graphs and tables that are hard to typeset: `\sourcefig` cuts
  them from the source pdf as vectors (find the box with
  `pdftotext -bbox-layout`), no redrawing.
- Multiple choice: `options` environment. Response questions: keep the
  part labels (a), (b)(i); drop the blank response space and lines.
- `\qcaa{Unit 3 Topic 2: <name>}{U3T2-4, U3T2-5}{<answer>}`: the answer
  is the MC letter or a short final result from the marking guide.
- One question per file; a question spanning pages is still one file.

## Build and check

```
QCAA/build.sh "QCAA/<Subject>/Questions"
```

`standalone` crops to the content (1pt border); pdfs have no page fill, so
the background is transparent. Check a few pdfs by rendering
(`pdftoppm -png -r 80`) and looking; check `index.tsv` has no empty fields
and every MC answer is A–D.

## Saving tokens

- Extract text with `pdftotext -layout`; only look at page images for
  diagrams and to check a build.
- Subagents get one booklet each, plus this file and the syllabus ids,
  not the whole syllabus.
- `\sourcefig` instead of redrawing figures in TikZ.
- Classify from the dot point ids list, not the full syllabus text.
