class_name GolfObstacle
extends Node2D

## Bloque obstáculo o barrera en el campo de minigolf

@export var rect_size: Vector2 = Vector2(40, 100)
@export var fill_color: Color = Color(0.48, 0.28, 0.16)
@export var border_color: Color = Color(0.30, 0.15, 0.08)

func _ready() -> void:
	queue_redraw()

func get_rect2() -> Rect2:
	return Rect2(global_position - rect_size * 0.5, rect_size)

func _draw() -> void:
	var half = rect_size * 0.5
	var local_rect = Rect2(-half, rect_size)
	
	# Sombra
	draw_rect(Rect2(-half + Vector2(3, 4), rect_size), Color(0, 0, 0, 0.3), true)
	
	# Cuerpo principal
	draw_rect(local_rect, fill_color, true)
	
	# Borde biselado
	draw_rect(local_rect, border_color, false, 3.0)
	
	# Detalle interior (estilo bloque de madera o franjas de minigolf)
	draw_line(Vector2(-half.x + 4, -half.y + 4), Vector2(half.x - 4, -half.y + 4), Color(1, 1, 1, 0.25), 1.5)
	draw_line(Vector2(-half.x + 4, half.y - 4), Vector2(half.x - 4, half.y - 4), Color(0, 0, 0, 0.35), 1.5)

