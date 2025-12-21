extends Area2D

signal collected

func _on_body_entered(body):
	if body.name == "Player":
		collected.emit()
		call_deferred("queue_free")

func _ready():
	# Connect the body_entered signal
	body_entered.connect(_on_body_entered)
	# Add a slight animation
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "rotation", TAU, 2.0).as_relative()
	tween.tween_property($Sprite2D, "scale", Vector2(0.4, 0.4), 0.3).set_trans(Tween.TRANS_QUAD)
	tween.tween_property($Sprite2D, "scale", Vector2(0.5, 0.5), 0.3).set_trans(Tween.TRANS_QUAD)
