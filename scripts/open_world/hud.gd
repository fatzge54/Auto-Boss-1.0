extends CanvasLayer
const MiniMap=preload("res://scripts/open_world/minimap.gd")
const WorldMap=preload("res://scripts/open_world/world_map.gd")
const WorldData=preload("res://scripts/open_world/world_data.gd")
const VehicleData=preload("res://scripts/open_world/vehicle.gd")
var game
var screen:Control
var driving_hud:Control
var menu:Control
var stats:Label
var target_label:Label
var region_label:Label
var feedback_label:Label
var map_view
var pickup_button:Button
var message_timer:float=0.0
var menu_page:String="start"

func _ready()->void:
	screen=Control.new();screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	create_driving_ui()
	show_menu("start")

func button(text:String)->Button:
	var b:=Button.new()
	b.text=text
	b.focus_mode=Control.FOCUS_NONE
	b.custom_minimum_size=Vector2(175,46)
	b.add_theme_font_size_override("font_size",18)
	var style:=StyleBoxFlat.new();style.bg_color=Color(0.045,0.13,0.22,0.96);style.corner_radius_top_left=7;style.corner_radius_top_right=7;style.corner_radius_bottom_left=7;style.corner_radius_bottom_right=7
	style.border_color=Color(0.12,0.52,0.72);style.set_border_width_all(1)
	b.add_theme_stylebox_override("normal",style)
	return b

func label(text:String,font_size:int=20)->Label:
	var l:=Label.new();l.text=text
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",Color(0.91,0.97,1.0))
	return l

func create_driving_ui()->void:
	driving_hud=Control.new();driving_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	driving_hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	screen.add_child(driving_hud)
	# Semi-opaque dashboard is readable against bright fog, snow and daylight.
	var stats_back:=ColorRect.new()
	stats_back.position=Vector2(13,10)
	stats_back.size=Vector2(385,142)
	stats_back.color=Color(0.012,0.034,0.053,0.81)
	stats_back.mouse_filter=Control.MOUSE_FILTER_IGNORE
	driving_hud.add_child(stats_back)
	var nav_back:=ColorRect.new()
	nav_back.position=Vector2(412,10)
	nav_back.size=Vector2(627,133)
	nav_back.color=Color(0.012,0.034,0.053,0.81)
	nav_back.mouse_filter=Control.MOUSE_FILTER_IGNORE
	driving_hud.add_child(nav_back)
	stats=label("0 km/h",25);stats.position=Vector2(24,20)
	stats.size=Vector2(455,135);driving_hud.add_child(stats)
	region_label=label("Lindenfurt",17);region_label.position=Vector2(430,18)
	region_label.size=Vector2(520,50);driving_hud.add_child(region_label)
	target_label=label("Freie Fahrt",18);target_label.position=Vector2(450,50)
	target_label.size=Vector2(570,105);driving_hud.add_child(target_label)
	map_view=MiniMap.new();map_view.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map_view.position=Vector2(-240,22);map_view.size=Vector2(220,220)
	map_view.scale_factor=0.12;driving_hud.add_child(map_view)
	feedback_label=label("",18)
	feedback_label.anchor_top=1.0;feedback_label.anchor_bottom=1.0
	feedback_label.position=Vector2(370,-172);feedback_label.size=Vector2(570,100)
	feedback_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	driving_hud.add_child(feedback_label)
	var left_btn:=make_touch("◀",Vector2(22,-138),"left")
	var right_btn:=make_touch("▶",Vector2(143,-138),"right")
	var brake_btn:=make_touch("BREMSE",Vector2(-274,-138),"brake",true)
	var gas_btn:=make_touch("GAS",Vector2(-143,-138),"gas",true)
	for item in [left_btn,right_btn,brake_btn,gas_btn]:driving_hud.add_child(item)
	var menu_btn:=button("☰ MENÜ");menu_btn.custom_minimum_size=Vector2(0,0)
	menu_btn.position=Vector2(22,143);menu_btn.size=Vector2(140,42)
	menu_btn.pressed.connect(func():game.pause_game());driving_hud.add_child(menu_btn)
	var cam_btn:=button("KAMERA");cam_btn.position=Vector2(170,143);cam_btn.size=Vector2(142,42)
	cam_btn.pressed.connect(func():game.toggle_camera());driving_hud.add_child(cam_btn)
	var map_btn:=button("KARTE ±");map_btn.position=Vector2(320,143);map_btn.size=Vector2(142,42)
	map_btn.pressed.connect(func():map_view.scale_factor=0.04 if map_view.scale_factor>0.08 else 0.12);driving_hud.add_child(map_btn)
	pickup_button=button("FAHRZEUG ÜBERNEHMEN")
	pickup_button.anchor_top=1.0;pickup_button.anchor_bottom=1.0
	pickup_button.position=Vector2(430,-246);pickup_button.size=Vector2(355,64)
	pickup_button.pressed.connect(func():game.quick_action());driving_hud.add_child(pickup_button)
	pickup_button.visible=false
	driving_hud.visible=false

func make_touch(text:String,offset:Vector2,control:String,from_right:bool=false)->Button:
	var b:=button(text)
	b.anchor_top=1.0;b.anchor_bottom=1.0
	if from_right:
		b.anchor_left=1.0;b.anchor_right=1.0
	b.position=offset;b.size=Vector2(108,112)
	b.button_down.connect(func():game.set_touch(control,true))
	b.button_up.connect(func():game.set_touch(control,false))
	return b

func show_driving()->void:
	if menu!=null:menu.queue_free();menu=null
	driving_hud.visible=true

func notify(text_value:String,seconds:float=3.2)->void:
	feedback_label.text=text_value
	message_timer=seconds

func _process(delta:float)->void:
	if game==null:return
	if message_timer>0.0:
		message_timer-=delta
		if message_timer<=0.0:feedback_label.text=""
	if driving_hud.visible:
		stats.text="%d km/h\nTANK %d%%  •  SCHADEN %d%%\nKONTO %d €  •  RUF %d" % [game.vehicle.kmh(),int(game.vehicle.fuel),int(game.vehicle.damage),game.career.money,game.career.reputation]
		region_label.text="⌖ "+game.current_region+"     ☁ "+game.weather+"     "+game.clock_text()
		target_label.text=game.navigation_text()
		map_view.car=game.vehicle
		map_view.has_target=game.career.active_stage!=""
		map_view.target=game.career.target()
		map_view.track=game.route
		pickup_button.visible=game.career.active_stage=="" or game.can_interact()
		if game.career.active_stage=="":pickup_button.text="▶ ERSTEN AUFTRAG STARTEN"
		elif game.career.active_stage=="pickup":pickup_button.text="FAHRZEUG ÜBERNEHMEN"
		elif game.career.active_stage=="delivery":pickup_button.text="FAHRZEUG ABGEBEN"

func show_menu(page:String)->void:
	menu_page=page
	driving_hud.visible=false
	if menu!=null:menu.queue_free()
	menu=Control.new();menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(menu)
	var fade:=ColorRect.new();fade.color=Color(0.013,0.029,0.05,0.975)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(fade)
	var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(center)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(910,635)
	center.add_child(scroll)
	var column:=VBoxContainer.new();column.custom_minimum_size=Vector2(880,620)
	column.add_theme_constant_override("separation",9)
	scroll.add_child(column)
	var title:=label("AUTO BOSS 71.0  •  GERMAN ROADS",36)
	title.add_theme_color_override("font_color",Color(0.36,0.83,1.0))
	column.add_child(title)
	column.add_child(label("OPEN WORLD · LOGISTIK · TRANSPORTKARRIERE",18))
	column.add_child(HSeparator.new())
	match page:
		"start":
			column.add_child(label("Dein Unternehmen: "+game.career.rank(),24))
			column.add_child(label("Konto: %d €   •   Ruf: %d   •   Aufträge: %d" % [game.career.money,game.career.reputation,game.career.jobs_completed],19))
			if game.career.active_stage=="":
				add_action(column,"★  ERSTEN TRANSPORT SOFORT STARTEN",func():game.quick_action())
			else:
				add_action(column,"★  AKTIVEN AUFTRAG FORTSETZEN",func():game.resume_driving())
			add_action(column,"▶  FREIE FAHRT / SPIEL FORTSETZEN",func():game.resume_driving())
			add_action(column,"▣  AUFTRAGSBÖRSE",func():show_menu("jobs"))
			add_action(column,"▥  FIRMENZENTRALE & TUNING",func():show_menu("company"))
			add_action(column,"⌖  REGIONEN UND SPIELWELT",func():show_menu("regions"))
			add_action(column,"⚙  GRAFIK & PERFORMANCE",func():show_menu("settings"))
			add_action(column,"ℹ  STEUERUNG & HILFE",func():show_menu("help"))
		"pause":
			column.add_child(label("FAHRT PAUSIERT",25))
			add_action(column,"▶  WEITERFAHREN",func():game.resume_driving())
			add_action(column,"▣  AUFTRAGSBÖRSE",func():show_menu("jobs"))
			add_action(column,"▥  FIRMENZENTRALE",func():show_menu("company"))
			add_action(column,"⚙  GRAFIK & PERFORMANCE",func():show_menu("settings"))
			add_action(column,"💾  SPIEL SPEICHERN",func():game.save_progress())
			add_action(column,"⌂  HAUPTMENÜ",func():show_menu("start"))
		"jobs":
			column.add_child(label("Wähle einen Transportvertrag. Abholung und Übergabe erfolgen direkt in der offenen Welt.",16))
			column.add_child(label("AKTIV FREIGESCHALTET: Ruf %d" % game.career.reputation,19))
			for i in range(game.career.contracts.size()):
				var r:Dictionary=game.career.contracts[i]
				var locked:bool=game.career.reputation<int(r["required_rep"])
				var desc:String="%s  |  %s → %s  |  %s  |  %d €  |  Ruf %d" % [str(r["title"]),str(r["from"]),str(r["to"]),VehicleData.CATALOG[int(r["car"])]["name"],int(r["reward"]),int(r["required_rep"])]
				if int(r.get("deadline_minutes",0))>0:desc+="  |  EXPRESS %d min" % int(r["deadline_minutes"])
				var idx:int=i
				var b:=add_action(column,desc,func():game.accept_contract(idx))
				b.disabled=locked or game.career.active_stage!=""
			if game.career.active_stage!="":column.add_child(label("Aktiver Vertrag: "+game.career.destination_name(),18))
			add_action(column,"← ZURÜCK",func():show_menu("start"))
		"company":
			column.add_child(label("KARRIERESTATUS: "+game.career.rank(),22))
			column.add_child(label("Konto: %d €   |  Firmenstandorte: %d   |  Mitarbeiter: %d" % [game.career.money,1+game.career.depot_level,game.career.staff],18))
			add_action(column,"Motorupgrade  •  %d €  |  Level %d" % [650+game.career.engine_upgrade*450,game.career.engine_upgrade],func():game.buy_upgrade("engine"))
			add_action(column,"Bremsupgrade  •  %d €  |  Level %d" % [540+game.career.brake_upgrade*400,game.career.brake_upgrade],func():game.buy_upgrade("brakes"))
			add_action(column,"Neues Depot  •  %d €" % [7500+game.career.depot_level*9000],func():game.buy_upgrade("depot"))
			add_action(column,"Mitarbeiter einstellen  •  %d €" % [12500+game.career.staff*7500],func():game.buy_upgrade("staff"))
			add_action(column,"Kundenfahrzeug / Firmenwagen warten  •  225 €",func():game.service_vehicle())
			add_action(column,"← ZURÜCK",func():show_menu("start"))
		"regions":
			column.add_child(label("REGIONSKARTE  •  GESAMTES STRASSENNETZ",20))
			var overview:=WorldMap.new()
			overview.game=game
			column.add_child(overview)
			for c in WorldData.CITY_CENTERS:
				column.add_child(label("●  %s     [%s]" % [str(c["name"]),str(c["kind"])],20))
			column.add_child(label("25 × 25 km Koordinatenwelt, dynamisches Streaming und fünf Regionen.",16))
			column.add_child(label("Die Welt ist ein technischer Ausbau-Prototyp, keine fertig ausgestaltete Deutschlandkarte.",16))
			add_action(column,"← ZURÜCK",func():show_menu("start"))
		"settings":
			column.add_child(label("WELT-STREAMING / VERKEHR / MOBILE-PERFORMANCE",23))
			var quality_names:Array[String]=["PERFORMANCE", "AUSGEWOGEN", "DETAILS"]
			column.add_child(label("Aktuell: "+quality_names[game.quality],19))
			add_action(column,"PERFORMANCE  •  9 Weltsektoren, 8 KI-Fahrzeuge",func():game.set_quality(0))
			add_action(column,"AUSGEWOGEN  •  25 Weltsektoren, 12 KI-Fahrzeuge",func():game.set_quality(1))
			add_action(column,"DETAILS  •  25 Weltsektoren, 16 KI-Fahrzeuge",func():game.set_quality(2))
			column.add_child(label("Bei Leistungseinbrüchen PERFORMANCE wählen. Ziel: möglichst stabile 30 FPS.",17))
			add_action(column,"← ZURÜCK",func():show_menu("start"))
		"help":
			column.add_child(label("HANDY: Links/rechts unten lenken · GAS/BREMSE rechts gedrückt halten.",20))
			column.add_child(label("Neu: Abseits befestigter Straßen ist das Fahrzeug deutlich langsamer.",18))
			column.add_child(label("PC: W/↑ Gas, S/↓ Bremsen/Rückwärts, A/D oder ←/→ lenken.",20))
			column.add_child(label("F: Übernahme/Abgabe · C: Kamera · M: Karte · ESC: Menü.",20))
			column.add_child(label("Gelbe Zielmarkierung finden, anhalten und ÜBERNEHMEN/ABGEBEN drücken.",19))
			add_action(column,"← ZURÜCK",func():show_menu("start"))
		"result":
			column.add_child(label(game.career.last_result,23))
			add_action(column,"NÄCHSTEN AUFTRAG ANSEHEN",func():show_menu("jobs"))
			add_action(column,"WEITERFAHREN",func():game.resume_driving())
			add_action(column,"HAUPTMENÜ",func():show_menu("start"))

func add_action(column:VBoxContainer,title:String,callback:Callable)->Button:
	var b:=button(title)
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	b.pressed.connect(callback)
	column.add_child(b)
	return b
