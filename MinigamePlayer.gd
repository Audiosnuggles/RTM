extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0 # (Passe diesen Wert an, wenn du die Höhe ändern willst)

# Schwerkraft vom Projekt holen (oder Standardwert)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite
@onready var minigame_scene = get_parent() # Zugriff auf die Haupt-Minigame-Szene

# Invincibility variables
var is_invincible = false
@onready var invincibility_timer = $InvincibilityTimer
@onready var invisibility_timer = $InvisibilityTimer # Timer for blinking

func _physics_process(delta):
	# Schwerkraft hinzufügen
	if not is_on_floor():
		velocity.y += gravity * delta

	# Sprung-Input verarbeiten
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Richtung ermitteln (Links/Rechts)
	var direction = Input.get_axis("ui_left", "ui_right")

	# Bewegung anwenden
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED) # Langsamer werden

	# --- KORREKTUR: LOGIK FÜR SPRITE-DREHUNG ---
	# Diese Logik muss JEDES MAL laufen, wenn eine Richtung gedrückt wird,
	# egal ob in der Luft oder am Boden.
	if direction != 0:
		animated_sprite.flip_h = (direction < 0) # Sprite spiegeln bei Linkslauf
	# --- ENDE KORREKTUR ---

	# --- Logik für Animationen ---
	if not is_on_floor():
		# In der Luft:
		if animated_sprite.animation != "Jump_Loop":
			animated_sprite.play("Jump_Loop")
	elif direction != 0:
		# Läuft (am Boden)
		animated_sprite.play("Run")
	else:
		# Steht still (am Boden)
		animated_sprite.play("Idle")
	# --- ENDE ANIMATIONS-LOGIK ---

	# Bewegung ausführen
	move_and_slide()


func _on_spikes_body_entered(body):
	if body == self and not is_invincible:
		take_damage()

func take_damage():
	print("Player took damage!")
	is_invincible = true
	invincibility_timer.start(1.0) # 1 Sekunde unverwundbar
	invisibility_timer.start(0.1) # Start blinking
	modulate.a = 0.5 # Start semi-transparent

	# Rufe die player_died Funktion in der Haupt-Minigame-Szene auf
	if minigame_scene.has_method("player_died"):
		minigame_scene.player_died()
	else:
		print("FEHLER: player_died() Methode nicht in minigame_scene gefunden!")


func _on_invincibility_timer_timeout():
	is_invincible = false
	modulate.a = 1.0 # Fully visible again
	invisibility_timer.stop() # Stop blinking


func _on_invisibility_timer_timeout():
	# Toggle visibility for blinking effect
	if is_invincible:
		modulate.a = 1.0 - modulate.a # Flip between 0.5 and 1.0
		invisibility_timer.start(0.1) # Restart timer for next blink
