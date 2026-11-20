"""Square contact sheet: each cast SVG beside its silhouette (grey), half size, on cream cells with the feet line.
Usage: python contact_sheet.py <theme-dir> <out.svg> <stem> [<stem> ...]   (stem e.g. dino_t_trex_01)
Render headless (no window): nice -n 10 qlmanage -t -s 1800 -o <dir> <out.svg>  (Quick Look crops to a square)."""
import math, re, sys, os

def inner(path):
    s = open(path).read()
    s = re.sub(r'<\?xml[^>]*>', '', s)
    s = re.sub(r'<title>.*?</title>', '', s, flags=re.S)
    return re.sub(r'^\s*<svg[^>]*>|</svg>\s*$', '', s.strip(), flags=re.S)

def main(theme, out, stems):
    W, H, PAD, LAB = 320, 220, 12, 22            # one half-size artboard, padding, label height
    cols = 2 if len(stems) <= 12 else 4          # (cast, silhouette) pairs per row; more for big sheets
    cw = 2 * W + PAD; ch = H + LAB
    rows = math.ceil(len(stems) / cols)
    side = max(cols * cw + PAD * (cols + 1), rows * ch + PAD * (rows + 1))
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{side}" height="{side}" viewBox="0 0 {side} {side}">',
         f'<rect width="{side}" height="{side}" fill="#ffffff"/>']
    for i, st in enumerate(stems):
        x0 = PAD + (i % cols) * (cw + PAD); y0 = PAD + (i // cols) * (ch + PAD)
        o.append(f'<text x="{x0}" y="{y0 + 15}" font-family="Helvetica" font-size="14" fill="#2a2340">{st}</text>')
        for j, (sub, pre, grey) in enumerate([('art', 'cast_', False), ('sil', 'sil_', True)]):
            x = x0 + j * (W + PAD); y = y0 + LAB
            body = inner(os.path.join(theme, 'src', sub, pre + st + '.svg'))
            if grey:
                body = re.sub(r'fill="#[0-9a-fA-F]{6}"', 'fill="#9a93ad"', body)
            o.append(f'<rect x="{x}" y="{y}" width="{W}" height="{H}" fill="#f6f1e6"/>')
            o.append(f'<line x1="{x}" y1="{y + 205}" x2="{x + W}" y2="{y + 205}" stroke="#c9bfa8" stroke-width="1" stroke-dasharray="4 3"/>')
            o.append(f'<g transform="translate({x} {y}) scale(0.5)">{body}</g>')
    o.append('</svg>')
    open(out, 'w').write('\n'.join(o) + '\n')

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3:])
