extends Node

## Phases of a single day. Values are sequential indexes starting at 0.
enum TIME_STATE {
	MORNING,
	AFTERNOON,
	EVENING
}

## Days of the week. Values are sequential indexes starting at 0.
enum WEEK_STATE {
	MONDAY,
	TUESDAY,
	WEDNESDAY,
	THURSDAY,
	FRIDAY,
	SATURDAY,
	SUNDAY
}

const TIME_STATE_NAMES: Dictionary = {
	TIME_STATE.MORNING: "Morning",
	TIME_STATE.AFTERNOON: "Afternoon",
	TIME_STATE.EVENING: "Evening",
}

const WEEK_STATE_NAMES: Dictionary = {
	WEEK_STATE.MONDAY: "MON",
	WEEK_STATE.TUESDAY: "TUE",
	WEEK_STATE.WEDNESDAY: "WED",
	WEEK_STATE.THURSDAY: "THU",
	WEEK_STATE.FRIDAY: "FRI",
	WEEK_STATE.SATURDAY: "SAT",
	WEEK_STATE.SUNDAY: "SUN",
}
