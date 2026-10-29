"""Pair actual Godot captures from before and after the Floor 2 art revision."""

from pathlib import Path

from PIL import Image, ImageDraw


RECORDS = Path(__file__).resolve().parents[2] / "Registros" / "andar2-correcao-visual"
BEFORE = RECORDS / "antes"
AFTER = RECORDS / "versao-refinada"
OUT = RECORDS / "comparacoes"

NAMES = {
    "visao-geral": "Visao geral",
    "pedreira-dourada": "Pedreira Dourada",
    "ruinas-da-chapada": "Ruinas da Chapada",
    "arena-do-colosso": "Arena do Colosso",
    "campos-e-perigo": "Campos e Regiao Perigosa",
    "area-segura": "Area Segura",
    "celular-vertical": "Exploracao vertical",
    "acampamento-celular-vertical": "Acampamento vertical",
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for stem, title in NAMES.items():
        if not (BEFORE / f"{stem}.png").exists():
            continue
        old = Image.open(BEFORE / f"{stem}.png").convert("RGB")
        new = Image.open(AFTER / f"{stem}.png").convert("RGB")
        assert old.size == new.size, f"Framing changed: {stem}"
        w, h = old.size
        comparison = Image.new("RGB", (w * 2, h + 32), (42, 49, 38))
        comparison.paste(old, (0, 32))
        comparison.paste(new, (w, 32))
        draw = ImageDraw.Draw(comparison)
        draw.text((10, 9), f"{title} | ANTES", fill=(255, 238, 192))
        draw.text((w + 10, 9), f"{title} | DEPOIS", fill=(255, 238, 192))
        comparison.save(OUT / f"{stem}-antes-depois.png")
    print(f"Comparacoes de capturas reais: {OUT}")


if __name__ == "__main__":
    main()
