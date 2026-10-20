"""Build reusable Cerrado sprites and tiled terrain from the approved reference.

The world keeps individual objects and collisions; only terrain pixels are baked.
Run with the bundled Python/Pillow runtime from the project directory.
"""

from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps


PROJECT = Path(__file__).resolve().parents[1]
RECORDS = PROJECT.parent / "Registros" / "andar2-correcao-visual"
ART = PROJECT / "assets" / "art" / "andar2"
OUT = ART / "refined"
SOURCE = RECORDS / "fonte-rochas-arvore.png"
RUINS_SOURCE = RECORDS / "fonte-ruinas-arena.png"
BASE_TERRAIN = RECORDS / "terreno-antes.png"

COLORS = {
    "grass": (217, 188, 85),
    "grass_light": (224, 195, 101),
    "grass_shadow": (191, 176, 82),
    "dry": (225, 193, 110),
    "dry_light": (233, 203, 128),
    "path": (246, 208, 143),
    "path_light": (255, 223, 164),
    "path_edge": (223, 183, 117),
    "path_shadow": (189, 164, 95),
    "arena": (239, 199, 135),
}


def sprite_region(source: Image.Image, box: tuple[int, int, int, int], size: tuple[int, int],
                  content: tuple[int, int, int, int]) -> Image.Image:
    part = source.crop(box)
    alpha_box = part.getchannel("A").getbbox()
    if alpha_box is None:
        raise ValueError(f"Empty sprite region: {box}")
    part = part.crop(alpha_box)
    x0, y0, x1, y1 = content
    part = part.resize((x1 - x0, y1 - y0), Image.Resampling.LANCZOS)
    # One clean alpha threshold keeps the game's nearest-neighbour pixel edge.
    a = part.getchannel("A").point(lambda value: 255 if value >= 96 else 0)
    part.putalpha(a)
    tight = part.getchannel("A").getbbox()
    if tight is None:
        raise ValueError(f"Empty resized sprite region: {box}")
    part = part.crop(tight)
    result = Image.new("RGBA", size, (0, 0, 0, 0))
    result.alpha_composite(part, ((size[0] - part.width) // 2, size[1] - part.height))
    return result


def build_sprites() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    OUT.mkdir(parents=True, exist_ok=True)
    definitions = {
        "sandstone-boulder.png": ((170, 118, 590, 470), (50, 37), (1, 3, 49, 37)),
        "sandstone-outcrop.png": ((710, 128, 1390, 480), (98, 68), (3, 17, 95, 66)),
        "iron-deposit.png": ((170, 630, 630, 1020), (50, 37), (1, 2, 49, 37)),
        "cerrado-tree-medium.png": ((800, 545, 1415, 1030), (72, 76), (2, 3, 70, 76)),
        "cerrado-tree-small.png": ((800, 545, 1415, 1030), (54, 62), (1, 2, 53, 62)),
    }
    for name, (box, size, content) in definitions.items():
        sprite_region(source, box, size, content).save(OUT / name)
    tree = Image.open(OUT / "cerrado-tree-medium.png")
    ImageOps.mirror(tree).save(OUT / "cerrado-tree-medium-b.png")
    canopy = tree.crop((2, 4, 70, 47)).resize((30, 19), Image.Resampling.LANCZOS)
    shrub = Image.new("RGBA", (31, 21), (0, 0, 0, 0))
    shrub.alpha_composite(canopy, (0, 2))
    shrub.save(OUT / "cerrado-shrub.png")
    ImageOps.mirror(shrub).save(OUT / "cerrado-shrub-b.png")
    ruins = Image.open(RUINS_SOURCE).convert("RGBA")
    ruin_definitions = {
        "ruin-pillar.png": ((150, 65, 565, 560), (32, 56), (2, 1, 30, 56)),
        "ruin-marker.png": ((150, 65, 565, 560), (32, 46), (3, 2, 29, 46)),
        "ruin-wall.png": ((775, 250, 1315, 565), (78, 33), (1, 5, 77, 33)),
        "ruin-altar.png": ((105, 645, 720, 1015), (68, 47), (1, 3, 67, 47)),
        "arena-stones.png": ((785, 565, 1365, 1050), (98, 68), (2, 2, 96, 68)),
    }
    for name, (box, size, content) in ruin_definitions.items():
        sprite_region(ruins, box, size, content).save(OUT / name)
    ImageOps.mirror(Image.open(OUT / "ruin-pillar.png")).save(OUT / "ruin-pillar-b.png")
    ImageOps.mirror(Image.open(OUT / "ruin-marker.png")).save(OUT / "ruin-marker-b.png")


def palette_tile(base: tuple[int, int, int], seed: int, category: str) -> Image.Image:
    rng = random.Random(seed)
    im = Image.new("RGB", (32, 32), base)
    draw = ImageDraw.Draw(im)
    speckles = 14 if category == "path" else 18
    for _ in range(speckles):
        x, y = rng.randrange(2, 31), rng.randrange(2, 31)
        if category == "path":
            tone = tuple(min(255, v + 8) for v in base) if rng.randrange(3) else tuple(max(0, v - 11) for v in base)
            w, h = rng.choice([(1, 1), (2, 1), (3, 1)])
        else:
            tone = tuple(max(0, v - 12) for v in base) if rng.randrange(3) else tuple(min(255, v + 8) for v in base)
            w, h = rng.choice([(1, 1), (2, 1), (2, 2)])
        draw.rectangle((x, y, x + w, y + h), fill=tone)
    return im


def build_tiles() -> dict[str, list[Image.Image]]:
    atlas = Image.new("RGB", (128, 32 * len(COLORS)))
    result: dict[str, list[Image.Image]] = {}
    for row, (key, color) in enumerate(COLORS.items()):
        category = "path" if key.startswith("path") else "field"
        variants = [palette_tile(color, 381 + row * 17 + i * 97, category) for i in range(4)]
        for col, tile in enumerate(variants):
            atlas.paste(tile, (col * 32, row * 32))
        result[key] = variants
    atlas.save(OUT / "terrain-tiles.png")
    return result


def in_quarry(x: int, y: int) -> bool:
    dx = (x - 250) / 235.0
    dy = (y - 153) / 157.0
    return dx * dx + dy * dy < 1.0


def field_noise(x: float, y: float, cell: int, seed: int) -> float:
    gx, gy = math.floor(x / cell), math.floor(y / cell)
    fx, fy = x / cell - gx, y / cell - gy
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)

    def value(ix: int, iy: int) -> float:
        n = (ix * 374761393 + iy * 668265263 + seed * 1442695041) & 0xFFFFFFFF
        n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
        return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0

    a = value(gx, gy) * (1 - fx) + value(gx + 1, gy) * fx
    b = value(gx, gy + 1) * (1 - fx) + value(gx + 1, gy + 1) * fx
    return a * (1 - fy) + b * fy


def build_terrain(quarry_only: bool) -> None:
    original = Image.open(BASE_TERRAIN).convert("RGB")
    output = original.copy()
    tiles = build_tiles()
    reverse = {color: key for key, color in COLORS.items()}
    source_pixels = original.load()
    result_pixels = output.load()
    kinds: list[list[str | None]] = [[None] * original.width for _ in range(original.height)]
    for y in range(original.height):
        for x in range(original.width):
            if quarry_only and not in_quarry(x, y):
                continue
            key = reverse.get(source_pixels[x, y])
            if key is None:
                continue
            # Distorcer somente categorias de solo conserva a planta, a arena,
            # o piso das ruinas e os objetos interativos no lugar original.
            dx = round((field_noise(x, y, 26, 11) - 0.5) * 12)
            dy = round((field_noise(x, y, 31, 27) - 0.5) * 12)
            warped = reverse.get(source_pixels[min(original.width - 1, max(0, x + dx)),
                                               min(original.height - 1, max(0, y + dy))])
            if warped is not None:
                key = warped
            kinds[y][x] = key
            variant = ((x // 32) * 17 + (y // 32) * 23) % 4
            result_pixels[x, y] = tiles[key][variant].getpixel((x % 32, y % 32))
    # Desgaste curto nas bordas: a trilha invade e cede ao campo em pequenos
    # trechos. A máscara original mantém largura e conexão das rotas.
    path_keys = {"path", "path_light", "path_edge", "path_shadow"}
    for y in range(3, original.height - 3):
        for x in range(3, original.width - 3):
            if quarry_only and not in_quarry(x, y):
                continue
            key = kinds[y][x]
            if key is None:
                continue
            checksum = (x * 2017 + y * 7309 + x * y * 13) % 101
            if key in path_keys and checksum < 16:
                for distance in (1, 2, 3):
                    neighbors = ((x - distance, y), (x + distance, y),
                                 (x, y - distance), (x, y + distance))
                    ground = next((COLORS[kinds[ny][nx]] for nx, ny in neighbors
                                   if kinds[ny][nx] in
                                   {"grass", "grass_light", "grass_shadow", "dry", "dry_light"}), None)
                    if ground is not None:
                        result_pixels[x, y] = ground
                        break
            elif key in {"grass", "grass_light", "grass_shadow", "dry", "dry_light"} and checksum < 10:
                adjacent_path = any(kinds[ny][nx] in path_keys
                                    for nx, ny in ((x - 1, y), (x + 1, y),
                                                   (x, y - 1), (x, y + 1)))
                if adjacent_path:
                    result_pixels[x, y] = COLORS["path_edge"]
    # Tufts e pontos secos pequenos, fixos por semente. Sao detalhes do solo,
    # nao obstaculos: caminhos, acampamento, ruinas e arena ficam livres.
    rng = random.Random(12026)
    draw = ImageDraw.Draw(output)
    for _ in range(420 if not quarry_only else 105):
        x, y = rng.randrange(8, original.width - 8), rng.randrange(8, original.height - 8)
        if quarry_only and not in_quarry(x, y):
            continue
        if kinds[y][x] not in {"grass", "grass_light", "grass_shadow", "dry", "dry_light"}:
            continue
        if any(kinds[y + oy][x + ox] in path_keys for ox, oy in
               ((0, 0), (-5, 0), (5, 0), (0, -5), (0, 5))):
            continue
        if 95 < x < 275 and 360 < y < 510:
            continue
        if 455 < x < 705 and y < 285:
            continue
        if x > 540 and y > 460:
            continue
        color = rng.choice(((113, 128, 59), (126, 136, 63), (145, 145, 68)))
        draw.line((x - 2, y, x - 1, y - 2), fill=color)
        draw.line((x, y + 1, x, y - 3), fill=color)
        draw.line((x + 1, y, x + 2, y - 2), fill=color)
        if rng.randrange(7) == 0:
            draw.point((x, y - 4), fill=(241, 224, 156))
    if not quarry_only:
        # O piso da arena era o unico grande disco cinza: aproximar ao
        # arenito quente da referencia sem tocar em seus riscos e bordas.
        for y in range(original.height):
            for x in range(original.width):
                if source_pixels[x, y] == (205, 187, 131):
                    variant = ((x // 32) * 17 + (y // 32) * 23) % 4
                    result_pixels[x, y] = tiles["arena"][variant].getpixel((x % 32, y % 32))
    output.save(OUT / ("terrain-quarry.png" if quarry_only else "terrain-full.png"))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--full", action="store_true", help="Apply terrain textures to the whole floor")
    args = parser.parse_args()
    build_sprites()
    build_terrain(quarry_only=not args.full)
