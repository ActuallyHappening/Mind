#!/usr/bin/env bash
# Build each question .tex into a cropped pdf beside it, then write index.tsv:
# file, unit/topic, dot points, answer (from each file's \qcaa line).
# Usage: QCAA/build.sh "QCAA/Specialist Mathematics/Questions" [file.tex ...]
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
dir=$1; shift
cd "$dir"
files=("$@"); [ ${#files[@]} -gt 0 ] || files=(*.tex)
for f in "${files[@]}"; do
  tectonic -Z search-path="$here" --chatter minimal "$f" || echo "FAILED: $f" >&2
done
{
  printf 'file\ttopic\tdotpoints\tanswer\n'
  for f in *.tex; do
    sed -n 's/^\\qcaa{\(.*\)}{\(.*\)}{\(.*\)}$/\1\t\2\t\3/p' "$f" |
      sed "s|^|${f%.tex}\t|"
  done
} > index.tsv
