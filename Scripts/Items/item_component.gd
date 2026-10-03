@abstract
class_name ItemComponent extends Resource
## A module of item behaviour. Subclass it for new capabilities
## (usable, equippable, giftable, sellable, ...).


## Text for the "effect" part of the tooltip. Empty means nothing to show.
func describe() -> String:
	return ""
