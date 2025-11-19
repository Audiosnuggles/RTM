# DIESER CODE GEHÖRT IN: hacking_minigame.gd

extends CanvasLayer

# Signal, das an main_scene gesendet wird
signal minigame_finished(success: bool)

# --- Verknüpfungen ---
@onready var lab_room_screen = $LabRoomScreen
@onready var hacking_terminal_screen = $HackingTerminalScreen
@onready var clue_window = $LabRoomScreen/ClueWindow

# NEU: ClueContent Container und die einzelnen Seiten verknüpfen
@onready var clue_content = $LabRoomScreen/ClueWindow/ClueContent
@onready var whiteboard_clue = $LabRoomScreen/ClueWindow/ClueContent/WhiteboardClue
@onready var desk_clue = $LabRoomScreen/ClueWindow/ClueContent/DeskClue
@onready var id_card_clue = $LabRoomScreen/ClueWindow/ClueContent/IDCardClue

@onready var login_window = $HackingTerminalScreen/LoginWindow
@onready var password_input = $HackingTerminalScreen/LoginWindow/PasswordInput
@onready var error_label = $HackingTerminalScreen/LoginWindow/ErrorLabel

# Korrigierte Pfade (beinhalten LoginWindow)
@onready var success_window = $HackingTerminalScreen/LoginWindow/SuccessWindow
@onready var success_text = $HackingTerminalScreen/LoginWindow/SuccessWindow/SuccessText

# Referenzen für das Verstecken der Login-Elemente
@onready var login_label = $HackingTerminalScreen/LoginWindow/Label
@onready var submit_button = $HackingTerminalScreen/LoginWindow/SubmitButton
@onready var exit_button = $HackingTerminalScreen/LoginWindow/ExitButton

# +++ DEIN SHADER-NODE +++
# !!! WICHTIG: Stelle sicher, dass dieser Pfad auf deinen ColorRect mit dem Augen-Shader zeigt!
@onready var eyelid_effect = $eyelid_effect 


func _ready():
	# Starte im Labor
	lab_room_screen.show()
	hacking_terminal_screen.hide()
	clue_window.hide()
	error_label.hide()
	success_window.hide()
	
	# Verstecke alle Inhaltsseiten im ClueWindow
	_hide_all_clues()

	# +++ NEU: Starte die Blinzel-Animation +++
	start_blinking_animation()


# NEU: Hilfsfunktion zum Verstecken aller Inhalte
func _hide_all_clues():
	whiteboard_clue.hide()
	desk_clue.hide()
	id_card_clue.hide()


# --- STUFE 1: Labor (Hinweise finden) ---

# --- LOGIK-FUNKTIONEN ---

func _on_Clickable_Whiteboard_logic():
	print("DEBUG: [LOGIK] Whiteboard-Logik ausgeführt.")
	_hide_all_clues()
	whiteboard_clue.show()
	clue_window.show()

func _on_Clickable_Desk_logic():
	print("DEBUG: [LOGIK] Desk-Logik ausgeführt.")
	_hide_all_clues()
	desk_clue.show()
	clue_window.show()

func _on_Clickable_IDCard_logic():
	print("DEBUG: [LOGIK] IDCard-Logik ausgeführt.")
	_hide_all_clues()
	id_card_clue.show()
	clue_window.show()

func _on_CloseClueButton_pressed():
	clue_window.hide()
	# Optional: _hide_all_clues()

func _on_Clickable_Computer_logic():
	print("DEBUG: [LOGIK] Computer-Logik ausgeführt. Wechsel zu Terminal.")
	# Verstecke ClueWindow, falls offen
	clue_window.hide()
	# Wechsle zum Hacking-Terminal
	lab_room_screen.hide()
	hacking_terminal_screen.show()
	password_input.grab_focus()

# NEU: ZURÜCK-BUTTON FUNKTION 
func _on_ExitButton_pressed():
	print("DEBUG: Zurück zum Labor.")
	hacking_terminal_screen.hide()
	lab_room_screen.show()


# --- AREA2D EINGABE-HANDLER (Muss mit input_event verbunden werden) ---

func _on_Clickable_Whiteboard_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if lab_room_screen.is_visible() and not clue_window.is_visible():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("--- AREA2D GEKLICKT: Whiteboard ---")
			_on_Clickable_Whiteboard_logic()

func _on_Clickable_Desk_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if lab_room_screen.is_visible() and not clue_window.is_visible():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("--- AREA2D GEKLICKT: Desk ---")
			_on_Clickable_Desk_logic()

func _on_Clickable_IDCard_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if lab_room_screen.is_visible() and not clue_window.is_visible():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("--- AREA2D GEKLICKT: IDCard ---")
			_on_Clickable_IDCard_logic()

func _on_Clickable_Computer_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if lab_room_screen.is_visible() and not clue_window.is_visible():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("--- AREA2D GEKLICKT: Computer ---")
			_on_Clickable_Computer_logic()


# --- STUFE 2: Terminal (Passwort eingeben) ---

func _on_SubmitButton_pressed():
	# Prüfe das Passwort (ALVIN rückwärts = SOLAT, ID = 077)
	print("!!! SUBMIT BUTTON GEDRÜCKT !!!")
	if password_input.text.strip_edges().to_upper() == "NIVLA077":
		# Erfolg!
		
		# --- KORREKTUR ---
		# Verstecke NUR die Login-Elemente, nicht das ganze Fenster
		if is_instance_valid(login_label): login_label.hide()
		if is_instance_valid(password_input): password_input.hide()
		if is_instance_valid(submit_button): submit_button.hide()
		if is_instance_valid(exit_button): exit_button.hide()
		if is_instance_valid(error_label): error_label.hide()
		
		# Starte die Erfolgssequenz
		start_success_sequence()
	else:
		# Fehlschlag
		print("DEBUG: Fehler! Passwort falsch.")
		error_label.text = "ZUGRIFF VERWEIGERT"
		error_label.show() 
		password_input.clear()
		password_input.grab_focus()


func start_success_sequence():
	success_window.show()
	
	# +++ KORREKTUR FÜR FEHLER 3: Text anzeigen +++
	success_text.show() 
	
	# success_text muss jetzt im Editor gestaltet sein
	
	# Warte 3 Sekunden, damit der Spieler es lesen kann
	await get_tree().create_timer(3.0).timeout
	
	# Beende das Minispiel
	minigame_finished.emit(true)
	

func _on_SubmitButton2_pressed() -> void:
	pass # Replace with function body.


# +++ HIER IST DEINE NEUE ANIMATIONSFUNKTION +++
func start_blinking_animation():
	
	# 1. Sicherstellen, dass das Material existiert
	if not is_instance_valid(eyelid_effect) or not eyelid_effect.material is ShaderMaterial:
		print("FEHLER (HackingMinigame): 'eyelid_effect' Node nicht gefunden oder hat kein ShaderMaterial! Pfad in Zeile 31 prüfen.")
		return

	var material = eyelid_effect.material as ShaderMaterial
	
	# 2. Auge am Anfang sofort schließen
	material.set_shader_parameter("open_amount", 0.0)

	# 3. Tween (Animation) erstellen
	var tween = create_tween()
	
	# Wir verwenden EASE_IN_OUT für sanfte Übergänge
	tween.set_ease(Tween.EASE_IN_OUT) 
	
	# Wir ketten die Animationen basierend auf deiner Beschreibung aneinander:

	# 1. "ganz langsam aufmachen" (Dauer: 1.5s, Start-Verzögerung: 0.5s)
	tween.tween_property(material, "shader_parameter/open_amount", 1.0, 1.0).set_delay(0.5)
	
	# 2. "dann wieder zu" (Dauer: 0.3s, Verzögerung: 0.8s)
	tween.tween_property(material, "shader_parameter/open_amount", 0.0, 0.3).set_delay(0.8)

	# 3. "etwas zulassen" (auf 30% öffnen) (Dauer: 0.8s, Verzögerung: 0.5s)
	tween.tween_property(material, "shader_parameter/open_amount", 1.0, 1.5).set_delay(0.5)

	# 4. "wieder auf" (Dauer: 0.5s, Verzögerung: 1.0s)
	tween.tween_property(material, "shader_parameter/open_amount", 1.0, 0.2).set_delay(1.0)

	# 6. "dann zweimal blinzeln" (Blink 2) (Dauer: 0.1s zu, 0.2s auf, Verzögerung: 0.3s)
	tween.tween_property(material, "shader_parameter/open_amount", 0.0, 0.1).set_delay(0.3)
	tween.tween_property(material, "shader_parameter/open_amount", 1.0, 0.2) # Direkt danach wieder auf
	
	# 7. "bevor die augen ganz offen sind" (Finale Öffnung)
	tween.tween_property(material, "shader_parameter/open_amount", 1.0, 0.4) # Bleibt offen

	# +++ DIESE ZEILE WURDE ENTFERNT +++
	# tween.start()
