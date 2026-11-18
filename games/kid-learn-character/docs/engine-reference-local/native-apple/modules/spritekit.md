# SpriteKit (the stage)

Rule: PROVEN (TASK-033), SOURCED (Apple URL) or NOT SOURCEABLE (see `../VERSION.md`).

| Claim | Status |
|---|---|
| A SpriteKit scene in a SwiftUI shell draws 240 additive soft-dot `SKSpriteNode` specks from MorphCore positions; frame p99 26.73 ms on a real Mac (one miss case), 17.07 ms on the iPad Simulator | **PROVEN (TASK-033)**, `evidence/TASK-033/runs/` |
| `SKShapeNode` with `glowWidth` draws a glyph path and a flat silhouette | **PROVEN (TASK-033)** (one shape each, `Spike/MorphScene.swift`) |
| Many `SKShapeNode`s for layered, per-part creature art at 60 fps on an iPad | **NOT SOURCEABLE**: unmeasured — the reason for ADR-0009's device spike (Cast Rendering R11) |
| SpriteKit has no SVG renderer | **NOT SOURCEABLE** as an Apple statement; the spike found none and the art bible §8 records it |
| A clamped additive cap (Cast Rendering F4) | **NOT SOURCEABLE**: mechanism left to ADR-0009 |
