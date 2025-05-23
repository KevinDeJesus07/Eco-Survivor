extends Control
class_name TimerUI

# Señales para comunicar eventos
signal tiempo_agotado
signal tiempo_cambiado(tiempo_restante: float)
signal tiempo_agregado(cantidad: float)
signal tiempo_restado(cantidad: float)

# Configuración del temporizador
@export_group("Configuración del Tiempo")
@export var tiempo_inicial: float = 120.0  # 2 minutos por defecto
@export var tiempo_maximo_permitido: float = 300.0  # 5 minutos máximo
@export var usar_timer_nodo: bool = true  # Si usar Timer node o _process
@export var mostrar_centesimas: bool = false  # Mostrar centésimas de segundo

# Referencias a nodos
@onready var time_label: Label = $ProgressContainer/TimeLabel
@onready var progress_bar: ProgressBar = $ProgressContainer/TimeProgressBar
@onready var timer_node: Timer = $TimerNode

# Variables internas
var tiempo_maximo: float
var tiempo_actual: float
var esta_corriendo: bool = false
var tiempo_pausado: bool = false

func _ready():
	# Configuración inicial
	tiempo_maximo = tiempo_inicial
	tiempo_actual = tiempo_inicial
	
	# Configurar ProgressBar
	progress_bar.min_value = 0
	progress_bar.max_value = tiempo_maximo
	progress_bar.value = tiempo_actual
	
	# Configurar Timer si se usa
	if usar_timer_nodo and is_instance_valid(timer_node):
		timer_node.wait_time = 0.1 if mostrar_centesimas else 1.0
		timer_node.timeout.connect(_on_timer_timeout)
	
	# Actualizar visuales iniciales
	_actualizar_visuales()
	
	print("Timer UI listo. Tiempo inicial: %.1f segundos" % tiempo_inicial)

func _process(delta: float):
	# Solo usar _process si no usamos Timer node
	if not usar_timer_nodo and esta_corriendo and not tiempo_pausado:
		_decrementar_tiempo(delta)

func _on_timer_timeout():
	# Función llamada por el Timer node
	if esta_corriendo and not tiempo_pausado:
		var decremento = 0.1 if mostrar_centesimas else 1.0
		_decrementar_tiempo(decremento)

func _decrementar_tiempo(delta: float):
	tiempo_actual -= delta
	tiempo_actual = max(0.0, tiempo_actual)
	
	_actualizar_visuales()
	tiempo_cambiado.emit(tiempo_actual)
	
	# Verificar si se acabó el tiempo
	if tiempo_actual <= 0.0:
		_tiempo_terminado()

func _actualizar_visuales():
	if not is_instance_valid(progress_bar) or not is_instance_valid(time_label):
		return
	
	# Actualizar barra de progreso
	progress_bar.value = tiempo_actual
	
	# Actualizar texto
	time_label.text = _formatear_tiempo(tiempo_actual)
	
	# Cambiar color según el tiempo restante (opcional)
	_actualizar_colores()

func _formatear_tiempo(tiempo: float) -> String:
	var minutos = int(tiempo) / 60
	var segundos = int(tiempo) % 60
	
	if mostrar_centesimas:
		var centesimas = int((tiempo - int(tiempo)) * 100)
		return "%02d:%02d.%02d" % [minutos, segundos, centesimas]
	else:
		return "%02d:%02d" % [minutos, segundos]

func _actualizar_colores():
	# Cambiar colores basado en el tiempo restante
	var porcentaje_restante = tiempo_actual / tiempo_maximo
	
	if porcentaje_restante > 0.5:
		# Verde - tiempo suficiente
		progress_bar.modulate = Color.GREEN
		time_label.modulate = Color.WHITE
	elif porcentaje_restante > 0.25:
		# Amarillo - precaución
		progress_bar.modulate = Color.YELLOW
		time_label.modulate = Color.YELLOW
	else:
		# Rojo - crítico
		progress_bar.modulate = Color.RED
		time_label.modulate = Color.RED
		
		# Efecto de parpadeo cuando queda poco tiempo
		if porcentaje_restante < 0.1:
			var alpha = 0.5 + 0.5 * sin(Time.get_time_dict_from_system()["second"] * 4)
			time_label.modulate.a = alpha

func _tiempo_terminado():
	esta_corriendo = false
	if usar_timer_nodo and is_instance_valid(timer_node):
		timer_node.stop()
	
	print("¡Tiempo agotado!")
	tiempo_agotado.emit()

# --- FUNCIONES PÚBLICAS PARA INTERACTUAR CON EL TEMPORIZADOR ---

func iniciar_temporizador():
	"""Inicia la cuenta atrás del temporizador"""
	if tiempo_actual > 0:
		esta_corriendo = true
		tiempo_pausado = false
		if usar_timer_nodo and is_instance_valid(timer_node):
			timer_node.start()
		print("Temporizador iniciado")

func pausar_temporizador():
	"""Pausa el temporizador"""
	tiempo_pausado = true
	if usar_timer_nodo and is_instance_valid(timer_node):
		timer_node.paused = true
	print("Temporizador pausado")

func reanudar_temporizador():
	"""Reanuda el temporizador si estaba pausado"""
	if esta_corriendo:
		tiempo_pausado = false
		if usar_timer_nodo and is_instance_valid(timer_node):
			timer_node.paused = false
		print("Temporizador reanudado")

func detener_temporizador():
	"""Detiene completamente el temporizador"""
	esta_corriendo = false
	tiempo_pausado = false
	if usar_timer_nodo and is_instance_valid(timer_node):
		timer_node.stop()
	print("Temporizador detenido")

func reiniciar_temporizador():
	"""Reinicia el temporizador al tiempo inicial"""
	tiempo_actual = tiempo_inicial
	esta_corriendo = false
	tiempo_pausado = false
	if usar_timer_nodo and is_instance_valid(timer_node):
		timer_node.stop()
	_actualizar_visuales()
	print("Temporizador reiniciado")

func sumar_tiempo(cantidad: float):
	"""Añade tiempo al temporizador"""
	tiempo_actual += cantidad
	tiempo_actual = min(tiempo_actual, tiempo_maximo_permitido)
	_actualizar_visuales()
	tiempo_agregado.emit(cantidad)
	print("Tiempo agregado: +%.1f segundos. Total: %.1f" % [cantidad, tiempo_actual])

func restar_tiempo(cantidad: float):
	"""Resta tiempo del temporizador"""
	tiempo_actual -= cantidad
	tiempo_actual = max(0.0, tiempo_actual)
	_actualizar_visuales()
	tiempo_restado.emit(cantidad)
	
	# Si se acabó el tiempo por esta resta
	if tiempo_actual <= 0.0:
		_tiempo_terminado()
	else:
		print("Tiempo restado: -%.1f segundos. Total: %.1f" % [cantidad, tiempo_actual])

func establecer_tiempo(nuevo_tiempo: float):
	"""Establece un tiempo específico"""
	tiempo_actual = clamp(nuevo_tiempo, 0.0, tiempo_maximo_permitido)
	_actualizar_visuales()
	print("Tiempo establecido a: %.1f segundos" % tiempo_actual)

func obtener_tiempo_restante() -> float:
	"""Retorna el tiempo restante"""
	return tiempo_actual

func obtener_porcentaje_restante() -> float:
	"""Retorna el porcentaje de tiempo restante (0.0 a 1.0)"""
	return tiempo_actual / tiempo_maximo

func esta_el_temporizador_corriendo() -> bool:
	"""Retorna true si el temporizador está corriendo"""
	return esta_corriendo and not tiempo_pausado

func esta_el_temporizador_pausado() -> bool:
	"""Retorna true si el temporizador está pausado"""
	return tiempo_pausado

# --- FUNCIONES PARA CONFIGURACIÓN DINÁMICA ---

func configurar_tiempo_inicial(nuevo_tiempo_inicial: float):
	"""Configura un nuevo tiempo inicial"""
	tiempo_inicial = nuevo_tiempo_inicial
	tiempo_maximo = nuevo_tiempo_inicial
	progress_bar.max_value = tiempo_maximo
	reiniciar_temporizador()

func configurar_modo_precision(activar_centesimas: bool):
	"""Activa o desactiva el modo de centésimas"""
	mostrar_centesimas = activar_centesimas
	if usar_timer_nodo and is_instance_valid(timer_node):
		timer_node.wait_time = 0.1 if mostrar_centesimas else 1.0
	_actualizar_visuales()
