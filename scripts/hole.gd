class_name GolfHole
extends Node2D

## Representa el hoyo de golf con bandera animada y zona de captura

@export var radius: float = 14.0
@export var flag_height: float = 46.0

var _anim_time: float = 0.0

func _process(delta: float) -> void:
	_anim_time += delta * 4.0
	queue_redraw()

func _draw() -> void:
	# Borde del hoyo (césped aplastado alrededor)
	draw_circle(Vector2.ZERO, radius + 3.0, Color(0.18, 0.45, 0.18, 0.5))
	
	# Interior del hoyo (sombra y profundidad)
	draw_circle(Vector2.ZERO, radius, Color(0.08, 0.12, 0.08))
	draw_circle(Vector2(0, 1), radius * 0.7, Color(0.03, 0.05, 0.03))
	
	# Borde interior metálico/blanco de la cazoleta
	draw_arc(Vector2.ZERO, radius - 1.0, 0, TAU, 32, Color(0.2, 0.25, 0.22), 1.5, true)
	
	# Mástil de la bandera
	var pole_start = Vector2(0, 0)
	var pole_end = Vector2(0, -flag_height)
	draw_line(pole_start, pole_end, Color(0.85, 0.88, 0.92), 2.5, true)
	draw_circle(pole_end, 2.5, Color(0.95, 0.75, 0.1)) # Bola dorada en la punta
	
	# Bandera ondeante roja (polígono triangular con animación suave)
	var wave_offset = sin(_anim_time) * 3.0
	var flag_tip = Vector2(24.0 + wave_offset * 0.5, -flag_height + 10.0 + wave_offset)
	var flag_pts = PackedVector2Array([
		Vector2(0, -flag_height),
		Vector2(0, -flag_height + 18.0),
		flag_tip
	])
	draw_colored_polygon(flag_pts, Color(0.92, 0.2, 0.18))
	
	# Detalle en la bandera
	draw_line(Vector2(4, -flag_height + 4), Vector2(16, -flag_height + 9), Color(1, 0.8, 0.2, 0.7), 1.5)

