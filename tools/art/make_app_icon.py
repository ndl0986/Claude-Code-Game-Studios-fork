#!/usr/bin/env python3
"""Draw the PLACEHOLDER app icon (TASK-026): a bronze-drum sun star on an indigo disc.

Final art waits for D-18 (portrayal and palette sign-off). Colours come from the art bible
(design/art/art-bible.md §4, primary palette). No text: it is unreadable at icon size.

Writes into assets/art/app_icon/ (relative to the repo root given as argv[1], default "."):
  icon_ios_1024.png            iOS App Store / AppIcon single size: 1024x1024 RGB, no alpha,
                               square corners (iOS applies its own mask)
  play_512.png                 Google Play listing icon: 512x512 RGB (Play applies its mask)
  ic_launcher_foreground.png   Android adaptive foreground: 432x432 RGBA (108dp @ xxxhdpi)
  ic_launcher_background.png   Android adaptive background: 432x432 RGB
  ic_launcher_monochrome.png   Android 13+ themed-icon layer: 432x432 RGBA, white on clear
  previews/*.png               small renders under each mask, for the readability check

Run: python -I tools/art/make_app_icon.py .   (needs Pillow; nothing else)
Deterministic: the same input gives byte-identical shapes (no randomness).
"""
import math
import os
import sys

from PIL import Image, ImageDraw

# Art bible §4 primary palette
RIVER_BLUE = (0x3E, 0x8F, 0xC4)
BRONZE_GOLD = (0xE8, 0xA9, 0x3B)
STORM_INDIGO = (0x3B, 0x3F, 0x6B)
INK_BROWN = (0x4A, 0x34, 0x28)
PAPER_CREAM = (0xF3, 0xE6, 0xC8)

SS = 4  # supersampling factor for smooth edges

# Mark geometry as fractions of the mark radius R (outer edge of the disc outline).
DISC_OUTLINE = 0.06       # ink ring width
STAR_OUTER = 0.80         # star tip radius
STAR_INNER = 0.46         # star valley radius (chunky points stay readable at 40 px)
STAR_POINTS = 12          # Đông Sơn drum centre star
STAR_OUTLINE = 0.05
HUB = 0.16                # small cream hub in the star's centre


def star_polygon(cx, cy, r_out, r_in, n, rot=-math.pi / 2):
    pts = []
    for i in range(2 * n):
        r = r_out if i % 2 == 0 else r_in
        a = rot + i * math.pi / n
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def draw_mark(d, cx, cy, R, mono=False):
    """Draw the mark of outer radius R centred at (cx, cy). Returns the bounding radius used."""
    ink = (255, 255, 255, 255) if mono else INK_BROWN
    if not mono:
        d.ellipse([cx - R, cy - R, cx + R, cy + R], fill=INK_BROWN)
        r = R * (1 - DISC_OUTLINE)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=STORM_INDIGO)
    ro = R * STAR_OUTER
    ri = R * STAR_INNER
    w = R * STAR_OUTLINE
    # outline = the same star grown by w
    d.polygon(star_polygon(cx, cy, ro + w, ri + w, STAR_POINTS), fill=ink)
    if mono:
        return R * STAR_OUTER + w
    d.polygon(star_polygon(cx, cy, ro, ri, STAR_POINTS), fill=BRONZE_GOLD)
    h = R * HUB
    d.ellipse([cx - h - w, cy - h - w, cx + h + w, cy + h + w], fill=INK_BROWN)
    d.ellipse([cx - h, cy - h, cx + h, cy + h], fill=PAPER_CREAM)
    return R


def render(size, mark_radius_frac, background, mono=False):
    S = size * SS
    mode = "RGBA"
    bg = (0, 0, 0, 0) if background is None else background + (255,)
    img = Image.new(mode, (S, S), bg)
    d = ImageDraw.Draw(img)
    used = draw_mark(d, S / 2, S / 2, S * mark_radius_frac, mono=mono)
    img = img.resize((size, size), Image.LANCZOS)
    return img, used / SS


def flat_rgb(img):
    return img.convert("RGB")


# ---- masks for previews -------------------------------------------------------------
def mask_rounded(size, radius_frac):
    m = Image.new("L", (size * SS, size * SS), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [0, 0, size * SS - 1, size * SS - 1], radius=radius_frac * size * SS, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def mask_circle(size):
    m = Image.new("L", (size * SS, size * SS), 0)
    ImageDraw.Draw(m).ellipse([0, 0, size * SS - 1, size * SS - 1], fill=255)
    return m.resize((size, size), Image.LANCZOS)


def mask_squircle(size, n=4.0):
    S = size * SS
    m = Image.new("L", (S, S), 0)
    pts = []
    for i in range(720):
        t = 2 * math.pi * i / 720
        c, s = math.cos(t), math.sin(t)
        x = math.copysign(abs(c) ** (2 / n), c)
        y = math.copysign(abs(s) ** (2 / n), s)
        pts.append((S / 2 + x * S / 2, S / 2 + y * S / 2))
    ImageDraw.Draw(m).polygon(pts, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def apply_mask(img, mask, backdrop=(255, 255, 255)):
    out = Image.new("RGB", img.size, backdrop)
    out.paste(img.convert("RGB"), (0, 0), mask)
    return out


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    out = os.path.join(root, "assets", "art", "app_icon")
    prev = os.path.join(out, "previews")
    os.makedirs(prev, exist_ok=True)

    # iOS / Play: full-bleed river blue, mark radius 0.40 of the side.
    # iOS's corner mask (~0.2237 of the side) never reaches a circle of radius 0.40.
    ios, _ = render(1024, 0.40, RIVER_BLUE)
    flat_rgb(ios).save(os.path.join(out, "icon_ios_1024.png"), optimize=True)
    play, _ = render(512, 0.40, RIVER_BLUE)
    flat_rgb(play).save(os.path.join(out, "play_512.png"), optimize=True)

    # Android adaptive: 108dp canvas = 432 px at xxxhdpi (4 px/dp).
    # Safe zone: the 66dp circle (radius 33dp = 132 px), kept by every launcher mask.
    PX_PER_DP = 4
    SAFE_R = 33 * PX_PER_DP
    MARK_R_DP = 30                     # mark radius 30dp: 3dp margin inside the safe circle
    frac = MARK_R_DP / 108
    fg, used = render(432, frac, None)
    fg.save(os.path.join(out, "ic_launcher_foreground.png"), optimize=True)
    bg = Image.new("RGB", (432, 432), RIVER_BLUE)
    bg.save(os.path.join(out, "ic_launcher_background.png"), optimize=True)
    mono, used_mono = render(432, frac, None, mono=True)
    mono.save(os.path.join(out, "ic_launcher_monochrome.png"), optimize=True)
    for name, r in (("foreground", used), ("monochrome", used_mono)):
        status = "OK" if r <= SAFE_R else "OUTSIDE"
        print(f"android {name}: mark radius {r:.1f} px vs safe radius {SAFE_R} px -> {status}")
        if r > SAFE_R:
            sys.exit(1)

    # Android composite as a launcher shows it: background + foreground, then the centre
    # 72dp viewport (288 px of 432), then the mask.
    comp = bg.convert("RGBA")
    comp.alpha_composite(fg)
    view = comp.crop((72, 72, 360, 360))

    def save_preview(img, px, mask_fn, name):
        small = img.resize((px, px), Image.LANCZOS)
        apply_mask(small, mask_fn(px)).save(os.path.join(prev, name))

    for px in (60, 40):
        save_preview(ios, px, lambda s: mask_rounded(s, 0.2237), f"ios_{px}.png")
        save_preview(view, px, mask_circle, f"android_circle_{px}.png")
        save_preview(view, px, mask_squircle, f"android_squircle_{px}.png")
        save_preview(view, px, lambda s: mask_rounded(s, 0.16), f"android_roundsquare_{px}.png")

    # One contact sheet at 4x zoom (nearest neighbour), so a reviewer sees the real pixels.
    names = sorted(f for f in os.listdir(prev) if f.endswith(".png") and f != "sheet.png")
    tiles = [Image.open(os.path.join(prev, n)) for n in names]
    gap = 16
    w = sum(t.width * 4 + gap for t in tiles) + gap
    h = max(t.height * 4 for t in tiles) + 2 * gap
    sheet = Image.new("RGB", (w, h), (255, 255, 255))
    x = gap
    for t in tiles:
        sheet.paste(t.resize((t.width * 4, t.height * 4), Image.NEAREST), (x, gap))
        x += t.width * 4 + gap
    sheet.save(os.path.join(prev, "sheet.png"))
    print("previews:", ", ".join(names + ["sheet.png"]))


if __name__ == "__main__":
    main()
