extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0 

@export var max_health: int = 3
var current_health: int
@export var health_bar: ProgressBar # Zugewiesen im Editor

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite
@onready var minigame_scene = get_parent() 

@onready var stand_shape = $StandShape
@onready var crouch_shape = $CrouchShape

var is_invincible = false
@onready var invincibility_timer = $InvincibilityTimer
@onready var invisibility_timer = $InvisibilityTimer 

var is_crouching = false


func _ready():
	current_health = max_health
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = current_health
	else:
		print("FEHLER in MinigamePlayer.gd: Die 'Health Bar'-Variable wurde nicht im Inspektor zugewiesen!")
	
	stand_shape.disabled = false
	crouch_shape.disabled = true
	
	# WICHTIG: Stellt sicher, dass das Signal verbunden ist
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	var crouch_input = Input.is_action_pressed("ui_down")
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# ---------------------------------
	# 3. Ducken-Zustand (State Machine)
	# ---------------------------------
	var wants_to_crouch = crouch_input and is_on_floor()

	if wants_to_crouch and not is_crouching:
		# Spieler will sich HINSETZEN
		is_crouching = true
		stand_shape.disabled = true
		crouch_shape.disabled = false
		if animated_sprite.animation != "Crouch_Start":
			animated_sprite.play("Crouch_Start") 
		
	elif not wants_to_crouch and is_crouching:
		# Spieler will AUFSTEHEN
		is_crouching = false
		stand_shape.disabled = false
		crouch_shape.disabled = true
		
		if animated_sprite.animation == "Crouch_Idle":
			animated_sprite.play("Crouch_End")
	
	# ---------------------------------
	# 4. Horizontale Bewegung
	# ---------------------------------
	
	if is_crouching or animated_sprite.animation in ["Crouch_Start", "Crouch_End"]:
		velocity.x = 0
	else:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# ---------------------------------
	# 5. Vertikale Bewegung (Sprung)
	# ---------------------------------
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY

	# ---------------------------------
	# 6. Bewegung ausführen
	# ---------------------------------
	move_and_slide()

	# ---------------------------------
	# 7. Animationen & Sprite-Drehung
	# ---------------------------------
	if direction != 0:
		animated_sprite.flip_h = (direction < 0) 

	# Animations-Logik (nur für Laufen/Idle/Springen)
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

# --- KORRIGIERTE FUNKTION ---
# Wird aufgerufen, wenn eine Animation (mit Loop=OFF) endet
func _on_animation_finished():
	
	var anim_name = animated_sprite.animation
	
	if anim_name == "Crouch_Start":
		# Wenn die "Hinsetz"-Animation fertig ist...
		if is_crouching:
			# ...spiele die "Geduckt-Bleiben"-Animation (Loop=ON)
			animated_sprite.play("Crouch_Idle")
			
	elif anim_name == "Crouch_End":
		# Wenn die "Aufsteh"-Animation fertig ist...
		# ...prüfe, was der Spieler gerade tut, anstatt stur "Idle" zu spielen
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			animated_sprite.play("Run")
		else:
			animated_sprite.play("Idle")


# --- (Rest des Skripts bleibt gleich) ---

func _on_spikes_body_entered(body):
	if body == self:
		take_damage(1) 

func take_damage(damage_amount: int = 1):
	if is_invincible:
		return 

	print("Player took damage: ", damage_amount)
	current_health -= damage_amount
	
	if is_instance_valid(health_bar):
		health_bar.value = current_health
	else:
		print("HealthBar nicht gefunden, kann Wert nicht aktualisieren.")

	is_invincible = true
	invincibility_timer.start(1.0) 
	invisibility_timer.start(0.1) 
	modulate.a = 0.5 

	if current_health <= 0:
		print("Player health is zero. Calling player_died()")
		await get_tree().create_timer(0.5).timeout
		
		if minigame_scene.has_method("player_died"):
			minigame_scene.player_died()
		else:
			print("FEHLER: player_died() Methode nicht in minigame_scene gefunden!")
	else:
		print("Player health remaining: ", current_health)


func _on_invincibility_timer_timeout():
	is_invincible = false
	modulate.a = 1.0 
	invisibility_timer.stop() 


func _on_invisibility_timer_timeout():
	if is_invincible:
		modulate.a = 1.0 - modulate.a 
		invisibility_timer.start(0.1)
