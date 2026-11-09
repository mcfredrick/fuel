extends Node2D

const MARGIN := 90.0
const CLEAR_OF_START := 260.0
const SHAKE_DECAY := 30.0
const WISECRACKS := [
	"Your tank ran blank, little stank.",
	"Silence is deadly… apparently so is running dry.",
	"The diaper is willing but the booty is weak.",
	"You can't spell 'flatulence' without 'fuel'. Literally, you can't.",
	"Next time, pace those pinto beans.",
	"The gas pedal only works with gas, champ.",
	"Nap time's cancelled 'til you find more beans, baby.",
	"Guess someone skipped diaper refueling duty.",
	"Pacifier policy: no toot, no loot.",
	"Mom says no more tummy time until you top off.",
	"Diaper sag detected. Needs gas, not wipes.",
]

var area: Dictionary
var score := 0
var growth := 0.0
var goal := 1.0
var is_over := false
var rng := RandomNumberGenerator.new()
var exit: AreaExit
var _shake := 0.0
var _restart: Callable

@onready var floor_rect: ColorRect = $Floor
@onready var actors: Node2D = $Actors
@onready var player: Player = $Actors/Player
@onready var camera: Camera2D = $Camera
@onready var ui: Control = $HUD/UI
@onready var area_label: Label = $HUD/UI/Status/VBox/AreaLabel
@onready var fuel_bar: ProgressBar = $HUD/UI/Status/VBox/FuelBar
@onready var growth_bar: ProgressBar = $HUD/UI/Status/VBox/GrowthBar
@onready var score_label: Label = $HUD/UI/Status/VBox/Row/ScoreLabel
@onready var turbo_label: Label = $HUD/UI/Status/VBox/Row/TurboValue
@onready var banner: Label = $HUD/UI/Banner
@onready var end_panel: PanelContainer = $HUD/UI/EndPanel
@onready var end_title: Label = $HUD/UI/EndPanel/VBox/Title
@onready var end_detail: Label = $HUD/UI/EndPanel/VBox/Detail
@onready var end_button: Button = $HUD/UI/EndPanel/VBox/Button
@onready var fade: ColorRect = $HUD/UI/Fade


func _ready() -> void:
	var debug := DebugArgs.parse()
	DebugArgs.choose_area(debug)
	rng.seed = debug.get("seed", randi())
	area = GameData.areas()[Run.area_index]
	goal = area.goal
	score = Run.area_start_score
	_apply_theme()
	_build_world()
	player.fart_meter_changed.connect(_on_fart_meter_changed)
	player.turbo_charges_changed.connect(_on_turbo_charges_changed)
	player.initialize_fart_meter(100.0)
	_on_turbo_charges_changed(player.turbo_charges)
	end_button.pressed.connect(func(): _restart.call())
	$HUD/UI/Status/VBox/Row/StarIcon.texture = GameData.sprite("turbo_star")
	area_label.text = area.name
	_add_growth(0.0)
	_show_banner(area.intro)
	var hints := Hints.new()
	hints.set_anchors_preset(Control.PRESET_FULL_RECT)
	hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hints)
	ui.move_child(hints, fade.get_index())
	hints.setup(player, $HUD/TouchControls, debug.has("hints"))
	_fade_in()
	DebugArgs.apply(debug, self)


func _apply_theme() -> void:
	var theme := Theme.new()
	theme.default_font = load("res://assets/fonts/Fredoka.ttf")
	theme.default_font_size = 20
	var ink := Color(0.1, 0.06, 0.14)
	theme.set_color("font_color", "Label", ink)
	for state in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(1, 0.82, 0.25) if state != "hover" else Color(1, 0.88, 0.45)
		box.set_corner_radius_all(14)
		box.set_border_width_all(3)
		box.border_color = ink
		theme.set_stylebox(state, "Button", box)
		theme.set_color("font_%s_color" % state if state != "normal" else "font_color", "Button", ink)
	theme.set_font_size("font_size", "Button", 24)
	ui.theme = theme
	$HUD/TouchControls.theme = theme


func _build_world() -> void:
	var size := Vector2(area.size[0], area.size[1])
	floor_rect.size = size
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/floor_%s.gdshader" % area.floor)
	mat.set_shader_parameter("world_size", size)
	floor_rect.material = mat

	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)
	player.stage = Run.area_index
	player.bounds = Rect2(Vector2.ONE * 40.0, size - Vector2.ONE * 80.0)
	player.position = size / 2.0
	camera.position = player.position
	camera.reset_smoothing()

	if not area.exit.is_empty():
		exit = AreaExit.create(area.exit)
		exit.entered.connect(_on_exit_entered)
		actors.add_child(exit)

	for prop_id in area.props:
		for i in int(area.props[prop_id]):
			var prop := Prop.create(prop_id)
			var spot := _free_spot(prop.size * 0.6)
			if spot == Vector2.INF:
				prop.free()
				continue
			prop.position = spot
			prop.smashed.connect(_on_prop_smashed)
			actors.add_child(prop)
	for i in int(area.food_count):
		_spawn_food(area.foods[rng.randi() % area.foods.size()])


## A random spot inside the area, clear of the start, the exit and every solid prop.
func _free_spot(clearance: float) -> Vector2:
	var size := Vector2(area.size[0], area.size[1])
	for attempt in 60:
		var p := Vector2(rng.randf_range(MARGIN, size.x - MARGIN), rng.randf_range(MARGIN + 40.0, size.y - MARGIN))
		if p.distance_to(size / 2.0) < CLEAR_OF_START:
			continue
		if exit and p.distance_to(exit.position) < 200.0:
			continue
		var blocked := false
		for node in actors.get_children():
			if node is Prop and not node.is_smashed and p.distance_to(node.position) < clearance + node.size * 0.6:
				blocked = true
				break
		if not blocked:
			return p
	return Vector2.INF


func _spawn_food(food_id: String, at := Vector2.INF) -> void:
	var food := Food.create(food_id)
	food.position = at if at != Vector2.INF else _free_spot(40.0)
	if food.position == Vector2.INF:
		food.free()
		return
	food.eaten.connect(_on_food_eaten)
	actors.add_child.call_deferred(food)


func _physics_process(delta: float) -> void:
	camera.position = player.position
	_shake = maxf(_shake - SHAKE_DECAY * delta, 0.0)
	camera.offset = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _shake


func _on_food_eaten(food: Food) -> void:
	player.feed(food.nutrition)
	if food.turbo_reward > 0:
		player.add_turbo_charge(food.turbo_reward)
	score += food.nutrition
	_add_growth(food.nutrition)
	_spawn_food(area.foods[rng.randi() % area.foods.size()])


func _on_prop_smashed(prop: Prop) -> void:
	score += prop.points
	_shake = 6.0 + prop.size / 12.0
	_add_growth(prop.points)
	for food_id in prop.drops:
		var toss := Vector2.from_angle(rng.randf() * TAU) * prop.size * 0.7
		_spawn_food(food_id, (prop.position + toss).clamp(player.bounds.position, player.bounds.end))


func _add_growth(amount: float) -> void:
	if is_over:
		return
	growth = minf(growth + amount, goal)
	player.size = Progression.size_for(growth, goal)
	player.set_grown(Progression.scale_for(growth, goal))
	growth_bar.max_value = goal
	growth_bar.value = growth
	score_label.text = "Score: %d" % score
	var open := Progression.exit_open(growth, goal)
	growth_bar.get_node("Label").text = "Growth: %d%%" % roundi(growth / goal * 100.0)
	if not open:
		return
	if Run.is_last_area():
		_win()
	elif not exit.is_open:
		growth_bar.get_node("Label").text = "Way out is open!"
		exit.open()
		_show_banner("The way out is open!")


func _on_fart_meter_changed(current: float, capacity: float) -> void:
	fuel_bar.max_value = capacity
	fuel_bar.value = current
	fuel_bar.get_node("Label").text = "Fart fuel: %d/%d" % [round(current), round(capacity)]
	if current <= 0.0 and not is_over:
		_game_over()


func _on_turbo_charges_changed(count: int) -> void:
	turbo_label.text = "x%d" % count


func _on_exit_entered() -> void:
	if is_over:
		return
	is_over = true
	player.set_controls_enabled(false)
	player.flash_pose("turbo", 999.0)
	Run.area_index += 1
	Run.area_start_score = score
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.6)
	tween.tween_callback(get_tree().reload_current_scene)


func _game_over() -> void:
	is_over = true
	player.set_controls_enabled(false)
	end_title.text = WISECRACKS[rng.randi() % WISECRACKS.size()]
	end_detail.text = "Score: %d\nTry %s again from where you came in." % [score, area.name.to_lower()]
	end_button.text = "Try again"
	_restart = get_tree().reload_current_scene
	_show_end()


func _win() -> void:
	is_over = true
	player.set_controls_enabled(false)
	player.flash_pose("turbo", 999.0)
	end_title.text = "The whole world is your diaper."
	end_detail.text = "Final score: %d" % score
	end_button.text = "Be born again"
	_restart = func():
		Run.reset()
		get_tree().reload_current_scene()
	_show_end()


func _show_end() -> void:
	end_panel.visible = true
	end_panel.scale = Vector2.ONE * 0.8
	end_panel.pivot_offset = end_panel.size / 2.0
	create_tween().tween_property(end_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	end_button.grab_focus()


func _show_banner(text: String) -> void:
	banner.text = text
	banner.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.8)
	tween.tween_property(banner, "modulate:a", 0.0, 0.6)


func _fade_in() -> void:
	fade.color.a = 1.0
	create_tween().tween_property(fade, "color:a", 0.0, 0.5)
