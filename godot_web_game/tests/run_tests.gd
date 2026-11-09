## Run: godot --headless --path godot_web_game --script res://tests/run_tests.gd
extends SceneTree

const POSES := ["idle", "toot", "turbo", "smash", "chomp", "sad"]

var _failures := 0


func _init() -> void:
	# Every test_ method runs, so a new test can't be written and then forgotten here.
	for m in get_method_list():
		if m.name.begins_with("test_"):
			call(m.name)
	print("FAILED: %d" % _failures if _failures else "all tests passed")
	quit(1 if _failures else 0)


func check(cond: bool, msg: String) -> void:
	if not cond:
		_failures += 1
		push_error(msg)


func test_size_steps_up_each_third_of_the_goal() -> void:
	for c in [[0.0, 0], [49.0, 0], [50.0, 1], [99.0, 1], [100.0, 2], [150.0, 2], [400.0, 2]]:
		check(Progression.size_for(c[0], 150.0) == c[1], "size_for(%s) should be %d" % c)


func test_smashing_needs_speed_and_size_unless_turbo() -> void:
	var fast := Progression.SMASH_SPEED + 1.0
	var slow := Progression.SMASH_SPEED - 1.0
	check(Progression.can_smash(0, 0, fast, false), "small and fast smashes a flimsy prop")
	check(not Progression.can_smash(0, 0, slow, false), "too slow to smash")
	check(not Progression.can_smash(1, 2, fast, false), "too small for a tough prop")
	check(Progression.can_smash(2, 2, fast, false), "big enough for a tough prop")
	check(Progression.can_smash(0, 2, 0.0, true), "turbo smashes anything")


func test_growth_scale_and_exit() -> void:
	check(Progression.scale_for(0.0, 100.0) == 1.0, "starts at scale 1")
	check(Progression.scale_for(300.0, 100.0) == Progression.GROWN_SCALE, "scale stops at the grown size")
	check(not Progression.exit_open(99.0, 100.0) and Progression.exit_open(100.0, 100.0), "exit opens at the goal")


func test_every_area_is_complete_and_beatable() -> void:
	var areas := GameData.areas()
	for i in areas.size():
		var area: Dictionary = areas[i]
		check(ResourceLoader.exists("res://shaders/floor_%s.gdshader" % area.floor), "%s: no floor shader" % area.id)
		check(area.exit.is_empty() == (i == areas.size() - 1), "%s: only the last area has no exit" % area.id)
		if not area.exit.is_empty():
			_check_sprite(area.exit.sprite)
		for food_id in area.foods:
			check(GameData.foods().has(food_id), "%s: unknown food %s" % [area.id, food_id])
		var flimsy := false
		for prop_id in area.props:
			check(GameData.props().has(prop_id), "%s: unknown prop %s" % [area.id, prop_id])
			flimsy = flimsy or GameData.props()[prop_id].toughness == 0
		# A fresh baby is size 0, so each area needs something it can smash before it grows.
		check(flimsy, "%s: nothing a size-0 baby can smash" % area.id)


func test_every_sprite_exists() -> void:
	for food_id in GameData.foods():
		_check_sprite(food_id)
	for prop_id in GameData.props():
		var spec: Dictionary = GameData.props()[prop_id]
		_check_sprite(prop_id)
		_check_sprite(prop_id + "_broken")
		check(spec.toughness >= 0 and spec.toughness < Progression.SIZES, "%s: toughness out of range" % prop_id)
		for food_id in spec.get("drops", []):
			check(GameData.foods().has(food_id), "%s drops unknown food %s" % [prop_id, food_id])
	for name in ["puff", "dust", "turbo_star", "lock"]:
		_check_sprite(name)
	for stage in GameData.areas().size():
		for pose in POSES:
			check(ResourceLoader.exists("res://assets/baby/baby%d_%s.png" % [stage, pose]), "missing baby%d_%s" % [stage, pose])


func _check_sprite(name: String) -> void:
	check(ResourceLoader.exists("res://assets/sprites/%s.png" % name), "missing sprite " + name)
