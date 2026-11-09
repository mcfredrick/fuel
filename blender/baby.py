"""Render the fart-propelled baby: six poses at each of four stages, comic-inked on transparent backgrounds.

Run: Blender -b --python blender/baby.py -- [stage ...]
Writes godot_web_game/assets/baby/baby<stage>_<pose>.png.

The baby faces -Y (the camera), +Z is up. Poses move the face and arms; each stage keeps everything
from the stage before and adds one thing (bib, cape, crown).
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import ink  # noqa: E402
from ink import dress, hexc  # noqa: E402
from kit_common import empty, lathe_bm, mesh_obj, slab_bm, sphere_bm, transform_bm, tube_bm  # noqa: E402

OUT_DIR = Path(__file__).resolve().parent.parent / "godot_web_game" / "assets" / "baby"
HEAD = (0.62, 0.55, 0.58)
HEAD_Z = 1.25

# brow: (height, inner tilt) per side, eye: openness or "arc" (happily shut) or "squeeze" (straining),
# mouth: (smile -1..1, open 0..1, width), arms: shoulder angle in degrees (0 down, 90 out, 160 up),
# fists: arms reach toward the camera.
POSES = {
    "idle": {"brow": ((0.0, 0.0), (0.0, 0.0)), "eye": 1.0, "mouth": (0.6, 0.0, 0.9), "arms": 35, "blush": 0.4},
    "toot": {"brow": ((-0.02, 0.35), (-0.02, 0.35)), "eye": "squeeze", "mouth": (-0.2, 0.25, 0.45), "arms": 20,
             "blush": 1.0, "kick": 1.0},
    "turbo": {"brow": ((0.1, 0.15), (0.1, 0.15)), "eye": "arc", "mouth": (1.0, 0.6, 1.2), "arms": 125,
              "blush": 0.7, "kick": 1.0},
    "smash": {"brow": ((-0.05, -0.4), (-0.05, -0.4)), "eye": 0.8, "mouth": (-0.3, 0.8, 1.15), "arms": 80,
              "fists": True, "blush": 0.6},
    "chomp": {"brow": ((0.12, 0.1), (0.12, 0.1)), "eye": 1.15, "mouth": (0.2, 1.0, 1.0), "arms": 55, "blush": 0.5},
    "sad": {"brow": ((0.05, 0.4), (0.05, 0.4)), "eye": 0.7, "mouth": (-0.8, 0.0, 0.8), "arms": 10, "blush": 0.2,
            "tear": True},
}

SKIN = hexc("f6cdb0")
COLORS = {
    "skin": SKIN, "blush": hexc("f48a8a"), "diaper": hexc("f6f7ff"), "tape": hexc("8fb6ff"),
    "hair": hexc("5a3b22"), "bib": hexc("ffd166"), "bib_trim": hexc("ef476f"), "cape": hexc("d62839"),
    "cape_lining": hexc("ffcf3f"), "crown": hexc("ffc93c"), "gem": hexc("3fa7ff"),
}


def face_point(x, z, out=0.0):
    """Point on the front of the head ellipsoid at (x, z), pushed `out` toward the camera."""
    rx, ry, rz = HEAD
    k = max(1 - (x / rx) ** 2 - (z / rz) ** 2, 0.02)
    return Vector((x, -ry * math.sqrt(k) - out, z))


def eyes(p, mats, head):
    for side in (-1, 1):
        base = face_point(side * 0.24, 0.02, out=-0.03)
        if p["eye"] in ("arc", "squeeze"):
            # Happy arcs curve up; a strain squeezes into sideways chevrons pointing at the nose.
            if p["eye"] == "arc":
                pts = [base + Vector(((i / 8 - 0.5) * 0.2, -0.05, 0.05 * math.sin(math.pi * i / 8))) for i in range(9)]
            else:
                pts = [base + Vector((side * (0.08 - 0.08 * abs(i / 4 - 1)) - side * 0.02, -0.05, (i / 4 - 1) * 0.07))
                       for i in range(9)]
            dress(mesh_obj(f"lid{side}", tube_bm(pts, [0.024] * 9, 8), head), mats["line"])
            continue
        open_ = p["eye"]
        white = sphere_bm(0.11, 24, 12, lambda v: Vector((v.x, v.y * 0.6, v.z * 1.15 * open_)))
        dress(mesh_obj(f"white{side}", transform_bm(white, lambda v: v + base), head), mats["white"])
        pupil_at = base + Vector((0, -0.06, -0.01))
        iris = sphere_bm(0.075, 16, 8, lambda v: Vector((v.x, v.y * 0.4, v.z * 1.1 * min(open_, 1.0))))
        dress(mesh_obj(f"iris{side}", transform_bm(iris, lambda v: v + pupil_at), head), mats["iris"])
        glint = sphere_bm(0.024, 8, 4)
        dress(mesh_obj(f"glint{side}", transform_bm(glint, lambda v: v + pupil_at + Vector((-0.025, -0.04, 0.03))),
                       head), mats["white"])


def brows(p, mats, head):
    for side, (height, tilt) in zip((-1, 1), p["brow"]):
        pts = []
        for i in range(7):
            u = i / 6
            x = side * (0.24 - 0.09 + 0.18 * u)
            # The camera looks down, so inner ends (nearer the camera) read low; lift them to look level.
            z = 0.2 + height + tilt * 0.3 * ((1 - u) - 0.5) + 0.035 * (1 - u)
            pts.append(face_point(x, z, out=0.02))
        if side < 0:
            pts.reverse()
        dress(mesh_obj(f"brow{side}", tube_bm(pts, [0.022] * 7, 8), head), mats["line"])


def mouth(p, mats, head):
    smile, open_, width = p["mouth"]
    w = 0.13 * width
    z0 = -0.25
    if open_ > 0:
        cavity = sphere_bm(1.0, 24, 12, lambda v: Vector((v.x * w * 0.95, v.y * 0.05,
                                                          v.z * 0.22 * open_ if v.z < 0 else v.z * 0.03)))
        at = face_point(0, z0 - 0.03 * open_, out=-0.02)
        dress(mesh_obj("cavity", transform_bm(cavity, lambda v: v + at), head), mats["mouth"])
        tongue = sphere_bm(1.0, 16, 8, lambda v: Vector((v.x * w * 0.55, v.y * 0.05, v.z * 0.07 * open_)))
        at_t = face_point(0, z0 - 0.11 * open_, out=0.0)
        dress(mesh_obj("tongue", transform_bm(tongue, lambda v: v + at_t), head), mats["tongue"])
    pts = [face_point(u * w, z0 + smile * 0.06 * (u * u - 0.5), out=0.015) for u in ((i / 8) * 2 - 1 for i in range(9))]
    dress(mesh_obj("lips", tube_bm(pts, [0.016] * 9, 8), head), mats["line"])


def cheeks(p, mats, head):
    if p["blush"] <= 0:
        return
    for side in (-1, 1):
        at = face_point(side * 0.4, -0.13, out=-0.01)
        r = 0.08 + 0.04 * p["blush"]
        blob = sphere_bm(r, 16, 8, lambda v: Vector((v.x, v.y * 0.3, v.z * 0.7)))
        dress(mesh_obj(f"blush{side}", transform_bm(blob, lambda v: v + at), head), mats["blush"])


def tear(mats, head):
    at = face_point(0.3, -0.12, out=0.02)
    drop = sphere_bm(0.05, 12, 8, lambda v: Vector((v.x, v.y * 0.5, v.z * 1.5 if v.z > 0 else v.z)))
    dress(mesh_obj("tear", transform_bm(drop, lambda v: v + at), head), mats["tear"])


def curl(mats, head):
    pts = [Vector((0.08 * math.cos(t) * (1 - t / 9), -0.15 + 0.08 * math.sin(t) * (1 - t / 9), HEAD[2] + 0.02 + 0.03 * t))
           for t in (i * 0.45 for i in range(14))]
    dress(mesh_obj("curl", tube_bm(pts, [0.03] * 14, 8), head), mats["hair"])


def limb(name, start, end, radius, mats, root, hand=0.0):
    pts = [start.lerp(end, i / 6) for i in range(7)]
    dress(mesh_obj(name, tube_bm(pts, [radius] * 7, 12), root), mats["skin"])
    if hand:
        dress(mesh_obj(f"{name}_hand", transform_bm(sphere_bm(hand, 16, 8), lambda v: v + end), root), mats["skin"])


def body(p, mats, root):
    torso = sphere_bm(1.0, 32, 16, lambda v: Vector((v.x * 0.55, v.y * 0.45, v.z * 0.5)))
    dress(mesh_obj("torso", transform_bm(torso, lambda v: v + Vector((0, 0, 0.5))), root), mats["skin"])
    diaper = sphere_bm(1.0, 32, 16, lambda v: Vector((v.x * 0.6, v.y * 0.5, v.z * 0.32)))
    dress(mesh_obj("diaper", transform_bm(diaper, lambda v: v + Vector((0, 0, 0.22))), root), mats["diaper"])
    for side in (-1, 1):
        tab = sphere_bm(0.09, 12, 6, lambda v: Vector((v.x, v.y * 0.4, v.z * 0.6)))
        dress(mesh_obj(f"tape{side}", transform_bm(tab, lambda v: v + Vector((side * 0.36, -0.42, 0.33))), root),
              mats["tape"])
        # The baby never walks: legs fold up like it's sitting on its own fart cloud. Straining
        # poses kick the feet out wider.
        kick = p.get("kick", 0.0)
        hip = Vector((side * 0.26, -0.1, 0.15))
        knee = Vector((side * (0.36 + 0.1 * kick), -0.5, 0.2 + 0.1 * kick))
        foot = Vector((side * (0.4 + 0.15 * kick), -0.55, -0.05 + 0.12 * kick))
        limb(f"thigh{side}", hip, knee, 0.15, mats, root)
        limb(f"shin{side}", knee, foot, 0.13, mats, root, hand=0.15)
        shoulder = Vector((side * 0.42, 0, 0.72))
        a = math.radians(p["arms"])
        reach = 0.6
        hand_at = shoulder + Vector((side * math.sin(a) * reach, -0.35 * reach if p.get("fists") else -0.1,
                                     -math.cos(a) * reach))
        limb(f"arm{side}", shoulder, hand_at, 0.11, mats, root, hand=0.15 if p.get("fists") else 0.12)


def head(p, mats, root):
    h = empty("head", root, loc=(0, 0, HEAD_Z))
    skull = sphere_bm(1.0, 48, 24, lambda v: Vector((v.x * HEAD[0], v.y * HEAD[1], v.z * HEAD[2])))
    dress(mesh_obj("skull", skull, h), mats["skin"])
    for side in (-1, 1):
        ear = sphere_bm(0.12, 16, 8, lambda v: Vector((v.x * 0.5, v.y, v.z * 1.2)))
        dress(mesh_obj(f"ear{side}", transform_bm(ear, lambda v: v + Vector((side * HEAD[0] * 0.98, 0.05, 0))), h),
              mats["skin"])
    eyes(p, mats, h)
    brows(p, mats, h)
    mouth(p, mats, h)
    cheeks(p, mats, h)
    if p.get("tear"):
        tear(mats, h)
    curl(mats, h)
    return h


def bib(mats, root):
    shape = [(0.3 * math.cos(a), 0.26 * math.sin(a) - 0.1) for a in (math.pi + math.pi * i / 16 for i in range(17))]
    plate = slab_bm(shape + [(0.18, 0.02), (-0.18, 0.02)], 0.04)
    plate = transform_bm(plate, lambda v: Vector((v.x, -0.5 + v.z - 0.25 * v.y, 0.78 + v.y)))
    dress(mesh_obj("bib", plate, root), mats["bib"])
    trim = [Vector((0.31 * math.cos(a), -0.48 + 0.07 * math.sin(a), 0.68 + 0.27 * math.sin(a))) for a in (math.pi + math.pi * i / 16 for i in range(17))]
    dress(mesh_obj("bib_trim", tube_bm(trim, [0.025] * 17, 8), root), mats["bib_trim"])


def cape(mats, root):
    outline = [(-0.45, 0.9), (0.45, 0.9), (0.75, -0.1), (0.35, 0.0), (0.0, -0.15), (-0.35, 0.0), (-0.75, -0.1)]
    cloth = slab_bm(outline, 0.05)
    cloth = transform_bm(cloth, lambda v: Vector((v.x, 0.45 + 0.15 * (0.9 - v.y), v.y + v.z)))
    dress(mesh_obj("cape", cloth, root), mats["cape"])
    tie = [Vector((0.38 * math.cos(a), -0.1 + 0.36 * math.sin(a) * 0.0 - 0.3 * abs(math.sin(a)), 0.92))
           for a in (math.pi * i / 10 for i in range(11))]
    dress(mesh_obj("cape_tie", tube_bm(tie, [0.035] * 11, 8), root), mats["cape_lining"])


def crown(mats, h):
    z = HEAD[2] - 0.12
    band = lathe_bm([(z, 0.36), (z + 0.14, 0.38)], axis="z", segments=40)
    dress(mesh_obj("crown_band", band, h), mats["crown"])
    for i in range(5):
        a = math.pi / 2 + (i - 2) * 0.55 + math.pi
        at = Vector((0.37 * math.cos(a), 0.37 * math.sin(a), z + 0.14))
        spike = lathe_bm([(0.0, 0.09), (0.2, 0.0)], axis="z", segments=12)
        dress(mesh_obj(f"crown_spike{i}", transform_bm(spike, lambda v, at=at: v + at), h), mats["crown"])
        ball = sphere_bm(0.035, 10, 6)
        dress(mesh_obj(f"crown_ball{i}", transform_bm(ball, lambda v, at=at: v + at + Vector((0, 0, 0.21)))
                       , h), mats["crown"])
    gem = sphere_bm(0.06, 12, 8, lambda v: Vector((v.x, v.y * 0.5, v.z * 1.2)))
    dress(mesh_obj("gem", transform_bm(gem, lambda v: v + Vector((0, -0.38, z + 0.07))), h), mats["gem"])


def materials():
    comic, flat = ink.comic_material, ink.flat_material
    mats = {k: comic(k, COLORS[k]) for k in ("skin", "diaper", "tape", "hair", "bib", "bib_trim", "cape",
                                             "cape_lining", "crown", "gem")}
    mats.update({
        "white": flat("white", (1, 1, 1)), "iris": flat("iris", hexc("2b1d3a")), "line": flat("line", ink.INK),
        "mouth": flat("mouth", hexc("6b0f2e")), "tongue": flat("tongue", hexc("f0607a")),
        "blush": flat("blush", COLORS["blush"]), "tear": flat("tear", hexc("9fdcff")),
    })
    return mats


def build(stage, pose):
    p = POSES[pose]
    mats = materials()
    root = empty("baby")
    body(p, mats, root)
    h = head(p, mats, root)
    if stage >= 1:
        bib(mats, root)
    if stage >= 2:
        cape(mats, root)
    if stage >= 3:
        crown(mats, h)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    stages = [int(s) for s in argv] or [0, 1, 2, 3]
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for stage in stages:
        for pose in POSES:
            ink.reset()
            build(stage, pose)
            ink.setup_render(bpy.context.scene, ortho_scale=2.9, target=(0, 0, 0.95), lift=2.0)
            ink.render(OUT_DIR / f"baby{stage}_{pose}.png")


if __name__ == "__main__":
    main()
