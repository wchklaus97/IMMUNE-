import numpy as np
from PIL import Image

ROOT = r"C:\Users\wchkl\Documents\Codex\2026-08-12\https-chatgpt-com-share-6a7b9aee-e840-2"
OUT = ROOT + r"\build\shots\critic-gel"

def figure_box(path, thr=0.10):
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(np.float32)/255.0
    l = 0.2126*a[...,0]+0.7152*a[...,1]+0.0722*a[...,2]
    ys, xs = np.where(l > thr)
    return im, (xs.min(), ys.min(), xs.max()+1, ys.max()+1)

def norm(path, H=760):
    im, box = figure_box(path)
    c = im.crop(box)
    s = H/c.height
    return c.resize((max(1,int(c.width*s)), H), Image.LANCZOS)

panels = [
    ("ref",  ROOT + r"\godot\immune\characters\concepts\CHAR-BASE-T-3d-alt.png"),
    ("tripo",ROOT + r"\build\shots\t-gel\t-gel-tripo-front.png"),
    ("fix",  OUT  + r"\critgel-front.png"),
    ("old",  ROOT + r"\build\shots\t-godot\t-godot-34.png"),
]
imgs = [norm(p) for _, p in panels]
W = sum(i.width for i in imgs) + 16*(len(imgs)-1)
sheet = Image.new("RGB", (W, 760), (0,0,0))
x = 0
for i in imgs:
    sheet.paste(i, (x, 0)); x += i.width + 16
sheet.save(OUT + r"\zoom\SBS-matched.png")
print("SBS", sheet.size)

# --- limb-tip vs core hue/value probe on the tripo render -----------------
def probe(path, pts, label):
    a = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)/255.0
    print("::", label)
    for name,(x,y) in pts.items():
        p = a[y-3:y+4, x-3:x+4].reshape(-1,3).mean(axis=0)
        mx, mn = p.max(), p.min()
        # "yellowness" of a warm gel: G/R ratio. Higher = hotter/yellower thin part.
        print(f"   {name:<14} rgb=({p[0]:.3f},{p[1]:.3f},{p[2]:.3f})  G/R={p[1]/max(p[0],1e-4):.3f}  luma={0.2126*p[0]+0.7152*p[1]+0.0722*p[2]:.3f}")

# reference: sample thick dome core, arm tip, skirt bottom edge
probe(ROOT + r"\godot\immune\characters\concepts\CHAR-BASE-T-3d-alt.png",
      {"dome core":(410,170), "cheek thick":(300,470), "L arm tip":(120,565),
       "R arm tip":(700,560), "skirt bottom":(180,700), "skirt bottom2":(600,690)}, "REFERENCE")

probe(ROOT + r"\build\shots\t-gel\t-gel-tripo-front.png",
      {"dome core":(470,175), "cheek thick":(430,330), "L arm tip":(360,385),
       "R arm tip":(660,380), "skirt bottom":(410,455), "skirt bottom2":(575,450)}, "GEL tripo-front")
