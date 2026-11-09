"""Comic-ink look shared by every sprite, after Starship Tinkerer's blender/portraits.py.

Flat color, halftone dots that grow as the light falls off, ink hatching in deep shadow, and sketchy
Freestyle brush outlines. Shading is in screen space so the dots stay the same size on every sprite.
"""

import math

import bpy
from mathutils import Vector

# Halftone and hatch spacing, in cells across and down the frame. Sprites render at 256 square,
# so about seven pixels per cell.
CELLS = (37, 37)


def hexc(h):
    """sRGB hex to the linear values Blender's emission expects, so colors land exactly as picked."""
    return tuple((int(h[i:i + 2], 16) / 255) ** 2.2 for i in (0, 2, 4))


INK = hexc("1a0f24")
# Toward the light: upper left, in front of the subject.
LIGHT = Vector((-0.45, -0.6, 0.66)).normalized()


def lerp(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


def flat_material(name, color):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    emit = nt.nodes.new("ShaderNodeEmission")
    emit.inputs["Color"].default_value = (*color, 1)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    return m


def _math(nt, op, a, b, clamp=False):
    n = nt.nodes.new("ShaderNodeMath")
    n.operation = op
    n.use_clamp = clamp
    for i, x in enumerate((a, b)):
        if isinstance(x, (int, float)):
            n.inputs[i].default_value = x
        else:
            nt.links.new(x, n.inputs[i])
    return n.outputs[0]


def _screen(nt, angle):
    """Window coordinates in halftone cells, rotated so dots and hatching run on a diagonal."""
    coord = nt.nodes.new("ShaderNodeTexCoord")
    scale = nt.nodes.new("ShaderNodeVectorMath")
    scale.operation = "MULTIPLY"
    scale.inputs[1].default_value = (*CELLS, 0)
    nt.links.new(coord.outputs["Window"], scale.inputs[0])
    rot = nt.nodes.new("ShaderNodeVectorRotate")
    rot.rotation_type = "Z_AXIS"
    rot.inputs["Angle"].default_value = math.radians(angle)
    nt.links.new(scale.outputs[0], rot.inputs["Vector"])
    return rot.outputs[0]


def _mix(nt, factor, a, b):
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    for slot, v in (("A", a), ("B", b)):
        if isinstance(v, tuple):
            mix.inputs[slot].default_value = (*v, 1)
        else:
            nt.links.new(v, mix.inputs[slot])
    nt.links.new(factor, mix.inputs["Factor"])
    return mix.outputs["Result"]


def comic_material(name, color):
    """Flat color, halftone dots that grow as the light falls off, and ink hatching in deep shadow."""
    shade = lerp(tuple(ch * 0.45 for ch in color), (0.03, 0.0, 0.1), 0.3)
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    # Light is the surface normal against a fixed direction instead of a lamp, so no cast shadows or
    # screen-space occlusion from eyes and cheeks smudge hatching across small faces.
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    facing = nt.nodes.new("ShaderNodeVectorMath")
    facing.operation = "DOT_PRODUCT"
    facing.inputs[1].default_value = LIGHT
    nt.links.new(geo.outputs["Normal"], facing.inputs[0])
    light = _math(nt, "ADD", _math(nt, "MULTIPLY", facing.outputs["Value"], 0.9), 0.2)

    frac = nt.nodes.new("ShaderNodeVectorMath")
    frac.operation = "FRACTION"
    nt.links.new(_screen(nt, 45), frac.inputs[0])
    centered = nt.nodes.new("ShaderNodeVectorMath")
    centered.operation = "SUBTRACT"
    centered.inputs[1].default_value = (0.5, 0.5, 0)
    nt.links.new(frac.outputs[0], centered.inputs[0])
    length = nt.nodes.new("ShaderNodeVectorMath")
    length.operation = "LENGTH"
    nt.links.new(centered.outputs[0], length.inputs[0])
    radius = _math(nt, "MULTIPLY", _math(nt, "MULTIPLY", _math(nt, "SUBTRACT", 0.75, light), 2.2, clamp=True), 0.62)
    dots = _math(nt, "LESS_THAN", length.outputs["Value"], radius)

    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(_screen(nt, -45), sep.inputs[0])
    width = _math(nt, "MULTIPLY", _math(nt, "MULTIPLY", _math(nt, "SUBTRACT", 0.3, light), 3.0, clamp=True), 0.4)
    hatch = _math(nt, "LESS_THAN", _math(nt, "FRACT", sep.outputs[0], 0), width)

    result = _mix(nt, hatch, _mix(nt, dots, color, shade), INK)
    emit = nt.nodes.new("ShaderNodeEmission")
    nt.links.new(result, emit.inputs["Color"])
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(emit.outputs[0], out.inputs["Surface"])
    return m


def ink_lines(scene):
    """Freestyle brush: a slanted nib, tapered ends, two loose passes that overshoot a little."""
    scene.render.use_freestyle = True
    scene.render.line_thickness_mode = "ABSOLUTE"
    layer = scene.view_layers[0]
    layer.use_freestyle = True
    settings = layer.freestyle_settings
    settings.crease_angle = math.radians(135)
    lineset = settings.linesets[0] if settings.linesets else settings.linesets.new("ink")
    for attr in ("select_silhouette", "select_border", "select_crease", "select_contour", "select_external_contour"):
        setattr(lineset, attr, True)
    style = bpy.data.linestyles.new("ink")
    lineset.linestyle = style
    style.color = INK
    style.thickness = 4.0
    style.use_chaining = True
    style.chaining = "SKETCHY"
    style.rounds = 2
    style.geometry_modifiers.new("sample", "SAMPLING").sampling = 2.0
    wobble = style.geometry_modifiers.new("wobble", "PERLIN_NOISE_1D")
    wobble.frequency = 6.0
    wobble.amplitude = 1.5
    wobble.octaves = 2
    style.geometry_modifiers.new("overshoot", "BACKBONE_STRETCHER").backbone_length = 4.2
    nib = style.thickness_modifiers.new("nib", "CALLIGRAPHY")
    nib.orientation = 60
    nib.thickness_min = 1.5
    nib.thickness_max = 5.5
    taper = style.thickness_modifiers.new("taper", "ALONG_STROKE")
    taper.blend = "MULTIPLY"
    taper.mapping = "CURVE"
    curve = taper.curve.curves[0]
    curve.points[0].location = (0.0, 0.1)
    curve.points[1].location = (1.0, 0.1)
    curve.points.new(0.25, 1.0)
    curve.points.new(0.75, 1.0)
    taper.curve.update()



def dress(obj, material):
    obj.data.materials.append(material)
    return obj


def setup_render(scene, ortho_scale, target=(0, 0, 0.5), size=256, lift=4.0):
    """Transparent square render from in front and `lift` above. Materials light themselves (LIGHT)."""
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.film_transparent = True
    scene.render.resolution_x = scene.render.resolution_y = size
    scene.view_settings.view_transform = "Standard"
    scene.world = bpy.data.worlds.new("world")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0

    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = ortho_scale
    target = Vector(target)
    cam.location = target + Vector((0, -6.0, lift))
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    ink_lines(scene)


def render(path):
    bpy.context.scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def reset():
    """Empty scene with no leftover line styles, ready for the next sprite."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for style in list(bpy.data.linestyles):
        bpy.data.linestyles.remove(style)
