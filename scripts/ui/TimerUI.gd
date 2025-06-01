# TimerUI.gd (solo UI)
extends Control

# Referencias a nodos
@onready var time_label: Label = $ProgressContainer/TimeLabel
@onready var progress_bar: ProgressBar = $ProgressContainer/TimeProgressBar

# Configuración visual
@export var mostrar_centesimas: bool = false

func _ready():
	# Conectar al Autoload de lógica
	TimerLogic.tiempo_cambiado.connect(_on_tiempo_cambiado)
	TimerLogic.tiempo_agotado.connect(_on_tiempo_agotado)
	
	# Configuración inicial
	progress_bar.min_value = 0
	progress_bar.max_value = TimerLogic.tiempo_inicial
	progress_bar.value = TimerLogic.tiempo_actual
	_actualizar_visuales(TimerLogic.tiempo_actual)

func _on_tiempo_cambiado(tiempo_restante: float):
	_actualizar_visuales(tiempo_restante)

func _on_tiempo_agotado():
	# Efectos especiales cuando se acaba el tiempo
	print("¡Tiempo agotado en UI!")

func _actualizar_visuales(tiempo: float):
	if not is_instance_valid(progress_bar) or not is_instance_valid(time_label):
		return
	
	# Actualizar barra de progreso
	progress_bar.value = tiempo
	
	# Actualizar texto
	time_label.text = _formatear_tiempo(tiempo)
	
	# Actualizar colores
	_actualizar_colores(tiempo)

func _formatear_tiempo(tiempo: float) -> String:
	var minutos = int(tiempo) / 60
	var segundos = int(tiempo) % 60
	
	if mostrar_centesimas:
		var centesimas = int((tiempo - int(tiempo)) * 100)
		return "%02d:%02d.%02d" % [minutos, segundos, centesimas]
	else:
		return "%02d:%02d" % [minutos, segundos]

func _actualizar_colores(tiempo: float):
	var porcentaje_restante = tiempo / TimerLogic.tiempo_inicial
	
	if porcentaje_restante > 0.5:
		progress_bar.modulate = Color.GREEN
		time_label.modulate = Color.WHITE
	elif porcentaje_restante > 0.25:
		progress_bar.modulate = Color.YELLOW
		time_label.modulate = Color.YELLOW
	else:
		progress_bar.modulate = Color.RED
		time_label.modulate = Color.RED
		
		if porcentaje_restante < 0.1:
			var alpha = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01)
			time_label.modulate.a = alpha
