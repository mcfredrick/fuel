extends Area2D

signal eaten(nutrition, turbo_reward)

@export var nutrition := 15
@export var turbo_reward := 0
@export var hover_distance := 6.0
@export var hover_speed := 0.9

func _ready():
	body_entered.connect(_on_body_entered)
	_start_hover_animation()

func _on_body_entered(body):
	if body.name == "Player":
		eaten.emit(nutrition, turbo_reward)
		call_deferred("queue_free")

func _start_hover_animation():
	var tween = create_tween().set_loops()
	var start_y := position.y
	tween.tween_property(self, "position:y", start_y - hover_distance, hover_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", start_y + hover_distance, hover_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", start_y, hover_speed * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
