"""Deterministically extract the approved v0.3.7 poses, without redrawing.

Build-only dependencies: Pillow, numpy, opencv-python-headless.
No runtime dependency. Source study is excluded from Godot by .gdignore.
Rows down/up/left/right; columns held idle A/B, then four approved walk poses.
"""
from pathlib import Path
import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'tools/source/explorer_approved_v037.png'
DEST = ROOT / 'assets/art/explorer_atlas.png'
WALK = ROOT / 'docs/art/EXPLORER_SHEET_V037.png'
XS = [(164,337),(351,531),(548,722),(738,919)]
YS = [(9,242),(250,488),(495,725),(725,953)]
SIZE = 48
SCALE = 0.19  # One scale for all 16 poses; no stretching limbs independently.


def extract(source, box):
    rgb = np.array(source.crop(box))
    h, w = rgb.shape[:2]
    mask = np.full((h,w), cv2.GC_PR_FGD, np.uint8)
    # Black outline seeds preserve boots that resemble the brown backdrop.
    mask[rgb.max(axis=2) < 38] = cv2.GC_FGD
    mask[:3] = mask[-3:] = cv2.GC_BGD
    mask[:,:3] = mask[:,-3:] = cv2.GC_BGD
    cv2.grabCut(rgb, mask, None, np.zeros((1,65)), np.zeros((1,65)),
                8, cv2.GC_INIT_WITH_MASK)
    alpha = np.uint8((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD))*255
    _, labels, stats, _ = cv2.connectedComponentsWithStats(alpha)
    alpha = labels == 1+np.argmax(stats[1:,cv2.CC_STAT_AREA])
    rgba = Image.fromarray(np.dstack([rgb, alpha.astype(np.uint8)*255]))
    bounds = rgba.getbbox()
    cropped = rgba.crop(bounds)
    # Head centre is a stable anchor; backpack/arms must not shift the torso.
    hair = rgba.crop((0,0,w,95)).getbbox()
    anchor = (hair[0]+hair[2])/2 - bounds[0]
    resized = cropped.resize((round(cropped.width*SCALE),round(cropped.height*SCALE)),
                             Image.Resampling.NEAREST)
    frame = Image.new('RGBA',(SIZE,SIZE))
    frame.alpha_composite(resized,(24-round(anchor*SCALE),46-resized.height))
    assert frame.getbbox()[3] == 46
    return frame


def main():
    cv2.setRNGSeed(0)
    source = Image.open(SOURCE).convert('RGB')
    assert source.size == (1536,1024)
    atlas = Image.new('RGBA',(SIZE*6,SIZE*4))
    walk = Image.new('RGBA',(SIZE*4,SIZE*4))
    for row,(y0,y1) in enumerate(YS):
        frames = [extract(source,(x0,y0,x1,y1)) for x0,x1 in XS]
        for column,frame in enumerate([frames[1],frames[1]]+frames):
            atlas.alpha_composite(frame,(column*SIZE,row*SIZE))
        for column,frame in enumerate(frames):
            walk.alpha_composite(frame,(column*SIZE,row*SIZE))
    atlas.save(DEST,optimize=True)
    walk.save(WALK,optimize=True)
    print('Approved walk:',walk.size, WALK.stat().st_size,'bytes; runtime atlas:',DEST.stat().st_size)

if __name__ == '__main__':
    main()
