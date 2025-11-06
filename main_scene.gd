extends Node2D

# --- NODE-VERKNÜPFUNGEN ---
@onready var main_camera = $MainCamera 
@export var klicker_background: Sprite2D
@export var klicker_roboter: Sprite2D

@onready var music_player = $MusicPlayer
@onready var hub_music_player = $HubMusicPlayer # Für die Hub-Musik
@onready var anim_player = $AnimationPlayer 
@onready var fade_screen = $UI_Layer/FadeScreen # Für den Fade-Übergang

const UI_LAYER_PATH = "UI_Layer/"
var next_round_timer: Timer
var video_player: VideoStreamPlayer

# --- HACKING KORREKTUR: Neue Konstante für Hacking-Szene ---
const HACKING_MINIGAME_PATH = preload("res://hacking_minigame.tscn") # FÜR AUTOMATISCHEN START
const PLATFORMER_MINIGAME_PATH = preload("res://minigame_scene.tscn") # FÜR MISSION 1 BUTTON
var current_minigame: Node = null

# --- (Restliche Konstanten bleiben gleich) ---
const MISSION_1_BUTTON_PATH = UI_LAYER_PATH + "HubMap/Mission_1_Button"
const MISSION_2_BUTTON_PATH = UI_LAYER_PATH + "HubMap/Mission_2_Button"
const MISSION_3_BUTTON_PATH = UI_LAYER_PATH + "HubMap/Mission_3_Button"
const MISSION_4_BUTTON_PATH = UI_LAYER_PATH + "HubMap/Mission_4_Button"
const MISSION_5_BUTTON_PATH = UI_LAYER_PATH + "HubMap/Mission_5_Button"
const DRONE_GALLERY_LABEL_PATH = UI_LAYER_PATH + "Drone_Gallery_Label"
const SEARCH_LABEL_PATH = UI_LAYER_PATH + "Search_Screen/Typewriter_Label"

const MISSION_BUTTONS_MAP = [
    MISSION_1_BUTTON_PATH,
    MISSION_2_BUTTON_PATH,
    MISSION_3_BUTTON_PATH,
    MISSION_4_BUTTON_PATH,
    MISSION_5_BUTTON_PATH,
]

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
var search_text_updated: bool = false
var enter_text_shown: bool = false
var simulated_progress: float = 0.0
const SEARCH_DURATION: float = 8.0


# --------------------------------------------------------------------------------------
## INITIALISIERUNG
# --------------------------------------------------------------------------------------

func _ready():
    next_round_timer = get_node("Next_Round_Timer")
    video_player = get_node("Video_Player")
    var health_bar = get_node(UI_LAYER_PATH + "Health_Bar")

    if !is_instance_valid(main_camera) or !is_instance_valid(klicker_background) or !is_instance_valid(klicker_roboter):
        print("FATALER FEHLER: 'Main Camera', 'Klicker Background' oder 'Klicker Roboter' wurden nicht im Inspektor der MainScene zugewiesen!")
    
    if is_instance_valid(klicker_roboter):
        Combat.healing_impulse_fired.connect(klicker_roboter.apply_healing_visual)
        Combat.corrupted_healed.connect(_on_corrupted_healed)
    
    if is_instance_valid(Combat) and is_instance_valid(health_bar):
        Combat.corrupted_health_changed.connect(Callable(health_bar, "_on_corrupted_health_changed"))

    if is_instance_valid(video_player):
        video_player.position = Vector2(0, 0)
        video_player.size = Vector2(1920, 1080)
        video_player.hide()

    if is_instance_valid(main_camera):
        main_camera.enabled = true
        main_camera.make_current()

    if is_instance_valid(klicker_roboter):
        klicker_roboter.hide()
        
    # Zeige den Welt-Hintergrund für den Titelbildschirm
    if is_instance_valid(klicker_background):
        klicker_background.show() 
        
    _hide_ui()
    
    # FadeScreen zu Beginn unsichtbar machen
    if is_instance_valid(fade_screen):
        fade_screen.modulate.a = 0.0
        fade_screen.hide()

    goto_title_screen()

func _unhandled_input(event):
    if current_state == GameState.STATE_COMBAT:
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            Combat.perform_click_impulse()
            Combat.healing_impulse_fired.emit(event.position)
            get_viewport().set_input_as_handled()

# --- FUNKTION FÜR TITLESCREEN-BUTTON ---
func _on_button_start_pressed():
    # Diese Funktion wird vom Button auf dem TitleScreen aufgerufen (per Signalverbindung).
    if is_instance_valid(anim_player):
        anim_player.stop() 
    if is_instance_valid(main_camera):
        main_camera.zoom = Vector2(1, 1)
    
    var tween = create_tween()
    if is_instance_valid(music_player):
        tween.tween_property(music_player, "volume_db", -80.0, 1.5)
        await tween.finished
        
    goto_story_intro()
# --- ENDE FUNKTION ---


func goto_title_screen():
    get_tree().paused = false
    current_state = GameState.STATE_TITLE
    
    # Stelle sicher, dass der Welt-Hintergrund sichtbar ist
    if is_instance_valid(klicker_background):
        klicker_background.show()
    if is_instance_valid(klicker_roboter):
        klicker_roboter.hide()
    
    if is_instance_valid(anim_player):
        anim_player.play("Camaera_Zoom") 
    
    var title_screen = get_node(UI_LAYER_PATH + "TitleScreen")
    var hub_map = get_node(UI_LAYER_PATH + "HubMap")
    var story_intro = get_node(UI_LAYER_PATH + "StoryIntro")
    
    if is_instance_valid(title_screen): title_screen.show()
    if is_instance_valid(hub_map): hub_map.hide()
    if is_instance_valid(story_intro): story_intro.hide()
    
    # --- MUSIK-LOGIK ---
    if is_instance_valid(hub_music_player) and hub_music_player.is_playing():
        hub_music_player.stop()
        
    if is_instance_valid(music_player):
        music_player.volume_db = 0.0
        if not music_player.is_playing():
            music_player.play()
    
    print("Zustand: TITLE SCREEN.")

func goto_story_intro():
    current_state = GameState.STATE_STORY
    var title_screen = get_node(UI_LAYER_PATH + "TitleScreen")
    if is_instance_valid(title_screen): title_screen.hide()
    
    var story_intro = get_node(UI_LAYER_PATH + "StoryIntro")
    if is_instance_valid(story_intro): story_intro.show()
    
    print("Zustand: STORY INTRO.")
    
    # --- START: KORREKTUR FÜR INTRO-TEXT ---
    var intro_label_1 = get_node(UI_LAYER_PATH + "StoryIntro/ColorRect/RichTextLabel")
    var intro_label_2 = get_node(UI_LAYER_PATH + "StoryIntro/ColorRect/RichTextLabel2")
    if is_instance_valid(intro_label_1) and intro_label_1.has_method("start_typing"):
        intro_label_1.start_typing()
    if is_instance_valid(intro_label_2) and intro_label_2.has_method("start_typing"):
        intro_label_2.start_typing()
    # --- ENDE: KORREKTUR FÜR INTRO-TEXT ---
    
    # --- NEU: Vom Schwarz weich einblenden ---
    if is_instance_valid(fade_screen) and fade_screen.modulate.a > 0.9:
        var fade_out_tween = create_tween()
        fade_out_tween.tween_property(fade_screen, "modulate:a", 0.0, 1.0)
        await fade_out_tween.finished
        fade_screen.hide()
        
    # --- KORREKTUR: PROGRESSION NACH STORY INTRO ---
    # Wir starten hier NICHTS. Wir warten darauf, dass story_intro.gd
    # am Ende "main_scene_node.goto_hub_map()" aufruft.
    # --- ENDE KORREKTUR ---

func goto_hub_map():
    # --- KORREKTUR: FÄNGT DEN AUFRUF VOM STORY INTRO AB ---
    # Wenn wir noch am Anfang sind (Level 0), starte das Hacking Game statt der Hub Map.
    if Combat.current_level_index == 0:
        start_hacking_minigame()
        return # Verhindert, dass der Rest von goto_hub_map ausgeführt wird
    # --- ENDE KORREKTUR ---
    
    current_state = GameState.STATE_HUB_MAP
    
    # --- NEUER MUSIK-CODE START ---
    if is_instance_valid(music_player) and music_player.is_playing():
        music_player.stop() 
    if is_instance_valid(hub_music_player) and hub_music_player.is_playing():
        hub_music_player.stop()
    if is_instance_valid(hub_music_player) and not hub_music_player.is_playing():
        hub_music_player.play()
    # --- NEUER MUSIK-CODE ENDE ---
    
    if is_instance_valid(klicker_roboter): klicker_roboter.hide()
    if is_instance_valid(klicker_background): klicker_background.show()
    
    var story_intro = get_node(UI_LAYER_PATH + "StoryIntro")
    if is_instance_valid(story_intro): story_intro.hide()
    var hub_map_node = get_node(UI_LAYER_PATH + "HubMap")
    if is_instance_valid(hub_map_node): hub_map_node.show()
    
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

# --------------------------------------------------------------------------------------
## NAVIGATIONS-FUNKTIONEN (ANGEPASST)
# --------------------------------------------------------------------------------------

func _return_to_combat_after_transition():
    var search_screen = get_node(UI_LAYER_PATH + "Search_Screen")
    if is_instance_valid(search_screen): search_screen.hide()
    if is_instance_valid(video_player): 
        video_player.hide()
        
    if is_instance_valid(main_camera):
        main_camera.enabled = true
        main_camera.make_current()
        
    current_state = GameState.STATE_COMBAT
    
    if is_instance_valid(klicker_roboter): klicker_roboter.show()
    _show_ui()
    
    var health_bar = get_node(UI_LAYER_PATH + "Health_Bar")
    if is_instance_valid(health_bar): health_bar.show()
    
    start_next_corrupted(level_to_start)
    
    print("Zustand: COMBAT.")

# --- NEUE FUNKTION ZUM STARTEN DES HACKING-SPIELS ---
func start_hacking_minigame():
    print("start_hacking_minigame aufgerufen.")
    
    if is_instance_valid(current_minigame):
        current_minigame.queue_free()

    var minigame_scene_resource = HACKING_MINIGAME_PATH
    if minigame_scene_resource:
        current_minigame = minigame_scene_resource.instantiate()
        
        if current_minigame.has_signal("minigame_finished"):
            current_minigame.minigame_finished.connect(_on_minigame_finished)
        else:
            print("  WARNUNG: Hacking-Minigame hat kein 'minigame_finished' Signal.")
        
        # Verstecke die Hauptwelt (keine Kamera-Anpassung nötig, da Hacking-Szene ein CanvasLayer ist)
        if is_instance_valid(main_camera): main_camera.enabled = false
        if is_instance_valid(klicker_background): klicker_background.hide()
        if is_instance_valid(klicker_roboter): klicker_roboter.hide()
        _hide_ui()
        
        add_child(current_minigame)
    else:
        print("  FEHLER: Hacking-Minigame-Szene konnte nicht geladen werden.")


# --- start_minigame_level (Platformer) verwendet den neuen Pfad PLATFORMER_MINIGAME_PATH ---
func start_minigame_level():
    print("start_minigame_level aufgerufen.")
    
    var minigame_scene_resource = PLATFORMER_MINIGAME_PATH
    
    if is_instance_valid(current_minigame):
        print("  Altes Minigame wird entfernt.")
        current_minigame.queue_free()

    if minigame_scene_resource:
        print("  Neues Minigame wird instanziiert.")
        current_minigame = minigame_scene_resource.instantiate()

        if current_minigame.has_signal("minigame_finished"):
            current_minigame.minigame_finished.connect(_on_minigame_finished)
        else:
            print("  WARNUNG: Minigame hat kein 'minigame_finished' Signal.")

        print("  Versuche Klicker-Welt zu verstecken und Kamera zu deaktivieren...")
        if is_instance_valid(main_camera):
            main_camera.enabled = false
            print("    MainCamera deaktiviert.")
        else:
            print("    FEHLER: main_camera Variable ist leer!")

        if is_instance_valid(klicker_background):
            klicker_background.hide()
            print("    Klicker Background versteckt.")
        else:
            print("    FEHLER: klicker_background Variable ist leer!")

        if is_instance_valid(klicker_roboter):
            klicker_roboter.hide()
            print("    Klicker Roboter versteckt.")
        else:
            print("    FEHLER: klicker_roboter Variable ist leer!")

        print("  Füge Minigame zum Baum hinzu.")
        add_child(current_minigame)

        print("  Versuche Minigame-Kamera zu finden und zu aktivieren...")
        
        await get_tree().process_frame

        var minigame_camera = current_minigame.get_node_or_null("Player/Camera2D")
        if is_instance_valid(minigame_camera):
            print("    Minigame-Kamera gefunden.")

            if not minigame_camera.is_enabled():
                print("      Kamera war nicht enabled, aktiviere sie jetzt.")
                minigame_camera.enabled = true
            else:
                print("      Kamera ist bereits enabled.")

            print("      Versuche make_current()...")
            minigame_camera.make_current()
            
            await get_tree().process_frame

            if get_viewport().get_camera_2d() == minigame_camera:
                print("      ERFOLG: Minigame-Kamera IST jetzt die aktive Kamera.")
            else:
                print("      FEHLSCHLAG: Minigame-Kamera ist NICHT die aktive Kamera. Etwas anderes hat übernommen!")
                var current_cam = get_viewport().get_camera_2d()
                if is_instance_valid(current_cam):
                    print("        Aktive Kamera ist: " + current_cam.name + " (" + str(current_cam.get_path()) + ")")
                else:
                    print("        Es ist keine Camera2D aktiv (Default Viewport Kamera).")

        else:
            print("      FATALER FEHLER: Minigame-Kamera ('Player/Camera2D') konnte nicht gefunden werden!")

        _hide_ui()
        print("  UI versteckt.")
        
        if current_minigame.has_method("start_game"):
            print("  Rufe start_game() im Minigame auf.")
            current_minigame.start_game()
    else:
        print("  FEHLER: Minigame-Szene konnte nicht geladen werden.")


# --- KORREKTUR: _on_minigame_finished (DEIN NEUER FLOW) ---
func _on_minigame_finished(success: bool):

    # 1. Zeige den FadeScreen (der noch 0 Alpha hat) und blende ihn ein
    if is_instance_valid(fade_screen):
        fade_screen.modulate.a = 0.0 # Stelle sicher, dass er transparent ist
        fade_screen.show()
        
        var fade_in_tween = create_tween()
        fade_in_tween.tween_property(fade_screen, "modulate:a", 1.0, 0.5) 
        await fade_in_tween.finished
    
    # 2. JETZT (wo der Bildschirm schwarz ist), räume die Szene auf
    if is_instance_valid(main_camera):
        main_camera.enabled = true
        main_camera.make_current()

    if is_instance_valid(current_minigame):
        current_minigame.queue_free()
        current_minigame = null
        
    # Stelle sicher, dass der Hintergrund der Hauptszene wieder sichtbar ist!
    if is_instance_valid(klicker_background):
        klicker_background.show()
    
    # 3. Fortschritt basierend auf dem Level setzen
    if success:
        print("Minigame erfolgreich abgeschlossen!")
        
        # --- START: DEIN NEUER FLOW-FIX ---
        if Combat.current_level_index == 0: 
            # Hacking Game (Mission 0) fertig -> Starte Klicker Level 1 (Index 0)
            Combat.current_level_index = 1 # Schalte Mission 1 (Platformer) frei
            level_to_start = 0 # Klicker Level Index 0
            
            # FIX FÜR BLACK SCREEN: Verstecke den FadeScreen manuell,
            # bevor der Search_Screen startet.
            if is_instance_valid(fade_screen):
                fade_screen.hide()
                fade_screen.modulate.a = 0.0
            
            _show_search_screen(true) # Starte Klicker Level 1
            return # Wichtig: Verlasse die Funktion, damit goto_hub_map nicht aufgerufen wird
        # --- ENDE: DEIN NEUER FLOW-FIX ---
            
        elif Combat.current_level_index == 1: 
            # Platformer (Mission 1) fertig -> Schalte Klicker Level 2 (Mission 2) frei
            Combat.current_level_index = 2 # Schaltet Mission 2 frei
            
    else:
        print("Minigame fehlgeschlagen. Zurück zur Karte.")
        
    # 4. Wechsle zur Hub-Map (passiert sofort hinter dem schwarzen Bildschirm)
    #    (Dieser Teil wird nur noch vom Platformer erreicht)
    goto_hub_map()
    
    # 5. Blende den FadeScreen wieder aus, um die Hub-Map zu enthüllen
    if is_instance_valid(fade_screen):
        var fade_out_tween = create_tween()
        fade_out_tween.tween_property(fade_screen, "modulate:a", 0.0, 1.0) # 1 Sekunde Fade-Out
        await fade_out_tween.finished
        fade_screen.hide()


# --- KORREKTUR: MISSION BUTTON HANDLER (Behebt die UNUSED_PARAMETER Warnung) ---
# (Dieser Code ist derselbe wie in deiner Originaldatei, da er
#  jetzt mit dem neuen Flow übereinstimmt)
func _on_mission_button_pressed(level_index: int):
    # Das Argument wird nun korrekt als level_index empfangen und verwendet
    if current_state != GameState.STATE_HUB_MAP: return
    
    # Musik stoppen
    if is_instance_valid(hub_music_player) and hub_music_player.is_playing():
        hub_music_player.stop()
    
    var hub_map_node = get_node(UI_LAYER_PATH + "HubMap")
    if is_instance_valid(hub_map_node): hub_map_node.hide()

    # --- START DER LOGIK (aus deiner Datei) ---
    if level_index == 0:
        # MISSION 1 (Index 0) startet das PLATTFORMER SPIEL
        current_state = GameState.STATE_MINIGAME
        start_minigame_level()
    elif level_index == 1:
        # MISSION 2 (Index 1) startet das KLICKER SPIEL 2 (Klicker Index 1)
        # (Klicker 1 (Index 0) wurde nach dem Hacking Game gespielt)
        current_state = GameState.STATE_COMBAT
        level_to_start = 1 # Klicker Level 1
        _show_search_screen(true)
    else:
        # MISSION 3-5 (Index 2, 3, 4): KLICKER SPIELE STARTEN
        # Klicker Level 2 ist Index 2
        # Klicker Level 3 ist Index 3 (was Asset 0 lädt, via Modulo)
        # Klicker Level 4 ist Index 4 (was Asset 1 lädt, via Modulo)
        level_to_start = level_index
        _show_search_screen(true)
    # --- ENDE DER LOGIK ---


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


func _on_next_button_pressed() -> void:
    pass # Replace with function body.
# ... (Alle KAMPF- UND ÜBERGANGSLOGIK Funktionen bleiben gleich) ...
# ...
func start_next_corrupted(level_index: int):
    var asset_array = Combat.CLICKER_LEVEL_ASSETS
    var asset_index_to_load = level_index % asset_array.size()
    var current_assets = asset_array[asset_index_to_load]

    
    var background_node = klicker_background
    var corrupted_node = klicker_roboter

    var victory_display = get_node(UI_LAYER_PATH + "Victory_Display")
    var search_screen = get_node(UI_LAYER_PATH + "Search_Screen")

    if is_instance_valid(search_screen): search_screen.hide()
    if is_instance_valid(victory_display): victory_display.hide()

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
    var corrupted_node = klicker_roboter
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

    if Combat.current_level_index == 3:
        if is_instance_valid(video_player):
            video_player.show()
            video_player.play()
            await video_player.finished
            video_player.hide()

    # KORREKTUR: Nach JEDEM Klicker-Sieg zur Hub-Map zurückkehren
    goto_hub_map()


func _show_search_screen(to_combat: bool = false):
    var victory_display = get_node(UI_LAYER_PATH + "Victory_Display")
    var search_screen = get_node(UI_LAYER_PATH + "Search_Screen")
    var search_label = get_node(SEARCH_LABEL_PATH)
    var progress_bar = get_node(UI_LAYER_PATH + "Search_Screen/Search_Progress_Bar")

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

func _hide_ui():
    var nodes_to_hide = ["Fragment_Display", "Power_Display", "Upgrade_Button", "Click_Upgrade_Button", "Drone_Gallery", "Health_Bar", "Drone_Gallery_Label"]
    for node_name in nodes_to_hide:
        var node = get_node(UI_LAYER_PATH + node_name)
        if is_instance_valid(node): node.hide()

func _show_ui():
    var nodes_to_show = ["Fragment_Display", "Power_Display", "Upgrade_Button", "Click_Upgrade_Button", "Drone_Gallery", "Drone_Gallery_Label"]
    for node_name in nodes_to_show:
        var node = get_node(UI_LAYER_PATH + node_name)
        if is_instance_valid(node): node.show()

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
            if is_instance_valid(sprite_rect): sprite_rect.texture = null

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

func _on_click_Upgrade_Button_pressed() -> void:
    pass # Replace with function body.
func _on_Upgrade_Button_pressed() -> void:
    pass # Replace with function body.
