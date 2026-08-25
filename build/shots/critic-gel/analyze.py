import sys, numpy as np
from PIL import Image
import colorsys

def stats(path, label):
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(np.float32) / 255.0
    luma = 0.2126*a[...,0] + 0.7152*a[...,1] + 0.0722*a[...,2]
    fig = luma > 0.10                      # figure + visible halo
    if fig.sum() == 0:
        print(label, "empty"); return
    mx = a.max(axis=2); mn = a.min(axis=2)
    sat = np.where(mx > 1e-4, (mx-mn)/np.maximum(mx,1e-4), 0.0)
    L = luma[fig]; S = sat[fig]
    # highlight structure
    near_white_mask = (mn > 0.80)          # genuinely desaturated bright = specular
    clip = (mx >= 0.995)
    print(f"--- {label}  ({im.size[0]}x{im.size[1]})")
    print(f"  figure px            {fig.sum():>8d}  ({100.0*fig.sum()/luma.size:.1f}% of frame)")
    print(f"  luma mean/med        {L.mean():.3f} / {np.median(L):.3f}")
    print(f"  luma p05/p25/p75/p95 {np.percentile(L,5):.3f} / {np.percentile(L,25):.3f} / {np.percentile(L,75):.3f} / {np.percentile(L,95):.3f}")
    print(f"  sat mean (figure)    {S.mean():.3f}")
    print(f"  any-channel clipped  {100.0*clip[fig].mean():.2f}% of figure")
    print(f"  R clipped            {100.0*(a[...,0][fig]>=0.995).mean():.2f}%")
    print(f"  G clipped            {100.0*(a[...,1][fig]>=0.995).mean():.2f}%")
    print(f"  white specular px    {100.0*near_white_mask[fig].mean():.2f}% of figure")
    # dark fraction: how much of the body sits in the lower half of the range
    print(f"  luma<0.25 fraction   {100.0*(L<0.25).mean():.1f}%   luma>0.75 fraction {100.0*(L>0.75).mean():.1f}%")

for p,l in [(a.split('=',1)[1], a.split('=',1)[0]) for a in sys.argv[1:]]:
    stats(p,l)
