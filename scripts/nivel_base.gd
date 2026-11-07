class_name NivelGolf
extends Node2D

## Clase base para cada nivel/escena de hoyo de golf

@export_group("Información del Hoyo")
@export var titulo: String = "Hoyo 1"
@export_multiline var descripcion: String = "Descripción del hoyo"
@export var ecuacion_sugerida: String = "0"
@export var par: int = 1

@export_group("Parámetros de Juego")
@export var limites: Rect2 = Rect2(80, 70, 1120, 460)
@export_range(0.1, 0.95, 0.01) var sweet_spot_centro: float = 0.8
@export_range(0.05, 0.3, 0.01) var sweet_spot_ancho: float = 0.16

@export_group("Referencias de Nodos")
@export var posicion_inicio: Marker2D
@export var hoyo: Node2D
@export var contenedor_obstaculos: Node2D

func get_start_position() -> Vector2:
	if posicion_inicio != null:
		return posicion_inicio.global_position
	return Vector2(200, 300)

func get_hole_position() -> Vector2:
	if hoyo != null:
		return hoyo.global_position
	return Vector2(600, 300)

func get_obstacles_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var target_parent = contenedor_obstaculos if contenedor_obstaculos != null else self
	for child in target_parent.get_children():
		if child is GolfObstacle:
			rects.append(child.get_rect2())
		elif child.has_method("get_rect2"):
			rects.append(child.get_rect2())
	return rects

