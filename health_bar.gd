# health_bar.gd
extends ProgressBar

var health_label: Label = null 

func _ready():
	# 1. Label finden
	health_label = get_node_or_null("HealthLabel") 
	
	# 2. Eine Frame-Verzögerung einfügen, um sicherzustellen, dass Combat bereit ist
	await get_tree().process_frame
	
	# 3. Initiales Update der Leiste und des Textes
	_on_corrupted_health_changed(Combat.corrupted_current_health, Combat.healing_target_health)
	
# --- FUNKTION VON MAINSCENE/COMBAT AUFGERUFEN ---

func _on_corrupted_health_changed(new_health: float, max_health: float):
	if not is_instance_valid(Combat):
		return
		
	# 1. ProgressBar Werte setzen
	self.max_value = max_health
	self.value = new_health
	
	# 2. Das Health-Label aktualisieren
	if is_instance_valid(health_label):
		health_label.text = str(int(new_health)) + " / " + str(int(max_health))
