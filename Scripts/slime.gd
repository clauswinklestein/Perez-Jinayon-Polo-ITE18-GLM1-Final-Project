extends Node2D
const SPEED = 60
var direction = 1
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _process(delta: float) -> void:
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false
	position.x += direction * SPEED * delta

func _on_body_entered(body):
	print("========== SLIME COLLISION ==========")
	print("Body touched slime: ", body.name)
	
	if body.name == "Player":
		# Check player size by checking the animated_sprite scale
		var player_sprite = body.get_node("AnimatedSprite2D2")
		
		if player_sprite:
			print("Player sprite scale: ", player_sprite.scale)
			
			# If player sprite is scaled up (2x means giant/large)
			if player_sprite.scale.x >= 2.0 or player_sprite.scale.y >= 2.0:
				print("🔴 LARGE PLAYER CRUSHED THE SLIME!")
				
				# Optional: Add visual effect
				animated_sprite.modulate = Color(1, 0, 0, 1)  # Flash red
				
				# Destroy the slime
				queue_free()
				return  # Don't damage player!
		
		print("⚠️ Normal sized player - taking damage...")
		
		# Normal damage for regular-sized player
		if body.has_method("take_damage"):
			print("Player has take_damage method - calling it")
			body.take_damage()
		else:
			print("ERROR: Player doesn't have take_damage method!")
		
		# Game over
		get_node("/root/Game/GameOverSound").play()
		body.get_node("CollisionShape2D").queue_free()
		await get_tree().create_timer(1.0).timeout
		get_tree().reload_current_scene()
