extends Node

var _instance_num = -1
var _instance_max = 20
var _instance_socket: TCPServer 
var _id_str = ''

func _ready():
	if OS.is_debug_build():
		_instance_socket = TCPServer.new()
		while _instance_num < _instance_max:
			_instance_num += 1
			if _instance_socket.listen(5000 + _instance_num) == OK:
				_id_str = "[" + str(_instance_num) + "] "
				break
	info(self, "_ready()")
	
func instance_id():
	return _instance_num if _instance_num > -1 else -1

func info(node: Node, message: String) -> void:
	var text = "[color=lightgreen] == INFO == " + _id_str + "[" + node.name + "]: [/color]" + message
	Console.write_plain(text)
	print_rich(text)

func warn(node: Node, message: String) -> void:
	var text = "[color=orange] == WARNING == " + _id_str + "[" + node.name + "]: [/color]" + message
	Console.write_plain(text)
	print_rich(text)
	
func error(node: Node, message: String) -> void:
	var text = "[color=red] == ERROR == " + _id_str + "[" + node.name + "]: [/color]" + message
	Console.write_error(text)
	print_rich(text)
	
func debug(node: Node, message: String) -> void:
	var text = "[color=blue] == DEBUG == " + _id_str + "[" + node.name + "]: [/color]" + message
	Console.write_plain(text)
	print_rich(text)
	
