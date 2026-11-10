#!/usr/bin/env python3
"""Texturas de papel para los estilos de álbum vintage. Requiere numpy y pillow.
Uso: python3 tools/make_skins.py"""
import numpy as np
from PIL import Image

def fbm(w, h, cells, octaves, seed):
    rng = np.random.default_rng(seed)
    acc = np.zeros((h, w), np.float32); amp = 1.0; tot = 0.0
    for o in range(octaves):
        c = max(2, int(cells * (2 ** o)))
        small = rng.random((max(2, int(c * h / w)), c)).astype(np.float32)
        img = Image.fromarray((small * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        acc += amp * np.asarray(img, np.float32) / 255.0; tot += amp; amp *= 0.5
    acc /= tot
    return (acc - acc.min()) / (acc.max() - acc.min())

def vignette(w, h, p=2.2):
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.sqrt(((x / w - .5) * 1.6) ** 2 + ((y / h - .5) * 1.6) ** 2)
    return np.clip(d, 0, 1) ** p

def save(col, out):
    Image.fromarray(np.clip(col, 0, 255).astype(np.uint8)).save(out, quality=86)

def black(w, h, seed, out):
    base = np.array([20, 20, 23], np.float32)
    fib = fbm(w, h, 160, 2, seed)[..., None]
    mott = fbm(w, h, 6, 3, seed + 1)[..., None]
    col = base + (fib - .5) * 9 + (mott - .5) * 6
    col -= vignette(w, h)[..., None] * 9
    col += np.random.default_rng(seed).normal(0, 1.6, (h, w, 1))
    save(col, out)

def kraft(w, h, seed, out):
    lo, hi = np.array([188, 150, 102], np.float32), np.array([214, 181, 133], np.float32)
    t = (0.6 * fbm(w, h, 5, 3, seed) + 0.4 * fbm(w, h, 24, 3, seed + 1))[..., None]
    col = lo + (hi - lo) * t
    fib = fbm(w, h, 220, 1, seed + 2)[..., None]
    col += (fib - .5) * 16
    streak = fbm(w, 6, 3, 2, seed + 3)      # fibras largas horizontales
    col += (np.asarray(Image.fromarray((streak * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC), np.float32)[..., None] / 255 - .5) * 10
    col -= vignette(w, h)[..., None] * np.array([34, 36, 30], np.float32)
    col += np.random.default_rng(seed).normal(0, 2.0, (h, w, 1))
    save(col, out)

def aged(w, h, seed, out):
    base = np.array([240, 228, 200], np.float32)
    stain = fbm(w, h, 4, 4, seed)[..., None]
    col = base - (stain - .5) * np.array([16, 22, 34], np.float32)
    rng = np.random.default_rng(seed + 5)
    spots = np.zeros((h, w), np.float32)
    for _ in range(int(w * h / 22000)):                       # manchas de humedad (foxing)
        cx, cy, r = rng.integers(0, w), rng.integers(0, h), rng.integers(3, 14)
        y0, y1, x0, x1 = max(0, cy - r), min(h, cy + r), max(0, cx - r), min(w, cx + r)
        yy, xx = np.mgrid[y0:y1, x0:x1]
        spots[y0:y1, x0:x1] += np.clip(1 - np.sqrt((yy - cy) ** 2 + (xx - cx) ** 2) / r, 0, 1) * rng.uniform(.1, .35)
    col -= np.clip(spots, 0, 1)[..., None] * np.array([34, 52, 80], np.float32)
    col -= vignette(w, h, 1.8)[..., None] * np.array([40, 58, 90], np.float32)   # bordes amarillentos
    col += (fbm(w, h, 200, 1, seed + 6)[..., None] - .5) * 7
    col += np.random.default_rng(seed).normal(0, 1.7, (h, w, 1))
    save(col, out)

for name, fn, s in [("black", black, 3), ("kraft", kraft, 5), ("cloth", aged, 9)]:
    fn(1000, 2200, s, f"Memorias/Resources/skin-{name}-portrait.jpg")
    fn(1800, 1350, s + 1, f"Memorias/Resources/skin-{name}-landscape.jpg")
print("ok")
