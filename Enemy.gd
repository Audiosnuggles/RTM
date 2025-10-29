# Enemy.gd

extends CharacterBody2D

# Definiere ein Signal, das gesendet wird, wenn der Gegner den Player trifft
signal player_hit() 

# Werte können im Inspektor für jede Gegner-Instanz angepasst werden
@export var speed: float = 120.0
@export var walk_distance: float = 250.0 
@export var gravity: float = 980.0 

# Interne Variablen
var initial_x: float = 0.0
var direction: int = 1 


func _ready():
	initial_x = position.x
	
	if has_node("Sprite"):
		$Sprite.modulate = Color(1.0, 0.0, 0.0, 1.0) 


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if position.x > initial_x + walk_distance:
		direction = -1 
	elif position.x < initial_x - walk_distance:
		direction = 1 
		
	velocity.x = direction * speed
	
	if has_node("Sprite"):
		$Sprite.flip_h = (direction == -1)
	
	move_and_slide()


# Wird ausgelöst, wenn der Spieler die Hitbox berührt (body_entered Signal von Area2D)
func _on_hitbox_body_entered(body):
	
	if body.name == "Player":
		
		# Prüft auf Unverwundbarkeit und sendet das Signal
		if not body.is_invincible and not body.is_invisible:
			
			# NEU: Sende das Signal, anstatt direkt player_died aufzurufen
			player_hit.emit() 
			
			# Stoppe die Logik des Gegners SOFORT
			set_process(false) 
			set_physics_process(false)
