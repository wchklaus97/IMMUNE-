import sys
import numpy as np
from PIL import Image


def segs(path, ys):
    rgb = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)
    print(path, rgb.shape)
    for y in ys:
        row = rgb[y].max(axis=1) > 30
        idx = np.nonzero(row)[0]
        if idx.size == 0:
            print(f"  y={y}: empty")
            continue
        runs = []
        s = idx[0]
        p = idx[0]
        for i in idx[1:]:
            if i != p + 1:
                runs.append((s, p))
                s = i
            p = i
        runs.append((s, p))
        print(f"  y={y}: " + " ".join(f"[{a}-{b}|{b-a+1}]" for a, b in runs))


if __name__ == "__main__":
    path = sys.argv[1]
    ys = [int(v) for v in sys.argv[2:]]
    segs(path, ys)
