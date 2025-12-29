extends CharacterBody2D

var SPEED = 125
var JUMP_VELOCITY = -300.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_large = false


@onready var camera: Camera2D = $Camera2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D2
#@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


func use_power_up():
	var powerUpDuration = 15
	
	animated_sprite.scale *= 2
	animated_sprite.position.y *= 2
	collision_shape_2d.scale *= 2
	collision_shape_2d.position.y *= 2
	
	await get_tree().create_timer(powerUpDuration).timeout
	animated_sprite.scale /= 2
	animated_sprite.position.y /= 2
	collision_shape_2d.scale /= 2
	collision_shape_2d.position.y /= 2
	

# ========== POWER-UP VARIABLES ==========
var has_shield = false
var shield_timer = 0.0
var shield_duration = 10.0
var shield_sprite: Sprite2D

var normal_scale = Vector2(1.0, 1.0)
var is_giant = true  # SET TO TRUE FOR TESTING
var is_tiny = false
var size_timer = 0.0
var size_duration = 8.0

# Store original values
var original_speed = SPEED
var original_jump = JUMP_VELOCITY

func _ready():
	normal_scale = scale
	create_shield_visual()

func _physics_process(delta: float) -> void:
	# Handle power-up timers
	handle_power_up_timers(delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_sound.play()
	
	# Get the input direction: -1, 0, 1
	var direction := Input.get_axis("move_left", "move_right")
	
	# Flip the sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		elif direction == 1:
			animated_sprite.play("run")
		elif direction == -1:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	
	# Apply movement (using current SPEED which may be modified by power-ups)
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()

# ========== POWER-UP TIMER MANAGEMENT ==========
func handle_power_up_timers(delta):
	# Shield timer
	if has_shield:
		shield_timer -= delta
		if shield_timer <= 0:
			deactivate_shield()
		elif shield_timer <= 3:
			# Blink warning when about to expire
			shield_sprite.visible = int(shield_timer * 10) % 2 == 0
	#
	# Size timer
	if is_giant or is_tiny:
		size_timer -= delta
		if size_timer <= 0:
			reset_size()
		elif size_timer <= 3:
			# Blink warning
			modulate.a = 0.5 if int(size_timer * 10) % 2 == 0 else 1.0
#
# ========== SHIELD FUNCTIONS ==========
func create_shield_visual():
	shield_sprite = Sprite2D.new()
	add_child(shield_sprite)
	shield_sprite.z_index = -1
	shield_sprite.visible = false
	shield_sprite.scale = Vector2(2.5, 2.5)
	
	# Create shield texture
	var shield_texture = create_shield_texture()
	shield_sprite.texture = shield_texture

func create_shield_texture() -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	
	# Draw shield circle
	for y in range(64):
		for x in range(64):
			var center = Vector2(32, 32)
			var pos = Vector2(x, y)
			var dist = center.distance_to(pos)
			
			# Outer glow
			if dist < 30 and dist > 26:
				img.set_pixel(x, y, Color(0.3, 0.7, 1.0, 0.8))
			# Inner fill
			elif dist < 26:
				var alpha = 0.3 * (1.0 - dist / 26.0)
				img.set_pixel(x, y, Color(0.3, 0.7, 1.0, alpha))
	
	return ImageTexture.create_from_image(img)

func activate_shield():
	has_shield = true
	shield_timer = shield_duration
	shield_sprite.visible = true
	
	# Pulse animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(shield_sprite, "scale", Vector2(3.0, 3.0), 0.5)
	tween.tween_property(shield_sprite, "scale", Vector2(2.5, 2.5), 0.5)
	
	print("🛡️ Shield activated! Duration: ", shield_duration, "s")

func deactivate_shield():
	has_shield = false
	shield_sprite.visible = false
	modulate.a = 1.0
	print("🛡️ Shield deactivated!")

# ========== SIZE CHANGE FUNCTIONS ==========
func grow():
	# If already tiny, reset first
	if is_tiny:
		reset_size()
		await get_tree().create_timer(0.3).timeout
	#
	is_giant = true
	is_tiny = false
	size_timer = size_duration
	
	# Animate growth
	var tween = create_tween()
	tween.tween_property(self, "scale", normal_scale * 2.0, 0.3)
	
	# Adjust movement - giant is slower but has more weight
	const_set("SPEED", original_speed * 0.7)
	const_set("JUMP_VELOCITY", original_jump * 0.85)
	
	print("🔴 Player grew GIANT!")

#func shrink():
	# If already giant, reset first
	if is_giant:
		reset_size()
		await get_tree().create_timer(0.3).timeout
		
	is_tiny = true
	is_giant = false
	size_timer = size_duration
	
	# Animate shrinking
	#var tween = create_tween()
	tween.tween_property(self, "scale", normal_scale * 0.5, 0.3)
	
	# Adjust movement - tiny is faster and jumps higher
	const_set("SPEED", original_speed * 1.4)
	const_set("JUMP_VELOCITY", original_jump * 1.3)
	
	print("🟢 Player became TINY!")

func reset_size():
	var tween = create_tween()
	tween.tween_property(self, "scale", normal_scale, 0.3)
	
	# Reset movement values
	const_set("SPEED", original_speed)
	const_set("JUMP_VELOCITY", original_jump)
	
	is_giant = false
	is_tiny = false
	modulate.a = 1.0
	
	print("⚪ Player returned to normal size!")

# Helper function to modify constants
func const_set(const_name: String, value):
	if const_name == "SPEED":
		set_meta("current_speed", value)
		# Update the speed in physics process
	elif const_name == "JUMP_VELOCITY":
		set_meta("current_jump", value)

# ========== EXISTING FUNCTIONS (ENHANCED) ==========
func shake_camera(intensity: float = 5.0, duration: float = 0.3):
	var shake_tween = create_tween()
	var original_offset = camera.offset
	for i in range(int(duration * 60)):
		var random_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		shake_tween.tween_property(camera, "offset", random_offset, 0.016)
	shake_tween.tween_property(camera, "offset", original_offset, 0.1)

func take_damage():
	# Check if shield protects
	if has_shield:
		print("🛡️ Shield blocked damage!")
		deactivate_shield()
		shake_camera(2.0, 0.2)
		return  # Don't take damage!
	
	# Normal damage
	$HurtSound.play()
	shake_camera(3.0, 0.3)

 # New function for killzone to check protection
func is_protected() -> bool:
	return has_shield
