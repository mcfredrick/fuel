## Command-line hooks for screenshots and checks. Pass after `--`:
##   --area=<id>       start in that area (data/areas.json)
##   --seed=<n>        fixed scatter of props and food
##   --growth=<0..1>   fill the growth meter that far
##   --smash=<n>       smash the n props nearest the baby
##   --turbo           start a turbo burst
##   --thrust=<x,y>    hold that direction (shows the fart puffs)
##   --gameover        run the tank dry
##   --touch           show the touch controls on desktop
##   --hints           show the first-time hints even if they were seen
##   --shot=<png>      save a screenshot after --wait seconds (default 1.5) and quit
class_name DebugArgs


static func parse() -> Dictionary:
	var out := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		out[parts[0]] = parts[1] if parts.size() > 1 else ""
	if out.has("seed"):
		out.seed = int(out.seed)
	return out


## Runs before the area is built.
static func choose_area(args: Dictionary) -> void:
	if not args.has("area"):
		return
	var ids := GameData.areas().map(func(a): return a.id)
	assert(args.area in ids, "unknown area " + args.area)
	Run.area_index = ids.find(args.area)


## Runs after the area is built.
static func apply(args: Dictionary, main: Node2D) -> void:
	var player: Player = main.player
	if args.has("growth"):
		main._add_growth(float(args.growth) * main.goal)
	if args.has("smash"):
		var props: Array = main.actors.get_children().filter(func(n): return n is Prop)
		props.sort_custom(func(a, b): return a.position.distance_to(player.position) < b.position.distance_to(player.position))
		for prop in props.slice(0, int(args.smash)):
			prop.smash()
	if args.has("turbo"):
		player._set_turbo_active(true)
		player.turbo_timer = 999.0
	if args.has("thrust"):
		var xy: PackedStringArray = args.thrust.split(",")
		player.held_input = Vector2(float(xy[0]), float(xy[1]))
	if args.has("gameover"):
		player.fart_level = 0.0
		player._emit_meter(true)
	if args.has("shot"):
		var wait := float(args.get("wait", "1.5"))
		await main.get_tree().create_timer(wait).timeout
		await RenderingServer.frame_post_draw
		main.get_viewport().get_texture().get_image().save_png(args.shot)
		main.get_tree().quit()
