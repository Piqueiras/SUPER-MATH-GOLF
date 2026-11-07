class_name InterfazUsuario
extends CanvasLayer

## Gestiona la interfaz de usuario, HUD, entrada de fórmulas y barra de potencia

signal formula_cambiada(nueva_formula: String)
signal disparo_iniciado
signal disparo_soltado(potencia: float, es_sweet_spot: bool)
signal potencia_actualizada(potencia: float, cargando: bool)
signal solicitar_reiniciar
signal solicitar_siguiente_hoyo
signal solicitar_anterior_hoyo

@export_group("Textos y Feedback")
@export var campo_formula: LineEdit
@export var etiqueta_estado: Label
@export var etiqueta_titulo: Label
@export var etiqueta_descripcion: Label
@export var etiqueta_golpes: Label

@export_group("Controles de Disparo")
@export var medidor_potencia: PowerMeter
@export var boton_disparar: Button
@export var contenedor_botones_rapidos: HBoxContainer

@export_group("Navegación")
@export var boton_anterior: Button
@export var boton_reiniciar: Button
@export var boton_siguiente: Button

@export_group("Banner de Victoria")
@export var banner_victoria: PanelContainer
@export var etiqueta_victoria: Label
@export var boton_victoria_siguiente: Button

var _bloqueado: bool = false
var _espacio_presionado: bool = false

func _ready() -> void:
	if campo_formula != null:
		campo_formula.text_changed.connect(_on_formula_text_changed)
	if boton_disparar != null:
		boton_disparar.button_down.connect(_on_shoot_down)
		boton_disparar.button_up.connect(_on_shoot_up)
	if medidor_potencia != null:
		medidor_potencia.power_changed.connect(func(p):
			potencia_actualizada.emit(p, medidor_potencia.is_charging)
		)
		medidor_potencia.shot_released.connect(_on_power_meter_released)
	if boton_reiniciar != null:
		boton_reiniciar.pressed.connect(func(): solicitar_reiniciar.emit())
	if boton_siguiente != null:
		boton_siguiente.pressed.connect(func(): solicitar_siguiente_hoyo.emit())
	if boton_anterior != null:
		boton_anterior.pressed.connect(func(): solicitar_anterior_hoyo.emit())
	if boton_victoria_siguiente != null:
		boton_victoria_siguiente.pressed.connect(_on_victoria_boton_pressed)
	
	_configurar_botones_rapidos()

func _input(event: InputEvent) -> void:
	if _bloqueado:
		return
	# Atajo de teclado: Barra espaciadora para cargar y disparar
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if campo_formula != null and campo_formula.has_focus():
			return
		
		if event.is_pressed() and not event.is_echo() and not _espacio_presionado:
			_espacio_presionado = true
			_on_shoot_down()
		elif not event.is_pressed() and _espacio_presionado:
			_espacio_presionado = false
			_on_shoot_up()

func _configurar_botones_rapidos() -> void:
	if contenedor_botones_rapidos == null:
		return
	for btn in contenedor_botones_rapidos.get_children():
		if btn is Button:
			btn.pressed.connect(func():
				var f = btn.get_meta("formula", btn.text)
				if campo_formula != null:
					campo_formula.text = f
					_on_formula_text_changed(f)
			)

func _on_formula_text_changed(texto: String) -> void:
	formula_cambiada.emit(texto)

func _on_shoot_down() -> void:
	if _bloqueado or medidor_potencia == null:
		return
	disparo_iniciado.emit()
	medidor_potencia.start_charging()

func _on_shoot_up() -> void:
	if _bloqueado or medidor_potencia == null or not medidor_potencia.is_charging:
		return
	medidor_potencia.release_power()

func _on_power_meter_released(power: float, in_sweet_spot: bool) -> void:
	disparo_soltado.emit(power, in_sweet_spot)

func _on_victoria_boton_pressed() -> void:
	banner_victoria.visible = false
	solicitar_siguiente_hoyo.emit()

func configurar_nivel(
	titulo: String,
	descripcion: String,
	sugerida: String,
	sweet_centro: float,
	sweet_ancho: float,
	par: int,
	es_primero: bool,
	es_ultimo: bool
) -> void:
	if etiqueta_titulo != null:
		etiqueta_titulo.text = titulo
	if etiqueta_descripcion != null:
		etiqueta_descripcion.text = descripcion
	if medidor_potencia != null:
		medidor_potencia.set_sweet_spot(sweet_centro, sweet_ancho)
	if campo_formula != null:
		campo_formula.text = sugerida
		_on_formula_text_changed(sugerida)
	if boton_anterior != null:
		boton_anterior.disabled = es_primero
	if boton_siguiente != null:
		boton_siguiente.disabled = es_ultimo
	if banner_victoria != null:
		banner_victoria.visible = false
	
	actualizar_puntuacion(0, par)

func actualizar_puntuacion(golpes: int, par: int) -> void:
	if etiqueta_golpes != null:
		etiqueta_golpes.text = "Golpes: %d | Par: %d" % [golpes, par]

func establecer_estado_formula(valida: bool, mensaje: String) -> void:
	if etiqueta_estado != null:
		if valida:
			etiqueta_estado.text = "✔ Ecuación válida: f(0) = 0"
			etiqueta_estado.modulate = Color(0.3, 0.95, 0.4)
		else:
			etiqueta_estado.text = "⚠ %s" % mensaje
			etiqueta_estado.modulate = Color(1.0, 0.4, 0.3)
	
	if boton_disparar != null and not _bloqueado:
		boton_disparar.disabled = not valida

func bloquear_controles(bloquear: bool) -> void:
	_bloqueado = bloquear
	if campo_formula != null:
		campo_formula.editable = not bloquear
	if boton_disparar != null:
		boton_disparar.disabled = bloquear

func mostrar_victoria(golpes: int, es_ultimo: bool) -> void:
	if banner_victoria == null:
		return
	if etiqueta_victoria != null:
		etiqueta_victoria.text = "¡HOLE IN ONE!" if golpes == 1 else "¡EMBOCADO EN %d GOLPES!" % golpes
	if boton_victoria_siguiente != null:
		boton_victoria_siguiente.text = "Jugar de Nuevo ↺" if es_ultimo else "Siguiente Hoyo ▶"
	banner_victoria.visible = true

func ocultar_victoria() -> void:
	if banner_victoria != null:
		banner_victoria.visible = false

