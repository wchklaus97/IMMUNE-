"""Side-by-side crops normalised to a common height, for eyeballing one region.

Usage: python critic2_pair.py <out.png> <height> <img:x0,y0,x1,y1> [...]
"""

import sys
from pathlib import Path

from PIL import Image


def main(argv):
    out = Path(argv[0])
    height = int(argv[1])
    panels = []
    for spec in argv[2:]:
        path, box = spec.rsplit(":", 1)
        x0, y0, x1, y1 = (int(v) for v in box.split(","))
        img = Image.open(path).convert("RGB").crop((x0, y0, x1, y1))
        scale = height / img.height
        panels.append(img.resize((max(1, int(img.width * scale)), height), Image.LANCZOS))
    gap = 8
    sheet = Image.new("RGB", (sum(p.width for p in panels) + gap * (len(panels) - 1), height), (40, 40, 40))
    x = 0
    for p in panels:
        sheet.paste(p, (x, 0))
        x += p.width + gap
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"PAIR {out} {sheet.size}")


if __name__ == "__main__":
    main(sys.argv[1:])
