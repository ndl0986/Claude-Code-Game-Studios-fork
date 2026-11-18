# ADR-0009 H-2 overlap check (headless) at 6e455bfc

- `output.txt`: `prototypes/DeviceSpike/tools/overlap-check.swift` (SpriteKit rendered offscreen by `SKRenderer` into a Metal texture; no view, no window; macOS GPU). A white X (two crossing strokes in ONE path) over black, 12 pt wide.
- Result: one `SKShapeNode` blends its own overlap **twice** (crossing 0.961 vs arm 0.800), whether the alpha is on the stroke colour or on the node; an `SKEffectNode` with `shouldRasterize` at alpha 0.8 blends **once** (0.800 / 0.800). So the merged outline needs the effect node for the art bible's group look (ADR-0009 D3 fallback).
- The in-app "Overlap check" (DeviceSpike Render) repeats it on the iPad GPU in the device session.
