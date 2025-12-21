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

var fart_capacity := 100.0
var fart_level := 100.0
var turbo_charges := 0

var _last_reported_capacity := -1.0
var _last_reported_level := -1.0
var _last_reported_turbo := -1
var controls_enabled := true
var turbo_active := false
var turbo_timer := 0.0

@onready var fart_cloud: Node2D = $FartCloud
@onready var turbo_aura: Node2D = $TurboAura

func initialize_fart_meter(initial_capacity: float) -> void:
	fart_capacity = initial_capacity
	fart_level = initial_capacity
	_emit_meter(true)

func feed(nutrition: float) -> void:
	fart_capacity += nutrition
	fart_level = min(fart_level + nutrition, fart_capacity)
	_emit_meter(true)

func add_turbo_charge(amount: int) -> void:
	if amount <= 0:
		return
	turbo_charges += amount
	_emit_turbo_charges()

func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		fart_cloud.visible = false
		_set_turbo_active(false)

func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity = velocity.move_toward(Vector2.ZERO, DRAG * delta)
		move_and_slide()
		_emit_meter()
		return

	_handle_turbo_input()
	_update_turbo_timer(delta)

	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	var thrust_vector := Vector2.ZERO
	if input_vector.length_squared() > 0:
		thrust_vector = input_vector.normalized()

	var thrusting := false
	if thrust_vector != Vector2.ZERO and fart_level > 0.0:
		var thrust_force := FART_FORCE
		if turbo_active:
			thrust_force *= TURBO_FORCE_MULTIPLIER
		fart_level = max(fart_level - BURN_RATE * delta, 0.0)
		velocity += thrust_vector * thrust_force * delta
		thrusting = true

	var drag := DRAG
	if turbo_active:
		drag *= (1.0 - TURBO_DRAG_REDUCTION)
	velocity = velocity.move_toward(Vector2.ZERO, drag * delta)
	if velocity.length() > MAX_SPEED:
		var max_speed := MAX_SPEED
		if turbo_active:
			max_speed *= TURBO_FORCE_MULTIPLIER
		velocity = velocity.normalized() * max_speed

	move_and_slide()

	var viewport_size := get_viewport_rect().size
	position.x = clamp(position.x, 0.0, viewport_size.x)
	position.y = clamp(position.y, 0.0, viewport_size.y)

	_update_fart_cloud(thrusting, thrust_vector)
	_update_turbo_aura(delta)
	_emit_meter()

func _update_fart_cloud(thrusting: bool, thrust_vector: Vector2) -> void:
	if fart_cloud == null:
		return

	fart_cloud.visible = thrusting
	if thrusting:
		fart_cloud.rotation = thrust_vector.angle() + PI
		fart_cloud.scale = fart_cloud.scale.lerp(Vector2(1.15, 1.15), 0.18)
	else:
		fart_cloud.scale = fart_cloud.scale.lerp(Vector2(0.6, 0.6), 0.2)

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
	if Input.is_action_just_pressed("turbo") and turbo_charges > 0 and not turbo_active:
		turbo_charges -= 1
		_emit_turbo_charges()
		_set_turbo_active(true)
		turbo_timer = TURBO_DURATION

func _update_turbo_timer(delta: float) -> void:
	if turbo_active:
		turbo_timer -= delta
		if turbo_timer <= 0.0:
			_set_turbo_active(false)

func _set_turbo_active(active: bool) -> void:
	if turbo_active == active:
		return
	turbo_active = active
	if not active:
		turbo_timer = 0.0
	_update_turbo_aura(0.0, true)

func _update_turbo_aura(delta: float, force: bool = false) -> void:
	if turbo_aura == null:
		return
	turbo_aura.visible = turbo_active
	if turbo_active:
		turbo_aura.rotation += deg_to_rad(120) * delta
		var pulse := 1.0 + 0.15 * sin(Time.get_ticks_msec() / 80.0)
		turbo_aura.scale = Vector2(pulse, pulse)
	elif force:
		turbo_aura.rotation = 0.0
		turbo_aura.scale = Vector2.ONE
