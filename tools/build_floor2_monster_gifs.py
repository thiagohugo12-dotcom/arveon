"""Build shareable GIFs from real frames captured in the Godot preview."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT.parent / "Registros" / "andar2-monstros-animacoes"
FRAMES = OUT / "frames"
STATES = {
    "goblin_garimpeiro": ["idle", "walk", "attack", "hit", "death"],
    "tatu_rochoso": ["idle", "walk", "charge", "hit", "death"],
    "escorpiao_da_chapada": ["idle", "walk", "attack", "hit", "death"],
}
COUNTS = [4, 6, 6, 3, 6]
DURATION = {"idle": 210, "walk": 110, "attack": 120, "charge": 110, "hit": 170, "death": 170}

for name, states in STATES.items():
    images = []
    timings = []
    for state, count in zip(states, COUNTS):
        for frame in range(count):
            path = FRAMES / f"{name}-{state}-{frame:02d}.png"
            image = Image.open(path).convert("RGB").crop((0, 0, 960, 390))
            image = image.resize((640, 260), Image.Resampling.NEAREST)
            images.append(image)
            timings.append(DURATION[state])
        timings[-1] += 220 if state != "death" else 700
    palette = images[0].quantize(colors=192, method=Image.Quantize.MEDIANCUT)
    indexed = [image.quantize(palette=palette, dither=Image.Dither.NONE) for image in images]
    target = OUT / f"{name}.gif"
    indexed[0].save(target, save_all=True, append_images=indexed[1:], loop=0,
                    duration=timings, optimize=True, disposal=2)
    print(f"{target.name}: {len(images)} frames, {target.stat().st_size:,} bytes")
