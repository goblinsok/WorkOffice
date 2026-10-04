@abstract
class_name InteractionCondition extends Resource
## Base class for anything that decides whether an interaction is available.
## Subclass it for typed, inspector-friendly conditions.

## How a stat condition compares the stat with `amount`.
enum Comparison {
	## value >= amount
	AT_LEAST,
	## value <= amount
	AT_MOST,
	## value < its max (amount is ignored), e.g. "energy is not full". Needs a max_<stat> property.
	BELOW_MAX,
}


@abstract func is_met(context: InteractionContext) -> bool


## max_value < 0 means the stat has no max (BELOW_MAX is then never met).
static func compare(value: int, max_value: int, comparison: Comparison, amount: int) -> bool:
	match comparison:
		Comparison.AT_LEAST:
			return value >= amount
		Comparison.AT_MOST:
			return value <= amount
		Comparison.BELOW_MAX:
			return max_value >= 0 and value < max_value
	return false
