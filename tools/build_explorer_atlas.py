"""Build transparent 48px explorer frames from the four-view pixel source.

Only a build-time Pillow dependency is needed; Godot consumes the committed PNG.
Rows: down, up, left, right. Columns: idle A/B, walk 0/1/2/3.
"""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source/explorer_views.png"
DEST = ROOT / "assets/art/explorer_atlas.png"
PREVIEW = ROOT / "docs/art/EXPLORER_WALK_V036.gif"
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
    frame = image.crop(box)
    if box[0] == 0:
        # Two readable eyes at native size; the hair and broad scarf remain the
        # recognisable silhouette from the approved explorer.
        frame.putpixel((20, 16), (53, 38, 35, 255))
        frame.putpixel((29, 16), (53, 38, 35, 255))
    return frame


def idle(base: Image.Image, phase: int) -> Image.Image:
    if phase == 0:
        return base.copy()
    # Only the scarf fringe breathes; the whole head/torso never jumps.
    result = base.copy()
    fringe = base.crop((14, 20, 32, 23))
    result.paste((0, 0, 0, 0), (14, 20, 32, 23))
    result.alpha_composite(fringe, (14, 21))
    return result


def walk(base: Image.Image, direction: int, phase: int) -> Image.Image:
    """Alternating contact/passing boots on one ground line, fixed torso anchor."""
    result = base.copy()
    result.paste((0, 0, 0, 0), (0, 34, SIZE, SIZE))
    # Existing hand-drawn boots remain intact; move each independently by at
    # most two pixels. Contact soles stay on the original y=45 baseline.
    boxes = [(10, 34, 24, 47), (25, 34, 41, 47)] if direction < 2 else [
        (10, 34, 25, 47), (25, 34, 41, 47)]
    offsets = [((-1, 0), (1, -2)), ((1, 0), (-1, -1)),
               ((-1, -2), (1, 0)), ((1, -1), (-1, 0))][phase]
    order = (1, 0) if phase < 2 else (0, 1)
    for index in order:
        x0, y0, x1, y1 = boxes[index]
        dx, dy = offsets[index]
        leg = base.crop((x0, y0, x1, y1))
        result.alpha_composite(leg, (x0 + dx, y0 + dy))
        # Bridge the thigh to the planted hips without stretching the boot.
        hip_x = 18 if index == 0 else 30
        for y in range(34, 36):
            color = base.getpixel((hip_x, y))
            if color[3]:
                result.putpixel((hip_x + dx // 2, y), color)
    result.alpha_composite(base.crop((0, 30, SIZE, 34)), (0, 30))
    swing = (-1, 0, 1, 0)[phase]
    arms = ((5, 15), (33, 43)) if direction < 2 else ((31, 43),)
    for arm_index, (x0, x1) in enumerate(arms):
        arm = base.crop((x0, 25, x1, 34))
        result.paste((0, 0, 0, 0), (x0, 25, x1, 34))
        result.alpha_composite(arm, (x0, 25 + (swing if arm_index == 0 else -swing)))
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
