extends Node2D

@onready var player = $Player
@onready var fuel_bar = $HUD/Margin/VBox/FuelBar
@onready var score_label = $HUD/Margin/VBox/ScoreLabel
@onready var turbo_label = $HUD/Margin/VBox/TurboMeter/TurboValue
@onready var game_over_panel = $HUD/GameOverPanel
@onready var wisecrack_label = $HUD/GameOverPanel/VBox/Title
@onready var final_score_label = $HUD/GameOverPanel/VBox/FinalScore
@onready var restart_button = $HUD/GameOverPanel/VBox/RestartButton

const FOOD_SCENES := [
	preload("res://scenes/food.tscn"),
	preload("res://scenes/foods/beans.tscn"),
	preload("res://scenes/foods/broccoli.tscn"),
	preload("res://scenes/foods/banana_mash.tscn"),
	preload("res://scenes/foods/peas_pouch.tscn"),
	preload("res://scenes/foods/spicy_chili.tscn")
]

var score := 0
var is_game_over := false
const WISECRACKS := [
	"Your tank ran blank, little stank.",
	"Silence is deadly… apparently so is running dry.",
	"The diaper is willing but the booty is weak.",
	"You can’t spell ‘flatulence’ without ‘fuel’. Literally, you can’t.",
	"Next time, pace those pinto beans.",
	"The gas pedal only works with gas, champ.",
	"Nap time’s cancelled ‘til you find more beans, baby.",
	"Guess someone skipped diaper refueling duty.",
	"Pacifier policy: no toot, no loot.",
	"Mom says no more tummy time until you top off.",
	"Diaper sag detected—needs gas, not wipes."
]

func _ready():
	randomize()
	player.initialize_fart_meter(100.0)
	player.fart_meter_changed.connect(_on_player_fart_meter_changed)
	player.turbo_charges_changed.connect(_on_turbo_charges_changed)
	_on_player_fart_meter_changed(player.fart_level, player.fart_capacity)
	_on_turbo_charges_changed(player.turbo_charges)
	_update_score_label()
	restart_button.pressed.connect(_on_restart_button_pressed)
	for i in range(10):
		spawn_food()

func spawn_food():
	if FOOD_SCENES.is_empty():
		return
	var food_scene = FOOD_SCENES[randi() % FOOD_SCENES.size()]
	var food = food_scene.instantiate()
	var viewport_size = get_viewport_rect().size
	food.position = Vector2(
		randi() % int(viewport_size.x - 50) + 25,
		randi() % int(viewport_size.y - 50) + 25
	)
	food.connect("eaten", _on_food_eaten)
	call_deferred("add_child", food)

func _on_food_eaten(nutrition, turbo_reward):
	player.feed(nutrition)
	if turbo_reward > 0:
		player.add_turbo_charge(turbo_reward)
	score += nutrition
	_update_score_label()
	spawn_food()

func _on_player_fart_meter_changed(current: float, capacity: float) -> void:
	if fuel_bar:
		fuel_bar.max_value = capacity
		fuel_bar.value = current
		fuel_bar.get_node("Label").text = "Fart Fuel: %d/%d" % [round(current), round(capacity)]
	if current <= 0.0 and not is_game_over:
		_trigger_game_over()

func _update_score_label():
	if score_label:
		score_label.text = "Score: %d" % score

func _on_turbo_charges_changed(count: int) -> void:
	if turbo_label:
		turbo_label.text = "x%d" % count

func _trigger_game_over():
	is_game_over = true
	player.set_controls_enabled(false)
	if WISECRACKS.size() > 0:
		var index = randi() % WISECRACKS.size()
		wisecrack_label.text = WISECRACKS[index]
	final_score_label.text = "Final Score: %d" % score
	game_over_panel.visible = true
	restart_button.grab_focus()

func _on_restart_button_pressed():
	get_tree().reload_current_scene()
