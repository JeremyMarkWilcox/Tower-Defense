extends Node

@export var viewport: SubViewport
@export var file_name: String = "new"

func _ready() -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw  # one extra frame so particles appear
	var img := viewport.get_texture().get_image()
	img.save_png("res://game/ui/tower_icons/%s.png" % file_name)
	print("Saved icon: ", file_name)
	get_tree().quit()
