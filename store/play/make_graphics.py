# -*- coding: utf-8 -*-
"""Play Store graphics, generated from the app's own artwork.

Two files Play will not publish a listing without:
  store/play/icon-512.png                512x512, opaque
  store/play/feature-graphic-1024x500.png

Both are built from assets/images, so they cannot drift from the app's own
icon and logo. Re-run this script if either of those changes.
"""
import os
from PIL import Image, ImageDraw, ImageFont

# Repo root, two levels up from store/play/, so this runs from anywhere.
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(R, 'store', 'play')
os.makedirs(OUT, exist_ok=True)

WHITE = (255, 255, 255)
INK = (16, 27, 49)          # the near-black of the wordmark
BLUE = (25, 167, 224)       # the house blue
ORANGE = (225, 112, 46)     # AppColors.primaryOrange
SLATE = (71, 85, 105)       # slate-600

BOLD = 'C:/Windows/Fonts/segoeuib.ttf'
REG = 'C:/Windows/Fonts/segoeui.ttf'


def flatten(path):
    """Composite an RGBA asset onto white; Play wants no alpha."""
    im = Image.open(path).convert('RGBA')
    bg = Image.new('RGBA', im.size, WHITE + (255,))
    return Image.alpha_composite(bg, im)


def trim(im, bg=WHITE):
    """Crop the white margin off, so the mark can be re-padded deliberately."""
    rgb = im.convert('RGB')
    mask = Image.new('RGB', rgb.size, bg)
    from PIL import ImageChops
    diff = ImageChops.difference(rgb, mask).convert('L')
    box = diff.point(lambda p: 255 if p > 8 else 0).getbbox()
    return im.crop(box) if box else im


def trim_alpha(path):
    """Crop to the drawn pixels, keeping transparency, so the artwork can sit
    on a coloured ground without dragging a white rectangle along with it."""
    im = Image.open(path).convert('RGBA')
    box = im.split()[3].getbbox()
    return im.crop(box) if box else im


# ---------------------------------------------------------------- 512 icon
#
# The launcher icon carries a wide margin, which is right on a home screen and
# wrong on a store listing, where the icon is already small. Trim the artwork
# back to its own edges and re-pad to a deliberate 8%, so the mark actually
# fills the tile.
mark = trim(flatten(os.path.join(R, 'assets/images/icon.png')))
pad = 0.08
inner = int(512 * (1 - 2 * pad))
w, h = mark.size
scale = min(inner / w, inner / h)
mark = mark.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.LANCZOS)

icon = Image.new('RGB', (512, 512), WHITE)
icon.paste(mark, ((512 - mark.width) // 2, (512 - mark.height) // 2), mark)
icon.save(os.path.join(OUT, 'icon-512.png'), 'PNG', optimize=True)
print('icon-512.png', icon.size, icon.mode)


# ------------------------------------------------------- feature graphic
#
# 1024x500. Google crops the edges on some surfaces, so everything that must
# be read sits inside the middle. Logo left, the promise right, nothing else.
W, H = 1024, 500
fg = Image.new('RGB', (W, H), WHITE)
d = ImageDraw.Draw(fg)

# A soft vertical wash, white at the top into the faintest blue, so the card
# does not read as a blank rectangle next to other listings.
for y in range(H):
    t = y / float(H - 1)
    d.line([(0, y), (W, y)],
           fill=(int(255 - 21 * t), int(255 - 9 * t), int(255 - 2 * t)))

# The brand's own blue, as a wedge in the bottom-right corner that echoes the
# roof line in the logo rather than competing with it.
d.polygon([(W, H), (W, int(H * 0.30)), (int(W * 0.72), H)], fill=(232, 246, 253))
d.polygon([(W, H), (W, int(H * 0.56)), (int(W * 0.84), H)], fill=(214, 238, 251))

logo = trim_alpha(os.path.join(R, 'assets/images/logo.png'))
target_h = 250
lw, lh = logo.size
scale = target_h / float(lh)
logo = logo.resize((int(lw * scale), target_h), Image.LANCZOS)
fg.paste(logo, (72, (H - target_h) // 2), logo)

x = 72 + logo.width + 64
f_head = ImageFont.truetype(BOLD, 46)
f_sub = ImageFont.truetype(REG, 27)

head1 = 'Verified home tutors,'
head2 = 'one tuition at a time'
sub1 = "Lucknow's home tuition network"
sub2 = 'Parents find a tutor. Teachers find work.'

y = 150
d.text((x, y), head1, font=f_head, fill=INK)
y += 56
d.text((x, y), head2, font=f_head, fill=INK)
y += 76
d.rectangle([x, y + 4, x + 54, y + 9], fill=ORANGE)
y += 28
d.text((x, y), sub1, font=f_sub, fill=SLATE)
y += 38
d.text((x, y), sub2, font=f_sub, fill=SLATE)

fg.save(os.path.join(OUT, 'feature-graphic-1024x500.png'), 'PNG', optimize=True)
print('feature-graphic-1024x500.png', fg.size, fg.mode)
