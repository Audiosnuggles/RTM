# Im Skript deiner Intro-Labels (TyperwriterLabel.gd)

extends RichTextLabel

@export var typing_speed: float = 0.05 
@export var initial_delay: float = 0.5 

var full_text: String = ""
var text_length: int = 0
var char_index: int = 0
var timer: Timer
var is_typing: bool = false 

signal typing_finished

# NEU: Ein Status, um zu wissen, ob wir noch in der Verzögerung sind
var waiting_for_delay: bool = false

func _ready():
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	
	full_text = text
	text_length = full_text.length()
	bbcode_enabled = true
	visible_characters = 0
	
func start_typing():
	full_text = text 
	text_length = full_text.length()
	
	if is_typing:
		return
		
	char_index = 0
	is_typing = true
	
	if initial_delay > 0:
		# Wir starten die Verzögerung
		waiting_for_delay = true
		timer.wait_time = initial_delay
		timer.one_shot = true # WICHTIG: Nur einmal auslösen
		timer.start()
	else:
		# Keine Verzögerung, starte direkt mit dem Tippen
		waiting_for_delay = false
		_start_actual_typing()

func _start_actual_typing():
	# Diese Funktion stellt den Timer auf "Tipp-Modus" um
	timer.wait_time = typing_speed
	timer.one_shot = false # WICHTIG: Muss für jeden Buchstaben auslösen
	timer.start()
	_on_timer_timeout() # Löst den ersten Buchstaben sofort aus

func _on_timer_timeout():
	# Prüfen, ob der Timer gerade für die Verzögerung lief
	if waiting_for_delay:
		waiting_for_delay = false
		_start_actual_typing() # Verzögerung vorbei, starte das Tippen
		return # Wichtig: Verlasse die Funktion für diesen Frame

	# Wenn wir hier sind, sind wir im "Tipp-Modus"
	if char_index < text_length:
		char_index += 1
		visible_characters = char_index
		# Der Timer wird automatisch neu gestartet (da one_shot = false)
	else:
		timer.stop()
		is_typing = false
		typing_finished.emit()
		
func skip_typing():
	if is_typing:
		timer.stop()
		visible_characters = text_length
		char_index = text_length
		is_typing = false
		waiting_for_delay = false
		typing_finished.emit()
