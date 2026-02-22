## // SPRITE // ##

extends Node

## // FUNCTIONS // ##

func _ready() -> void:
	
	get_node("LoadingScreen/Menu").play("Show")
	
func open_main():
	get_node("LoadingScreen/Menu").play("ShowLoading")
	await get_tree().create_timer(.5).timeout
	$Login.queue_free()
	
	var main_scene : PackedScene = load("res://Scenes/Main/Main.tscn")
	var scene = main_scene.instantiate()
	add_child(scene)
