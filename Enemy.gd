extends CharacterBody2D

signal player_hit()

@export var speed: float = 120.0
@export var walk_distance: float = 250.0
@export var wait_time: float = 5.0
@export var gravity: float = 980.0
@export var shoot_cooldown: float = 1.0

# +++ NEU +++
# Diese Checkbox erscheint jetzt im Inspektor für jeden Gegner
@export var can_be_stomped: bool = true # Standard ist 'true' (Spinne)

const BULLET_SCENE = preload("res://Scenes/Bullet.tscn") # Pfad ggf. anpassen!

enum { STATE_WALKING, STATE_WAITING, STATE_SHOOTING }
var current_state = STATE_WALKING

var initial_x: float = 0.0
var direction: int = 1 # 1 = rechts, -1 = links

var player_in_range: CharacterBody2D = null

@onready var animated_sprite = $AnimatedSprite2D
@onready var wait_timer = $WaitTimer
@onready var player_detector = $PlayerDetector
@onready var shoot_timer = $ShootTimer
@onready var muzzle = $Muzzle


func _ready():
	initial_x = position.x
	shoot_timer.wait_time = shoot_cooldown
	set_state(STATE_WALKING)


func set_state(new_state):
	# ... (deine set_state Funktion bleibt unverändert) ...
	if new_state == current_state:
		return
	match current_state:
		STATE_WAITING:
			wait_timer.stop()
		STATE_SHOOTING:
			shoot_timer.stop()
			animated_sprite.play("default")
	current_state = new_state
	match current_state:
		STATE_WALKING:
			animated_sprite.play("default")
		STATE_WAITING:
			velocity.x = 0
			animated_sprite.stop()
			animated_sprite.frame = 0
			wait_timer.start(wait_time)
		STATE_SHOOTING:
			velocity.x = 0
			animated_sprite.stop()
			animated_sprite.frame = 0


func _physics_process(delta):
	# ... (deine _physics_process Funktion bleibt unverändert) ...
	if not is_on_floor():
		velocity.y += gravity * delta
	if player_in_range:
		set_state(STATE_SHOOTING)
	elif current_state == STATE_SHOOTING:
		set_state(STATE_WALKING)
	match current_state:
		STATE_WALKING:
			velocity.x = direction * speed
			animated_sprite.flip_h = (direction == 1)
			var is_at_boundary = false
			if direction == 1 and position.x > initial_x + walk_distance:
				is_at_boundary = true
			elif direction == -1 and position.x < initial_x - walk_distance:
				is_at_boundary = true
			if is_at_boundary:
				set_state(STATE_WAITING)
		STATE_WAITING:
			velocity.x = 0
			pass
		STATE_SHOOTING:
			velocity.x = 0
			if is_instance_valid(player_in_range):
				var player_is_right = (player_in_range.global_position.x > global_position.x)
				animated_sprite.flip_h = player_is_right
				player_detector.target_position = to_local(player_in_range.global_position)
				player_detector.force_raycast_update()
				var is_wall_in_way = player_detector.is_colliding()
				if not is_wall_in_way and shoot_timer.is_stopped():
					shoot()
					shoot_timer.start()
	move_and_slide()


func shoot():
	# ... (deine shoot Funktion bleibt unverändert) ...
	print("FEUER! (Finale KI)")
	var bullet = BULLET_SCENE.instantiate()
	var shoot_direction = Vector2.LEFT
	if animated_sprite.flip_h:
		shoot_direction = Vector2.RIGHT
	get_parent().add_child(bullet)
	bullet.start(muzzle.global_position, shoot_direction)


func _on_wait_timer_timeout():
	# ... (deine Timer Funktion bleibt unverändert) ...
	direction = -direction 
	set_state(STATE_WALKING)


func _on_hitbox_body_entered(body):
	# ... (deine Hitbox Funktion bleibt unverändert) ...
	if body.is_in_group("Player") or body.name == "Player":
		if body.has_method("take_damage") and not body.is_invincible:
			player_hit.emit()

# --- Funktionen für die "Blase" (DetectionRange) ---

func _on_detection_range_body_entered(body):
	# ... (deine DetectionRange Funktion bleibt unverändert) ...
	if body.is_in_group("Player") or body.name == "Player":
		player_in_range = body

func _on_detection_range_body_exited(body):
	# ... (deine DetectionRange Funktion bleibt unverändert) ...
	if body.is_in_group("Player") or body.name == "Player":
		player_in_range = null


# +++ HIER IST DIE NEUE LOGIK (StompDetector) +++
# Diese Funktion hast du schon, wir füllen sie nur
func _on_stomp_detector_body_entered(body: Node2D) -> void:
	# Prüfen, ob es der Spieler ist
	if body.is_in_group("Player") or body.name == "Player":
		
		# 1. Ist dieser Gegner zerstampfbar UND fällt der Spieler?
		if can_be_stomped and body.velocity.y > 0:
			
			# Ja (Spinne) -> Töte Gegner, lass Spieler abprallen
			queue_free() # Gegner stirbt
			if body.has_method("bounce"):
				body.bounce() # Spieler prallt ab
				
		else:
			# Nein (Roboter ODER Spieler springt von unten) -> Spieler verletzen
			if body.has_method("take_damage") and not body.is_invincible:
				body.take_damage(1)


# +++ HIER IST DIE NEUE LOGIK (HurtBox) +++
# Diese Funktion hast du schon, wir füllen sie nur
# Diese Area deckt die SEITEN des Gegners ab
func _on_hurt_box_body_entered(body: Node2D) -> void:
	# Prüfen, ob es der Spieler ist
	if body.is_in_group("Player") or body.name == "Player":
		
		# Berührung an der Seite tut IMMER weh
		if body.has_method("take_damage") and not body.is_invincible:
			body.take_damage(1)
