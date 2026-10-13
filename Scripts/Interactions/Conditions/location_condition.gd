class_name LocationCondition extends InteractionCondition
## Met when the context location is one of `locations`. Not met without a location.

@export var locations: Array[Ids.Location] = []


func is_met(context: InteractionContext) -> bool:
	return context != null and context.location != null and context.location.id in locations
