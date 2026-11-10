#!/usr/bin/env python3
"""Genera el fondo de papel acuarela (arena arriba, blanco abajo) de la pantalla «Mi día».
Requiere: pip install numpy pillow.  Uso: python3 tools/make_paper.py"""
import numpy as np
from PIL import Image

def fbm(w, h, cells, octaves, seed):
    rng = np.random.default_rng(seed)
    acc = np.zeros((h, w), dtype=np.float32); amp = 1.0; tot = 0.0
    for o in range(octaves):
        c = max(2, int(cells * (2 ** o)))
        small = rng.random((max(2, int(c * h / w)), c)).astype(np.float32)
        img = Image.fromarray((small * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        acc += amp * (np.asarray(img, dtype=np.float32) / 255.0); tot += amp; amp *= 0.5
    acc /= tot
    return (acc - acc.min()) / (acc.max() - acc.min())

def smooth(x, a, b):
    t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)

def make(w, h, edge, seed, out):
    y = np.linspace(0, 1, h, dtype=np.float32)[:, None] * np.ones((1, w), np.float32)
    low, mid, hi = fbm(w, h, 3, 3, seed), fbm(w, h, 9, 3, seed + 1), fbm(w, h, 40, 2, seed + 2)
    dens = smooth(0.55 * low + 0.35 * mid + 0.10 * hi, 0.30, 0.78)          # nubes de pigmento
    ex = fbm(w, 8, 4, 3, seed + 3)[3]                                         # borde irregular
    y_edge = edge + 0.045 * (ex - 0.5) * 2
    y_edge = y_edge[None, :] + 0.025 * (mid - 0.5)
    wet = 1 - smooth(y, y_edge - 0.06, y_edge + 0.015)                        # 1 = mojado, 0 = blanco
    ring = np.exp(-(((y - y_edge) / 0.010) ** 2)) * (0.45 + 0.55 * mid)       # borde donde se acumula pigmento
    cream = np.array([248, 238, 218], np.float32)
    tan = np.array([228, 198, 154], np.float32)
    deep = np.array([214, 174, 122], np.float32)
    col = cream + (tan - cream) * dens[..., None]
    col = col + (deep - col) * np.clip(ring + 0.35 * smooth(dens * (1 - hi * 0.4), 0.7, 1.0), 0, 1)[..., None]
    white = np.array([253, 252, 250], np.float32)
    col = white + (col - white) * wet[..., None]
    rng = np.random.default_rng(seed + 9)
    col += rng.normal(0, 2.2, (h, w, 1)).astype(np.float32)                   # grano del papel
    col += (fbm(w, h, 120, 1, seed + 5)[..., None] - 0.5) * 5                 # fibras
    Image.fromarray(np.clip(col, 0, 255).astype(np.uint8)).save(out, quality=88)

make(1000, 2200, 0.56, 11, "Memorias/Resources/paper-portrait.jpg")
make(1800, 1350, 0.62, 23, "Memorias/Resources/paper-landscape.jpg")
print("ok")
