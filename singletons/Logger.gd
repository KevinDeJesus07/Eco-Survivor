extends Node

enum Level { DEBUG, INFO, WARNING, ERROR }

var curr_level: Level = Level.DEBUG
var en_categories = {"INVENTORY": true, "PLAYER": true, "ENEMY": false}

func _log(level: Level, category: String, message: String, ctx_node: Node = null):
	if level >= curr_level and en_categories.get(category, true):
		var prefix = "[%s] [%s]" % [Level.keys()[level], category]
		if is_instance_valid(ctx_node):
			prefix += " [" + ctx_node.name + "]:"
			
		var final_msg = prefix + " " + message
		
		match level:
			Level.ERROR:
				push_error(final_msg)
				printerr(final_msg)
			Level.WARNING:
				push_warning(final_msg)
				print_rich("[color=yellow]" + final_msg + "[/color]")
			Level.INFO:
				print_rich("[color=cyan]" + final_msg + "[/color]")
			Level.DEBUG:
				print_rich("[color=gray]" + final_msg + "[/color]")
				
func debug(category: String, message: String, ctx_node: Node = null):
	_log(Level.DEBUG, category, message, ctx_node)

func info(category: String, message: String, ctx_node: Node = null):
	_log(Level.INFO, category, message, ctx_node)
	
func warn(category: String, message: String, ctx_node: Node = null):
	_log(Level.WARNING, category, message, ctx_node)
	
func error(category: String, message: String, ctx_node: Node = null):
	_log(Level.ERROR, category, message, ctx_node)
	
func set_category_en(category: String, enabled: bool):
	en_categories[category] = enabled
	
func set_level(level: Level):
	curr_level = level
