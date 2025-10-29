extends Node2D

const UI_LAYER_PATH = "UI_Layer/" 
var next_round_timer: Timer
var video_player: VideoStreamPlayer 

# Füge die Referenz für das Minigame hinzu!
const MINIGAME_SCENE_PATH = preload("res://minigame_scene.tscn") 
var current_minigame: Node = null 

# --- KONSTANTEN ---
const MISSION_1_BUTTON_PATH = UI_LAYER_PATH + "HubMap/Mission_1_Button"
const MISSION_2_BUTTON_PATH = UI_LAYER_PATH + "HubMap/Mission_2_Button" 
const MISSION_3_BUTTON_PATH = UI_LAYER_PATH + "HubMap/Mission_3_Button" 
const MISSION_4_BUTTON_PATH = UI_LAYER_PATH + "HubMap/Mission_4_Button" 
const MISSION_5_BUTTON_PATH = UI_LAYER_PATH + "HubMap/Mission_5_Button" # KORRIGIERT: 5. Button
const DRONE_GALLERY_LABEL_PATH = UI_LAYER_PATH + "Drone_Gallery_Label" 
const SEARCH_LABEL_PATH = UI_LAYER_PATH + "Search_Screen/Typewriter_Label"

# ARRAY DER MISSIONS-BUTTON-PFADE FÜR EINFACHES DURCHLAUFEN
const MISSION_BUTTONS_MAP = [
	MISSION_1_BUTTON_PATH,
	MISSION_2_BUTTON_PATH,
	MISSION_3_BUTTON_PATH,
	MISSION_4_BUTTON_PATH, 
	MISSION_5_BUTTON_PATH, # KORRIGIERT: 5. Button
]

# FARBEN UND ZUSTÄNDE
const COLOR_COMPLETED = Color(0.0, 1.0, 0.0)
const COLOR_CURRENT = Color(1.0, 1.0, 0.0)  
const COLOR_LOCKED = Color(1.0, 0.0, 0.0)   

enum GameState {
	STATE_TITLE,
	STATE_STORY,
	STATE_HUB_MAP,
	STATE_COMBAT,
	STATE_INVENTORY,
	STATE_MINIGAME
}
var current_state: GameState = GameState.STATE_TITLE 

const HEALED_SPRITE_SIZE = Vector2(256, 256)
const HEALED_SPRITE_OFFSET_X = 256 

var level_to_start: int = -1 

# ZUSTANDS-VARIABLEN FÜR DIE MANUELLE STEUERUNG
var search_text_updated: bool = false 
var enter_text_shown: bool = false   
var simulated_progress: float = 0.0   
const SEARCH_DURATION: float = 8.0     


# --------------------------------------------------------------------------------------
## INITIALISIERUNG
# --------------------------------------------------------------------------------------

func _ready():
	var corrupted_node = get_node("Corrupted_Visual")
	next_round_timer = get_node("Next_Round_Timer") 
	video_player = get_node("Video_Player") 
	
	var health_bar = get_node(UI_LAYER_PATH + "Health_Bar") 
	
	if is_instance_valid(corrupted_node):
		Combat.healing_impulse_fired.connect(corrupted_node.apply_healing_visual)
		Combat.corrupted_healed.connect(_on_corrupted_healed)
	
	if is_instance_valid(Combat) and is_instance_valid(health_bar):
		# KORREKTUR: Robuste Godot 4 Callable-Syntax
		Combat.corrupted_health_changed.connect(Callable(health_bar, "_on_corrupted_health_changed")) 

	if is_instance_valid(video_player):
		video_player.position = Vector2(0, 0)
		video_player.size = Vector2(1920, 1080)
		video_player.hide() 

	# Stellt sicher, dass die MainCamera existiert und beim Start aktiv ist.
	var main_cam = get_node_or_null("MainCamera")
	if is_instance_valid(main_cam):
		main_cam.enabled = true
		main_cam.make_current()
	else:
		print("WARNUNG: Node 'MainCamera' nicht in main_scene.tscn gefunden. Bitte füge eine Camera2D mit diesem Namen hinzu!")

	get_node("Corrupted_Visual").hide()
	_hide_ui() 
	
	goto_title_screen()

func _unhandled_input(event):
	if current_state == GameState.STATE_COMBAT:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Combat.perform_click_impulse() 
			Combat.healing_impulse_fired.emit(event.position) 
			get_viewport().set_input_as_handled()


# --------------------------------------------------------------------------------------
## NAVIGATIONS-FUNKTIONEN
# --------------------------------------------------------------------------------------

func goto_title_screen():
	current_state = GameState.STATE_TITLE
	
	var title_screen = get_node(UI_LAYER_PATH + "TitleScreen")
	var hub_map = get_node(UI_LAYER_PATH + "HubMap")
	var story_intro = get_node(UI_LAYER_PATH + "StoryIntro")
	
	if is_instance_valid(title_screen):
		title_screen.show()
	
	if is_instance_valid(hub_map):
		hub_map.hide()
	if is_instance_valid(story_intro):
		story_intro.hide()
	
	print("Zustand: TITLE SCREEN.")

func goto_story_intro():
	current_state = GameState.STATE_STORY
	
	var title_screen = get_node(UI_LAYER_PATH + "TitleScreen")
	if is_instance_valid(title_screen):
		title_screen.hide()
		
	var story_intro = get_node(UI_LAYER_PATH + "StoryIntro")
	if is_instance_valid(story_intro):
		story_intro.show()
		
	print("Zustand: STORY INTRO.")

func goto_hub_map():
	current_state = GameState.STATE_HUB_MAP
	
	get_node("Corrupted_Visual").hide()
	
	var main_bg = get_node("Background")
	if is_instance_valid(main_bg):
		main_bg.show()
	
	var story_intro = get_node(UI_LAYER_PATH + "StoryIntro")
	if is_instance_valid(story_intro):
		story_intro.hide()
		
	var hub_map_node = get_node(UI_LAYER_PATH + "HubMap") 
	if is_instance_valid(hub_map_node):
		hub_map_node.show()
	
	_hide_ui() 
	
	_update_drone_gallery() 
	_show_ui() 
	
	for i in range(MISSION_BUTTONS_MAP.size()):
		var button_path = MISSION_BUTTONS_MAP[i]
		var button = get_node(button_path)
		
		if is_instance_valid(button):
			button.show()
			
			if i < Combat.current_level_index:
				button.modulate = COLOR_COMPLETED
				button.disabled = false
			elif i == Combat.current_level_index:
				button.modulate = COLOR_CURRENT
				button.disabled = false
			else:
				button.modulate = COLOR_LOCKED
				button.disabled = true
			
	print("Zustand: HUB/WORLDMAP.")

func goto_combat(level_index: int):
	if current_state != GameState.STATE_HUB_MAP:
		print("FEHLER: Kampf kann nur aus HUB/MAP gestartet werden.")
		return
		
	level_to_start = level_index 
	
	var hub_map_node = get_node(UI_LAYER_PATH + "HubMap")
	if is_instance_valid(hub_map_node):
		hub_map_node.hide()
	
	if level_index == 1:
		current_state = GameState.STATE_MINIGAME
		start_minigame_level() 
	else:
		_show_search_screen(true) 

func _return_to_combat_after_transition():
	var search_screen = get_node(UI_LAYER_PATH + "Search_Screen")
	if is_instance_valid(search_screen):
		search_screen.hide()
	
	if is_instance_valid(video_player):
		video_player.hide()
		
	var main_cam = get_node_or_null("MainCamera")
	if is_instance_valid(main_cam):
		main_cam.enabled = true
		main_cam.make_current()
		
	current_state = GameState.STATE_COMBAT
	
	get_node("Corrupted_Visual").show()
	_show_ui() 
	
	var health_bar = get_node(UI_LAYER_PATH + "Health_Bar")
	if is_instance_valid(health_bar):
		health_bar.show()
		
	var klicker_level_index = level_to_start
	if level_to_start > 1: 
		klicker_level_index = level_to_start - 1 
		
	start_next_corrupted(klicker_level_index) 
	print("Zustand: COMBAT.")

# --------------------------------------------------------------------------------------
## MINIGAME-LOGIK (MIT KORRIGIERTEM KAMERA-WECHSEL)
# --------------------------------------------------------------------------------------

func start_minigame_level():
	if is_instance_valid(current_minigame):
		current_minigame.queue_free()
		
	var minigame_scene_resource = MINIGAME_SCENE_PATH
	if minigame_scene_resource:
		# 1. Instanz erstellen und Signal verbinden
		current_minigame = minigame_scene_resource.instantiate() 
		
		if current_minigame.has_signal("minigame_finished"):
			current_minigame.minigame_finished.connect(_on_minigame_finished)
		
		# 2. Haupt-Kamera SOFORT deaktivieren
		var main_cam = get_node_or_null("MainCamera")
		if is_instance_valid(main_cam):
			main_cam.enabled = false
		
		# 3. Szene zum Baum hinzufügen
		add_child(current_minigame)
		
		# --- NEUE, SICHERE METHODE ---
		# 4. EINEN FRAME WARTEN, damit das Minigame (inkl. Player/Camera)
		#    vollständig im Szenenbaum initialisiert ist.
		await get_tree().process_frame 
		
		# 5. Jetzt die Minigame-Kamera sicher finden und aktivieren
		var minigame_camera = current_minigame.get_node_or_null("Player/Camera2D")
		if is_instance_valid(minigame_camera):
			minigame_camera.enabled = true
			minigame_camera.make_current()
		else:
			print("FATALER FEHLER: 'Player/Camera2D' in minigame_scene.tscn nicht gefunden!")
		# --- ENDE DER NEUEN METHODE ---
		
		# Starte das Minigame (falls es eine start_game Funktion hat)
		if current_minigame.has_method("start_game"):
			current_minigame.start_game()
		
	_hide_ui() 
	get_node("Corrupted_Visual").hide()
	
	var main_bg = get_node("Background")
	if is_instance_valid(main_bg):
		main_bg.hide()


func _on_minigame_finished(success: bool):
	
	# Schalte auf die Haupt-Kamera zurück, BEVOR das Minigame gelöscht wird.
	var main_cam = get_node_or_null("MainCamera")
	if is_instance_valid(main_cam):
		main_cam.enabled = true
		main_cam.make_current()

	if is_instance_valid(current_minigame):
		current_minigame.queue_free()
		current_minigame = null 

	if success:
		print("Minigame erfolgreich abgeschlossen!")
		Combat.current_level_index = 2
	else:
		print("Minigame fehlgeschlagen. Zurück zur Karte.")
		
	goto_hub_map()
		
# --------------------------------------------------------------------------------------
## KAMPF- UND ÜBERGANGSLOGIK
# --------------------------------------------------------------------------------------

func start_next_corrupted(level_index: int): 
	
	var asset_array = Combat.CLICKER_LEVEL_ASSETS 
	var asset_index_to_load = level_index % asset_array.size()
	var current_assets = asset_array[asset_index_to_load]

	Combat.current_level_index = level_index 
	
	var corrupted_node = get_node("Corrupted_Visual")
	var background_node = get_node("Background")
	var victory_display = get_node(UI_LAYER_PATH + "Victory_Display")
	var search_screen = get_node(UI_LAYER_PATH + "Search_Screen")
	
	if is_instance_valid(search_screen):
		search_screen.hide()
	if is_instance_valid(victory_display):
		victory_display.hide()
		
	if is_instance_valid(background_node) and current_assets.background:
		background_node.texture = current_assets.background
		background_node.show() 
		
	if is_instance_valid(corrupted_node) and current_assets.sprite:
		corrupted_node.texture = current_assets.sprite
		corrupted_node.region_enabled = true
		corrupted_node.region_rect.size = Vector2(256, 256) 
		corrupted_node.position = Vector2(960, 620)

	Combat.start_new_combat(level_index) 
	
	if is_instance_valid(corrupted_node):
		var current_region = corrupted_node.region_rect
		current_region.position.x = 0 
		corrupted_node.region_rect = current_region
		corrupted_node.modulate = Color(1.0, 0.2, 0.2)
		

func _on_corrupted_healed():
	var corrupted_node = get_node("Corrupted_Visual")
	if is_instance_valid(corrupted_node):
		var current_region = corrupted_node.region_rect
		current_region.position.x = HEALED_SPRITE_OFFSET_X 
		corrupted_node.region_rect = current_region
		corrupted_node.modulate = Color(1.0, 1.0, 1.0) 

	var victory_display = get_node(UI_LAYER_PATH + "Victory_Display")
	var victory_animator = get_node(UI_LAYER_PATH + "Victory_Display/Victory_Animator")
	
	if is_instance_valid(next_round_timer):
		next_round_timer.wait_time = 2.0 
		next_round_timer.start()
		await next_round_timer.timeout
		
	if is_instance_valid(victory_display):
		victory_display.text = "Firmware updated.\n(+ " + str(int(Combat.healing_target_health * 0.5)) + " Coins)"
		victory_display.modulate = Color(1, 1, 1, 0)
		victory_display.show()
	
	if is_instance_valid(victory_animator):
		victory_animator.play("Fade_IN") 
		await victory_animator.animation_finished

	if is_instance_valid(next_round_timer):
		next_round_timer.wait_time = 3.0 
		next_round_timer.start()
		await next_round_timer.timeout
		
	if is_instance_valid(next_round_timer):
		if is_instance_valid(victory_display):
			victory_display.hide()
		_hide_ui() 
		
		next_round_timer.wait_time = 2.0 
		next_round_timer.start()
		await next_round_timer.timeout
		
	if Combat.current_level_index == 2: 
		if is_instance_valid(video_player):
			
			video_player.show()
			video_player.play()
			await video_player.finished
			video_player.hide()
	
	goto_hub_map()


func _show_search_screen(to_combat: bool = false):
	
	var victory_display = get_node(UI_LAYER_PATH + "Victory_Display")
	var search_screen = get_node(UI_LAYER_PATH + "Search_Screen")
	var search_label = get_node(SEARCH_LABEL_PATH) 
	
	var progress_bar = get_node(UI_LAYER_PATH + "Search_Screen/Search_Progress_Bar")
	
	if is_instance_valid(victory_display):
		victory_display.hide()
	_hide_ui() 
	
	if is_instance_valid(search_screen):
		search_screen.show()

	_update_drone_gallery() 
	
	simulated_progress = 0.0
	search_text_updated = false
	enter_text_shown = false 
	
	if is_instance_valid(search_label) and search_label.has_method("start_typing"):
		search_label.text = "SCANNING AREA..." 
		search_label.visible_characters = 0 
		search_label.start_typing()
		
	if is_instance_valid(next_round_timer):
		next_round_timer.wait_time = SEARCH_DURATION
		next_round_timer.start()
		
		if is_instance_valid(progress_bar):
			progress_bar.max_value = SEARCH_DURATION
			progress_bar.value = 0.0 
	
	while simulated_progress < SEARCH_DURATION:
		await get_tree().process_frame
		
	if is_instance_valid(progress_bar):
		progress_bar.value = progress_bar.max_value

	var temp_timer = Timer.new()
	add_child(temp_timer)
	temp_timer.one_shot = true
	temp_timer.wait_time = 0.1 
	temp_timer.start()
	await temp_timer.timeout
	temp_timer.queue_free()

	if to_combat:
		_return_to_combat_after_transition() 
	else:
		goto_hub_map() 

func _update_search_text(new_text: String):
	
	var search_label = get_node(SEARCH_LABEL_PATH) 
	
	if is_instance_valid(search_label):
		
		if search_label.has_method("skip_typing"):
			search_label.skip_typing()
			
		var final_text = new_text
		
		if final_text == "CORRUPTION FOUND...":
			final_text = "[color=red]" + final_text + "[/color]"
		elif final_text == "ENTER":
			final_text = "[color=yellow]" + final_text + "[/color]"

		search_label.text = final_text
		
		search_label.start_typing()


# --------------------------------------------------------------------------------------
## HILFSFUNKTIONEN & PROCESS
# --------------------------------------------------------------------------------------

func _hide_ui():
	var nodes_to_hide = ["Fragment_Display", "Power_Display", "Upgrade_Button", "Click_Upgrade_Button", "Drone_Gallery", "Health_Bar", "Drone_Gallery_Label"]
	for node_name in nodes_to_hide:
		var node = get_node(UI_LAYER_PATH + node_name)
		if is_instance_valid(node):
			node.hide()

func _show_ui():
	var nodes_to_show = ["Fragment_Display", "Power_Display", "Upgrade_Button", "Click_Upgrade_Button", "Drone_Gallery", "Drone_Gallery_Label"]
	for node_name in nodes_to_show:
		var node = get_node(UI_LAYER_PATH + node_name)
		if is_instance_valid(node):
			node.show()

func _update_drone_gallery():
	if not is_instance_valid(Combat): return
	var drone_count = Combat.CLICKER_LEVEL_ASSETS.size() 
	
	for i in range(drone_count):
		var panel = get_node(UI_LAYER_PATH + "Drone_Gallery/Drone_Panel_" + str(i + 1))
		if not is_instance_valid(panel): continue
		var sprite_rect = panel.get_node("Sprite") 
		
		if i < Combat.collected_drones.size():
			var drone_texture = Combat.collected_drones[i]
			if is_instance_valid(sprite_rect) and is_instance_valid(drone_texture):
				var base_image: Image = drone_texture.get_image()
				if not is_instance_valid(base_image): continue
				var cropped_image: Image = base_image.get_region( 
					Rect2(HEALED_SPRITE_OFFSET_X, 0, HEALED_SPRITE_SIZE.x, HEALED_SPRITE_SIZE.y)
				)
				var cropped_texture = ImageTexture.create_from_image(cropped_image)
				sprite_rect.texture = cropped_texture
		else:
			if is_instance_valid(sprite_rect):
				sprite_rect.texture = null

func _update_fragment_display():
	var fragment_display = get_node(UI_LAYER_PATH + "Fragment_Display")
	if is_instance_valid(Combat) and is_instance_valid(fragment_display):
		fragment_display.text = "Coins: " + str(Combat.harmony_fragments) 
			
	var power_display = get_node(UI_LAYER_PATH + "Power_Display")
	if is_instance_valid(power_display):
		power_display.text = (
			"Passiv: " + str(Combat.echo_healing_power) + " HP/s\n" +
			"Klick: " + str(Combat.echo_click_power) + " HP"
		)

func _process(_delta):
	
	var fragment_display = get_node(UI_LAYER_PATH + "Fragment_Display")
	
	var search_screen = get_node(UI_LAYER_PATH + "Search_Screen")
	if is_instance_valid(search_screen) and search_screen.visible:
		var progress_bar = get_node(UI_LAYER_PATH + "Search_Screen/Search_Progress_Bar")
		var search_label = get_node(SEARCH_LABEL_PATH) 
		
		if simulated_progress < SEARCH_DURATION:
			
			var progress_ratio = simulated_progress / SEARCH_DURATION
			var speed_multiplier = 1.0 
			
			if progress_ratio >= 0.50 and progress_ratio < 0.81:
				
				if not search_text_updated:
					_update_search_text("CORRUPTION FOUND...")
					search_text_updated = true
					
				speed_multiplier = 0.4 
			
			elif progress_ratio >= 0.81:
				speed_multiplier = 1.5 
				
				if progress_ratio >= 0.85 and is_instance_valid(search_label) and not search_label.is_typing and not enter_text_shown:
					_update_search_text("ENTER") 
					enter_text_shown = true
			
			simulated_progress += _delta * speed_multiplier
			
			simulated_progress = min(simulated_progress, SEARCH_DURATION)
			
			if is_instance_valid(progress_bar):
				progress_bar.value = simulated_progress
			
	if is_instance_valid(fragment_display) and fragment_display.visible:
		_update_fragment_display() 
			
# --------------------------------------------------------------------------------------
## BUTTON-SIGNAL-HANDLER
# --------------------------------------------------------------------------------------

func _on_button_start_pressed(): 
	goto_story_intro()
	
func _on_upgrade_button_pressed():
	if Combat.upgrade_healing_power():
		_update_fragment_display() 
		var button = get_node(UI_LAYER_PATH + "Upgrade_Button")
		if is_instance_valid(button):
			button.text = "Upgrade Healing (" + str(Combat.upgrade_cost) + " C)"
			button.release_focus() 

func _on_click_upgrade_button_pressed():
	if Combat.upgrade_click_power():
		_update_fragment_display() 
		var button = get_node(UI_LAYER_PATH + "Click_Upgrade_Button")
		if is_instance_valid(button):
			button.text = "Upgrade Click (" + str(Combat.click_upgrade_cost) + " C)"
			button.release_focus()

func _on_mission_1_button_pressed(): goto_combat(0)
func _on_mission_2_button_pressed(): goto_combat(1)
func _on_mission_3_button_pressed(): goto_combat(2)
func _on_mission_4_button_pressed(): goto_combat(3)
func _on_mission_5_button_pressed(): goto_combat(4)
