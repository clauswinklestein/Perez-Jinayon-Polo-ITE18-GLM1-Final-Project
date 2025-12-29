extends Area2D
@onready var timer: Timer = $Timer
@onready var game_over_sound = get_node("/root/Game/GameOverSound")
@onready var game_over_label = get_node("/root/Game/GameOverLabel")

func _on_body_entered(body: Node2D) -> void:
	# Check if player has shield protection
	if body.has_method("is_protected") and body.is_protected():
		print("🛡️ Shield saved you from the killzone!")
		body.deactivate_shield()
		body.shake_camera(2.0, 0.2)
		# Bounce player up slightly
		if body is CharacterBody2D:
			body.velocity.y = -200
		return  # Don't kill player!
	
	# CHECK IF PLAYER IS LARGE/GIANT - if so, don't kill them!
	if body.name == "Player":
		var player_sprite = body.get_node("AnimatedSprite2D2")
		
		if player_sprite:
			print("🔍 Checking player size... Scale: ", player_sprite.scale)
			
			# If player is large (scale >= 2.0), they survive!
			if player_sprite.scale.x >= 2.0 or player_sprite.scale.y >= 2.0:
				print("🔴 LARGE PLAYER IS IMMUNE TO KILLZONE!")
				# Optional: bounce them up
				if body is CharacterBody2D:
					body.velocity.y = -300
				return  # Don't kill large player!
	
	print("You died!")
	
	# Camera shake when hurt
	if body.has_method("shake_camera"):
		body.shake_camera(3.0, 0.2)
	
	game_over_sound.play()
	Engine.time_scale = 0.3
	body.get_node("CollisionShape2D").queue_free()
	timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
