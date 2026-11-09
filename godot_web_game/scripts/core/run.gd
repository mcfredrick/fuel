## The run in progress. Static so it survives reloading the main scene between areas and retries.
class_name Run

static var area_index := 0
## The score when the current area began, so a retry starts the area over from there.
static var area_start_score := 0


static func reset() -> void:
	area_index = 0
	area_start_score = 0


static func is_last_area() -> bool:
	return area_index == GameData.areas().size() - 1
