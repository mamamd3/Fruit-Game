extends Node
# BulletPool.gd v3 — Object Pool 50 pociskow, zero GC spikes

@export var bullet_scene: PackedScene
const POOL_SIZE: int = 50

var _pool: Array[Node] = []

func _ready() -> void:
	assert(bullet_scene != null, "Przypisz bullet_scene w edytorze!")
	for i in POOL_SIZE:
		var b = bullet_scene.instantiate()
		b.process_mode = Node.PROCESS_MODE_DISABLED
		b.visible = false
		add_child(b)
		_pool.append(b)

func acquire() -> Node:
	for b in _pool:
		if not b.visible:
			b.visible = true
			b.process_mode = Node.PROCESS_MODE_INHERIT
			return b
	var b = bullet_scene.instantiate()
	add_child(b)
	_pool.append(b)
	push_warning("BulletPool rozszerza sie! Rozmiar=%d" % _pool.size())
	return b

func release(bullet: Node) -> void:
	bullet.visible = false
	bullet.process_mode = Node.PROCESS_MODE_DISABLED
	if bullet.has_method("reset"):
		bullet.reset()
