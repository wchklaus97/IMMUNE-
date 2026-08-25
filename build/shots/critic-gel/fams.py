import numpy as np, colorsys
from PIL import Image, ImageFilter
ROOT = r"C:\Users\wchkl\Documents\Codex\2026-08-12\https-chatgpt-com-share-6a7b9aee-e840-2"
G = ROOT + r"\build\shots\t-gel"

JELLY = {"T":(1.0,0.48,0.16),"B":(0.62,0.22,0.86),"M":(0.78,0.58,0.98),
         "N":(0.52,0.86,0.18),"A":(0.98,0.62,0.22),"D":(1.0,0.50,0.22)}

print(f"{'fam':<4}{'palette hue':>12}{'render hue':>12}{'dHue(deg)':>11}{'sat':>7}{'clip%':>8}{'coreclip%':>11}")
for f,(r,g,b) in JELLY.items():
    ph = colorsys.rgb_to_hsv(r,g,b)[0]
    p = f"{G}\\fam-{f}-front.png" if f!="T" else f"{G}\\t-gel-front.png"
    a = np.asarray(Image.open(p).convert("RGB")).astype(np.float32)/255.0
    l = 0.2126*a[...,0]+0.7152*a[...,1]+0.0722*a[...,2]
    fig = l>0.10
    mx = a.max(axis=2); mn = a.min(axis=2)
    # hue only on pixels that are not channel-clipped and not near-white specular
    good = fig & (mx<0.99) & (mx>0.15) & ((mx-mn)/np.maximum(mx,1e-4) > 0.25)
    px = a[good]
    hs = np.array([colorsys.rgb_to_hsv(*q)[0] for q in px[::max(1,len(px)//4000)]])
    # circular median
    ang = hs*2*np.pi
    rh = np.arctan2(np.sin(ang).mean(), np.cos(ang).mean())/(2*np.pi) % 1.0
    d = (rh-ph+0.5)%1.0-0.5
    sat = ((mx-mn)/np.maximum(mx,1e-4))[fig].mean()
    m = np.asarray(Image.fromarray((fig*255).astype(np.uint8)).filter(ImageFilter.MinFilter(9)))>127
    clip_any = (mx>=0.995)
    print(f"{f:<4}{ph*360:>11.1f}째{rh*360:>11.1f}째{d*360:>10.1f}째{sat:>7.3f}{100*clip_any[fig].mean():>7.1f}%{100*clip_any[m].mean():>10.1f}%")
