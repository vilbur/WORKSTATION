from PIL import Image, ImageDraw
from io import BytesIO
from pathlib import Path
import struct

SIZES = (16, 24, 32, 48, 64, 128, 256)

def draw_icon(size):
    scale = 4 if size >= 24 else 1
    n = size * scale
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    def box(x0,y0,x1,y1,r,fill,outline=None,width=1):
        d.rounded_rectangle((x0*scale,y0*scale,x1*scale,y1*scale), radius=r*scale, fill=fill, outline=outline, width=width*scale)
    if size == 16:
        box(0,0,15,15,3,'#20252C', '#8BA6BC')
        for y,color,width in [(3,'#F5A34A',7),(7,'#F28B30',6),(11,'#D96A20',7)]:
            d.rectangle((3,y,4,y+1),fill=color)
            d.rectangle((6,y,6+width-1,y+1),fill='#EAF3F8')
    else:
        u=size/16
        def B(coords,r,fill,outline=None,w=1):
            d.rounded_rectangle(tuple(round(q*u*scale) for q in coords), radius=round(r*u*scale), fill=fill,outline=outline,width=max(1,round(w*u*scale)))
        B((0.5,0.5,15.5,15.5),3,'#20252C','#7894A9',0.55)
        B((2.1,2.1,13.9,13.9),1.35,'#303A44')
        for y,color,length in [(3.5,'#F5A34A',6.0),(7.1,'#F28B30',5.0),(10.7,'#D96A20',6.0)]:
            B((3.35,y,4.55,y+1.6),0.35,color)
            B((5.5,y+0.25,5.5+length,y+1.35),0.25,'#ECF4FA')
    return im.resize((size,size),Image.Resampling.LANCZOS) if scale > 1 else im

images=[draw_icon(s) for s in SIZES]
blobs=[]
for im in images:
    buf=BytesIO(); im.save(buf,format='PNG'); blobs.append(buf.getvalue())
header=struct.pack('<HHH',0,1,len(images))
offset=6+16*len(images)
entries=[]
for size,blob in zip(SIZES,blobs):
    entries.append(struct.pack('<BBBBHHII',size%256,size%256,0,0,1,32,len(blob),offset))
    offset+=len(blob)
Path('Window-List-Manager.ico').write_bytes(header+b''.join(entries)+b''.join(blobs))
preview=Image.new('RGBA',(512,320),'#111820')
for i,s in enumerate(SIZES):
    image=images[i]
    if i<4:
        image=image.resize((s*4,s*4),Image.Resampling.NEAREST)
    x=(i%4)*124+16; y=(i//4)*150+8
    if x+image.width<=512 and y+image.height<=320:
        preview.alpha_composite(image,(x,y))
preview.save('Window-List-Manager-Icon-Preview.png')
