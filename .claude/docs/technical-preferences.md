# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6 (stable)
- **Language**: GDScript (primary)
- **Rendering**: Compatibility (OpenGL) — 2D pixel art, Steam Deck optimized
- **Physics**: Godot Physics 2D (default; Jolt NOT enabled — 2D project)
- **Navigation**: NavigationAgent2D + NavigationServer2D (4.5+ independent from 3D)

## Naming Conventions

- **Classes / Node scripts**: PascalCase (e.g., `AnimalTower`, `EnemyAI`, `HeroSkillSystem`)
- **Variables / functions**: snake_case (e.g., `base_atk`, `apply_effect()`, `get_next_path_position()`)
- **Signals**: snake_case, verb_noun (e.g., `enemy_died`, `tower_placed`, `wave_started`) — **never prefix with underscore** (hidden in 4.6)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_WAVE`, `BASE_HP_DEFAULT`)
- **Files / Scenes**: snake_case (e.g., `animal_tower.gd`, `enemy_raptor.tscn`)
- **Autoloads (Singletons)**: PascalCase (e.g., `GameState`, `AudioSystem`, `VFXSystem`)

## Performance Budgets

- **Target Framerate**: 60 fps (Steam Deck minimum)
- **Frame Budget**: 16.6ms
- **Draw Calls**: < 100 per frame (2D batching via Compatibility renderer)
- **Memory Ceiling**: 512MB RAM (matches Steam Deck minimum)
- **Max simultaneous SFX**: 8 (see audio.md)
- **VFX particle cap**: 10 death effects per frame (see vfx.md)

## Testing

- **Framework**: GUT (Godot Unit Testing) addon
- **Minimum Coverage**: All balance formulas, damage calculation, status effect stacking
- **Required Tests**: damage-calculation.md formulas, save/load round-trip, status effect apply/remove

## Forbidden Patterns

- `NavigationServer3D` in any 2D context — use `NavigationServer2D` only
- Signals prefixed with `_` (hidden in Godot 4.6 autocomplete)
- `duplicate()` without explicit `true` arg where deep copy is needed (4.5 semantics change)
- Per-cell runtime collision on TileMapLayer (use tile data editor instead — 4.5 chunk collision)
- Direct3D 12 or Vulkan renderer (use Compatibility/OpenGL for pixel art + Steam Deck)
- Magic numbers for collision layers — use named constants from `collision_layers.gd`

## Allowed Libraries / Addons

- **GUT** (Godot Unit Testing) — test framework
- No other addons approved yet — add via architecture decision

## Collision Layer Map

```
Layer 1: HERO
Layer 2: ENEMIES
Layer 3: TOWERS
Layer 4: PROJECTILES
Layer 5: PATH_DETECTION
```

## Autoload / Singleton Map

```
GameState     — wave, gold, base_hp, game_state enum
AudioSystem   — play_sfx(), play_bgm(), volume settings
VFXSystem     — play(effect_id, position)
Localization  — L(key), load(language_code)
SaveLoad      — save(), load(), settings
```

## Architecture Decisions Log

- 2026-03-27: Godot 4.6 + Compatibility renderer selected (2D pixel art, Steam Deck target)
- 2026-03-27: GDScript primary language (solo dev, rapid iteration)
- 2026-03-27: NavigationAgent2D for all pathfinding (4.5+ independent 2D nav)
