extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -650.0 

@export var max_health: int = 3
var current_health: int
@export var health_bar: ProgressBar # Zugewiesen im Editor

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite
@onready var minigame_scene = get_parent() 

# --- RAUCH-EFFEKT ---
@onready var death_smoke_effect = $DeathSmoke 

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
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = current_health
	else:
		print("FEHLER in MinigamePlayer.gd: Die 'Health Bar'-Variable wurde nicht im Inspektor zugewiesen!")
	
	stand_shape.disabled = false
	crouch_shape.disabled = true
	
	is_dead = false
	set_physics_process(true)
	
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta):
	if is_dead:
		velocity.x = 0 
		move_and_slide() 
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	var crouch_input = Input.is_action_pressed("ui_down")
	var direction = Input.get_axis("ui_left", "ui_right")
	
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
	
	if anim_name == "Death":
		return
	
	if anim_name == "Crouch_Start":
		if is_crouching:
			animated_sprite.play("Crouch_Idle")
		else:
			animated_sprite.play("Crouch_End")
			
	elif anim_name == "Crouch_End":
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			animated_sprite.play("Run")
		else:
			animated_sprite.play("Idle")

func _on_spikes_body_entered(body):
	if body == self:
		take_damage(1) 

func take_damage(damage_amount: int = 1):
	if is_invincible or is_dead:
		return 

	print("Player took damage: ", damage_amount)
	current_health -= damage_amount
	
	if is_instance_valid(health_bar):
		health_bar.value = current_health
	else:
		print("HealthBar nicht gefunden, kann Wert nicht aktualisieren.")

	# --- KORREKTUR: Unverwundbarkeit nur setzen, WENN man noch lebt ---
	if current_health > 0:
		is_invincible = true
		invincibility_timer.start(1.0) 
		invisibility_timer.start(0.1) 
		modulate.a = 0.5 
	# --- ENDE KORREKTUR ---

	is_shaking = true
	camera_shake_timer.start(0.2)

	if current_health <= 0 and not is_dead:
		print("Player health is zero. Starte Todes-Sequenz...")
		
		# 1. Spieler als "tot" markieren
		is_dead = true
		
		# --- KORREKTUR: Stelle sicher, dass der Spieler sichtbar ist ---
		modulate.a = 1.0
		# --- ENDE KORREKTUR ---
		
		# 2. "Death"-Animation abspielen
		print("DEBUG: Spiele 'Death'-Animation...")
		animated_sprite.play("Death")
		
		# 3. RAUCH-EFFEKT
		if is_instance_valid(death_smoke_effect):
			death_smoke_effect.emitting = true 
		else:
			print("WARNUNG: 'DeathSmoke'-Node nicht gefunden!")
		
		# 4. Warte, bis die "Death"-Animation fertig ist
		await animated_sprite.animation_finished
		print("DEBUG: 'Death'-Animation beendet.")
		
		# 5. Erst DANACH rufe die Game-Over-Szene (DOOM-EffEkt) auf
		if minigame_scene.has_method("player_died"):
			print("DEBUG [take_damage]: Rufe 'await minigame_scene.player_died()' auf...")
			await minigame_scene.player_died()
			print("DEBUG [take_damage]: 'await minigame_scene.player_died()' ist BEENDET.")
		else:
			print("FEHLER: player_died() Methode nicht in minigame_scene gefunden!")
			
	elif current_health > 0:
		print("Player health remaining: ", current_health)


func _on_invincibility_timer_timeout():
	is_invincible = false
	modulate.a = 1.0 
	invisibility_timer.stop() 


func _on_invisibility_timer_timeout():
	if is_invincible:
		modulate.a = 1.0 - modulate.a 
		invisibility_timer.start(0.1)


func _on_camera_shake_timer_timeout():
	is_shaking = false
	camera.offset = Vector2.ZERO


func _on_spikes_3_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.


func _on_spikes_2_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.


func _on_spikes_5_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.


func _on_spikes_6_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.


func _on_spikes_7_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.


func _on_spikes_8_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.
