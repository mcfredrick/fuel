"""Render food, props, exits and effects, comic-inked on transparent backgrounds.

Run: Blender -b --python blender/sprites.py -- [name ...]
Writes godot_web_game/assets/sprites/<name>.png, and <name>_broken.png for every smashable prop.

Every sprite is framed to fill its square; the game sets display sizes from data/*.json. A broken
prop is the same build with every part toppled, sunk and scattered into a pile.
"""

import math
import random
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import bpy  # noqa: E402
from mathutils import Euler, Matrix, Vector  # noqa: E402

import ink  # noqa: E402
from ink import dress, hexc  # noqa: E402
from kit_common import box_bm, empty, lathe_bm, mesh_obj, slab_bm, sphere_bm, transform_bm, tube_bm  # noqa: E402

OUT_DIR = Path(__file__).resolve().parent.parent / "godot_web_game" / "assets" / "sprites"

_mats = {}


def mat(h):
    if h not in _mats:
        _mats[h] = ink.comic_material(h, hexc(h))
    return _mats[h]


def flat(h):
    key = "flat" + h
    if key not in _mats:
        _mats[key] = ink.flat_material(key, hexc(h))
    return _mats[key]


def put(root, name, bm, color, at=(0, 0, 0), material=None):
    return dress(mesh_obj(name, transform_bm(bm, lambda v: v + Vector(at)), root), material or mat(color))


def ball(r, sx=1.0, sy=1.0, sz=1.0, seg=24):
    return sphere_bm(r, seg, max(seg // 2, 6), lambda v: Vector((v.x * sx, v.y * sy, v.z * sz)))


def box(x, y, z, bevel=0.04):
    return transform_bm(box_bm((x, y, z), bevel=bevel), lambda v: v + Vector((0, 0, z / 2)))


def bowl(root, color, rim=0.75):
    shape = lathe_bm([(0.0, 0.0), (0.0, 0.35), (0.35, rim), (0.4, rim - 0.04), (0.06, 0.32), (0.06, 0.0)], axis="z")
    put(root, "bowl", shape, color)


def tube(points, r, seg=10):
    return tube_bm([Vector(p) for p in points], [r] * len(points), seg)


# ---------------------------------------------------------------- food

def banana_mash(root):
    bowl(root, "f2f2ff")
    put(root, "mash", ball(0.62, sz=0.35), "ffe066", (0, 0, 0.38))
    swirl = [(0.35 * math.cos(t) * (1 - t / 13), 0.35 * math.sin(t) * (1 - t / 13), 0.55 + 0.02 * t)
             for t in (i * 0.5 for i in range(18))]
    put(root, "swirl", tube(swirl, 0.05), "e0b23a")


def peas_pouch(root):
    outline = [(-0.45, 0), (0.45, 0), (0.5, 0.8), (0.3, 1.1), (-0.3, 1.1), (-0.5, 0.8)]
    pouch = transform_bm(slab_bm(outline, 0.3, taper=0.85), lambda v: Vector((v.x, v.z, v.y)))
    put(root, "pouch", pouch, "8fd16a")
    put(root, "cap", lathe_bm([(1.1, 0.14), (1.4, 0.14)], axis="z"), "ff7b54")
    for i in range(3):
        put(root, f"pea{i}", ball(0.11), "4c9a2a", (-0.2 + 0.2 * i, -0.17, 0.45 + 0.08 * (i % 2)))


def broccoli(root):
    put(root, "stalk", lathe_bm([(0, 0.18), (0.6, 0.14), (0.8, 0.3)], axis="z"), "8cc56b")
    for i, (x, y, z, r) in enumerate([(0, 0, 1.0, 0.38), (-0.35, 0, 0.85, 0.3), (0.35, 0, 0.85, 0.3),
                                      (-0.18, -0.2, 1.05, 0.25), (0.2, -0.2, 1.1, 0.26), (0, 0.15, 1.2, 0.27)]):
        put(root, f"floret{i}", ball(r, seg=16), "2f7d32", (x, y, z))


def beans(root):
    bowl(root, "f2f2ff")
    put(root, "sauce", ball(0.62, sz=0.25), "b5452c", (0, 0, 0.4))
    rng = random.Random(3)
    for i in range(14):
        a, r = rng.uniform(0, math.tau), rng.uniform(0, 0.5)
        bean = ball(0.09, sx=1.5, sz=0.7, seg=12)
        put(root, f"bean{i}", transform_bm(bean, lambda v, a=a: Euler((0, 0, a)).to_matrix() @ v), "8a2e1b",
            (r * math.cos(a), r * math.sin(a), 0.5))
    for i, x in enumerate((-0.2, 0.15)):
        steam = [(x + 0.06 * math.sin(j * 1.3), 0, 0.75 + 0.1 * j) for j in range(7)]
        put(root, f"steam{i}", tube(steam, 0.03), None, material=flat("ffffff"))


def spicy_chili(root):
    pts = [(-0.6 + 1.2 * t, 0, 0.5 + 0.35 * math.sin(t * 2.5)) for t in (i / 10 for i in range(11))]
    radii = [0.08 + 0.2 * math.sin(math.pi * min(t * 1.2, 1)) for t in (i / 10 for i in range(11))]
    put(root, "pepper", tube_bm([Vector(p) for p in pts], radii, 16), "e63946")
    put(root, "stem", tube([(-0.6, 0, 0.5), (-0.72, 0, 0.62), (-0.7, 0, 0.75)], 0.05), "3a7d2c")
    for i in range(4):
        a = i * math.pi / 2
        put(root, f"flame{i}", ball(0.07), None, (0.65 + 0.12 * math.cos(a), 0, 1.05 + 0.12 * math.sin(a)),
            flat("ffb703"))


def taco(root):
    shell = sphere_bm(0.8, 32, 16, lambda v: Vector((v.x, v.y * 0.3, min(v.z, 0))))
    put(root, "shell", shell, "f4c56a", (0, 0, 0.85))
    put(root, "meat", ball(0.66, sy=0.22, sz=0.14), "8b4a2b", (0, 0, 0.85))
    put(root, "lettuce", ball(0.7, sy=0.26, sz=0.14), "6abf4b", (0, 0.02, 0.95))
    for i in range(3):
        put(root, f"tomato{i}", ball(0.1), "e63946", (-0.35 + 0.35 * i, -0.18, 1.0))


def pizza(root):
    outline = [(0, 0)] + [(1.1 * math.cos(a), 1.1 * math.sin(a)) for a in (math.radians(60 + 60 * i / 8) for i in range(9))]
    slice_ = transform_bm(slab_bm(outline, 0.1), lambda v: Vector((v.x, v.y - 0.6, v.z + 0.05)))
    put(root, "slice", slice_, "ffd166")
    crust = [(1.12 * math.cos(a), 1.12 * math.sin(a) - 0.6, 0.12) for a in (math.radians(60 + 60 * i / 8) for i in range(9))]
    put(root, "crust", tube(crust, 0.1), "d99a4e")
    for i, (x, y) in enumerate([(0, -0.2), (-0.2, 0.15), (0.22, 0.2), (0, 0.38)]):
        put(root, f"pep{i}", ball(0.11, sz=0.3), "c1121f", (x, y, 0.13))


def hot_dog(root):
    bun = ball(0.85, sy=0.35, sz=0.25)
    put(root, "bun", bun, "e9b872", (0, 0, 0.25))
    dog = lathe_bm([(-0.95, 0.04), (-0.85, 0.15), (0.85, 0.15), (0.95, 0.04)], axis="y")
    put(root, "dog", transform_bm(dog, lambda v: Vector((v.y, 0, v.z))), "b5452c", (0, 0, 0.42))
    mustard = [(-0.7 + 1.4 * i / 14, 0.06 * math.sin(i * 1.6), 0.57) for i in range(15)]
    put(root, "mustard", tube(mustard, 0.035), "ffd60a")


def ice_cream(root):
    put(root, "cone", lathe_bm([(0, 0.02), (0.9, 0.32)], axis="z"), "e0a458")
    put(root, "scoop1", ball(0.38), "ffc8dd", (0, 0, 1.05))
    put(root, "scoop2", ball(0.32), "a3d977", (0, 0, 1.42))
    put(root, "cherry", ball(0.1), "d90429", (0, -0.05, 1.78))


def burrito(root):
    def sideways(bm):
        return transform_bm(bm, lambda v: Vector((v.y, v.x, v.z)))
    put(root, "wrap", sideways(lathe_bm([(-0.9, 0.05), (-0.8, 0.3), (0.6, 0.38), (0.75, 0.35)], axis="y")), "f1d6a0",
        (0, 0, 0.4))
    put(root, "rice", ball(0.3, sx=0.4), "fffbe6", (0.78, 0, 0.42))
    put(root, "foil", sideways(lathe_bm([(-0.95, 0.06), (-0.5, 0.33), (-0.3, 0.4)], axis="y")), "c9d1d9", (0, 0, 0.4))


def donut(root):
    loop = [(0.62 * math.cos(a), 0.62 * math.sin(a), 0.35) for a in (math.tau * i / 40 for i in range(41))]
    put(root, "dough", tube(loop, 0.33, 20), "d4a373")
    icing = [(x, y, z + 0.1) for x, y, z in loop]
    put(root, "icing", tube_bm([Vector(p) for p in icing], [0.3] * 41, 20), "ff8fab")
    rng = random.Random(5)
    colors = ("ffd60a", "4cc9f0", "ffffff", "80ed99")
    for i in range(16):
        a, r = rng.uniform(0, math.tau), rng.uniform(0.45, 0.85)
        put(root, f"sprinkle{i}", ball(0.04, sx=2.0), colors[i % 4], (r * math.cos(a), r * math.sin(a), 0.75))


# ---------------------------------------------------------------- nursery

def blocks(root):
    colors = ("ef476f", "ffd166", "06d6a0", "118ab2", "f78c6b")
    z = 0
    for i, (x, rot) in enumerate([(-0.35, 5), (0.35, -8), (0.0, 12), (-0.1, -4), (0.08, 20)]):
        x = x if i < 2 else x
        zz = 0 if i < 2 else 0.6 * (i - 1)
        b = transform_bm(box(0.55, 0.55, 0.55, bevel=0.05), lambda v, r=rot: Euler((0, 0, math.radians(r))).to_matrix() @ v)
        put(root, f"block{i}", b, colors[i], (x, 0, zz))
        z = zz


def teddy(root):
    fur = "b07d4f"
    put(root, "body", ball(0.5, sz=1.1), fur, (0, 0, 0.55))
    put(root, "belly", ball(0.32, sy=0.5), "e6c79c", (0, -0.35, 0.5))
    put(root, "head", ball(0.42), fur, (0, 0, 1.3))
    put(root, "snout", ball(0.17, sy=0.7), "e6c79c", (0, -0.38, 1.22))
    put(root, "nose", ball(0.06), "2b1d3a", (0, -0.5, 1.27))
    for s in (-1, 1):
        put(root, f"ear{s}", ball(0.15, sy=0.6), fur, (s * 0.32, 0, 1.65))
        put(root, f"eye{s}", ball(0.05), None, (s * 0.15, -0.37, 1.4), flat("1a0f24"))
        put(root, f"arm{s}", ball(0.15, sz=1.8), fur, (s * 0.5, -0.1, 0.65))
        put(root, f"leg{s}", ball(0.2, sy=1.4), fur, (s * 0.28, -0.25, 0.15))
    put(root, "bow", ball(0.12, sx=2.2, sy=0.5), "ef476f", (0, -0.35, 0.95))


def rocking_horse(root):
    rocker = [(-1.0 + 2.0 * i / 16, 0, 0.15 + 0.35 * ((i / 8 - 1) ** 2)) for i in range(17)]
    for s in (-1, 1):
        put(root, f"rocker{s}", tube([(x, s * 0.3, z) for x, _, z in rocker], 0.06), "c1121f")
        for x in (-0.45, 0.45):
            put(root, f"leg{s}{x}", tube([(x, s * 0.3, 0.2), (x * 0.8, s * 0.15, 0.85)], 0.07), "f4a261")
    put(root, "body", ball(0.6, sx=1.0, sy=0.45, sz=0.4), "f4a261", (0, 0, 1.0))
    put(root, "neck", tube([(0.45, 0, 1.0), (0.65, 0, 1.45)], 0.18), "f4a261")
    put(root, "head", ball(0.3, sx=1.4, sy=0.7, sz=0.8), "f4a261", (0.8, 0, 1.55))
    put(root, "mane", tube([(0.35, 0, 1.25), (0.5, 0, 1.6), (0.65, 0, 1.75)], 0.1), "6d3b1f")
    put(root, "saddle", ball(0.3, sy=0.5, sz=0.15), "118ab2", (-0.05, 0, 1.35))
    put(root, "eye", ball(0.05), None, (0.88, -0.2, 1.62), flat("1a0f24"))


def toy_chest(root):
    put(root, "chest", box(1.6, 0.9, 0.9), "4f772d")
    put(root, "lid", box(1.7, 1.0, 0.18), "90a955", (0, 0, 0.9))
    put(root, "band", box(1.72, 1.02, 0.14), "ffd166", (0, 0, 0.45))
    put(root, "star", ball(0.18, sy=0.3), "ef476f", (0, -0.47, 0.6))
    put(root, "duck", ball(0.22), "ffd60a", (-0.4, 0.1, 1.25))
    put(root, "ball", ball(0.25), "4cc9f0", (0.45, 0, 1.3))


def nursery_door(root):
    put(root, "frame", box(1.4, 0.2, 2.3), "f2e8cf")
    put(root, "door", box(1.15, 0.24, 2.1), "a3c4f3", (0, -0.02, 0.05))
    for z in (0.5, 1.4):
        put(root, f"panel{z}", box(0.8, 0.05, 0.6), "cdb4db", (0, -0.15, z))
    put(root, "knob", ball(0.08), "ffd166", (0.42, -0.2, 1.05))


# ---------------------------------------------------------------- house

def lamp(root):
    put(root, "base", lathe_bm([(0, 0.35), (0.1, 0.3), (0.15, 0.08)], axis="z"), "6c584c")
    put(root, "pole", tube([(0, 0, 0.1), (0, 0, 1.5)], 0.05), "a98467")
    put(root, "shade", lathe_bm([(1.3, 0.45), (1.9, 0.25)], axis="z"), "ffe8a3")
    put(root, "bulb", ball(0.1), None, (0, 0, 1.35), flat("fff3b0"))


def vase(root):
    put(root, "vase", lathe_bm([(0, 0.2), (0.3, 0.38), (0.7, 0.32), (1.0, 0.15), (1.2, 0.22)], axis="z"), "3d5a80")
    put(root, "stripe", lathe_bm([(0.48, 0.38), (0.6, 0.36)], axis="z"), "ee6c4d")
    for i, a in enumerate((-0.4, 0, 0.4)):
        stem = [(0.4 * math.sin(a) * t, 0, 1.1 + 0.6 * t) for t in (j / 5 for j in range(6))]
        put(root, f"stem{i}", tube(stem, 0.025), "52b788")
        put(root, f"bloom{i}", ball(0.14), ("ffafcc", "ffd60a", "cdb4db")[i], stem[-1])


def armchair(root):
    put(root, "seat", box(1.4, 1.1, 0.5), "bc4749", (0, 0, 0.25))
    put(root, "cushion", box(1.0, 0.9, 0.2, bevel=0.08), "e07a5f", (0, -0.05, 0.75))
    put(root, "back", box(1.4, 0.3, 1.0), "bc4749", (0, 0.45, 0.75))
    for s in (-1, 1):
        put(root, f"arm{s}", box(0.25, 1.1, 0.5, bevel=0.1), "a7383a", (s * 0.7, 0, 0.75))
        for y in (-0.4, 0.4):
            put(root, f"foot{s}{y}", box(0.12, 0.12, 0.25), "4a2c2a", (s * 0.55, y, 0))


def tv(root):
    put(root, "stand", box(1.4, 0.6, 0.6), "6c584c")
    put(root, "set", box(1.3, 0.5, 0.9, bevel=0.08), "2b2d42", (0, 0, 0.6))
    put(root, "screen", box(1.05, 0.05, 0.7, bevel=0.05), None, (0, -0.25, 0.7), flat("7bdff2"))
    put(root, "glare", box(0.25, 0.06, 0.4, bevel=0.03), None, (-0.25, -0.27, 0.85), flat("e0fbfc"))
    for s in (-1, 1):
        put(root, f"ear{s}", tube([(0, 0.1, 1.5), (s * 0.4, 0.1, 2.0)], 0.025), "8d99ae")


def fridge(root):
    put(root, "body", box(1.0, 0.85, 2.2, bevel=0.08), "e9ecef")
    put(root, "seam", box(1.02, 0.87, 0.04), "adb5bd", (0, 0, 1.4))
    for z0, z1 in ((0.35, 1.2), (1.6, 2.0)):
        put(root, f"handle{z0}", tube([(0.38, -0.47, z0), (0.38, -0.47, z1)], 0.04), "6c757d")
    for i, (x, z, c) in enumerate([(-0.2, 1.75, "ef476f"), (0.05, 1.85, "ffd166"), (-0.25, 0.9, "06d6a0")]):
        put(root, f"magnet{i}", ball(0.07, sy=0.4), c, (x, -0.44, z))


def front_door(root):
    put(root, "frame", box(1.5, 0.25, 2.4), "f2e8cf")
    put(root, "door", box(1.2, 0.3, 2.2), "9d0208", (0, -0.02, 0.05))
    put(root, "window", ball(0.25, sy=0.2), None, (0, -0.17, 1.75), flat("caf0f8"))
    put(root, "knob", ball(0.08), "ffd166", (0.45, -0.22, 1.05))
    put(root, "mat", box(1.4, 0.7, 0.05), "a98467", (0, -0.5, 0))


# ---------------------------------------------------------------- neighborhood

def mailbox(root):
    put(root, "post", box(0.15, 0.15, 1.0), "8d6346")
    body = lathe_bm([(-0.5, 0.3), (0.5, 0.3)], axis="y", squash=(1, 1.2))
    put(root, "box", transform_bm(body, lambda v: Vector((v.y, v.x, v.z))), "1d3557", (0, 0, 1.25))
    put(root, "flag", box(0.25, 0.06, 0.4), "e63946", (0.1, -0.33, 1.3))


def hydrant(root):
    put(root, "body", lathe_bm([(0, 0.32), (0.15, 0.25), (0.8, 0.25), (0.95, 0.3), (1.15, 0.2), (1.25, 0.05)], axis="z"),
        "e63946")
    for s in (-1, 1):
        put(root, f"nozzle{s}", tube([(s * 0.2, 0, 0.6), (s * 0.42, 0, 0.6)], 0.1), "d62828")
    put(root, "cap", ball(0.12, sy=0.6), "ffd166", (0, -0.27, 0.55))


def fence(root):
    for i in range(5):
        x = -1.0 + 0.5 * i
        put(root, f"picket{i}", box(0.22, 0.08, 1.1), "fefae0", (x, 0, 0))
        put(root, f"tip{i}", lathe_bm([(0, 0.13), (0.2, 0.0)], axis="z", segments=4), "fefae0", (x, 0, 1.1))
    for z in (0.3, 0.8):
        put(root, f"rail{z}", box(2.3, 0.06, 0.12), "e9edc9", (0, 0.07, z))


def tree(root):
    put(root, "trunk", lathe_bm([(0, 0.25), (0.9, 0.17), (1.3, 0.14)], axis="z"), "7f5539")
    for i, (x, y, z, r) in enumerate([(0, 0, 1.6, 0.6), (-0.45, 0, 1.4, 0.45), (0.45, 0, 1.45, 0.45),
                                      (0, -0.2, 2.0, 0.45), (0.25, 0.2, 1.9, 0.4)]):
        put(root, f"leaves{i}", ball(r, seg=16), "52b788", (x, y, z))
    for i, (x, z) in enumerate([(-0.3, 1.65), (0.35, 1.8), (0.05, 2.15)]):
        put(root, f"apple{i}", ball(0.08), "e63946", (x, -0.5, z))


def car(root):
    put(root, "body", box(1.9, 0.95, 0.45, bevel=0.12), "4361ee", (0, 0, 0.2))
    put(root, "cabin", box(1.1, 0.85, 0.42, bevel=0.15), "4361ee", (-0.1, 0, 0.6))
    for s in (-1, 1):
        put(root, f"glass{s}", box(0.95, 0.88, 0.3, bevel=0.1), None, (-0.1, 0, 0.66), flat("bde0fe"))
        for x in (-0.6, 0.6):
            w = lathe_bm([(-0.1, 0.22), (0.1, 0.22)], axis="y")
            put(root, f"wheel{s}{x}", w, "222222", (x, s * 0.45, 0.22))
    put(root, "light", ball(0.08, sy=0.5), None, (0.95, -0.3, 0.42), flat("fff3b0"))
    put(root, "light2", ball(0.08, sy=0.5), None, (0.95, 0.3, 0.42), flat("fff3b0"))


def highway_sign(root):
    for s in (-1, 1):
        put(root, f"post{s}", box(0.1, 0.1, 1.9), "adb5bd", (s * 0.8, 0, 0))
    put(root, "board", box(2.0, 0.08, 0.9, bevel=0.05), "2d6a4f", (0, 0, 1.3))
    put(root, "border", box(1.85, 0.04, 0.75, bevel=0.04), None, (0, -0.04, 1.375), flat("ffffff"))
    put(root, "inner", box(1.75, 0.04, 0.65, bevel=0.03), "2d6a4f", (0, -0.07, 1.425))
    arrow = [(-0.5, 0), (0.2, 0), (0.2, 0.15), (0.55, -0.1), (0.2, -0.35), (0.2, -0.2), (-0.5, -0.2)]
    shape = transform_bm(slab_bm(arrow, 0.04), lambda v: Vector((v.x, -0.1 + v.z, 1.85 + v.y)))
    put(root, "arrow", shape, None, material=flat("ffffff"))


# ---------------------------------------------------------------- world

def water_tower(root):
    for i in range(4):
        a = math.pi / 4 + i * math.pi / 2
        put(root, f"leg{i}", tube([(0.5 * math.cos(a), 0.5 * math.sin(a), 0), (0.3 * math.cos(a), 0.3 * math.sin(a), 1.1)],
                                  0.05), "6c757d")
    put(root, "tank", lathe_bm([(1.0, 0.0), (1.05, 0.55), (1.6, 0.55), (1.95, 0.0)], axis="z"), "90e0ef")
    put(root, "band", lathe_bm([(1.3, 0.565), (1.4, 0.565)], axis="z"), "0077b6")


def radio_mast(root):
    for s in (-1, 1):
        put(root, f"rail{s}", tube([(s * 0.3, 0, 0), (s * 0.05, 0, 2.2)], 0.035), "e63946")
    for i in range(7):
        z = 0.15 + 0.3 * i
        w = 0.3 - 0.25 * z / 2.2
        put(root, f"rung{i}", tube([(-w, 0, z), (w, 0, z + 0.15)], 0.025), "ffffff" if i % 2 else "e63946")
    put(root, "beacon", ball(0.1), None, (0, 0, 2.28), flat("ff006e"))


def skyscraper(root):
    put(root, "tower", box(0.9, 0.9, 2.2, bevel=0.03), "8ecae6")
    put(root, "top", box(0.6, 0.6, 0.4, bevel=0.03), "219ebc", (0, 0, 2.2))
    put(root, "spire", tube([(0, 0, 2.6), (0, 0, 3.0)], 0.03), "adb5bd")
    for r in range(7):
        for c in range(3):
            put(root, f"win{r}{c}", box(0.18, 0.04, 0.16, bevel=0.0), None,
                (-0.27 + 0.27 * c, -0.46, 0.2 + 0.28 * r), flat("ffe066" if (r * 3 + c) % 4 else "023047"))


def cottage(root):
    put(root, "walls", box(1.2, 0.9, 0.8), "f4f1de")
    roof = lathe_bm([(0, 0.95), (0.55, 0.0)], axis="z", segments=4)
    roof = transform_bm(roof, lambda v: Euler((0, 0, math.pi / 4)).to_matrix() @ Vector((v.x * 0.95, v.y * 0.7, v.z)))
    put(root, "roof", roof, "e07a5f", (0, 0, 0.8))
    put(root, "door", box(0.28, 0.05, 0.45), "81b29a", (0, -0.46, 0))
    put(root, "window", box(0.25, 0.05, 0.22), None, (0.35, -0.46, 0.4), flat("ffe066"))


# ---------------------------------------------------------------- effects and icons

def puff(root):
    for i, (x, z, r) in enumerate([(0, 0.5, 0.45), (-0.4, 0.4, 0.32), (0.4, 0.42, 0.34), (0.15, 0.8, 0.3),
                                   (-0.2, 0.78, 0.28)]):
        put(root, f"cloud{i}", ball(r, seg=16), "a7e08d", (x, 0, z))


def dust(root):
    for i, (x, z, r) in enumerate([(0, 0.5, 0.45), (-0.4, 0.4, 0.32), (0.4, 0.42, 0.34), (0.15, 0.8, 0.3)]):
        put(root, f"dust{i}", ball(r, seg=16), "d6ccc2", (x, 0, z))


def turbo_star(root):
    outline = [((0.9 if i % 2 == 0 else 0.4) * math.cos(math.pi / 2 + i * math.pi / 5),
                (0.9 if i % 2 == 0 else 0.4) * math.sin(math.pi / 2 + i * math.pi / 5)) for i in range(10)]
    star = transform_bm(slab_bm(outline, 0.3, taper=0.6), lambda v: Vector((v.x, v.z, v.y + 0.9)))
    put(root, "star", star, "ffd60a")


def lock(root):
    put(root, "body", box(0.8, 0.35, 0.65, bevel=0.08), "ffb703", (0, 0, 0.1))
    put(root, "shackle", tube([(-0.25 * math.cos(a), 0, 0.75 + 0.3 * math.sin(a)) for a in
                               (math.pi * i / 12 for i in range(13))], 0.07), "adb5bd")
    put(root, "hole", ball(0.07, sy=0.3), None, (0, -0.18, 0.4), flat("1a0f24"))


# name: (builder, ortho scale, target height, smashable)
SPRITES = {
    "banana_mash": (banana_mash, 2.0, 0.4, False), "peas_pouch": (peas_pouch, 2.0, 0.6, False),
    "broccoli": (broccoli, 2.0, 0.75, False), "beans": (beans, 2.0, 0.5, False),
    "spicy_chili": (spicy_chili, 2.0, 0.65, False), "taco": (taco, 2.0, 0.5, False),
    "pizza": (pizza, 2.4, 0.1, False), "hot_dog": (hot_dog, 2.2, 0.35, False),
    "ice_cream": (ice_cream, 2.2, 0.95, False), "burrito": (burrito, 2.2, 0.4, False),
    "donut": (donut, 2.4, 0.5, False),
    "blocks": (blocks, 2.6, 0.9, True), "teddy": (teddy, 2.4, 0.95, True),
    "rocking_horse": (rocking_horse, 2.8, 1.0, True), "toy_chest": (toy_chest, 2.6, 0.8, True),
    "nursery_door": (nursery_door, 2.8, 1.15, False),
    "lamp": (lamp, 2.4, 1.0, True), "vase": (vase, 2.4, 0.85, True), "armchair": (armchair, 2.4, 0.7, True),
    "tv": (tv, 2.6, 1.0, True), "fridge": (fridge, 2.8, 1.1, True), "front_door": (front_door, 2.8, 1.15, False),
    "mailbox": (mailbox, 2.2, 0.85, True), "hydrant": (hydrant, 2.0, 0.6, True), "fence": (fence, 2.8, 0.6, True),
    "tree": (tree, 3.0, 1.25, True), "car": (car, 2.6, 0.45, True), "highway_sign": (highway_sign, 2.8, 1.2, False),
    "water_tower": (water_tower, 2.6, 1.05, True), "radio_mast": (radio_mast, 2.8, 1.15, True),
    "skyscraper": (skyscraper, 3.4, 1.5, True), "cottage": (cottage, 2.4, 0.7, True),
    "puff": (puff, 1.8, 0.55, False), "dust": (dust, 1.8, 0.55, False), "turbo_star": (turbo_star, 2.2, 0.9, False),
    "lock": (lock, 2.0, 0.5, False),
}


def topple(root, seed):
    """Knock every part of a prop over into a heap on the floor."""
    rng = random.Random(seed)
    parts = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in parts:
        o.rotation_euler = (rng.uniform(-1.2, 1.2), rng.uniform(-1.2, 1.2), rng.uniform(-0.8, 0.8))
        o.location = Vector((o.location.x, o.location.y, o.location.z * 0.25)) + Vector(
            (rng.uniform(-0.35, 0.35), rng.uniform(-0.2, 0.2), 0))
        o.scale = Vector((1.0, 1.0, 0.6))


def render(name, broken=False):
    build, scale, target, _ = SPRITES[name]
    ink.reset()
    _mats.clear()
    root = empty(name)
    build(root)
    bpy.context.view_layer.update()
    if broken:
        # Parts are built in place around the prop's origin; recentering each on itself lets
        # topple tip it where it stood.
        for o in [o for o in bpy.data.objects if o.type == "MESH"]:
            center = sum((o.matrix_world @ Vector(c) for c in o.bound_box), Vector()) / 8
            o.data.transform(Matrix.Translation(-center))
            o.location = center
        topple(root, zlib.crc32(name.encode()))
    ink.setup_render(bpy.context.scene, ortho_scale=scale * (1.2 if broken else 1.0), target=(0, 0, target * (0.45 if broken else 1.0)))
    ink.render(OUT_DIR / f"{name}{'_broken' if broken else ''}.png")


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    names = argv or list(SPRITES)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name in names:
        render(name)
        if SPRITES[name][3]:
            render(name, broken=True)


if __name__ == "__main__":
    main()
