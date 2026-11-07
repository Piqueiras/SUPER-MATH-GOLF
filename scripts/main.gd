class_name MainGame
extends Node2D

## Controlador principal de Golf Matemático

const MathEvaluator = preload("res://scripts/math_evaluator.gd")
const TrajectoryCalculator = preload("res://scripts/trajectory_calculator.gd")
const CartesianGrid = preload("res://scripts/cartesian_grid.gd")
const TrajectoryVisualizer = preload("res://scripts/trajectory_visualizer.gd")
const GolfHole = preload("res://scripts/hole.gd")
const GolfBall = preload("res://scripts/ball.gd")
const CourseManager = preload("res://scripts/course_manager.gd")
const PowerMeter = preload("res://scripts/power_meter.gd")

# Componentes de la lógica
var evaluator: MathEvaluator = MathEvaluator.new()
var trajectory_calc: TrajectoryCalculator = TrajectoryCalculator.new()

# Nodos de la escena
@onready var grid: CartesianGrid = $GameWorld/CartesianGrid
@onready var visualizer: TrajectoryVisualizer = $GameWorld/TrajectoryVisualizer
@onready var obstacles_node: Node2D = $GameWorld/Obstacles
@onready var hole: GolfHole = $GameWorld/Hole
@onready var ball: GolfBall = $GameWorld/Ball
@onready var course_mgr: CourseManager = $CourseManager

# Nodos de UI
@onready var formula_input: LineEdit = %FormulaInput
@onready var status_label: Label = %StatusLabel
@onready var hole_title_label: Label = %HoyoTitleLabel
@onready var hole_desc_label: Label = %HoyoDescLabel
@onready var strokes_label: Label = %StrokesLabel
@onready var power_meter: PowerMeter = %PowerMeter
@onready var shoot_button: Button = %ShootButton
@onready var next_button: Button = %NextHoleButton
@onready var reset_button: Button = %ResetHoleButton
@onready var prev_button: Button = %PrevHoleButton
@onready var victory_banner: PanelContainer = %VictoryBanner
@onready var victory_label: Label = %VictoryLabel
@onready var victory_next_btn: Button = %VictoryNextButton

var _current_trajectory: Dictionary = {}
var _is_shooting: bool = false
var _space_pressed: bool = false

func _ready() -> void:
	# Conectar señales de la bola y del campo
	ball.movement_finished.connect(_on_ball_movement_finished)
	ball.entered_hole_event.connect(_on_ball_entered_hole)
	course_mgr.score_updated.connect(_on_score_updated)
	power_meter.shot_released.connect(_on_power_shot_released)
	
	# Conectar botones de UI
	formula_input.text_changed.connect(_on_formula_text_changed)
	shoot_button.button_down.connect(_on_shoot_button_down)
	shoot_button.button_up.connect(_on_shoot_button_up)
	reset_button.pressed.connect(_on_reset_pressed)
	next_button.pressed.connect(_on_next_hole_pressed)
	prev_button.pressed.connect(_on_prev_hole_pressed)
	victory_next_btn.pressed.connect(_on_victory_next_pressed)
	
	# Botones rápidos de fórmulas
	_setup_quick_buttons()
	
	# Iniciar campos
	course_mgr.setup_courses(grid, ball, hole, obstacles_node)
	_load_current_hole_ui()

func _input(event: InputEvent) -> void:
	# Permitir usar la barra espaciadora para el minijuego de potencia
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if formula_input.has_focus():
			return # Si está escribiendo en el campo de texto, dejar que ponga espacios
		
		if event.is_pressed() and not event.is_echo() and not _space_pressed:
			_space_pressed = true
			_on_shoot_button_down()
		elif not event.is_pressed() and _space_pressed:
			_space_pressed = false
			_on_shoot_button_up()

func _load_current_hole_ui() -> void:
	victory_banner.visible = false
	var data = course_mgr.get_current_hole_data()
	if data.is_empty():
		return
	
	hole_title_label.text = data.title
	hole_desc_label.text = data.description
	power_meter.set_sweet_spot(data.sweet_spot_center, 0.16)
	
	# Poner la fórmula sugerida inicial
	formula_input.text = data.suggested
	_on_formula_text_changed(data.suggested)
	
	prev_button.disabled = (course_mgr.current_hole_index == 0)
	next_button.disabled = (course_mgr.current_hole_index >= course_mgr._holes.size() - 1)

func _setup_quick_buttons() -> void:
	var quick_container = %QuickButtons
	if not quick_container:
		return
	for btn in quick_container.get_children():
		if btn is Button:
			btn.pressed.connect(func():
				var f = btn.get_meta("formula", btn.text)
				formula_input.text = f
				_on_formula_text_changed(f)
			)

func _on_formula_text_changed(new_text: String) -> void:
	var parse_result = evaluator.parse_formula(new_text)
	
	if parse_result.valid:
		status_label.text = "✔ Ecuación válida: f(0) = 0"
		status_label.modulate = Color(0.3, 0.95, 0.4)
		shoot_button.disabled = _is_shooting
		_recalculate_trajectory()
	else:
		status_label.text = "⚠ %s" % parse_result.error
		status_label.modulate = Color(1.0, 0.4, 0.3)
		visualizer.clear()
		shoot_button.disabled = true

func _recalculate_trajectory() -> void:
	if not evaluator.is_valid():
		visualizer.clear()
		return
	
	var data = course_mgr.get_current_hole_data()
	var obstacles: Array[Rect2] = data.obstacles
	var bounds: Rect2 = data.bounds
	
	_current_trajectory = trajectory_calc.calculate_trajectory(
		evaluator,
		ball.global_position,
		bounds,
		obstacles,
		550.0, # Longitud de arco fija
		60.0   # Escala por unidad matemática
	)
	
	visualizer.update_trajectory(
		_current_trajectory.points,
		evaluator.is_valid(),
		_current_trajectory.hit_obstacle,
		_current_trajectory.collision_points
	)

func _on_shoot_button_down() -> void:
	if _is_shooting or not evaluator.is_valid():
		return
	power_meter.start_charging()

func _on_shoot_button_up() -> void:
	if _is_shooting or not power_meter.is_charging:
		return
	power_meter.release_power()

func _on_power_shot_released(power: float, is_sweet_spot: bool) -> void:
	if _is_shooting or not evaluator.is_valid():
		return
	
	if _current_trajectory.is_empty() or _current_trajectory.points.size() < 2:
		_recalculate_trajectory()
	
	_is_shooting = true
	shoot_button.disabled = true
	formula_input.editable = false
	course_mgr.record_stroke()
	
	if is_sweet_spot:
		status_label.text = "⚡ ¡POTENCIA ÓPTIMA (SWEET SPOT)!"
		status_label.modulate = Color(0.2, 1.0, 0.4)
	else:
		status_label.text = "Tiro realizado (%d%% potencia)" % int(power * 100.0)
		status_label.modulate = Color(0.9, 0.9, 0.9)
	
	var hole_pos = course_mgr.get_current_hole_data().hole_pos
	ball.start_shot(
		_current_trajectory.points,
		power,
		hole_pos,
		trajectory_calc.total_arc_length
	)

func _on_ball_movement_finished(final_pos: Vector2, in_hole: bool) -> void:
	_is_shooting = false
	formula_input.editable = true
	shoot_button.disabled = not evaluator.is_valid()
	
	if not in_hole:
		# Actualizar origen cartesiano a la nueva posición de la bola
		grid.set_origin(final_pos)
		_recalculate_trajectory()

func _on_ball_entered_hole() -> void:
	course_mgr.mark_hole_complete()
	victory_label.text = "¡HOLE IN ONE!" if course_mgr.current_strokes == 1 else "¡EMBOCADO EN %d GOLPES!" % course_mgr.current_strokes
	victory_banner.visible = true
	var is_last_hole = (course_mgr.current_hole_index >= course_mgr._holes.size() - 1)
	next_button.disabled = is_last_hole
	victory_next_btn.text = "Jugar de Nuevo ↺" if is_last_hole else "Siguiente Hoyo ▶"

func _on_victory_next_pressed() -> void:
	victory_banner.visible = false
	if course_mgr.current_hole_index >= course_mgr._holes.size() - 1:
		course_mgr.load_hole(0)
		_load_current_hole_ui()
	else:
		_on_next_hole_pressed()

func _on_score_updated(strokes: int, par: int) -> void:
	strokes_label.text = "Golpes: %d | Par: %d" % [strokes, par]

func _on_reset_pressed() -> void:
	if _is_shooting:
		return
	course_mgr.restart_current_hole()
	_load_current_hole_ui()

func _on_next_hole_pressed() -> void:
	if _is_shooting:
		return
	if course_mgr.next_hole():
		_load_current_hole_ui()

func _on_prev_hole_pressed() -> void:
	if _is_shooting:
		return
	if course_mgr.current_hole_index > 0:
		course_mgr.load_hole(course_mgr.current_hole_index - 1)
		_load_current_hole_ui()
