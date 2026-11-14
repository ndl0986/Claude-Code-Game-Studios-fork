# Technical Preferences

<!-- project.yaml at the repo root is the machine-readable source of truth for
     engine, specialists, naming, performance, platform, and testing.framework.
     This file is the human-readable LEGACY FALLBACK: agents and skills resolve
     each key from project.yaml first and fall back here only when the
     project.yaml key is absent. /setup-engine dual-writes both.
     Forbidden patterns and allowed libraries are NOT migrated — they live only
     in this file. Populated by /setup-engine; updated as decisions are made. -->

## Engine & Language

- **Engine**: Godot 4.7.2
- **Language**: GDScript
- **Rendering**: Compatibility (GL Compatibility). Chosen over the 2D non-web default Forward+ for the low-end Android performance floor (TASK-002 plan, approved by Luan 2026-11-14)
- **Physics**: Godot Physics 2D

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Mobile: Android + iOS phones (tablets later)
- **Input Methods**: Touch
- **Primary Input**: Touch
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: Landscape, either way up (sensor landscape). Touch-first for 6–10 year olds: big on-screen buttons (move, attack, defend), multi-touch, safe-area insets. No hover-only interactions. VI default with a runtime EN switch; fonts need full Vietnamese diacritics. Performance floor: a low-end Android phone. Fully offline; no data collection (design/gdd/game-concept.md)

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Variables**: snake_case (e.g., `move_speed`)
- **Signals/Events**: snake_case past tense (e.g., `health_changed`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`)
- **Scenes/Prefabs**: snake_case matching the file (e.g., `player_controller.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60 fps; 30 fps is the acceptable floor on a low-end Android phone
- **Frame Budget**: 16.6 ms at 60 fps (33.3 ms at the 30 fps floor)
- **Draw Calls**: [TO BE CONFIGURED — set after the first build on a real low-end phone]
- **Memory Ceiling**: [TO BE CONFIGURED — set after the first build on a real low-end phone]

## Testing

- **Framework**: gdUnit4 (`/test-setup` installs it later, pinned to 6.2.2)
- **Minimum Coverage**: [TO BE CONFIGURED]
- **Required Tests**: Balance formulas, gameplay systems, networking (if applicable)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist for material design and shader code. Invoke GDExtension specialist only when native extensions are involved.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
