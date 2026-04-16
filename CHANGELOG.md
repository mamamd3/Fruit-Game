# Changelog

Wszystkie istotne zmiany w projekcie Fruit Game.

Format oparty na [Keep a Changelog](https://keepachangelog.com/pl/1.1.0/).

---

## [0.4.0] — 2026-04-07

### Dodane
- **Menu główne** — wybór trybu: gra lokalna / LAN
- **System Gracz/Bot/Off** — 4 sloty, klikaj żeby cyklować typ
- **Bot AI** (`bot_controller.gd`) — szuka wroga, strzela, skacze, unika
- **Ananas MELEE** — cios obszarowy (r=40px) z knockbackiem zamiast pocisku
- **Wizualny łuk ciosu** — Line2D slash effect dla Ananasa
- **Per-gracz gnicie** — `rot_time_remaining` zamiast globalnego Timera
- **3 nowe mody zaimplementowane**: `antirot`, `rot_shot` (direct), `rot_accelerator`
- **8 legacy modów** dodanych do puli losowania: bouncy, spinning, poison, lifesteal, explosive, sticky, armor, speed
- **MultiplayerManager** w autoload (`project.godot`)

### Naprawione
- **thick_skin** — HP nie kumuluje się między rundami (ORIGINAL_BASE_CHARACTERS const)
- **Poison stacks** — wygasają po 3 sekundach (decay timer per stack)
- **Ścieżki** — ujednolicono `res://Scenes/` → `res://scenes/` (Linux/Android safe)
- **Shotgun** — zmieniono z 4 na 3 dodatkowe pociski
- **Head nudge** — hc[1] i hc[3] teraz obsługiwane
- **RPC spawn bullet** — walidacja nadawcy (anti-cheat)
- **Gnicie Timer** — usunięto podwójny autostart
- **modifier_select** — safety check `pool.slice(0, mini(3, pool.size()))`
- **Indentacja** — poprawiono antirot, rot_shot, rot_accelerator w match/case
- **Dead signals** — usunięto `_on_hitbox_body_entered` z 4 scen postaci

### Usunięte
- **~170 plików SkeleRealms** — ai, barter, covens, crime, entities, fsm, tools, itd.
- **8 starych branchy** + 1 PR zamknięty — repo czyste, tylko `main`
- **pociski.gd** — martwy/zepsuty plik z dwoma `extends Node`

---

## [0.3.0] — 2026-04-05

### Dodane
- Multiplayer LAN (ENet, server-authoritative)
- Lobby z listą graczy i slotami
- Network interpolation + LAN discovery
- Spectator mode

---

## [0.2.0] — 2026-04-03

### Dodane
- System modyfikatorów (30 modów w registry)
- ModifierSystem autoload z triggerami: on_apply, on_shoot, on_hit, on_receive, on_lethal, on_bounce, passive
- Wybór modyfikatorów między rundami (anti-snowball)
- System rund z punktacją (3/2/1/0)
- Kill feed na ekranie
- Owocowe pociski (nasiona, pestki) — draw-based
- Owocowe sprite'y postaci — draw-based
- Etykiety z nazwami nad postaciami
- Odbijanie pocisków od terenu (1 bounce domyślnie)

---

## [0.1.0] — 2026-04-01

### Dodane
- 4 postacie: Strawberry, Orange, Pineapple, Grape
- Unikalne staty per postać (HP, speed, DMG, fire_rate)
- Fizyka platformówki: grawitacja, coyote time, jump buffer, head nudge, wall climb
- Sterowanie dla 4 graczy na jednym ekranie
- Mapa z platformami i kolizjami
- Rysowanie tła (niebo, chmury, trawa, krzewy)
- Podstawowa struktura projektu w Godot 4.3
