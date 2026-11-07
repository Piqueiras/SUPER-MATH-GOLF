class_name TrajectoryVisualizer
extends Node2D

## Dibuja el rayo de previsualización de la trayectoria matemática con brillo,
## marcas de rebote e indicador del punto final

var points: PackedVector2Array = PackedVector2Array()
var is_valid: bool = false
var hit_obstacle: bool = false
var collision_points: Array[Vector2] = []
var _pulse_t: float = 0.0

@export var line_color: Color = Color(0.25, 0.92, 1.0, 0.92) # Cian brillante
@export var glow_color: Color = Color(0.10, 0.45, 0.85, 0.35)
@export var invalid_color: Color = Color(0.95, 0.25, 0.25, 0.6)

func _process(delta: float) -> void:
	_pulse_t += delta * 3.0
	queue_redraw()

func update_trajectory(new_points: PackedVector2Array, valid: bool, hit_obs: bool, col_points: Array[Vector2]) -> void:
	points = new_points
	is_valid = valid
	hit_obstacle = hit_obs
	collision_points = col_points
	queue_redraw()

func clear() -> void:
	points.clear()
	is_valid = false
	hit_obstacle = false
	collision_points.clear()
	queue_redraw()

func _draw() -> void:
	if not is_valid or points.size() < 2:
		return
	
	var active_col = line_color if not hit_obstacle else Color(1.0, 0.8, 0.25, 0.95)
	var active_glow = glow_color if not hit_obstacle else Color(0.9, 0.6, 0.1, 0.3)
	
	# Pulso suave en la intensidad
	var alpha_pulse = 0.85 + 0.15 * sin(_pulse_t)
	active_col.a *= alpha_pulse
	
	# 1. Resplandor / Glow exterior
	draw_polyline(points, active_glow, 7.0, true)
	
	# 2. Línea central nítida
	draw_polyline(points, active_col, 2.8, true)
	
	# 3. Marcar puntos de rebote / colisión
	for cp in collision_points:
		# Anillo de impacto
		draw_arc(cp, 8.0, 0, TAU, 24, Color(1.0, 0.3, 0.2, 0.9), 2.0, true)
		draw_circle(cp, 3.5, Color(1.0, 0.4, 0.3, 1.0))
	
	# 4. Indicador en el extremo final del rayo (Longitud fija máxima)
	var end_pt = points[points.size() - 1]
	var ring_r = 5.0 + 1.5 * sin(_pulse_t * 1.5)
	draw_arc(end_pt, ring_r, 0, TAU, 16, active_col, 1.8, true)
	draw_circle(end_pt, 2.0, active_col)

