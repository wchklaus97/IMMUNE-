"""Assemble processed early 2x3 + late 2x2 frames into HUD 2x5 scan sheets."""

from pathlib import Path

from PIL import Image
import numpy as np


def strip_near_magenta(im: Image.Image) -> Image.Image:
    """Key leftover chroma plates that survived generate2dsprite thresholding."""
    arr = np.array(im.convert("RGBA"))
    chroma = (arr[:, :, 0] > 200) & (arr[:, :, 2] > 200) & (arr[:, :, 1] < 90) & (arr[:, :, 3] > 0)
    arr[chroma, 3] = 0
    return Image.fromarray(arr)

IMMUNE = Path(__file__).resolve().parents[1]
WORKSPACE = Path(__file__).resolve().parents[3]
RUNS = IMMUNE / "ui_icons/symbols/sprite-runs"
GODOT_SHEETS = IMMUNE / "ui_icons/symbols/sheets"
HTML_SHEETS = WORKSPACE / "ui/immune-research-network/assets/symbols/sheets"
GODOT_SYMBOLS = IMMUNE / "ui_icons/symbols"
HTML_SYMBOLS = WORKSPACE / "ui/immune-research-network/assets/symbols"
CELL = 256
COLS = 5
ROWS = 2


def iter_ids() -> list[str]:
    names: list[str] = []
    if not RUNS.exists():
        return names
    for ident in sorted(RUNS.iterdir()):
        if not ident.is_dir():
            continue
        if (ident / "early" / "charge-1.png").exists() and (ident / "late" / "charge-1.png").exists():
            names.append(ident.name)
    return names


def main() -> None:
    GODOT_SHEETS.mkdir(parents=True, exist_ok=True)
    HTML_SHEETS.mkdir(parents=True, exist_ok=True)
    GODOT_SYMBOLS.mkdir(parents=True, exist_ok=True)
    HTML_SYMBOLS.mkdir(parents=True, exist_ok=True)
    ids = iter_ids()
    if not ids:
        raise SystemExit("no processed early/late sprite runs found")
    for ident in ids:
        family_dir = RUNS / ident
        frames = []
        for index in range(1, 7):
            path = family_dir / "early" / f"charge-{index}.png"
            if not path.exists():
                raise SystemExit(f"missing {path}")
            frames.append(strip_near_magenta(Image.open(path).convert("RGBA")))
        for index in range(1, 5):
            path = family_dir / "late" / f"charge-{index}.png"
            if not path.exists():
                raise SystemExit(f"missing {path}")
            frames.append(strip_near_magenta(Image.open(path).convert("RGBA")))
        sheet = Image.new("RGBA", (COLS * CELL, ROWS * CELL), (0, 0, 0, 0))
        for idx, frame in enumerate(frames):
            if frame.size != (CELL, CELL):
                frame = frame.resize((CELL, CELL), Image.Resampling.LANCZOS)
            row, col = divmod(idx, COLS)
            sheet.paste(frame, (col * CELL, row * CELL), frame)
            frame.save(family_dir / f"charge-{idx + 1}.png")
        sheet.save(family_dir / "sheet-transparent.png")
        name = f"{ident}-scan.png"
        sheet.save(GODOT_SHEETS / name)
        sheet.save(HTML_SHEETS / name)
        if ident.startswith("SYM-PAIR-") or ident.startswith("SYM-TRIPLE-") or ident.startswith("SYM-APEX-") or ident.startswith("SYM-BASE-") or ident.startswith("SYM-UNI-") or ident.startswith("SYM-STATUS-") or ident == "SYM-PRIME":
            still = frames[9]
            still.save(GODOT_SYMBOLS / f"{ident}.png")
            still.save(HTML_SYMBOLS / f"{ident}.png")
        print(f"{ident}: {sheet.size[0]}x{sheet.size[1]}")


if __name__ == "__main__":
    main()
