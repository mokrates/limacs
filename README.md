# limacs — an Emacs-style editor written in limo

    ./limacs [files...]          # needs `limo` (with ncurses module) on PATH, or LIMO=/path/to/limo
    tests/run.sh "keys" [file]   # headless test driver; @dump prints the screen

Modes: **C**, **Limo** (lisp/scm/el too), **Markdown** (with embedded C/limo fences), plus Text/Prog/Fundamental.
Each mode controls syntax highlighting (`:scan-line`), auto-indent/format (`:indent-line`, `:electric-chars`,
`:newline`, `:format-buffer`, `:indent-region`), and input methods (`:input-method`, `:input-method-context`).

## Keys (Emacs-like)
Movement C-f C-b C-n C-p C-a C-e M-f M-b M-< M-> C-v M-v · mark C-SPC, C-x C-x · kill/yank C-k C-w M-w C-y M-y
Undo C-/ C-_ C-x u (redo M-_) · search C-s C-r · replace M-% · files C-x C-f C-s C-w C-x b C-x k C-x C-b C-x C-c
TAB indent · C-M-\ indent region · M-q fill · C-x f format buffer · M-; comment · M-x any command · M-: eval
Input method: C-\ toggles (M-x set-input-method) · Help: C-h k/f/m/b/t · C-x C-e eval sexp (limo)
Toggle minor modes with `M-x hl-line-mode`, `electric-pair-mode`, `auto-fill-mode`, `format-on-save-mode`, ...

## Keyboard macros
F3 / `C-x (` start recording (F3 while recording inserts the counter) · F4 / `C-x )` stop; with nothing recording, F4 runs the last macro ·
`C-x e` stop+run · `C-u N F4` run N times, `C-u 0 F4` until an error (a failed search, end of buffer...) · `C-g` interrupts an endless one.
`C-x C-k` prefix: `b` bind to a key · `n` name it (then `M-x name`) · `r` run on each line of the region · `C-n`/`C-p` macro ring ·
`v` show it · `C-i`/`C-c`/`C-a`/`C-f` insert / set / add to the counter, set its format · `M-x insert-kbd-macro` prints
`(define-kmacro 'name "C-a h i RET")` for your init file. A macro replays recorded keys through the normal key lookup,
so it works with M-x, search, minibuffer prompts and every mode. Any error aborts a running macro. "Def" shows in the mode line while recording.

## Themes
`M-x load-theme` (dark, light, or your own). Define one with `(define-theme 'name '((keyword . "1;38;5;19") (comment . "3;38;5;243") ...))`
(face → SGR parameters; see `lib/display.limo` for all face names), then `(load-theme 'name)` in your init file.

## Dired
`C-x d` (or `limacs some/dir`, or find-file on a directory) opens a directory; `C-x C-j` jumps to the current file's directory.
n/p move · RET/f visit · v view · ^ parent · g refresh · s sort name/date · m/u mark/unmark · U unmark all · t toggle
d flag · x delete flagged · % m / % d mark/flag by regexp · D delete · R rename/move · C copy · + mkdir · ! shell command · w copy name · q quit.
Operations act on the marked files, or on the file at point. It shells out to ls/rm/mv/cp/mkdir via limo's popen.

## Background syntax scanning
Highlighting runs in a worker thread (limo's threading library) so typing and scrolling never wait for a scanner:
the UI draws cached spans, hands the worker a snapshot of the missing lines, merges its results while idle and redraws.
Indentation still scans synchronously where it needs exact answers. `M-x toggle-async-syntax` switches it off;
`LIMACS_SYNC=1 ./limacs` starts without threads. `LIMACS_ASYNC=1 tests/run.sh "... @wait @dump"` tests it headlessly (`@wait` = let the worker finish).

## Performance notes (limo is slow, so limacs avoids work)
Rendering is cached at three levels: a whole-frame cache (moving point with nothing else changing redraws nothing),
a per-line cache of rendered segments *and* their ANSI strings (scrolling/typing only re-renders changed lines), and a
run-based fast path for plain ASCII lines. Allocation dominates in limo, so the code minimises substrings and string building.

## Extending
Copy `init-example.limo` to `~/.limacs.limo`. API:

    (define-major-mode NAME PARENT "Pretty" :scan-line F :indent-line F :electric-chars '("}") :comment-start "// " ...)
    (define-minor-mode NAME "Lighter" :overlays F :global :t :vars '(...) :on F :off F)
    (define-input-method "name" "doc" '(("->" . "→")))
    (define-key KEYMAP "C-c x" 'command)     (defcommand name () "doc" ...)
    (add-auto-mode "\\.ext$" 'mode)          (add-hook 'find-file-hook F)

Scanners: `(scan-line line state)` → `(spans . new-state)`, spans = `(start end face)`; overlays = `(line start end face)`.
Mode functions are evaluated when the mode is defined, so define them first.

## Limits
Single window; long lines are truncated (horizontal scroll), not wrapped. Strings are byte-based; UTF-8 handled in motion/display.
