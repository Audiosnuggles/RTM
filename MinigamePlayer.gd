# MinigamePlayer.gd

extends CharacterBody2D

# --- Physik Konstanten ---
const SPEED = 300.0
const JUMP_VELOCITY = -450.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") 

# --- Item Zustände ---
var is_invincible: bool = false
var is_invisible: bool = false

# --- Level-Begrenzung ---
const LEVEL_START_X = 0 
const LEVEL_END_X = 4000

# Referenzen zu anderen Nodes
var minigame_scene: Node = null 
var invincibility_timer: Timer
var invisibility_timer: Timer

@onready var animated_sprite = $AnimatedSprite 


func _ready():
	# 1. Referenz zur Root-Szene (MinigameScene)
	minigame_scene = get_parent()
	
	# 2. Timer-Nodes über den $-Operator referenzieren
	invincibility_timer = $InvincibilityTimer
	invisibility_timer = $InvisibilityTimer 
	
	# 3. Timer-Timeout-Signale verbinden
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	invisibility_timer.timeout.connect(_on_invisibility_timer_timeout)
	
	# SICHERHEITS-CHECK: Stellt sicher, dass der Player verwundbar startet
	is_invincible = false
	is_invisible = false
	
	# Startanimation spielen
	animated_sprite.play("Idle")
	
	# NEU: Signalverbindung zum Gegner-Node herstellen
	# Annahme: Der Enemy ist direkt in der MinigameScene geladen und heißt "Enemy"
	var enemy_node = minigame_scene.get_node_or_null("Enemy")
	
	if enemy_node != null:
		# Prüfen, ob der Enemy das player_hit Signal hat und verbinden
		if enemy_node.has_signal("player_hit"):
			enemy_node.player_hit.connect(_on_enemy_hit)


func _physics_process(delta):
	# 1. Schwerkraft anwenden
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Bewegung verarbeiten
	var direction = Input.get_axis("ui_left", "ui_right")

	# --- ANIMATIONS- UND BEWEGUNGSSTEUERUNG ---
	
	if direction:
		velocity.x = direction * SPEED
		animated_sprite.flip_h = (direction < 0) 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if is_on_floor():
		if direction:
			animated_sprite.play("Run") 
		else:
			animated_sprite.play("Idle")
			
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY
			animated_sprite.play("Jump_Loop") 
			
	else: 
		if animated_sprite.animation != "Jump_Land":
			animated_sprite.play("Jump_Loop") 
		
	# 4. CHARAKTER BEWEGEN
	move_and_slide()
	
	# 5. Begrenze die horizontale Position
	var new_position = position
	
	if new_position.x < LEVEL_START_X:
		new_position.x = LEVEL_START_X
		velocity.x = 0 
		
	if new_position.x > LEVEL_END_X:
		new_position.x = LEVEL_END_X
		velocity.x = 0
		
	position = new_position

	# --- TODESTEST (Temporär) ---
	if position.y > 1000:
		minigame_scene.player_died()


# --- ITEM ZUSTANDS-LOGIK ---

func activate_invincibility(duration: float):
	if not invincibility_timer.is_stopped():
		invincibility_timer.stop() 
		
	is_invincible = true
	invincibility_timer.start(duration)
	animated_sprite.modulate = Color(1.0, 0.7, 0.0, 1.0) 


func _on_invincibility_timer_timeout():
	is_invincible = false
	animated_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0) 


func activate_invisibility(duration: float):
	if not invisibility_timer.is_stopped():
		invisibility_timer.stop() 
		
	is_invisible = true
	invisibility_timer.start(duration)
	animated_sprite.modulate.a = 0.5


func _on_invisibility_timer_timeout():
	is_invisible = false
	animated_sprite.modulate.a = 1.0


# NEU: Funktion zum Empfangen des Treffer-Signals vom Gegner
func _on_enemy_hit():
	if not is_invincible and not is_invisible:
		minigame_scene.player_died()
		
		# Stoppe die Player-Logik (Player-Tod-Animation könnte hier folgen)
		set_process(false) 
		set_physics_process(false)
		hide()


# --- SCHADENS-/TODES-LOGIK (Spikes) ---

func _on_spikes_body_entered(_body):
	if not is_invincible and not is_invisible:
		minigame_scene.player_died()
		
		set_process(false) 
		set_physics_process(false)
		hide()
