import numpy as np
from PIL import Image
ROOT = r"C:\Users\wchkl\Documents\Codex\2026-08-12\https-chatgpt-com-share-6a7b9aee-e840-2"
OUT  = ROOT + r"\build\shots\critic-gel\zoom"

def crop(path, box, out, scale=3):
    im = Image.open(path).convert("RGB").crop(box)
    im = im.resize((im.width*scale, im.height*scale), Image.LANCZOS)
    im.save(out); print(out, im.size)

# reference: right arm + skirt foot
crop(ROOT+r"\godot\immune\characters\concepts\CHAR-BASE-T-3d-alt.png", (620,430,819,780), OUT+r"\limb-ref.png", 2)
# render: right arm + foot (tripo)
crop(ROOT+r"\build\shots\t-gel\t-gel-tripo-front.png", (600,300,760,500), OUT+r"\limb-tripo.png", 4)

# scanline across a limb, tip -> body, normalised, to show the gradient
def scan(path, y, x0, x1, label):
    a = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)/255.0
    row = a[y, x0:x1]
    n = 12
    idx = np.linspace(0, row.shape[0]-1, n).astype(int)
    print(f"\n{label}  scanline y={y}, x {x0}->{x1} (outer edge -> inward)")
    print("   pos      R     G     B    G/R")
    for i in idx:
        p = row[i]
        print(f"   {i:>4d}  {p[0]:.3f} {p[1]:.3f} {p[2]:.3f}  {p[1]/max(p[0],1e-4):.3f}")

scan(ROOT+r"\godot\immune\characters\concepts\CHAR-BASE-T-3d-alt.png", 690, 660, 800, "REFERENCE skirt foot")
scan(ROOT+r"\build\shots\t-gel\t-gel-tripo-front.png", 440, 620, 700, "GEL tripo skirt foot")
