"""Rebuild the app icon from the brand logo, exactly as the logo is drawn.

Run this, then `dart run flutter_launcher_icons`, whenever the logo changes.
It writes assets/images/icon.png and icon_foreground.png (the two sources
flutter_launcher_icons reads) and, optionally, the 512x512 PNG the Play
Console store listing wants, which is not a build artefact and so is written
outside the repo.

    PYTHONIOENCODING=utf-8 python tool/make_icons.py [path/for/play-icon-512.png]

The source is assets/images/logo.png and nothing is redrawn or substituted:
the roof, "THE HOME TUITIONS" and "Learn & Earn" all go in as they are. An
earlier version of these icons set the house mark over the letters "THT"
instead, which is not the logo.

The adaptive foreground is the one that needs care. A launcher may mask it to
a circle 66dp across inside its 108dp canvas, and a circle clips corners, not
edges. Rather than shrink the logo until its whole bounding box fits -- which
wastes a lot of room, because the logo's own corners are empty -- this scales
it until the furthest INK pixel from the centre sits on that circle. Nothing
can be cut, and the logo still renders as large as the mask allows.
"""
import sys

from PIL import Image, ImageChops

ROOT = 'D:/Downloads/THTPRO-app/'

LOGO = ROOT + 'assets/images/logo.png'
ICON_FIT = 0.86                  # logo width as a fraction of a plain icon
SAFE_CIRCLE = 0.66               # 66dp of the adaptive icon's 108dp canvas
WHITE = (255, 255, 255, 255)


def ink_box(im):
    """Bounding box of everything that is not white.

    Not .getbbox() on the alpha channel: the icons this writes are fully
    opaque with the white baked in, so alpha covers the whole canvas and says
    nothing about where the artwork is.
    """
    flat = Image.new('RGB', im.size, WHITE[:3])
    diff = ImageChops.difference(im.convert('RGB'), flat).convert('L')
    return diff.point(lambda p: 255 if p > 12 else 0).getbbox()


def load_logo():
    logo = Image.open(LOGO).convert('RGBA')
    return logo.crop(logo.split()[3].getbbox())


def ink_radius(logo):
    """Furthest ink pixel from the logo's centre, as a fraction of its width.

    Measured on a small copy -- the result is a ratio, and a 200px-wide
    sample is plenty for a value used to scale artwork.
    """
    w = 200
    small = logo.resize((w, max(1, round(w * logo.height / logo.width))),
                        Image.LANCZOS)
    alpha = small.split()[3]
    cx, cy = small.width / 2, small.height / 2
    best = 0.0
    for y in range(small.height):
        row = alpha.crop((0, y, small.width, y + 1)).getdata()
        for x, a in enumerate(row):
            if a > 24:
                d = ((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2) ** 0.5
                if d > best:
                    best = d
    return best / small.width


def frame(logo, size, width_px, path):
    """Centre the logo on a white square at the given drawn width."""
    w = round(width_px)
    h = round(w * logo.height / logo.width)
    out = Image.new('RGBA', (size, size), WHITE)
    out.alpha_composite(logo.resize((w, h), Image.LANCZOS),
                        ((size - w) // 2, (size - h) // 2))
    out.save(path)
    print(path, out.size, 'ink', ink_box(out))


def main():
    logo = load_logo()
    print('logo', logo.size, 'aspect', round(logo.width / logo.height, 3))

    frame(logo, 1024, 1024 * ICON_FIT, ROOT + 'assets/images/icon.png')

    # Largest width whose furthest ink pixel still lands inside the safe
    # circle: radius = ink_radius * width, and that must reach 33% of 1024.
    safe_w = (1024 * SAFE_CIRCLE / 2) / ink_radius(logo)
    print('adaptive width', round(safe_w), 'of 1024',
          '(bounding-box fit would be',
          round(1024 * SAFE_CIRCLE /
                (1 + (logo.height / logo.width) ** 2) ** 0.5), ')')
    frame(logo, 1024, safe_w, ROOT + 'assets/images/icon_foreground.png')

    if len(sys.argv) > 1:
        frame(logo, 512, 512 * ICON_FIT, sys.argv[1])


if __name__ == '__main__':
    main()
