extends Node2D
# --- FIX: "class_name MainScene" entfernt, um den "hides global script class" Fehler zu beheben ---

# ==============================================================================
# 1. NODE-VERKNÜPFUNGEN
# ==============================================================================

# --- Exportierte Nodes (müssen im Editor zugewiesen werden) ---
@export var klicker_background: Sprite2D
@export var klicker_roboter: Sprite2D

# --- Interne Node-Referenzen (Caching) ---
@onready var main_camera = $MainCamera
@onready var music_player = $MusicPlayer
@onready var hub_music_player = $HubMusicPlayer
@onready var anim_player = $AnimationPlayer
@onready var fade_screen = $UI_Layer/FadeScreen
@onready var next_round_timer = $Next_Round_Timer
@onready var video_player = $Video_Player

# --- UI Node-Referenzen (Caching) ---
@onready var health_bar = $UI_Layer/Health_Bar
@onready var title_screen = $UI_Layer/TitleScreen
@onready var story_intro = $UI_Layer/StoryIntro
@onready var story_intro_label_1 = $UI_Layer/StoryIntro/ColorRect/RichTextLabel
@onready var story_intro_label_2 = $UI_Layer/StoryIntro/ColorRect/RichTextLabel2
@onready var hub_map = $UI_Layer/HubMap
@onready var search_screen = $UI_Layer/Search_Screen
@onready var search_label = $UI_Layer/Search_Screen/Typewriter_Label
@onready var search_progress_bar = $UI_Layer/Search_Screen/Search_Progress_Bar
@onready var fragment_display = $UI_Layer/Fragment_Display
@onready var power_display = $UI_Layer/Power_Display
@onready var upgrade_button = $UI_Layer/Upgrade_Button
@onready var click_upgrade_button = $UI_Layer/Click_Upgrade_Button
@onready var victory_display = $UI_Layer/Victory_Display
@onready var victory_animator = $UI_Layer/Victory_Display/Victory_Animator
@onready var drone_gallery = $UI_Layer/Drone_Gallery
@onready var drone_gallery_label = $UI_Layer/Drone_Gallery_Label

# ==============================================================================
# 2. KONSTANTEN
# ==============================================================================

# --- Szenen-Pfade ---
const HACKING_MINIGAME_PATH = preload("res://hacking_minigame.tscn")
const PLATFORMER_MINIGAME_PATH = preload("res://minigame_scene.tscn")

# --- UI-Pfade (nur für dynamische Schleifen) ---
const UI_LAYER_PATH = "UI_Layer/"
const MISSION_BUTTONS_MAP = [
	UI_LAYER_PATH + "HubMap/Mission_1_Button",
	UI_LAYER_PATH + "HubMap/Mission_2_Button",
	UI_LAYER_PATH + "HubMap/Mission_3_Button",
	UI_LAYER_PATH + "HubMap/Mission_4_Button",
	UI_LAYER_PATH + "HubMap/Mission_5_Button",
]

# --- Visuelle Konstanten ---
const COLOR_COMPLETED = Color(0.0, 1.0, 0.0)
const COLOR_CURRENT = Color(1.0, 1.0, 0.0)
const COLOR_LOCKED = Color(1.0, 0.0, 0.0)
const HEALED_SPRITE_SIZE = Vector2(256, 256)
const HEALED_SPRITE_OFFSET_X = 256
const SEARCH_DURATION: float = 8.0

# --- Spiel-Logik ---
enum GameState {
	STATE_TITLE,
	STATE_STORY,
	STATE_HUB_MAP,
	STATE_COMBAT,
	STATE_INVENTORY,
	STATE_MINIGAME
}

# ==============================================================================
# 3. STATE-VARIABLEN
# ==============================================================================

var current_state: GameState = GameState.STATE_TITLE
var current_minigame: Node = null
var level_to_start: int = -1

# --- Search Screen Timer ---
var search_text_updated: bool = false
var enter_text_shown: bool = false
var simulated_progress: float = 0.0


# ==============================================================================
# 4. GODOT BUILT-IN FUNKTIONEN
# ==============================================================================

func _ready():
	# Prüfe zugewiesene Export-Variablen
	if !is_instance_valid(main_camera) or !is_instance_valid(klicker_background) or !is_instance_valid(klicker_roboter):
		print("FATALER FEHLER: 'Main Camera', 'Klicker Background' oder 'Klicker Roboter' wurden nicht im Inspektor der MainScene zugewiesen!")
	
	# Verbinde Signale mit dem Combat-Singleton
	if is_instance_valid(klicker_roboter):
		Combat.healing_impulse_fired.connect(klicker_roboter.apply_healing_visual)
		Combat.corrupted_healed.connect(_on_corrupted_healed)
	
	if is_instance_valid(Combat) and is_instance_valid(health_bar):
		Combat.corrupted_health_changed.connect(Callable(health_bar, "_on_corrupted_health_changed"))

	# Initialisiere Nodes
	if is_instance_valid(video_player):
		video_player.position = Vector2(0, 0)
		video_player.size = Vector2(1920, 1080)
		video_player.hide()

	if is_instance_valid(main_camera):
		main_camera.enabled = true
		main_camera.make_current()

	if is_instance_valid(klicker_roboter):
		klicker_roboter.hide()
		
	if is_instance_valid(klicker_background):
		klicker_background.show() 
		
	_hide_ui()
	
	if is_instance_valid(fade_screen):
		fade_screen.modulate.a = 0.0
		fade_screen.hide()

	# Starte das Spiel
	goto_title_screen()

func _unhandled_input(event):
	# Globale Klick-Erkennung für das Klicker-Spiel
	if current_state == GameState.STATE_COMBAT:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Combat.perform_click_impulse()
			Combat.healing_impulse_fired.emit(event.position)
			get_viewport().set_input_as_handled()

func _process(_delta):
	# Verarbeite den Ladebalken des Search_Screen
	if is_instance_valid(search_screen) and search_screen.visible:
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
			
			if is_instance_valid(search_progress_bar):
				search_progress_bar.value = simulated_progress
	
	# Aktualisiere das Fragment-Display (nur wenn es sichtbar ist)
	elif is_instance_valid(fragment_display) and fragment_display.visible:
		_update_fragment_display()


# ==============================================================================
# 5. GAME STATE TRANSITIONS (goto_... Funktionen)
# ==============================================================================

func goto_title_screen():
	get_tree().paused = false
	current_state = GameState.STATE_TITLE
	
	if is_instance_valid(klicker_background):
		klicker_background.show()
	if is_instance_valid(klicker_roboter):
		klicker_roboter.hide()
	
	if is_instance_valid(anim_player):
		anim_player.play("Camaera_Zoom") 
	
	if is_instance_valid(title_screen): title_screen.show()
	if is_instance_valid(hub_map): hub_map.hide()
	if is_instance_valid(story_intro): story_intro.hide()
	
	if is_instance_valid(hub_music_player) and hub_music_player.is_playing():
		hub_music_player.stop()
	if is_instance_valid(music_player):
		music_player.volume_db = 0.0
		if not music_player.is_playing():
			music_player.play()
	
	print("Zustand: TITLE SCREEN.")

func goto_story_intro():
	current_state = GameState.STATE_STORY
	
	if is_instance_valid(title_screen): title_screen.hide()
	if is_instance_valid(story_intro): story_intro.show()
	
	print("Zustand: STORY INTRO.")
	
	# Starte die Typewriter-Effekte
	if is_instance_valid(story_intro_label_1) and story_intro_label_1.has_method("start_typing"):
		story_intro_label_1.start_typing()
	if is_instance_valid(story_intro_label_2) and story_intro_label_2.has_method("start_typing"):
		story_intro_label_2.start_typing()
	
	# Fade-in vom schwarzen Bildschirm (nach Titel)
	if is_instance_valid(fade_screen) and fade_screen.modulate.a > 0.9:
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(fade_screen, "modulate:a", 0.0, 1.0)
		await fade_out_tween.finished
		fade_screen.hide()
		
	# HINWEIS: Das Skript wartet, bis story_intro.gd "goto_hub_map()" aufruft.

func goto_hub_map():
	# Fängt den allerersten Aufruf ab (nach dem Story-Intro)
	if not Combat.has_completed_intro:
		start_hacking_minigame()
		return # Stoppt hier, bis das Hacking-Intro fertig ist

	# Regulärer Ladevorgang der Hub-Map
	current_state = GameState.STATE_HUB_MAP
	
	if is_instance_valid(music_player) and music_player.is_playing():
		music_player.stop() 
	if is_instance_valid(hub_music_player) and not hub_music_player.is_playing():
		hub_music_player.play()
	
	if is_instance_valid(klicker_roboter): klicker_roboter.hide()
	if is_instance_valid(klicker_background): klicker_background.show()
	if is_instance_valid(story_intro): story_intro.hide()
	if is_instance_valid(hub_map): hub_map.show()
	
	_hide_ui()
	_update_drone_gallery()
	_show_ui()
	
	# Aktualisiere Missions-Buttons basierend auf dem globalen Fortschritt
	for i in range(MISSION_BUTTONS_MAP.size()):
		var button = get_node(MISSION_BUTTONS_MAP[i])
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

# ==============================================================================
# 6. SZENEN-LADEFUNKTIONEN
# ==============================================================================

func start_hacking_minigame():
	print("Lade Hacking-Minigame...")
	
	if is_instance_valid(current_minigame):
		current_minigame.queue_free()

	if HACKING_MINIGAME_PATH:
		current_minigame = HACKING_MINIGAME_PATH.instantiate()
		
		if current_minigame.has_signal("minigame_finished"):
			current_minigame.minigame_finished.connect(_on_minigame_finished)
		else:
			print("  WARNUNG: Hacking-Minigame hat kein 'minigame_finished' Signal.")
		
		if is_instance_valid(main_camera): main_camera.enabled = false
		if is_instance_valid(klicker_background): klicker_background.hide()
		if is_instance_valid(klicker_roboter): klicker_roboter.hide()
		_hide_ui()
		
		add_child(current_minigame)
	else:
		print("  FEHLER: Hacking-Minigame-Szene konnte nicht geladen werden.")

func start_minigame_level():
	print("Lade Platformer-Minigame...")
	
	if is_instance_valid(current_minigame):
		current_minigame.queue_free()

	if PLATFORMER_MINIGAME_PATH:
		current_minigame = PLATFORMER_MINIGAME_PATH.instantiate()

		if current_minigame.has_signal("minigame_finished"):
			current_minigame.minigame_finished.connect(_on_minigame_finished)
		else:
			print("  WARNUNG: Minigame hat kein 'minigame_finished' Signal.")

		if is_instance_valid(main_camera): main_camera.enabled = false
		if is_instance_valid(klicker_background): klicker_background.hide()
		if is_instance_valid(klicker_roboter): klicker_roboter.hide()

		add_child(current_minigame)
		await get_tree().process_frame # Warten, damit der Player-Node registriert wird

		# Aktiviere die Kamera des Minigame-Players
		var minigame_camera = current_minigame.get_node_or_null("Player/Camera2D")
		if is_instance_valid(minigame_camera):
			minigame_camera.enabled = true
			minigame_camera.make_current()
			if get_viewport().get_camera_2d() == minigame_camera:
				print("      ERFOLG: Minigame-Kamera ist jetzt aktiv.")
			else:
				print("      FEHLSCHLAG: Minigame-Kamera konnte nicht aktiviert werden.")
		else:
			print("      FATALER FEHLER: Minigame-Kamera ('Player/Camera2D') konnte nicht gefunden werden!")

		_hide_ui()
		
		if current_minigame.has_method("start_game"):
			current_minigame.start_game()
	else:
		print("  FEHLER: Minigame-Szene konnte nicht geladen werden.")


# ==============================================================================
# 7. SPIEL-LOGIK & TRANSITIONS-HANDLER
# ==============================================================================

# Wird aufgerufen, wenn Hacking- oder Platformer-Minigame "minigame_finished" signalisieren
func _on_minigame_finished(success: bool):

	# 1. Fade-Out (Bildschirm wird schwarz)
	if is_instance_valid(fade_screen):
		fade_screen.modulate.a = 0.0
		fade_screen.show()
		var fade_in_tween = create_tween()
		fade_in_tween.tween_property(fade_screen, "modulate:a", 1.0, 0.5) 
		await fade_in_tween.finished
	
	# 2. Aufräumen (hinter dem schwarzen Bildschirm)
	if is_instance_valid(main_camera):
		main_camera.enabled = true
		main_camera.make_current()

	if is_instance_valid(current_minigame):
		var minigame_path = current_minigame.scene_file_path
		current_minigame.queue_free()
		current_minigame = null
		
		if is_instance_valid(klicker_background):
			klicker_background.show()
		
		# 3. Fortschritt verarbeiten
		if success:
			print("Minigame erfolgreich abgeschlossen!")
			
			if minigame_path == HACKING_MINIGAME_PATH.resource_path:
				# --- Fall 1: Hacking-Intro war erfolgreich ---
				# (current_level_index ist noch 0)
				level_to_start = 0 # Klicker-Spiel 0 (Intro Teil 2)
				
				# Black-Screen-Fix: FadeScreen sofort ausblenden
				if is_instance_valid(fade_screen):
					fade_screen.hide()
					fade_screen.modulate.a = 0.0
				
				_show_search_screen(true) # Starte Intro-Klicker
				return # WICHTIG: Stoppt hier, geht nicht zur Hub-Map
			
			elif minigame_path == PLATFORMER_MINIGAME_PATH.resource_path:
				# --- Fall 2: Platformer (Mission 1) war erfolgreich ---
				if Combat.current_level_index == 0:
					Combat.current_level_index = 1 # Schalte Mission 2 (Index 1) frei
		else:
			print("Minigame fehlgeschlagen. Zurück zur Karte.")
	
	# 4. Zur Hub-Map zurückkehren (wird nur von Fall 2 oder Fehlschlag erreicht)
	goto_hub_map()
	
	# 5. Fade-In (Schwarzer Bildschirm verschwindet)
	if is_instance_valid(fade_screen):
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(fade_screen, "modulate:a", 0.0, 1.0)
		await fade_out_tween.finished
		fade_screen.hide()

# Wird aufgerufen, wenn ein Klicker-Spiel "corrupted_healed" signalisiert
func _on_corrupted_healed():
	# Visuelles Feedback
	if is_instance_valid(klicker_roboter):
		var current_region = klicker_roboter.region_rect
		current_region.position.x = HEALED_SPRITE_OFFSET_X
		klicker_roboter.region_rect = current_region
		klicker_roboter.modulate = Color(1.0, 1.0, 1.0)

	# Sieges-Anzeige
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

	# Kurze Pause auf dem Sieges-Bildschirm
	if is_instance_valid(next_round_timer):
		next_round_timer.wait_time = 3.0
		next_round_timer.start()
		await next_round_timer.timeout

	# UI ausblenden
	if is_instance_valid(next_round_timer):
		if is_instance_valid(victory_display):
			victory_display.hide()
		_hide_ui()

		next_round_timer.wait_time = 2.0
		next_round_timer.start()
		await next_round_timer.timeout

	# Spezielles Video-Event
	if Combat.current_level_index == 3:
		if is_instance_valid(video_player):
			video_player.show()
			video_player.play()
			await video_player.finished
			video_player.hide()

	# Nach JEDEM Klicker-Sieg zur Hub-Map zurückkehren
	goto_hub_map()

# Startet das Klicker-Level (wird von _show_search_screen aufgerufen)
func start_next_corrupted(level_index: int):
	var asset_array = Combat.CLICKER_LEVEL_ASSETS
	var asset_index_to_load = level_index % asset_array.size()
	var current_assets = asset_array[asset_index_to_load]
	
	if is_instance_valid(search_screen): search_screen.hide()
	if is_instance_valid(victory_display): victory_display.hide()

	if is_instance_valid(klicker_background) and current_assets.background:
		klicker_background.texture = current_assets.background
		klicker_background.show()

	if is_instance_valid(klicker_roboter) and current_assets.sprite:
		klicker_roboter.texture = current_assets.sprite
		klicker_roboter.region_enabled = true
		klicker_roboter.region_rect.size = Vector2(256, 256)
		klicker_roboter.position = Vector2(960, 620)
		
		var current_region = klicker_roboter.region_rect
		current_region.position.x = 0
		klicker_roboter.region_rect = current_region
		klicker_roboter.modulate = Color(1.0, 0.2, 0.2)

	# Startet die Logik im Singleton
	Combat.start_new_combat(level_index)


# ==============================================================================
# 8. SIGNAL-HANDLER (UI-BUTTONS)
# ==============================================================================

func _on_button_start_pressed():
	if is_instance_valid(anim_player):
		anim_player.stop() 
	if is_instance_valid(main_camera):
		main_camera.zoom = Vector2(1, 1)
	
	var tween = create_tween()
	if is_instance_valid(music_player):
		tween.tween_property(music_player, "volume_db", -80.0, 1.5)
		await tween.finished
		
	goto_story_intro()

func _on_mission_button_pressed(level_index: int):
	if current_state != GameState.STATE_HUB_MAP: return
	
	if is_instance_valid(hub_music_player) and hub_music_player.is_playing():
		hub_music_player.stop()
	if is_instance_valid(hub_map): 
		hub_map.hide()

	if level_index == 0:
		# MISSION 1 (Index 0) startet das PLATTFORMER SPIEL
		current_state = GameState.STATE_MINIGAME
		start_minigame_level()
	elif level_index == 1:
		# MISSION 2 (Index 1) startet das KLICKER SPIEL (Asset 1)
		current_state = GameState.STATE_COMBAT
		level_to_start = 1 # Klicker Level 1
		_show_search_screen(true)
	else:
		# MISSION 3+ (Index 2, 3, 4...)
		current_state = GameState.STATE_COMBAT
		level_to_start = level_index
		_show_search_screen(true)

# --- KORREKTUR 1: Namen an .tscn-Signale angepasst (Großschreibung) ---
func _on_Upgrade_Button_pressed():
	if Combat.upgrade_healing_power():
		_update_fragment_display()
		if is_instance_valid(upgrade_button):
			upgrade_button.text = "Upgrade Healing (" + str(Combat.upgrade_cost) + " C)"
			upgrade_button.release_focus()

func _on_Click_Upgrade_Button_pressed():
	if Combat.upgrade_click_power():
		_update_fragment_display()
		if is_instance_valid(click_upgrade_button):
			click_upgrade_button.text = "Upgrade Click (" + str(Combat.click_upgrade_cost) + " C)"
			click_upgrade_button.release_focus()
# --- ENDE KORREKTUR 1 ---


# ==============================================================================
# 9. UI HELPER-FUNKTIONEN
# ==============================================================================

func _show_search_screen(to_combat: bool = false):
	if is_instance_valid(victory_display): victory_display.hide()
	_hide_ui()
	if is_instance_valid(search_screen): search_screen.show()

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
		if is_instance_valid(search_progress_bar):
			search_progress_bar.max_value = SEARCH_DURATION
			search_progress_bar.value = 0.0

	# Wartet, bis der Ladebalken im _process voll ist
	while simulated_progress < SEARCH_DURATION:
		await get_tree().process_frame

	if is_instance_valid(search_progress_bar):
		search_progress_bar.value = search_progress_bar.max_value
	
	# Kurze Verzögerung, damit "ENTER" gelesen werden kann
	var temp_timer = Timer.new()
	add_child(temp_timer)
	temp_timer.one_shot = true
	temp_timer.wait_time = 0.1
	temp_timer.start()
	await temp_timer.timeout
	temp_timer.queue_free()

	# Entscheide, ob zum Kampf oder zur Hub-Map gewechselt wird
	if to_combat:
		_return_to_combat_after_transition()
	else:
		goto_hub_map()

# Kehrt vom Search_Screen zum Klicker-Kampf zurück
func _return_to_combat_after_transition():
	if is_instance_valid(search_screen): search_screen.hide()
	if is_instance_valid(video_player): video_player.hide()
		
	if is_instance_valid(main_camera):
		main_camera.enabled = true
		main_camera.make_current()
		
	current_state = GameState.STATE_COMBAT
	
	if is_instance_valid(klicker_roboter): klicker_roboter.show()
	_show_ui()
	
	if is_instance_valid(health_bar): health_bar.show()
	
	start_next_corrupted(level_to_start)
	
	print("Zustand: COMBAT.")

# Versteckt die Haupt-UI (Klicker/Hub)
func _hide_ui():
	# --- FIX: Verwendet jetzt die gecachten @onready vars ---
	var nodes_to_hide = [fragment_display, power_display, upgrade_button, 
						click_upgrade_button, health_bar, 
						drone_gallery, drone_gallery_label]
	# --- ENDE FIX ---
	for node in nodes_to_hide:
		if is_instance_valid(node): node.hide()

# Zeigt die Haupt-UI (Klicker/Hub)
func _show_ui():
	# --- FIX: Verwendet jetzt die gecachten @onready vars ---
	var nodes_to_show = [fragment_display, power_display, upgrade_button, 
						click_upgrade_button,
						drone_gallery, drone_gallery_label]
	# --- ENDE FIX ---
	for node in nodes_to_show:
		if is_instance_valid(node): node.show()

# Aktualisiert die Drohnen-Galerie mit gesammelten Drohnen
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
				
				# Schneide das "geheilte" Sprite aus dem Spritesheet
				var cropped_image: Image = base_image.get_region(
					Rect2(HEALED_SPRITE_OFFSET_X, 0, HEALED_SPRITE_SIZE.x, HEALED_SPRITE_SIZE.y)
				)
				var cropped_texture = ImageTexture.create_from_image(cropped_image)
				sprite_rect.texture = cropped_texture
		else:
			if is_instance_valid(sprite_rect): sprite_rect.texture = null

# Aktualisiert die Text-Anzeigen für Währung und Power
func _update_fragment_display():
	if is_instance_valid(Combat) and is_instance_valid(fragment_display):
		fragment_display.text = "Coins: " + str(Combat.harmony_fragments)
		
	if is_instance_valid(power_display):
		power_display.text = (
			"Passiv: " + str(Combat.echo_healing_power) + " HP/s\n" +
			"Klick: " + str(Combat.echo_click_power) + " HP"
		)

# Aktualisiert den Text des Search-Screens (für "CORRUPTION FOUND...")
func _update_search_text(new_text: String):
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
