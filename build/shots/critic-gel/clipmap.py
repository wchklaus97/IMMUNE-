import numpy as np
from PIL import Image
ROOT = r"C:\Users\wchkl\Documents\Codex\2026-08-12\https-chatgpt-com-share-6a7b9aee-e840-2"
OUT  = ROOT + r"\build\shots\critic-gel\zoom"

def clipmap(path, out, label):
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(np.float32)/255.0
    l = 0.2126*a[...,0]+0.7152*a[...,1]+0.0722*a[...,2]
    fig = l > 0.10
    clipR = (a[...,0] >= 0.995) & fig
    vis = (a*255).astype(np.uint8).copy()
    # paint clipped-red pixels cyan
    vis[clipR] = [0,255,255]
    Image.fromarray(vis).save(out)
    # how much of the *solid body* (not the halo) clips: erode figure a lot
    from PIL import ImageFilter
    m = Image.fromarray((fig*255).astype(np.uint8)).filter(ImageFilter.MinFilter(9))
    core = np.asarray(m) > 127
    print(f"{label}: R-clip over figure {100*clipR[fig].mean():5.1f}% | over eroded core {100*((a[...,0]>=0.995)&core)[core].mean():5.1f}%")

clipmap(ROOT+r"\godot\immune\characters\concepts\CHAR-BASE-T-3d-alt.png", OUT+r"\clip-ref.png", "REFERENCE   ")
clipmap(ROOT+r"\build\shots\t-gel\t-gel-tripo-front.png", OUT+r"\clip-tripo.png", "GEL tripo   ")
clipmap(ROOT+r"\build\shots\critic-gel\critgel-front.png", OUT+r"\clip-fix.png", "GEL fix     ")

# --- area hue: median G/R on unclipped body pixels ------------------------
def hue_report(path,label):
    a = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)/255.0
    l = 0.2126*a[...,0]+0.7152*a[...,1]+0.0722*a[...,2]
    fig = l>0.10
    unclipped = fig & (a[...,0]<0.99) & (a[...,0]>0.15)
    gr = a[...,1][unclipped]/np.maximum(a[...,0][unclipped],1e-4)
    print(f"{label}: unclipped body px {unclipped.sum():>7d}  G/R p25={np.percentile(gr,25):.3f} med={np.median(gr):.3f} p75={np.percentile(gr,75):.3f}")

print()
hue_report(ROOT+r"\godot\immune\characters\concepts\CHAR-BASE-T-3d-alt.png","REFERENCE   ")
hue_report(ROOT+r"\build\shots\t-gel\t-gel-tripo-front.png","GEL tripo   ")
hue_report(ROOT+r"\build\shots\critic-gel\critgel-front.png","GEL fix     ")
print("\npalette JELLY T = (1.0,0.48,0.16) -> G/R = 0.480")
