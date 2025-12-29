extends Node2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if "Player" in body.name:
		body.use_power_up()
		queue_free()
