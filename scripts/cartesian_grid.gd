class_name CartesianGrid
extends Node2D

## Dibuja el césped del campo, la cuadrícula cartesiana centrada en la bola
## con marcas numéricas de unidades y los ejes +X y +Y.

@export var unit_scale: float = 60.0 # Píxeles por unidad matemática
@export var bounds: Rect2 = Rect2(80, 40, 1120, 520)

var origin_pos: Vector2 = Vector2(200, 300)
var _default_font: Font = null

func _ready() -> void:
	_default_font = ThemeDB.fallback_font
	queue_redraw()

func set_origin(pos: Vector2) -> void:
	origin_pos = pos
	queue_redraw()

func set_bounds(new_bounds: Rect2) -> void:
	bounds = new_bounds
	queue_redraw()

func _draw() -> void:
	# 1. Fondo del césped (Green de minigolf)
	_draw_course_green()
	
	# 2. Cuadrícula cartesiana sutil
	_draw_grid()
	
	# 3. Ejes cartesianos X e Y centrados en la bola
	_draw_axes()
	
	# 4. Bordes/Paredes exteriores del campo
	_draw_course_borders()

func _draw_course_green() -> void:
	# Sombra suave bajo el campo
	draw_rect(bounds.grow(6.0), Color(0, 0, 0, 0.3), true)
	
	# Césped base (verde esmeralda suave)
	draw_rect(bounds, Color(0.20, 0.55, 0.28), true)
	
	# Rayas de corte de césped sutiles alternadas
	var stripe_w = 40.0
	var count = int(bounds.size.x / stripe_w) + 1
	for i in range(count):
		if i % 2 == 0:
			var s_rect = Rect2(
				bounds.position.x + i * stripe_w,
				bounds.position.y,
				min(stripe_w, bounds.end.x - (bounds.position.x + i * stripe_w)),
				bounds.size.y
			)
			draw_rect(s_rect, Color(0.18, 0.52, 0.26, 0.45), true)

func _draw_grid() -> void:
	var grid_col = Color(1.0, 1.0, 1.0, 0.08)
	var major_grid_col = Color(1.0, 1.0, 1.0, 0.16)
	
	# Líneas verticales paralelas al eje Y (a pasos de unit_scale desde origin_pos.x)
	var x_offset = origin_pos.x
	# Hacia la derecha
	var x = x_offset
	var step_idx = 0
	while x <= bounds.end.x:
		if x >= bounds.position.x:
			var col = major_grid_col if step_idx % 5 == 0 else grid_col
			draw_line(Vector2(x, bounds.position.y), Vector2(x, bounds.end.y), col, 1.0)
		x += unit_scale
		step_idx += 1
	
	# Hacia la izquierda
	x = x_offset - unit_scale
	step_idx = 1
	while x >= bounds.position.x:
		var col = major_grid_col if step_idx % 5 == 0 else grid_col
		draw_line(Vector2(x, bounds.position.y), Vector2(x, bounds.end.y), col, 1.0)
		x -= unit_scale
		step_idx += 1
	
	# Líneas horizontales paralelas al eje X (a pasos de unit_scale desde origin_pos.y)
	var y_offset = origin_pos.y
	# Hacia arriba
	var y = y_offset
	step_idx = 0
	while y >= bounds.position.y:
		if y <= bounds.end.y:
			var col = major_grid_col if step_idx % 5 == 0 else grid_col
			draw_line(Vector2(bounds.position.x, y), Vector2(bounds.end.x, y), col, 1.0)
		y -= unit_scale
		step_idx += 1
	
	# Hacia abajo
	y = y_offset + unit_scale
	step_idx = 1
	while y <= bounds.end.y:
		var col = major_grid_col if step_idx % 5 == 0 else grid_col
		draw_line(Vector2(bounds.position.x, y), Vector2(bounds.end.x, y), col, 1.0)
		y += unit_scale
		step_idx += 1

func _draw_axes() -> void:
	var font = _default_font if _default_font != null else ThemeDB.fallback_font
	var font_size = 12
	
	# Eje X (+X hacia la derecha en cian tenue)
	var x_axis_col = Color(0.25, 0.85, 1.0, 0.75)
	var text_col = Color(0.9, 0.95, 1.0, 0.9)
	
	# Línea principal del eje X en origin_pos.y
	if origin_pos.y >= bounds.position.y and origin_pos.y <= bounds.end.y:
		draw_line(
			Vector2(bounds.position.x, origin_pos.y),
			Vector2(bounds.end.x, origin_pos.y),
			x_axis_col,
			2.0
		)
		# Flecha +X
		var arrow_x = bounds.end.x - 8.0
		var arrow_pts_x = PackedVector2Array([
			Vector2(arrow_x, origin_pos.y - 6),
			Vector2(arrow_x + 8, origin_pos.y),
			Vector2(arrow_x, origin_pos.y + 6)
		])
		draw_colored_polygon(arrow_pts_x, x_axis_col)
		draw_string(font, Vector2(arrow_x - 22, origin_pos.y - 10), "+X", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_col)
	
	# Eje Y (+Y hacia arriba en rojo suave/coral)
	var y_axis_col = Color(1.0, 0.45, 0.4, 0.75)
	if origin_pos.x >= bounds.position.x and origin_pos.x <= bounds.end.x:
		draw_line(
			Vector2(origin_pos.x, bounds.end.y),
			Vector2(origin_pos.x, bounds.position.y),
			y_axis_col,
			2.0
		)
		# Flecha +Y
		var arrow_y = bounds.position.y + 8.0
		var arrow_pts_y = PackedVector2Array([
			Vector2(origin_pos.x - 6, arrow_y),
			Vector2(origin_pos.x, arrow_y - 8),
			Vector2(origin_pos.x + 6, arrow_y)
		])
		draw_colored_polygon(arrow_pts_y, y_axis_col)
		draw_string(font, Vector2(origin_pos.x + 10, arrow_y + 14), "+Y", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_col)

	# Marcas numéricas sobre los ejes (1, 2, 3...)
	# Marcas en X (+1, +2, +3...)
	var u_idx = 1
	var mark_x = origin_pos.x + unit_scale
	while mark_x <= bounds.end.x - 25.0:
		draw_line(Vector2(mark_x, origin_pos.y - 4), Vector2(mark_x, origin_pos.y + 4), x_axis_col, 1.5)
		draw_string(font, Vector2(mark_x - 4, origin_pos.y + 16), str(u_idx), HORIZONTAL_ALIGNMENT_CENTER, -1, 10, text_col)
		mark_x += unit_scale
		u_idx += 1
		
	# Marcas en Y (+1, +2 hacia arriba, -1, -2 hacia abajo)
	# Hacia arriba (+Y)
	u_idx = 1
	var mark_y = origin_pos.y - unit_scale
	while mark_y >= bounds.position.y + 20.0:
		draw_line(Vector2(origin_pos.x - 4, mark_y), Vector2(origin_pos.x + 4, mark_y), y_axis_col, 1.5)
		draw_string(font, Vector2(origin_pos.x + 8, mark_y + 4), "+%d" % u_idx, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, text_col)
		mark_y -= unit_scale
		u_idx += 1
		
	# Hacia abajo (-Y)
	u_idx = 1
	mark_y = origin_pos.y + unit_scale
	while mark_y <= bounds.end.y - 15.0:
		draw_line(Vector2(origin_pos.x - 4, mark_y), Vector2(origin_pos.x + 4, mark_y), y_axis_col, 1.5)
		draw_string(font, Vector2(origin_pos.x + 8, mark_y + 4), "-%d" % u_idx, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, text_col)
		mark_y += unit_scale
		u_idx += 1
	
	# Indicador de origen (0,0)
	draw_circle(origin_pos, 3.5, Color(1, 1, 1, 0.9))
	draw_string(font, Vector2(origin_pos.x - 28, origin_pos.y + 16), "(0,0)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.75))

func _draw_course_borders() -> void:
	# Marco / Madera de contorno del campo (Paredes reflectoras)
	var border_col = Color(0.35, 0.22, 0.14) # Madera
	var inner_border_col = Color(0.55, 0.38, 0.26)
	
	draw_rect(bounds, border_col, false, 8.0)
	draw_rect(bounds.grow(4.0), inner_border_col, false, 2.0)

