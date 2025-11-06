extends CanvasLayer

# Signal, das an main_scene gesendet wird
signal minigame_finished(success: bool)

# --- Verknüpfungen ---
@onready var lab_room_screen = $LabRoomScreen
@onready var hacking_terminal_screen = $HackingTerminalScreen
@onready var clue_window = $LabRoomScreen/ClueWindow
@onready var clue_text = $LabRoomScreen/ClueWindow/ClueText
@onready var login_window = $HackingTerminalScreen/LoginWindow
@onready var password_input = $HackingTerminalScreen/LoginWindow/PasswordInput
@onready var error_label = $HackingTerminalScreen/LoginWindow/ErrorLabel
@onready var success_window = $HackingTerminalScreen/SuccessWindow
@onready var success_text = $HackingTerminalScreen/SuccessWindow/SuccessText


# --- Die versteckten Hinweise ---
const HINWEIS_WHITEBOARD = "PROJEKT-STATUS:\n\n- Aktueller Build: ALVIN 2.5\n- Nächstes Ziel: ZENITH"
const HINWEIS_DESK = "MEMO:\n\nDas neue Sicherheitsprotokoll ist ein Albtraum.\nWer soll sich 'Projektname (rückwärts) + ID der Projektleiterin' merken können??"
const HINWEIS_IDCARD = "MITARBEITERAUSWEIS\n\nDr. Elara Vance\nID: 004\nPosition: Projektleiterin"
const HINWEIS_ERFOLG = "> ZUGRIFF GENEHMIGT...\n> VERBINDE MIT ROBOTER-EINHEIT..."


func _ready():
	# Starte im Labor
	lab_room_screen.show()
	hacking_terminal_screen.hide()
	clue_window.hide()
	error_label.hide()
	success_window.hide()


# --- STUFE 1: Labor (Hinweise finden) ---

# --- LOGIK-FUNKTIONEN ---

func _on_Clickable_Whiteboard_logic():
	print("DEBUG: [LOGIK] Whiteboard-Logik ausgeführt.")
	clue_text.text = HINWEIS_WHITEBOARD
	clue_window.show()

func _on_Clickable_Desk_logic():
	print("DEBUG: [LOGIK] Desk-Logik ausgeführt.")
	clue_text.text = HINWEIS_DESK
	clue_window.show()

func _on_Clickable_IDCard_logic():
	print("DEBUG: [LOGIK] IDCard-Logik ausgeführt.")
	clue_text.text = HINWEIS_IDCARD
	clue_window.show()

func _on_CloseClueButton_pressed():
	clue_window.hide()

func _on_Clickable_Computer_logic():
	print("DEBUG: [LOGIK] Computer-Logik ausgeführt. Wechsel zu Terminal.")
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

# KORREKTUR: Alle unbenutzten Parameter mit Unterstrich versehen
func _on_Clickable_Whiteboard_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if lab_room_screen.is_visible() and not clue_window.is_visible():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("--- AREA2D GEKLICKT: Whiteboard ---")
			_on_Clickable_Whiteboard_logic()

# KORREKTUR: Alle unbenutzten Parameter mit Unterstrich versehen
func _on_Clickable_Desk_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if lab_room_screen.is_visible() and not clue_window.is_visible():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("--- AREA2D GEKLICKT: Desk ---")
			_on_Clickable_Desk_logic()

# KORREKTUR: Alle unbenutzten Parameter mit Unterstrich versehen
func _on_Clickable_IDCard_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if lab_room_screen.is_visible() and not clue_window.is_visible():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("--- AREA2D GEKLICKT: IDCard ---")
			_on_Clickable_IDCard_logic()

# KORREKTUR: Alle unbenutzten Parameter mit Unterstrich versehen
func _on_Clickable_Computer_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if lab_room_screen.is_visible() and not clue_window.is_visible():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("--- AREA2D GEKLICKT: Computer ---")
			_on_Clickable_Computer_logic()


# --- STUFE 2: Terminal (Passwort eingeben) ---

func _on_SubmitButton_pressed():
	# Prüfe das Passwort (ALVIN rückwärts = NIVLA, ID = 004)
	if password_input.text.strip_edges().to_upper() == "NIVLA004":
		# Erfolg!
		login_window.hide()
		error_label.hide()
		
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
	success_text.text = HINWEIS_ERFOLG
	
	# Warte 3 Sekunden, damit der Spieler es lesen kann
	await get_tree().create_timer(3.0).timeout
	
	# Beende das Minispiel
	minigame_finished.emit(true)
