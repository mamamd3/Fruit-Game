# 🍓 Fruit Game

**2D PvP arena shooter** w Godot 4.3 — do 4 graczy na jednym ekranie lub przez LAN.

> Wersja: **0.4.0** | Status: **Alpha** | Licencja: MIT

---

## Spis treści

- [Postacie](#postacie)
- [Mechaniki](#mechaniki)
- [Modyfikatory](#modyfikatory)
- [Sterowanie](#sterowanie)
- [Tryby gry](#tryby-gry)
- [Struktura projektu](#struktura-projektu)
- [Uruchomienie](#uruchomienie)
- [Status implementacji](#status-implementacji)

---

## Postacie

| Postać | HP | Speed | DMG | Fire Rate | Typ | Styl |
|--------|-----|-------|-----|-----------|-----|------|
| 🍓 Strawberry | 100 | 80 | 25 | 0.8s | Ranged | Klasyczny, zrównoważony |
| 🍊 Orange | 50 | 90 | 50 | 2.5s | Ranged | Szklany snajper — mało HP, dużo DMG |
| 🍍 Pineapple | 200 | 60 | 30 | 0.5s | **MELEE** | Powolny tank z ciosem obszarowym |
| 🍇 Grape | 80 | 100 | 15 | 0.2s | Ranged | Szybkostrzelny, niski DMG |

### Pineapple — atak melee

Ananas jako jedyna postać nie strzela pociskami. Zamiast tego wykonuje **cios obszarowy** (promień 40px) w kierunku celowania z knockbackiem. Mody `on_hit` (lifesteal, fermentacja, sticky) działają normalnie.

---

## Mechaniki

### System rund
1. **Wybór postaci** — każdy gracz (lub bot) wybiera unikalną postać
2. **Walka** — arena FFA, ostatni żywy wygrywa rundę
3. **Modyfikatory** — przegrani wybierają ulepszenia między rundami (anti-snowball)
4. **Set** — co 5 rund podsumowanie punktów i ranking

### Punktacja
| Miejsce | Punkty |
|---------|--------|
| 1. | 3 pkt |
| 2. | 2 pkt |
| 3. | 1 pkt |
| 4. | 0 pkt |

### Gnicie (Rot)
Każdy gracz ma **120 sekund** zanim zgnije i zginie. Mody wpływają indywidualnie:
- `antirot` → +5s na starcie
- `rot_shot` → trafiony traci 3s
- `rot_accelerator` → wrogowie w zasięgu gniją 15% szybciej

### Fizyka
- Grawitacja + coyote time + jump buffer
- Head nudge — pomaga wejść pod niskie platformy
- Wall climb nudge — wspomaganie przy krawędziach
- Odbijanie pocisków od terenu (domyślnie 1 odbicie)

---

## Modyfikatory

Przegrani gracze wybierają modyfikatory między rundami. 3 losowe karty do wyboru.

### Projectile (ataki)

| Mod | Opis |
|-----|------|
| ✌️ Podwójny strzał | Dodatkowy pocisk obok głównego |
| 🎯 Pestka snajpera | Pocisk +25% szybciej |
| 🧪 Fermentacja | Pocisk zatruwa wroga na 3 sek |
| 🍑 Dojrzały strzał | Co 3. strzał +30% DMG |
| 💥 Shotgun pestek | 3 dodatkowe pociski w wachlarzu |
| ☢️ Radioaktywna pestka | Toksyczna plama na 3 sek przy trafieniu |
| 🦠 Strzał zgnilizny | Trafiony gnije o 3 sek szybciej |
| 🧲 Magnetyczna pestka | Pocisk skręca w stronę wroga (2m) |
| 🌰 Kolekcjoner pestek | +1 DMG za trafienie bez ciosu (reset przy otrzymaniu) |
| 🔥 Owocowa passa | 3 trafienia z rzędu → następny +30% DMG |

### Defense (obrona)

| Mod | Opis |
|-----|------|
| 🥊 Gruba skórka | Max HP +25 |
| 💧 Soczyste wnętrze | 15% brakującego HP przy trafieniu wroga |
| 🕯️ Woskowa powłoka | Blokuje 1. trafienie w rundzie |
| 🌵 Kolczasta tarcza | Atakujący dostaje -3 HP |
| 🪨 Twardy owoc | -10% obrażeń |
| 🧴 Antyzgnilizna | Gnijesz 5 sek wolniej |
| 🛡️ Konserwant | 15 sek odporności na starcie |
| 🍀 Drugi owoc | Przeżywasz śmiertelny cios z 5 HP (raz/rundę) |
| 🌿 Zielony jeszcze | HP < 30% → regen 1 HP co 2 sek |
| 🗿 Kamienna pestka | +8 pancerza, -10% speed |
| 🪞 Lustrzana skórka | 10% szansa odbicia ataku |

### Bounce (odbicia)

| Mod | Opis |
|-----|------|
| ↩️ Dodatkowe odbicie | +1 odbicie |
| ⚡ Przyspieszające odbicie | +10% speed pocisku na odbicie |
| 💢 Niszczące odbicie | +5 DMG na odbicie |
| 🧲 Magnetyczne odbicie | Po odbiciu → homing 2 sek |
| 😡 Wściekłe odbicie | Odbity pocisk +30% DMG |

### Passive / Area

| Mod | Opis |
|-----|------|
| 👟 Dojrzały sprint | +15% speed |
| 💀 Przyspieszacz gnicia | Wrogowie w zasięgu 150px gniją 15% szybciej |
| 🌋 Gnilna eksplozja | HP < 20% → odpychasz wrogów + 10 HP (jednorazowo) |
| 🔄 Duplikator modów | Kopiuje losowy posiadany mod |

### Legacy mods (dodatkowe)

| Mod | Opis |
|-----|------|
| ↩️ Odbijające pociski | 4 odbicia |
| 🌪️ Wirujące pociski | Sinusoidalny ruch |
| ☠️ Ślad trucizny | Toksyczny ślad za graczem |
| 🔴 Kradzież HP | 30% DMG → HP |
| 💣 Eksplodujące | Eksplozja przy trafieniu |
| 🐌 Lepkie pociski | Spowolnienie 3 sek |
| 🛡️ Pancerz | -30% obrażeń |
| 👟 +20% prędkość | Speed boost |

---

## Sterowanie

| Gracz | Ruch | Skok | Strzał/Cios |
|-------|------|------|-------------|
| P1 | A / D | Space | LPM |
| P2 | ← / → | ↑ | PPM |
| P3 | J / L | I | Środkowy myszy |
| P4 | Numpad 4/6 | Numpad 8 | Przycisk myszy 9 |
| Bot | — | — | AI automatycznie |

---

## Tryby gry

### Gra lokalna
- Menu start z **4 slotami**: kliknij żeby cyklować **Gracz → Bot → Wyłączony**
- Domyślnie: Slot 1-2 = Gracz, Slot 3-4 = Bot
- Minimum 2 aktywne sloty do startu
- Boty automatycznie wybierają losową postać

### Gra sieciowa (LAN)
- Host tworzy serwer (ENet, port 7777)
- Klienci łączą się po IP
- Lobby z listą graczy → start gdy ≥ 2
- Server-authoritative: HP, śmierć, koniec rundy

---

## Struktura projektu

```
Fruit-Game/
├── scenes/
│   ├── characters/     # Grape, Orange, Pineapple, Strawberry (.tscn)
│   ├── bullets/        # Pociski per postać (.tscn)
│   ├── effects/        # Eksplozje, trucizna, melee hit (.tscn)
│   ├── ui/             # Menu, lobby, wybór postaci, modyfikatory, wyniki
│   ├── main_game.tscn  # Arena
│   └── global.tscn     # Singleton scena
├── scripts/
│   ├── ai/             # Bot AI controller
│   ├── bullets/        # Logika pocisków
│   ├── characters/     # Logika postaci + fruit drawer
│   ├── core/           # Global, MainGame, ModifierSystem
│   ├── effects/        # Eksplozje, trucizna, melee
│   ├── map/            # Rysowanie tła/mapy
│   ├── multiplayer/    # MultiplayerManager, LAN discovery
│   └── ui/             # UI flow (menu, lobby, pick, results)
├── assets/sprites/     # Tekstury
├── fonts/              # Czcionki
└── docs/               # Game Design Document
```

---

## Uruchomienie

1. Otwórz projekt w **Godot 4.3**
2. **F5** — gra startuje od menu głównego
3. Wybierz tryb: lokalna (z botami) lub LAN

---

## Status implementacji

### ✅ Zrobione (v0.4.0)

| Funkcja | Status |
|---------|--------|
| 4 postacie z unikalnymi statami | ✅ |
| Pineapple melee (cios obszarowy + knockback) | ✅ |
| 38 modyfikatorów (30 doc + 8 legacy) | ✅ |
| System rund + punktacja + ranking | ✅ |
| Wybór modyfikatorów (anti-snowball) | ✅ |
| Per-gracz gnicie (rot) z modami | ✅ |
| Menu start: Local + LAN | ✅ |
| Wybór Gracz / Bot / Wyłączony per slot | ✅ |
| Bot AI (szuka wroga, strzela, skacze, unika) | ✅ |
| Owocowe sprite'y (draw-based) | ✅ |
| Owocowe pociski (nasiona, pestki) | ✅ |
| Kill feed na ekranie | ✅ |
| Multiplayer LAN (ENet, server-authoritative) | ✅ |
| Lobby z listą graczy | ✅ |
| Fizyka: coyote time, jump buffer, head nudge | ✅ |
| Odbijanie pocisków od terenu | ✅ |
| Etykiety z nazwami nad postaciami | ✅ |
| Dźwięki i muzyka | ✅ |

### 🔧 Do zrobienia (backlog)

| Funkcja | Priorytet |
|---------|-----------|
| Więcej map / losowa mapa | 🔴 Wysoki |
| Animacje postaci (idle, walk, jump, attack) | 🔴 Wysoki |
| Pixel art sprite'y zamiast draw-based | 🟡 Średni |
| Ekran tytułowy / splash screen | 🟡 Średni |
| Balans postaci (playtesting) | 🟡 Średni |
| Gamepad support | 🟡 Średni |
| HUD — timer gnicia, aktywne mody, kill count | 🟡 Średni |
| Efekty cząsteczkowe (trafienie, śmierć, eksplozja) | 🟡 Średni |
| Interpolacja sieciowa (smooth movement online) | 🟢 Niski |
| Reconnect po rozłączeniu | 🟢 Niski |
| Boty w trybie LAN | 🟢 Niski |
| Zapisywanie ustawień gracza | 🟢 Niski |
| Export na Windows / Linux / Android | 🟢 Niski |
