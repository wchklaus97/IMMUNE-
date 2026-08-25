"""Superimpose the rendered outlines so the shape difference is visible.

Aggregate numbers keep agreeing while the shapes plainly do not, so this draws
the concept's outline and the mesh's outline on top of each other, normalised on
height and aligned on the bounding box.
"""

import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SIZE = 700


def mask(path, kind):
    a = np.asarray(Image.open(path).convert("RGB"), dtype=float)
    if kind == "green":
        m = ~((a[:, :, 1] > a[:, :, 0] + 20) & (a[:, :, 1] > a[:, :, 2] + 20))
    else:
        m = a.mean(axis=2) > 28
    ys, xs = np.nonzero(m)
    return m[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def fit(m):
    """Scale on height, centre horizontally, sit on the bottom edge."""
    h, w = m.shape
    s = SIZE * 0.94 / h
    im = Image.fromarray((m * 255).astype(np.uint8)).resize(
        (max(int(w * s), 1), max(int(h * s), 1)), Image.LANCZOS)
    out = Image.new("L", (SIZE, SIZE), 0)
    out.paste(im, ((SIZE - im.size[0]) // 2, SIZE - im.size[1] - int(SIZE * 0.03)))
    return np.asarray(out) > 110


def edge(m):
    e = np.zeros_like(m)
    e[1:-1, 1:-1] = m[1:-1, 1:-1] & ~(m[:-2, 1:-1] & m[2:, 1:-1]
                                      & m[1:-1, :-2] & m[1:-1, 2:])
    for _ in range(1):
        e |= np.roll(e, 1, 0) | np.roll(e, 1, 1)
    return e


def main(mesh_png, out_png):
    ref = fit(mask(os.path.join(ROOT, "godot", "immune", "characters", "concepts",
                                "CHAR-BASE-T-3d-alt.png"), "lum"))
    grn = fit(mask(os.path.join(ROOT, "ui", "immune-research-network", "assets",
                                "characters", "alt", "CHAR-BASE-T-alt.png"), "green"))
    mesh = fit(mask(mesh_png, "lum"))

    rgb = np.zeros((SIZE, SIZE, 3), dtype=np.uint8)
    rgb[..., 0] = np.where(ref, 90, 0)
    rgb[..., 1] = np.where(mesh, 70, 0)
    rgb[..., 2] = np.where(mesh, 70, 0)
    er, eg, em = edge(ref), edge(grn), edge(mesh)
    rgb[er] = [255, 90, 40]
    rgb[eg] = [255, 210, 60]
    rgb[em] = [80, 230, 255]
    Image.fromarray(rgb).save(out_png)

    for name, m in (("concept", ref), ("green", grn), ("mesh", mesh)):
        cols = m.sum(axis=0)
        rows = m.sum(axis=1)
        print("%-8s area %6d  widest row y=%3d  bottom rows lit %d"
              % (name, m.sum(), int(np.argmax(rows)), int((rows > 0).sum())))
    inter = (ref & mesh).sum()
    union = (ref | mesh).sum()
    print("concept vs mesh IoU %.3f   (mesh-only %d, concept-only %d)"
          % (inter / union, (mesh & ~ref).sum(), (ref & ~mesh).sum()))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1
         else os.path.join(HERE, "shots", "t-fix", "t-fix-front.png"),
         sys.argv[2] if len(sys.argv) > 2
         else os.path.join(HERE, "ref-crops", "outline-overlay.png"))
