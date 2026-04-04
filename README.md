# 🍓 Fruit Game

**Silnik:** Godot 4.3 stable  
**Wersja:** v3 PRODUKCYJNA  
**Data:** 2026-04-04  

Wieloosobowa gra akcji PvP — owocowe postacie walczą na losowych mapach, gniją z upływem czasu i ewoluują dzięki systemowi modyfikatorów.

## Postacie (GDD v1.0)

| Postać | HP | SPD | DMG | Fire Rate | Skill |
|---|---|---|---|---|---|
| 🍓 Strawberry | 100 | 200 | 20 | 0.5s | Dash |
| 🍇 Grape | 70 | 220 | 10 | 0.2s | Grad winogron |
| 🍍 Pineapple | 150 | 160 | 35 | 0.8s | Kolce |
| 🍊 Orange | 90 | 240 | 15 | 0.35s | Fokus |

## Architektura

```
scripts/
  characters/   Strawberry, Grape, Pineapple, Orange
  core/         GameManager, RotManager, StateMachine
  weapons/      BulletPool, Bullet
  modifiers/    GameModifier (6 modów)
  map/          MapGenerator (seed + mutatory)
scenes/characters/   .tscn z GPUParticles2D
assets/sprites/characters/   PNG 64x64 (5 animacji)
```

## Roadmap

- [x] v3 — BulletPool + StateMachine + GPUParticles2D  
- [ ] v4 — WebSocket multiplayer, HUD, testy GUT  
- [ ] v5 — BalanceSimulator AI-vs-AI, release build  
