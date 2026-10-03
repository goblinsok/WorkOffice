# Dialog runtime

The `.dlg` syntax reference is in `Dialogs/README.md`. Content files live in `Dialogs/<girl_id>/<name>.dlg`.

Pipeline: `DialogParser` (indentation → statement tree → flat jump instructions, labels resolved) produces a `DialogResource`. `DialogRunner` is a pure step machine: `next()` returns a `DialogLine`, an `Array[DialogChoice]`, or null. `DialogManager` (autoload) caches the resources, turns the steps into signals, and plays bubbles. `UI/Dialog/dialog_panel` is the view and answers with `advance()` / `choose()`.

- Start a dialog from code with `await DialogManager.start(path, label, ctx)`. From an interaction, use `DialogEffect` (its `dialog_path` supports `{girl}`).
- `DialogLine.choices_follow` lets the panel show the choices without an extra click.
- To add a syntax feature: add a `Kind` in the parser, emit existing ops (`LINE`, `MENU`, `JUMP`, `BRANCH`, `DO`, `END`) where possible, and handle any new op in `DialogRunner.next()`. Add a parser case to the smoke test.
- Parse errors are collected in `DialogResource.errors`, and the runner refuses to run an invalid dialog.
