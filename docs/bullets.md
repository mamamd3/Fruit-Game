# System pocisków (Bullets)

Dokumentacja systemu pocisków Fruit Game.

---

## Pliki

| Plik | Opis |
|------|------|
| `scripts/bullets/bullet.gd` | Główna logika każdego pocisku (ruch, kolizje, obrażenia) |
| `scripts/bullets/pociski.gd` | Katalog scen pocisków (stały słownik + opis architektury) |
| `scripts/core/main_game.gd` | Spawnie pociski — `_do_spawn_bullet()` |
| `scripts/core/Modifier_System.gd` | Modyfikatory pocisków (triggery `on_shoot`, `on_hit`, `on_bounce`) |
| `scenes/bullets/` | Sceny (`.tscn`) dla każdej postaci |

---

## Typy pocisków

Każda postać ma swoją scenę pocisku z unikalną grafiką proceduralną.

| Postać | Scena | Wygląd |
|--------|-------|--------|
| Strawberry | `strawberry_bullet.tscn` | Żółto-zielona pestka + czerwona kropla soku |
| Grape | `grape_bullet.tscn` | Fioletowa kulka z odblaskiem soku |
| Orange | `orange_bullet.tscn` | Pomarańczowy plasterek z pestką |
| Pineapple | `pineapple_bullet.tscn` | Żółty klocek miąższu z zielonym kolcem |

---

## Parametry postaci

| Postać | HP | Prędkość | Fire Rate | DMG |
|--------|-----|----------|-----------|-----|
| Strawberry | 100 | 80 | 0.8 s | 25 |
| Grape | 80 | 100 | 0.2 s | 15 |
| Orange | 50 | 90 | 2.5/s | 50 |
| Pineapple | 200 | 150 | 0.5 s | 30 |

---

## Cykl życia pocisku

```
main_game._do_spawn_bullet(pos, dir, player_prefix)
    │
    ├─ instantiate() sceny pocisku
    ├─ bullet.setup(pos, dir, shooter_name)    ← ustawia prędkość, odbicia, flagi
    │       └─ ModifierSystem.get_extra_bullet_dirs()  ← shotgun, double_shot
    │
    ├─ _physics_process(delta)
    │       ├─ spinning: ruch sinusoidalny
    │       ├─ magnetic_seed / magnetic_bounce: homing
    │       └─ grawitacja + przemieszczanie
    │
    └─ _on_body_entered(body)
            ├─ Terrain → odbicie lub queue_free
            └─ Gracz   → oblicz DMG → receive_damage() → ModifierSystem.apply_on_hit()
                                                        → queue_free
```

---

## Zmienne bullet.gd

| Zmienna | Typ | Opis |
|---------|-----|------|
| `velocity` | `Vector2` | Bieżąca prędkość (px/s) |
| `shooter_name` | `String` | Nazwa postaci, która wystrzeliła |
| `bullet_speed` | `float` | Bazowa prędkość (180 px/s, +25% przy `sniper_seed`) |
| `GRAVITY` | `float` | Stała grawitacja 75.0 |
| `bounces_left` | `int` | Pozostałe odbicia (domyślnie 1) |
| `has_bounced` | `bool` | Czy już się odbiło |
| `bonus_dmg` | `float` | Dodatkowe DMG (`destroying_bounce`: +5/odbicie) |
| `bounce_dmg_mult` | `float` | Mnożnik DMG po odbiciu (`rage_bounce`: ×1.3) |
| `is_magnetic` | `bool` | Homing aktywny od startu (`magnetic_seed`) |
| `magnetic_after_bounce` | `bool` | Homing przez 2 s po odbiciu (`magnetic_bounce`) |
| `ripe_shot_bonus` | `bool` | Co 3. strzał +30% DMG (`ripe_shot`) |
| `streak_bonus` | `bool` | Po 3 trafieniach z rzędu +30% DMG (`fruit_streak`) |

---

## Modyfikatory pocisków

### Triggery `on_shoot` — wpływają na strzał w momencie wystrzelenia

| ID | Nazwa | Opis |
|----|-------|------|
| `double_shot` | Podwójny strzał | 1 dodatkowy pocisk lekko obok |
| `shotgun` | Shotgun pestek | 4 dodatkowe pociski w wachlarzu ±15°/±30° |
| `sniper_seed` | Pestka snajpera | Prędkość pocisku +25% |
| `extra_bounce` | Dodatkowe odbicie | +1 odbicie |
| `bouncy` | Odbijające pociski | 4 odbicia |
| `spinning` | Wirujące pociski | Ruch sinusoidalny |
| `magnetic_seed` | Magnetyczna pestka | Homing do najbliższego wroga |
| `ripe_shot` | Dojrzały strzał | Co 3. pocisk +30% DMG |

### Triggery `on_hit` — po trafieniu w gracza

| ID | Nazwa | Opis |
|----|-------|------|
| `fermentation` | Fermentacja | Zatruwa trafionego na 3 s |
| `radioactive_seed` | Radioaktywna pestka | Toksyczna plama w miejscu trafienia |
| `rot_shot` | Strzał zgnilizny | Trafiony gnije o 3 s szybciej |
| `lifesteal` | Kradzież HP | Odzysk 30% zadanych obrażeń |
| `juicy_core` | Soczyste wnętrze | Odzysk 15% brakującego HP strzelca |
| `sticky` | Lepkie pociski | Trafiony jest spowolniony przez 3 s |
| `explosive` | Eksplodujące | Eksplozja w miejscu trafienia |
| `seed_collector` | Kolekcjoner pestek | +1 DMG za każde trafienie bez otrzymania ciosu |
| `fruit_streak` | Owocowa passa | 3 trafienia z rzędu → następny pocisk +30% DMG |

### Triggery `on_bounce` — przy odbiciu od terenu

| ID | Nazwa | Opis |
|----|-------|------|
| `accelerating_bounce` | Przyspieszające odbicie | Prędkość ×1.1 przy każdym odbiciu |
| `destroying_bounce` | Niszczące odbicie | +5 DMG przy każdym odbiciu |
| `rage_bounce` | Wściekłe odbicie | DMG ×1.3 po odbiciu |
| `magnetic_bounce` | Magnetyczne odbicie | Homing przez 2 s po odbiciu |

---

## Jak dodać nowy typ pocisku

### 1. Scena (`.tscn`)
Utwórz `scenes/bullets/<nowa_postac>_bullet.tscn`:
- Korzeń: `Area2D`, grupy: `["Bullet"]`
- Skrypt korzenia: `res://scripts/bullets/bullet.gd`
- Dziecko `CollisionShape2D` z `CircleShape2D` (radius ≈ 3–5)
- Dziecko `BulletSprite` (`Node2D`) z proceduralnym rysowaniem w `_draw()`

### 2. Powiązanie w `main_game.gd`
Dodaj wpis do słownika na początku pliku:
```gdscript
{ "bullet": preload("res://scenes/bullets/<nowa_postac>_bullet.tscn") }
```

### 3. Wizualizacja
W `BulletSprite._draw()` użyj funkcji `draw_circle`, `draw_colored_polygon`,
`draw_line` itp. Wzoruj się na `_draw_grape_seed()` lub `_draw_pineapple_chunk()`.

### 4. Katalog
Dodaj wpis do `BULLET_SCENES` w `scripts/bullets/pociski.gd`.

---

## Jak dodać nowy modyfikator

Patrz nagłówek `Modifier_System.gd` — 3-krokowy przepis:

1. **`global.gd`** — dodaj wpis do `modifier_registry` i ID do `all_modifiers`.
2. **`Modifier_System.gd`** — dodaj `case` w funkcji odpowiadającej triggerowi.
3. **`modifier_select.gd`** — nic nie rób, mod pojawi się automatycznie.
