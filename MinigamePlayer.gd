extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0 

@export var max_health: int = 3
var current_health: int
@export var health_bar: ProgressBar # Zugewiesen im Editor

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite
@onready var minigame_scene = get_parent() 

# --- Referenzen zu BEIDEN Formen ---
@onready var stand_shape = $StandShape
@onready var crouch_shape = $CrouchShape
# -----------------------------------

var is_invincible = false
@onready var invincibility_timer = $InvincibilityTimer
@onready var invisibility_timer = $InvisibilityTimer 

var is_crouching = false # Wichtig: 'var', nicht 'const'


func _ready():
	current_health = max_health
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = current_health
	else:
		print("FEHLER in MinigamePlayer.gd: Die 'Health Bar'-Variable wurde nicht im Inspektor zugewiesen!")
	
	# Sicherstellen, dass der Start-Zustand korrekt ist
	stand_shape.disabled = false
	crouch_shape.disabled = true


func _physics_process(delta):
	# ---------------------------------
	# 1. Schwerkraft
	# ---------------------------------
	if not is_on_floor():
		velocity.y += gravity * delta

	# ---------------------------------
	# 2. Inputs lesen
	# ---------------------------------
	var crouch_input = Input.is_action_pressed("ui_down")
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# ---------------------------------
	# 3. Ducken-Zustand (STABILE LOGIK)
	# ---------------------------------
	
	# Wenn wir in der Luft sind, können wir nicht ducken (automatisch aufstehen)
	if not is_on_floor():
		is_crouching = false
	else:
		# Wenn wir am Boden sind, bestimmt der Input den Zustand
		is_crouching = crouch_input

	# Schalte die Kollisionsformen basierend auf dem finalen Zustand um
	# (Diese Logik ist jetzt stabil und zittert nicht mehr)
	stand_shape.disabled = is_crouching
	crouch_shape.disabled = not is_crouching
	
	# ---------------------------------
	# 4. Horizontale Bewegung
	# ---------------------------------
	
	# Wenn wir ducken (was impliziert, dass wir auf dem Boden sind), stoppen wir
	if is_crouching:
		velocity.x = 0
	else:
		# Normale Bewegung (auch in der Luft)
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# ---------------------------------
	# 5. Vertikale Bewegung (Sprung)
	# ---------------------------------
	# Kann nur springen, wenn am Boden UND nicht geduckt
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

	# Animationen basierend auf dem finalen Zustand
	if is_crouching:
		animated_sprite.play("Crouch")
	elif not is_on_floor():
		animated_sprite.play("Jump_Loop")
	elif direction != 0:
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
