"""Build transparent 48px explorer frames from the four-view pixel source.

Only a build-time Pillow dependency is needed; Godot consumes the committed PNG.
Rows: down, up, left, right. Columns: idle A/B, walk 0/1/2/3.
"""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source/explorer_views.png"
DEST = ROOT / "assets/art/explorer_atlas.png"
PREVIEW = ROOT / "docs/art/EXPLORER_WALK_V035.gif"
SIZE = 48
# Source views were individually cut and reduced from the reference study.
BOXES = [
    (0, 0, 48, 48),      # down
    (48, 0, 96, 48),    # up
    (144, 0, 192, 48),  # left: face points to image left
    (96, 0, 144, 48),   # right: face points to image right
]


def transparent() -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def source_view(image: Image.Image, box: tuple[int, ...]) -> Image.Image:
    return image.crop(box)


def idle(base: Image.Image, phase: int) -> Image.Image:
    if phase == 0:
        return base.copy()
    # A one-pixel breath at the scarf/shoulders; feet stay planted.
    result = base.copy()
    upper = base.crop((0, 0, SIZE, 33))
    result.paste((0, 0, 0, 0), (0, 0, SIZE, 33))
    result.alpha_composite(upper, (0, 1))
    return result


def walk(base: Image.Image, direction: int, phase: int) -> Image.Image:
    """Four footfall poses: left contact, right passing, right contact, left passing.

    Contact feet remain on the source ground line; a passing boot lifts two pixels.
    Limbs move independently while the scarf, pack, head and torso keep their anchor.
    """
    result = base.copy()
    result.paste((0, 0, 0, 0), (0, 34, SIZE, SIZE))
    if direction < 2:
        boxes = [(8, 34, 24, 47), (24, 34, 42, 47)]
    else:
        boxes = [(9, 34, 25, 47), (25, 34, 43, 47)]
    # x shifts stay small and never change leg width. y=0 is the planted sole.
    offsets = [((-1, 0), (1, -2)), ((1, 0), (-2, -2)),
               ((-1, -2), (1, 0)), ((2, -2), (-1, 0))][phase]
    # The lifted limb goes behind the planted one. The belt is restored last.
    order = (1, 0) if phase < 2 else (0, 1)
    for index in order:
        x0, y0, x1, y1 = boxes[index]
        dx, dy = offsets[index]
        leg = base.crop((x0, y0, x1, y1))
        result.alpha_composite(leg, (x0 + dx, y0 + dy))
        # Two tiny hip bridges prevent a detached leg at the waist.
        hip_x = 18 if index == 0 else 29
        for y in range(34, 36):
            color = base.getpixel((hip_x, y))
            if color[3]:
                result.putpixel((hip_x + dx // 2, y), color)
    # Stable belt and tunic cover the hip seams; sleeves swing in counterphase.
    result.alpha_composite(base.crop((0, 30, SIZE, 34)), (0, 30))
    swing = (-1, 0, 1, 0)[phase]
    arms = ((5, 15), (33, 43)) if direction < 2 else ((31, 43),)
    for arm_index, (x0, x1) in enumerate(arms):
        arm = base.crop((x0, 25, x1, 34))
        result.paste((0, 0, 0, 0), (x0, 25, x1, 34))
        offset = swing if arm_index == 0 else -swing
        result.alpha_composite(arm, (x0, 25 + offset))
    return result


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    assert source.size == (192, 48), "Unexpected source crop dimensions"
    atlas = Image.new("RGBA", (SIZE * 6, SIZE * 4), (0, 0, 0, 0))
    for direction, box in enumerate(BOXES):
        base = source_view(source, box)
        frames = [idle(base, 0), idle(base, 1)] + [walk(base, direction, i) for i in range(4)]
        for column, frame in enumerate(frames):
            atlas.alpha_composite(frame, (column * SIZE, direction * SIZE))
    atlas.save(DEST, optimize=True)
    preview_frames = []
    for phase in range(4):
        sheet = Image.new("RGBA", (SIZE * 4, SIZE), "#477b49")
        for direction in range(4):
            sheet.alpha_composite(atlas.crop(((phase + 2) * SIZE, direction * SIZE,
                                             (phase + 3) * SIZE, (direction + 1) * SIZE)),
                                  (direction * SIZE, 0))
        preview_frames.append(sheet.resize((SIZE * 12, SIZE * 3), Image.Resampling.NEAREST).convert("RGB"))
    preview_frames[0].save(PREVIEW, save_all=True, append_images=preview_frames[1:],
                           duration=160, loop=0, optimize=True)
    print(f"Wrote {DEST.relative_to(ROOT)}: {atlas.size}")


if __name__ == "__main__":
    main()
