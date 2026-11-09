## First-time hints: how to fart around, and how to spend a turbo star. Each shows until the player
## does the thing once, then never again (remembered in user://settings.cfg).
class_name Hints
extends Control

const SETTINGS := "user://settings.cfg"
## Speed that counts as having figured out how to move.
const MOVED_SPEED := 60.0

var player: Player
var touch: TouchControls
var _settings := ConfigFile.new()
var _move_label: Label
var _turbo_label: Label
var _wiggle: Tween


func setup(p: Player, t: TouchControls, force := false) -> void:
	player = p
	touch = t
	_settings.load(SETTINGS)
	if force:
		_settings.clear()
	if not _seen("move"):
		_move_label = _label("Drag to fart around" if touch.visible else "Arrow keys to fart around")
		if touch.visible:
			_place_over(_move_label, touch.joystick)
			_wiggle = create_tween().set_loops()
			_wiggle.tween_method(func(a: float): touch._update_knob_visual(Vector2.from_angle(a) * 0.8), 0.0, TAU, 1.4)
		else:
			_place_bottom(_move_label)
	player.turbo_charges_changed.connect(_on_turbo_charges_changed)


func _process(_delta: float) -> void:
	if _move_label and player.velocity.length() > MOVED_SPEED:
		_dismiss("move", _move_label)
		_move_label = null
		if _wiggle:
			_wiggle.kill()
			touch._update_knob_visual(Vector2.ZERO)
	if _turbo_label and player.turbo_active:
		_dismiss("turbo", _turbo_label)
		_turbo_label = null


func _on_turbo_charges_changed(count: int) -> void:
	if count == 0 or _turbo_label or _seen("turbo"):
		return
	_turbo_label = _label("Tap for a mega-fart!" if touch.visible else "Space for a mega-fart!")
	if touch.visible:
		_place_over(_turbo_label, touch.turbo_button)
	else:
		_place_bottom(_turbo_label)


func _seen(hint: String) -> bool:
	return _settings.get_value("hints", hint, false)


func _dismiss(hint: String, label: Label) -> void:
	_settings.set_value("hints", hint, true)
	_settings.save(SETTINGS)
	var tween := label.create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(label.queue_free)


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1, 0.96, 0.85))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.14))
	label.add_theme_constant_override("outline_size", 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var bob := label.create_tween().set_loops()
	bob.tween_property(label, "scale", Vector2.ONE * 1.06, 0.5).set_trans(Tween.TRANS_SINE)
	bob.tween_property(label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	return label


## Center the label just above a touch control.
func _place_over(label: Label, target: Control) -> void:
	label.reset_size()
	var rect := target.get_global_rect()
	label.position = Vector2(rect.get_center().x - label.size.x / 2.0, rect.position.y - label.size.y - 12.0)
	label.position.x = clampf(label.position.x, 12.0, get_viewport_rect().size.x - label.size.x - 12.0)
	label.pivot_offset = label.size / 2.0


func _place_bottom(label: Label) -> void:
	label.reset_size()
	var view := get_viewport_rect().size
	label.position = Vector2((view.x - label.size.x) / 2.0, view.y - label.size.y - 40.0)
	label.pivot_offset = label.size / 2.0
