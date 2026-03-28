#!/usr/bin/env python3
"""Generate 64×64 RGBA placeholder PNGs for towers and enemies.

Run from project root:
    python tools/gen_placeholder_sprites.py
"""
import os
import struct
import zlib

W, H = 64, 64

TOWER_COLORS = {
    "cheetah":      (242, 204,  51),
    "wolf_pack":    (128, 128, 179),
    "honey_badger": ( 77,  77,  77),
    "elephant":     (153, 153, 166),
    "pangolin":     (179, 140,  89),
    "tiger":        (230, 128,  26),
    "lion":         (242, 191,  77),
    "eagle":        ( 77, 128, 230),
    "owl":          (140, 102, 179),
    "otter":        (102, 179, 153),
    "peacock":      ( 26, 191, 153),
    "chameleon":    ( 77, 204,  77),
}

ENEMY_COLORS = {
    "raptor":        (180,  80,  60),
    "pterodactyl":   (100, 140, 200),
    "triceratops":   ( 70, 140,  70),
    "brachiosaurus": ( 50, 110,  60),
    "saber_tooth":   (210, 160,  80),
    "mammoth":       ( 90,  75, 120),
    "cave_bear":     (130,  80,  40),
    "dunkleosteus":  ( 50,  90, 150),
    "mosasaurus":    ( 40, 130, 110),
    "ammonite":      (170, 160, 100),
    "trex_king":     (180,  20,  20),
}


def _png_chunk(name: bytes, data: bytes) -> bytes:
    header = name + data
    crc = zlib.crc32(header) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + header + struct.pack(">I", crc)


def _make_png(rgb: tuple) -> bytes:
    r, g, b = rgb
    cx, cy = W // 2, H // 2
    radius = W // 2 - 4

    rows = []
    for y in range(H):
        row = bytearray([0])  # filter byte None
        for x in range(W):
            dx, dy = x - cx, y - cy
            if dx * dx + dy * dy <= radius * radius:
                row += bytes([r, g, b, 255])
            else:
                row += bytes([0, 0, 0, 0])
        rows.append(bytes(row))

    raw = b"".join(rows)
    compressed = zlib.compress(raw, 9)

    png = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0)
    png += _png_chunk(b"IHDR", ihdr)
    png += _png_chunk(b"IDAT", compressed)
    png += _png_chunk(b"IEND", b"")
    return png


def generate(out_dir: str, color_map: dict) -> None:
    os.makedirs(out_dir, exist_ok=True)
    for name, rgb in color_map.items():
        path = os.path.join(out_dir, f"{name}.png")
        with open(path, "wb") as f:
            f.write(_make_png(rgb))
        print(f"  wrote {path}")


if __name__ == "__main__":
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print("Generating tower sprites...")
    generate(os.path.join(base, "assets", "art", "towers"), TOWER_COLORS)
    print("Generating enemy sprites...")
    generate(os.path.join(base, "assets", "art", "enemies"), ENEMY_COLORS)
    print("Done.")
