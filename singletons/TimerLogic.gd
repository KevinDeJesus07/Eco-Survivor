# TimerLogic.gd (Autoload)
extends Node

# Señales para la lógica del temporizador
signal tiempo_agotado
signal tiempo_cambiado(tiempo_restante: float)
signal tiempo_agregado(cantidad: float)
signal tiempo_restado(cantidad: float)

# Variables de estado
var tiempo_inicial: float = 20.0
var tiempo_actual: float = 20.0
var tiempo_maximo_permitido: float = 300.0
var esta_corriendo: bool = false
var tiempo_pausado: bool = false

func iniciar_temporizador():
	"""Inicia la cuenta atrás del temporizador"""
	if tiempo_actual > 0:
		esta_corriendo = true
		tiempo_pausado = false
		print("Temporizador iniciado")

func pausar_temporizador():
	"""Pausa el temporizador"""
	tiempo_pausado = true
	print("Temporizador pausado")

func reanudar_temporizador():
	"""Reanuda el temporizador si estaba pausado"""
	if esta_corriendo:
		tiempo_pausado = false
		print("Temporizador reanudado")

func detener_temporizador():
	"""Detiene completamente el temporizador"""
	esta_corriendo = false
	tiempo_pausado = false
	print("Temporizador detenido")

func reiniciar_temporizador():
	"""Reinicia el temporizador al tiempo inicial"""
	tiempo_actual = tiempo_inicial
	esta_corriendo = false
	tiempo_pausado = false
	print("Temporizador reiniciado")
	tiempo_cambiado.emit(tiempo_actual)

func sumar_tiempo(cantidad: float):
	"""Añade tiempo al temporizador"""
	tiempo_actual += cantidad
	tiempo_actual = min(tiempo_actual, tiempo_maximo_permitido)
	tiempo_agregado.emit(cantidad)
	tiempo_cambiado.emit(tiempo_actual)
	print("Tiempo agregado: +%.1f segundos. Total: %.1f" % [cantidad, tiempo_actual])

func restar_tiempo(cantidad: float):
	"""Resta tiempo del temporizador"""
	tiempo_actual -= cantidad
	tiempo_actual = max(0.0, tiempo_actual)
	tiempo_restado.emit(cantidad)
	tiempo_cambiado.emit(tiempo_actual)
	
	if tiempo_actual <= 0.0:
		_tiempo_terminado()
	else:
		print("Tiempo restado: -%.1f segundos. Total: %.1f" % [cantidad, tiempo_actual])

func _tiempo_terminado():
	GameManager.next_wave()
	esta_corriendo = false
	tiempo_agotado.emit()
	reiniciar_completamente()
	iniciar_temporizador()

func _process(delta: float):
	if esta_corriendo and not tiempo_pausado:
		tiempo_actual -= delta
		tiempo_actual = max(0.0, tiempo_actual)
		tiempo_cambiado.emit(tiempo_actual)
		
		if tiempo_actual <= 0.0:
			_tiempo_terminado()

func reiniciar_completamente():
	"""Reinicia completamente el temporizador para una nueva partida"""
	tiempo_actual = tiempo_inicial
	esta_corriendo = false
	tiempo_pausado = false
	print("Temporizador completamente reiniciado")
	tiempo_cambiado.emit(tiempo_actual)
