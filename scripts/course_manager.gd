class_name CourseManager
extends Node2D

## Administra los hoyos, posición de inicio, hoyo de destino y obstáculos de cada nivel

const CartesianGrid = preload("res://scripts/cartesian_grid.gd")
const GolfBall = preload("res://scripts/ball.gd")
const GolfHole = preload("res://scripts/hole.gd")
const GolfObstacle = preload("res://scripts/obstacle.gd")

signal hole_completed(hole_index: int, strokes: int)
signal score_updated(strokes: int, par: int)

var current_hole_index: int = 0
var current_strokes: int = 0
var total_strokes: int = 0
var _holes: Array[Dictionary] = []

@onready var grid: CartesianGrid = null
@onready var ball: GolfBall = null
@onready var hole: GolfHole = null
@onready var obstacle_container: Node2D = null

func setup_courses(
	grid_node: CartesianGrid,
	ball_node: GolfBall,
	hole_node: GolfHole,
	obstacles_node: Node2D
) -> void:
	grid = grid_node
	ball = ball_node
	hole = hole_node
	obstacle_container = obstacles_node
	_build_levels()
	load_hole(0)

func _build_levels() -> void:
	_holes.clear()
	
	# ==========================================
	# HOYO 1: RECTA PLANA
	# ==========================================
	var bounds1 = Rect2(80, 70, 1120, 460)
	var ball1 = Vector2(220, 300)
	var hole1 = Vector2(660, 300) # Distancia = 440 px
	var obstacles1: Array[Rect2] = []
	
	_holes.append({
		"title": "Hoyo 1: Recta Plana",
		"description": "¡El clásico tiro directo! Prueba f(x) = 0 y suelta la barra en la zona verde.",
		"hint": "Ecuación: 0",
		"suggested": "0",
		"ball_start": ball1,
		"hole_pos": hole1,
		"bounds": bounds1,
		"obstacles": obstacles1,
		"par": 1,
		"sweet_spot_center": 0.80 # 440 / 550
	})
	
	# ==========================================
	# HOYO 2: SLALOM SINUSOIDAL
	# ==========================================
	var bounds2 = Rect2(80, 70, 1120, 460)
	var ball2 = Vector2(160, 300)
	# sin(x) con scale=60px:
	# x=pi/2=1.57 -> X=254, Y=240 (pasa por arriba)
	# x=3pi/2=4.71 -> X=443, Y=360 (pasa por abajo)
	# x=2pi=6.28 -> X=537, Y=300 (Hoyo)
	var hole2 = Vector2(537, 300)
	
	var obstacles2: Array[Rect2] = [
		# Primer par de barreras en X = 254 (deja paso solo arriba en Y ~ 240)
		Rect2(240, 275, 28, 95),  # Bloque central/inferior
		Rect2(240, 95, 28, 105),  # Bloque superior
		
		# Segundo par de barreras en X = 443 (deja paso solo abajo en Y ~ 360)
		Rect2(429, 225, 28, 95),  # Bloque central/superior
		Rect2(429, 395, 28, 110), # Bloque inferior
	]
	
	_holes.append({
		"title": "Hoyo 2: Slalom Sinusoidal",
		"description": "¡Muros escalonados! Una recta o diagonal chocará; solo sin(x) oscila entre las aperturas.",
		"hint": "Ecuación: sin(x)",
		"suggested": "sin(x)",
		"ball_start": ball2,
		"hole_pos": hole2,
		"bounds": bounds2,
		"obstacles": obstacles2,
		"par": 1,
		"sweet_spot_center": 0.83 # 458 / 550
	})
	
	# ==========================================
	# HOYO 3: REBOTE EN PARED (VALOR ABSOLUTO)
	# ==========================================
	# Campo con pared superior en Y = 137
	var bounds3 = Rect2(80, 137, 1120, 390)
	var ball3 = Vector2(200, 300)
	var hole3 = Vector2(510, 300)
	
	# Muro central que bloquea cualquier disparo directo horizontal o bajo
	var obstacles3: Array[Rect2] = [
		Rect2(290, 250, 130, 170)
	]
	
	_holes.append({
		"title": "Hoyo 3: Rebote en Pared (|f(x)|)",
		"description": "¡Un muro bloquea el tiro recto! Usa la diagonal f(x) = x para rebotar en la pared superior y embocar.",
		"hint": "Ecuación: x",
		"suggested": "x",
		"ball_start": ball3,
		"hole_pos": hole3,
		"bounds": bounds3,
		"obstacles": obstacles3,
		"par": 1,
		"sweet_spot_center": 0.80
	})

func get_current_hole_data() -> Dictionary:
	if current_hole_index < 0 or current_hole_index >= _holes.size():
		return {}
	return _holes[current_hole_index]

func load_hole(index: int) -> void:
	if index < 0 or index >= _holes.size():
		return
	current_hole_index = index
	current_strokes = 0
	
	var data = _holes[current_hole_index]
	
	# Configurar cuadrícula y límites
	grid.set_bounds(data.bounds)
	grid.set_origin(data.ball_start)
	
	# Configurar bola y hoyo
	ball.reset_to(data.ball_start)
	hole.global_position = data.hole_pos
	
	# Configurar obstáculos visuales
	_spawn_obstacles(data.obstacles)
	
	score_updated.emit(current_strokes, data.par)

func next_hole() -> bool:
	if current_hole_index + 1 < _holes.size():
		load_hole(current_hole_index + 1)
		return true
	return false

func restart_current_hole() -> void:
	load_hole(current_hole_index)

func record_stroke() -> void:
	current_strokes += 1
	total_strokes += 1
	var data = get_current_hole_data()
	score_updated.emit(current_strokes, data.par)

func mark_hole_complete() -> void:
	hole_completed.emit(current_hole_index, current_strokes)

func _spawn_obstacles(obs_rects: Array[Rect2]) -> void:
	# Limpiar obstáculos anteriores
	for child in obstacle_container.get_children():
		child.queue_free()
	
	for r in obs_rects:
		var obs = GolfObstacle.new()
		obs.global_position = r.get_center()
		obs.rect_size = r.size
		obs.fill_color = Color(0.42, 0.25, 0.15)
		obs.border_color = Color(0.24, 0.12, 0.06)
		obstacle_container.add_child(obs)
