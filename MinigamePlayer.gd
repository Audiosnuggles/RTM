extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -650.0 

@export var max_health: int = 3
var current_health: int

# --- UI REFERENZEN ---
@export var health_bar: ProgressBar # Die vordere Leiste (Aktuelle HP)
@export var damage_bar: ProgressBar # Die hintere Leiste (Nachzieheffekt)

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite
@onready var minigame_scene = get_parent() 

@onready var death_smoke_effect = get_node_or_null("DeathSmoke") 

@onready var stand_shape = $StandShape
@onready var crouch_shape = $CrouchShape

var is_invincible = false
@onready var invincibility_timer = $InvincibilityTimer
@onready var invisibility_timer = $InvisibilityTimer 

var is_crouching = false

@onready var camera = $Camera2D
@onready var camera_shake_timer = $CameraShakeTimer
var shake_intensity = 10.0
var is_shaking = false

var is_dead: bool = false


func _ready():
	current_health = max_health
	
	print("--- PLAYER START ---")
	# Initialisiere BEIDE Bars
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.show_percentage = false # Optional: Text ausblenden für cleaneren Look
	
	if is_instance_valid(damage_bar):
		damage_bar.max_value = max_health
		damage_bar.value = current_health
		damage_bar.show_percentage = false
		
	stand_shape.disabled = false
	crouch_shape.disabled = true
	
	is_dead = false
	set_physics_process(true)
	
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta):
	var direction = 0.0
	
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_dead:
		velocity.x = 0
	else:
		var crouch_input = Input.is_action_pressed("ui_down")
		direction = Input.get_axis("ui_left", "ui_right") 
		
		var wants_to_crouch = crouch_input and is_on_floor()

		if wants_to_crouch and not is_crouching:
			is_crouching = true
			stand_shape.disabled = true
			crouch_shape.disabled = false
			if animated_sprite.animation != "Crouch_Start":
				animated_sprite.play("Crouch_Start") 
			
		elif not wants_to_crouch and is_crouching:
			is_crouching = false
			stand_shape.disabled = false
			crouch_shape.disabled = true
			
			if animated_sprite.animation == "Crouch_Idle":
				animated_sprite.play("Crouch_End")
		
		if is_crouching or animated_sprite.animation in ["Crouch_Start", "Crouch_End"]:
			velocity.x = 0
		else:
			if direction:
				velocity.x = direction * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)

		if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouching:
			velocity.y = JUMP_VELOCITY
			
	move_and_slide()

	if not is_dead:
		if direction != 0:
			animated_sprite.flip_h = (direction < 0) 

		if not is_crouching and animated_sprite.animation not in ["Crouch_Start", "Crouch_End"]:
			if not is_on_floor():
				if animated_sprite.animation != "Jump_Loop":
					animated_sprite.play("Jump_Loop")
			elif direction != 0:
				if animated_sprite.animation != "Run":
					animated_sprite.play("Run")
			else:
				if animated_sprite.animation != "Idle":
					animated_sprite.play("Idle")
					
		if is_shaking:
			camera.offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)

func _on_animation_finished():
	var anim_name = animated_sprite.animation
	if anim_name == "Death": return
	if anim_name == "Crouch_Start":
		animated_sprite.play("Crouch_Idle" if is_crouching else "Crouch_End")
	elif anim_name == "Crouch_End":
		animated_sprite.play("Idle")

func _on_spikes_body_entered(body):
	if body == self: take_damage(1) 

func take_damage(damage_amount: int = 1):
	if is_invincible or is_dead: return 

	current_health -= damage_amount
	print("--- TREFFER --- HP:", current_health)
	
	# 1. HealthBar sofort aktualisieren (Hartes Feedback)
	if is_instance_valid(health_bar):
		health_bar.value = current_health
	
	# 2. DamageBar sanft nachziehen (Visueller "Ghost" Effekt)
	if is_instance_valid(damage_bar):
		var tween = create_tween()
		# Warte kurz (0.2s), damit der Unterschied sichtbar ist
		tween.tween_interval(0.2) 
		# Animiere den Wert über 0.4 Sekunden auf den neuen Stand
		tween.tween_property(damage_bar, "value", current_health, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# TODES-LOGIK
	if current_health <= 0:
		if not is_dead:
			is_dead = true
			is_invincible = true
			modulate.a = 1.0
			
			set_deferred("process_mode", Node.PROCESS_MODE_DISABLED) 
			set_deferred("collision_layer", 0) 
			set_deferred("collision_mask", 0)  
			
			if invincibility_timer: invincibility_timer.stop()
			if invisibility_timer: invisibility_timer.stop()
			if camera_shake_timer: camera_shake_timer.stop()
			is_shaking = false
			if camera: camera.offset = Vector2.ZERO
			
			animated_sprite.play("Death")
			if is_instance_valid(death_smoke_effect):
				death_smoke_effect.emitting = true
			
			if minigame_scene.has_method("player_died"):
				await minigame_scene.player_died()
		return 

	# ÜBERLEBT
	is_invincible = true
	if invincibility_timer: invincibility_timer.start(1.0) 
	if invisibility_timer: invisibility_timer.start(0.1) 
	modulate.a = 0.5 

	is_shaking = true
	if camera_shake_timer: camera_shake_timer.start(0.2)


func heal(amount: int):
	if current_health < max_health:
		current_health = min(current_health + amount, max_health)
		
		# Bei Heilung aktualisieren wir beide sofort (oder animieren hoch)
		if is_instance_valid(health_bar): 
			health_bar.value = current_health
		if is_instance_valid(damage_bar): 
			damage_bar.value = current_health # Ghost-Bar zieht sofort nach
			
		return true 
	return false 

func bounce():
	velocity.y = JUMP_VELOCITY * 0.8

func _on_invincibility_timer_timeout():
	is_invincible = false
	modulate.a = 1.0 
	if invisibility_timer: invisibility_timer.stop() 

func _on_invisibility_timer_timeout():
	if is_invincible:
		modulate.a = 1.0 - modulate.a 
		invisibility_timer.start(0.1)

func _on_camera_shake_timer_timeout():
	is_shaking = false
	if camera: camera.offset = Vector2.ZERO

# Dummy-Funktionen
func _on_spikes_3_body_entered(_body: Node2D) -> void: pass
func _on_spikes_2_body_entered(_body: Node2D) -> void: pass
func _on_spikes_5_body_entered(_body: Node2D) -> void: pass
func _on_spikes_6_body_entered(_body: Node2D) -> void: pass
func _on_spikes_7_body_entered(_body: Node2D) -> void: pass
func _on_spikes_8_body_entered(_body: Node2D) -> void: pass
