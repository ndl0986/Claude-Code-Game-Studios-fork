"""Dinosaurs cast as code: one parametric template per family (TASK-137+), drawn to
design/assets/specs/dinosaurs-assets.md. Colours are the spec's per-item values. Uses lib.py (the TASK-136 helpers:
per-part colour unions, outline = boundary of the part's body union, silhouette = body union grown by 3).

Usage: python figures.py <theme-dir> <keys>     e.g.  python figures.py content/themes/dinosaurs t,p,b,y
writes <theme-dir>/src/art/cast_dino_<key>_<name>_01.svg and <theme-dir>/src/sil/sil_….svg, and prints each figure's
node counts against the spec's caps (R-2: stage <= 23, parade <= 15, <= 5 parts; babies R-3)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import *  # noqa: F401,F403  (ell, circ, rrect, rpoly, tf, Part, write, smile, INK, CREAM, BONE, ROSE)
from shapely.geometry import Polygon

# ---- spec colours (body, far side, belly, accents) -------------------------------------------------------------
C = {
 'a': ('#5f8fd6', '#3673cc', '#acbfd9', {'club': '#3f68a8', 'studs': '#a9c6f2'}),
 'b': ('#8fbf6a', '#75ac4a', '#c3d7a3', {'spots': '#77a556'}),
 'c': ('#dd8d63', '#d46e39', '#ebbea0', {'frill': '#e0c08a', 'horns': BONE}),
 'd': ('#5fb3a8', '#48978d', '#acd1c2', {'spots': '#3f8a82'}),
 'e': ('#9fb8d8', '#7b9dc9', '#ccd3da', {'bill': BONE}),
 'g': ('#d8b06a', '#cd9b42', '#e8d0a3', {'feathers': '#efd39a', 'beak': '#e0c08a'}),
 'h': ('#7dc396', '#5ab37a', '#bad9b9', {'bump': '#6aa982'}),
 'i': ('#c99a52', '#b18137', '#e0c497', {'thumb': BONE}),
 'j': ('#7aa7d6', '#538dca', '#b9cbd9', {'fuzz': '#a9c6f2'}),
 'k': ('#c9a24f', '#af8836', '#e0c896', {'spikes': '#e0c08a'}),
 'l': ('#e7a0b8', '#dd779a', '#f0c8ca', {'crest': '#c94f6d'}),
 'm': ('#a98fd6', '#8c6ac8', '#d0bfd9', {'brow': '#8f75c0', 'baby': '#c39af0'}),
 'o': ('#e68ca8', '#dd6288', '#efbec2', {'crest': '#c94f6d', 'beak': '#e0c08a'}),
 'p': ('#5fb6b0', '#479b95', '#acd2c6', {'crest': '#e67151', 'wing': '#9fd9cf'}),
 'q': ('#dea363', '#d58a39', '#ebc9a0', {'crest': '#e67151', 'wing': '#c4864a'}),
 'r': ('#68b761', '#4f9d48', '#b0d39e', {'stripes': '#5a9256'}),
 's': ('#7cb85a', '#639c43', '#bad39b', {'plates': '#e79c56', 'plates_far': '#d77f30'}),
 't': ('#9a6fd1', '#7f48c5', '#c9afd6', {'ridge': '#c39af0'}),
 'u': ('#c76a4a', '#aa5234', '#e0ac93', {'feathers': '#eaa36c', 'crest': '#8a4630'}),
 'v': ('#b99a6a', '#a3814d', '#d8c4a3', {'speckles': '#9e7633'}),
 'w': ('#6ca9bb', '#4d92a7', '#b2cccc', {'plates': '#e0c08a'}),
 'x': ('#8f9fd8', '#697fcb', '#c3c7da', {'frill': '#b9c3ec', 'horns': BONE}),
 'y': ('#d97a5a', '#cf5931', '#e8b49b', {'feathers': '#eaa36c'}),
 'z': ('#abbb54', '#8f9d3f', '#d2d598', {'frill': '#d6dca8', 'horns': BONE}),
}
NEST, NEST_FAR, ROCK = '#a8743f', '#835a31', '#6e4a2c'
PASTELS = ['#7fcf8f', '#f2a37a', '#8fb4ea', '#d8b87a', '#c39af0', '#f29ab0', '#6fc9c0', '#e48a5a', '#a5d46a']

def eye(x, y, r):
    """Eye white + pupil (body layer, survives the parade) and the highlight (detail)."""
    return [(CREAM, [circ(x, y, r)]), (INK, [circ(x + r * 0.35, y + r * 0.08, r * 0.55)])], ('fill', CREAM, [circ(x + r * 0.5, y - r * 0.25, r * 0.22)])

def face(x, y, r, blush, mouth, extra=()):
    """Body groups and detail items for a head: eye, highlight, blush, smile (S-4)."""
    body, hl = eye(x, y, r)
    det = [hl, ('fill', ROSE, [ell(*blush)], 0.7), ('stroke', smile(*mouth), 4)] + list(extra)
    return body, det

# ================================================================================================ rex (T, Y)
def trex(k='t', feathered=False):
    B, F, BL, acc = C[k]
    chin = ell(466, 203, 38, 13).difference(circ(468, 163, 42))      # TASK-137: a chin under a smile line, not a slab
    teeth = ('fill', BONE, [circ(458, 199.5, 2.8), circ(468, 200.5, 2.8), circ(478, 199.5, 2.8)])
    jaw = Part('jaw', (398, 182), body=[(B, [chin])], detail=[teeth])
    hb, hd = face(468, 146, 15, (496, 172, 11, 7), (0, 0, 0, 0, 0, 0))
    hd = [d for d in hd if d[0] != 'stroke']                         # the chin's carved edge is the smile
    head = Part('head', (380, 176), body=[(B, [ell(448, 165, 74, 50, -6)])] + hb, detail=hd, front=[jaw])
    neckshapes = [ell(386, 214, 44, 62, 25)]
    backbumps = []
    if feathered:   # Y: a soft feather fringe on the outline (body colour), feather-tip colour only as detail
        neckshapes += [circ(352, 178, 11), circ(366, 165, 11)]
        backbumps = [circ(x, y, 12) for x, y in [(225, 225), (255, 210), (285, 203), (315, 205), (345, 214)]]
    neck = Part('neck', (360, 250), body=[(B, neckshapes)], front=[head])
    tail = Part('tail', (196, 270), body=[(B, [ell(158, 292, 125, 30, 8)] + ([circ(80, 282, 10), circ(110, 276, 10)] if feathered else []))])
    arm = [ell(398, 304, 18, 9, 35)] + ([circ(408, 312, 8), circ(396, 316, 8)] if feathered else [])
    marks = ('fill', acc['feathers' if feathered else 'ridge'],
             [ell(x, y, 8, 5, -20) for x, y in ([(250, 222), (300, 214), (340, 226)] if feathered else [])] or
             [circ(270, 222, 9), circ(300, 214, 9), circ(330, 218, 9)])
    root = Part('root', (320, 410), back=[tail, neck],
                body=[(F, [rrect(262, 320, 46, 90, 22)]), (B, [ell(305, 282, 108, 82, -8), rrect(318, 318, 56, 92, 26)] + arm + backbumps),
                      (BL, [ell(335, 305, 58, 46, -10)]), (BONE, [ell(366, 403, 16, 7)])],
                detail=[marks])
    return root

# ================================================================================================ flyer, in flight (P)
def tapejara():
    B, F, BL, acc = C['p']
    WF = '#7fbfb4'
    # TASK-137: the near wing is a curved, tapered membrane arching down from the shoulder, with a scalloped
    # (finger) trailing edge, not a flat board.
    def qb(p0, c, p1, n=24):
        return [((1 - t) ** 2 * p0[0] + 2 * t * (1 - t) * c[0] + t * t * p1[0], (1 - t) ** 2 * p0[1] + 2 * t * (1 - t) * c[1] + t * t * p1[1]) for t in [i / n for i in range(n + 1)]]
    lead = qb((338, 258), (230, 196), (96, 262))
    trail = qb((96, 262), (190, 300), (300, 300))
    wing = Polygon(lead + trail[1:]).difference(circ(150, 296, 15)).difference(circ(212, 306, 15)).buffer(-3, 24).buffer(3, 24)
    wf = Part('wing_far', (300, 250), body=[(WF, [ell(276, 182, 95, 26, 55)])])
    wn = Part('wing_near', (330, 255), body=[(acc['wing'], [wing])],
              detail=[('stroke', smile(300, 268, 230, 240, 160, 262), 3), ('stroke', smile(300, 276, 240, 262, 205, 282), 3)])
    hb, hd = face(462, 214, 9, (476, 230, 7, 4), (470, 236, 482, 240, 494, 233))
    root = Part('root', (320, 410), back=[wf], front=[wn],
                body=[(acc['crest'], [ell(430, 182, 30, 34, -20)]),
                      (B, [ell(330, 268, 72, 32, -8), ell(396, 246, 28, 14, -30), ell(455, 222, 38, 25, -10), ell(508, 234, 40, 9, 16), ell(288, 293, 18, 8, 20)])] + hb,
                detail=hd)
    return root

# ================================================================================================ sauropods (B, D)
def sauropod(k, neck_up):
    B, F, BL, acc = C[k]
    if neck_up:   # B: neck almost straight up, head near the top, front legs longer than back
        head_c, eyep = (444, 74), (452, 66)
        neckshape = ell(404, 172, 24, 104, 10)
        torso = ell(300, 300, 110, 60, -12)
        legs_far = [rrect(232, 330, 40, 80, 18), rrect(352, 300, 40, 110, 18)]
        legs = [rrect(254, 330, 44, 80, 20), rrect(374, 296, 44, 114, 20)]
        pivots = ((392, 250), (430, 92))
    else:
        head_c, eyep = (560, 198), (568, 188)
        neckshape = ell(458, 240, 95, 24, -20)
        torso = ell(300, 300, 115, 62, 0)
        legs_far = [rrect(230, 330, 40, 80, 18), rrect(350, 330, 40, 80, 18)]
        legs = [rrect(252, 330, 44, 80, 20), rrect(372, 330, 44, 80, 20)]
        pivots = ((400, 262), (540, 205))
    hb, hd = face(eyep[0], eyep[1], 10, (eyep[0] + 15, eyep[1] + 19, 8, 5), (eyep[0] + 3, eyep[1] + 22, eyep[0] + 16, eyep[1] + 27, eyep[0] + 27, eyep[1] + 18))
    head = Part('head', pivots[1], body=[(B, [ell(head_c[0], head_c[1], 38, 26, -5)])] + hb, detail=hd)
    neck = Part('neck', pivots[0], body=[(B, [neckshape])], front=[head])
    tail = Part('tail', (182, 316), body=[(B, [ell(140, 326, 125, 22, 10)])])
    toes = [ell(l.bounds[2] - 8, 404, 12, 6) for l in legs]
    return Part('root', (320, 410), back=[tail, neck],
                body=[(F, legs_far), (B, [torso] + legs), (BL, [ell(305, 326, 72, 26, -6 if neck_up else 0)]), (BONE, toes)],
                detail=[('fill', acc['spots'], [circ(258, 280, 10), circ(300, 268, 10), circ(342, 276, 10)])])

# ================================================================================================ raptors (R, J, U, V)
def raptor(k, variant):
    B, F, BL, acc = C[k]
    headrx, headx = {'long-snout': (64, 444), 'fuzz': (44, 428)}.get(variant, (52, 432))
    er = 13 if variant == 'fuzz' else 11
    hshapes = [ell(headx, 205, headrx, 30 if variant != 'long-snout' else 24, -8 if variant != 'long-snout' else -4)]
    hextra = []
    if variant == 'stripes-brows':
        hshapes.append(ell(434, 183, 22, 9, -10))                    # the brow ridge on the outline
    if variant == 'arm-feathers-crest':
        hextra = [(acc['crest'], [ell(420, 176, 16, 9, -30)])]        # a small head crest
    ex = {'long-snout': 432, 'fuzz': 430}.get(variant, 442)
    m = (ex + 4, 222, ex + 16, 228, ex + 28, 219) if variant == 'fuzz' else (ex + 10, 222, ex + 24, 228, ex + 37, 219)   # J's short head: keep the smile inside it
    hb, hd = face(ex, 196, er, (ex + 21, 215, 9, 6), m)
    head = Part('head', (408, 214), body=hextra + [(B, hshapes)] + hb, detail=hd)
    tailshapes = [ell(150, 282, 108, 22, -10)]
    torso = [ell(300, 280, 80, 52, -15), ell(378, 240, 28, 42, 30), rrect(300, 318, 40, 92, 18), ell(374, 284, 16, 7, 40)]
    extra_groups, marks = [], []
    if variant == 'fuzz':   # J: a scalloped fuzz edge along back and tail (outline trait)
        torso += [circ(x, y, 11) for x, y in [(250, 245), (275, 232), (300, 226), (325, 226)]]
        tailshapes += [circ(x, y, 9) for x, y in [(80, 288), (110, 280), (140, 272), (170, 266), (200, 262)]]
        marks = [('fill', acc['fuzz'], [ell(260, 248, 6, 4), ell(300, 232, 6, 4), ell(150, 276, 6, 4)])]
    elif variant == 'arm-feathers-crest':   # U: a feather fringe under the arm
        extra_groups = [(acc['feathers'], [rpoly([(360, 280), (392, 294), (356, 306)], 3), rpoly([(352, 290), (384, 306), (348, 314)], 3)])]
        marks = [('fill', acc['crest'], [ell(372, 296, 6, 3, 20), ell(364, 306, 6, 3, 20)])]
    elif variant == 'long-snout':
        marks = [('fill', acc['speckles'], [circ(262, 262, 5), circ(290, 252, 5), circ(318, 258, 5), circ(276, 282, 5)])]
    else:
        marks = [('fill', acc['stripes'], [ell(266, 252, 6, 15, -15), ell(291, 244, 6, 15, -15), ell(316, 240, 6, 15, -15)])]
    tail = Part('tail', (210, 300), body=[(B, tailshapes)])
    return Part('root', (320, 410), back=[tail], front=[head],
                body=[(F, [rrect(268, 320, 34, 90, 16)]), (B, torso)] + extra_groups + [(BL, [ell(318, 296, 44, 28, -15)]), (BONE, [ell(338, 404, 12, 6)])],
                detail=marks)

# ================================================================================================ ankylosaur (A)
def ankylo():
    B, F, BL, acc = C['a']
    hb, hd = face(466, 312, 10, (483, 333, 8, 5), (470, 342, 482, 347, 493, 340))
    head = Part('head', (470, 300), body=[(B, [ell(455, 322, 40, 30, 5)])] + hb, detail=hd)
    tail = Part('tail', (170, 330), body=[(B, [ell(135, 336, 85, 18, 8)]), (acc['club'], [ell(56, 346, 28, 20)])])
    return Part('root', (320, 410), back=[tail], front=[head],
                body=[(F, [rrect(215, 345, 40, 65, 18), rrect(355, 345, 40, 65, 18)]),
                      (B, [ell(300, 320, 125, 58), rrect(237, 345, 44, 65, 20), rrect(377, 345, 44, 65, 20)] + [circ(x, y, 14) for x, y in [(220, 274), (260, 264), (300, 260), (340, 264), (380, 274)]]),
                      (BL, [ell(300, 350, 85, 20)]), (BONE, [ell(277, 404, 12, 6), ell(417, 404, 12, 6)])],
                detail=[('fill', acc['studs'], [circ(250, 300, 7), circ(300, 294, 7), circ(350, 300, 7)])])

# ================================================================================================ flyer, standing (Q)
def quetzal():
    B, F, BL, acc = C['q']
    hb, hd = face(398, 86, 8, (410, 100, 6, 4), (404, 104, 414, 108, 424, 102))
    head = Part('head', (390, 96), body=[(acc['crest'], [ell(378, 66, 18, 12, -25)]), (B, [ell(395, 90, 26, 18, -8), ell(456, 112, 62, 8, 18)])] + hb, detail=hd)
    wing = Part('wing_near', (300, 300), body=[(acc['wing'], [ell(292, 272, 56, 28, -28)])],
                detail=[('stroke', smile(250, 280, 290, 268, 332, 262), 3)])
    return Part('root', (320, 410), front=[wing, head],
                body=[(F, [rrect(282, 300, 14, 110, 7)]), (B, [ell(300, 268, 58, 40, -22), ell(352, 172, 16, 82, 14), rrect(306, 300, 14, 110, 7)]),
                      (BL, [ell(312, 284, 30, 22, -22)]), (BONE, [ell(318, 405, 12, 5)])])

# ================================================================================================ duckbills (E, H, I, L, M)
def duckbill(k, trait):
    B, F, BL, acc = C[k]
    hb, hd = face(448, 182, 11, (468, 200, 9, 6), (456, 208, 470, 213, 484, 205))
    hgroups = []
    hshapes = [ell(440, 192, 50, 26, -12)]
    if trait == 'duck-bill':
        hgroups.append((acc['bill'], [ell(494, 204, 30, 12, -6)]))
    else:
        hshapes.append(ell(488, 204, 22, 11, -6))
    if trait == 'bump':
        hgroups.append((acc['bump'], [circ(470, 178, 13)]))
    if trait == 'hatchet-crest':
        hgroups.append((acc['crest'], [rpoly([(410, 176), (432, 110), (468, 108), (452, 178)], 8)]))
    if trait == 'brow-baby':
        hgroups.append((acc['brow'], [ell(446, 166, 18, 7, -12)]))
    head = Part('head', (430, 170), body=[(B, hshapes)] + hgroups + hb, detail=hd)
    tail = Part('tail', (190, 300), body=[(B, [ell(150, 300, 110, 24, -8)])])
    # the front leg comes down from under the chest (TASK-137 review: a leg in front of the body read as a post)
    rootb = [(F, [rrect(250, 330, 42, 80, 20), rrect(334, 320, 26, 90, 12)]),
             (B, [ell(300, 290, 95, 60, -8), ell(382, 240, 30, 46, 35), ell(272, 322, 40, 46), rrect(270, 330, 46, 80, 22), rrect(354, 300, 28, 110, 13)]),
             (BL, [ell(312, 310, 56, 32, -8)]), (BONE, [ell(312, 404, 13, 6), ell(378, 404, 10, 6)])]
    extra_det = []
    if trait == 'thumb-spike':   # I: a cream thumb spike pointing up from the front hand
        rootb[3] = (BONE, rootb[3][1] + [rpoly([(372, 336), (410, 300), (384, 346)], 4)])
    if trait == 'brow-baby':     # M: a tiny baby beside the front foot, part of the outline
        rootb.insert(3, (acc['baby'], [ell(470, 392, 20, 16), circ(486, 374, 14)]))
        extra_det = [('fill', INK, [circ(490, 372, 3)])]
    stripes = ('fill', F, [ell(268, 252, 5, 13, -10), ell(298, 244, 5, 13, -10)])
    return Part('root', (320, 410), back=[tail], front=[head], body=rootb, detail=[stripes] + extra_det)

# ================================================================================================ horned (C, X, Z)
def horned(k, trait):
    B, F, BL, acc = C[k]
    frill = {'tri-horn': ell(414, 282, 54, 60, -10), 'xeno-horns': ell(414, 286, 50, 56, -10), 'zuni-horns': ell(420, 296, 36, 40, -10)}[trait]
    fgroup = [frill]
    if trait == 'xeno-horns':   # X: a row of long spikes along the frill's top edge
        fgroup += [ell(390 + 22 * i, 232 - 6 * (i == 1) - 4 * (i == 2), 6, 22, -20 + 12 * i) for i in range(4)]
    horns = []
    if trait in ('tri-horn', 'zuni-horns'):
        horns += [ell(494, 268, 34, 6, -32), ell(486, 278, 30, 6, -24)]   # two long brow horns
    else:
        horns += [ell(486, 286, 14, 6, -35)]                               # short brow horns
    if trait == 'tri-horn':
        horns.append(ell(512, 314, 11, 6, -60))                            # short nose horn
    hb, hd = face(462, 310, 10, (482, 330, 8, 5), (470, 340, 482, 345, 494, 337))
    head = Part('head', (430, 300), body=[(acc['frill'], fgroup), (B, [ell(458, 322, 52, 38, 8)]), (acc['horns'], horns)] + hb, detail=hd)
    tail = Part('tail', (190, 320), body=[(B, [ell(160, 330, 82, 22, 10)])])
    return Part('root', (320, 410), back=[tail], front=[head],
                body=[(F, [rrect(220, 345, 40, 65, 18), rrect(350, 345, 40, 65, 18)]),
                      (B, [ell(290, 320, 115, 62), rrect(242, 345, 44, 65, 20), rrect(372, 345, 44, 65, 20)]),
                      (BL, [ell(292, 348, 80, 22)]), (BONE, [ell(282, 404, 12, 6), ell(412, 404, 12, 6)])],
                detail=[('fill', acc['horns'] if trait != 'zuni-horns' else BL, [circ(408, 256, 5), circ(426, 250, 5)])])

# ================================================================================================ plated (S, K, W)
def plated(k, trait):
    B, F, BL, acc = C[k]
    groups = []
    if trait == 'plates':      # S: two staggered rows of tall rounded plates; four tail spikes
        far = [rpoly([(x - 18, 270), (x, 210 - (24 if 1 <= i <= 3 else 0)), (x + 18, 270)], 8) for i, x in enumerate([214, 262, 310, 358])]
        near = [rpoly([(x - 20, 276), (x, 220 - (26 if 1 <= i <= 3 else 0)), (x + 20, 276)], 9) for i, x in enumerate([190, 238, 286, 334, 382])]
        groups = [(acc['plates_far'], far)]
        nearg = (acc['plates'], near)
        tailx = [(acc['plates'], [ell(78, 306, 18, 6, -40), ell(94, 300, 18, 6, -60), ell(70, 334, 18, 6, 30), ell(88, 340, 18, 6, 50)])]
    elif trait == 'spikes':    # K: short shoulder plates turning into tall rounded spikes over hips and tail
        nearg = (acc['spikes'], [rpoly([(x - 14, 274), (x, 248), (x + 14, 274)], 5) for x in (350, 380)] +
                 [ell(x, 240, 7, 34, r) for x, r in [(250, -12), (282, -4), (316, 4)]])
        tailx = [(acc['spikes'], [ell(120, 296, 6, 26, -30), ell(90, 304, 6, 22, -40)])]
    else:                      # W: long, low, rounded plates, wider than tall
        nearg = (acc['plates'], [ell(x, 262, 26, 14, 0) for x in (210, 258, 306, 354)])
        tailx = []
    hb, hd = face(466, 340, 9, (480, 356, 7, 4), (470, 362, 480, 366, 490, 360))
    head = Part('head', (470, 330), body=[(B, [ell(458, 350, 34, 24, 10)])] + hb, detail=hd)
    tail = Part('tail', (180, 320), body=[(B, [ell(140, 324, 100, 20, 12)])] + tailx)
    return Part('root', (320, 410), back=[tail], front=[head],
                body=groups + [(F, [rrect(222, 345, 38, 65, 17), rrect(352, 345, 38, 65, 17)]),
                               (B, [ell(300, 322, 122, 56), rrect(244, 345, 42, 65, 19), rrect(374, 345, 42, 65, 19)]), nearg,
                               (BL, [ell(300, 350, 84, 20)]), (BONE, [ell(282, 404, 12, 6), ell(412, 404, 12, 6)])],
                detail=[('fill', F, [ell(270, 318, 12, 5), ell(330, 318, 12, 5)])])

# ================================================================================================ ornithomimids (G, O)
def ornitho(k, trait):
    B, F, BL, acc = C[k]
    if trait == 'gallimimus':   # G: long neck and legs, a small beaked head, a fluffy tail
        hb, hd = face(432, 102, 8, (442, 116, 6, 4), (436, 120, 446, 124, 455, 118))
        head = Part('head', (430, 150), body=[(B, [ell(430, 108, 22, 15, -8)]), (acc['beak'], [ell(458, 115, 20, 6, 10)])] + hb, detail=hd)
        tail = Part('tail', (200, 280), body=[(B, [ell(205, 240, 70, 18, -15)]), (acc['feathers'], [circ(x, y, 12) for x, y in [(140, 255), (160, 244), (150, 266)]])])
        body = [(F, [rrect(282, 260, 14, 150, 7)]), (B, [ell(300, 248, 70, 42, -10), ell(376, 172, 16, 72, 25), rrect(310, 262, 16, 148, 8)]), (BL, [ell(310, 262, 40, 22, -10)]), (BONE, [ell(324, 405, 12, 5)])]
    else:                       # O: a tall rounded head crest and a short parrot beak; arm feathers
        hb, hd = face(436, 186, 10, (450, 202, 7, 4), (440, 208, 452, 212, 462, 205))
        head = Part('head', (430, 150), body=[(acc['crest'], [ell(424, 150, 18, 30, -10)]), (B, [ell(430, 190, 30, 22, -8)]), (acc['beak'], [rpoly([(452, 186), (476, 196), (452, 210)], 4)])] + hb, detail=hd)
        tail = Part('tail', (200, 280), body=[(B, [ell(200, 262, 72, 18, -12)])])
        body = [(F, [rrect(280, 292, 16, 118, 8)]), (B, [ell(300, 270, 70, 48, -15), ell(380, 222, 18, 36, 20), rrect(308, 292, 18, 118, 9), ell(360, 284, 20, 9, 35)]), (BL, [ell(312, 286, 40, 26, -15)]), (BONE, [ell(324, 405, 12, 5)])]
    marks = ('fill', acc['feathers'] if trait == 'gallimimus' else acc['crest'], [ell(364, 292, 6, 3, 30), ell(352, 298, 6, 3, 30)])
    return Part('root', (320, 410), back=[tail], front=[head], body=body, detail=[marks])

# ================================================================================================ objects (F, N, 0)
def fossil():
    ring = circ(320, 320, 64).difference(circ(320, 320, 38)).difference(Polygon([(320, 320), (420, 320), (420, 420), (320, 420)]))
    bone = ring.union(circ(384, 320, 17)).union(circ(320, 384, 17))
    return Part('root', (320, 410), body=[(ROCK, [rrect(110, 226, 420, 184, 64)]), (BONE, [bone])],
                detail=[('fill', '#8a6440', [circ(170, 280, 6), circ(470, 372, 6)])])

def nest(with_egg):
    bowl = ell(320, 372, 202, 40).union(rrect(118, 330, 404, 44, 22))
    det = [('fill', NEST_FAR, [ell(320, 336, 170, 12)])] + [('stroke', d, 3) for d in
           ('M150 352Q320 376 490 352', 'M170 376Q320 396 470 376', 'M140 336Q320 352 500 336')]
    root = Part('root', (320, 410), body=[(NEST, [bowl])], detail=det)
    if with_egg:   # N: one cream egg with a little peeking eye; the egg is its own part (egg wobble)
        egg = Part('egg', (320, 352), body=[(BONE, [ell(320, 286, 50, 62)])],
                   detail=[('fill', INK, [circ(334, 262, 6)]), ('fill', CREAM, [circ(336, 260, 2)]), ('stroke', 'M286 296L300 286L312 298L326 286L340 298L354 288', 3)])
        root.back.append(egg)
    return root

# ================================================================================================ babies (1–9)
def babies(n):
    front = min(n, 5); back = n - front; slots = []
    for j in range(back): slots.append((320 + 104 * (j - (back - 1) / 2), 292, 0.95, PASTELS[(j + 5) % 9]))
    for i in range(front): slots.append((320 + 104 * (i - (front - 1) / 2), 410, 1.05, PASTELS[i % 9]))
    WORD = ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine']
    kids = []
    for k, (fx, fy, s, col) in enumerate(slots):
        T = lambda g: tf(g, s, fx, fy)
        body = [T(ell(0, -30, 36, 30)), T(circ(10, -62, 28)), T(ell(-36, -22, 12, 7, -20)), T(ell(-14, -6, 12, 6)), T(ell(16, -6, 12, 6))]
        kids.append(Part(f'baby_{WORD[k]}', (fx, fy), body=[(col, body), (CREAM, [T(circ(20, -66, 9))]), (INK, [T(circ(23, -65, 5))])],
                         detail=[('fill', CREAM, [T(circ(25, -68, 2))]), ('stroke', smile(fx + 22 * s, fy - 50 * s, fx + 30 * s, fy - 45 * s, fx + 37 * s, fy - 52 * s), 3.5 * s)]))
    return Part('root', (320, 410), front=kids)

# ================================================================================================ the set
FIG = {
 't': ('trex', 'T-Rex', lambda: trex('t')), 'd': ('diplodocus', 'Diplodocus', lambda: sauropod('d', False)),
 'r': ('raptor', 'Raptor', lambda: raptor('r', 'stripes-brows')), 'p': ('tapejara', 'Tapejara', tapejara),
 'a': ('ankylosaurus', 'Ankylosaurus', ankylo), '9': ('babies', 'nine baby dinosaurs', lambda: babies(9)),
 'b': ('brachiosaurus', 'Brachiosaurus', lambda: sauropod('b', True)), 'y': ('yutyrannus', 'Yutyrannus', lambda: trex('y', True)),
 'j': ('juravenator', 'Juravenator', lambda: raptor('j', 'fuzz')), 'u': ('utahraptor', 'Utahraptor', lambda: raptor('u', 'arm-feathers-crest')),
 'v': ('velociraptor', 'Velociraptor', lambda: raptor('v', 'long-snout')), 'q': ('quetzalcoatlus', 'Quetzalcoatlus', quetzal),
 'e': ('edmontosaurus', 'Edmontosaurus', lambda: duckbill('e', 'duck-bill')), 'h': ('hadrosaurus', 'Hadrosaurus', lambda: duckbill('h', 'bump')),
 'i': ('iguanodon', 'Iguanodon', lambda: duckbill('i', 'thumb-spike')), 'l': ('lambeosaurus', 'Lambeosaurus', lambda: duckbill('l', 'hatchet-crest')),
 'm': ('maiasaura', 'Maiasaura', lambda: duckbill('m', 'brow-baby')),
 'c': ('triceratops', 'Triceratops', lambda: horned('c', 'tri-horn')), 'x': ('xenoceratops', 'Xenoceratops', lambda: horned('x', 'xeno-horns')),
 'z': ('zuniceratops', 'Zuniceratops', lambda: horned('z', 'zuni-horns')),
 's': ('stegosaurus', 'Stegosaurus', lambda: plated('s', 'plates')), 'k': ('kentrosaurus', 'Kentrosaurus', lambda: plated('k', 'spikes')),
 'w': ('wuerhosaurus', 'Wuerhosaurus', lambda: plated('w', 'low-plates')),
 'g': ('gallimimus', 'Gallimimus', lambda: ornitho('g', 'gallimimus')), 'o': ('oviraptor', 'Oviraptor', lambda: ornitho('o', 'oviraptor')),
 'f': ('fossil', 'Fossil', fossil), 'n': ('nest', 'Nest', lambda: nest(True)), '0': ('nest', 'an empty nest', lambda: nest(False)),
}
WORDS = ['', 'one baby dinosaur', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight']
for _n in range(1, 9):
    FIG[str(_n)] = ('babies', WORDS[_n] if _n == 1 else f'{WORDS[_n]} baby dinosaurs', (lambda m: (lambda: babies(m)))(_n))

if __name__ == '__main__':
    out, keys = sys.argv[1], sys.argv[2]
    os.makedirs(os.path.join(out, 'src/art'), exist_ok=True); os.makedirs(os.path.join(out, 'src/sil'), exist_ok=True)
    ok = True
    for k in keys.split(','):
        name, title, fn = FIG[k]
        isbaby = name == 'babies'
        # R-3: the babies are one fixed size across every number so the count reads (art bible §5), so S-1's
        # 60 % fill is not checked for them; their node caps are per baby (6 stage / 4 parade).
        caps = (6 * 9, 4 * 9, None) if isbaby else (23, 15, 5)
        ok &= write(f'dino_{k}_{name}_01', f'Letterlings Dinosaurs: {title}', fn(), caps, out, skipfill=isbaby)
    print('ALL OK' if ok else 'PROBLEM')
