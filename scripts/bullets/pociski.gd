## pociski.gd
## Katalog pocisków Fruit Game.
##
## Logika każdego pocisku żyje w bullet.gd (skrypt dołączony do każdej sceny
## z katalogu scenes/bullets/).  Poniższy słownik służy wyłącznie jako
## dokumentacja w kodzie — rzeczywiste preloady trafiają do main_game.gd.
##
## ┌─────────────┬────────────────────────────────────────────────────────────┐
## │ Postać      │ Scena pocisku                                              │
## ├─────────────┼────────────────────────────────────────────────────────────┤
## │ Strawberry  │ res://scenes/bullets/strawberry_bullet.tscn               │
## │ Grape       │ res://scenes/bullets/grape_bullet.tscn                    │
## │ Orange      │ res://scenes/bullets/orange_bullet.tscn                   │
## │ Pineapple   │ res://scenes/bullets/pineapple_bullet.tscn                │
## └─────────────┴────────────────────────────────────────────────────────────┘
##
## Każda scena pocisku zawiera:
##   • Area2D (korzeń) + skrypt bullet.gd
##   • CollisionShape2D z CircleShape2D (promień dopasowany do pocisku)
##   • BulletSprite (Node2D) z rysowaniem proceduralnym (_draw)
##
## Cykl życia pocisku:
##   1. main_game.gd tworzy instancję sceny pocisku.
##   2. Wywołuje bullet.setup(pos, dir, shooter_name) — ustawia prędkość,
##      liczbę odbić i flagi modyfikatorów.
##   3. _physics_process() porusza pocisk, obsługuje wirowanie i homing.
##   4. _on_body_entered() obsługuje kolizje z terenem (odbicia) i graczami
##      (obrażenia + wywołanie ModifierSystem.apply_on_hit).
##   5. Po trafieniu lub wyczerpaniu odbić pocisk usuwa się (queue_free).
##
## Aby dodać nowy typ pocisku — patrz docs/bullets.md.

const BULLET_SCENES: Dictionary = {
"Strawberry": "res://scenes/bullets/strawberry_bullet.tscn",
"Grape":      "res://scenes/bullets/grape_bullet.tscn",
"Orange":     "res://scenes/bullets/orange_bullet.tscn",
"Pineapple":  "res://scenes/bullets/pineapple_bullet.tscn",
}
