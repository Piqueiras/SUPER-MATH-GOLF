class_name MainGame
extends Node2D

## Controlador de Escena Principal: orquesta la carga de niveles, la bola, la cuadrícula y la interfaz

@export_group("Niveles del Juego")
## Array de escenas de niveles para instanciar dinámicamente
@export var niveles: Array[PackedScene] = []

@export_group("Referencias de Nodos Principales")
@export var contenedor_nivel: Node2D
@export var bola: GolfBall
@export var cuadricula: CartesianGrid
@export var visualizador: TrajectoryVisualizer
@export var interfaz: CanvasLayer

# Estado del juego
var _nivel_actual: int = 1
var _nivel_instanciado: Node2D = null
var _golpes: int = 0
var _esta_disparando: bool = false
var _trayectoria_actual: Dictionary = {}

# Módulos matemáticos
var _evaluador: MathEvaluator = MathEvaluator.new()
var _calc_trayectoria: TrajectoryCalculator = TrajectoryCalculator.new()

func _ready() -> void:
	# Conexión limpia de señales entre componentes desacoplados
	if bola != null:
		bola.movement_finished.connect(_on_ball_movement_finished)
		bola.entered_hole_event.connect(_on_ball_entered_hole)
	
	if interfaz != null:
		interfaz.formula_cambiada.connect(_on_formula_cambiada)
		interfaz.potencia_actualizada.connect(_on_potencia_actualizada)
		interfaz.disparo_soltado.connect(_on_disparo_soltado)
		interfaz.solicitar_reiniciar.connect(_reiniciar_nivel)
		interfaz.solicitar_siguiente_hoyo.connect(_siguiente_nivel)
		interfaz.solicitar_anterior_hoyo.connect(_anterior_nivel)
	
	# Cargar el primer nivel usando call_deferred para evitar problemas de jerarquía
	_crear_nivel.call_deferred(_nivel_actual)

# ==========================================
# GESTIÓN Y CICLO DE VIDA DE NIVELES
# ==========================================

func _crear_nivel(numero_nivel: int) -> void:
	if numero_nivel < 1 or numero_nivel > niveles.size():
		return
	
	_eliminar_nivel()
	
	var escena_nivel = niveles[numero_nivel - 1]
	if escena_nivel == null:
		return
	
	_nivel_instanciado = escena_nivel.instantiate()
	if contenedor_nivel != null:
		contenedor_nivel.add_child(_nivel_instanciado)
	else:
		add_child(_nivel_instanciado)
	
	_nivel_actual = numero_nivel
	_golpes = 0
	_esta_disparando = false
	
	# Extraer datos y posiciones del nivel instanciado
	var pos_inicio = _nivel_instanciado.get_start_position()
	var limites = _nivel_instanciado.limites
	
	# Configurar escenario y cuadrícula
	if cuadricula != null:
		cuadricula.set_bounds(limites)
		cuadricula.set_origin(pos_inicio)
	
	# Posicionar y reiniciar la bola
	if bola != null:
		bola.reset_to(pos_inicio)
	
	# Configurar interfaz de usuario
	if interfaz != null:
		interfaz.configurar_nivel(
			_nivel_instanciado.titulo,
			_nivel_instanciado.descripcion,
			_nivel_instanciado.ecuacion_sugerida,
			_nivel_instanciado.sweet_spot_centro,
			_nivel_instanciado.sweet_spot_ancho,
			_nivel_instanciado.par,
			_nivel_actual == 1,
			_nivel_actual == niveles.size()
		)
		interfaz.bloquear_controles(false)

func _eliminar_nivel() -> void:
	if _nivel_instanciado != null:
		_nivel_instanciado.queue_free()
		_nivel_instanciado = null

func _reiniciar_nivel() -> void:
	if _esta_disparando:
		return
	_eliminar_nivel()
	_crear_nivel.call_deferred(_nivel_actual)

func _siguiente_nivel() -> void:
	if _esta_disparando:
		return
	if _nivel_actual < niveles.size():
		_eliminar_nivel()
		_crear_nivel.call_deferred(_nivel_actual + 1)
	else:
		# Volver al inicio si terminó todos los niveles
		_eliminar_nivel()
		_crear_nivel.call_deferred(1)

func _anterior_nivel() -> void:
	if _esta_disparando:
		return
	if _nivel_actual > 1:
		_eliminar_nivel()
		_crear_nivel.call_deferred(_nivel_actual - 1)

# ==========================================
# CÁLCULO DE FÓRMULA Y TRAYECTORIA
# ==========================================

func _on_formula_cambiada(texto_formula: String) -> void:
	var parse_result = _evaluador.parse_formula(texto_formula)
	if interfaz != null:
		interfaz.establecer_estado_formula(parse_result.valid, parse_result.error)
	
	if parse_result.valid:
		_recalcular_trayectoria()
	else:
		if visualizador != null:
			visualizador.clear()

func _recalcular_trayectoria() -> void:
	if not _evaluador.is_valid() or _nivel_instanciado == null or bola == null:
		if visualizador != null:
			visualizador.clear()
		return
	
	var obs_rects = _nivel_instanciado.get_obstacles_rects()
	var limites = _nivel_instanciado.limites
	
	_trayectoria_actual = _calc_trayectoria.calculate_trajectory(
		_evaluador,
		bola.global_position,
		limites,
		obs_rects,
		550.0,
		60.0
	)
	
	if visualizador != null:
		visualizador.update_trajectory(
			_trayectoria_actual.points,
			_evaluador.is_valid(),
			_trayectoria_actual.hit_obstacle,
			_trayectoria_actual.collision_points,
			_calc_trayectoria.total_arc_length
		)
		visualizador.set_power_preview(
			0.0,
			false,
			_nivel_instanciado.sweet_spot_centro,
			_nivel_instanciado.sweet_spot_ancho
		)

func _on_potencia_actualizada(potencia: float, cargando: bool) -> void:
	if visualizador != null and _nivel_instanciado != null:
		visualizador.set_power_preview(
			potencia,
			cargando,
			_nivel_instanciado.sweet_spot_centro,
			_nivel_instanciado.sweet_spot_ancho
		)

# ==========================================
# DISPARO Y GESTIÓN DE LA BOLA
# ==========================================

func _on_disparo_soltado(potencia: float, es_sweet_spot: bool) -> void:
	if _esta_disparando or not _evaluador.is_valid() or _nivel_instanciado == null:
		return
	
	if _trayectoria_actual.is_empty() or _trayectoria_actual.points.size() < 2:
		_recalcular_trayectoria()
	
	_esta_disparando = true
	_golpes += 1
	
	if visualizador != null and _nivel_instanciado != null:
		visualizador.set_power_preview(
			0.0,
			false,
			_nivel_instanciado.sweet_spot_centro,
			_nivel_instanciado.sweet_spot_ancho
		)
	
	if interfaz != null:
		interfaz.bloquear_controles(true)
		interfaz.actualizar_puntuacion(_golpes, _nivel_instanciado.par)
		if es_sweet_spot:
			interfaz.etiqueta_estado.text = "⚡ ¡POTENCIA ÓPTIMA (SWEET SPOT)!"
			interfaz.etiqueta_estado.modulate = Color(0.2, 1.0, 0.4)
		else:
			interfaz.etiqueta_estado.text = "Tiro realizado (%d%% potencia)" % int(potencia * 100.0)
			interfaz.etiqueta_estado.modulate = Color(0.9, 0.9, 0.9)
	
	var pos_hoyo = _nivel_instanciado.get_hole_position()
	bola.start_shot(
		_trayectoria_actual.points,
		potencia,
		pos_hoyo,
		_calc_trayectoria.total_arc_length
	)

func _on_ball_movement_finished(final_pos: Vector2, in_hole: bool) -> void:
	_esta_disparando = false
	if interfaz != null:
		interfaz.bloquear_controles(false)
	
	if not in_hole:
		if cuadricula != null:
			cuadricula.set_origin(final_pos)
		_recalcular_trayectoria()

func _on_ball_entered_hole() -> void:
	if interfaz != null:
		interfaz.mostrar_victoria(_golpes, _nivel_actual == niveles.size())
