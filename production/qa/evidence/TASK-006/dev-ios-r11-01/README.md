# iOS-R11-01: the skip warning's text clear of the medal drum (developer check, not QC evidence)

QC r11 (190fbe0): on the VI skip warning the drum ring and the first text line had a 0 px gap (the circumflex of
"nhận" over the ring's last rows). Fix: the warning text is 8 world px lower (y 300 → 308). The drum's top already sits
on the card's edge, so moving it up wasn't an option. Two lines at 37 px now end at ≈ 358, still above the buttons at
390.

| Shot | Check |
|---|---|
| skip-warning-vi-after | The ring clears the circumflex on "nhận" by ≈ 10 screen px (it touched in r11) |
| skip-warning-en-after | EN: the gap grows by the same amount; the buttons stay clear below the text |

R11 (d) and the r11 screen pass both pass on this tree (dev Simulator FB836E51). Not frozen: it rides the next round.
