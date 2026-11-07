class_name TrajectoryCalculator
extends RefCounted

## Calcula los puntos de la trayectoria matemática f(x) con longitud de arco fija
## y reflexión tipo valor absoluto en paredes y bordes.

const MathEvaluator = preload("res://scripts/math_evaluator.gd")

const DEFAULT_ARC_LENGTH: float = 550.0 # Longitud de arco total fija en píxeles
const DEFAULT_UNIT_SCALE: float = 60.0  # Píxeles por unidad matemática

# Resultados del cálculo
var points: PackedVector2Array = PackedVector2Array()
var total_arc_length: float = 0.0
var hit_obstacle: bool = false
var collision_points: Array[Vector2] = []

func calculate_trajectory(
	evaluator: MathEvaluator,
	start_pos: Vector2,
	bounds: Rect2,
	obstacles: Array[Rect2] = [],
	target_arc_length: float = DEFAULT_ARC_LENGTH,
	unit_scale: float = DEFAULT_UNIT_SCALE
) -> Dictionary:
	points.clear()
	collision_points.clear()
	total_arc_length = 0.0
	hit_obstacle = false
	
	if not evaluator or not evaluator.is_valid():
		return {"points": points, "length": 0.0, "hit_obstacle": false}
	
	points.append(start_pos)
	var prev_point: Vector2 = start_pos
	
	var x_math: float = 0.0
	var dx_math: float = 0.02 # Paso de muestreo en X matemático
	var max_steps: int = 1500
	
	# Límites de rebote (con un margen de radio de la bola ~10px)
	var ball_radius: float = 8.0
	var y_min: float = bounds.position.y + ball_radius
	var y_max: float = bounds.end.y - ball_radius
	var x_min: float = bounds.position.x + ball_radius
	var x_max: float = bounds.end.x - ball_radius
	
	var current_length: float = 0.0
	
	for step in range(max_steps):
		x_math += dx_math
		var y_val = evaluator.evaluate(x_math)
		if y_val == null:
			break
		
		var y_math: float = float(y_val)
		
		# Coordenada pura antes de rebote de pared
		# +X matemático va a la derecha (+X pantalla)
		# +Y matemático va hacia arriba (-Y pantalla)
		var raw_x: float = start_pos.x + x_math * unit_scale
		var raw_y: float = start_pos.y - y_math * unit_scale
		
		# Reflexión tipo valor absoluto / plegado (ping-pong) en bordes superior e inferior
		var reflected_y: float = _fold_coordinate(raw_y, y_min, y_max)
		var reflected_x: float = _fold_coordinate(raw_x, x_min, x_max)
		
		var next_point: Vector2 = Vector2(reflected_x, reflected_y)
		
		# Comprobar colisión con obstáculos interiores (bloques de slalom / barreras)
		var segment_collision = _check_obstacle_collision(prev_point, next_point, obstacles, ball_radius)
		if segment_collision.hit:
			# Chocó con un obstáculo interior
			var hit_pos: Vector2 = segment_collision.position
			var seg_len = prev_point.distance_to(hit_pos)
			current_length += seg_len
			points.append(hit_pos)
			collision_points.append(hit_pos)
			hit_obstacle = true
			break
		
		var segment_len: float = prev_point.distance_to(next_point)
		
		if current_length + segment_len >= target_arc_length:
			# Interpolar el punto final exacto para que la longitud sea fija y constante
			var remaining: float = target_arc_length - current_length
			var ratio: float = 0.0
			if segment_len > 0.0001:
				ratio = remaining / segment_len
			var final_point: Vector2 = prev_point.lerp(next_point, ratio)
			points.append(final_point)
			current_length = target_arc_length
			break
		else:
			points.append(next_point)
			current_length += segment_len
			prev_point = next_point
	
	total_arc_length = current_length
	return {
		"points": points,
		"length": total_arc_length,
		"hit_obstacle": hit_obstacle,
		"collision_points": collision_points
	}

# Función de plegado / ping-pong para rebote continuo en paredes
func _fold_coordinate(val: float, min_val: float, max_val: float) -> float:
	var span: float = max_val - min_val
	if span <= 0.001:
		return min_val
	
	var offset: float = val - min_val
	# Simular rebote ping-pong de período 2 * span
	var period: float = 2.0 * span
	var mod_val: float = fposmod(offset, period)
	
	if mod_val <= span:
		return min_val + mod_val
	else:
		return min_val + (period - mod_val)

func _check_obstacle_collision(p1: Vector2, p2: Vector2, obstacles: Array[Rect2], radius: float) -> Dictionary:
	for obs in obstacles:
		var expanded = obs.grow(radius)
		if expanded.has_point(p1):
			return {"hit": true, "position": p1}
		var hit_p = _get_segment_rect_intersection(p1, p2, expanded)
		if hit_p != null:
			return {"hit": true, "position": hit_p}
		if expanded.has_point(p2):
			return {"hit": true, "position": p2}
	return {"hit": false, "position": Vector2.ZERO}

func _get_segment_rect_intersection(p1: Vector2, p2: Vector2, rect: Rect2) -> Variant:
	var edges = [
		[rect.position, Vector2(rect.end.x, rect.position.y)], # Superior
		[Vector2(rect.end.x, rect.position.y), rect.end],      # Derecha
		[rect.end, Vector2(rect.position.x, rect.end.y)],      # Inferior
		[Vector2(rect.position.x, rect.end.y), rect.position]  # Izquierda
	]
	var closest_hit: Variant = null
	var min_dist: float = INF
	
	for edge in edges:
		var hit = Geometry2D.segment_intersects_segment(p1, p2, edge[0], edge[1])
		if hit != null:
			var d = p1.distance_to(hit)
			if d < min_dist:
				min_dist = d
				closest_hit = hit
	return closest_hit
