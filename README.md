# 🍓 Fruit Game

**2D PvP arena shooter** w Godot 4.3 — steruj owocowym wojownikiem i strzelaj sokiem we wrogów.

## Postacie

| Postać | HP | SPD | Fire Rate | DMG | Styl |
|--------|-----|-----|-----------|-----|------|
| 🍇 Grape | 70 | 220 | 0.2s | 10 | Szybkostrzelny snajper |
| 🍊 Orange | 90 | 240 | 0.35s | 15 | Zrównoważony |
| 🍓 Strawberry | 100 | 200 | 0.5s | 20 | Klasyczny |
| 🍍 Pineapple | 150 | 160 | 0.8s | 35 | Powolny tank |

## Mechaniki

- **Gnicie** — każda postać gnije z czasem (rot_progress), przyspieszając przy końcu
- **Object Pool** — 50 pocisków w puli, zero skoków GC
- **Modyfikatory pocisków** — BounceShots, StickyShots, ExplosiveShots
- **Anti-snowball** — liderzy dostają utrudnienia w kolejnych rundach
- **State Machine** — IDLE / MOVE / SHOOT / HIT / DEAD

## Sterowanie

| Akcja | Klawisz |
|-------|---------|
| Ruch | WASD |
| Strzał | LPM (w kierunku kursora) |

## Struktura projektu

```
Fruit-Game/
├── scenes/
│   ├── characters/       # Grape, Orange, Pineapple, Strawberry
│   ├── weapons/          # Bullet
│   └── main_game.tscn    # Główna scena
├── scripts/
│   ├── characters/       # Logika postaci
│   ├── core/             # GameManager, StateMachine, RotManager
│   ├── map/              # MapGenerator
│   ├── modifiers/        # GameModifier
│   └── weapons/          # Bullet, BulletPool
├── assets/
│   ├── sprites/          # Sprite sheety postaci (TODO)
│   └── sounds/           # Dźwięki (TODO)
└── docs/
    └── fruit-game-gdd.html  # Game Design Document
```

## Status

- [x] Logika postaci (ruch, strzelanie, gnicie, cząsteczki)
- [x] Object Pool pocisków
- [x] State Machine
- [x] GameManager (rundy, scoring, anti-snowball)
- [x] HUD (HP, wynik, runda)
- [ ] Sprite sheety / animacje
- [ ] Mapa z kolizjami
- [ ] Multiplayer (WebSocket)

## Uruchomienie

1. Otwórz projekt w **Godot 4.3**
2. Poczekaj na import zasobów
3. F5 — uruchom z `scenes/main_game.tscn`

Gracz 1 (Grape): WASD + LPM
