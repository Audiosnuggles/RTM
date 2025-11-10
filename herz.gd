# Herz.gd
extends Area2D

func _ready():
	# Verbindet das "body_entered"-Signal automatisch mit diesem Skript
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Prüfen, ob der Körper (body) die "heal"-Funktion hat (also der Spieler ist)
	if body.has_method("heal"):
		
		# Rufe die 'heal'-Funktion auf dem Spieler auf
		# Die Funktion gibt 'true' zurück, wenn die Heilung geklappt hat
		if body.heal(1):
			# Sammle das Herz ein (zerstöre es)
			queue_free()
