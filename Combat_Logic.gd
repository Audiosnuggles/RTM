extends Node

signal healing_impulse_fired  
signal corrupted_healed  
# KORREKTUR: Das von main_scene.gd benötigte Signal wurde hinzugefügt
signal corrupted_health_changed(new_health: float, max_health: float) 

# NEUE VARIABLE: Speichert die Texture2D-Assets der geretteten Roboter
var collected_drones: Array[Texture2D] = []

# NEUE ARRAY: Speichert die visuellen Assets pro Level
# HINWEIS: Die Pfade MÜSSEN zu deinen tatsächlichen Dateien passen!
const LEVEL_ASSETS = [
	{
		"sprite": preload("res://sprites/drohne_1_sheet.png"), 
		"background": preload("res://backgrounds/bg_1_lab.png"),
		"hp_increase": 0.0
	},
	{
		"sprite": preload("res://sprites/drohne_2_sheet.png"),
		"background": preload("res://backgrounds/bg_2_forest.png"),
		"hp_increase": 100.0
	},
	{
		"sprite": preload("res://sprites/drohne_3_sheet.png"),
		"background": preload("res://backgrounds/bg_3_space.png"),
		"hp_increase": 200.0
	}
]

var current_level_index = 0

# --- WÄHRUNG / UPGRADES ---
var harmony_fragments = 0
var upgrade_cost = 100
var echo_healing_power = 10.0
var healing_interval = 1.0 
var click_upgrade_cost = 50
var echo_click_power = 1.0 
var time_until_next_heal = 0.0

# --- FEIND (CORRUPTED) STATISTIKEN ---
var corrupted_max_health = 500.0
var corrupted_current_health = 0.0
var healing_target_health = 500.0 

var is_combat_active = false
var is_corrupted_healed = false


func _process(delta):
	if is_combat_active and not is_corrupted_healed:
		time_until_next_heal -= delta
		
		if time_until_next_heal <= 0:
			_perform_passive_healing()
			time_until_next_heal = healing_interval

func _perform_passive_healing():
	corrupted_current_health += echo_healing_power
	# KORREKTUR: Signal muss gesendet werden
	corrupted_health_changed.emit(corrupted_current_health, healing_target_health)
	_check_for_win()
	healing_impulse_fired.emit()

func perform_click_impulse():
	if is_combat_active and not is_corrupted_healed:
		corrupted_current_health += echo_click_power
		# KORREKTUR: Signal muss gesendet werden
		corrupted_health_changed.emit(corrupted_current_health, healing_target_health)
		_check_for_win()

func _check_for_win():
	if corrupted_current_health >= healing_target_health:
		corrupted_current_health = healing_target_health
		is_corrupted_healed = true
		is_combat_active = false
		
		# ------------------------------------------------------------------
		# NEUE LOGIK: Sammle den Roboter, bevor der Level-Index erhöht wird!
		# ------------------------------------------------------------------
		var asset_index_to_save = current_level_index % LEVEL_ASSETS.size()
		var saved_asset = LEVEL_ASSETS[asset_index_to_save].sprite
		
		if saved_asset and not collected_drones.has(saved_asset):
			collected_drones.append(saved_asset)
		
		# Belohnung (Fragmente)
		var reward = round(corrupted_max_health * 0.5) 
		harmony_fragments += reward
		
		corrupted_healed.emit() 
		
		current_level_index += 1


# KORREKTUR: Die Funktion muss das level_index Argument akzeptieren, 
# um mit start_next_corrupted in main_scene.gd zu synchronisieren
func start_new_combat(level_index: int):
	# Ignoriert das Argument, da die Logik current_level_index verwendet,
	# aber akzeptiert es, um den Fehler in main_scene.gd zu verhindern.
	
	var lv_index = current_level_index # Verwendet die interne Variable
	
	if lv_index >= LEVEL_ASSETS.size():
		lv_index = 0
		current_level_index = 0
		corrupted_max_health += 100.0 
	else:
		corrupted_max_health = 500.0 + LEVEL_ASSETS[lv_index].hp_increase

	healing_target_health = corrupted_max_health
	corrupted_current_health = 0.0
	is_corrupted_healed = false
	is_combat_active = true
	time_until_next_heal = healing_interval
	# KORREKTUR: Initiales Signal zum Anzeigen/Zurücksetzen der Health Bar
	corrupted_health_changed.emit(corrupted_current_health, healing_target_health)

func upgrade_healing_power():
	if harmony_fragments >= upgrade_cost:
		harmony_fragments -= upgrade_cost
		echo_healing_power += 10.0 
		upgrade_cost = round(upgrade_cost * 1.5) 
		return true
	return false

func upgrade_click_power():
	if harmony_fragments >= click_upgrade_cost:
		harmony_fragments -= click_upgrade_cost
		echo_click_power += 1.0 
		click_upgrade_cost = round(click_upgrade_cost * 2.0) 
		return true
	return false
