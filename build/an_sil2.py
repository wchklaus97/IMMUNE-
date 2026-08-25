"""Width-per-height profile of rendered silhouettes, normalised on height.

The mesh bounding box and the rendered outline disagree for this character —
the limbs splay in Z as well as X — so proportion decisions are made off the
render, which is what the reviewer compares against the concept.
"""

import numpy as np
from PIL import Image

STEPS = 21


def profile(path):
    a = np.asarray(Image.open(path).convert('L'), dtype=float)
    m = a > 28
    ys, xs = np.nonzero(m)
    m = m[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    h, w = m.shape
    out = []
    for f in np.linspace(0, 1, STEPS):
        row = m[min(int(f * (h - 1)), h - 1)]
        out.append(row.sum() / h)
    return np.array(out), w / h


def main():
    srcs = [
        ('ref', r'..\godot\immune\characters\concepts\CHAR-BASE-T-3d-alt.png'),
        ('raw', r'shots\t-raw\t-raw-front.png'),
        ('fix', r'shots\t-fix\t-fix-front.png'),
    ]
    res = {}
    for name, path in srcs:
        res[name] = profile(path)
        print(name, 'w/h', round(res[name][1], 3))
    print('frac    ref    raw    fix')
    for i, f in enumerate(np.linspace(0, 1, STEPS)):
        print('%4.2f  %.3f  %.3f  %.3f' % (
            f, res['ref'][0][i], res['raw'][0][i], res['fix'][0][i]))


if __name__ == '__main__':
    main()
