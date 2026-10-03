@abstract
class_name InteractionEffect extends Resource
## Base class for a single step of an interaction. execute() may be a coroutine;
## InteractionData awaits it before running the next effect.


@abstract func execute(context: InteractionContext) -> void


## Player-facing description, used in item tooltips. Empty hides it.
func describe() -> String:
	return ""
