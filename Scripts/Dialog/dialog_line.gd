class_name DialogLine extends RefCounted
## A resolved line ready for display. Speaker names and {expressions} are already applied.

var speaker_id: String
## Empty for narration.
var speaker_name: String
var speaker_color: Color = Color.WHITE
var text: String
## True when a choice menu comes right after this line. The UI then shows the
## choices as soon as the text finishes typing, without an extra click.
var choices_follow: bool = false
