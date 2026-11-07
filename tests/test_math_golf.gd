extends Node

const MathEvaluator = preload("res://scripts/math_evaluator.gd")
const TrajectoryCalculator = preload("res://scripts/trajectory_calculator.gd")

func _ready() -> void:
	print("--- INICIANDO SUITE DE TESTS: GOLF MATEMÁTICO ---")
	test_evaluator()
	test_trajectory_fixed_length()
	test_levels_logic()
	print("--- TODOS LOS TESTS PASARON CON ÉXITO ---")
	get_tree().quit(0)

func test_evaluator() -> void:
	print("[TEST] MathEvaluator...")
	var eval = MathEvaluator.new()
	
	# Casos válidos f(0) = 0
	var res0 = eval.parse_formula("0")
	assert(res0.valid, "f(x)=0 debe ser válida")
	assert(abs(eval.evaluate(5.0) - 0.0) < 0.001)
	
	var resX = eval.parse_formula("x")
	assert(resX.valid, "f(x)=x debe ser válida")
	assert(abs(eval.evaluate(3.0) - 3.0) < 0.001)
	
	var resSin = eval.parse_formula("sin(x)")
	assert(resSin.valid, "f(x)=sin(x) debe ser válida")
	assert(abs(eval.evaluate(PI / 2.0) - 1.0) < 0.001)
	
	var resCos = eval.parse_formula("cos(x) - 1")
	assert(resCos.valid, "f(x)=cos(x)-1 debe ser válida")
	assert(abs(eval.evaluate(0.0) - 0.0) < 0.001)
	
	# Auto-reemplazo de potencias y multiplicación implícita
	var resPow = eval.parse_formula("x^2")
	assert(resPow.valid, "x^2 debe convertirse a x**2")
	assert(abs(eval.evaluate(3.0) - 9.0) < 0.001)
	
	var resMult = eval.parse_formula("2x")
	assert(resMult.valid, "2x debe convertirse a 2*x")
	assert(abs(eval.evaluate(4.0) - 8.0) < 0.001)
	
	# Casos inválidos f(0) != 0
	var resFail1 = eval.parse_formula("1")
	assert(not resFail1.valid, "f(x)=1 no pasa por el origen y debe fallar")
	
	var resFail2 = eval.parse_formula("x + 5")
	assert(not resFail2.valid, "f(x)=x+5 no pasa por el origen y debe fallar")
	
	# Sintaxis inválida
	var resSyntax = eval.parse_formula("sin(")
	assert(not resSyntax.valid, "sin( tiene sintaxis inválida")
	
	print("  ✔ MathEvaluator OK")

func test_trajectory_fixed_length() -> void:
	print("[TEST] TrajectoryCalculator fixed arc length...")
	var eval = MathEvaluator.new()
	var calc = TrajectoryCalculator.new()
	var bounds = Rect2(80, 70, 1120, 460)
	var start = Vector2(200, 300)
	var target_len = 550.0
	
	# 1. Función plana f(x) = 0
	eval.parse_formula("0")
	var t0 = calc.calculate_trajectory(eval, start, bounds, [], target_len)
	assert(abs(t0.length - target_len) < 0.5, "Longitud de f(x)=0 debe ser exactamente 550px")
	
	# 2. Función sinusoidal f(x) = sin(x)
	eval.parse_formula("sin(x)")
	var tSin = calc.calculate_trajectory(eval, start, bounds, [], target_len)
	assert(abs(tSin.length - target_len) < 0.5, "Longitud de f(x)=sin(x) debe ser exactamente 550px")
	
	# 3. Función diagonal con rebote en techo f(x) = 0.7*x
	eval.parse_formula("0.7*x")
	var tSlope = calc.calculate_trajectory(eval, start, bounds, [], target_len)
	assert(abs(tSlope.length - target_len) < 0.5, "Longitud de f(x)=0.7*x con rebote debe ser exactamente 550px")
	
	print("  ✔ Fixed Arc Length (550px) OK para 0, sin(x) y 0.7*x")

func test_levels_logic() -> void:
	print("[TEST] Verificación lógica de los Hoyos...")
	var eval = MathEvaluator.new()
	var calc = TrajectoryCalculator.new()
	
	# Hoyo 2: Slalom
	var bounds2 = Rect2(80, 70, 1120, 460)
	var ball2 = Vector2(160, 300)
	var hole2 = Vector2(537, 300)
	var obstacles2: Array[Rect2] = [
		Rect2(240, 275, 28, 95),
		Rect2(240, 95, 28, 105),
		Rect2(429, 225, 28, 95),
		Rect2(429, 395, 28, 110)
	]
	
	# Probar y = 0 en Hoyo 2: DEBE chocar con obstáculo
	eval.parse_formula("0")
	var t0_h2 = calc.calculate_trajectory(eval, ball2, bounds2, obstacles2, 550.0)
	assert(t0_h2.hit_obstacle == true, "Hoyo 2: La recta 0 debe chocar contra el obstáculo")
	
	# Probar sin(x) en Hoyo 2: NO debe chocar con obstáculos
	eval.parse_formula("sin(x)")
	var tSin_h2 = calc.calculate_trajectory(eval, ball2, bounds2, obstacles2, 550.0)
	assert(tSin_h2.hit_obstacle == false, "Hoyo 2: sin(x) debe pasar sin chocar")
	
	# Comprobar que sin(x) pasa muy cerca del hoyo2
	var found_near_hole = false
	for p in tSin_h2.points:
		if p.distance_to(hole2) < 20.0:
			found_near_hole = true
			break
	assert(found_near_hole, "Hoyo 2: La trayectoria sin(x) debe alcanzar el hoyo")
	
	# Hoyo 3: Rebote en pared
	var bounds3 = Rect2(80, 137, 1120, 390)
	var ball3 = Vector2(200, 300)
	var hole3 = Vector2(510, 300)
	var obstacles3: Array[Rect2] = [
		Rect2(290, 250, 130, 170)
	]
	
	# Probar 0 en Hoyo 3: Choca contra el muro central
	eval.parse_formula("0")
	var t0_h3 = calc.calculate_trajectory(eval, ball3, bounds3, obstacles3, 550.0)
	assert(t0_h3.hit_obstacle == true, "Hoyo 3: La recta 0 debe chocar contra el muro central")
	
	# Probar x en Hoyo 3: Rebota en la pared superior y NO choca contra el muro central
	eval.parse_formula("x")
	var tBounce_h3 = calc.calculate_trajectory(eval, ball3, bounds3, obstacles3, 550.0)
	assert(tBounce_h3.hit_obstacle == false, "Hoyo 3: x debe rebotar en la pared superior y esquivar el muro")
	
	found_near_hole = false
	for p in tBounce_h3.points:
		if p.distance_to(hole3) < 25.0:
			found_near_hole = true
			break
	assert(found_near_hole, "Hoyo 3: El rebote de x debe alcanzar el hoyo")
	
	print("  ✔ Lógica de los 3 Hoyos (Llano, Slalom con sin(x), Rebote con |f(x)|) verificada al 100%")
