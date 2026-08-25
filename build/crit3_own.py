"""Independent critic-3 measurement. Written from scratch; shares no code with
build/gel_compare.py or build/critic2_*.py so the numbers are not inherited.

Bands are defined by inward city-block distance from the silhouette, expressed as
a fraction of subject bbox height, so a 760px-tall reference and a 380px-tall
render are comparable.

    python build/crit3_own.py bands  <img> [img...]
    python build/crit3_own.py bands  --match=<img> <img> [img...]   # rescale each
                                                                   # to match subject
                                                                   # height of --match
    python build/crit3_own.py clip   <img> [img...]
    python build/crit3_own.py profile <img>          # sat/lum vs depth curve
    python build/crit3_own.py eyes   <img>
    python build/crit3_own.py strip  <out> <img> [img...]
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

BG = 30.0        # background is (2,3,4)-ish; anything above this is subject
LIT = 60.0       # below this is baked ink (eyes/pore/mouth), not gel body
CLIP = 254.0
RIBBON = 0.012
SHELL = 0.05
CORE = 0.12


def load(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)


def subject_mask(rgb: np.ndarray) -> np.ndarray:
    return rgb.max(axis=2) > BG


def bbox_height(mask: np.ndarray) -> float:
    ys = np.flatnonzero(mask.any(axis=1))
    return float(ys[-1] - ys[0] + 1)


def inward_px(mask: np.ndarray, limit: int) -> np.ndarray:
    """City-block distance to the nearest background pixel, capped at `limit`.
    Verified against a synthetic disc in `selftest`."""
    d = np.zeros(mask.shape, dtype=np.int32)
    cur = mask.copy()
    for step in range(1, limit + 1):
        e = cur.copy()
        e[1:, :] &= cur[:-1, :]
        e[:-1, :] &= cur[1:, :]
        e[:, 1:] &= cur[:, :-1]
        e[:, :-1] &= cur[:, 1:]
        if not e.any():
            break
        d[e] = step
        cur = e
    return d


def rescale_to(rgb: np.ndarray, target_h: float) -> np.ndarray:
    """Resize whole image so the subject's bbox height equals target_h."""
    h = bbox_height(subject_mask(rgb))
    k = target_h / h
    img = Image.fromarray(rgb.astype(np.uint8))
    out = img.resize((max(int(round(img.width * k)), 1),
                      max(int(round(img.height * k)), 1)), Image.LANCZOS)
    return np.asarray(out, dtype=np.float32)


def stats(px: np.ndarray) -> dict:
    if px.shape[0] == 0:
        return {k: float("nan") for k in ("n", "lum50", "lum90", "sat", "b50", "b90", "hot")}
    v = px / 255.0
    r, g, b = v[:, 0], v[:, 1], v[:, 2]
    mx, mn = v.max(axis=1), v.min(axis=1)
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
    return {
        "n": float(px.shape[0]),
        "lum50": float(np.percentile(lum, 50)),
        "lum90": float(np.percentile(lum, 90)),
        "sat": float(sat.mean()),
        "b50": float(np.percentile(b, 50)),
        "b90": float(np.percentile(b, 90)),
        "hot": float((lum > 0.75).mean() * 100.0),
    }


def band_report(paths: list[Path], match: Path | None) -> None:
    target_h = bbox_height(subject_mask(load(match))) if match else None
    hdr = (f"{'image':<30}{'subjH':>7}{'band':>8}{'n':>8}{'lum50':>8}{'lum90':>8}"
           f"{'sat':>7}{'b50':>7}{'b90':>7}{'hot%':>7}")
    print(hdr)
    print("-" * len(hdr))
    for p in paths:
        rgb = load(p)
        if target_h is not None:
            rgb = rescale_to(rgb, target_h)
        mask = subject_mask(rgb)
        h = bbox_height(mask)
        d = inward_px(mask, int(h * (CORE + 0.03)) + 2)
        depth = d / h
        lit = rgb.max(axis=2) > LIT
        rows = {}
        for name, lo, hi in (("ribbon", 0.0, RIBBON), ("shell", 0.0, SHELL),
                             ("mid", SHELL, CORE), ("core", CORE, 9.0)):
            sel = (depth > lo) & (depth <= hi) & lit
            s = stats(rgb[sel])
            rows[name] = s
            print(f"{p.name if name=='ribbon' else '':<30}{h if name=='ribbon' else 0:>7.0f}"
                  f"{name:>8}{s['n']:>8.0f}{s['lum50']:>8.3f}{s['lum90']:>8.3f}"
                  f"{s['sat']:>7.3f}{s['b50']:>7.3f}{s['b90']:>7.3f}{s['hot']:>7.2f}")
        print(f"{'':<30}{'SAT DROP core->ribbon':>53}{rows['core']['sat']-rows['ribbon']['sat']:>+8.3f}")
        print(f"{'':<30}{'LUM RISE core->ribbon':>53}{rows['ribbon']['lum50']-rows['core']['lum50']:>+8.3f}")
        print(f"{'':<30}{'BLUE RISE core->ribbon':>53}{rows['ribbon']['b90']-rows['core']['b90']:>+8.3f}")
        tot = float(mask.sum())
        print(f"{'':<30}{'SHELL % of subject':>53}{rows['shell']['n']/max(tot,1)*100:>8.1f}")
        print()


def clip_report(paths: list[Path]) -> None:
    hdr = (f"{'image':<30}{'corePx':>8}{'R>=254%':>9}{'G>=254%':>9}{'B>=254%':>9}"
           f"{'any%':>7}{'R>=250%':>9}{'satMean':>9}{'lum50':>8}")
    print(hdr)
    print("-" * len(hdr))
    for p in paths:
        rgb = load(p)
        mask = subject_mask(rgb)
        m = mask.copy()
        for _ in range(6):
            e = m.copy()
            e[1:, :] &= m[:-1, :]
            e[:-1, :] &= m[1:, :]
            e[:, 1:] &= m[:, :-1]
            e[:, :-1] &= m[:, 1:]
            m = e
        px = rgb[m & (rgb.max(axis=2) > LIT)]
        v = px / 255.0
        mx, mn = v.max(axis=1), v.min(axis=1)
        sat = (mx - mn) / np.maximum(mx, 1e-6)
        lum = 0.2126 * v[:, 0] + 0.7152 * v[:, 1] + 0.0722 * v[:, 2]
        print(f"{p.name:<30}{px.shape[0]:>8}"
              f"{(px[:,0]>=CLIP).mean()*100:>9.2f}{(px[:,1]>=CLIP).mean()*100:>9.2f}"
              f"{(px[:,2]>=CLIP).mean()*100:>9.2f}{(px>=CLIP).any(axis=1).mean()*100:>7.2f}"
              f"{(px[:,0]>=250).mean()*100:>9.2f}{sat.mean():>9.3f}{np.percentile(lum,50):>8.3f}")


def profile(path: Path) -> None:
    """Sat / lum / blue as a function of normalised depth, in 12 shells."""
    rgb = load(path)
    mask = subject_mask(rgb)
    h = bbox_height(mask)
    d = inward_px(mask, int(h * 0.35) + 2)
    depth = d / h
    lit = rgb.max(axis=2) > LIT
    print(f"{path.name}  subjH={h:.0f}")
    print(f"{'depth%':>8}{'n':>8}{'lum50':>8}{'sat':>7}{'R50':>7}{'G50':>7}{'B50':>7}")
    edges = [0.0, 0.004, 0.008, 0.012, 0.018, 0.026, 0.035, 0.05, 0.07, 0.09, 0.12, 0.16, 0.30]
    for lo, hi in zip(edges[:-1], edges[1:]):
        sel = (depth > lo) & (depth <= hi) & lit
        if not sel.any():
            continue
        v = rgb[sel] / 255.0
        mx, mn = v.max(axis=1), v.min(axis=1)
        sat = ((mx - mn) / np.maximum(mx, 1e-6)).mean()
        lum = 0.2126 * v[:, 0] + 0.7152 * v[:, 1] + 0.0722 * v[:, 2]
        print(f"{hi*100:>8.1f}{sel.sum():>8}{np.percentile(lum,50):>8.3f}{sat:>7.3f}"
              f"{np.percentile(v[:,0],50):>7.3f}{np.percentile(v[:,1],50):>7.3f}"
              f"{np.percentile(v[:,2],50):>7.3f}")


def eyes(path: Path) -> None:
    """Darkest 2% of subject pixels: are the ink features still near-black and
    neutral, or have they picked up coloured bleed?"""
    rgb = load(path)
    mask = subject_mask(rgb)
    px = rgb[mask]
    lum = 0.2126 * px[:, 0] + 0.7152 * px[:, 1] + 0.0722 * px[:, 2]
    ink = px[lum <= np.percentile(lum, 2)]
    dark = px[px.max(axis=1) <= LIT]
    print(f"{path.name}: subject={px.shape[0]} inkPx(<=60max)={dark.shape[0]} "
          f"({dark.shape[0]/px.shape[0]*100:.2f}%)")
    for name, sel in (("darkest2%", ink), ("max<=60", dark)):
        if sel.shape[0] == 0:
            print(f"  {name}: none")
            continue
        v = sel / 255.0
        mx, mn = v.max(axis=1), v.min(axis=1)
        print(f"  {name:<10} n={sel.shape[0]:>7} meanRGB=({v[:,0].mean():.3f},"
              f"{v[:,1].mean():.3f},{v[:,2].mean():.3f}) "
              f"maxOfMax={mx.max():.3f} p95max={np.percentile(mx,95):.3f} "
              f"chroma={np.mean(mx-mn):.3f}")


def strip(out: Path, paths: list[Path], height: int = 640) -> None:
    tiles = []
    for p in paths:
        img = Image.open(p).convert("RGB")
        m = subject_mask(np.asarray(img, dtype=np.float32))
        ys, xs = np.nonzero(m)
        pad = 10
        crop = img.crop((max(int(xs.min()) - pad, 0), max(int(ys.min()) - pad, 0),
                         min(int(xs.max()) + pad, img.width),
                         min(int(ys.max()) + pad, img.height)))
        k = height / crop.height
        tiles.append(crop.resize((max(int(crop.width * k), 1), height), Image.LANCZOS))
    sheet = Image.new("RGB", (sum(t.width for t in tiles) + 6 * (len(tiles) - 1), height))
    x = 0
    for t in tiles:
        sheet.paste(t, (x, 0))
        x += t.width + 6
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"STRIP {out}  ({' | '.join(p.name for p in paths)})")


def selftest() -> None:
    """Confirm inward_px really measures distance from the silhouette."""
    n = 201
    yy, xx = np.mgrid[0:n, 0:n]
    disc = ((yy - 100) ** 2 + (xx - 100) ** 2) < 80 ** 2
    d = inward_px(disc, 90)
    print("selftest disc r=80: centre depth =", d[100, 100],
          "(city-block erosion of a disc peaks at r)  edge depth =", d[100, 21])
    rgb = np.zeros((n, n, 3), np.float32)
    rgb[disc] = 200
    print("bbox height =", bbox_height(subject_mask(rgb)), "(expect ~159-161)")


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__)
        return 2
    cmd, rest = argv[0], argv[1:]
    if cmd == "selftest":
        selftest()
    elif cmd == "bands":
        match = None
        if rest and rest[0].startswith("--match="):
            match = Path(rest[0].split("=", 1)[1])
            rest = rest[1:]
        band_report([Path(a) for a in rest], match)
    elif cmd == "clip":
        clip_report([Path(a) for a in rest])
    elif cmd == "profile":
        for a in rest:
            profile(Path(a))
            print()
    elif cmd == "eyes":
        for a in rest:
            eyes(Path(a))
    elif cmd == "strip":
        strip(Path(rest[0]), [Path(a) for a in rest[1:]])
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
