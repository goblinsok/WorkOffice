@abstract
class_name CutsceneStep extends Resource
## Base class for one step of a CutsceneData. run() may be a coroutine; CutsceneManager
## awaits it before moving on.

## Wait for a player click before this step runs. Ignored for the first step.
@export var wait_for_click: bool = true


@abstract func run(context: InteractionContext) -> void
