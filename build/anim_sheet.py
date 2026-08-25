"""Contact sheet for a gel-rig animation strip.

Usage: python build/anim_sheet.py <shots dir> <tag> <anim> [cols] [cell] [face]

Reads <tag>-<anim>-NN.png, crops each frame to the shared subject bounding box
so the motion is not hidden by letterboxing, and writes a numbered grid to
<tag>-<anim>-SHEET.png next to them.

Pass `face` as the sixth argument to crop to the top two thirds of the subject
instead, which is the readability check for the pore, eyes and frown.
"""

import sys
import pathlib

from PIL import Image, ImageDraw


def frame_paths(shots: pathlib.Path, tag: str, anim: str):
    return sorted(shots.glob(f"{tag}-{anim}-[0-9][0-9].png"))


def content_box(images):
    """Union of the non-background pixels across every frame."""
    box = None
    for img in images:
        bbox = img.convert("L").point(lambda v: 255 if v > 18 else 0).getbbox()
        if bbox is None:
            continue
        box = bbox if box is None else (
            min(box[0], bbox[0]),
            min(box[1], bbox[1]),
            max(box[2], bbox[2]),
            max(box[3], bbox[3]),
        )
    return box


def main() -> int:
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    shots = pathlib.Path(sys.argv[1])
    tag, anim = sys.argv[2], sys.argv[3]
    cols = int(sys.argv[4]) if len(sys.argv) > 4 else 6
    cell = int(sys.argv[5]) if len(sys.argv) > 5 else 300
    face = len(sys.argv) > 6 and sys.argv[6] == "face"

    paths = frame_paths(shots, tag, anim)
    if not paths:
        print(f"no frames for {tag}-{anim} in {shots}")
        return 1
    images = [Image.open(p).convert("RGB") for p in paths]

    box = content_box(images)
    if box is not None:
        pad = 18
        w, h = images[0].size
        box = (
            max(0, box[0] - pad),
            max(0, box[1] - pad),
            min(w, box[2] + pad),
            min(h, box[3] + pad),
        )
        if face:
            side = int((box[3] - box[1]) * 0.66)
            cx = (box[0] + box[2]) // 2
            box = (
                max(0, cx - side // 2),
                box[1],
                min(w, cx + side // 2),
                min(h, box[1] + side),
            )
        images = [im.crop(box) for im in images]

    rows = (len(images) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell, rows * cell), (8, 9, 12))
    draw = ImageDraw.Draw(sheet)
    for i, im in enumerate(images):
        im = im.resize((cell, cell), Image.LANCZOS)
        x, y = (i % cols) * cell, (i // cols) * cell
        sheet.paste(im, (x, y))
        draw.text((x + 8, y + 6), f"{i:02d}", fill=(240, 240, 245))
        draw.rectangle([x, y, x + cell - 1, y + cell - 1], outline=(38, 42, 50))

    out = shots / f"{tag}-{anim}-{'FACE' if face else 'SHEET'}.png"
    sheet.save(out)
    print(f"SHEET {out}  frames={len(images)} crop={box}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
