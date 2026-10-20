"""Pack the approved golem poses into regular, feet-aligned Godot frames.

This only crops and scales the supplied sheet. It does not redraw the character.
Rows: idle 4, walk 6, attack 6, hit 3, death 6. Frame: 128x96.
"""

from pathlib import Path

from PIL import Image


PROJECT = Path(__file__).resolve().parents[1]
SOURCE = PROJECT.parent / "Registros" / "andar2-guardiao-torre" / "fonte-golem.png"
DEST = PROJECT / "assets" / "art" / "andar2" / "refined" / "sandstone-guardian-atlas.png"
TOWER_SOURCE = SOURCE.with_name("fonte-torre.png")
TOWER_DEST = DEST.with_name("sandstone-ascension-tower.png")
FRAME = (128, 96)
SCALE = 0.43

BOXES = [
    [(15, 15, 235, 190), (240, 15, 465, 190), (470, 15, 705, 190), (710, 15, 945, 190)],
    [(15, 195, 205, 370), (205, 195, 390, 370), (390, 195, 575, 370),
     (575, 195, 760, 370), (760, 195, 945, 370), (945, 195, 1130, 370)],
    [(15, 375, 275, 550), (275, 375, 490, 550), (490, 375, 760, 550),
     (760, 375, 1000, 550), (1000, 375, 1230, 550), (1230, 375, 1440, 550)],
    [(430, 740, 635, 895), (635, 740, 830, 895), (830, 740, 1035, 895)],
    [(15, 900, 245, 1086), (245, 900, 490, 1086), (490, 900, 745, 1086),
     (745, 900, 985, 1086), (985, 900, 1210, 1086), (1210, 900, 1440, 1086)],
]


def keep_character(part: Image.Image) -> Image.Image:
    """Discard fragments from neighboring source poses inside loose row crops."""
    alpha = part.getchannel("A")
    pixels = alpha.load()
    seen = bytearray(part.width * part.height)
    groups: list[list[tuple[int, int]]] = []
    for y in range(part.height):
        for x in range(part.width):
            index = y * part.width + x
            if seen[index] or pixels[x, y] < 90:
                continue
            seen[index] = 1
            stack = [(x, y)]
            group = []
            while stack:
                px, py = stack.pop()
                group.append((px, py))
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1),
                               (px - 1, py - 1), (px + 1, py - 1),
                               (px - 1, py + 1), (px + 1, py + 1)):
                    if 0 <= nx < part.width and 0 <= ny < part.height:
                        ni = ny * part.width + nx
                        if not seen[ni] and pixels[nx, ny] >= 90:
                            seen[ni] = 1
                            stack.append((nx, ny))
            groups.append(group)
    if not groups:
        return part
    largest = max(groups, key=len)
    keep = set(largest)
    source = part.load()
    for y in range(part.height):
        for x in range(part.width):
            if (x, y) not in keep:
                source[x, y] = (0, 0, 0, 0)
    return part


def pack() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    atlas = Image.new("RGBA", (6 * FRAME[0], 5 * FRAME[1]), (0, 0, 0, 0))
    for row, frames in enumerate(BOXES):
        for col, box in enumerate(frames):
            part = source.crop(box)
            pixels = part.load()
            for y in range(part.height):
                for x in range(part.width):
                    r, g, b, a = pixels[x, y]
                    if a and r > 155 and g < 38 and b < 45:
                        pixels[x, y] = (0, 0, 0, 0)  # Stray red sheet fringe.
            part = keep_character(part)
            bounds = part.getchannel("A").getbbox()
            if bounds is None:
                raise ValueError(f"Empty golem frame {row}:{col}")
            part = part.crop(bounds)
            size = (round(part.width * SCALE), round(part.height * SCALE))
            part = part.resize(size, Image.Resampling.NEAREST)
            if part.width > FRAME[0] or part.height > FRAME[1]:
                ratio = min(FRAME[0] / part.width, FRAME[1] / part.height)
                part = part.resize((int(part.width * ratio), int(part.height * ratio)), Image.Resampling.NEAREST)
            x = col * FRAME[0] + (FRAME[0] - part.width) // 2
            y = row * FRAME[1] + FRAME[1] - part.height
            atlas.alpha_composite(part, (x, y))
    DEST.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(DEST)
    print(f"Guardian atlas: {DEST}")
    tower = Image.open(TOWER_SOURCE).convert("RGBA")
    tower.putalpha(tower.getchannel("A").point(lambda a: 255 if a >= 96 else 0))
    tower = tower.crop(tower.getchannel("A").getbbox())
    tower.thumbnail((60, 94), Image.Resampling.LANCZOS)
    alpha = tower.getchannel("A").point(lambda a: 255 if a >= 96 else 0)
    tower.putalpha(alpha)
    tower.save(TOWER_DEST)
    print(f"Floor 2 tower: {TOWER_DEST}")


if __name__ == "__main__":
    pack()
