class_name GolfBall
extends CharacterBody2D

## Representa la bola de golf con nodos visuales (Sprite, Sombra, Partículas y CollisionShape2D)

signal movement_finished(final_pos: Vector2, in_hole: bool)
signal entered_hole_event

enum State { IDLE, MOVING, SINKING, IN_HOLE }

@export_group("Parámetros Físicos")
@export var velocidad_base: float = 500.0 # Píxeles por segundo
@export var radio: float = 10.0
@export var radio_captura_hoyo: float = 34.0

@export_group("Referencias de Nodos Hijos")
@export var sprite_bola: Sprite2D
@export var sombra_bola: Sprite2D
@export var particulas_estela: CPUParticles2D
@export var shape_colision: CollisionShape2D

var current_state: State = State.IDLE
var _path_points: PackedVector2Array = PackedVector2Array()
var _target_distance: float = 0.0
var _current_distance: float = 0.0
var _current_segment_idx: int = 0
var _segment_progress: float = 0.0
var _current_speed: float = 500.0
var _hole_target_pos: Vector2 = Vector2.ZERO
var _sink_t: float = 0.0

func _ready() -> void:
	if particulas_estela != null:
		particulas_estela.emitting = false

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
	
	# Velocidad rápida escalada con la potencia
	_current_speed = lerp(velocidad_base * 0.8, velocidad_base * 1.35, power_ratio)
	current_state = State.MOVING
	global_position = _path_points[0]
	
	if particulas_estela != null:
		particulas_estela.emitting = true
	if sprite_bola != null:
		sprite_bola.visible = true
	if sombra_bola != null:
		sombra_bola.visible = true

func _physics_process(delta: float) -> void:
	if current_state == State.MOVING:
		_process_movement(delta)
	elif current_state == State.SINKING:
		_process_sinking(delta)

func _process_movement(delta: float) -> void:
	if _path_points.size() < 2 or _current_segment_idx >= _path_points.size() - 1:
		_finish_shot()
		return
	
	# Desaceleración nítida en los últimos 60px para no frenar antes de tiempo
	var remaining_dist = _target_distance - _current_distance
	var decel = clamp(remaining_dist / 60.0, 0.5, 1.0)
	var active_speed = _current_speed * decel
	
	# Distancia total a recorrer en este frame
	var frame_distance = active_speed * delta
	if frame_distance > remaining_dist:
		frame_distance = remaining_dist
	
	# Bucle para avanzar a través de TODOS los segmentos necesarios en este frame
	while frame_distance > 0.0 and _current_segment_idx < _path_points.size() - 1:
		var p_start = _path_points[_current_segment_idx]
		var p_end = _path_points[_current_segment_idx + 1]
		var seg_length = p_start.distance_to(p_end)
		
		if seg_length <= 0.0001:
			_current_segment_idx += 1
			_segment_progress = 0.0
			continue
		
		var remaining_in_segment = seg_length - _segment_progress
		
		if frame_distance < remaining_in_segment:
			_segment_progress += frame_distance
			_current_distance += frame_distance
			global_position = p_start.lerp(p_end, _segment_progress / seg_length)
			frame_distance = 0.0
		else:
			frame_distance -= remaining_in_segment
			_current_distance += remaining_in_segment
			global_position = p_end
			_current_segment_idx += 1
			_segment_progress = 0.0
	
	# Rotación visual del sprite de la bola
	if sprite_bola != null:
		sprite_bola.rotation += (active_speed * delta) * 0.15
	
	# Detección y succión gravitatoria hacia el hoyo
	var dist_to_hole = global_position.distance_to(_hole_target_pos)
	if dist_to_hole <= radio_captura_hoyo:
		# Atracción hacia el hoyo
		global_position = global_position.move_toward(_hole_target_pos, delta * 350.0)
		# Embocar si está en la zona y su parada o velocidad son compatibles
		if active_speed < 850.0 or remaining_dist < 65.0 or dist_to_hole < 18.0:
			_start_sinking()
			return
	
	# Finalizar si completó la distancia
	if _current_distance >= _target_distance:
		_finish_shot()

func _start_sinking() -> void:
	current_state = State.SINKING
	if particulas_estela != null:
		particulas_estela.emitting = false
	entered_hole_event.emit()

func _process_sinking(delta: float) -> void:
	_sink_t += delta * 5.0
	global_position = global_position.lerp(_hole_target_pos, delta * 14.0)
	scale = Vector2.ONE * max(0.05, 1.0 - _sink_t * 0.85)
	if _sink_t >= 1.0:
		current_state = State.IN_HOLE
		scale = Vector2.ONE
		if sprite_bola != null:
			sprite_bola.visible = false
		if sombra_bola != null:
			sombra_bola.visible = false
		movement_finished.emit(global_position, true)

func _finish_shot() -> void:
	current_state = State.IDLE
	if particulas_estela != null:
		particulas_estela.emitting = false
	
	# Comprobación final en reposo con margen generoso
	var dist_to_hole = global_position.distance_to(_hole_target_pos)
	if dist_to_hole <= (radio_captura_hoyo + 8.0):
		_start_sinking()
	else:
		movement_finished.emit(global_position, false)

func reset_to(pos: Vector2) -> void:
	current_state = State.IDLE
	global_position = pos
	scale = Vector2.ONE
	_sink_t = 0.0
	if sprite_bola != null:
		sprite_bola.visible = true
		sprite_bola.rotation = 0.0
	if sombra_bola != null:
		sombra_bola.visible = true
	if particulas_estela != null:
		particulas_estela.emitting = false
