extends CanvasLayer

@onready var p1_label = $Control/Margin/Grid/P1Label
@onready var p2_label = $Control/Margin/Grid/P2Label
@onready var p3_label = $Control/Margin/Grid/P3Label
@onready var p4_label = $Control/Margin/Grid/P4Label

var labels: Array

func _ready() -> void:
	labels = [p1_label, p2_label, p3_label, p4_label]
	update_hud()

func _process(delta: float) -> void:
	# Częsta aktualizacja na wypadek zmian HP / modów
	update_hud()

func update_hud() -> void:
	for i in range(4):
		var prefix = "p" + str(i + 1)
		var char_name = ""
		match i:
			0: char_name = Global.player1_character
			1: char_name = Global.player2_character
			2: char_name = Global.player3_character
			3: char_name = Global.player4_character
			
		var lbl = labels[i]
		if char_name == "" or Global.slot_types.get(i+1, "off") == "off":
			lbl.text = ""
			continue
			
		var txt = "[b]" + prefix.to_upper() + ": " + char_name + "[/b]\n"
		
		# Życie
		if Global.alive.get(char_name, false):
			var hp = Global.characters.get(char_name, {}).get("hp", 0)
			txt += "HP: " + str(int(hp)) + "\n"
		else:
			txt += "[color=red]MARTWY[/color]\n"
			
		# Punkty (Kille)
		var pts = Global.points.get(char_name, 0)
		txt += "Punkty: " + str(pts) + "\n"
		
		# Modyfikatory
		var mods = Global.modifiers.get(char_name, [])
		if mods.size() > 0:
			txt += "Mody: "
			for m in mods:
				if Global.modifier_registry.has(m):
					txt += Global.modifier_registry[m]["emoji"]
		
		lbl.text = txt
