extends CanvasLayer

@onready var output = $VBoxContainer/Output
@onready var input = $VBoxContainer/HBoxContainer/Input
@onready var close_on_command = $VBoxContainer/HBoxContainer/CloseOnCommand

var console_active = false

func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		toggle_console()
	if console_active and Input.is_action_just_pressed("enter"):
		process_input()

func toggle_console():
	console_active = !console_active
	visible = console_active
	if console_active:
		input.grab_focus()

func process_input():
	var user_input = input.text.strip_edges()
	if user_input == "":
		write_error("[Error] No command entered")
		clear_input()
		return
	var args: Array = user_input.split(" ")
	var command = args.pop_front()
	run_console_command(command, args)

func run_console_command(command: String, args: Array):
	clear_input()
	if has_method(command):
		var callable = Callable(self, command)
		if callable.is_valid():
			callable.callv([args])
			if close_on_command.button_pressed:
				toggle_console()
		else:
			write_error("[Error] Invalid command: " + command)
	else:
		write_error("[Error] Command " + command + " not found.")

func clear_input():
	input.text = ""

func write_plain(data: String):
	output.text += data + '\n'

func write_error(data: String):
	output.text += "[color='red']" + data + "[/color]" + "\n"

func write_success(data: String):
	output.text += "[color='green']" + data + "[/color]" + "\n"

# -------------------------------------------------
# Console Commands
# -------------------------------------------------
func test(args: Array):
	write_plain("test called with arguments: " + str(args))

func ui(args: Array):
	if args.size() != 1:
		write_error("[Error] Required arguments: [scene_name]")
		return
	var scene_name = args[0]
	var base_path = "res://scenes/ui/"
	var scene_path = base_path + scene_name + ".tscn"
	if !ResourceLoader.exists(scene_path):
		write_error("[Error] Scene " + scene_name + " not found")
		return
	write_success("Changing scene to " + scene_path)
	Sceney.change_to_scene(scene_path)
