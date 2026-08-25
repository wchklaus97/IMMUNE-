"""Independent critic measurement for the wet-gel material.

Written from scratch so the verdict does not rest on build/gel_compare.py.

Stats reported, all on subject pixels only:
  clip%       fraction of eroded-core pixels with a channel >= 254/255
  lum p50/p90 luminance percentiles, subject pixels excluding ink
  sat         mean HSV saturation
  edge/core   ratio of median luminance in a thin silhouette shell to the
              median luminance of the deep interior. This is the thick-to-thin
              read: gel should be BRIGHTER at the thin edge than in the middle.
  halo        mean luminance of background pixels within 12px of the silhouette,
              i.e. how much light the body throws into the stage.

Usage:
  python critic2_measure.py stats <img> [img ...]
  python critic2_measure.py scan <img> <y> [x0 x1]
  python critic2_measure.py shell <img> [img ...]
  python critic2_measure.py profile <img> <y>      # normalised limb cross-section
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

BG = 30          # 0-255, above the near-black stage
INK = 60         # below this max-channel = dark eye/mouth ink, not gel body
CLIP = 254


def load(path):
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)


def erode(mask, n):
    for _ in range(n):
        m = mask.copy()
        m[1:, :] &= mask[:-1, :]
        m[:-1, :] &= mask[1:, :]
        m[:, 1:] &= mask[:, :-1]
        m[:, :-1] &= mask[:, 1:]
        mask = m
    return mask


def dilate(mask, n):
    for _ in range(n):
        m = mask.copy()
        m[1:, :] |= mask[:-1, :]
        m[:-1, :] |= mask[1:, :]
        m[:, 1:] |= mask[:, :-1]
        m[:, :-1] |= mask[:, 1:]
        mask = m
    return mask


def lum(rgb):
    return (0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]) / 255.0


def sat(rgb):
    mx = rgb.max(axis=-1)
    mn = rgb.min(axis=-1)
    return np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0.0)


def masks(rgb, core_erode=6):
    subject = rgb.max(axis=2) > BG
    gel = subject & (rgb.max(axis=2) > INK)
    core = erode(subject, core_erode) & gel
    return subject, gel, core


def stats(path, core_erode=6):
    rgb = load(path)
    subject, gel, core = masks(rgb, core_erode)
    L = lum(rgb)
    S = sat(rgb)
    px = rgb[core]
    clipped = px >= CLIP
    dom = int(np.argmax(px.mean(axis=0)))
    # silhouette shell: 2..6 px inside the subject edge (thin parts)
    shell = erode(subject, 2) & ~erode(subject, 7) & gel
    deep = erode(subject, 22) & gel
    bg_ring = dilate(subject, 12) & ~subject
    return {
        "name": Path(path).name,
        "core_px": int(core.sum()),
        "dom": "RGB"[dom],
        "clip_dom": clipped[:, dom].mean() * 100,
        "clip_r": clipped[:, 0].mean() * 100,
        "clip_g": clipped[:, 1].mean() * 100,
        "clip_any": clipped.any(axis=1).mean() * 100,
        "lum50": np.percentile(L[gel], 50),
        "lum90": np.percentile(L[gel], 90),
        "lum99": np.percentile(L[gel], 99),
        "sat": S[gel].mean(),
        "shell_l50": np.percentile(L[shell], 50) if shell.any() else float("nan"),
        "deep_l50": np.percentile(L[deep], 50) if deep.any() else float("nan"),
        "shell_l90": np.percentile(L[shell], 90) if shell.any() else float("nan"),
        "halo": L[bg_ring].mean() if bg_ring.any() else float("nan"),
    }


def print_stats(paths):
    hdr = (f"{'image':<24}{'core':>7}{'dom':>4}{'clipDom%':>9}{'clipAny%':>9}"
           f"{'sat':>6}{'lum50':>7}{'lum90':>7}{'lum99':>7}"
           f"{'shell50':>8}{'deep50':>8}{'e/c':>6}{'halo':>7}")
    print(hdr)
    print("-" * len(hdr))
    for p in paths:
        s = stats(p)
        ec = s["shell_l50"] / max(s["deep_l50"], 1e-6)
        print(f"{s['name']:<24}{s['core_px']:>7}{s['dom']:>4}{s['clip_dom']:>9.2f}"
              f"{s['clip_any']:>9.2f}{s['sat']:>6.3f}{s['lum50']:>7.3f}"
              f"{s['lum90']:>7.3f}{s['lum99']:>7.3f}{s['shell_l50']:>8.3f}"
              f"{s['deep_l50']:>8.3f}{ec:>6.2f}{s['halo']:>7.4f}")


def scan(path, y, x0=None, x1=None):
    rgb = load(path)
    row = rgb[y]
    lit = np.nonzero(row.max(axis=1) > BG)[0]
    if lit.size == 0:
        print(f"{path}: row {y} empty")
        return
    a = int(lit.min()) if x0 is None else x0
    b = int(lit.max()) if x1 is None else x1
    seg = row[a:b + 1] / 255.0
    pin = int((seg[:, 0] >= CLIP / 255.0).sum())
    print(f"SCAN {Path(path).name} y={y} x={a}..{b} n={seg.shape[0]} R_pinned={pin}")
    print(f"  R {seg[:,0].min():.3f}->{seg[:,0].max():.3f}  "
          f"G {seg[:,1].min():.3f}->{seg[:,1].max():.3f}  "
          f"B {seg[:,2].min():.3f}->{seg[:,2].max():.3f}")
    step = max(1, seg.shape[0] // 26)
    for i in range(0, seg.shape[0], step):
        r, g, bl = seg[i]
        flag = "  <-- R PINNED" if r >= CLIP / 255.0 else ""
        print(f"  x={a+i:>4} R={r:.3f} G={g:.3f} B={bl:.3f} L={0.2126*r+0.7152*g+0.0722*bl:.3f}{flag}")


def shell_profile(paths):
    """Median luminance / sat as a function of depth inside the silhouette.
    Depth in px from the edge; normalised so the two framings are comparable
    by reporting the ratio to the deepest band."""
    for p in paths:
        rgb = load(p)
        subject = rgb.max(axis=2) > BG
        gel = subject & (rgb.max(axis=2) > INK)
        L = lum(rgb)
        S = sat(rgb)
        # scale depth bands by subject size so a big and small framing compare
        h = np.nonzero(subject.any(axis=1))[0]
        size = h.max() - h.min() + 1
        print(f"\n{Path(p).name}  subject height={size}px")
        print(f"  {'depth%':>8}{'px':>7}{'n':>8}{'lumP50':>9}{'lumP90':>9}{'sat':>7}")
        prev = subject.copy()
        for frac in (0.005, 0.012, 0.025, 0.05, 0.09, 0.15, 0.25):
            d = max(1, int(round(frac * size)))
            inner = erode(subject, d)
            band = prev & ~inner & gel if frac > 0.005 else (subject & ~inner & gel)
            band = (erode(subject, max(1, d - max(1, int(round(0.005*size))))) if False else band)
            if band.any():
                print(f"  {frac*100:>7.1f}%{d:>7}{int(band.sum()):>8}"
                      f"{np.percentile(L[band],50):>9.3f}{np.percentile(L[band],90):>9.3f}"
                      f"{S[band].mean():>7.3f}")
            prev = inner


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    cmd = argv[0]
    if cmd == "stats":
        print_stats(argv[1:])
    elif cmd == "scan":
        scan(argv[1], int(argv[2]),
             int(argv[3]) if len(argv) > 3 else None,
             int(argv[4]) if len(argv) > 4 else None)
    elif cmd == "shell":
        shell_profile(argv[1:])
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
