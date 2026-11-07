class_name MathEvaluator
extends RefCounted

## Evaluador de funciones matemáticas f(x) con validación de paso por el origen (0,0)

var _expression: Expression = Expression.new()
var _raw_formula: String = ""
var _parsed_formula: String = ""
var _is_valid: bool = false
var _error_message: String = ""

# Constantes matemáticas accesibles directamente en la expresión
var e: float = 2.718281828459045
var E: float = 2.718281828459045
var pi: float = PI
var PI_CONST: float = PI
var tau: float = TAU

func parse_formula(raw_input: String) -> Dictionary:
	_raw_formula = raw_input.strip_edges()
	_error_message = ""
	_is_valid = false
	
	if _raw_formula.is_empty():
		_error_message = "Introduce una función f(x)"
		return {"valid": false, "error": _error_message, "parsed": ""}
	
	# Normalizar texto de la fórmula
	_parsed_formula = _normalize_formula(_raw_formula)
	
	# Parsear con Godot Expression
	_expression = Expression.new()
	var error = _expression.parse(_parsed_formula, PackedStringArray(["x"]))
	if error != OK:
		_error_message = "Error de sintaxis: %s" % _expression.get_error_text()
		return {"valid": false, "error": _error_message, "parsed": _parsed_formula}
	
	# Probar evaluación en x = 0
	var test_f0 = _expression.execute([0.0], self)
	if _expression.has_execute_failed():
		_error_message = "Error de ejecución al evaluar f(0)"
		return {"valid": false, "error": _error_message, "parsed": _parsed_formula}
	
	if typeof(test_f0) != TYPE_FLOAT and typeof(test_f0) != TYPE_INT:
		_error_message = "La función debe devolver un número"
		return {"valid": false, "error": _error_message, "parsed": _parsed_formula}
	
	var f0: float = float(test_f0)
	if is_nan(f0) or is_inf(f0):
		_error_message = "f(0) no está definido (es NaN o infinito)"
		return {"valid": false, "error": _error_message, "parsed": _parsed_formula}
	
	# Validar paso por el origen f(0) == 0
	if abs(f0) > 0.001:
		_error_message = "Debe pasar por el origen: f(0) = %0.3f ≠ 0" % f0
		return {"valid": false, "error": _error_message, "parsed": _parsed_formula}
	
	_is_valid = true
	return {"valid": true, "error": "", "parsed": _parsed_formula}

func evaluate(x: float) -> Variant:
	if not _is_valid:
		return null
	var result = _expression.execute([x], self)
	if _expression.has_execute_failed():
		return null
	if typeof(result) == TYPE_FLOAT or typeof(result) == TYPE_INT:
		var val = float(result)
		if is_nan(val) or is_inf(val):
			return null
		return val
	return null

func is_valid() -> bool:
	return _is_valid

func get_error_message() -> String:
	return _error_message

func get_parsed_formula() -> String:
	return _parsed_formula

func _normalize_formula(text: String) -> String:
	var s: String = text
	
	# Quitar prefijos comunes como 'y =', 'y=', 'f(x) =', 'f(x)='
	var lower = s.to_lower()
	if lower.begins_with("y"):
		var rest = s.substr(1).strip_edges()
		if rest.begins_with("="):
			s = rest.substr(1).strip_edges()
	elif lower.begins_with("f(x)"):
		var rest = s.substr(4).strip_edges()
		if rest.begins_with("="):
			s = rest.substr(1).strip_edges()
	
	# Reemplazar operador potencia '^' por '**'
	s = s.replace("^", "**")
	
	# Reemplazar 'pi' y 'tau' por valores numéricos literales para compatibilidad
	# Usar expresiones regulares simples o reemplazos cuidadosos
	var regex_pi = RegEx.new()
	regex_pi.compile("(?i)\\bpi\\b")
	s = regex_pi.sub(s, str(PI), true)
	
	var regex_tau = RegEx.new()
	regex_tau.compile("(?i)\\btau\\b")
	s = regex_tau.sub(s, str(TAU), true)
	
	# Insertar '*' en multiplicación implícita (ej. 2x -> 2*x, 3sin -> 3*sin, )x -> )*x)
	var regex_mult1 = RegEx.new()
	regex_mult1.compile("(\\d)([a-zA-Z\\(])")
	s = regex_mult1.sub(s, "$1*$2", true)
	
	var regex_mult2 = RegEx.new()
	regex_mult2.compile("(\\))([a-zA-Z0-9\\(])")
	s = regex_mult2.sub(s, "$1*$2", true)
	
	var regex_mult3 = RegEx.new()
	regex_mult3.compile("(?i)(x)([a-zA-Z\\(])")
	# Cuidado: no romper funciones que contengan 'x' como 'exp'
	# Solo si 'x' va seguido de '(' o número
	var regex_x_paren = RegEx.new()
	regex_x_paren.compile("(?i)\\bx\\s*\\(")
	s = regex_x_paren.sub(s, "x*(", true)

	return s

