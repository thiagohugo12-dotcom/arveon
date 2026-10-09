"""Build transparent 48px explorer frames from the four-view pixel source.

Only a build-time Pillow dependency is needed; Godot consumes the committed PNG.
Rows: down, up, left, right. Columns: idle A/B, walk 0/1/2/3.
"""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source/explorer_views.png"
DEST = ROOT / "assets/art/explorer_atlas.png"
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
    """Recompose limbs, so arm and boot poses change instead of moving a static cutout."""
    result = base.copy()
    stance = (-1, 0, 1, 0)[phase]
    passing = 1 if phase == 1 else -1 if phase == 3 else 0
    bounce = 1 if phase == 1 else 0
    # Waist/torso is stable. Only the lower leg silhouettes and sleeves move.
    result.paste((0, 0, 0, 0), (0, 34, SIZE, SIZE))
    if direction < 2:
        left = base.crop((5, 34, 24, 48))
        right = base.crop((24, 34, 43, 48))
        result.alpha_composite(left, (5 + stance * 3 + passing, 34 - bounce))
        result.alpha_composite(right, (24 - stance * 3 - passing, 34 - bounce))
        # Exposed trousers beneath the belt connect each displaced leg.
        for x in range(17, 31):
            color = base.getpixel((x, 34))
            if color[3] > 0:
                result.putpixel((x, 34), color)
    else:
        # Profiles overlap at the waist, but their boots alternate in depth.
        rear = base.crop((8, 34, 25, 48))
        front = base.crop((25, 34, 43, 48))
        result.alpha_composite(rear, (8 + stance * 2 + passing, 34 - bounce))
        result.alpha_composite(front, (25 - stance * 3 - passing, 34 - bounce))
    # Outer sleeves and gloves swing opposite the advancing leg.
    for x0, x1, sign in ((4, 13, 1), (35, 44, -1)):
        arm = base.crop((x0, 23, x1, 34))
        result.paste((0, 0, 0, 0), (x0, 23, x1, 34))
        result.alpha_composite(arm, (x0, 23 + sign * (stance * 2 + passing)))
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
    print(f"Wrote {DEST.relative_to(ROOT)}: {atlas.size}")


if __name__ == "__main__":
    main()
