class_name Player
extends CharacterBody2D

signal fart_meter_changed(current, capacity)
signal turbo_charges_changed(count)

const FART_FORCE := 900.0
const MAX_SPEED := 520.0
const DRAG := 420.0
const BURN_RATE := 28.0
const TURBO_FORCE_MULTIPLIER := 1.6
const TURBO_DRAG_REDUCTION := 0.3
const TURBO_DURATION := 1.5
## Display height of the baby at scale 1, in pixels.
const HEIGHT := 120.0
const BOUNCE := 0.6
## The baby never touches the floor: it rides this high over its shadow, bobbing on its own gas.
const HOVER := 34.0
const BOB := 5.0

@export var touch_controls_path: NodePath

var fart_capacity := 100.0
var fart_level := 100.0
var turbo_charges := 0
## Which outfit to draw (one per area) and the in-area size used for smashing (Progression).
var stage := 0
var size := 0
var bounds := Rect2(0, 0, 1152, 648)

var _last_reported_capacity := -1.0
var _last_reported_level := -1.0
var _last_reported_turbo := -1
var controls_enabled := true
var turbo_active := false
var turbo_timer := 0.0
var _flash_pose := ""
var _flash_timer := 0.0
var _thrusting := false
var _grown := 1.0
var _facing := 1.0
var _shadow: Sprite2D
var _touch_controls: TouchControls
## Held direction from DebugArgs --thrust, for screenshots of the baby on the move.
var held_input := Vector2.ZERO

@onready var body_sprite: Sprite2D = $Body
@onready var puffs: CPUParticles2D = $Puffs
@onready var turbo_stars: Node2D = $TurboStars
@onready var shape: CollisionShape2D = $CollisionShape2D


func initialize_fart_meter(initial_capacity: float) -> void:
	fart_capacity = initial_capacity
	fart_level = initial_capacity
	_emit_meter(true)


func feed(nutrition: float) -> void:
	fart_capacity += nutrition
	fart_level = min(fart_level + nutrition, fart_capacity)
	_emit_meter(true)
	flash_pose("chomp", 0.35)


func add_turbo_charge(amount: int) -> void:
	if amount <= 0:
		return
	turbo_charges += amount
	_emit_turbo_charges()


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		puffs.emitting = false
		_set_turbo_active(false)


## Show `pose` for a moment over whatever the baby is doing.
func flash_pose(pose: String, seconds: float) -> void:
	_flash_pose = pose
	_flash_timer = seconds


func set_grown(scale_factor: float) -> void:
	_grown = scale_factor
	(shape.shape as CircleShape2D).radius = HEIGHT * 0.27 * scale_factor
	turbo_stars.scale = Vector2.ONE * scale_factor
	_update_pose()


func _ready() -> void:
	shape.shape = shape.shape.duplicate()
	body_sprite.texture = GameData.baby(stage, "idle")
	body_sprite.offset.y = -body_sprite.texture.get_height() * 0.3
	_shadow = Sprite2D.new()
	_shadow.texture = _shadow_texture()
	_shadow.z_index = -1
	add_child(_shadow)
	move_child(_shadow, 0)
	puffs.texture = GameData.sprite("puff")
	for star in turbo_stars.get_children():
		(star as Sprite2D).texture = GameData.sprite("turbo_star")
	set_grown(1.0)
	if touch_controls_path != NodePath(""):
		var candidate = get_node_or_null(touch_controls_path)
		if candidate is TouchControls:
			_touch_controls = candidate


func _physics_process(delta: float) -> void:
	_flash_timer -= delta
	if not controls_enabled:
		velocity = velocity.move_toward(Vector2.ZERO, DRAG * delta)
		_move(delta)
		_update_pose()
		return

	_handle_turbo_input()
	_update_turbo_timer(delta)

	var input_vector := _get_input_vector()
	var thrust_vector := Vector2.ZERO
	if input_vector.length_squared() > 0:
		thrust_vector = input_vector.normalized()

	_thrusting = false
	if thrust_vector != Vector2.ZERO and fart_level > 0.0:
		var thrust_force := FART_FORCE
		if turbo_active:
			thrust_force *= TURBO_FORCE_MULTIPLIER
		fart_level = max(fart_level - BURN_RATE * delta, 0.0)
		velocity += thrust_vector * thrust_force * delta
		_thrusting = true

	var drag := DRAG
	if turbo_active:
		drag *= (1.0 - TURBO_DRAG_REDUCTION)
	velocity = velocity.move_toward(Vector2.ZERO, drag * delta)
	var max_speed := MAX_SPEED * (TURBO_FORCE_MULTIPLIER if turbo_active else 1.0)
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	_move(delta)
	_update_puffs(thrust_vector)
	_update_turbo_stars(delta)
	_update_pose()
	_emit_meter()


## Slide, smashing what the baby is big or fast enough to break and bouncing off the rest.
func _move(_delta: float) -> void:
	var before := velocity
	move_and_slide()
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var prop := hit.get_collider() as Prop
		if prop == null or prop.is_smashed:
			continue
		if Progression.can_smash(size, prop.toughness, before.length(), turbo_active):
			prop.smash()
			velocity = before * 0.8
			flash_pose("smash", 0.45)
		else:
			velocity = before.bounce(hit.get_normal()) * BOUNCE
	position = position.clamp(bounds.position, bounds.end)


func _update_pose() -> void:
	var pose := "idle"
	if _flash_timer > 0.0:
		pose = _flash_pose
	elif not controls_enabled:
		pose = "sad"
	elif turbo_active:
		pose = "turbo"
	elif _thrusting:
		pose = "toot"
	body_sprite.texture = GameData.baby(stage, pose)
	if absf(velocity.x) > 20.0:
		_facing = signf(velocity.x)
	var s := HEIGHT * _grown / body_sprite.texture.get_height()
	body_sprite.scale = Vector2(s * _facing, s)
	var bob := sin(Time.get_ticks_msec() / 260.0)
	body_sprite.position.y = -(HOVER + BOB * bob) * _grown
	_shadow.scale = Vector2(1.0, 0.45) * _grown * (1.0 - 0.08 * bob)
	body_sprite.rotation = clampf(velocity.x / MAX_SPEED, -1.0, 1.0) * 0.15


func _update_puffs(thrust_vector: Vector2) -> void:
	puffs.emitting = _thrusting
	if _thrusting:
		# Puffs come out the back, opposite the way the baby is pushing.
		puffs.direction = -thrust_vector
		puffs.position = body_sprite.position + Vector2(0, HEIGHT * 0.1 * _grown) - thrust_vector * HEIGHT * 0.2 * _grown


func _emit_meter(force := false) -> void:
	if force or _last_reported_level != fart_level or _last_reported_capacity != fart_capacity:
		_last_reported_level = fart_level
		_last_reported_capacity = fart_capacity
		fart_meter_changed.emit(fart_level, fart_capacity)


func _emit_turbo_charges() -> void:
	if _last_reported_turbo != turbo_charges:
		_last_reported_turbo = turbo_charges
		turbo_charges_changed.emit(turbo_charges)


func _handle_turbo_input() -> void:
	var turbo_pressed := Input.is_action_just_pressed("turbo")
	if not turbo_pressed and _touch_controls and _touch_controls.visible:
		turbo_pressed = _touch_controls.consume_turbo_request()
	if turbo_pressed and turbo_charges > 0 and not turbo_active:
		turbo_charges -= 1
		_emit_turbo_charges()
		_set_turbo_active(true)
		turbo_timer = TURBO_DURATION


func _get_input_vector() -> Vector2:
	var vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if held_input != Vector2.ZERO:
		vector = held_input
	if _touch_controls and _touch_controls.visible:
		var touch_vector: Vector2 = _touch_controls.get_move_vector()
		if touch_vector != Vector2.ZERO:
			vector = touch_vector
	return vector


func _update_turbo_timer(delta: float) -> void:
	if turbo_active:
		turbo_timer -= delta
		if turbo_timer <= 0.0:
			_set_turbo_active(false)


func _set_turbo_active(active: bool) -> void:
	turbo_active = active
	turbo_stars.visible = active
	if not active:
		turbo_timer = 0.0


func _update_turbo_stars(delta: float) -> void:
	if turbo_active:
		turbo_stars.rotation += TAU * 0.6 * delta


func _shadow_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.1, 0.06, 0.14, 0.35))
	gradient.set_color(1, Color(0.1, 0.06, 0.14, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 96
	tex.height = 96
	return tex
