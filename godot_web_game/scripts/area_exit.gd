## The way out of an area: padlocked until the growth meter fills.
class_name AreaExit
extends Area2D

signal entered

var is_open := false
var _lock: Sprite2D
var _sprite: Sprite2D


static func create(spec: Dictionary) -> AreaExit:
	var exit := AreaExit.new()
	var size: float = spec.size
	exit._sprite = Sprite2D.new()
	exit._sprite.texture = GameData.sprite(spec.sprite)
	exit._sprite.scale = Vector2.ONE * size / exit._sprite.texture.get_width()
	exit.add_child(exit._sprite)
	exit._lock = Sprite2D.new()
	exit._lock.texture = GameData.sprite("lock")
	exit._lock.scale = Vector2.ONE * size * 0.45 / exit._lock.texture.get_width()
	exit._lock.position = Vector2(0, size * 0.1)
	exit.add_child(exit._lock)
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = size * 0.35
	exit.add_child(shape)
	exit.position = Vector2(spec.at[0], spec.at[1])
	return exit


func _ready() -> void:
	_sprite.modulate = Color(0.6, 0.6, 0.65)
	body_entered.connect(_on_body_entered)


func open() -> void:
	if is_open:
		return
	is_open = true
	_sprite.modulate = Color.WHITE
	var drop := create_tween()
	drop.tween_property(_lock, "position:y", _lock.position.y + 60.0, 0.5).set_trans(Tween.TRANS_QUAD)
	drop.parallel().tween_property(_lock, "modulate:a", 0.0, 0.5)
	var pulse := create_tween().set_loops()
	pulse.tween_property(_sprite, "scale", _sprite.scale * 1.08, 0.45).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_sprite, "scale", _sprite.scale, 0.45).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node2D) -> void:
	if is_open and body is Player:
		entered.emit()
