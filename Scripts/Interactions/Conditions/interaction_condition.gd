@abstract
class_name InteractionCondition extends Resource
## Base class for anything that decides whether an interaction is available.
## Subclass it for typed, inspector-friendly conditions.


@abstract func is_met(context: InteractionContext) -> bool
