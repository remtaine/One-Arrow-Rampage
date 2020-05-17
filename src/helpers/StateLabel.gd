extends Label

onready var Player = get_parent()

var _state_text

func _ready():
	_state_text = {
		Player.STATES.IDLE: "idle",
		Player.STATES.WALK: "walk",
		Player.STATES.JUMP: "jump",
		Player.STATES.FALL: "fall",
		Player.STATES.ROLL: "roll",
		Player.STATES.ATTACK_AIR: "attack AIR",
		Player.STATES.ATTACK_GROUND: "attack GROUND",
		Player.STATES.GRAPPLE_MOVE: "Grapple Move",
		Player.STATES.FLY: "Flying",
		Player.STATES.GRAPPLE_LAUNCH_AIR: "Grapple AIR",
		Player.STATES.GRAPPLE_LAUNCH_GROUND: "Grapple GROUND",
		Player.STATES.DIE: "DIE",
	}

#enum STATES {
#	IDLE,
#	WALK,
#	RUN,
#	ATTACK,
#	JUMP,
#	BUMP,
#	FALL,
#	CLIMB,
#	RESPAWN,
#	GRAPPLE_LAUNCH,
#	GRAPPLE_MOVE,
#}

func _on_Character_state_changed(state):
	text = _state_text[state]
