# QCAA questions for Mind

Requests and decisions for the question pdfs. How to make them: AGENTS.md.

## Requests

- Every QCAA past paper for a subject, plus its syllabus with dot points,
  in `QCAA/<Subject>/Source/` as pdfs. First subject: Specialist
  Mathematics. Other subjects follow the same way.
- Syllabus converted to `Syllabus.tex` (tectonic), read to classify
  questions.
- Every question to its own `.tex`, one consistent style, named like
  `2025 Paper 1 Multiple Choice Question Booklet - Q3.tex`, built to a pdf
  cropped tightly with a transparent background, for importing into Mind.
- Each question tagged with unit, topic and dot points; answers matched to
  the marking guide as a check.
- Record token-saving techniques (AGENTS.md, Saving tokens).

## Decisions

- Everything, pdfs included, is committed under `QCAA/` in this repo.
- Metadata: pdf Subject (unit and topic) and Keywords (dot point ids),
  plus `index.tsv` per subject with the answer, from each `\qcaa` line.
- Diagrams are cut from the source pdf as vectors, not redrawn.

## TODO

- [ ] Source pdfs for Specialist Mathematics: QCAA's site serves a
      Cloudflare challenge to scripts, so download by hand in a browser.
- [ ] Syllabus.tex, then convert one paper and revise AGENTS.md.
- [ ] Convert all papers, check, build.
