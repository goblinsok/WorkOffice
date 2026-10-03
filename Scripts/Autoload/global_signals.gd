extends Node
## Global event bus. Systems emit here, and views/other systems listen.
## Keep signals past-tense for "something happened" and *_requested for commands.

# --- Locations ---
## Request to move the player to another location (emitted by the map).
signal switch_location(new_location: LocationInfo)
## The location view finished switching.
signal location_changed(location: LocationInfo)

# --- Time ---
## Emitted after the day/phase changed (before the fade-in finishes).
signal time_changed(day: Enums.WEEK_STATE, time: Enums.TIME_STATE)
## Emitted when a new day starts (after overnight recovery, before the first phase).
signal day_started(day: Enums.WEEK_STATE)
## Emitted after girls were (re)assigned to points of interest.
signal girls_placed()

# --- Interactions ---
## A girl in the world was clicked.
signal girl_clicked(view: BaseGirlLocation)
signal interaction_started(interaction: InteractionData, context: InteractionContext)
signal interaction_finished(interaction: InteractionData, context: InteractionContext)
