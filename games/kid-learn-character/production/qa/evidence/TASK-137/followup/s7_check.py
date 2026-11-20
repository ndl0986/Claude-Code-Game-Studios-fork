"""Spec S-7 check: white silhouettes at about 64 px figure height, a 'before' row against an 'after' row.
Usage: python s7_check.py <before-theme-dir> <after-theme-dir> <out.svg> <stem> [<stem> ...]
Prints the sheet's side in px. Render it 1:1: qlmanage -t -s <side> -o <dir> <out.svg>."""
import re, sys

S = 0.26   # a ~250-unit figure lands at ~65 px

def main(before, after, out, stems):
    rows = [(before, 'before'), (after, 'after')]
    cw, ch = int(640 * S) + 10, int(440 * S) + 24
    side = max(cw * len(stems), ch * len(rows))
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{side}" height="{side}" viewBox="0 0 {side} {side}">',
         f'<rect width="{side}" height="{side}" fill="#2a2340"/>']
    for r, (d, lab) in enumerate(rows):
        for c, st in enumerate(stems):
            p = re.search(r'<path[^>]*/>', open(f'{d}/src/sil/sil_{st}.svg').read()).group(0).replace('#000000', '#ffffff')
            x, y = c * cw + 5, r * ch
            o.append(f'<text x="{x}" y="{y + 14}" font-family="Helvetica" font-size="11" fill="#c9bfa8">{lab} {st.split("_")[1]}</text>')
            o.append(f'<g transform="translate({x} {y + 20}) scale({S})">{p}</g>')
    o.append('</svg>')
    open(out, 'w').write('\n'.join(o) + '\n')
    print(side)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:])
