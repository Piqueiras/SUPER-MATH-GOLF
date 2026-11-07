class_name PowerMeter
extends Control

## Minijuego de potencia oscilante tipo golf clásico al mantener pulsado

signal power_changed(current_power: float)
signal shot_released(power: float, is_sweet_spot: bool)

@export var cycle_speed: float = 1.5 # Ciclos de ida y vuelta por segundo
@export var sweet_spot_center: float = 0.82
@export var sweet_spot_width: float = 0.16

var is_charging: bool = false
var current_power: float = 0.0
var _direction: float = 1.0
var _anim_t: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(250, 48)
	queue_redraw()

func set_sweet_spot(center: float, width: float = 0.16) -> void:
	sweet_spot_center = clamp(center, 0.15, 0.95)
	sweet_spot_width = clamp(width, 0.08, 0.25)
	queue_redraw()

func start_charging() -> void:
	if is_charging:
		return
	is_charging = true
	current_power = 0.0
	_direction = 1.0
	_anim_t = 0.0
	queue_redraw()

func release_power() -> float:
	if not is_charging:
		return current_power
	is_charging = false
	var in_sweet_spot = is_in_sweet_spot()
	shot_released.emit(current_power, in_sweet_spot)
	queue_redraw()
	return current_power

func cancel_charging() -> void:
	is_charging = false
	current_power = 0.0
	queue_redraw()

func is_in_sweet_spot() -> bool:
	return abs(current_power - sweet_spot_center) <= (sweet_spot_width * 0.5)

func _process(delta: float) -> void:
	if not is_charging:
		return
	
	_anim_t += delta * cycle_speed * TAU
	# Oscilación suave ping-pong entre 0.0 y 1.0
	# Usando seno mapeado a [0, 1]
	current_power = 0.5 - 0.5 * cos(_anim_t)
	power_changed.emit(current_power)
	queue_redraw()

func _draw() -> void:
	var font = ThemeDB.fallback_font
	var w = size.x
	var h = 26.0
	var bar_y = 20.0
	
	# Etiqueta superior
	var label_text = "POTENCIA (Mantén y suelta en la zona verde)"
	if is_charging:
		if is_in_sweet_spot():
			label_text = "¡ZONA ÓPTIMA! (¡SUELTA YA!)"
		else:
			label_text = "Cargando... %d%%" % int(current_power * 100.0)
	
	var label_col = Color(0.2, 0.9, 0.3) if (is_charging and is_in_sweet_spot()) else Color(0.9, 0.92, 0.95)
	draw_string(font, Vector2(0, 14), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, label_col)
	
	# Marco de fondo de la barra
	var bg_rect = Rect2(0, bar_y, w, h)
	draw_rect(bg_rect, Color(0.12, 0.14, 0.18), true)
	
	# Zona general de la barra (degradado visual suave o segmentos)
	# Zona izquierda (baja potencia / corto)
	var sw_start = clamp(sweet_spot_center - sweet_spot_width * 0.5, 0.0, 1.0) * w
	var sw_end = clamp(sweet_spot_center + sweet_spot_width * 0.5, 0.0, 1.0) * w
	
	# Tramo bajo (amarillo / naranja)
	draw_rect(Rect2(0, bar_y, sw_start, h), Color(0.7, 0.5, 0.15, 0.75), true)
	
	# Tramo ÓPTIMO (SWEET SPOT - Verde brillante)
	var sw_rect = Rect2(sw_start, bar_y, sw_end - sw_start, h)
	draw_rect(sw_rect, Color(0.18, 0.85, 0.35, 0.9), true)
	
	# Tramo alto / pasado (rojo / sobrepasado)
	draw_rect(Rect2(sw_end, bar_y, w - sw_end, h), Color(0.8, 0.25, 0.2, 0.75), true)
	
	# Barra de progreso actual si está cargando
	if current_power > 0.001:
		var fill_w = current_power * w
		var fill_col = Color(1.0, 1.0, 1.0, 0.25)
		draw_rect(Rect2(0, bar_y, fill_w, h), fill_col, true)
	
	# Cursor / Aguja indicadora
	var needle_x = current_power * w
	var needle_col = Color(1, 1, 1) if not is_in_sweet_spot() else Color(1, 1, 0.3)
	draw_line(Vector2(needle_x, bar_y - 2), Vector2(needle_x, bar_y + h + 2), needle_col, 3.0)
	
	# Triángulo puntero sobre la aguja
	var arrow_pts = PackedVector2Array([
		Vector2(needle_x - 4, bar_y - 5),
		Vector2(needle_x + 4, bar_y - 5),
		Vector2(needle_x, bar_y - 1)
	])
	draw_colored_polygon(arrow_pts, needle_col)
	
	# Bordes de la barra
	draw_rect(bg_rect, Color(0.4, 0.45, 0.5), false, 2.0)
	# Marcas de sweet spot
	draw_line(Vector2(sw_start, bar_y), Vector2(sw_start, bar_y + h), Color(1, 1, 1, 0.8), 1.5)
	draw_line(Vector2(sw_end, bar_y), Vector2(sw_end, bar_y + h), Color(1, 1, 1, 0.8), 1.5)
