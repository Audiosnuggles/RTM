# TypewriterLabel.gd (Muss so aussehen)
extends RichTextLabel

@export var typing_speed: float = 0.05 
@export var initial_delay: float = 0.5 

var full_text: String = ""
var text_length: int = 0
var char_index: int = 0
var timer: Timer
var is_typing: bool = false 

signal typing_finished

func _ready():
	# 1. Timer Node erstellen
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	
	# 2. Den vollen Text speichern, der im Inspector eingetragen ist
	full_text = text
	text_length = full_text.length()
	
	# 3. Text verstecken, aber NICHT die Animation starten!
	visible_characters = 0
	# Die Animation wird später von MainScene.gd gestartet

func start_typing():
	# Wird von MainScene.gd aufgerufen
	char_index = 0
	is_typing = true
	
	if initial_delay > 0:
		timer.start(initial_delay)
		# Wichtig: 'await' hier hinzufügen, damit der Code auf den Delay wartet
		await timer.timeout 
		
	timer.wait_time = typing_speed
	timer.start()

func _on_timer_timeout():
	if char_index < text_length:
		char_index += 1
		visible_characters = char_index
		timer.start()
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
		typing_finished.emit()
