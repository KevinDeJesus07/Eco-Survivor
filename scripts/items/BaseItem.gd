extends Area2D

@export var item: ItemData

func _ready():
	body_entered.connect(_on_body_entered) # Activar detección de entrada de cuerpos
	
	if not is_instance_valid(item):
		Logger.error("BASE_ITEM", str(name) + " en " + str(global_position) + " NO tiene 'Item' asignado en el Inspector. No funcionara correctamente.", self)
		return

func _on_body_entered(body):
	if not is_instance_valid(item):
		Logger.warn("BASE_ITEM", "sin 'Item' válido detectó cuerpo: " + str(body.name), self)
		return
		
	if not body.is_in_group("Player"):
		Logger.debug("BASE_ITEM", str(body.name) + " NO es 'Player', ignorando.", self)
		return	
	
	if not InventoryManager:
		Logger.error("BASE_ITEM", "InventoryManager no encontrado!", self)
		return
		
	Logger.info("BASE_ITEM", str(body.name) + " es 'Player'. Intentando recoger " + str(item.item_name), self)
	var remaining = InventoryManager.add_item(item, 1)
	
	if remaining != 0:
		Logger.info("BASE_ITEM", "No se pudo recoger " + str(item.item_name) + ". Inventario lleno.", self)
		return
	
	Logger.info("BASE_ITEM", "jugador recogió: " + str(item.item_name), self)
	queue_free() # Destruir item del suelo
