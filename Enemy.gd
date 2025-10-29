# Enemy.gd

extends CharacterBody2D

# Definiere ein Signal, das gesendet wird, wenn der Gegner den Player trifft
signal player_hit()

# Werte können im Inspektor für jede Gegner-Instanz angepasst werden
@export var speed: float = 120.0
@export var walk_distance: float = 250.0
@export var gravity: float = 980.0 # Standard Godot Schwerkraft ist 980

# Interne Variablen
var initial_x: float = 0.0
var direction: int = 1


func _ready():
	initial_x = position.x
	
	# Optional: Gib dem Gegner eine Farbe zur Unterscheidung (z.B. Rot)
	if has_node("Sprite"): # Sicherstellen, dass ein Sprite-Node existiert
		$Sprite.modulate = Color(1.0, 0.0, 0.0, 1.0) # Rot färben


func _physics_process(delta):
	# Schwerkraft hinzufügen, wenn nicht auf dem Boden
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Richtung umkehren, wenn die Grenzen erreicht sind
	if position.x > initial_x + walk_distance:
		direction = -1 # Nach links bewegen
	elif position.x < initial_x - walk_distance:
		direction = 1 # Nach rechts bewegen
		
	# Horizontale Geschwindigkeit setzen
	velocity.x = direction * speed
	
	# Sprite spiegeln basierend auf der Richtung
	if has_node("Sprite"):
		$Sprite.flip_h = (direction == -1) # Spiegeln, wenn nach links
	
	# Bewegung ausführen
	move_and_slide()


# Wird ausgelöst, wenn der Spieler die Hitbox berührt (body_entered Signal von Area2D)
func _on_hitbox_body_entered(body):
	# Prüfen, ob der kollidierende Körper der Spieler ist
	if body.name == "Player":
		
		# KORRIGIERT: Prüft auf Unverwundbarkeit ('is_invincible')
		# 'is_invisible' existiert im Player-Skript nicht.
		if body.has_method("take_damage") and not body.is_invincible:
			
			# NEU: Sende das Signal, anstatt direkt player_died aufzurufen
			player_hit.emit() 
			
			# Stoppe die Logik des Gegners SOFORT, um Mehrfach-Hits zu vermeiden
			set_process(false) 
			set_physics_process(false) 
			# Optional: Gegner könnte auch eine Animation abspielen oder verschwinden
			# queue_free() # Beispiel: Gegner entfernen
