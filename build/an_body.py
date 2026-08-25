"""Where the limbs and the hem actually are, in cylindrical coordinates.

The silhouette work is all on the body shell, so this maps the outer radius as
a function of height and azimuth. Azimuth 0 is +X (screen right in the front
render), 90 is +Y (behind the character), 180 is -X, 270 is -Y (facing camera).
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bl_fix_t_ops as ops  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
RAMP = " .:-=+*#%@"


def body_shell(co, tris):
    inv, P = ops.weld(co)
    gt = ops.group_tris(tris, inv)
    comp = ops.components(len(P), ops.tri_edges(gt))
    ids, counts = np.unique(comp, return_counts=True)
    big = ids[np.argmax(counts)]
    return P, gt, comp, big


def main(path):
    d = np.load(path)
    co, tris = d["co"], d["tris"]
    P, gt, comp, big = body_shell(co, tris)
    B = P[comp == big]
    zlo, zhi = B[:, 2].min(), B[:, 2].max()
    print("body shell %d verts, z %.4f .. %.4f, x %.4f .. %.4f, y %.4f .. %.4f"
          % (len(B), zlo, zhi, B[:, 0].min(), B[:, 0].max(),
             B[:, 1].min(), B[:, 1].max()))

    # outer radius about the vertical axis through the body centre in xy
    cx, cy = 0.0, B[:, 1].mean()
    r = np.hypot(B[:, 0] - cx, B[:, 1] - cy)
    th = np.degrees(np.arctan2(B[:, 1] - cy, B[:, 0] - cx)) % 360.0
    print("axis at x %.4f y %.4f" % (cx, cy))

    nz, nt = 26, 36
    zed = np.linspace(zlo, zhi, nz + 1)
    grid = np.zeros((nz, nt))
    for i in range(nz):
        zm = (B[:, 2] >= zed[i]) & (B[:, 2] < zed[i + 1] + 1e-9)
        for j in range(nt):
            tm = zm & (th >= j * 360.0 / nt) & (th < (j + 1) * 360.0 / nt)
            grid[i, j] = r[tm].max() if tm.any() else np.nan

    hi = np.nanmax(grid)
    print("max radius %.4f   (columns are azimuth 0..350 in 10 deg steps)" % hi)
    print("   z      " + "".join("%-2d" % (j * 10 // 10 % 10) for j in range(nt)))
    for i in range(nz - 1, -1, -1):
        row = grid[i]
        s = "".join(" " if np.isnan(v) else
                    RAMP[min(int(v / hi * (len(RAMP) - 1)), len(RAMP) - 1)]
                    for v in row)
        print("  %.3f  %s   max %.4f" % (zed[i], s, np.nanmax(row)))

    # widest point of the outline, and the hem
    print("\nfront-view half width by height (max |x| in each band):")
    for i in range(nz - 1, -1, -1):
        zm = (B[:, 2] >= zed[i]) & (B[:, 2] < zed[i + 1] + 1e-9)
        if zm.any():
            print("  z %.3f  |x|max %.4f  |y|span %.4f .. %.4f"
                  % (zed[i], np.abs(B[zm, 0]).max(),
                     B[zm, 1].min(), B[zm, 1].max()))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1
         else os.path.join(HERE, "dump", "t_mesh.npz"))
