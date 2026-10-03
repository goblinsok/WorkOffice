# Dialog script format (`.dlg`)

`.dlg` files are plain text. `DialogParser` compiles them into a `DialogResource` the first time
`DialogManager` needs one, and caches the result.

Indentation matters and works like Python: a tab counts as 4 spaces. Blank lines and lines
starting with `#` are ignored.

| Syntax | Meaning |
|---|---|
| `~ label` | Starts a labeled section, which must not be indented. The dialog **ends** when execution reaches the next label; it doesn't fall through. |
| `Speaker: text` | A spoken line. The speaker can be a girl id (`lidya`/`Lidya`, looked up in GirlsRepo), `girl` (the girl in context), `player`, or any other literal name. |
| `text` | Narration: no name box. |
| `- choice` | A choice. Consecutive `-` lines at the same indent form one menu. The choice's body is the block indented under it; after the body runs, execution continues after the menu. |
| `- choice [if expr]` | The choice is hidden when the expression is false. |
| `- choice => label` | Selecting the choice jumps to the label, after running the body if it has one. `=> END` ends the dialog. |
| `if expr` / `elif expr` / `else` | Conditional blocks. A trailing `:` is optional. |
| `=> label` | Jumps to a label. `=> END` ends the dialog. |
| `do expr` | Runs an expression for its side effects. |
| `{expr}` | Inserts the value of the expression into text, choices, or the speaker name. |

## Expressions

Expressions use Godot's `Expression` class and are evaluated by `GameExpression`.

- **Variables:** `girl` (GirlInfo), `player` (PlayerInfo), `world` (WorldInfo), `location` (LocationInfo), `name` (the girl's display name).
- **Functions** (public methods of `InteractionContext`): `add_stat("affection", 1)`, `stat("energy")`, `add_money(-10)`, `flag("met")`, `set_flag("met")`, `set_flag("mood", "happy")`, `bubble("text")`.

Expose a new function by adding a public method to `InteractionContext`.

## Where dialogs are used

`DialogEffect.dialog_path` can contain `{girl}`, which is replaced with the girl id. That way a
single `talk.tres` interaction serves every girl through `res://Dialogs/{girl}/talk.dlg`.

Speaker detection: a line is treated as spoken when it starts with `Word:` (letters, digits,
`_` or spaces, up to 24 characters) followed by a colon. Narration therefore must not start that
way, and must not start with a lowercase `if`, `elif`, `else`, or `do` followed by a space.
