class_name GolfBall
extends Node2D

## Representa la bola de golf y gestiona su desplazamiento sobre los puntos de la trayectoria

signal movement_finished(final_pos: Vector2, in_hole: bool)
signal entered_hole_event

enum State { IDLE, MOVING, SINKING, IN_HOLE }

@export var radius: float = 9.0

var current_state: State = State.IDLE
var _path_points: PackedVector2Array = PackedVector2Array()
var _target_distance: float = 0.0
var _current_distance: float = 0.0
var _current_segment_idx: int = 0
var _segment_progress: float = 0.0
var _base_speed: float = 380.0 # Píxeles por segundo
var _current_speed: float = 380.0
var _hole_target_pos: Vector2 = Vector2.ZERO
var _hole_capture_radius: float = 24.0

# Animación visual
var _roll_angle: float = 0.0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	if current_state == State.IN_HOLE:
		return
	
	# Sombra de la bola
	draw_circle(Vector2(2, 3), radius * 0.95, Color(0, 0, 0, 0.25))
	
	# Cuerpo principal blanco de la bola
	draw_circle(Vector2.ZERO, radius, Color(0.96, 0.97, 0.99))
	
	# Borde sutil
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.75, 0.78, 0.82), 1.2, true)
	
	# Brillo especular y textura de hoyuelos
	draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.35, Color(1, 1, 1, 0.8))
	
	# Puntos/hoyuelos sutiles
	var dimple_col = Color(0.85, 0.87, 0.90)
	var d1 = Vector2(cos(_roll_angle) * 3, sin(_roll_angle) * 3)
	var d2 = Vector2(cos(_roll_angle + 2.0) * 4, sin(_roll_angle + 2.0) * 4)
	var d3 = Vector2(cos(_roll_angle + 4.0) * 3, sin(_roll_angle + 4.0) * 3)
	draw_circle(d1, 1.2, dimple_col)
	draw_circle(d2, 1.2, dimple_col)
	draw_circle(d3, 1.2, dimple_col)

func start_shot(
	trajectory_points: PackedVector2Array,
	power_ratio: float,
	hole_pos: Vector2,
	max_trajectory_length: float
) -> void:
	if trajectory_points.size() < 2:
		return
	
	_path_points = trajectory_points
	_hole_target_pos = hole_pos
	_target_distance = clamp(power_ratio, 0.05, 1.0) * max_trajectory_length
	_current_distance = 0.0
	_current_segment_idx = 0
	_segment_progress = 0.0
	_base_speed = lerp(260.0, 480.0, power_ratio)
	_current_speed = _base_speed
	current_state = State.MOVING
	global_position = _path_points[0]
	queue_redraw()

func _physics_process(delta: float) -> void:
	if current_state == State.MOVING:
		_process_movement(delta)
	elif current_state == State.SINKING:
		_process_sinking(delta)

func _process_movement(delta: float) -> void:
	if _path_points.size() < 2 or _current_segment_idx >= _path_points.size() - 1:
		_finish_shot()
		return
	
	# Desaceleración suave al final del tiro (sensación de rodaje en césped)
	var remaining_dist = _target_distance - _current_distance
	var decel_factor = clamp(remaining_dist / 120.0, 0.18, 1.0)
	_current_speed = _base_speed * decel_factor
	
	var step = _current_speed * delta
	if step > remaining_dist:
		step = remaining_dist
	
	var p_start = _path_points[_current_segment_idx]
	var p_end = _path_points[_current_segment_idx + 1]
	var seg_length = p_start.distance_to(p_end)
	
	while seg_length <= 0.001:
		_current_segment_idx += 1
		if _current_segment_idx >= _path_points.size() - 1:
			_finish_shot()
			return
		p_start = _path_points[_current_segment_idx]
		p_end = _path_points[_current_segment_idx + 1]
		seg_length = p_start.distance_to(p_end)
		_segment_progress = 0.0
	
	var remaining_in_segment = seg_length - _segment_progress
	
	if step < remaining_in_segment:
		_segment_progress += step
		_current_distance += step
		global_position = p_start.lerp(p_end, _segment_progress / seg_length)
	else:
		_current_distance += remaining_in_segment
		global_position = p_end
		_current_segment_idx += 1
		_segment_progress = 0.0
	
	# Rotación visual
	_roll_angle += step * 0.08
	queue_redraw()
	
	# Comprobar si pasa lo suficientemente cerca del hoyo a baja velocidad para embocar
	if global_position.distance_to(_hole_target_pos) <= _hole_capture_radius:
		if _current_speed < 320.0 or remaining_dist < 40.0:
			_start_sinking()
			return
	
	# Verificar si ya completó la distancia de la potencia
	if _current_distance >= _target_distance:
		_finish_shot()

func _start_sinking() -> void:
	current_state = State.SINKING
	entered_hole_event.emit()

var _sink_t: float = 0.0
func _process_sinking(delta: float) -> void:
	_sink_t += delta * 3.5
	global_position = global_position.lerp(_hole_target_pos, delta * 8.0)
	scale = Vector2.ONE * max(0.1, 1.0 - _sink_t * 0.8)
	queue_redraw()
	if _sink_t >= 1.0:
		current_state = State.IN_HOLE
		scale = Vector2.ONE
		movement_finished.emit(global_position, true)

func _finish_shot() -> void:
	current_state = State.IDLE
	# Comprobar captura final en el hoyo
	var dist_to_hole = global_position.distance_to(_hole_target_pos)
	if dist_to_hole <= _hole_capture_radius:
		_start_sinking()
	else:
		movement_finished.emit(global_position, false)
	queue_redraw()

func reset_to(pos: Vector2) -> void:
	current_state = State.IDLE
	global_position = pos
	scale = Vector2.ONE
	_sink_t = 0.0
	queue_redraw()
