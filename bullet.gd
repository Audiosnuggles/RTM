extends Area2D

var speed = 600
var velocity = Vector2.ZERO

func start(start_position, direction_vector):
	global_position = start_position
	velocity = direction_vector * speed

func _physics_process(delta):
	position += velocity * delta


# --- DAS IST DIE WICHTIGE FUNKTION MIT DEBUGGING ---
# Wird aufgerufen, wenn die Kugel etwas auf ihrer "Maske" (Layer 2) trifft
func _on_body_entered(body):
	
	# --- DEBUGGING SCHRITT 1 ---
	print("--- KUGEL-TREFFER-TEST ---")
	print("1. Kugel hat 'body_entered' Signal ausgelöst.")
	print("2. Getroffenes Objekt: ", body.name)

	# --- DEBUGGING SCHRITT 2 ---
	# Prüfen, ob das Objekt der Spieler ist
	# (Wir prüfen den Namen UND den Layer, um sicherzugehen)
	if body.name == "Player" or body.collision_layer == 2:
		print("3. Objekt ist 'Player'.")
		
		# --- DEBUGGING SCHRITT 3 ---
		# Prüfen, ob der Spieler die Funktion "take_damage" hat
		if body.has_method("take_damage"):
			print("4. Spieler hat 'take_damage'. Funktion wird aufgerufen...")
			body.take_damage(1)
		else:
			print("4. FEHLER: Spieler hat 'take_damage' NICHT!")
	else:
		print("3. Objekt ist NICHT 'Player'.")

	# Zerstöre die Kugel, sobald sie etwas getroffen hat
	queue_free()


# Wird aufgerufen, wenn die Kugel den Bildschirm verlässt
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
