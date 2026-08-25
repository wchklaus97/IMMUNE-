"""Local (non-Blender) analysis helpers for the CHAR-BASE-T fix pass."""

import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DUMP = os.path.join(ROOT, "build", "dump")


def load():
    z = np.load(os.path.join(DUMP, "t_mesh.npz"))
    return {k: z[k] for k in z.files}


def vert_uv(d):
    n = len(d["co"])
    acc = np.zeros((n, 2))
    cnt = np.zeros(n)
    np.add.at(acc, d["loop_vert"], d["uv"])
    np.add.at(cnt, d["loop_vert"], 1.0)
    cnt[cnt == 0] = 1
    return acc / cnt[:, None]


def tex_lum(uvs, size=1024):
    im = Image.open(os.path.join(DUMP, "t_basecolor.png")).convert("RGB")
    im = im.resize((size, size), Image.LANCZOS)
    a = np.asarray(im).astype(np.float32) / 255.0
    u = np.clip(uvs[:, 0] % 1.0, 0, 1) * (size - 1)
    v = (1.0 - np.clip(uvs[:, 1] % 1.0, 0, 1)) * (size - 1)
    cols = a[v.astype(int), u.astype(int)]
    return cols @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32), a


def vertex_normals(co, tris):
    n = np.zeros_like(co)
    a, b, c = co[tris[:, 0]], co[tris[:, 1]], co[tris[:, 2]]
    fn = np.cross(b - a, c - a)
    for k in range(3):
        np.add.at(n, tris[:, k], fn)
    ln = np.linalg.norm(n, axis=1)
    ln[ln == 0] = 1
    return n / ln[:, None]


def weld_groups(co, tol=1e-6):
    """Coincident-position groups (GLB splits verts at UV seams)."""
    key = np.round(co / tol).astype(np.int64)
    _, inv = np.unique(key, axis=0, return_inverse=True)
    return inv
