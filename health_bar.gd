# health_bar.gd
extends ProgressBar

# Diese Funktion wird von MainScene.gd aufgerufen, wenn Combat.corrupted_health_changed sendet
func _on_corrupted_health_changed():
	if not is_instance_valid(Combat):
		return
	
	# 1. Maximalwert und aktuellen Wert setzen
	self.max_value = Combat.healing_target_health
	self.value = Combat.corrupted_current_health
	
	# 2. Text aktualisieren
	var current_hp = round(Combat.corrupted_current_health)
	var max_hp = round(Combat.healing_target_health)
	
	# WICHTIG: Stellt sicher, dass die Child-Node "HealthLabel" existiert.
	if is_instance_valid($HealthLabel):
		$HealthLabel.text = str(current_hp) + " / " + str(max_hp)

# HINWEIS: Die alte _process-Funktion wurde entfernt, da die Aktualisierung jetzt über Signale läuft.
