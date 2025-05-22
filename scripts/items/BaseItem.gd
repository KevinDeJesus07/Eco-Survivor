extends Area2D

@export var item: Item

func _ready():
	body_entered.connect(_on_body_entered) # Activar detección de entrada de cuerpos
	
	if not is_instance_valid(item):
		Logger.priority("BASE_ITEM", str(name) + " en " + str(global_position) + " NO tiene 'Item' asignado en el Inspector. No funcionara correctamente.", self)
		return

func _on_body_entered(body):
	Logger.priority("BASE_ITEM", "En _on_body_entered", self)
	if not is_instance_valid(item):
		Logger.priority("BASE_ITEM", "sin 'Item' válido detectó cuerpo: " + str(body.name), self)
		return
		
	if not body.is_in_group("Player"):
		Logger.priority("BASE_ITEM", str(body.name) + " NO es 'Player', ignorando.", self)
		return	
	
	if not InventoryManager:
		Logger.priority("BASE_ITEM", "InventoryManager no encontrado!", self)
		return
		
	Logger.priority("BASE_ITEM", str(body.name) + " es 'Player'. Intentando recoger " + str(item.name), self)
	var remaining = InventoryManager.add_item(item, 1)
	
	if remaining != 0:
		Logger.priority("BASE_ITEM", "No se pudo recoger " + str(item.name) + ". Inventario lleno.", self)
		return
	
	Logger.priority("BASE_ITEM", "jugador recogió: " + str(item.name), self)
	queue_free() # Destruir item del suelo
