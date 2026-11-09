# Fuel

A fart-powered baby eats everything in sight, grows, and breaks out of the nursery. Then the
house, then the neighborhood, then the world. Arcade pacing, one run in a sitting, Rampage-style
mayhem by the end.

## Core loop

- The baby never walks. Farts are the only way it moves. Arrow keys or the touch joystick blast gas
  out the back and the baby drifts the other way, coasting to a stop when the farting stops. Thrust
  burns fart fuel; an empty tank ends the run.
- Food refills the tank and raises its capacity. Spicy chili also banks a turbo star.
- Ramming a prop fast enough smashes it. Smashing scores points and feeds the growth meter, and some
  props spill food when they break.
- A full growth meter opens the area's exit. Flying into it moves the baby to the next area, one
  stage bigger.
- Filling the meter in the last area wins the run.

## Areas

Each area is a world larger than the screen. The camera follows the baby and stops at the edges.
Areas are data in `data/areas.json`: size, floor shader, foods, props, exit, growth goal.

| Area | Floor | Props (toughness 0, 1, 2) | Exit |
| --- | --- | --- | --- |
| Nursery | Pastel quilt rug | Block tower, teddy bear / rocking horse / toy chest | Nursery door |
| House | Wood floor, rug islands | Lamp, vase / armchair, TV / fridge | Front door |
| Neighborhood | Lawns, streets, sidewalks | Mailbox, hydrant / fence, tree / car | Highway sign |
| World | Land and sea from above | Water tower / radio mast / skyscraper | None (the finale) |

Props shrink relative to the baby as areas go on (blocks in the nursery, cars in the neighborhood,
skyscrapers in the world), so growing reads without the baby filling the screen.

## Smashing

- A hit smashes a prop when the baby's speed is over the smash threshold and the baby is big enough
  for the prop's toughness. Otherwise the baby bounces off.
- Within an area the baby has three sizes, set by the growth meter (thirds). Size 0 smashes
  toughness 0, size 2 smashes everything.
- Turbo smashes anything at any speed.
- Smashed props leave rubble, throw debris and shake the camera.

## Runs

- Running out of fuel offers "Try again", which restarts the current area with the score you
  entered it with.
- Winning shows the final score and starts over from the nursery.

## Look

Comic ink, matching Starship Tinkerer's portraits: flat color, halftone dots in the midtones,
hatching in deep shadow and sketchy brush outlines. All characters, food and props are modeled in
Blender scripts and rendered to transparent PNGs (`blender/`), committed so the game builds without
Blender. Floors are Godot shaders with the same halftone treatment so sprites and floors sit
together.

The baby floats over its shadow with its legs tucked up, bobbing on its own gas, and leans into
each blast. It has six poses (idle, toot, turbo, smash, chomp, sad) at each of four stages. Each stage
adds something: a curl and diaper in the nursery, a bib in the house, a cape in the neighborhood,
a crown in the world.

## Later

Cats that scratch fuel away, objectives, a leaderboard and sound effects stay in `TODO.md`.
