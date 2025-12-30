extends Control

@onready var host_button = $VBoxContainer/HostButton
@onready var join_button = $VBoxContainer/HBoxContainer/JoinButton
@onready var ip_input = $VBoxContainer/HBoxContainer/IpInput

func _ready():
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)

func _on_host_pressed():
	MultiPlayerManager.host_game()
	# Switch to your game scene
	get_tree().change_scene_to_file("res://src/Main.tscn")

func _on_join_pressed():
	var ip = ip_input.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1" # default to localhost
	MultiPlayerManager.join_game(ip)
	get_tree().change_scene_to_file("res://src/Main.tscn")
