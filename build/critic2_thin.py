"""Does the thin edge read as light passing through?

Transmission has a spectral signature that a coloured surface cannot fake: as a
path through the gel gets shorter, LESS of the complement is absorbed, so the
non-dominant channels climb and saturation FALLS while luminance RISES. A merely
brighter orange keeps its saturation.

Measured in a scale-normalised shell band (0 - 5% of subject height in from the
silhouette) versus a deep band (>= 18% in), so the reference's larger framing is
not what is being compared.

Usage: python critic2_thin.py <img> [img ...]
       python critic2_thin.py --crop <out.png> <img> <x0> <y0> <x1> <y1> <scale>
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image

BG = 30
INK = 60


def erode(mask, n):
    for _ in range(n):
        m = mask.copy()
        m[1:, :] &= mask[:-1, :]
        m[:-1, :] &= mask[1:, :]
        m[:, 1:] &= mask[:, :-1]
        m[:, :-1] &= mask[:, 1:]
        mask = m
    return mask


def report(path):
    rgb = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32) / 255.0
    subject = rgb.max(axis=2) > BG / 255.0
    gel = subject & (rgb.max(axis=2) > INK / 255.0)
    rows = np.nonzero(subject.any(axis=1))[0]
    size = rows.max() - rows.min() + 1
    d_shell = max(1, int(round(0.05 * size)))
    d_deep = max(2, int(round(0.18 * size)))
    shell = subject & ~erode(subject, d_shell) & gel
    deep = erode(subject, d_deep) & gel
    L = 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    S = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
    B = rgb[..., 2]
    G = rgb[..., 1]

    def band(m, label):
        return {
            "label": label,
            "n": int(m.sum()),
            "L50": float(np.percentile(L[m], 50)),
            "L90": float(np.percentile(L[m], 90)),
            "S50": float(np.percentile(S[m], 50)),
            "G50": float(np.percentile(G[m], 50)),
            "G90": float(np.percentile(G[m], 90)),
            "B50": float(np.percentile(B[m], 50)),
            "B90": float(np.percentile(B[m], 90)),
            "hot%": float((L[m] > 0.75).mean() * 100.0),
        }

    s = band(shell, "shell<5%")
    d = band(deep, "deep>18%")
    print(f"\n{Path(path).name}   subject={size}px  shell_d={d_shell}px deep_d={d_deep}px")
    print(f"  {'band':<11}{'n':>8}{'L50':>7}{'L90':>7}{'S50':>7}"
          f"{'G50':>7}{'G90':>7}{'B50':>7}{'B90':>7}{'hot%':>7}")
    for r in (s, d):
        print(f"  {r['label']:<11}{r['n']:>8}{r['L50']:>7.3f}{r['L90']:>7.3f}"
              f"{r['S50']:>7.3f}{r['G50']:>7.3f}{r['G90']:>7.3f}"
              f"{r['B50']:>7.3f}{r['B90']:>7.3f}{r['hot%']:>7.2f}")
    print(f"  --> L50 shell/deep = {s['L50']/max(d['L50'],1e-6):.3f}   "
          f"sat DROP at edge = {d['S50']-s['S50']:+.3f}   "
          f"B90 shell/deep = {s['B90']/max(d['B90'],1e-6):.2f}")


def crop(out, path, x0, y0, x1, y1, scale):
    img = Image.open(path).convert("RGB").crop((x0, y0, x1, y1))
    img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(f"CROP {out} {img.size}")


if __name__ == "__main__":
    a = sys.argv[1:]
    if a and a[0] == "--crop":
        crop(a[1], a[2], *[int(v) for v in a[3:8]])
    else:
        for p in a:
            report(p)
