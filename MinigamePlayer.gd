extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0 # (Passe diesen Wert an, wenn du die Höhe ändern willst)

# --- NEUE HEALTH-VARIABLEN ---
@export var max_health: int = 3
var current_health: int

# --- NEU: @export VARIABLE FÜR HEALTHBAR ---
# Diese Variable müssen wir im Godot-Editor zuweisen!
@export var health_bar: ProgressBar
# -------------------------------------------

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite
@onready var minigame_scene = get_parent() 

var is_invincible = false
@onready var invincibility_timer = $InvincibilityTimer
@onready var invisibility_timer = $InvisibilityTimer 


# --- ANGEPASSTE _ready Funktion ---
func _ready():
	current_health = max_health
	
	# Prüft, ob die HealthBar im Editor zugewiesen wurde
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = current_health
	else:
		print("FEHLER in MinigamePlayer.gd: Die 'Health Bar'-Variable wurde nicht im Inspektor zugewiesen!")


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction = Input.get_axis("ui_left", "ui_right")

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if direction != 0:
		animated_sprite.flip_h = (direction < 0) 

	if not is_on_floor():
		if animated_sprite.animation != "Jump_Loop":
			animated_sprite.play("Jump_Loop")
	elif direction != 0:
		animated_sprite.play("Run")
	else:
		animated_sprite.play("Idle")

	move_and_slide()


func _on_spikes_body_entered(body):
	if body == self:
		take_damage(1) 


func take_damage(damage_amount: int = 1):
	if is_invincible:
		return 

	print("Player took damage: ", damage_amount)
	current_health -= damage_amount
	
	# UI-Leiste aktualisieren (prüft jetzt auch hier)
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
