extends Control
class_name TouchControls

@export var force_visible := true
@export_range(0.0, 1.0, 0.01) var deadzone := 0.18

var _joystick_touch_id := -1
var _move_vector := Vector2.ZERO
var _turbo_requested := false

@onready var joystick: Control = $Joystick
@onready var knob: Control = $Joystick/Knob
@onready var turbo_button: Button = $TurboButton

func _ready() -> void:
	var should_show := force_visible or DisplayServer.is_touchscreen_available()
	visible = should_show
	mouse_filter = Control.MOUSE_FILTER_PASS if should_show else Control.MOUSE_FILTER_IGNORE
	set_process_input(should_show)
	if not should_show:
		return
	_reset_joystick()
	if is_instance_valid(turbo_button):
		turbo_button.pressed.connect(_on_turbo_pressed)

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _joystick_touch_id == -1 and _touch_in_joystick_half(event.position):
			_joystick_touch_id = event.index
			_update_move_vector(event.position)
	else:
		if event.index == _joystick_touch_id:
			_reset_joystick()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _joystick_touch_id:
		_update_move_vector(event.position)

func _touch_in_joystick_half(screen_position: Vector2) -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	return screen_position.x <= viewport_size.x * 0.55

func _update_move_vector(screen_position: Vector2) -> void:
	if joystick == null:
		return
	var rect: Rect2 = joystick.get_global_rect()
	var center: Vector2 = rect.position + rect.size * 0.5
	var radius: float = min(rect.size.x, rect.size.y) * 0.5
	if radius <= 0.0:
		radius = 1.0
	var delta: Vector2 = screen_position - center
	var vector: Vector2 = delta / radius
	if vector.length() > 1.0:
		vector = vector.normalized()
	if vector.length() < deadzone:
		vector = Vector2.ZERO
	_move_vector = vector
	_update_knob_visual(vector)

func _update_knob_visual(vector: Vector2) -> void:
	if knob == null or joystick == null:
		return
	var center: Vector2 = joystick.size * 0.5
	var radius: float = min(joystick.size.x, joystick.size.y) * 0.5 - knob.size.x * 0.5
	knob.position = center + vector * max(radius, 0.0) - knob.size * 0.5

func _reset_joystick() -> void:
	_joystick_touch_id = -1
	_move_vector = Vector2.ZERO
	_update_knob_visual(Vector2.ZERO)

func _on_turbo_pressed() -> void:
	_turbo_requested = true

func get_move_vector() -> Vector2:
	return _move_vector

func consume_turbo_request() -> bool:
	if _turbo_requested:
		_turbo_requested = false
		return true
	return false

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_MASK_LEFT:
		if event.pressed:
			if _joystick_touch_id == -1 and _touch_in_joystick_half(event.position):
				_joystick_touch_id = -2  # Use -2 to distinguish mouse input
				_update_move_vector(event.position)
		else:
			if _joystick_touch_id == -2:
				_reset_joystick()

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _joystick_touch_id == -2 and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_update_move_vector(event.position)
