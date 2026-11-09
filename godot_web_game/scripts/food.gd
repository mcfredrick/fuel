## A snack bobbing on the floor. Built from data/foods.json.
class_name Food
extends Area2D

signal eaten(food: Food)

var id := ""
var nutrition := 0
var turbo_reward := 0


static func create(food_id: String) -> Food:
	var spec: Dictionary = GameData.foods()[food_id]
	var food := Food.new()
	food.id = food_id
	food.nutrition = spec.nutrition
	food.turbo_reward = spec.get("turbo", 0)
	var sprite := Sprite2D.new()
	sprite.texture = GameData.sprite(food_id)
	var size: float = spec.size
	sprite.scale = Vector2.ONE * size / sprite.texture.get_width()
	food.add_child(sprite)
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = size * 0.4
	food.add_child(shape)
	return food


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var sprite: Sprite2D = get_child(0)
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -7.0, 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 0.0, 0.9).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		eaten.emit(self)
		queue_free()
