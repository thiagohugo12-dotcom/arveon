"""Normalize the approved-image edits into strict transparent Godot sprite grids.

Sources are image-generation edits stored outside the game project in
outputs/ARVEON/Registros/andar2-monstros-fonte. This script only packs and
scales frames; it does not invent or redraw character features.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT.parent / "Registros" / "andar2-monstros-fonte"
DEST = ROOT / "assets" / "art" / "andar2" / "monsters"
DEST.mkdir(parents=True, exist_ok=True)

FRAME_W, FRAME_H = 72, 64
SRC_W = 256
ROW_Y = [(0, 220), (220, 425), (425, 640), (640, 820), (820, 1024)]
CENTERS = {
    "goblin_garimpeiro": [
        [375, 637, 887, 1147],
        [140, 390, 640, 892, 1142, 1394],
        [147, 399, 655, 910, 1137, 1384],
        [497, 760, 1037],
        [148, 409, 667, 880, 1131, 1388],
    ],
    "tatu_rochoso": [
        [335, 607, 894, 1174],
        [144, 387, 638, 887, 1130, 1380],
        [130, 386, 638, 894, 1146, 1392],
        [450, 760, 1072],
        [128, 371, 624, 885, 1136, 1392],
    ],
    "escorpiao_da_chapada": [
        [274, 538, 790, 1031],
        [137, 379, 627, 875, 1122, 1385],
        [138, 387, 640, 894, 1157, 1407],
        [334, 594, 825],
        [138, 398, 657, 893, 1139, 1391],
    ],
}
X_LIMITS = {
    ("goblin_garimpeiro", 2): [(46, 250), (284, 516), (539, 773), (786, 1036), (1043, 1232), (1285, 1484)],
    ("goblin_garimpeiro", 4): [(52, 244), (305, 514), (563, 771), (788, 971), (1031, 1231), (1285, 1492)],
    ("tatu_rochoso", 2): [(23, 239), (260, 511), (527, 749), (782, 994), (1040, 1241), (1290, 1491)],
    ("tatu_rochoso", 4): [(14, 243), (254, 489), (504, 744), (763, 1006), (1013, 1259), (1275, 1508)],
    ("escorpiao_da_chapada", 2): [(27, 249), (273, 501), (524, 755), (768, 1019), (1032, 1281), (1302, 1512)],
    ("escorpiao_da_chapada", 3): [(229, 442), (489, 701), (725, 924)],
    ("escorpiao_da_chapada", 4): [(26, 250), (294, 501), (540, 773), (786, 999), (1012, 1266), (1273, 1509)],
}

for name, rows in CENTERS.items():
    source = Image.open(SOURCES / (name + ".png")).convert("RGBA")
    assert source.size == (1536, 1024), (name, source.size)
    sheet = Image.new("RGBA", (FRAME_W * 6, FRAME_H * 5), (0, 0, 0, 0))
    for row_index, (centers, (top, bottom)) in enumerate(zip(rows, ROW_Y)):
        for column, center in enumerate(centers):
            limits = X_LIMITS.get((name, row_index))
            if limits:
                left, right = limits[column]
                cell = Image.new("RGBA", (SRC_W, bottom-top), (0, 0, 0, 0))
                cell.alpha_composite(source.crop((left, top, right, bottom)), (left-(center-SRC_W//2), 0))
            else:
                cell = source.crop((center - SRC_W//2, top, center + SRC_W//2, bottom))
            alpha_bbox = cell.getchannel("A").point(lambda value: 255 if value > 80 else 0).getbbox()
            assert alpha_bbox is not None, (name, row_index, column, "empty")
            # Frame edges remain transparent and no subject may be cut by a cell.
            assert alpha_bbox[0] > 1 and alpha_bbox[2] < SRC_W-1, (name, row_index, column, alpha_bbox)
            scaled = cell.resize((SRC_W//4, round((bottom-top)/4)), Image.Resampling.NEAREST)
            frame = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
            frame.alpha_composite(scaled, ((FRAME_W-scaled.width)//2, FRAME_H-scaled.height-4))
            bbox = frame.getchannel("A").getbbox()
            # Technical baseline alignment, without changing the drawn design.
            aligned = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
            aligned.alpha_composite(frame, (0, 60-bbox[3]))
            final_bbox = aligned.getchannel("A").getbbox()
            assert final_bbox[0] > 0 and final_bbox[1] > 0 and final_bbox[2] < FRAME_W and final_bbox[3] == 60
            sheet.alpha_composite(aligned, (column*FRAME_W, row_index*FRAME_H))
    target = DEST / (name + ".png")
    sheet.save(target, optimize=True)
    print(f"{target.name}: {sheet.width}x{sheet.height}, 4/6/6/3/6 frames, RGBA")
