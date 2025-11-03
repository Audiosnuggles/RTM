extends CharacterBody2D

signal player_hit()

@export var speed: float = 120.0
@export var walk_distance: float = 250.0
@export var wait_time: float = 5.0
@export var gravity: float = 980.0
@export var shoot_cooldown: float = 1.0
# Wir brauchen sight_range nicht mehr, da wir direkt auf den Spieler zielen

const BULLET_SCENE = preload("res://Scenes/Bullet.tscn") # Pfad ggf. anpassen!

enum { STATE_WALKING, STATE_WAITING, STATE_SHOOTING }
var current_state = STATE_WALKING

var initial_x: float = 0.0
var direction: int = 1 # 1 = rechts, -1 = links

var player_in_range: CharacterBody2D = null # Speichert den Spieler, wenn er in der "Blase" ist

@onready var animated_sprite = $AnimatedSprite2D
@onready var wait_timer = $WaitTimer
@onready var player_detector = $PlayerDetector # Das "Auge", das WÄNDE sucht
@onready var shoot_timer = $ShootTimer
@onready var muzzle = $Muzzle


func _ready():
	initial_x = position.x
	shoot_timer.wait_time = shoot_cooldown
	set_state(STATE_WALKING)


func set_state(new_state):
	if new_state == current_state:
		return

	match current_state:
		STATE_WAITING:
			wait_timer.stop()
		STATE_SHOOTING:
			shoot_timer.stop()
			animated_sprite.play("default") # Zurück zur Lauf-Animation

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
	# 1. Schwerkraft
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Zustands-Wechsel (gesteuert durch die "Blase")
	if player_in_range:
		set_state(STATE_SHOOTING)
	elif current_state == STATE_SHOOTING: # und player_in_range ist null
		set_state(STATE_WALKING)

	# 3. Logik *innerhalb* des aktuellen Zustands
	match current_state:
		
		STATE_WALKING:
			velocity.x = direction * speed
			animated_sprite.flip_h = (direction == 1) # 1 = rechts
			
			var is_at_boundary = false
			if direction == 1 and position.x > initial_x + walk_distance:
				is_at_boundary = true
			elif direction == -1 and position.x < initial_x - walk_distance:
				is_at_boundary = true
			if is_at_boundary:
				set_state(STATE_WAITING)

		STATE_WAITING:
			velocity.x = 0
			pass # Wartet auf Timer...

		STATE_SHOOTING:
			velocity.x = 0
			
			if is_instance_valid(player_in_range):
				# 1. Drehe dich IMMER zum Spieler
				var player_is_right = (player_in_range.global_position.x > global_position.x)
				animated_sprite.flip_h = player_is_right # true = rechts, false = links
				
				# 2. "Auge" (RayCast) DIREKT auf den Spieler richten
				#    Wir müssen die Position des Spielers in die LOKALE Koordinate des Gegners umrechnen
				player_detector.target_position = to_local(player_in_range.global_position)
				
				# 3. Prüfen, ob eine WAND (Layer 1) im Weg ist
				player_detector.force_raycast_update()
				var is_wall_in_way = player_detector.is_colliding()
				
				# 4. Schießen, wenn Cooldown vorbei UND keine Wand im Weg ist
				if not is_wall_in_way and shoot_timer.is_stopped():
					shoot()
					shoot_timer.start()

	move_and_slide()


func shoot():
	print("FEUER! (Finale KI)")
	var bullet = BULLET_SCENE.instantiate()
	
	# Dein Sprite schaut standardmäßig nach LINKS (flip_h=false)
	var shoot_direction = Vector2.LEFT
	if animated_sprite.flip_h: # flip_h = true (schaut nach rechts)
		shoot_direction = Vector2.RIGHT
		
	get_parent().add_child(bullet)
	bullet.start(muzzle.global_position, shoot_direction)


func _on_wait_timer_timeout():
	direction = -direction 
	set_state(STATE_WALKING)


func _on_hitbox_body_entered(body):
	# Berührungsschaden (Hitbox ist eine Area2D, die nach Layer 2 (Spieler) sucht)
	if body.is_in_group("Player") or body.name == "Player":
		if body.has_method("take_damage") and not body.is_invincible:
			player_hit.emit()

# --- Funktionen für die "Blase" (DetectionRange) ---

func _on_detection_range_body_entered(body):
	# WICHTIG: Prüfen, ob es der Spieler ist (auf Layer 2)
	if body.is_in_group("Player") or body.name == "Player":
		player_in_range = body # Speichert den Spieler

func _on_detection_range_body_exited(body):
	if body.is_in_group("Player") or body.name == "Player":
		player_in_range = null # Vergisst den Spieler
