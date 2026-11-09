## Something to smash. Solid until smashed, then rubble. Built from data/props.json.
class_name Prop
extends StaticBody2D

signal smashed(prop: Prop)

var id := ""
var toughness := 0
var points := 0
var drops: Array = []
var is_smashed := false
var size := 0.0

var _sprite: Sprite2D


static func create(prop_id: String) -> Prop:
	var spec: Dictionary = GameData.props()[prop_id]
	var prop := Prop.new()
	prop.id = prop_id
	prop.toughness = spec.toughness
	prop.points = spec.points
	prop.drops = spec.get("drops", [])
	prop.size = spec.size
	prop._sprite = Sprite2D.new()
	prop._sprite.texture = GameData.sprite(prop_id)
	prop._sprite.scale = Vector2.ONE * prop.size / prop._sprite.texture.get_width()
	# Sprites stand on the floor, so the footprint is the lower part of the picture.
	prop._sprite.offset.y = -prop._sprite.texture.get_height() * 0.3
	prop.add_child(prop._sprite)
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = prop.size * 0.33
	prop.add_child(shape)
	return prop


func smash() -> void:
	is_smashed = true
	_sprite.texture = GameData.sprite(id + "_broken")
	collision_layer = 0
	z_index = -1
	var tween := create_tween()
	_sprite.scale *= 1.25
	tween.tween_property(_sprite, "scale", _sprite.scale / 1.25, 0.25).set_trans(Tween.TRANS_BACK)
	_burst()
	smashed.emit(self)


func _burst() -> void:
	var dust := CPUParticles2D.new()
	dust.texture = GameData.sprite("dust")
	dust.one_shot = true
	dust.emitting = true
	dust.amount = 10
	dust.lifetime = 0.7
	dust.explosiveness = 1.0
	dust.spread = 180.0
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = 80.0
	dust.initial_velocity_max = 220.0
	dust.damping_min = 200.0
	dust.damping_max = 300.0
	dust.scale_amount_min = size / 900.0
	dust.scale_amount_max = size / 500.0
	dust.color_ramp = Gradient.new()
	dust.color_ramp.set_color(0, Color.WHITE)
	dust.color_ramp.set_color(1, Color(1, 1, 1, 0))
	dust.finished.connect(dust.queue_free)
	add_child(dust)
