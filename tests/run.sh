#!/bin/bash
# usage: tests/run.sh "keys..." [file]   -- run limacs headless; frames are dumped at @dump
# keys: space separated key names (C-x, M-f, RET, TAB, SPC, <up> ...); other tokens are typed literally.
DIR="$(cd "$(dirname "$0")/.." && pwd)"
K="${1//\\/\\\\}"; K="${K//\"/\\\"}"
FILES="${2:-}"
exec limo -e "(setq *limacs-dir* \"$DIR/\")" -i "$DIR/limacs.limo" -e "(setq *rows* ${ROWS:-24})" -e "(setq *cols* ${COLS:-80})" -e "(limacs-test \"$K\" (list $( [ -n "$FILES" ] && printf '"%s"' "$FILES" )))" -e '(exit)'
