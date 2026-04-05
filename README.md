# Fruit Game

**2D PvP arena shooter** w Godot 4.3 — do 4 graczy na jednym ekranie.

## Postacie

| Postać | HP | SPD | Fire Rate | DMG | Styl |
|--------|-----|-----|-----------|-----|------|
| Grape | 70 | 220 | 0.2s | 10 | Szybkostrzelny snajper |
| Orange | 90 | 240 | 0.35s | 15 | Zrównoważony |
| Strawberry | 100 | 200 | 0.5s | 20 | Klasyczny |
| Pineapple | 150 | 160 | 0.8s | 35 | Powolny tank |

## Mechaniki

- **Modyfikatory pocisków** — BounceShots, StickyShots, ExplosiveShots, PoisonTrail
- **System rund** — wybór postaci, modyfikatory między rundami, ranking
- **Anti-snowball** — liderzy dostają utrudnienia

## Sterowanie

| Gracz | Ruch | Skok | Strzał |
|-------|------|------|--------|
| P1 | A/D | Space | LPM |
| P2 | Strzałki L/R | Strzałka Up | PPM |
| P3 | J/L | I | Środkowy myszy |
| P4 | Numpad 4/6 | Numpad 8 | Przycisk myszy 9 |

## Struktura projektu

```
Fruit-Game/
├── scenes/
│   ├── characters/    # Grape, Orange, Pineapple, Strawberry (.tscn)
│   ├── bullets/       # Pociski (.tscn)
│   ├── effects/       # Eksplozje, strefy trucizny (.tscn)
│   ├── ui/            # Wybór postaci, modyfikatory, wyniki (.tscn)
│   ├── main_game.tscn
│   └── global.tscn
├── scripts/
│   ├── characters/    # Logika postaci (.gd)
│   ├── bullets/       # Logika pocisków (.gd)
│   ├── core/          # Global, MainGame (.gd)
│   ├── effects/       # Eksplozje, trucizna (.gd)
│   └── ui/            # UI flow (.gd)
├── assets/sprites/
└── docs/
```

## Uruchomienie

1. Otwórz projekt w **Godot 4.3**
2. F5 — gra startuje od ekranu wyboru postaci
