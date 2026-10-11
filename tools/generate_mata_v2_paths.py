"""Offline pixel terrain asset; no Pillow dependency in the exported game."""
from pathlib import Path
from PIL import Image, ImageDraw
import ast,math,re
root=Path(__file__).resolve().parents[1]
source=(root/'scripts/presentation/floor_view.gd').read_text()
paths=ast.literal_eval(re.sub(r'Vector2\(([^)]*)\)',r'(\1)',source.split('const TRAILS := ')[1].split('\nconst TRAIL_WIDTHS')[0]))
widths=ast.literal_eval(source.split('const TRAIL_WIDTHS := ')[1].split('\n')[0])
im=Image.new('RGBA',(600,450));draw=ImageDraw.Draw(im)
def hash_value(x,y):
 n=x*74509+y*53197+19033
 return abs((n^(n>>11))*31337)%9973
for path,width in zip(paths,widths):
 for a,b in zip(path,path[1:]):
  count=math.ceil(math.dist(a,b)/6)
  for n in range(count+1):
   x=round((a[0]+(b[0]-a[0])*n/count)/2)*2
   y=round((a[1]+(b[1]-a[1])*n/count)/2)*2
   radius=width/2; wobble=(hash_value(round(x/8),round(y/8))%3-1)*2
   for stripe in range(-round(radius),round(radius)+1,4):
    half=max(1,math.sqrt(max(0,radius*radius-stripe*stripe))+wobble)
    draw.rectangle((round((x-half)/2),round((y+stripe)/2),round((x+half)/2),round((y+stripe+4)/2)),fill='#ecc56e')
   if n%7==0:draw.rectangle((x//2+1,y//2-2,x//2+2,y//2-2),fill='#f5d385')
im.save(root/'assets/art/mata_v2/paths.png')
