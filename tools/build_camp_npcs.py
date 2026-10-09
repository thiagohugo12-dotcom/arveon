"""Build two small, transparent camp inhabitants. Run with Pillow at build time."""

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets/art/camp_npcs.png"
INK = "#302b29"
SKIN = "#d9a477"
SHADE = "#ae7355"


def character(kind: int, phase: int) -> Image.Image:
    frame = Image.new("RGBA", (32, 40))
    d = ImageDraw.Draw(frame)
    # Shared 32x40 ground line and consistent head/shoulder proportions.
    d.ellipse((5, 35, 27, 39), fill="#253b32a0")
    d.polygon([(9, 30), (23, 30), (25, 37), (19, 38), (17, 35),
               (15, 35), (13, 38), (7, 37)], fill=INK)
    d.rectangle((8, 33, 13, 37), fill="#554033")
    d.rectangle((19, 33, 24, 37), fill="#554033")
    d.rectangle((7, 37, 14, 38), fill="#312d2b")
    d.rectangle((18, 37, 25, 38), fill="#312d2b")
    tunic = "#685143" if kind == 0 else "#49685b"
    trim = "#9c6d48" if kind == 0 else "#c59a5e"
    d.polygon([(8, 19), (12, 17), (21, 17), (25, 20), (26, 30),
               (22, 33), (9, 33), (6, 29)], fill=INK)
    d.polygon([(10, 19), (21, 19), (23, 30), (10, 31), (8, 28)], fill=tunic)
    d.rectangle((10, 22, 13, 27), fill=trim)
    d.rectangle((11, 29, 22, 30), fill=INK)
    d.rectangle((16, 29, 18, 31), fill=trim)
    # Hair/hat surrounds the face; one pixel eyes remain readable at 1x.
    d.polygon([(10, 9), (13, 5), (20, 5), (23, 9), (23, 16),
               (20, 20), (12, 20), (9, 16)], fill=INK)
    d.polygon([(11, 10), (14, 8), (20, 9), (22, 13), (20, 18),
               (13, 18), (10, 15)], fill=SKIN)
    d.rectangle((12, 15, 14, 17), fill=SHADE)
    d.point((13, 13), fill=INK)
    d.point((20, 13), fill=INK)
    if kind == 0:
        # Forged leather apron and broad shoulders, dark hair, hammer in hand.
        d.polygon([(11, 22), (21, 22), (23, 34), (10, 34)], fill=INK)
        d.polygon([(12, 22), (20, 22), (21, 32), (12, 32)], fill="#ad7750")
        d.rectangle((14, 26, 18, 27), fill="#d49b66")
        d.polygon([(9, 7), (12, 3), (20, 3), (24, 8), (21, 11),
                   (15, 9), (11, 11)], fill="#493628")
        d.rectangle((10, 17, 22, 19), fill="#4b362d")
        d.rectangle((11, 18, 21, 19), fill="#674633")
        arm_y = 25 if phase == 0 else 24
        d.polygon([(5, 20), (10, 20), (11, 27), (8, 30), (4, 27)], fill=INK)
        d.rectangle((5, 22, 8, 26), fill="#c6b28b")
        d.rectangle((4, arm_y, 7, arm_y + 3), fill=SKIN)
        d.polygon([(23, 20), (27, 20), (29, arm_y + 4), (25, arm_y + 6),
                   (22, 26)], fill=INK)
        d.rectangle((25, arm_y, 28, arm_y + 3), fill=SKIN)
        d.rectangle((27, arm_y + 2, 28, 35), fill="#735039")
        d.rectangle((24, arm_y, 30, arm_y + 3), fill="#657477")
        d.rectangle((23, arm_y + 1, 29, arm_y + 2), fill="#a4ae9d")
    else:
        # Traveller cap, small bag and warm sash distinguish the vendor.
        d.polygon([(8, 10), (10, 5), (17, 3), (23, 7), (25, 11),
                   (22, 12), (14, 10), (9, 13)], fill="#66503d")
        d.polygon([(9, 9), (16, 6), (22, 9), (19, 9)], fill="#b08a59")
        d.rectangle((11, 21, 21, 22), fill="#c59a5e")
        d.rectangle((7, 25, 9, 31), fill="#977149")
        d.polygon([(4, 27), (10, 25), (12, 33), (5, 34)], fill=INK)
        d.polygon([(6, 28), (10, 27), (11, 32), (6, 32)], fill="#a7794d")
        d.rectangle((7, 28, 9, 28), fill="#d1ae71")
        arm_y = 27 if phase == 0 else 26
        d.polygon([(23, 20), (27, 21), (28, arm_y), (26, arm_y + 4),
                   (23, 28)], fill=INK)
        d.rectangle((25, arm_y, 28, arm_y + 2), fill=SKIN)
        d.polygon([(6, 20), (10, 20), (9, 26), (6, 28), (4, 26)], fill=INK)
        d.rectangle((5, 24, 8, 27), fill=SKIN)
    return frame


def main() -> None:
    atlas = Image.new("RGBA", (64, 80))
    for kind in range(2):
        for phase in range(2):
            atlas.alpha_composite(character(kind, phase), (phase * 32, kind * 40))
    atlas.save(DEST, optimize=True)
    print(f"Wrote {DEST.relative_to(ROOT)}: {atlas.size}")


if __name__ == "__main__":
    main()
