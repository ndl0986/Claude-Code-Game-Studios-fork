# Interaction Pattern Library

> **Status**: In Review · Task: TASK-021 · Author: game-art-content
> **Template**: Interaction Pattern Library
> **Platform Target**: Android + iOS phones, landscape, touch only.
> The behaviour rules live in `design/gdd/input-and-touch.md`. This library names the shared
> patterns so every screen spec cites one place.

| Pattern | When to use | Behaviour | Source |
|---|---|---|---|
| **Play pad** | Move, attack, defend, flag during play | Fires on press; the pointer owns the pad until up or cancel (identity, not position); the ◀↔▶ slide; drift forgiven; no tap tone | Input Rules 5–10 |
| **Menu button** | Start, Tiếp, Skip, pause items, results, unlock, map pins | Fires on release inside; one tone; ≥ 72 pt | Input Rule 8; Audio Rule 6 |
| **Advance button** (Tiếp, ask) | Any button that moves the story or quiz on | A menu button plus a press-time debounce of 0.25 s, also across a screen change | Input Rule 12 (B1) |
| **Choice card** | Quiz answers | A menu button; greyed after a wrong pick and never re-pickable | Quiz Rule 4 |
| **Locked state** | Shake, warning opening, reveal, transitions | Taps are dropped, never queued | Input Rule 13 (B4) |
| **Modal card** | Skip warning, pause menu | Dims the screen it came from; the default action is the biggest, right or top; no red | Mission flow Rule 15; pause.md |
| **Hint hand / pulse / arrow** | Teaching and stuck help | Wordless, ≤ 3 Hz, never takes touches | Hints GDD |
| **Tap vs drag** | Map, timeline column | A move over 10 pt is a drag and never activates | Input Rule 16 |
| **Clear-all** | Pointer cancel, focus loss, pause, background, audio route change or interruption, **only** | Every pad released, every press cancelled. A screen or beat change does **not** clear held pads; it only cancels a pressed **menu** button | Input Rule 11; Input edge cases |

**Animation standards:** a press squash of 4% in the next frame; a page slide of 0.1–0.15 s;
pulses ≤ 3 Hz; reveals ≤ 3 s.
**Sound standards:** one tone per menu press; play pads are silent; right is louder than wrong
(Audio Rules 3, 6).
