class_name TrajectoryVisualizer
extends Node2D

## Dibuja el rayo de la trayectoria matemática, marcadores de rebote
## y un indicador dinámico de aterrizaje (Ghost Ball / Retícula) para estimar la potencia exacta

var points: PackedVector2Array = PackedVector2Array()
var is_valid: bool = false
var hit_obstacle: bool = false
var collision_points: Array[Vector2] = []
var total_arc_length: float = 550.0

var current_power_ratio: float = 0.0
var is_charging_power: bool = false
var sweet_spot_center: float = 0.8
var sweet_spot_width: float = 0.16
var is_in_sweet_spot: bool = false

var _pulse_t: float = 0.0

@export var line_color: Color = Color(0.25, 0.92, 1.0, 0.92) # Cian brillante
@export var glow_color: Color = Color(0.10, 0.45, 0.85, 0.35)
@export var power_line_color: Color = Color(1.0, 0.95, 0.3, 0.95) # Amarillo/dorado activo
@export var sweet_spot_color: Color = Color(0.2, 1.0, 0.4, 0.95) # Verde óptimo

func _process(delta: float) -> void:
	_pulse_t += delta * 4.0
	queue_redraw()

func update_trajectory(
	new_points: PackedVector2Array,
	valid: bool,
	hit_obs: bool,
	col_points: Array[Vector2],
	arc_len: float = 550.0
) -> void:
	points = new_points
	is_valid = valid
	hit_obstacle = hit_obs
	collision_points = col_points
	total_arc_length = arc_len
	queue_redraw()

func set_power_preview(power: float, charging: bool, sweet_center: float, sweet_width: float) -> void:
	current_power_ratio = clamp(power, 0.0, 1.0)
	is_charging_power = charging
	sweet_spot_center = sweet_center
	sweet_spot_width = sweet_width
	is_in_sweet_spot = abs(current_power_ratio - sweet_spot_center) <= (sweet_spot_width * 0.5)
	queue_redraw()

func clear() -> void:
	points.clear()
	is_valid = false
	hit_obstacle = false
	collision_points.clear()
	is_charging_power = false
	queue_redraw()

func _draw() -> void:
	if not is_valid or points.size() < 2:
		return
	
	var active_col = line_color if not hit_obstacle else Color(1.0, 0.8, 0.25, 0.95)
	var active_glow = glow_color if not hit_obstacle else Color(0.9, 0.6, 0.1, 0.3)
	
	# Pulso suave en la línea base
	var alpha_pulse = 0.85 + 0.15 * sin(_pulse_t)
	active_col.a *= alpha_pulse
	
	# 1. Trazado completo de fondo (Atenuado si se está cargando potencia)
	var base_alpha = 0.45 if is_charging_power else 1.0
	var dim_col = active_col
	dim_col.a *= base_alpha
	draw_polyline(points, active_glow * base_alpha, 7.0, true)
	draw_polyline(points, dim_col, 2.5, true)
	
	# 2. Marcador fijo del Sweet Spot (zona óptima para embocar en este hoyo)
	var sw_dist = sweet_spot_center * total_arc_length
	var sw_pos = get_point_at_distance(sw_dist)
	# Anillo tenue de objetivo ideal
	draw_arc(sw_pos, 10.0 + sin(_pulse_t) * 1.5, 0, TAU, 24, Color(0.2, 0.9, 0.4, 0.55), 1.8, true)
	draw_circle(sw_pos, 3.0, Color(0.3, 1.0, 0.5, 0.7))
	
	# 3. Tramo activo cargado y Marcador dinámico de potencia (Llegada estimada)
	var effective_power = current_power_ratio if is_charging_power else sweet_spot_center
	var target_dist = effective_power * total_arc_length
	var landing_pos = get_point_at_distance(target_dist)
	
	# Resaltar la línea hasta la distancia de la potencia actual
	if effective_power > 0.02:
		var power_pts = get_points_up_to_distance(target_dist)
		if power_pts.size() >= 2:
			var reach_col = sweet_spot_color if (is_charging_power and is_in_sweet_spot) else power_line_color
			reach_col.a = 0.95
			draw_polyline(power_pts, reach_col * Color(1, 1, 1, 0.4), 8.0, true)
			draw_polyline(power_pts, reach_col, 3.5, true)
	
	# Retícula / Ghost Ball en el punto exacto donde frenará la bola
	var reticle_col = sweet_spot_color if (is_charging_power and is_in_sweet_spot) else Color(1.0, 0.9, 0.2)
	if not is_charging_power:
		reticle_col = Color(0.3, 0.9, 1.0, 0.75)
	
	var reticle_r = 8.5 + (2.0 * sin(_pulse_t * 2.0) if is_in_sweet_spot else 0.0)
	
	# Sombra del marcador
	draw_circle(landing_pos + Vector2(2, 2), reticle_r, Color(0, 0, 0, 0.3))
	# Círculo blanco translúcido tipo 'fantasma' de la bola
	draw_circle(landing_pos, reticle_r, Color(reticle_col.r, reticle_col.g, reticle_col.b, 0.4))
	draw_arc(landing_pos, reticle_r, 0, TAU, 24, reticle_col, 2.2, true)
	
	# Cruz de mira en el punto de llegada
	var cross_len = reticle_r + 4.0
	draw_line(landing_pos - Vector2(cross_len, 0), landing_pos + Vector2(cross_len, 0), reticle_col, 1.5)
	draw_line(landing_pos - Vector2(0, cross_len), landing_pos + Vector2(0, cross_len), reticle_col, 1.5)
	
	# 4. Marcar puntos de colisión / rebote
	for cp in collision_points:
		draw_arc(cp, 8.0, 0, TAU, 24, Color(1.0, 0.3, 0.2, 0.9), 2.0, true)
		draw_circle(cp, 3.5, Color(1.0, 0.4, 0.3, 1.0))
	
	# 5. Indicador en el extremo final absoluto del rayo (550px)
	var end_pt = points[points.size() - 1]
	draw_arc(end_pt, 5.0, 0, TAU, 16, active_col, 1.5, true)

func get_point_at_distance(target_dist: float) -> Vector2:
	if points.size() == 0:
		return Vector2.ZERO
	if points.size() == 1 or target_dist <= 0.0:
		return points[0]
	
	var accumulated: float = 0.0
	for i in range(points.size() - 1):
		var p1 = points[i]
		var p2 = points[i + 1]
		var d = p1.distance_to(p2)
		if accumulated + d >= target_dist:
			var remaining = target_dist - accumulated
			var t = remaining / d if d > 0.0001 else 0.0
			return p1.lerp(p2, t)
		accumulated += d
	return points[points.size() - 1]

func get_points_up_to_distance(target_dist: float) -> PackedVector2Array:
	var sub: PackedVector2Array = PackedVector2Array()
	if points.size() == 0:
		return sub
	sub.append(points[0])
	var accumulated: float = 0.0
	for i in range(points.size() - 1):
		var p1 = points[i]
		var p2 = points[i + 1]
		var d = p1.distance_to(p2)
		if accumulated + d >= target_dist:
			var remaining = target_dist - accumulated
			var t = remaining / d if d > 0.0001 else 0.0
			sub.append(p1.lerp(p2, t))
			break
		else:
			sub.append(p2)
			accumulated += d
	return sub
