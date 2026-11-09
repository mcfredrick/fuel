## Growth and smashing rules. Pure logic, so tests can run it without a scene.
class_name Progression

const SIZES := 3
const SMASH_SPEED := 240.0
## How much bigger the baby draws at a full growth meter than at the start of an area.
const GROWN_SCALE := 1.45


## The baby's size within an area: 0, 1 or 2, one step per third of the growth goal.
static func size_for(growth: float, goal: float) -> int:
	return clampi(int(growth / goal * SIZES), 0, SIZES - 1)


static func can_smash(size: int, toughness: int, speed: float, turbo: bool) -> bool:
	if turbo:
		return true
	return speed >= SMASH_SPEED and size >= toughness


static func scale_for(growth: float, goal: float) -> float:
	return lerpf(1.0, GROWN_SCALE, clampf(growth / goal, 0.0, 1.0))


static func exit_open(growth: float, goal: float) -> bool:
	return growth >= goal
