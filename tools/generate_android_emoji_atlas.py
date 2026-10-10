"""Build the single-codepoint Android/Gboard-style emoji atlas used by UTEU.

The source font is Google's official NotoColorEmoji Windows-compatible build.
GameMaker stores four-byte Unicode correctly, but its draw_text path does not
render colour-font layers.  This generator rasterises those layers once so the
runtime can draw them from one texture instead of shipping thousands of files.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw, ImageFont


CELL_SIZE = 64
COLUMNS = 64
SOURCE_SIZE = 112
INSET = 4


def is_single_codepoint_emoji(code: int) -> bool:
    return (
        0x1F000 <= code <= 0x1FAFF
        or 0x2300 <= code <= 0x23FF
        or 0x2600 <= code <= 0x27BF
        or 0x2B00 <= code <= 0x2BFF
        or code in (0x00A9, 0x00AE, 0x203C, 0x2049, 0x2122, 0x3030, 0x303D, 0x3297, 0x3299)
    )


def load_render_font(path: Path) -> ImageFont.FreeTypeFont:
    for size in (SOURCE_SIZE, 109, 96, 72, 64):
        try:
            return ImageFont.truetype(str(path), size=size)
        except OSError:
            continue
    raise RuntimeError(f"Pillow/FreeType cannot load a usable strike from {path}")


def render_tile(font: ImageFont.FreeTypeFont, character: str) -> Image.Image | None:
    scratch = Image.new("RGBA", (SOURCE_SIZE * 2, SOURCE_SIZE * 2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(scratch)
    try:
        bounds = draw.textbbox((0, 0), character, font=font, embedded_color=True)
    except (OSError, ValueError):
        return None
    width = max(1, bounds[2] - bounds[0])
    height = max(1, bounds[3] - bounds[1])
    x = (scratch.width - width) // 2 - bounds[0]
    y = (scratch.height - height) // 2 - bounds[1]
    try:
        draw.text((x, y), character, font=font, embedded_color=True)
    except (OSError, ValueError):
        return None
    alpha_bounds = scratch.getchannel("A").getbbox()
    if alpha_bounds is None:
        return None
    glyph = scratch.crop(alpha_bounds)
    available = CELL_SIZE - INSET * 2
    scale = min(available / glyph.width, available / glyph.height, 1.0)
    resized = glyph.resize(
        (max(1, round(glyph.width * scale)), max(1, round(glyph.height * scale))),
        Image.Resampling.LANCZOS,
    )
    tile = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
    tile.alpha_composite(resized, ((CELL_SIZE - resized.width) // 2, (CELL_SIZE - resized.height) // 2))
    return tile


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("font", type=Path)
    parser.add_argument("output_png", type=Path)
    parser.add_argument("output_json", type=Path)
    args = parser.parse_args()

    cmap = TTFont(str(args.font)).getBestCmap() or {}
    candidates = sorted(code for code in cmap if is_single_codepoint_emoji(code))
    render_font = load_render_font(args.font)
    rendered: list[tuple[int, Image.Image]] = []
    for code in candidates:
        tile = render_tile(render_font, chr(code))
        if tile is not None:
            rendered.append((code, tile))

    rows = max(1, math.ceil(len(rendered) / COLUMNS))
    atlas = Image.new("RGBA", (COLUMNS * CELL_SIZE, rows * CELL_SIZE), (0, 0, 0, 0))
    codes: list[int] = []
    for index, (code, tile) in enumerate(rendered):
        atlas.alpha_composite(tile, ((index % COLUMNS) * CELL_SIZE, (index // COLUMNS) * CELL_SIZE))
        codes.append(code)

    args.output_png.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(args.output_png, optimize=True)
    args.output_json.write_text(
        json.dumps(
            {"cell": CELL_SIZE, "columns": COLUMNS, "codes": codes},
            ensure_ascii=True,
            separators=(",", ":"),
        ),
        encoding="utf-8",
    )
    print(f"rendered={len(codes)} atlas={atlas.width}x{atlas.height}")


if __name__ == "__main__":
    main()
