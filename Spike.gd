extends Area2D

# Diese Funktion wird vom StompDetector (dem Kind) aufgerufen
func _on_stomp_detector_body_entered(body):
	# Prüfen, ob es der Spieler ist UND ob er von oben kommt
	if body.is_in_group("Player") and body.velocity.y > 0:
		
		# 1. Spieler abprallen lassen
		if body.has_method("bounce"):
			body.bounce()
			
		# 2. Diese Spinne zerstören
		queue_free()


# Diese Funktion wird von DIESEM Knoten (der Area2D, die "Spike" heißt) aufgerufen
func _on_body_entered(body):
	# Prüfen, ob es der Spieler ist
	if body.is_in_group("Player"):
		
		# Wenn die Seiten berührt werden, verletze den Spieler
		if body.has_method("take_damage") and not body.is_invincible:
			body.take_damage(1)
