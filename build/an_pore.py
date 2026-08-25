"""Print the forehead as a relief map: height above the fitted skull, in 1/1000
model units. 0 means flush, negative means pressed in, positive means a boss."""

import sys

import numpy as np

import an_t
import bl_fix_t_ops as ops


def relief(P, tris, C, n, half=0.13, grid=25, samples=8):
    t1 = np.cross(n, [0, 0, 1.0])
    t1 /= np.linalg.norm(t1)
    t2 = np.cross(n, t1)
    A, B, Cc = P[tris[:, 0]], P[tris[:, 1]], P[tris[:, 2]]
    fn = np.cross(B - A, Cc - A)
    fn /= np.linalg.norm(fn, axis=1)[:, None]
    keep = (fn @ n) > 0.0
    bs = [(i / samples, j / samples, 1 - i / samples - j / samples)
          for i in range(samples + 1) for j in range(samples + 1 - i)]
    pts = np.concatenate([A[keep] * b[0] + B[keep] * b[1] + Cc[keep] * b[2] for b in bs])
    rel = pts - C
    h = rel @ n
    u = rel @ t1
    v = rel @ t2
    m = (np.abs(u) < half) & (np.abs(v) < half) & (h > -0.12)
    u, v, h = u[m], v[m], h[m]

    r = np.hypot(u, v)
    ring = (r > 0.078) & (r < 0.125)
    M = np.stack([np.ones(ring.sum()), u[ring], v[ring],
                  u[ring] ** 2, u[ring] * v[ring], v[ring] ** 2], axis=1)
    ok = ring.copy()
    for _ in range(4):
        M = np.stack([np.ones(int(ok.sum())), u[ok], v[ok],
                      u[ok] ** 2, u[ok] * v[ok], v[ok] ** 2], axis=1)
        coef, *_ = np.linalg.lstsq(M, h[ok], rcond=None)
        res = h - (coef[0] + coef[1] * u + coef[2] * v
                   + coef[3] * u ** 2 + coef[4] * u * v + coef[5] * v ** 2)
        nxt = ring & (res > -0.010) & (res < 0.012)
        if nxt.sum() < 12:
            break
        ok = nxt

    out = np.full((grid, grid), np.nan)
    iu = np.clip(((u + half) / (2 * half) * (grid - 1)).astype(int), 0, grid - 1)
    iv = np.clip(((half - v) / (2 * half) * (grid - 1)).astype(int), 0, grid - 1)
    for a, b, c in zip(iv, iu, res):
        if np.isnan(out[a, b]) or c > out[a, b]:
            out[a, b] = c
    return out


def show(name, out):
    print("=== %s   (+ = proud of the skull, - = pressed in, units 1/1000)" % name)
    for row in out:
        print(" ".join("   ." if np.isnan(x) else "%+4.0f" % (x * 1000) for x in row))


if __name__ == "__main__":
    d = an_t.load()
    tris = d["tris"]
    C = np.array([-0.0038, -0.3100, 0.6763])
    n = np.array([0.0, -0.9160, 0.4011])
    which = sys.argv[1] if len(sys.argv) > 1 else "after"
    if which == "before":
        P = d["co"] * np.array([ops.PARAMS["scale_xy"], ops.PARAMS["scale_xy"],
                                ops.PARAMS["scale_z"]])
    else:
        P = np.load("dump/new_co.npy")
    show(which, relief(P, tris, C, n))
