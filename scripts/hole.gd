class_name GolfHole
extends Area2D

## Representa el hoyo de golf con nodos visuales para cazoleta, mástil, bandera animada y zona de colisión

@export var radio_captura: float = 34.0
@export var altura_bandera: float = 46.0

@export_group("Referencias de Nodos")
@export var cazoleta: Sprite2D
@export var mastil: Line2D
@export var bandera: Polygon2D
@export var collision_shape: CollisionShape2D

var _anim_time: float = 0.0

func _process(delta: float) -> void:
	_anim_time += delta * 4.0
	if bandera != null:
		# Animación ondeante de la bandera modificando la punta del triángulo
		var wave_offset = sin(_anim_time) * 3.5
		var flag_tip = Vector2(24.0 + wave_offset * 0.4, -altura_bandera + 10.0 + wave_offset)
		bandera.polygon = PackedVector2Array([
			Vector2(0, -altura_bandera),
			Vector2(0, -altura_bandera + 18.0),
			flag_tip
		])
