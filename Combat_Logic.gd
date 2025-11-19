extends Node

# --- Signale ---
signal healing_impulse_fired(position: Vector2) 
signal corrupted_healed
signal corrupted_health_changed(new_health: float, max_health: float) 
signal robot_status_changed(robot_id: String, new_status: int)

# --- NEUE STATUS-DEFINITIONEN FÜR ROBOTER ---
const ROBOT_STATUS = {
	"MISSION_LOCKED": 0,         # Mission kann noch nicht gestartet werden
	"REQUIRES_HACKING": 1,       # Roboter geborgen (Platformer-Sieg), Hack erforderlich
	"GARAGE_READY": 2            # Roboter ist vollständig freigeschaltet (für Upgrades/Produktion)
}

# --- STATUS-VERFOLGUNG ---
var robot_states = {
	"robot_1": ROBOT_STATUS.MISSION_LOCKED, # Startzustand des ersten Roboters
	"robot_2": ROBOT_STATUS.MISSION_LOCKED, # Mission I
	"robot_3": ROBOT_STATUS.MISSION_LOCKED, # Mission II
}
var current_mission_robot_id: String = "" # Die ID des Roboters, der gerade verfolgt wird
var robot_stats = {} # Upgrades pro Roboter
var infrastructure_points = 0.0

# --- Assets und Level-Steuerung ---
var collected_drones: Array[Texture2D] = []

# DEFINIERT NUR DIE ASSETS FÜR DEN KLICKER-KAMPF
const CLICKER_LEVEL_ASSETS = [
	{
		"sprite": preload("res://sprites/drohne_1_sheet.png"),
		"background": preload("res://backgrounds/bg_1_lab.png"),
		"hp_increase": 0.0 # Klicker Level 0 (Intro)
	},
	{
		"sprite": preload("res://sprites/drohne_2_sheet.png"),
		"background": preload("res://backgrounds/bg_2_forest.png"),
		"hp_increase": 200.0 # Klicker Level 1 (Mission I)
	},
	{
		"sprite": preload("res://sprites/drohne_3_sheet.png"),
		"background": preload("res://backgrounds/bg_3_space.png"),
		"hp_increase": 450.0 # Klicker Level 2 (Mission II)
	}
]

var current_level_index = 0 
var last_klicker_level_loaded = 0 
var has_completed_intro = false

# --- WÄHRUNG / UPGRADES ---
var harmony_fragments = 0.0 
var upgrade_cost = 100.0
var echo_healing_power = 10.0
var healing_interval = 1.0
var click_upgrade_cost = 50.0
var echo_click_power = 1.0
var time_until_next_heal = 0.0

# --- FEIND (CORRUPTED) STATISTIKEN ---
var corrupted_max_health = 500.0
var corrupted_current_health = 0.0
var healing_target_health = 500.0

var is_combat_active = false
var is_corrupted_healed = false


func _process(_delta): 
	if is_combat_active and not is_corrupted_healed:
		time_until_next_heal -= _delta
		
		if time_until_next_heal <= 0:
			_perform_passive_healing()
			time_until_next_heal = healing_interval

func _perform_passive_healing():
	corrupted_current_health += echo_healing_power
	_check_for_win()
	
	healing_impulse_fired.emit(Vector2.ZERO) 
	corrupted_health_changed.emit(corrupted_current_health, healing_target_health)

func perform_click_impulse():
	if is_combat_active and not is_corrupted_healed:
		corrupted_current_health += echo_click_power
		_check_for_win()
		corrupted_health_changed.emit(corrupted_current_health, healing_target_health)

func _check_for_win():
	if corrupted_current_health >= healing_target_health:
		corrupted_current_health = healing_target_health
		is_corrupted_healed = true
		is_combat_active = false
		
		var asset_index_to_save = last_klicker_level_loaded % CLICKER_LEVEL_ASSETS.size()
		var saved_asset = CLICKER_LEVEL_ASSETS[asset_index_to_save].sprite
		
		if saved_asset and not collected_drones.has(saved_asset):
			collected_drones.append(saved_asset)
		
		var reward = round(healing_target_health * 0.5)
		harmony_fragments += reward
		
		corrupted_healed.emit()
		
		# --- NEUE LOGIK FÜR STATUS ---
		if last_klicker_level_loaded == 0:
			# Intro-Clicker beendet
			has_completed_intro = true 
			set_robot_garage_ready("robot_1")
		elif current_mission_robot_id != "":
			# Missions-Clicker beendet
			set_robot_garage_ready(current_mission_robot_id)
			current_level_index += 1
		# --- ENDE NEUE LOGIK ---


func start_new_combat(level_index: int): 
	
	last_klicker_level_loaded = level_index
	
	var base_hp = 500.0
	var hp_increase = 0.0
	
	if level_index < CLICKER_LEVEL_ASSETS.size():
		hp_increase = CLICKER_LEVEL_ASSETS[level_index].hp_increase
	else:
		var multiplier = level_index - CLICKER_LEVEL_ASSETS.size() + 1
		var last_asset_hp = CLICKER_LEVEL_ASSETS.back().hp_increase if CLICKER_LEVEL_ASSETS.size() > 0 else 0
		hp_increase = last_asset_hp + (100.0 * multiplier * multiplier)
		
	corrupted_max_health = base_hp + hp_increase
	
	healing_target_health = corrupted_max_health
	corrupted_current_health = 0.0
	is_corrupted_healed = false
	is_combat_active = true
	time_until_next_heal = healing_interval
	
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

# --- NEUE HELFER-FUNKTIONEN FÜR DEN STATUS ---

func set_robot_requires_hacking(robot_id: String):
	if robot_states.has(robot_id):
		robot_states[robot_id] = ROBOT_STATUS.REQUIRES_HACKING
		robot_status_changed.emit(robot_id, ROBOT_STATUS.REQUIRES_HACKING)
		print("Status ", robot_id, ": REQUIRES_HACKING")

func set_robot_garage_ready(robot_id: String):
	if robot_states.has(robot_id):
		robot_states[robot_id] = ROBOT_STATUS.GARAGE_READY
		robot_status_changed.emit(robot_id, ROBOT_STATUS.GARAGE_READY)
		
		if not robot_stats.has(robot_id):
			robot_stats[robot_id] = {"speed_bonus": 0.0, "jump_bonus": 0.0, "extra_health": 0}
		print("Status ", robot_id, ": GARAGE_READY")
