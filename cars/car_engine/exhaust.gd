extends Node

@onready var pop_effect = $ExhaustEffects
@onready var pop_sound = $SoundEffect

# Emit the one time exhaust effects
func pop() -> void:
	pop_effect.emitting = true
