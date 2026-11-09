## Read-only content from data/*.json and the rendered sprites in assets/.
class_name GameData

static var _cache := {}


static func _json(name: String) -> Variant:
	if not _cache.has(name):
		var text := FileAccess.get_file_as_string("res://data/%s.json" % name)
		var parsed: Variant = JSON.parse_string(text)
		assert(parsed != null, "data/%s.json does not parse" % name)
		_cache[name] = parsed
	return _cache[name]


static func areas() -> Array:
	return _json("areas")


static func props() -> Dictionary:
	return _json("props")


static func foods() -> Dictionary:
	return _json("foods")


static func sprite(name: String) -> Texture2D:
	return load("res://assets/sprites/%s.png" % name)


static func baby(stage: int, pose: String) -> Texture2D:
	return load("res://assets/baby/baby%d_%s.png" % [stage, pose])
