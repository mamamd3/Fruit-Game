# Roadmap — Fruit Game

Przegląd tego co zrobione i co przed nami.

---

## Wersje

### ✅ v0.1.0 — Fundament
- [x] 4 postacie z unikalnymi statami
- [x] Fizyka platformówki (grawitacja, coyote time, jump buffer)
- [x] Sterowanie 4 graczy na 1 ekranie
- [x] Mapa z platformami
- [x] Rysowane tło i postacie

### ✅ v0.2.0 — Mechaniki
- [x] 30 modyfikatorów w systemie triggerów
- [x] System rund + punktacja + ranking
- [x] Wybór modów między rundami (anti-snowball)
- [x] Kill feed
- [x] Owocowe pociski (draw-based)
- [x] Owocowe sprite'y postaci
- [x] Odbijanie pocisków od terenu

### ✅ v0.3.0 — Multiplayer
- [x] LAN multiplayer (ENet)
- [x] Lobby z listą graczy
- [x] Server-authoritative gameplay
- [x] LAN discovery
- [x] Spectator mode

### ✅ v0.4.0 — Menu, Boty, MELEE (aktualnie)
- [x] Menu główne (Local + LAN)
- [x] System Gracz / Bot / Wyłączony per slot
- [x] Bot AI (szuka, strzela, skacze, unika)
- [x] Ananas atak MELEE (cios obszarowy + knockback)
- [x] Per-gracz gnicie z modami (antirot, rot_shot, rot_accelerator)
- [x] 38 modów w puli losowania
- [x] Cleanup repo (~170 plików usunięte)
- [x] Code review + naprawienie 20+ bugów

---

### 🎯 v0.5.0 — Audio + Visual Polish
- [x] Dźwięki: strzał, trafienie, śmierć, skok, wybór postaci
- [x] Muzyka: menu, walka (loopable)
- [x] Animacje postaci: idle, walk, jump, attack/shoot
- [x] Efekty cząsteczkowe: trafienie, śmierć, eksplozja, trucizna
- [x] Screen shake przy eksplozji / śmierci
- [x] Wizualny timer gnicia (pasek nad areną lub per gracz)

### 🎯 v0.6.0 — Mapy + Balans
- [x] 3-5 map z różnym layoutem (platformy, ściany, pułapki)
- [x] Losowy wybór mapy lub głosowanie
- [x] Balans postaci na podstawie playtestów
- [x] Balans modyfikatorów (nerf/buff na podstawie danych)
- [ ] Opcjonalne: destructible terrain

### 🎯 v0.7.0 — UX + HUD
- [ ] HUD w grze: HP bar, timer gnicia, aktywne mody, kill count
- [ ] Ekran tytułowy / splash screen
- [ ] Gamepad support (Xbox/PS kontrolery)
- [ ] Ustawienia: głośność, rozdzielczość, keybinds
- [ ] Zapisywanie ustawień (ConfigFile)

### 🎯 v0.8.0 — Nowa zawartość
- [ ] 2 nowe postacie (np. Lemon — ranged DOT, Watermelon — heavy shield)
- [ ] 10+ nowych modyfikatorów
- [ ] Power-upy na mapie (drop z nieba co X sekund)
- [ ] Tryb zespołowy 2v2
- [ ] Nowe typy pocisków (łukowe, piercing)

### 🎯 v0.9.0 — Network Polish
- [ ] Interpolacja sieciowa (smooth movement online)
- [ ] Reconnect po rozłączeniu
- [ ] Boty w trybie LAN (fill empty slots)
- [ ] Kompensacja lagów (lag compensation)
- [ ] Anti-cheat walidacje (server-side)

### 🎯 v1.0.0 — Release
- [ ] Export: Windows, Linux, Android
- [ ] Pixel art sprite'y zamiast draw-based
- [ ] Tutorial / jak grać (overlay)
- [ ] Statystyki po meczu (DMG dealt, accuracy, kills)
- [ ] Polish: juice, screenshake, hitstop, chromatic aberration
- [ ] Steam / itch.io page

---

## Podsumowanie

| Wersja | Status | Główne elementy |
|--------|--------|----------------|
| v0.1.0 | ✅ Done | Postacie, fizyka, sterowanie |
| v0.2.0 | ✅ Done | Mody, rundy, pociski, kill feed |
| v0.3.0 | ✅ Done | Multiplayer LAN |
| v0.4.0 | ✅ Done | Menu, boty, melee, cleanup |
| v0.5.0 | 🎯 Next | Audio, animacje, efekty |
| v0.6.0 | 📋 Plan | Mapy, balans |
| v0.7.0 | 📋 Plan | UX, HUD, gamepad |
| v0.8.0 | 📋 Plan | Nowa zawartość |
| v0.9.0 | 📋 Plan | Network polish |
| v1.0.0 | 📋 Plan | Release |
