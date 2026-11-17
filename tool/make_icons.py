"""Rebuild the app icon lockup: the house mark stacked over "THT".

Run this, then `dart run flutter_launcher_icons`, whenever the brand mark
changes. It writes assets/images/icon.png and icon_foreground.png (the two
sources flutter_launcher_icons reads) and, optionally, the 512x512 PNG the
Play Console store listing wants, which is NOT a build artefact and so is
written outside the repo.

    PYTHONIOENCODING=utf-8 python tool/make_icons.py [path/for/play-icon-512.png]

Why a script and not a one-off: the first version of these icons was made by
hand and the source for it was thrown away, so when a launcher turned out to
be cropping the mark there was nothing to re-run and the pubspec comment
describing the files had quietly gone stale. The proportions below are
measured off the original lockup, so re-running this reproduces it.

Three numbers carry the brand and should not be nudged without looking at
the result on a real home screen:

  TEXT_W_RATIO  text width  = 40.7% of the mark's width
  TEXT_GAP      gap         = 15.2% of the mark's height
  ICON_FIT      the lockup fills 80% of a plain square icon

The adaptive foreground is the one that needs care. A launcher may mask the
foreground to a circle of 66dp inside its 108dp canvas, and a circle clips
corners, not edges -- so the lockup is inscribed by its DIAGONAL in that
circle rather than by its width. Fitting it by width is what cut the outer
arms of the T's off on round-icon launchers.
"""
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = 'D:/Downloads/THTPRO-app/'

MARK = ROOT + 'assets/images/logo_mark.png'
FONT = ROOT + 'assets/fonts/PlusJakartaSans-ExtraBold.ttf'
INK = (15, 23, 42, 255)          # #0F172A, the same ink the app's type uses

MARK_W = 2400                    # master width; everything below scales off it
TEXT_W_RATIO = 0.407
TEXT_GAP_RATIO = 0.152
ICON_FIT = 0.80
SAFE_CIRCLE = 0.66               # 66dp of the adaptive icon's 108dp canvas

WHITE = (255, 255, 255, 255)


def ink_box(im):
    """Bounding box of everything that is not white.

    Not .getbbox() on the alpha channel: these PNGs are fully opaque with the
    white baked in, so alpha covers the whole canvas and says nothing.
    """
    flat = Image.new('RGB', im.size, WHITE[:3])
    diff = ImageChops.difference(im.convert('RGB'), flat).convert('L')
    return diff.point(lambda p: 255 if p > 12 else 0).getbbox()


def build_lockup():
    mark = Image.open(MARK).convert('RGBA')
    mark = mark.crop(mark.split()[3].getbbox())
    mark = mark.resize((MARK_W, round(MARK_W * mark.height / mark.width)),
                       Image.LANCZOS)

    target_w = round(MARK_W * TEXT_W_RATIO)
    # Render large, crop to ink, then scale: the font's own metrics include
    # ascender and descender space that "THT" does not use, so measuring the
    # glyphs is the only way to land on the intended width.
    probe = Image.new('RGBA', (MARK_W, MARK_W), (255, 255, 255, 0))
    draw = ImageDraw.Draw(probe)
    draw.text((40, 40), 'THT', font=ImageFont.truetype(FONT, 900), fill=INK)
    text = probe.crop(probe.split()[3].getbbox())
    text = text.resize((target_w, round(target_w * text.height / text.width)),
                       Image.LANCZOS)

    gap = round(mark.height * TEXT_GAP_RATIO)
    lock = Image.new('RGBA',
                     (MARK_W, mark.height + gap + text.height),
                     (255, 255, 255, 0))
    lock.alpha_composite(mark, (0, 0))
    lock.alpha_composite(text, ((MARK_W - text.width) // 2,
                                mark.height + gap))
    return lock


def frame(lock, size, fit, path):
    """Centre the lockup on a white square, its width `fit` of the canvas."""
    w = round(size * fit)
    h = round(w * lock.height / lock.width)
    out = Image.new('RGBA', (size, size), WHITE)
    out.alpha_composite(lock.resize((w, h), Image.LANCZOS),
                        ((size - w) // 2, (size - h) // 2))
    out.save(path)
    print(path, out.size, 'ink', ink_box(out))


def main():
    lock = build_lockup()
    print('lockup', lock.size, 'aspect', round(lock.width / lock.height, 3))

    frame(lock, 1024, ICON_FIT, ROOT + 'assets/images/icon.png')

    # Inscribe by the diagonal, not the width: on a round mask the corners of
    # the lockup's box are what reach furthest from the centre.
    diag = 1024 * SAFE_CIRCLE
    aspect = lock.width / lock.height
    height = diag / (1 + aspect ** 2) ** 0.5
    frame(lock, 1024, (height * aspect) / 1024,
          ROOT + 'assets/images/icon_foreground.png')

    if len(sys.argv) > 1:
        frame(lock, 512, ICON_FIT, sys.argv[1])


if __name__ == '__main__':
    main()
