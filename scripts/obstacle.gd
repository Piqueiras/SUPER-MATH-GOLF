@tool
class_name GolfObstacle
extends StaticBody2D

## Bloque obstáculo con nodos visuales (Sombra, Cuerpo, Bisel) y CollisionShape2D real

@export var rect_size: Vector2 = Vector2(40, 100):
	set(val):
		rect_size = val
		_actualizar_geometria()

@export var fill_color: Color = Color(0.48, 0.28, 0.16):
	set(val):
		fill_color = val
		if cuerpo != null:
			cuerpo.color = fill_color

@export var border_color: Color = Color(0.30, 0.15, 0.08)

@export_group("Referencias de Nodos")
@export var cuerpo: ColorRect
@export var sombra: ColorRect
@export var borde: Line2D
@export var collision_shape: CollisionShape2D

func _ready() -> void:
	_actualizar_geometria()

func get_rect2() -> Rect2:
	return Rect2(global_position - rect_size * 0.5, rect_size)

func _actualizar_geometria() -> void:
	var half = rect_size * 0.5
	
	if cuerpo != null:
		cuerpo.position = -half
		cuerpo.size = rect_size
		cuerpo.color = fill_color
	
	if sombra != null:
		sombra.position = -half + Vector2(3, 4)
		sombra.size = rect_size
	
	if borde != null:
		borde.points = PackedVector2Array([
			-half,
			Vector2(half.x, -half.y),
			half,
			Vector2(-half.x, half.y),
			-half
		])
		borde.default_color = border_color
	
	if collision_shape != null:
		if collision_shape.shape is RectangleShape2D:
			collision_shape.shape.size = rect_size
		else:
			var rect_shape = RectangleShape2D.new()
			rect_shape.size = rect_size
			collision_shape.shape = rect_shape
