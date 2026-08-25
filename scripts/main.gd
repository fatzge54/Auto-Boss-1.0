extends Node3D

var car
var cam
var gas=false
var brake=false
var left=false
var right=false
var speed=0.0
var fuel=100.0
var damage=0.0
var money=5000
var reputation=15
var game_state="menu"
var selected_route=0
var selected_car=0
var mission_finished=false
var distance_left=0.0
var traffic=[]
var traffic_timer=0.0

var routes=[
	{"name":"Stuttgart → Frankfurt","distance":205.0,"reward":295,"rep":15,"class":"STANDARD","risk":"NORMAL"},
	{"name":"Stuttgart → München","distance":220.0,"reward":340,"rep":15,"class":"STANDARD","risk":"NORMAL"},
	{"name":"Stuttgart → Nürnberg","distance":210.0,"reward":365,"rep":16,"class":"STANDARD","risk":"NORMAL"},
	{"name":"Stuttgart → Freiburg","distance":205.0,"reward":390,"rep":17,"class":"STANDARD","risk":"KURVEN"},
	{"name":"Stuttgart → Köln","distance":366.0,"reward":540,"rep":15,"class":"STANDARD","risk":"VERKEHR"},
	{"name":"Stuttgart → Düsseldorf","distance":410.0,"reward":650,"rep":20,"class":"EXPRESS","risk":"ZEITDRUCK"},
	{"name":"Stuttgart → Leipzig","distance":485.0,"reward":760,"rep":21,"class":"EXPRESS","risk":"ZEITDRUCK"},
	{"name":"Stuttgart → Hannover","distance":510.0,"reward":820,"rep":22,"class":"EXPRESS","risk":"VERKEHR"},
	{"name":"Stuttgart → Hamburg","distance":630.0,"reward":960,"rep":18,"class":"LANGSTRECKE","risk":"MÜDIGKEIT"},
	{"name":"Stuttgart → Bremen","distance":635.0,"reward":990,"rep":22,"class":"LANGSTRECKE","risk":"WETTER"},
	{"name":"Stuttgart → Berlin","distance":635.0,"reward":1120,"rep":24,"class":"PREMIUM","risk":"HOCH"},
	{"name":"Stuttgart → Rostock","distance":800.0,"reward":1390,"rep":28,"class":"PREMIUM","risk":"HOCH"},
	{"name":"Stuttgart → Kiel","distance":760.0,"reward":1460,"rep":32,"class":"VIP","risk":"EXTREM"},
	{"name":"Stuttgart → Dresden","distance":510.0,"reward":1210,"rep":35,"class":"VIP","risk":"EXTREM"}
]
var cars=[
	{"name":"Transporter","max_speed":42.0,"accel":14.0,"brake":30.0,"fuel_factor":0.80,"color":Color(0.08,0.22,0.55)},
	{"name":"Limousine","max_speed":48.0,"accel":18.0,"brake":34.0,"fuel_factor":1.00,"color":Color(0.08,0.08,0.10)},
	{"name":"Sportwagen","max_speed":55.0,"accel":24.0,"brake":39.0,"fuel_factor":1.25,"color":Color(0.75,0.08,0.08)}
]

var ui_layer
var menu_root
var game_root
var speed_label
var info_label
var mission_label
var money_label
var service_label
var refuel_button
var repair_button
var pause_button
var pause_panel
var pause_resume_button
var pause_abort_button
var pause_save_button
var near_service=false
var current_fuel_price=1.80
var current_service_name=""
var mission_start_money=0
var settlement_panel
var settlement_title
var settlement_details
var settlement_next_button
var settlement_home_button
var route_progress
var world_env
var sun_light
var day_clock=0.22
var weather_state="Klar"
var weather_timer=0.0
var rain_root
var weather_label
var headlights=[]
var career_level=1
var jobs_completed=0
var career_xp=0
var safe_driving_streak=0
var total_fines_paid=0
# AUTO BOSS 10.0 BIG JUMP systems
var fines_total=0
var speed_limit=130
var camera_cooldown=0.0
var event_timer=0.0
var event_text="Freie Fahrt"
var event_label
var fine_label
var headlights_on=true
var camera_mode=0 # 0 = Verfolger, 1 = Cockpit
var camera_button
var light_button
var police_heat=0
var clean_mission_bonus=0
var streak_bonus=0
var discipline_bonus=0
var long_distance_bonus=0
var mission_xp_earned=0
var engine_upgrade=0
var brake_upgrade=0
var eco_upgrade=0
var perfect_jobs=0
var company_staff=0
var company_fleet=0
var company_office=0
var company_jobs=0
var company_bonus_last=0
var driver_level=1
var driver_salary=45
var fleet_condition=100
var dispatch_reputation=0
var company_contracts_won=0
var empire_level=1
var branch_count=1
var logistics_rating=0
var elite_contracts=0
var company_cash_total=0


var company_income_total=0
var company_passive_last=0
# AUTO BOSS 14.0 CONTRACT COMMAND
var dispatch_mode=0 # 0 BALANCE, 1 SICHER, 2 PROFIT
var dispatch_route=0
var dispatch_streak=0
var navigation_label
var destination_bonus=0
var route_stage="AUTOBAHN"
var arrival_announced=false


func _ready():
	randomize()
	load_save()
	create_environment()
	create_ground()
	create_road()
	create_scenery()
	create_road_features()
	create_city_gate_80(-2780.0)
	create_extra_scenery_52()
	create_world_upgrade_53()
	create_visual_upgrade_100()
	create_visual_upgrade_110()
	create_road_graphics_150()
	create_visual_revolution_160()
	create_graphics_overhaul_170()
	create_world_revolution_180()
	create_service_station_at(Vector3(16.0,0,-520.0),"SERVICE SÜD",1.79)
	create_service_station_at(Vector3(16.0,0,-1120.0),"SERVICE MITTE",1.89)
	create_service_station_at(Vector3(16.0,0,-1720.0),"SERVICE NORD",1.84)
	create_player()
	create_rain_system()
	create_ui()
	apply_empire_theme_140()
	show_main_menu()


func _physics_process(delta):
	if game_state!="driving":
		return

	update_world_30(delta)
	update_road_events_40(delta)
	update_player(delta)
	wrap_road()
	update_camera()
	update_traffic(delta)
	update_service()
	update_mission(delta)
	update_hud()


func save_game():
	var cfg=ConfigFile.new()
	cfg.set_value("player","money",money)
	cfg.set_value("player","reputation",reputation)
	cfg.set_value("player","selected_car",selected_car)
	cfg.set_value("player","jobs_completed",jobs_completed)
	cfg.set_value("player","career_xp",career_xp)
	cfg.set_value("player","safe_driving_streak",safe_driving_streak)
	cfg.set_value("player","total_fines_paid",total_fines_paid)
	cfg.set_value("player","engine_upgrade",engine_upgrade)
	cfg.set_value("player","brake_upgrade",brake_upgrade)
	cfg.set_value("player","eco_upgrade",eco_upgrade)
	cfg.set_value("player","perfect_jobs",perfect_jobs)
	cfg.set_value("player","company_staff",company_staff)
	cfg.set_value("player","company_fleet",company_fleet)
	cfg.set_value("player","company_office",company_office)
	cfg.set_value("player","company_jobs",company_jobs)
	cfg.set_value("player","driver_level",driver_level)
	cfg.set_value("player","driver_salary",driver_salary)
	cfg.set_value("player","fleet_condition",fleet_condition)
	cfg.set_value("player","dispatch_reputation",dispatch_reputation)
	cfg.set_value("player","company_contracts_won",company_contracts_won)
	cfg.set_value("player","empire_level",empire_level)
	cfg.set_value("player","branch_count",branch_count)
	cfg.set_value("player","logistics_rating",logistics_rating)
	cfg.set_value("player","elite_contracts",elite_contracts)
	cfg.set_value("player","company_cash_total",company_cash_total)
	cfg.set_value("player","company_income_total",company_income_total)
	cfg.set_value("player","dispatch_mode",dispatch_mode)
	cfg.set_value("player","dispatch_route",dispatch_route)
	cfg.set_value("player","dispatch_streak",dispatch_streak)
	cfg.save("user://autoboss.cfg")


func load_save():
	var cfg=ConfigFile.new()
	if cfg.load("user://autoboss.cfg")==OK:
		money=int(cfg.get_value("player","money",5000))
		reputation=int(cfg.get_value("player","reputation",15))
		selected_car=int(cfg.get_value("player","selected_car",0))
	jobs_completed=int(cfg.get_value("player","jobs_completed",0))
	career_xp=int(cfg.get_value("player","career_xp",0))
	safe_driving_streak=int(cfg.get_value("player","safe_driving_streak",0))
	total_fines_paid=int(cfg.get_value("player","total_fines_paid",0))
	engine_upgrade=int(cfg.get_value("player","engine_upgrade",0))
	brake_upgrade=int(cfg.get_value("player","brake_upgrade",0))
	eco_upgrade=int(cfg.get_value("player","eco_upgrade",0))
	perfect_jobs=int(cfg.get_value("player","perfect_jobs",0))
	company_staff=int(cfg.get_value("player","company_staff",0))
	company_fleet=int(cfg.get_value("player","company_fleet",0))
	company_office=int(cfg.get_value("player","company_office",0))
	company_jobs=int(cfg.get_value("player","company_jobs",0))
	driver_level=int(cfg.get_value("player","driver_level",1))
	driver_salary=int(cfg.get_value("player","driver_salary",45))
	fleet_condition=int(cfg.get_value("player","fleet_condition",100))
	dispatch_reputation=int(cfg.get_value("player","dispatch_reputation",0))
	company_contracts_won=int(cfg.get_value("player","company_contracts_won",0))
	empire_level=int(cfg.get_value("player","empire_level",1))
	branch_count=int(cfg.get_value("player","branch_count",1))
	logistics_rating=int(cfg.get_value("player","logistics_rating",0))
	elite_contracts=int(cfg.get_value("player","elite_contracts",0))
	company_cash_total=int(cfg.get_value("player","company_cash_total",0))
	company_income_total=int(cfg.get_value("player","company_income_total",0))
	dispatch_mode=int(cfg.get_value("player","dispatch_mode",0))
	dispatch_route=int(cfg.get_value("player","dispatch_route",0))
	dispatch_streak=int(cfg.get_value("player","dispatch_streak",0))
	career_level=1+int(jobs_completed/3)


func apply_empire_theme_140():
	var theme=Theme.new()
	theme.default_font_size=18
	theme.set_color("font_color","Label",Color(0.92,0.96,1.0))
	theme.set_color("font_color","Button",Color(0.94,0.97,1.0))
	theme.set_color("font_hover_color","Button",Color.WHITE)
	var normal=StyleBoxFlat.new()
	normal.bg_color=Color(0.025,0.055,0.095,0.90)
	normal.border_color=Color(0.10,0.27,0.43,0.90)
	normal.set_border_width_all(1)
	normal.corner_radius_top_left=7; normal.corner_radius_top_right=7; normal.corner_radius_bottom_left=7; normal.corner_radius_bottom_right=7
	var hover=normal.duplicate()
	hover.bg_color=Color(0.035,0.22,0.52,0.96)
	hover.border_color=Color(0.18,0.58,1.0)
	var pressed=normal.duplicate()
	pressed.bg_color=Color(0.02,0.34,0.78,1.0)
	var disabled=normal.duplicate()
	disabled.bg_color=Color(0.035,0.045,0.06,0.72)
	theme.set_stylebox("normal","Button",normal)
	theme.set_stylebox("hover","Button",hover)
	theme.set_stylebox("pressed","Button",pressed)
	theme.set_stylebox("disabled","Button",disabled)
	theme.set_color("font_disabled_color","Button",Color(0.48,0.55,0.62))
	menu_root.theme=theme
	game_root.theme=theme

func empire_panel_140(pos:Vector2,size:Vector2,alpha:float=0.92):
	var panel=ColorRect.new()
	panel.color=Color(0.015,0.035,0.065,alpha)
	panel.position=pos; panel.size=size
	menu_root.add_child(panel)
	return panel

func empire_label_140(text_value:String,pos:Vector2,size_value:int=18,color_value:Color=Color(0.92,0.96,1.0)):
	var l=Label.new(); l.text=text_value; l.position=pos
	l.add_theme_font_size_override("font_size",size_value)
	l.add_theme_color_override("font_color",color_value)
	menu_root.add_child(l); return l

func empire_stat_140(title:String,value:String,pos:Vector2,width:float=145.0):
	var p=ColorRect.new(); p.color=Color(0.02,0.075,0.12,0.94); p.position=pos; p.size=Vector2(width,62); menu_root.add_child(p)
	var a=Label.new(); a.text=title; a.position=Vector2(12,8); a.add_theme_font_size_override("font_size",11); a.add_theme_color_override("font_color",Color(0.52,0.66,0.78)); p.add_child(a)
	var b=Label.new(); b.text=value; b.position=Vector2(12,27); b.add_theme_font_size_override("font_size",21); b.add_theme_color_override("font_color",Color(0.35,1.0,0.56)); p.add_child(b)

func clear_menu():
	for child in menu_root.get_children():
		child.queue_free()


func menu_button(text_value,pos,callback):
	var b=Button.new()
	b.text=text_value
	b.position=pos
	b.size=Vector2(440,62)
	b.add_theme_font_size_override("font_size",21)
	b.pressed.connect(callback)
	menu_root.add_child(b)



func career_rank_name():
	if jobs_completed>=40:
		return "AUTO-BOSS"
	elif jobs_completed>=28:
		return "EXPERTE"
	elif jobs_completed>=18:
		return "PROFI"
	elif jobs_completed>=10:
		return "DISPONENT"
	elif jobs_completed>=4:
		return "FAHRER"
	return "NEULING"

func contract_class_name():
	return str(routes[selected_route].get("class","STANDARD"))

func company_level():
	return 1+int(jobs_completed/5)

func company_name():
	if jobs_completed>=40: return "AUTO BOSS LOGISTICS"
	if jobs_completed>=20: return "PREMIUM TRANSFER"
	if jobs_completed>=8: return "ROADRUNNER TRANSPORT"
	return "STARTER TRANSFER"



func company_auto_capacity_122():
	return min(company_staff,company_fleet)

func dispatch_mode_name_134():
	if dispatch_mode==1:
		return "SICHERHEIT"
	elif dispatch_mode==2:
		return "MAX PROFIT"
	return "BALANCE"

func dispatch_mode_factor_134():
	if dispatch_mode==1:
		return 0.90
	elif dispatch_mode==2:
		return 1.22
	return 1.0

func dispatch_route_factor_134():
	# Gewählte Schwerpunkt-Route gibt einen kleinen Managementbonus.
	return 1.0+float(clamp(dispatch_route,0,4))*0.025

func company_passive_income_122():
	var teams=company_auto_capacity_122()
	if teams<=0:
		return 0
	var network_total=0
	for i in range(branch_count):
		network_total+=branch_income_131(i)
	var condition_factor=0.75+float(fleet_condition)*0.0025
	var streak_factor=1.0+min(dispatch_streak,10)*0.015
	return int(round(network_total*(1.0+float(company_office)*0.06)*dispatch_mode_factor_134()*dispatch_route_factor_134()*condition_factor*streak_factor))

func cycle_dispatch_mode_134():
	dispatch_mode=(dispatch_mode+1)%3
	save_game()
	show_company_dispatch_133()

func set_dispatch_route_134(index):
	dispatch_route=clamp(index,0,4)
	save_game()
	show_company_dispatch_133()

func run_company_jobs_122():
	var teams=company_auto_capacity_122()
	company_passive_last=company_passive_income_122()
	if teams>0:
		company_jobs+=teams
		company_income_total+=company_passive_last
		company_cash_total+=company_passive_last
		logistics_rating+=max(1,branch_count)
		money+=company_passive_last

func company_level_1202():
	return 1+company_staff+company_fleet+company_office

func company_bonus_1202():
	return company_staff*20+company_fleet*30+company_office*15

func company_upgrade_cost_1202(level):
	return 750+level*650

func buy_company_upgrade_1202(kind):
	var level=0
	if kind=="staff":
		level=company_staff
	elif kind=="fleet":
		level=company_fleet
	else:
		level=company_office
	if level>=5:
		return
	var cost=company_upgrade_cost_1202(level)
	if money<cost:
		return
	money-=cost
	if kind=="staff":
		company_staff+=1
	elif kind=="fleet":
		company_fleet+=1
	else:
		company_office+=1
	save_game()
	show_company_hq_1202()

func empire_rank_130():
	if empire_level>=5:
		return "LOGISTIK-IMPERIUM"
	elif empire_level>=4:
		return "BUNDESWEITE SPEDITION"
	elif empire_level>=3:
		return "REGIONALER MARKTFÜHRER"
	elif empire_level>=2:
		return "WACHSENDE FIRMA"
	return "STARTER-UNTERNEHMEN"

func branch_cost_130():
	return 2500+branch_count*1750

func buy_branch_130():
	var cost=branch_cost_130()
	if money<cost or branch_count>=5:
		return
	money-=cost
	branch_count+=1
	empire_level=max(empire_level,branch_count)
	save_game()
	show_company_hq_1202()

func empire_contract_bonus_130():
	var teams=min(company_staff,company_fleet)
	if teams<=0:
		return 0
	return teams*(branch_count*30+empire_level*25+company_office*15)

func company_driver_name_123():
	if driver_level>=5:
		return "SENIOR-FAHRER"
	elif driver_level>=3:
		return "PROFI-FAHRER"
	return "JUNIOR-FAHRER"

func driver_upgrade_cost_123():
	return 650+driver_level*500

func train_driver_123():
	if driver_level>=5:
		return
	var cost=driver_upgrade_cost_123()
	if money<cost:
		return
	money-=cost
	driver_level+=1
	driver_salary=45+(driver_level-1)*20
	save_game()
	show_company_hq_1202()

func repair_company_fleet_123():
	if fleet_condition>=100:
		return
	var cost=(100-fleet_condition)*8
	if money<cost:
		return
	money-=cost
	fleet_condition=100
	save_game()
	show_company_hq_1202()

func branch_city_131(index):
	var cities=["Stuttgart","Köln","Hamburg","Berlin","München"]
	return cities[clamp(index,0,cities.size()-1)]

func branch_income_131(index):
	var teams=max(1,company_auto_capacity_122())
	return int((70+index*35+company_office*18)*teams)

func show_branch_network_131():
	clear_menu()
	var title=Label.new()
	title.text="AUTO BOSS 17.0 • DEUTSCHLAND EMPIRE"
	title.position=Vector2(300,35)
	title.add_theme_font_size_override("font_size",32)
	menu_root.add_child(title)

	var sub=Label.new()
	sub.text="NIEDERLASSUNGS-NETZWERK   •   "+str(branch_count)+"/5 Standorte   •   "+empire_rank_130()
	sub.position=Vector2(315,82)
	sub.add_theme_font_size_override("font_size",18)
	menu_root.add_child(sub)

	for i in range(5):
		var card=Button.new()
		var active=i<branch_count
		if active:
			var teams=max(1,min(company_staff,company_fleet))
			card.text="✓  "+branch_city_131(i)+"   •   "+str(teams)+" Team(s)   •   Prognose +"+str(branch_income_131(i))+" €/Fahrt   •   Flotte "+str(fleet_condition)+"%"
		else:
			card.text="🔒  "+branch_city_131(i)+"   •   Niederlassung noch nicht eröffnet"
		card.position=Vector2(255,135+i*72)
		card.size=Vector2(770,56)
		card.disabled=true
		card.add_theme_font_size_override("font_size",17)
		menu_root.add_child(card)

	var totals=Label.new()
	totals.text="Firmenumsatz: "+str(company_cash_total)+" €   •   Firmengewinn: "+str(company_income_total)+" €   •   Logistik-Rating: "+str(logistics_rating)+"   •   Elite-Verträge: "+str(elite_contracts)
	totals.position=Vector2(275,515)
	totals.add_theme_font_size_override("font_size",16)
	menu_root.add_child(totals)

	if branch_count<5:
		var buy=Button.new()
		buy.text="NÄCHSTEN STANDORT ERÖFFNEN: "+branch_city_131(branch_count)+"   •   "+str(branch_cost_130())+" €"
		buy.position=Vector2(300,555)
		buy.size=Vector2(680,50)
		buy.disabled=money<branch_cost_130()
		buy.pressed.connect(func(): buy_branch_130())
		menu_root.add_child(buy)

	menu_button("← FIRMENZENTRALE",Vector2(420,630),func(): show_company_hq_1202())

func show_company_dispatch_133():
	clear_menu()
	var title=Label.new()
	title.text="AUTO BOSS 17.0 • CONTRACT COMMAND"
	title.position=Vector2(365,24)
	title.add_theme_font_size_override("font_size",30)
	menu_root.add_child(title)

	var teams=company_auto_capacity_122()
	var header=Label.new()
	header.text="TEAMS "+str(teams)+"   •   STANDORTE "+str(branch_count)+"/5   •   SERIE "+str(dispatch_streak)+"   •   PROGNOSE +"+str(company_passive_income_122())+" €/Fahrt"
	header.position=Vector2(315,67)
	header.add_theme_font_size_override("font_size",16)
	menu_root.add_child(header)

	var mode=Button.new()
	mode.text="STRATEGIE:  "+dispatch_mode_name_134()+"   •   tippen zum Wechseln   •   Faktor x"+str(snapped(dispatch_mode_factor_134(),0.01))
	mode.position=Vector2(285,100); mode.size=Vector2(710,45)
	mode.pressed.connect(func(): cycle_dispatch_mode_134())
	menu_root.add_child(mode)

	var routes_auto=[
		["Stuttgart → Köln",205],
		["Köln → Hamburg",420],
		["Hamburg → Berlin",290],
		["Berlin → München",585],
		["München → Stuttgart",225]
	]
	for i in range(5):
		var card=Button.new()
		var unlocked=i<branch_count
		var projected=branch_income_131(i) if unlocked else 0
		if unlocked:
			var marker="★ " if i==dispatch_route else "   "
			var team_text="Team bereit" if teams>0 else "Kein Team"
			card.text=marker+str(routes_auto[i][0])+"   •   "+str(routes_auto[i][1])+" km   •   "+team_text+"   •   Basis +"+str(projected)+" €"
			card.disabled=false
			card.pressed.connect(func(idx=i): set_dispatch_route_134(idx))
		else:
			card.text="🔒 "+str(routes_auto[i][0])+"   •   Niederlassung zuerst eröffnen"
			card.disabled=true
		card.position=Vector2(245,158+i*58)
		card.size=Vector2(790,46)
		card.add_theme_font_size_override("font_size",15)
		menu_root.add_child(card)

	var hint=Label.new()
	var risk="weniger Ertrag, stabilere Flotte" if dispatch_mode==1 else ("mehr Ertrag, höhere Flottenbelastung" if dispatch_mode==2 else "ausgewogener Betrieb")
	hint.text="SCHWERPUNKT: "+str(routes_auto[dispatch_route][0])+"   •   "+risk+"   •   Flotte "+str(fleet_condition)+"%"
	hint.position=Vector2(300,465)
	hint.add_theme_font_size_override("font_size",15)
	menu_root.add_child(hint)

	var summary=Label.new()
	summary.text="FIRMENJOBS "+str(company_jobs)+"   •   DISPO-REP "+str(dispatch_reputation)+"   •   GROSSVERTRÄGE "+str(company_contracts_won)+"   •   LOGISTIK "+str(logistics_rating)
	summary.position=Vector2(300,500)
	summary.add_theme_font_size_override("font_size",15)
	menu_root.add_child(summary)

	menu_button("← FIRMENZENTRALE",Vector2(420,565),func(): show_company_hq_1202())

func show_company_hq_1202():
	clear_menu()
	var shade=ColorRect.new(); shade.color=Color(0.005,0.018,0.035,0.58); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu_root.add_child(shade)
	empire_panel_140(Vector2(20,20),Vector2(1240,680),0.94)
	empire_label_140("FIRMENZENTRALE",Vector2(48,38),32,Color.WHITE)
	empire_label_140("DEIN IMPERIUM WÄCHST  •  "+empire_rank_130(),Vector2(50,78),13,Color(0.24,0.65,1.0))
	empire_stat_140("KONTOSTAND",str(money)+" €",Vector2(48,112),180)
	empire_stat_140("FIRMENGEWINN",str(company_income_total)+" €",Vector2(240,112),180)
	empire_stat_140("FIRMENJOBS",str(company_jobs),Vector2(432,112),160)
	empire_stat_140("LOGISTIK",str(logistics_rating),Vector2(604,112),150)
	empire_stat_140("STANDORTE",str(branch_count)+" / 5",Vector2(766,112),150)
	empire_stat_140("FLOTTE",str(fleet_condition)+"%",Vector2(928,112),150)
	var left=Vector2(48,205)
	empire_label_140("MANAGEMENT",left,16,Color(0.58,0.72,0.84))
	var entries=[
		["👥  MITARBEITER  "+str(company_staff)+"/5","Team erweitern  •  "+str(company_upgrade_cost_1202(company_staff))+" €","staff"],
		["🚘  FIRMENFLOTTE  "+str(company_fleet)+"/5","Fahrzeug kaufen  •  "+str(company_upgrade_cost_1202(company_fleet))+" €","fleet"],
		["📊  DISPOSITION  "+str(company_office)+"/5","Ertrag steigern  •  "+str(company_upgrade_cost_1202(company_office))+" €","office"]
	]
	for i in range(entries.size()):
		var b=Button.new(); b.text=entries[i][0]+"\n     "+entries[i][1]; b.position=Vector2(48,238+i*72); b.size=Vector2(500,60); b.alignment=HORIZONTAL_ALIGNMENT_LEFT; var kind=entries[i][2]; b.pressed.connect(func(): buy_company_upgrade_1202(kind)); menu_root.add_child(b)
	empire_label_140("OPERATIONS",Vector2(590,205),16,Color(0.58,0.72,0.84))
	var dispatch=Button.new(); dispatch.text="♛  CONTRACT COMMAND\n     "+dispatch_mode_name_134()+"  •  +"+str(company_passive_income_122())+" €/Fahrt"; dispatch.position=Vector2(590,238); dispatch.size=Vector2(610,72); dispatch.alignment=HORIZONTAL_ALIGNMENT_LEFT; dispatch.pressed.connect(func(): show_company_dispatch_133()); menu_root.add_child(dispatch)
	var network=Button.new(); var next_city="DEUTSCHLAND KOMPLETT" if branch_count>=5 else branch_city_131(branch_count)+" • "+str(branch_cost_130())+" €"; network.text="⌖  DEUTSCHLAND-EMPIRE  "+str(branch_count)+"/5\n     Nächster Standort: "+next_city; network.position=Vector2(590,322); network.size=Vector2(610,72); network.alignment=HORIZONTAL_ALIGNMENT_LEFT; network.pressed.connect(func(): show_branch_network_131()); menu_root.add_child(network)
	var train=Button.new(); train.text="FAHRER-TRAINING  •  L"+str(driver_level)+"/5  •  "+str(driver_upgrade_cost_123())+" €"; train.position=Vector2(590,406); train.size=Vector2(295,56); train.disabled=driver_level>=5 or money<driver_upgrade_cost_123(); train.pressed.connect(func(): train_driver_123()); menu_root.add_child(train)
	var repair=Button.new(); var repair_cost=(100-fleet_condition)*8; repair.text="FLOTTE WARTEN  •  "+str(repair_cost)+" €"; repair.position=Vector2(905,406); repair.size=Vector2(295,56); repair.disabled=fleet_condition>=100 or money<repair_cost; repair.pressed.connect(func(): repair_company_fleet_123()); menu_root.add_child(repair)
	empire_panel_140(Vector2(48,500),Vector2(1152,110),0.75)
	empire_label_140("AKTIVE STRATEGIE",Vector2(70,518),12,Color(0.52,0.66,0.78))
	empire_label_140(dispatch_mode_name_134(),Vector2(70,542),24,Color(1.0,0.72,0.18))
	empire_label_140("AUTO-BETRIEB  +"+str(company_passive_income_122())+" €/Fahrt     •     EIGENE FAHRT  +"+str(company_bonus_1202())+" €     •     DISPO-REP "+str(dispatch_reputation)+"     •     GROSSVERTRÄGE "+str(company_contracts_won),Vector2(285,548),15,Color(0.78,0.86,0.92))
	menu_button("←  ZURÜCK",Vector2(470,630),func(): show_main_menu())


func show_main_menu():
	game_state="menu"
	menu_root.visible=true; game_root.visible=false; clear_menu()
	# 16.0: eigenständiger Premium-Homescreen – die 3D-Welt scheint nicht mehr störend durch.
	var backdrop=ColorRect.new(); backdrop.color=Color(0.006,0.012,0.024,0.985); backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu_root.add_child(backdrop)
	var glow=ColorRect.new(); glow.color=Color(0.02,0.16,0.34,0.72); glow.position=Vector2(395,22); glow.size=Vector2(860,5); menu_root.add_child(glow)
	empire_panel_140(Vector2(22,22),Vector2(360,676),0.985)
	empire_label_140("AUTO BOSS",Vector2(48,42),44,Color.WHITE)
	empire_label_140("17.0  •  GRAPHICS OVERHAUL",Vector2(50,94),16,Color(0.16,0.70,1.0))
	empire_label_140("DRIVE  •  BUILD  •  DOMINATE",Vector2(50,126),11,Color(0.55,0.68,0.78))
	empire_label_140("DEIN WEG ZUM AUTO-IMPERIUM",Vector2(438,62),14,Color(0.38,0.72,1.0))
	empire_label_140("FAHRZEUGÜBERFÜHRUNG. ABER ALS GAME.",Vector2(438,88),29,Color.WHITE)
	empire_label_140("Aufträge fahren  •  Fuhrpark tunen  •  Standorte erobern  •  Firma skalieren",Vector2(438,130),15,Color(0.60,0.72,0.82))
	empire_panel_140(Vector2(410,174),Vector2(845,300),0.94)
	empire_label_140("LIVE OPERATIONS",Vector2(438,198),12,Color(0.42,0.70,0.92))
	empire_label_140("DEUTSCHLAND IST DEIN SPIELFELD",Vector2(438,226),25,Color.WHITE)
	empire_label_140("STUTTGART",Vector2(452,294),17,Color(0.35,1.0,0.58))
	empire_label_140("━━━━━━━━━━━━━━  FRANKFURT  ━━━━━━━━━━━━━━  KÖLN",Vector2(560,294),16,Color(0.48,0.67,0.82))
	empire_label_140("Nächster Auftrag",Vector2(452,352),12,Color(0.52,0.66,0.78))
	empire_label_140("Bereit für die Straße",Vector2(452,378),22,Color.WHITE)
	empire_label_140("Wähle links AUFTRAG STARTEN und baue deinen Ruf aus.",Vector2(452,420),14,Color(0.65,0.76,0.84))
	var y=170
	var items=[
		["🚗  AUFTRAG STARTEN",func(): show_routes()],
		["▣  GARAGE / FAHRZEUGE",func(): show_garage()],
		["▥  FIRMENZENTRALE",func(): show_company_hq_1202()],
		["⌖  DEUTSCHLAND-EMPIRE",func(): show_branch_network_131()],
		["💾  SPIELSTAND SPEICHERN",func(): save_game()]
	]
	for item in items:
		var b=Button.new(); b.text=item[0]; b.position=Vector2(48,y); b.size=Vector2(305,54); b.alignment=HORIZONTAL_ALIGNMENT_LEFT; b.add_theme_constant_override("icon_max_width",22); b.pressed.connect(item[1]); menu_root.add_child(b); y+=66
	empire_label_140("DEIN UNTERNEHMEN",Vector2(48,525),13,Color(0.55,0.68,0.78))
	empire_label_140(empire_rank_130(),Vector2(48,548),20,Color.WHITE)
	empire_label_140("Nächster Meilenstein: "+str(max(0,5-jobs_completed))+" Jobs",Vector2(48,580),13,Color(0.62,0.72,0.80))
	var prog=ProgressBar.new(); prog.position=Vector2(48,610); prog.size=Vector2(305,9); prog.value=min(100.0,float(jobs_completed%5)*20.0); prog.show_percentage=false; menu_root.add_child(prog)
	empire_panel_140(Vector2(410,520),Vector2(845,178),0.88)
	empire_label_140("FAHRER-PROFIL",Vector2(438,542),13,Color(0.52,0.66,0.78))
	empire_stat_140("KONTOSTAND",str(money)+" €",Vector2(438,575),180)
	empire_stat_140("REPUTATION",str(reputation),Vector2(630,575),140)
	empire_stat_140("JOBS",str(jobs_completed),Vector2(782,575),130)
	empire_stat_140("FIRMENJOBS",str(company_jobs),Vector2(924,575),145)
	empire_stat_140("STANDORTE",str(branch_count)+" / 5",Vector2(1081,575),145)
	empire_label_140("Deutschland wartet. Bau dein Fahrzeug-Imperium auf.",Vector2(438,654),16,Color(0.72,0.82,0.90))


func show_routes():
	clear_menu()

	var title=Label.new()
	title.text="AUFTRAGSZENTRALE"
	title.position=Vector2(450,35)
	title.add_theme_font_size_override("font_size",34)
	menu_root.add_child(title)

	for i in range(routes.size()):
		var r=routes[i]
		var b=Button.new()
		var needed=int(r.get("rep",15))
		var locked=reputation<needed
		b.text=("🔒 " if locked else "")+"["+str(r.get("class","STANDARD"))+"]  "+r["name"]+"  •  "+str(int(r["distance"]))+" km  •  "+str(r["reward"])+" €  •  "+str(r.get("risk","NORMAL"))+"  •  Rep "+str(needed)
		b.position=Vector2(205,74+i*34)
		b.size=Vector2(870,30)
		b.add_theme_font_size_override("font_size",13)
		b.disabled=locked
		var idx=i
		b.pressed.connect(func():
			selected_route=idx
			start_mission()
		)
		menu_root.add_child(b)

	menu_button("← ZURÜCK",Vector2(420,558),func(): show_main_menu())

func upgrade_cost(level):
	return 450+level*350

func buy_upgrade(kind):
	var level=engine_upgrade if kind=="engine" else (brake_upgrade if kind=="brake" else eco_upgrade)
	if level>=5:
		return
	var cost=upgrade_cost(level)
	if money<cost:
		return
	money-=cost
	if kind=="engine": engine_upgrade+=1
	elif kind=="brake": brake_upgrade+=1
	else: eco_upgrade+=1
	save_game()
	show_garage()

func show_garage():
	clear_menu()
	var garage_bg=ColorRect.new(); garage_bg.color=Color(0.006,0.012,0.024,0.985); garage_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu_root.add_child(garage_bg)
	var garage_line=ColorRect.new(); garage_line.color=Color(0.02,0.38,0.78,0.9); garage_line.position=Vector2(260,76); garage_line.size=Vector2(760,3); menu_root.add_child(garage_line)

	var title=Label.new()
	title.text="GARAGE 17.0 • PERFORMANCE STUDIO"
	title.position=Vector2(405,28)
	title.add_theme_font_size_override("font_size",32)
	menu_root.add_child(title)

	for i in range(cars.size()):
		var c=cars[i]
		var b=Button.new()
		var prefix="✓ " if i==selected_car else ""
		b.text=prefix+c["name"]+"   •   Vmax "+str(int(c["max_speed"]*3.6))+" km/h   •   Verbrauch "+str(c["fuel_factor"])+"x"
		b.position=Vector2(330,88+i*60)
		b.size=Vector2(620,52)
		b.add_theme_font_size_override("font_size",18)
		var idx=i
		b.pressed.connect(func():
			selected_car=idx
			save_game()
			show_garage()
		)
		menu_root.add_child(b)

	var upgrades=[
		["engine","MOTOR",engine_upgrade,"mehr Beschleunigung & Vmax"],
		["brake","BREMSEN",brake_upgrade,"kürzerer Bremsweg"],
		["eco","ECO",eco_upgrade,"weniger Verbrauch"]
	]
	for i in range(upgrades.size()):
		var u=upgrades[i]
		var level=int(u[2])
		var b=Button.new()
		var price_text="MAX" if level>=5 else str(upgrade_cost(level))+" €"
		b.text=str(u[1])+"  Stufe "+str(level)+"/5  •  "+str(u[3])+"  •  "+price_text
		b.position=Vector2(300,300+i*58)
		b.size=Vector2(680,50)
		b.disabled=level>=5 or (level<5 and money<upgrade_cost(level))
		var kind=str(u[0])
		b.pressed.connect(func(): buy_upgrade(kind))
		menu_root.add_child(b)

	var cash=Label.new()
	cash.text="Werkstatt-Konto: "+str(money)+" €"
	cash.position=Vector2(535,486)
	cash.add_theme_font_size_override("font_size",18)
	menu_root.add_child(cash)
	menu_button("← ZURÜCK",Vector2(420,535),func(): show_main_menu())


func start_mission():
	game_state="driving"
	menu_root.visible=false
	game_root.visible=true
	mission_finished=false
	company_bonus_last=0
	speed=0.0
	fuel=100.0
	damage=0.0
	distance_left=routes[selected_route]["distance"]
	mission_start_money=money
	day_clock=0.20
	weather_timer=0.0
	weather_state="Regen" if randi()%4==0 else "Klar"
	fines_total=0
	speed_limit=130
	camera_cooldown=0.0
	event_timer=0.0
	event_text="Freie Fahrt"
	police_heat=0
	clean_mission_bonus=0
	streak_bonus=0
	discipline_bonus=0
	long_distance_bonus=0
	mission_xp_earned=0
	destination_bonus=0
	route_stage="AUTOBAHN"
	arrival_announced=false

	if settlement_panel!=null:
		settlement_panel.visible=false
	car.position=Vector3(0,0,0)

	rebuild_player()

	for t in traffic:
		if is_instance_valid(t):
			t.queue_free()
	traffic.clear()

	for i in range(10):
		spawn_traffic(-60.0-float(i)*50.0)

	update_hud()


func update_player(delta):
	var steer=0.0
	if left: steer-=1.0
	if right: steer+=1.0

	var max_speed=float(cars[selected_car]["max_speed"])*(1.0+0.035*engine_upgrade)
	var accel=float(cars[selected_car]["accel"])*(1.0+0.10*engine_upgrade)
	var brake_power=float(cars[selected_car]["brake"])*(1.0+0.12*brake_upgrade)
	var fuel_factor=float(cars[selected_car]["fuel_factor"])*(1.0-0.10*eco_upgrade)

	if gas and fuel>0:
		speed=min(speed+accel*delta,max_speed)
	else:
		speed=max(speed-5.0*delta,0.0)

	if brake:
		speed=max(speed-brake_power*delta,0.0)

	car.velocity=Vector3(steer*5.5,0,-speed)
	car.move_and_slide()
	car.position.x=clamp(car.position.x,-7.0,7.0)
	car.position.y=0.0

	if speed>0:
		fuel=max(0.0,fuel-speed*0.00035*fuel_factor*delta)



func wrap_road():
	# Die bestehende Straße reicht von z=0 bis etwa z=-3000.
	# Bevor wir ihr Ende erreichen, setzen wir Spieler + Verkehr
	# gemeinsam 1200 Meter nach vorne. Die Missionskilometer bleiben
	# davon unberührt und laufen normal weiter.
	if car.position.z < -1400.0:
		car.position.z += 1200.0

		for t in traffic:
			if is_instance_valid(t):
				t.position.z += 1200.0


func update_camera():
	if camera_mode==1:
		# Cockpit/Driver view: tief und nah an der Windschutzscheibe.
		cam.global_position=car.global_position+Vector3(0,1.58,-0.35)
		cam.look_at(car.global_position+Vector3(0,1.30,-28),Vector3.UP)
	else:
		cam.global_position=car.global_position+Vector3(0,3.9,7.8)
		cam.look_at(car.global_position+Vector3(0,0.8,-12),Vector3.UP)


func update_mission(delta):
	distance_left-=speed*3.6*delta/120.0

	# 8.0: echte Anfahrtsphase – Navi führt in den letzten Kilometern zur Ausfahrt.
	if distance_left<=12.0 and route_stage=="AUTOBAHN":
		route_stage="AUSFAHRT"
		event_text="NAVI: Zielausfahrt in 12 km • rechts einordnen"
		event_timer=7.0
	if distance_left<=4.0 and route_stage=="AUSFAHRT":
		route_stage="ZIEL"
		event_text="ZIELBEREICH • Übergabe voraus"
		event_timer=7.0
		if not arrival_announced:
			arrival_announced=true
			destination_bonus=35 if car.position.x>1.5 else 15

	if distance_left<=0:
		distance_left=0
		finish_mission()


func finish_mission():
	if mission_finished:
		return

	mission_finished=true
	game_state="settlement"
	speed=0.0
	gas=false
	brake=false
	left=false
	right=false

	var base_reward=int(routes[selected_route]["reward"])
	# 8.0 Zielankunft-Bonus: sauberes Einordnen in der Anfahrtsphase wird belohnt.
	base_reward+=destination_bonus
	var clean_bonus=100 if damage<10 else 0
	var fuel_bonus=50 if fuel>20 else 0
	var damage_penalty=int(round(damage*2.0))

	var reward=max(
		0,
		base_reward+clean_bonus+fuel_bonus-damage_penalty
	)

	var service_costs=max(
		0,
		mission_start_money-money-fines_total
	)

	clean_mission_bonus=50 if fines_total==0 and damage<10 else 0
	streak_bonus=0
	discipline_bonus=100 if fines_total==0 and damage<=5 else 0
	long_distance_bonus=75 if float(routes[selected_route]["distance"])>=400.0 else 0
	if fines_total==0 and damage<10:
		streak_bonus=min(safe_driving_streak*25,125)
	company_bonus_last=company_bonus_1202()
	var active_teams=min(company_staff,company_fleet)
	if active_teams>0:
		var driver_income=active_teams*(35+driver_level*20+company_office*10)
		var salary_cost=active_teams*driver_salary
		company_bonus_last+=max(0,driver_income-salary_cost)
		company_jobs+=active_teams
		dispatch_reputation+=active_teams
		var wear=active_teams*(1 if dispatch_mode==1 else (4 if dispatch_mode==2 else 2))
		fleet_condition=max(0,fleet_condition-wear)
		dispatch_streak+=1
		var empire_bonus=empire_contract_bonus_130()
		company_bonus_last+=empire_bonus
		logistics_rating+=active_teams*branch_count
		company_cash_total+=company_bonus_last
		if logistics_rating>=25:
			var elite_bonus=500+empire_level*150+branch_count*100
			company_bonus_last+=elite_bonus
			company_cash_total+=elite_bonus
			elite_contracts+=1
			logistics_rating-=25
		if dispatch_reputation>=10:
			company_bonus_last+=250+company_office*75
			company_contracts_won+=1
			dispatch_reputation-=10
	money+=reward+clean_mission_bonus+streak_bonus+discipline_bonus+long_distance_bonus+company_bonus_last
	run_company_jobs_122()
	jobs_completed+=1
	total_fines_paid+=fines_total
	mission_xp_earned=10
	if damage<10 and fines_total==0:
		safe_driving_streak+=1
		perfect_jobs+=1
		mission_xp_earned+=25
	else:
		safe_driving_streak=0
	if float(routes[selected_route]["distance"])>=400.0:
		mission_xp_earned+=10
	if str(routes[selected_route].get("class","STANDARD"))=="PREMIUM":
		mission_xp_earned+=15
	if str(routes[selected_route].get("class","STANDARD"))=="VIP":
		mission_xp_earned+=30
	career_xp+=mission_xp_earned
	career_level=1+int(jobs_completed/3)

	if damage<25:
		reputation+=3
	elif damage<60:
		reputation+=1
	else:
		reputation=max(0,reputation-1)

	save_game()

	show_settlement(
		base_reward,
		clean_bonus,
		fuel_bonus,
		damage_penalty,
		service_costs,
		reward
	)


func show_settlement(
	base_reward,
	clean_bonus,
	fuel_bonus,
	damage_penalty,
	service_costs,
	reward
):
	settlement_panel.visible=true

	settlement_title.text=(
		"AUFTRAG ABGESCHLOSSEN\n"
		+routes[selected_route]["name"]
	)

	var real_profit=reward+clean_mission_bonus+streak_bonus+discipline_bonus+long_distance_bonus+company_bonus_last+company_passive_last-service_costs-fines_total

	settlement_details.text=(
		"Grundvergütung:        "+str(base_reward)+" €\n"
		+"Sauberkeitsbonus:     +"+str(clean_bonus)+" €\n"
		+"Tankbonus:            +"+str(fuel_bonus)+" €\n"
		+"Sicherheitsprämie:    +"+str(clean_mission_bonus)+" €\n"
		+"Serienbonus:           +"+str(streak_bonus)+" €\n"
		+"Disziplinbonus:        +"+str(discipline_bonus)+" €\n"
		+"Langstreckenbonus:     +"+str(long_distance_bonus)+" €\n"
		+"Firmenbonus:           +"+str(company_bonus_last)+" €\n"		+"Firmenmanagement:      Fahrer L"+str(driver_level)+" • Flotte "+str(fleet_condition)+"%\n"		+"Imperium:              "+empire_rank_130()+" • "+str(branch_count)+" Standorte\n"
		+"Firmen-Autoaufträge:   +"+str(company_passive_last)+" €  ("+dispatch_mode_name_134()+")\n"
		+"Schaden-Abzug:        -"+str(damage_penalty)+" €\n"
		+"Tank/Werkstatt:       -"+str(service_costs)+" €\n"
		+"Bußgelder:             -"+str(fines_total)+" €\n"
		+"────────────────────────\n"
		+"Auszahlung:            "+str(reward)+" €\n"
		+"Netto-Ergebnis Fahrt:  "+str(real_profit)+" €\n"
		+"Kontostand:            "+str(money)+" €\n"
		+"Reputation:            "+str(reputation)+"\n"
		+"Karriere-Rang:         "+career_rank_name()+"\n"
		+"Auftragsklasse:        "+contract_class_name()+"\n"
		+"XP dieser Fahrt:       +"+str(mission_xp_earned)+"\n"
		+"Perfekte Fahrten:      "+str(perfect_jobs)+"\n"
		+"Tuning M/B/E:          "+str(engine_upgrade)+"/"+str(brake_upgrade)+"/"+str(eco_upgrade)+"
"+"Firmenstufe:           "+str(company_level())
	)


func settlement_next_job():
	settlement_panel.visible=false
	menu_root.visible=true
	game_root.visible=false
	game_state="menu"
	show_routes()


func settlement_home():
	settlement_panel.visible=false
	show_main_menu()


func spawn_traffic(z_pos):
	var t=Node3D.new()
	var lanes=[-5.5,0.0,5.5]

	t.position=Vector3(lanes[randi()%3],0,z_pos)
	t.set_meta("traffic_speed",randf_range(17.0,34.0))
	t.set_meta("lane_timer",randf_range(3.0,8.0))
	t.set_meta("target_x",t.position.x)

	add_child(t)

	var colors=[
		Color(0.75,0.08,0.08), Color(0.08,0.25,0.8), Color(0.85,0.85,0.85),
		Color(0.05,0.05,0.06), Color(0.9,0.55,0.08), Color(0.15,0.65,0.25),
		Color(0.45,0.12,0.55), Color(0.72,0.72,0.68)
	]
	var traffic_type=randi()%14
	if traffic_type<2:
		create_truck_model(t)
		t.set_meta("traffic_speed",randf_range(14.0,22.0))
	elif traffic_type<4:
		create_van_model_53(t,colors[randi()%colors.size()])
		t.set_meta("traffic_speed",randf_range(18.0,28.0))
	elif traffic_type<7:
		create_suv_model_53(t,colors[randi()%colors.size()])
	elif traffic_type==7:
		create_sport_model_100(t,colors[randi()%colors.size()])
	else:
		create_vehicle_model(t,colors[randi()%colors.size()])
	add_ai_lights_53(t)

	traffic.append(t)


func update_traffic(delta):
	traffic_timer+=delta

	var spawn_delay=max(1.30,2.45-float(company_level())*0.08)
	if traffic_timer>spawn_delay:
		traffic_timer=0
		var traffic_cap=min(28,17+company_level())
		if traffic.size()<traffic_cap:
			spawn_traffic(car.position.z-randf_range(200.0,285.0))

	var lanes=[-5.5,0.0,5.5]

	for t in traffic.duplicate():
		if not is_instance_valid(t):
			traffic.erase(t)
			continue

		var ai_speed=float(t.get_meta("traffic_speed",22.0))
		var lane_timer=float(t.get_meta("lane_timer",5.0))-delta
		var target_x=float(t.get_meta("target_x",t.position.x))

		# Abstand halten: erkennt ein Fahrzeug direkt voraus.
		for other in traffic:
			if other==t or not is_instance_valid(other):
				continue
			if abs(other.position.x-t.position.x)<1.8:
				var gap=t.position.z-other.position.z
				if gap>0.0 and gap<24.0:
					ai_speed=max(10.0,ai_speed-10.0)
					lane_timer=0.0
					break

		# Gelegentlicher Spurwechsel / Überholen.
		if lane_timer<=0.0:
			lane_timer=randf_range(6.0,11.0)
			if randi()%100<30:
				var lane_index=0
				var best_dist=999.0
				for i in range(lanes.size()):
					var d=abs(t.position.x-lanes[i])
					if d<best_dist:
						best_dist=d
						lane_index=i
				var direction=-1 if randi()%2==0 else 1
				var next_index=clamp(lane_index+direction,0,lanes.size()-1)
				var candidate_x=lanes[next_index]
				var lane_free=true
				for other in traffic:
					if other!=t and is_instance_valid(other) and abs(other.position.x-candidate_x)<1.6 and abs(other.position.z-t.position.z)<30.0:
						lane_free=false
						break
				if lane_free:
					target_x=candidate_x

		t.set_meta("lane_timer",lane_timer)
		t.set_meta("target_x",target_x)
		t.set_meta("traffic_speed",lerp(float(t.get_meta("traffic_speed",22.0)),ai_speed,delta*1.5))

		t.position.x=move_toward(t.position.x,target_x,1.35*delta)
		t.position.z-=float(t.get_meta("traffic_speed",22.0))*delta

		if t.position.z>car.position.z+110:
			traffic.erase(t)
			t.queue_free()
			continue

		check_collision(t)



func create_truck_model(parent):
	var trailer=MeshInstance3D.new()
	var trailer_mesh=BoxMesh.new()
	trailer_mesh.size=Vector3(2.5,2.3,6.2)
	trailer.mesh=trailer_mesh
	trailer.position=Vector3(0,1.55,0.8)
	trailer.material_override=material(Color(0.82,0.82,0.84))
	parent.add_child(trailer)

	var cabin=MeshInstance3D.new()
	var cabin_mesh=BoxMesh.new()
	cabin_mesh.size=Vector3(2.3,2.1,2.4)
	cabin.mesh=cabin_mesh
	cabin.position=Vector3(0,1.45,-3.4)
	cabin.material_override=material(Color(0.15,0.38,0.68))
	parent.add_child(cabin)

	var windshield=MeshInstance3D.new()
	var glass_mesh=BoxMesh.new()
	glass_mesh.size=Vector3(1.8,0.65,0.08)
	windshield.mesh=glass_mesh
	windshield.position=Vector3(0,1.85,-4.62)
	windshield.material_override=material(Color(0.22,0.62,0.82))
	parent.add_child(windshield)

	for wx in [-1.15,1.15]:
		for wz in [-2.9,1.8,3.0]:
			var wheel=MeshInstance3D.new()
			var wheel_mesh=CylinderMesh.new()
			wheel_mesh.top_radius=0.46
			wheel_mesh.bottom_radius=0.46
			wheel_mesh.height=0.34
			wheel.mesh=wheel_mesh
			wheel.position=Vector3(wx,0.45,wz)
			wheel.rotation_degrees=Vector3(0,0,90)
			wheel.material_override=material(Color(0.02,0.02,0.02))
			parent.add_child(wheel)

	light_box(parent,Vector3(-0.75,0.95,3.95),Color.RED)
	light_box(parent,Vector3(0.75,0.95,3.95),Color.RED)


func check_collision(t):
	var dx=abs(t.position.x-car.position.x)
	var dz=abs(t.position.z-car.position.z)

	if dx<1.8 and dz<3.5 and not t.get_meta("hit",false):
		t.set_meta("hit",true)
		damage=min(100.0,damage+randf_range(1.5,4.0))
		speed*=0.55

		if t.position.x<=car.position.x:
			t.position.x-=1.8
		else:
			t.position.x+=1.8


func update_world_30(delta):
	# Ein kompletter Tag/Nacht-Zyklus dauert ca. 150 Sekunden Spielzeit.
	day_clock=fmod(day_clock+delta/150.0,1.0)
	weather_timer+=delta

	if weather_timer>42.0:
		weather_timer=0.0
		weather_state="Regen" if weather_state=="Klar" else "Klar"

	var sun_factor=clamp(sin(day_clock*PI),0.08,1.0)
	var is_night=day_clock>0.78 or day_clock<0.10

	if world_env!=null:
		if is_night:
			world_env.background_color=Color(0.025,0.045,0.10)
			world_env.ambient_light_color=Color(0.24,0.32,0.52)
			world_env.ambient_light_energy=0.42
		else:
			var rain_dim=0.68 if weather_state=="Regen" else 1.0
			world_env.background_color=Color(0.42*rain_dim,0.72*rain_dim,0.95*rain_dim)
			world_env.ambient_light_color=Color.WHITE
			world_env.ambient_light_energy=0.82 if weather_state=="Regen" else 1.05

	if sun_light!=null:
		sun_light.rotation_degrees.x=-15.0-day_clock*165.0
		sun_light.light_energy=0.18 if is_night else 1.35*sun_factor

	for lamp in headlights:
		if is_instance_valid(lamp):
			lamp.visible=headlights_on and (is_night or weather_state=="Regen")
	# KI-Lichtkegel ebenfalls nur nachts / bei Regen aktivieren.
	for t in traffic:
		if is_instance_valid(t):
			var ai_lamp=t.get_node_or_null("AIHeadlight11")
			if ai_lamp!=null:
				ai_lamp.visible=is_night or weather_state=="Regen"

	# 5.3: Straßenlaternen schalten sich nachts und bei Regen sichtbar ein.
	for node in get_tree().get_nodes_in_group("road_lamps_53"):
		if is_instance_valid(node):
			node.light_energy=1.45 if is_night else (0.55 if weather_state=="Regen" else 0.0)

	if rain_root!=null:
		rain_root.visible=weather_state=="Regen"
		rain_root.global_position=car.global_position+Vector3(0,7,-8)
		if weather_state=="Regen":
			for drop in rain_root.get_children():
				drop.position.y-=18.0*delta
				drop.position.z+=4.0*delta
				if drop.position.y < -2.0:
					drop.position.y=randf_range(4.0,10.0)
					drop.position.x=randf_range(-12.0,12.0)
					drop.position.z=randf_range(-15.0,8.0)


func update_road_events_40(delta):
	camera_cooldown=max(0.0,camera_cooldown-delta)
	event_timer+=delta

	# 6.5: mehr dynamische Verkehrslagen und wetterabhängige Limits.
	if event_timer>16.0:
		event_timer=0.0
		var roll=randi()%7
		if weather_state=="Regen" and roll<=1:
			speed_limit=100
			event_text="NÄSSE • 100 km/h"
		elif roll==0:
			speed_limit=80
			event_text="BAUSTELLE • 80 km/h"
		elif roll==1:
			speed_limit=90
			event_text="STAUWARNUNG • 90 km/h"
		elif roll==2:
			speed_limit=100
			event_text="DICHTER VERKEHR • 100 km/h"
		elif roll==3:
			speed_limit=120
			event_text="TEMPOLIMIT • 120 km/h"
		else:
			speed_limit=130
			event_text="FREIE FAHRT • 130 km/h"

	var kmh=int(speed*3.6)
	if camera_cooldown<=0.0 and kmh>speed_limit+15 and randi()%1000<5:
		var over=kmh-speed_limit
		var fine=30+over*2
		fine=min(fine,180)
		money=max(0,money-fine)
		fines_total+=fine
		camera_cooldown=15.0
		event_text="⚡ GEBLITZT!  "+str(kmh)+" km/h • -"+str(fine)+" €"

	if kmh>speed_limit+45:
		police_heat=min(5,police_heat+1)
	elif kmh<=speed_limit+5:
		police_heat=max(0,police_heat-1)
	if police_heat>=4 and camera_cooldown<=0.0:
		event_text="🚓 POLIZEI-WARNUNG • Tempo reduzieren!"

	if event_label!=null:
		event_label.text=event_text
	if fine_label!=null:
		fine_label.text="LIMIT "+str(speed_limit)+"  •  Bußgeld "+str(fines_total)+" €"


func create_rain_system():
	rain_root=Node3D.new()
	add_child(rain_root)
	for i in range(42):
		var drop=MeshInstance3D.new()
		var mesh=BoxMesh.new()
		mesh.size=Vector3(0.025,0.7,0.025)
		drop.mesh=mesh
		drop.position=Vector3(randf_range(-12,12),randf_range(-2,10),randf_range(-15,8))
		drop.rotation_degrees.x=-12
		drop.material_override=material(Color(0.72,0.84,1.0))
		rain_root.add_child(drop)
	rain_root.visible=false


func add_player_headlights():
	headlights.clear()
	for x in [-0.62,0.62]:
		var light=SpotLight3D.new()
		light.position=Vector3(x,0.92,-2.05)
		# SpotLight3D strahlt entlang -Z: nur leicht auf die Fahrbahn neigen.
		light.rotation_degrees.x=-7.0
		light.spot_range=52.0
		light.spot_angle=34.0
		light.light_energy=6.0
		light.light_color=Color(1.0,0.93,0.74)
		light.shadow_enabled=false
		car.add_child(light)
		headlights.append(light)


func create_environment():
	var world=WorldEnvironment.new()
	var env=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color(0.42,0.72,0.95)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color.WHITE
	env.ambient_light_energy=1.05
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	world.environment=env
	world_env=env
	add_child(world)

	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-25,0)
	sun.light_energy=1.35
	sun.light_color=Color(1.0,0.94,0.84)
	sun.shadow_enabled=true
	sun_light=sun
	add_child(sun)


func create_ground():
	box(Vector3(120,0.5,3000),Vector3(0,-0.3,-1500),Color(0.18,0.62,0.20))


func create_road():
	box(Vector3(18,0.2,3000),Vector3(0,0,-1500),Color(0.105,0.11,0.125))
	box(Vector3(2.2,0.10,3000),Vector3(-10.0,-0.02,-1500),Color(0.38,0.39,0.40))
	box(Vector3(2.2,0.10,3000),Vector3(10.0,-0.02,-1500),Color(0.38,0.39,0.40))

	for x in [-3.0,3.0]:
		for z in range(0,3000,25):
			box(Vector3(0.18,0.05,8),Vector3(x,0.15,-z),Color.WHITE)

	box(Vector3(0.18,0.05,3000),Vector3(-8.0,0.15,-1500),Color.WHITE)
	box(Vector3(0.18,0.05,3000),Vector3(8.0,0.15,-1500),Color.WHITE)

	box(Vector3(0.18,0.35,3000),Vector3(-9.2,0.65,-1500),Color(0.75,0.77,0.80))
	box(Vector3(0.18,0.35,3000),Vector3(9.2,0.65,-1500),Color(0.75,0.77,0.80))

	for z in range(-25,-3000,-50):
		box(Vector3(0.10,0.08,0.30),Vector3(-8.0,0.22,z),Color(0.95,0.95,0.80))
		box(Vector3(0.10,0.08,0.30),Vector3(8.0,0.22,z-25),Color(0.95,0.95,0.80))


func create_scenery():
	for z in range(-40,-2900,-80):
		tree(Vector3(-15-randf_range(0,8),0,z))
		tree(Vector3(15+randf_range(0,8),0,z-35))

	# Autobahn-Schilder: kompakter, höher und abwechslungsreicher
	var motorway_signs=[
		"A8  Karlsruhe   Frankfurt",
		"A81  Heilbronn   Würzburg",
		"A6  Mannheim   Nürnberg",
		"A7  Würzburg   Hamburg",
		"A3  Frankfurt   Köln",
		"A5  Frankfurt   Kassel"
	]
	var sign_i=0
	for z in range(-300,-2900,-500):
		create_motorway_sign(Vector3(0,0,z), motorway_signs[sign_i % motorway_signs.size()])
		sign_i+=1
	for z in range(-120,-2900,-160):
		box(Vector3(0.12,1.4,0.12),Vector3(-9.7,0.7,z),Color(0.75,0.77,0.80))
		box(Vector3(0.12,1.4,0.12),Vector3(9.7,0.7,z-80),Color(0.75,0.77,0.80))


	# 1.5: zusätzliche Vegetation, Hügel und Straßenbeleuchtung
	for z in range(-180,-2900,-260):
		create_hill(Vector3(-34-randf_range(0,10),0,z), randf_range(8.0,15.0))
		create_hill(Vector3(34+randf_range(0,10),0,z-120), randf_range(8.0,15.0))
	for z in range(-220,-2900,-240):
		create_lamp(Vector3(-10.8,0,z))
		create_lamp(Vector3(10.8,0,z-120))

func create_hill(pos:Vector3, scale_value:float):
	var hill=MeshInstance3D.new()
	var mesh=SphereMesh.new()
	mesh.radius=1.0
	mesh.height=2.0
	hill.mesh=mesh
	hill.position=pos+Vector3(0,-2.0,0)
	hill.scale=Vector3(scale_value,scale_value*0.42,scale_value*1.25)
	hill.material_override=material(Color(0.12,0.42+randf_range(0,0.08),0.16))
	add_child(hill)

func create_lamp(pos:Vector3):
	var root=Node3D.new()
	root.position=pos
	add_child(root)
	station_box(root,Vector3(0.12,5.8,0.12),Vector3(0,2.9,0),Color(0.38,0.40,0.43))
	station_box(root,Vector3(1.0,0.10,0.10),Vector3(-0.42,5.72,0),Color(0.38,0.40,0.43))
	station_box(root,Vector3(0.42,0.12,0.28),Vector3(-0.88,5.65,0),Color(1.0,0.86,0.52))
	var glow=OmniLight3D.new()
	glow.position=Vector3(-0.88,5.35,0)
	glow.omni_range=11.0
	glow.light_energy=0.0
	glow.light_color=Color(1.0,0.82,0.55)
	glow.set_meta("road_lamp_53",true)
	root.add_child(glow)
	glow.add_to_group("road_lamps_53")



func create_road_features():
	# Überführungen
	create_overpass(-760.0)
	create_overpass(-2140.0)

	# Zwei erkennbare Autobahn-Ausfahrten
	create_exit_area(-1380.0, "Ausfahrt 12  Heilbronn")
	create_exit_area(-2580.0, "Ausfahrt 29  Frankfurt")
	create_exit_area(-1880.0, "Raststätte  1000 m")

	# Kleine Gebäudegruppen und Böschungen am Straßenrand
	for z in [-420.0,-980.0,-1660.0,-2380.0]:
		create_roadside_buildings(Vector3(-25,0,z))
	for z in [-620.0,-1840.0,-2720.0]:
		create_roadside_buildings(Vector3(25,0,z))


func create_overpass(z_pos):
	var root=Node3D.new()
	root.position=Vector3(0,0,z_pos)
	add_child(root)

	# Pfeiler außerhalb der Fahrbahn
	station_box(root,Vector3(1.0,7.0,1.0),Vector3(-10.5,3.5,0),Color(0.48,0.50,0.54))
	station_box(root,Vector3(1.0,7.0,1.0),Vector3(10.5,3.5,0),Color(0.48,0.50,0.54))
	# Brückendeck hoch genug für Fahrzeuge
	station_box(root,Vector3(30.0,0.75,5.0),Vector3(0,7.1,0),Color(0.30,0.31,0.34))
	station_box(root,Vector3(30.0,0.20,0.20),Vector3(0,7.75,-2.25),Color(0.72,0.74,0.77))
	station_box(root,Vector3(30.0,0.20,0.20),Vector3(0,7.75,2.25),Color(0.72,0.74,0.77))


func create_exit_area(z_pos,label_text):
	var root=Node3D.new()
	root.position=Vector3(0,0,z_pos)
	add_child(root)

	# Abzweigende Fahrbahn rechts – optische Ausfahrt
	rotated_box(root,Vector3(6.0,0.18,42.0),Vector3(10.0,0.04,-18.0),Color(0.16,0.16,0.18),-11.0)
	rotated_box(root,Vector3(0.16,0.06,38.0),Vector3(7.7,0.16,-18.0),Color.WHITE,-11.0)
	rotated_box(root,Vector3(0.16,0.06,38.0),Vector3(12.3,0.16,-18.0),Color.WHITE,-11.0)

	# kleines grünes Ausfahrtsschild am rechten Rand
	station_box(root,Vector3(0.18,2.8,0.18),Vector3(10.5,1.4,5.0),Color(0.75,0.77,0.80))
	station_box(root,Vector3(3.7,1.0,0.14),Vector3(10.5,3.0,5.0),Color(0.02,0.35,0.18))
	var label=Label3D.new()
	label.text=label_text
	label.font_size=18
	label.outline_size=3
	label.position=Vector3(10.5,3.0,4.9)
	label.rotation_degrees.y=0
	root.add_child(label)


func create_roadside_buildings(pos):
	var root=Node3D.new()
	root.position=pos
	add_child(root)

	for i in range(3):
		var x=float(i-1)*5.0
		var h=randf_range(2.5,4.5)
		station_box(root,Vector3(3.6,h,4.2),Vector3(x,h/2.0,0),Color(0.70+randf_range(0,0.12),0.62+randf_range(0,0.12),0.48+randf_range(0,0.12)))
		station_box(root,Vector3(4.0,0.45,4.6),Vector3(x,h+0.18,0),Color(0.38,0.12,0.08))
		# Fensterfront zur Autobahn
		station_box(root,Vector3(1.3,0.75,0.08),Vector3(x,h*0.60,-2.12),Color(0.12,0.30,0.42))


func create_extra_scenery_52():
	# 5.2: mehr Autobahnleben – Parkplätze, Baustellenoptik und Leitbaken.
	for z in [-340.0,-1260.0,-2260.0]:
		create_rest_area_52(z)
	for z in range(-180,-2900,-310):
		station_box(self,Vector3(0.18,0.9,0.18),Vector3(-9.8,0.45,z),Color(0.92,0.92,0.92))
		station_box(self,Vector3(0.18,0.9,0.18),Vector3(9.8,0.45,z-150),Color(0.92,0.92,0.92))

func create_rest_area_52(z_pos):
	var root=Node3D.new()
	root.position=Vector3(18,0,z_pos)
	add_child(root)
	station_box(root,Vector3(12,0.18,28),Vector3(0,0.05,0),Color(0.22,0.23,0.25))
	station_box(root,Vector3(7,3.2,5),Vector3(2,1.6,7),Color(0.72,0.68,0.58))
	var label=Label3D.new()
	label.text="AUTO BOSS  •  RASTPLATZ"
	label.font_size=22
	label.outline_size=4
	label.position=Vector3(0,3.8,-4)
	label.rotation_degrees.y=0
	root.add_child(label)



# AUTO BOSS 6.6 – WORLD UPGRADE
func create_world_upgrade_53():
	# Leitpfosten dichter gesetzt, damit Geschwindigkeit und Entfernung besser lesbar sind.
	for z in range(-45,-2950,-45):
		create_delineator_53(Vector3(-9.65,0,z),false)
		create_delineator_53(Vector3(9.65,0,z-22),true)

	# Markante Autobahnabschnitte statt einer komplett leeren Gerade.
	create_construction_zone_53(-1080.0)
	create_construction_zone_53(-2440.0)
	create_rest_stop_detail_53(-1540.0)
	create_rest_stop_detail_53(-2780.0)

	# Zusätzliche Wegweiser in Fahrtrichtung.
	create_motorway_sign(Vector3(0,0,-520),"A8  München  174 km")
	create_motorway_sign(Vector3(0,0,-2020),"A3  Frankfurt  •  Köln")


func create_delineator_53(pos:Vector3,right_side:bool):
	var root=Node3D.new()
	root.position=pos
	add_child(root)
	station_box(root,Vector3(0.16,0.95,0.12),Vector3(0,0.48,0),Color(0.94,0.94,0.92))
	var reflector_x=0.07 if right_side else -0.07
	station_box(root,Vector3(0.05,0.18,0.13),Vector3(reflector_x,0.68,-0.02),Color(0.06,0.06,0.06))


func create_construction_zone_53(z_pos:float):
	var root=Node3D.new()
	root.position=Vector3(0,0,z_pos)
	add_child(root)
	for i in range(9):
		var z=-float(i)*7.0
		station_box(root,Vector3(0.28,0.85,0.28),Vector3(7.35,0.43,z),Color(0.95,0.45,0.05))
		station_box(root,Vector3(0.36,0.18,0.30),Vector3(7.35,0.72,z),Color.WHITE)
	station_box(root,Vector3(7.0,2.8,5.0),Vector3(14.0,1.4,-25.0),Color(0.62,0.60,0.52))
	var sign=Label3D.new()
	sign.text="BAUSTELLE  •  80"
	sign.font_size=28
	sign.outline_size=5
	sign.position=Vector3(10.0,3.0,5.0)
	sign.rotation_degrees.y=180
	root.add_child(sign)


func create_rest_stop_detail_53(z_pos:float):
	var root=Node3D.new()
	root.position=Vector3(-21,0,z_pos)
	add_child(root)
	station_box(root,Vector3(15,0.16,32),Vector3(0,0.05,0),Color(0.20,0.21,0.23))
	station_box(root,Vector3(9,3.5,7),Vector3(-1,1.75,8),Color(0.72,0.70,0.64))
	station_box(root,Vector3(9.5,0.55,7.5),Vector3(-1,3.7,8),Color(0.24,0.26,0.28))
	for x in [-3.0,0.0,3.0]:
		station_box(root,Vector3(1.5,0.9,0.10),Vector3(x,2.0,4.45),Color(0.12,0.32,0.48))
	var label=Label3D.new()
	label.text="P  •  RASTPLATZ"
	label.font_size=30
	label.outline_size=5
	label.position=Vector3(0,4.7,-4)
	label.rotation_degrees.y=0
	root.add_child(label)


func create_van_model_53(parent,color_value):
	station_box(parent,Vector3(2.15,1.65,4.7),Vector3(0,1.05,0),color_value)
	station_box(parent,Vector3(1.75,0.62,0.08),Vector3(0,1.48,-2.37),Color(0.12,0.28,0.38))
	for x in [-0.92,0.92]:
		for z in [-1.45,1.45]:
			var wheel=MeshInstance3D.new()
			var wm=CylinderMesh.new()
			wm.top_radius=0.38; wm.bottom_radius=0.38; wm.height=0.28
			wheel.mesh=wm; wheel.position=Vector3(x,0.38,z); wheel.rotation_degrees.z=90
			wheel.material_override=material(Color(0.02,0.02,0.02)); parent.add_child(wheel)


func create_suv_model_53(parent,color_value):
	station_box(parent,Vector3(2.15,1.15,4.3),Vector3(0,0.88,0),color_value)
	station_box(parent,Vector3(1.85,0.72,2.25),Vector3(0,1.55,0.25),color_value.darkened(0.08))
	station_box(parent,Vector3(1.65,0.50,0.08),Vector3(0,1.58,-1.95),Color(0.10,0.25,0.36))
	for x in [-0.96,0.96]:
		for z in [-1.35,1.35]:
			var wheel=MeshInstance3D.new(); var wm=CylinderMesh.new()
			wm.top_radius=0.42; wm.bottom_radius=0.42; wm.height=0.30
			wheel.mesh=wm; wheel.position=Vector3(x,0.42,z); wheel.rotation_degrees.z=90
			wheel.material_override=material(Color(0.02,0.02,0.02)); parent.add_child(wheel)


func add_ai_lights_53(parent):
	# 11.0: emissive Rück-/Frontlichter plus ein günstiger gemeinsamer Lichtkegel pro KI-Auto.
	for x in [-0.68,0.68]:
		light_box(parent,Vector3(x,0.72,2.18),Color(0.95,0.03,0.02))
		light_box(parent,Vector3(x,0.72,-2.18),Color(1.0,0.88,0.62))
	var beam=SpotLight3D.new()
	beam.name="AIHeadlight11"
	beam.position=Vector3(0,0.82,-2.2)
	beam.rotation_degrees.x=-6.0
	beam.spot_range=22.0
	beam.spot_angle=42.0
	beam.light_energy=1.7
	beam.light_color=Color(1.0,0.91,0.70)
	beam.shadow_enabled=false
	parent.add_child(beam)

func rotated_box(parent,size_value,pos,color_value,y_rotation):
	var obj=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=size_value
	obj.mesh=mesh
	obj.position=pos
	obj.rotation_degrees.y=y_rotation
	obj.material_override=material(color_value)
	parent.add_child(obj)


func create_motorway_sign(pos:Vector3,text_value:String):
	var root=Node3D.new()
	root.position=pos
	add_child(root)
	# Portal bleibt über der Fahrbahn, Schild selbst ist deutlich kleiner.
	station_box(root,Vector3(0.16,7.6,0.16),Vector3(-7.4,3.8,0),Color(0.72,0.74,0.76))
	station_box(root,Vector3(0.16,7.6,0.16),Vector3(7.4,3.8,0),Color(0.72,0.74,0.76))
	station_box(root,Vector3(15.0,0.16,0.16),Vector3(0,7.55,0),Color(0.72,0.74,0.76))
	station_box(root,Vector3(8.2,1.25,0.12),Vector3(0,7.15,-0.12),Color(0.02,0.28,0.55))
	var label=Label3D.new()
	label.text=text_value+"\n↓          ↓"
	label.font_size=26
	label.outline_size=5
	label.position=Vector3(0,7.15,-0.20)
	label.rotation_degrees.y=0
	root.add_child(label)


func create_service_station_at(pos,station_name,fuel_price):
	var station=Node3D.new()
	station.position=pos
	add_child(station)

	station_box(station,Vector3(14.0,0.25,22.0),Vector3(0,0.12,0),Color(0.32,0.32,0.34))
	station_box(station,Vector3(9.0,0.55,6.0),Vector3(0,4.3,0),Color(0.92,0.12,0.08))

	for x in [-3.2,3.2]:
		station_box(station,Vector3(0.35,4.2,0.35),Vector3(x,2.1,0),Color(0.78,0.80,0.82))
		station_box(station,Vector3(1.3,1.9,1.1),Vector3(x,0.95,0),Color(0.10,0.30,0.72))

	var building=MeshInstance3D.new()
	var building_mesh=BoxMesh.new()
	building_mesh.size=Vector3(8.0,3.2,5.5)
	building.mesh=building_mesh
	building.position=Vector3(0,1.6,7.0)
	building.material_override=material(Color(0.82,0.82,0.78))
	station.add_child(building)

	var sign=Label3D.new()
	sign.text=station_name+"\\n"+str(fuel_price)+" €/L"
	sign.font_size=32
	sign.outline_size=6
	sign.position=Vector3(0,5.2,0)
	sign.rotation_degrees.y=0
	station.add_child(sign)


func create_service_station_legacy_unused():
	var station=Node3D.new()
	station.position=Vector3(16.0,0,-520.0)
	add_child(station)

	station_box(
		station,
		Vector3(14.0,0.25,22.0),
		Vector3(0,0.12,0),
		Color(0.32,0.32,0.34)
	)

	station_box(
		station,
		Vector3(9.0,0.55,6.0),
		Vector3(0,4.3,0),
		Color(0.92,0.12,0.08)
	)

	for x in [-3.2,3.2]:
		station_box(
			station,
			Vector3(0.35,4.2,0.35),
			Vector3(x,2.1,0),
			Color(0.78,0.80,0.82)
		)

		station_box(
			station,
			Vector3(1.3,1.9,1.1),
			Vector3(x,0.95,0),
			Color(0.10,0.30,0.72)
		)

	var building=MeshInstance3D.new()
	var building_mesh=BoxMesh.new()
	building_mesh.size=Vector3(8.0,3.2,5.5)
	building.mesh=building_mesh
	building.position=Vector3(0,1.6,7.0)
	building.material_override=material(Color(0.82,0.82,0.78))
	station.add_child(building)

	var sign=Label3D.new()
	sign.text="AUTO BOSS\\nSERVICE"
	sign.font_size=34
	sign.outline_size=6
	sign.position=Vector3(0,5.2,0)
	sign.rotation_degrees.y=0
	station.add_child(sign)


func station_box(parent,size_value,pos,color_value):
	var obj=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=size_value
	obj.mesh=mesh
	obj.position=pos
	obj.material_override=material(color_value)
	parent.add_child(obj)


func update_service():
	near_service=false
	current_service_name=""
	current_fuel_price=1.80

	var stations=[
		{"z":-520.0,"name":"SERVICE SÜD","price":1.79},
		{"z":-1120.0,"name":"SERVICE MITTE","price":1.89},
		{"z":-1720.0,"name":"SERVICE NORD","price":1.84}
	]

	for station in stations:
		if (
			car.position.z < station["z"] + 65.0
			and car.position.z > station["z"] - 65.0
			and car.position.x > 6.0
			and speed < 3.0
		):
			near_service=true
			current_service_name=station["name"]
			current_fuel_price=station["price"]
			break

	if near_service:
		service_label.text=current_service_name+"  •  "+str(current_fuel_price)+" €/L"
		refuel_button.visible=true
		repair_button.visible=true
	else:
		service_label.text=""
		refuel_button.visible=false
		repair_button.visible=false


func refuel_car():
	if not near_service:
		return

	if fuel >= 99.5:
		service_label.text="Tank ist bereits voll."
		return

	var missing=100.0-fuel
	var cost=max(10,int(ceil(missing*current_fuel_price)))

	if money < cost:
		service_label.text="Nicht genug Geld zum Tanken."
		return

	money-=cost
	fuel=100.0
	save_game()
	service_label.text="Vollgetankt: -"+str(cost)+" €"


func repair_car():
	if not near_service:
		return

	if damage <= 0.5:
		service_label.text="Kein Schaden vorhanden."
		return

	var cost=max(25,int(ceil(damage*2.5)))

	if money < cost:
		service_label.text="Nicht genug Geld für die Reparatur."
		return

	money-=cost
	damage=0.0
	save_game()
	service_label.text="Fahrzeug repariert: -"+str(cost)+" €"


func tree(pos):
	var root=Node3D.new()
	root.position=pos
	add_child(root)

	var trunk=MeshInstance3D.new()
	var tm=CylinderMesh.new()
	tm.top_radius=0.25
	tm.bottom_radius=0.35
	tm.height=2.5
	trunk.mesh=tm
	trunk.position.y=1.25
	trunk.material_override=material(Color(0.38,0.20,0.08))
	root.add_child(trunk)

	var crown=MeshInstance3D.new()
	var cm=SphereMesh.new()
	cm.radius=1.25
	cm.height=2.5
	crown.mesh=cm
	crown.position.y=3
	crown.material_override=material(Color(0.08,0.60,0.12))
	root.add_child(crown)


func create_player():
	car=CharacterBody3D.new()
	add_child(car)

	var collision=CollisionShape3D.new()
	var shape=BoxShape3D.new()
	shape.size=Vector3(2,1.4,4.2)
	collision.shape=shape
	collision.position.y=0.8
	car.add_child(collision)

	create_vehicle_model(car,cars[selected_car]["color"])
	add_player_headlights()

	cam=Camera3D.new()
	cam.current=true
	add_child(cam)


func rebuild_player():
	for child in car.get_children():
		if child is MeshInstance3D or child is SpotLight3D:
			child.queue_free()

	create_vehicle_model(car,cars[selected_car]["color"])
	add_player_headlights()


func create_vehicle_model(parent,color_value):
	# 15.0: komplett neu gezeichnetes, niedrigeres Fahrzeug mit klarer Silhouette.
	create_vehicle_model_180(parent,color_value)
	return

func create_vehicle_model_legacy(parent,color_value):
	var body=MeshInstance3D.new()
	var bm=BoxMesh.new()
	bm.size=Vector3(2.0,0.75,4.2)
	body.mesh=bm
	body.position=Vector3(0,0.75,0)
	body.material_override=material(color_value)
	parent.add_child(body)

	var cabin=MeshInstance3D.new()
	var cm=BoxMesh.new()
	cm.size=Vector3(1.65,0.7,2.0)
	cabin.mesh=cm
	cabin.position=Vector3(0,1.45,0.15)
	cabin.material_override=material(Color(0.12,0.22,0.30))
	parent.add_child(cabin)

	for wx in [-1.0,1.0]:
		for wz in [-1.3,1.3]:
			var wheel=MeshInstance3D.new()
			var wm=CylinderMesh.new()
			wm.top_radius=0.38
			wm.bottom_radius=0.38
			wm.height=0.28
			wheel.mesh=wm
			wheel.position=Vector3(wx,0.42,wz)
			wheel.rotation_degrees=Vector3(0,0,90)
			wheel.material_override=material(Color(0.025,0.025,0.025))
			parent.add_child(wheel)

	# 1.5: stärker geformte Karosserie statt reiner Kastenform
	station_box(parent,Vector3(1.88,0.28,1.25),Vector3(0,1.02,-1.55),color_value.lightened(0.06))
	station_box(parent,Vector3(1.88,0.22,0.85),Vector3(0,0.98,1.72),color_value.darkened(0.04))
	station_box(parent,Vector3(1.92,0.12,0.16),Vector3(0,0.50,2.12),Color(0.07,0.07,0.08))
	# Stoßfänger, Scheiben und Frontscheinwerfer für ein klareres Fahrzeugmodell
	station_box(parent,Vector3(1.85,0.16,0.16),Vector3(0,0.52,-2.12),Color(0.06,0.06,0.07))
	station_box(parent,Vector3(1.45,0.42,0.08),Vector3(0,1.48,-0.88),Color(0.10,0.24,0.34))
	# Seitenscheiben und Spiegel
	station_box(parent,Vector3(0.08,0.42,1.15),Vector3(-0.83,1.45,0.10),Color(0.10,0.24,0.34))
	station_box(parent,Vector3(0.08,0.42,1.15),Vector3(0.83,1.45,0.10),Color(0.10,0.24,0.34))
	station_box(parent,Vector3(0.18,0.16,0.34),Vector3(-1.08,1.25,-0.65),Color(0.05,0.05,0.06))
	station_box(parent,Vector3(0.18,0.16,0.34),Vector3(1.08,1.25,-0.65),Color(0.05,0.05,0.06))
	light_box(parent,Vector3(-0.62,0.82,-2.12),Color(1.0,0.92,0.62))
	light_box(parent,Vector3(0.62,0.82,-2.12),Color(1.0,0.92,0.62))
	light_box(parent,Vector3(-0.62,0.82,2.12),Color.RED)
	light_box(parent,Vector3(0.62,0.82,2.12),Color.RED)


func light_box(parent,pos,color_value):
	var obj=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=Vector3(0.42,0.25,0.08)
	obj.mesh=mesh
	obj.position=pos
	var lm=material(color_value)
	lm.emission_enabled=true
	lm.emission=color_value
	lm.emission_energy_multiplier=2.2
	obj.material_override=lm
	parent.add_child(obj)


func create_ui():
	ui_layer=CanvasLayer.new()
	add_child(ui_layer)

	menu_root=Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(menu_root)

	game_root=Control.new()
	game_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(game_root)

	var panel=ColorRect.new()
	panel.color=Color(0.03,0.08,0.14,0.90)
	panel.position=Vector2(10,10)
	panel.size=Vector2(1260,105)
	game_root.add_child(panel)

	speed_label=Label.new()
	speed_label.position=Vector2(25,20)
	speed_label.add_theme_font_size_override("font_size",24)
	game_root.add_child(speed_label)

	mission_label=Label.new()
	mission_label.position=Vector2(350,20)
	mission_label.add_theme_font_size_override("font_size",23)
	game_root.add_child(mission_label)

	info_label=Label.new()
	info_label.position=Vector2(350,62)
	info_label.add_theme_font_size_override("font_size",19)
	game_root.add_child(info_label)

	navigation_label=Label.new()
	navigation_label.position=Vector2(350,116)
	navigation_label.size=Vector2(650,42)
	navigation_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	navigation_label.add_theme_font_size_override("font_size",17)
	game_root.add_child(navigation_label)

	money_label=Label.new()
	money_label.position=Vector2(1100,20)
	money_label.add_theme_font_size_override("font_size",24)
	game_root.add_child(money_label)

	weather_label=Label.new()
	weather_label.position=Vector2(1040,65)
	weather_label.size=Vector2(210,35)
	weather_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	weather_label.add_theme_font_size_override("font_size",17)
	game_root.add_child(weather_label)

	event_label=Label.new()
	event_label.position=Vector2(800,92)
	event_label.size=Vector2(430,28)
	event_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	event_label.add_theme_font_size_override("font_size",15)
	game_root.add_child(event_label)

	fine_label=Label.new()
	fine_label.position=Vector2(25,92)
	fine_label.size=Vector2(300,25)
	fine_label.add_theme_font_size_override("font_size",14)
	game_root.add_child(fine_label)

	route_progress=ProgressBar.new()
	route_progress.position=Vector2(350,88)
	route_progress.size=Vector2(430,12)
	route_progress.show_percentage=false
	game_root.add_child(route_progress)

	service_label=Label.new()
	service_label.position=Vector2(785,91)
	service_label.size=Vector2(250,25)
	service_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	service_label.add_theme_font_size_override("font_size",14)
	game_root.add_child(service_label)

	refuel_button=Button.new()
	refuel_button.text="TANKEN"
	refuel_button.position=Vector2(1030,390)
	refuel_button.size=Vector2(150,64)
	refuel_button.visible=false
	refuel_button.pressed.connect(func(): refuel_car())
	game_root.add_child(refuel_button)

	repair_button=Button.new()
	repair_button.text="REPARIEREN"
	repair_button.position=Vector2(1030,462)
	repair_button.size=Vector2(150,64)
	repair_button.visible=false
	repair_button.pressed.connect(func(): repair_car())
	game_root.add_child(repair_button)

	pause_button=Button.new()
	pause_button.text="II"
	pause_button.position=Vector2(1185,130)
	pause_button.size=Vector2(70,55)
	pause_button.pressed.connect(func(): toggle_pause())
	game_root.add_child(pause_button)

	camera_button=Button.new()
	camera_button.text="KAMERA"
	camera_button.position=Vector2(1080,130)
	camera_button.size=Vector2(95,55)
	camera_button.pressed.connect(func(): toggle_camera_110())
	game_root.add_child(camera_button)

	light_button=Button.new()
	light_button.text="LICHT AUTO"
	light_button.position=Vector2(965,130)
	light_button.size=Vector2(105,55)
	light_button.pressed.connect(func(): toggle_lights_110())
	game_root.add_child(light_button)

	pause_panel=ColorRect.new()
	pause_panel.color=Color(0.02,0.04,0.08,0.94)
	pause_panel.position=Vector2(360,180)
	pause_panel.size=Vector2(560,360)
	pause_panel.visible=false
	game_root.add_child(pause_panel)

	var pause_title=Label.new()
	pause_title.text="PAUSE"
	pause_title.position=Vector2(225,30)
	pause_title.add_theme_font_size_override("font_size",32)
	pause_panel.add_child(pause_title)

	pause_resume_button=Button.new()
	pause_resume_button.text="WEITERFAHREN"
	pause_resume_button.position=Vector2(110,100)
	pause_resume_button.size=Vector2(340,55)
	pause_resume_button.pressed.connect(func(): toggle_pause())
	pause_panel.add_child(pause_resume_button)

	pause_save_button=Button.new()
	pause_save_button.text="SPIELSTAND SPEICHERN"
	pause_save_button.position=Vector2(110,175)
	pause_save_button.size=Vector2(340,55)
	pause_save_button.pressed.connect(func(): save_game())
	pause_panel.add_child(pause_save_button)

	pause_abort_button=Button.new()
	pause_abort_button.text="AUFTRAG ABBRECHEN"
	pause_abort_button.position=Vector2(110,250)
	pause_abort_button.size=Vector2(340,55)
	pause_abort_button.pressed.connect(func(): abort_mission())
	pause_panel.add_child(pause_abort_button)

	settlement_panel=ColorRect.new()
	settlement_panel.color=Color(0.02,0.04,0.08,0.96)
	settlement_panel.position=Vector2(270,24)
	settlement_panel.size=Vector2(740,672)
	settlement_panel.visible=false
	game_root.add_child(settlement_panel)

	settlement_title=Label.new()
	settlement_title.position=Vector2(35,16)
	settlement_title.size=Vector2(670,76)
	settlement_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	settlement_title.add_theme_font_size_override("font_size",27)
	settlement_panel.add_child(settlement_title)

	settlement_details=Label.new()
	settlement_details.position=Vector2(92,96)
	settlement_details.size=Vector2(560,470)
	settlement_details.add_theme_font_size_override("font_size",14)
	settlement_panel.add_child(settlement_details)

	settlement_next_button=Button.new()
	settlement_next_button.text="NÄCHSTER AUFTRAG"
	settlement_next_button.position=Vector2(75,596)
	settlement_next_button.size=Vector2(270,54)
	settlement_next_button.add_theme_font_size_override("font_size",19)
	settlement_next_button.pressed.connect(func(): settlement_next_job())
	settlement_panel.add_child(settlement_next_button)

	settlement_home_button=Button.new()
	settlement_home_button.text="HAUPTMENÜ"
	settlement_home_button.position=Vector2(395,596)
	settlement_home_button.size=Vector2(270,54)
	settlement_home_button.add_theme_font_size_override("font_size",19)
	settlement_home_button.pressed.connect(func(): settlement_home())
	settlement_panel.add_child(settlement_home_button)

	game_button("◀",Vector2(30,560),"left")
	game_button("▶",Vector2(150,560),"right")
	game_button("BREMSE",Vector2(1020,560),"brake")
	game_button("GAS",Vector2(1140,560),"gas")



func toggle_pause():
	if pause_panel.visible:
		pause_panel.visible=false
		get_tree().paused=false
	else:
		speed=0.0
		pause_panel.visible=true
		pause_panel.process_mode=Node.PROCESS_MODE_WHEN_PAUSED
		get_tree().paused=true


func abort_mission():
	get_tree().paused=false
	pause_panel.visible=false
	speed=0.0
	game_state="menu"
	show_main_menu()


func game_button(text_value,pos,kind):
	var b=Button.new()
	b.text=text_value
	b.position=pos
	b.size=Vector2(100,100)
	b.button_down.connect(func(): set_control(kind,true))
	b.button_up.connect(func(): set_control(kind,false))
	game_root.add_child(b)


func set_control(kind,pressed):
	if kind=="left": left=pressed
	elif kind=="right": right=pressed
	elif kind=="gas": gas=pressed
	elif kind=="brake": brake=pressed


func update_hud():
	speed_label.text="AUTO BOSS 17.0\n"+str(int(speed*3.6))+" km/h   ◉ "+str(speed_limit)
	mission_label.text="AUFTRAG: "+routes[selected_route]["name"]+"  ["+contract_class_name()+"]"
	info_label.text=str(int(distance_left))+" km   •   Tank "+str(int(fuel))+"%   •   Schaden "+str(int(damage))+"%"
	money_label.text=str(money)+" €"
	if navigation_label!=null:
		var dest=route_destination_80()
		if distance_left>60.0:
			navigation_label.text="NAVI  ➜  "+dest+"  •  Autobahn folgen"
		elif distance_left>12.0:
			navigation_label.text="NAVI  ➜  "+dest+"  •  Ausfahrt in "+str(int(distance_left-8.0))+" km"
		elif distance_left>4.0:
			navigation_label.text="NAVI  ↗  RECHTS EINORDNEN  •  "+dest
		else:
			navigation_label.text="NAVI  ★  ZIELBEREICH "+dest+"  •  Übergabe"
	if weather_label!=null:
		var phase="NACHT" if day_clock>0.78 or day_clock<0.10 else "TAG"
		weather_label.text=phase+"  •  "+weather_state
	if route_progress!=null:
		var total=float(routes[selected_route]["distance"])
		route_progress.value=clamp((1.0-distance_left/total)*100.0,0.0,100.0)



func toggle_camera_110():
	camera_mode=1-camera_mode
	if camera_button!=null:
		camera_button.text="COCKPIT" if camera_mode==1 else "KAMERA"

func toggle_lights_110():
	headlights_on=not headlights_on
	if light_button!=null:
		light_button.text="LICHT AN" if headlights_on else "LICHT AUS"

func create_visual_upgrade_110():
	# 11.0: zusätzliche Leitpfosten/Reflektoren und Schilder für bessere Nachtorientierung.
	for z in range(-40,-2960,-80):
		for side in [-1.0,1.0]:
			station_box(self,Vector3(0.16,0.72,0.16),Vector3(side*8.65,0.46,z),Color(0.88,0.88,0.84))
			light_box(self,Vector3(side*8.58,0.70,z-0.10),Color(1.0,0.80,0.30))
	create_motorway_sign(Vector3(0,0,-1680),"A8  Karlsruhe   München")
	create_motorway_sign(Vector3(0,0,-2680),"Ausfahrt  1000 m")


func route_destination_80():
	var route_name=str(routes[selected_route]["name"])
	var parts=route_name.split("→")
	return parts[parts.size()-1].strip_edges()


func create_city_gate_80(z_pos):
	# 8.0 Zielregion: sichtbare Skyline und Logistik-/Übergabezone neben der Autobahn.
	var root=Node3D.new()
	root.position=Vector3(0,0,z_pos)
	add_child(root)
	for i in range(9):
		var side=-1.0 if i%2==0 else 1.0
		var x=side*(18.0+float(i%4)*5.0)
		var h=5.0+float((i*3)%9)
		station_box(root,Vector3(5.0,h,6.0),Vector3(x,h/2.0,-float(i)*9.0),Color(0.28,0.32,0.38))
	# markantes Zielportal
	station_box(root,Vector3(0.22,5.5,0.22),Vector3(9.5,2.75,-48),Color(0.75,0.77,0.80))
	station_box(root,Vector3(7.5,1.4,0.16),Vector3(12.5,5.0,-48),Color(0.02,0.38,0.20))
	var label=Label3D.new()
	label.text="AUTO BOSS • ZIEL / ÜBERGABE"
	label.font_size=24
	label.outline_size=4
	label.position=Vector3(12.5,5.0,-48.1)
	root.add_child(label)


func box(size_value,pos,color_value):
	var obj=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=size_value
	obj.mesh=mesh
	obj.position=pos
	obj.material_override=material(color_value)
	add_child(obj)


func material(color_value):
	var m=StandardMaterial3D.new()
	m.albedo_color=color_value
	return m


# AUTO BOSS 10.0 – Grafik-, Autobahn- und Traffic-Upgrade
func create_visual_upgrade_100():
	# Mittelstreifen-Reflektoren und Asphaltflicken geben der Straße mehr Tiefe.
	for z in range(-30,-2980,-55):
		station_box(self,Vector3(0.16,0.08,0.42),Vector3(-3.0,0.19,z),Color(0.92,0.92,0.72))
		station_box(self,Vector3(0.16,0.08,0.42),Vector3(3.0,0.19,z-24),Color(0.92,0.92,0.72))
	for z in range(-160,-2900,-310):
		station_box(self,Vector3(3.2,0.018,8.0),Vector3(-2.0,0.12,z),Color(0.085,0.09,0.10))
	# Lärmschutzwände in einigen Abschnitten.
	for z0 in [-520.0,-1560.0,-2460.0]:
		create_noise_barrier_100(z0,1.0)
	# Zusätzliche Brücken und moderne Schilder sorgen für erkennbare Streckenabschnitte.
	create_overpass(-1180.0)
	create_overpass(-2820.0)
	create_motorway_sign(Vector3(0,0,-1050),"A81  Heilbronn   Frankfurt")
	create_motorway_sign(Vector3(0,0,-2310),"A5  Frankfurt   Köln")

func create_noise_barrier_100(z_start:float, side:float):
	var root=Node3D.new()
	root.position=Vector3(0,0,z_start)
	add_child(root)
	for i in range(7):
		var z=-float(i)*14.0
		station_box(root,Vector3(0.20,3.4,13.2),Vector3(side*11.0,1.7,z),Color(0.30,0.48,0.55))
		station_box(root,Vector3(0.12,3.8,0.12),Vector3(side*10.9,1.9,z-6.5),Color(0.65,0.68,0.70))

func create_sport_model_100(parent,color_value):
	# Flacheres KI-Sportcoupé als zusätzliche Fahrzeugklasse.
	station_box(parent,Vector3(2.05,0.58,4.35),Vector3(0,0.68,0),color_value)
	station_box(parent,Vector3(1.62,0.55,1.75),Vector3(0,1.22,0.10),Color(0.08,0.18,0.27))
	station_box(parent,Vector3(1.92,0.18,0.72),Vector3(0,0.92,-1.82),color_value.lightened(0.08))
	station_box(parent,Vector3(1.82,0.12,0.18),Vector3(0,0.52,2.20),Color(0.04,0.04,0.05))
	for wx in [-1.02,1.02]:
		for wz in [-1.35,1.35]:
			var wheel=MeshInstance3D.new()
			var wm=CylinderMesh.new()
			wm.top_radius=0.40
			wm.bottom_radius=0.40
			wm.height=0.30
			wheel.mesh=wm
			wheel.position=Vector3(wx,0.38,wz)
			wheel.rotation_degrees=Vector3(0,0,90)
			wheel.material_override=material(Color(0.015,0.015,0.018))
			parent.add_child(wheel)
	light_box(parent,Vector3(-0.66,0.72,-2.18),Color(1.0,0.94,0.72))
	light_box(parent,Vector3(0.66,0.72,-2.18),Color(1.0,0.94,0.72))
	light_box(parent,Vector3(-0.70,0.70,2.18),Color.RED)
	light_box(parent,Vector3(0.70,0.70,2.18),Color.RED)


# AUTO BOSS 15.0 – ROAD & GRAPHICS OVERHAUL
func create_vehicle_model_150(parent,color_value):
	# Unterbau / Schweller
	station_box(parent,Vector3(2.04,0.18,3.75),Vector3(0,0.48,0.10),Color(0.025,0.03,0.04))
	# Hauptkarosserie in mehreren Ebenen – deutlich weniger Kastenoptik.
	station_box(parent,Vector3(1.96,0.48,3.72),Vector3(0,0.72,0.02),color_value.darkened(0.05))
	station_box(parent,Vector3(1.88,0.32,3.95),Vector3(0,0.92,-0.03),color_value)
	rotated_box(parent,Vector3(1.82,0.30,1.30),Vector3(0,1.10,-1.45),color_value.lightened(0.04),0.0)
	# Dach und Glas – kompakte Fastback-Silhouette.
	station_box(parent,Vector3(1.58,0.16,1.92),Vector3(0,1.62,0.15),color_value.darkened(0.10))
	rotated_box(parent,Vector3(1.55,0.72,0.08),Vector3(0,1.39,-0.76),Color(0.055,0.11,0.16),0.0)
	rotated_box(parent,Vector3(1.55,0.58,0.08),Vector3(0,1.36,0.94),Color(0.055,0.10,0.14),0.0)
	station_box(parent,Vector3(0.07,0.54,1.45),Vector3(-0.82,1.34,0.12),Color(0.055,0.11,0.16))
	station_box(parent,Vector3(0.07,0.54,1.45),Vector3(0.82,1.34,0.12),Color(0.055,0.11,0.16))
	# Stoßfänger, Grill, Kennzeichen und Leuchten.
	station_box(parent,Vector3(1.86,0.17,0.14),Vector3(0,0.54,-2.03),Color(0.035,0.04,0.05))
	station_box(parent,Vector3(0.90,0.22,0.05),Vector3(0,0.70,-2.11),Color(0.02,0.025,0.03))
	station_box(parent,Vector3(0.48,0.15,0.04),Vector3(0,0.53,-2.12),Color(0.88,0.88,0.82))
	station_box(parent,Vector3(1.90,0.15,0.14),Vector3(0,0.55,2.03),Color(0.035,0.04,0.05))
	light_box(parent,Vector3(-0.62,0.88,-2.08),Color(0.92,0.97,1.0))
	light_box(parent,Vector3(0.62,0.88,-2.08),Color(0.92,0.97,1.0))
	light_box(parent,Vector3(-0.64,0.82,2.08),Color(1.0,0.04,0.025))
	light_box(parent,Vector3(0.64,0.82,2.08),Color(1.0,0.04,0.025))
	# Räder + silberne Felgen.
	for wx in [-1.0,1.0]:
		for wz in [-1.28,1.28]:
			var wheel=MeshInstance3D.new()
			var wm=CylinderMesh.new()
			wm.top_radius=0.39
			wm.bottom_radius=0.39
			wm.height=0.30
			wheel.mesh=wm
			wheel.position=Vector3(wx,0.47,wz)
			wheel.rotation_degrees=Vector3(0,0,90)
			wheel.material_override=material(Color(0.018,0.02,0.024))
			parent.add_child(wheel)
			var rim=MeshInstance3D.new()
			var rm=CylinderMesh.new()
			rm.top_radius=0.22
			rm.bottom_radius=0.22
			rm.height=0.315
			rim.mesh=rm
			rim.position=Vector3(wx,0.47,wz)
			rim.rotation_degrees=Vector3(0,0,90)
			rim.material_override=material(Color(0.55,0.58,0.62))
			parent.add_child(rim)
	# Spiegel + Heckspoilerkante.
	station_box(parent,Vector3(0.20,0.12,0.32),Vector3(-1.03,1.28,-0.62),Color(0.035,0.04,0.05))
	station_box(parent,Vector3(0.20,0.12,0.32),Vector3(1.03,1.28,-0.62),Color(0.035,0.04,0.05))
	station_box(parent,Vector3(1.48,0.08,0.25),Vector3(0,1.08,1.94),color_value.darkened(0.12))

func create_road_graphics_150():
	# 15.0: Asphalt-Schultern, Mittellinien, Rumble-Strips und Reflektoren.
	station_box(self,Vector3(1.15,0.035,2990),Vector3(-8.62,0.125,-1495),Color(0.15,0.16,0.17))
	station_box(self,Vector3(1.15,0.035,2990),Vector3(8.62,0.125,-1495),Color(0.15,0.16,0.17))
	for z in range(-20,-2980,-18):
		station_box(self,Vector3(0.13,0.045,5.6),Vector3(-3.0,0.19,z),Color(0.94,0.94,0.91))
		station_box(self,Vector3(0.13,0.045,5.6),Vector3(3.0,0.19,z-9),Color(0.94,0.94,0.91))
	for z in range(-35,-2980,-34):
		station_box(self,Vector3(0.26,0.10,0.55),Vector3(-7.72,0.23,z),Color(1.0,0.82,0.34))
		station_box(self,Vector3(0.26,0.10,0.55),Vector3(7.72,0.23,z-17),Color(1.0,0.82,0.34))
	# Baumgruppen statt einzelner Spielzeugbäume.
	for z in range(-90,-2880,-150):
		create_tree_cluster_150(Vector3(-20-randf_range(0,9),0,z))
		create_tree_cluster_150(Vector3(20+randf_range(0,9),0,z-70))
	# Fernkulisse erzeugt Tiefe am Horizont.
	for z in range(-420,-2900,-420):
		create_hill(Vector3(-48,0,z),randf_range(16.0,24.0))
		create_hill(Vector3(50,0,z-180),randf_range(18.0,28.0))

# AUTO BOSS 16.0 – VISUAL REVOLUTION
func create_visual_revolution_160():
	# Rhythmus am Straßenrand: Leitpfosten, Lichtmasten und blaue Autobahn-Portale.
	for z in range(-70,-2940,-95):
		station_box(self,Vector3(0.12,0.95,0.12),Vector3(-9.55,0.58,z),Color(0.80,0.82,0.84))
		station_box(self,Vector3(0.12,0.95,0.12),Vector3(9.55,0.58,z-42),Color(0.80,0.82,0.84))
		station_box(self,Vector3(0.16,0.16,0.10),Vector3(-9.54,0.88,z),Color(0.08,0.08,0.09))
		station_box(self,Vector3(0.16,0.16,0.10),Vector3(9.54,0.88,z-42),Color(0.08,0.08,0.09))
	for z in [-360.0,-860.0,-1380.0,-1900.0,-2440.0]:
		station_box(self,Vector3(0.16,6.2,0.16),Vector3(-9.0,3.2,z),Color(0.36,0.39,0.43))
		station_box(self,Vector3(0.16,6.2,0.16),Vector3(9.0,3.2,z),Color(0.36,0.39,0.43))
		station_box(self,Vector3(18.1,0.16,0.16),Vector3(0,6.2,z),Color(0.42,0.45,0.49))
		station_box(self,Vector3(5.2,1.05,0.18),Vector3(0,5.55,z-0.12),Color(0.02,0.23,0.52))
	# Dunklere Asphalt-Inlays erzeugen Geschwindigkeit und brechen die flache Fläche.
	for z in range(-120,-2880,-260):
		station_box(self,Vector3(13.8,0.012,18.0),Vector3(0,0.145,z),Color(0.105,0.11,0.12))

func create_tree_cluster_150(pos:Vector3):
	for i in range(5):
		var p=pos+Vector3(randf_range(-5.0,5.0),0,randf_range(-9.0,9.0))
		var root=Node3D.new()
		root.position=p
		add_child(root)
		var trunk=MeshInstance3D.new()
		var tm=CylinderMesh.new()
		tm.top_radius=0.18
		tm.bottom_radius=0.30
		tm.height=2.8
		trunk.mesh=tm
		trunk.position.y=1.4
		trunk.material_override=material(Color(0.25,0.13,0.055))
		root.add_child(trunk)
		for j in range(3):
			var crown=MeshInstance3D.new()
			var cm=SphereMesh.new()
			cm.radius=1.0
			cm.height=2.0
			crown.mesh=cm
			crown.scale=Vector3(1.15+0.18*j,0.82,1.05+0.12*j)
			crown.position=Vector3(randf_range(-0.35,0.35),2.7+0.55*j,randf_range(-0.25,0.25))
			crown.material_override=material(Color(0.045+0.018*j,0.30+randf_range(0.0,0.10),0.07))
			root.add_child(crown)


# AUTO BOSS 17.0 – GRAPHICS OVERHAUL
# Rein visueller Layer: Gameplay, Karriere und Savegame bleiben unverändert.
func create_graphics_overhaul_170():
	# Moderner Himmel mit echter Himmelskuppel statt flacher Hintergrundfarbe.
	if world_env != null:
		var sky=Sky.new()
		var sky_mat=ProceduralSkyMaterial.new()
		sky_mat.sky_top_color=Color(0.055,0.20,0.40)
		sky_mat.sky_horizon_color=Color(0.52,0.76,0.94)
		sky_mat.ground_bottom_color=Color(0.08,0.11,0.13)
		sky_mat.ground_horizon_color=Color(0.42,0.55,0.52)
		sky_mat.sun_angle_max=18.0
		sky_mat.sun_curve=0.08
		sky.sky_material=sky_mat
		world_env.sky=sky
		world_env.background_mode=Environment.BG_SKY
		world_env.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
		world_env.ambient_light_energy=0.82
		world_env.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
		world_env.fog_enabled=true
		world_env.fog_light_color=Color(0.63,0.76,0.84)
		world_env.fog_density=0.0017
		world_env.fog_sky_affect=0.34

	# Asphalt: feine Reparaturstreifen, Fugen und optische Fahrspuren.
	for z in range(-80,-2960,-105):
		var shade=Color(0.075,0.080,0.087) if (abs(z/105)%2)==0 else Color(0.12,0.125,0.13)
		station_box(self,Vector3(5.15,0.010,0.13),Vector3(-3.1,0.205,z),shade)
		station_box(self,Vector3(4.75,0.010,0.11),Vector3(3.0,0.205,z-34),shade)
	for z in range(-45,-2980,-42):
		station_box(self,Vector3(0.045,0.012,9.0),Vector3(-5.4,0.208,z),Color(0.075,0.078,0.082))
		station_box(self,Vector3(0.045,0.012,8.0),Vector3(5.2,0.208,z-19),Color(0.075,0.078,0.082))

	# Deutsche Leitpfosten – dichter Rhythmus, schwarze Reflektorflächen.
	for z in range(-35,-2980,-55):
		create_delineator_170(Vector3(-9.72,0,z),false)
		create_delineator_170(Vector3(9.72,0,z-27),true)

	# Lärmschutzwände / Leitplanken sorgen für deutlich mehr Autobahn-Charakter.
	for z in [-610.0,-650.0,-690.0,-730.0,-1510.0,-1550.0,-1590.0,-1630.0]:
		create_noise_barrier_170(Vector3(11.4,0,z))
	for z in [-1030.0,-1070.0,-1110.0,-2290.0,-2330.0,-2370.0]:
		create_noise_barrier_170(Vector3(-11.4,0,z))

	# Fernwald und kleine Baumreihen füllen die bisher leeren grünen Flächen.
	for z in range(-140,-2900,-230):
		create_forest_strip_170(Vector3(-31-randf_range(0,8),0,z))
		create_forest_strip_170(Vector3(31+randf_range(0,8),0,z-100))

	# Wiedererkennbare Autobahn-Szenen: Baustelle, Windräder und Logistikpark.
	create_construction_zone_170(-1180.0)
	create_wind_turbine_170(Vector3(-43,0,-820))
	create_wind_turbine_170(Vector3(-51,0,-930))
	create_wind_turbine_170(Vector3(47,0,-2020))
	create_logistics_park_170(Vector3(31,0,-2460))

func create_delineator_170(pos:Vector3,right_side:bool):
	var root=Node3D.new(); root.position=pos; add_child(root)
	station_box(root,Vector3(0.20,1.10,0.16),Vector3(0,0.55,0),Color(0.93,0.94,0.92))
	station_box(root,Vector3(0.23,0.27,0.18),Vector3(0,0.79,-0.01),Color(0.035,0.04,0.045))
	var rx=0.055 if right_side else -0.055
	station_box(root,Vector3(0.07,0.09,0.19),Vector3(rx,0.81,-0.02),Color(0.96,0.96,0.90))

func create_noise_barrier_170(pos:Vector3):
	var root=Node3D.new(); root.position=pos; add_child(root)
	station_box(root,Vector3(0.14,3.0,39.0),Vector3(0,1.55,0),Color(0.30,0.49,0.56))
	station_box(root,Vector3(0.17,0.10,39.2),Vector3(0,3.05,0),Color(0.68,0.73,0.75))
	for zz in [-18.0,-9.0,0.0,9.0,18.0]:
		station_box(root,Vector3(0.22,3.25,0.16),Vector3(0,1.62,zz),Color(0.55,0.59,0.61))

func create_forest_strip_170(pos:Vector3):
	for i in range(7):
		var root=Node3D.new()
		root.position=pos+Vector3(randf_range(-10,10),0,randf_range(-18,18))
		add_child(root)
		var trunk=MeshInstance3D.new(); var tm=CylinderMesh.new(); tm.top_radius=0.16; tm.bottom_radius=0.25; tm.height=3.4; trunk.mesh=tm; trunk.position.y=1.7; trunk.material_override=material(Color(0.19,0.095,0.035)); root.add_child(trunk)
		var crown=MeshInstance3D.new(); var cm=SphereMesh.new(); cm.radius=1.0; cm.height=2.0; crown.mesh=cm; crown.scale=Vector3(randf_range(1.3,1.9),randf_range(1.6,2.2),randf_range(1.3,1.9)); crown.position.y=4.0; crown.material_override=material(Color(randf_range(0.035,0.075),randf_range(0.20,0.34),randf_range(0.045,0.085))); root.add_child(crown)

func create_construction_zone_170(z_pos:float):
	var root=Node3D.new(); root.position=Vector3(0,0,z_pos); add_child(root)
	for zz in range(-70,71,10):
		station_box(root,Vector3(0.32,0.75,0.32),Vector3(7.25,0.38,float(zz)),Color(1.0,0.48,0.03))
		station_box(root,Vector3(0.36,0.14,0.36),Vector3(7.25,0.78,float(zz)),Color(0.95,0.95,0.90))
	station_box(root,Vector3(4.8,0.08,135),Vector3(9.9,0.19,0),Color(0.16,0.17,0.18))
	var sign=Label3D.new(); sign.text="BAUSTELLE  •  80"; sign.font_size=42; sign.outline_size=7; sign.position=Vector3(8.4,3.2,58); root.add_child(sign)

func create_wind_turbine_170(pos:Vector3):
	var root=Node3D.new(); root.position=pos; add_child(root)
	var mast=MeshInstance3D.new(); var mm=CylinderMesh.new(); mm.top_radius=0.22; mm.bottom_radius=0.48; mm.height=14.0; mast.mesh=mm; mast.position.y=7.0; mast.material_override=material(Color(0.78,0.81,0.82)); root.add_child(mast)
	station_box(root,Vector3(1.3,0.65,0.65),Vector3(0,14.1,0),Color(0.82,0.84,0.84))
	for angle in [0.0,120.0,240.0]:
		var blade=MeshInstance3D.new(); var bm=BoxMesh.new(); bm.size=Vector3(0.18,6.0,0.12); blade.mesh=bm; blade.position=Vector3(0,14.1,0); blade.rotation_degrees.z=angle; blade.material_override=material(Color(0.88,0.89,0.88)); root.add_child(blade)

func create_logistics_park_170(pos:Vector3):
	var root=Node3D.new(); root.position=pos; add_child(root)
	station_box(root,Vector3(22,5.5,18),Vector3(0,2.75,0),Color(0.64,0.68,0.70))
	station_box(root,Vector3(22.4,0.30,18.4),Vector3(0,5.62,0),Color(0.16,0.19,0.22))
	for x in [-7.5,-2.5,2.5,7.5]:
		station_box(root,Vector3(3.3,2.5,0.16),Vector3(x,1.55,-9.08),Color(0.10,0.16,0.20))
	var label=Label3D.new(); label.text="AUTO BOSS LOGISTICS"; label.font_size=32; label.outline_size=5; label.position=Vector3(0,4.3,-9.18); root.add_child(label)


# AUTO BOSS 18.0 – CAR & WORLD REVOLUTION
# Visueller Layer über 17.0. Karriere, Physik und Savegame bleiben kompatibel.
func create_world_revolution_180():
	# Etwas erwachseneres Licht: weniger Neon-Grün, mehr natürliche Fernwirkung.
	if world_env != null:
		world_env.ambient_light_energy=0.72
		world_env.fog_density=0.00115
		world_env.fog_light_color=Color(0.68,0.76,0.80)
	if sun_light != null:
		sun_light.light_energy=1.18
		sun_light.light_color=Color(1.0,0.96,0.89)

	# Mittelstreifen/Schulter optisch aufwerten: Drainage, Fugen, Katzenaugen.
	for z in range(-30,-2980,-30):
		station_box(self,Vector3(0.12,0.035,0.42),Vector3(-7.82,0.235,z),Color(0.93,0.80,0.35))
		station_box(self,Vector3(0.12,0.035,0.42),Vector3(7.82,0.235,z-15),Color(0.93,0.80,0.35))
	for z in range(-110,-2920,-220):
		station_box(self,Vector3(14.6,0.008,0.055),Vector3(0,0.218,z),Color(0.035,0.038,0.043))

	# Große deutsche Schilderbrücken mit mehreren Tafeln statt leerer Balken.
	create_sign_gantry_180(-520.0,"A 81  HEILBRONN","A 6  MANNHEIM")
	create_sign_gantry_180(-1450.0,"A 5  FRANKFURT","A 3  KÖLN")
	create_sign_gantry_180(-2350.0,"FRANKFURT  38 km","KASSEL  182 km")

	# Landschafts-Landmarks: Felder, Solaranlage, Rastplatz und Industrie.
	create_field_180(Vector3(-34,0,-430),Color(0.42,0.48,0.12))
	create_field_180(Vector3(36,0,-1780),Color(0.52,0.43,0.13))
	create_solar_farm_180(Vector3(-34,0,-1880))
	create_rest_area_180(Vector3(25,0,-760))
	create_industry_180(Vector3(-34,0,-2650))

func create_sign_gantry_180(z_pos:float,left_text:String,right_text:String):
	var root=Node3D.new(); root.position=Vector3(0,0,z_pos); add_child(root)
	for x in [-8.7,8.7]:
		station_box(root,Vector3(0.22,6.0,0.22),Vector3(x,3.0,0),Color(0.46,0.49,0.51))
	station_box(root,Vector3(17.6,0.22,0.22),Vector3(0,5.95,0),Color(0.52,0.55,0.57))
	for data in [[-4.15,left_text],[4.15,right_text]]:
		station_box(root,Vector3(7.5,1.75,0.16),Vector3(float(data[0]),5.0,-0.15),Color(0.015,0.22,0.48))
		var lab=Label3D.new(); lab.text=str(data[1]); lab.font_size=28; lab.outline_size=5; lab.position=Vector3(float(data[0]),5.0,-0.27); lab.rotation_degrees.y=180; root.add_child(lab)

func create_field_180(pos:Vector3,color_value:Color):
	var root=Node3D.new(); root.position=pos; add_child(root)
	station_box(root,Vector3(30,0.06,130),Vector3(0,0.02,0),color_value)
	for x in range(-14,15,3):
		station_box(root,Vector3(0.35,0.035,128),Vector3(float(x),0.07,0),color_value.lightened(0.08))

func create_solar_farm_180(pos:Vector3):
	var root=Node3D.new(); root.position=pos; add_child(root)
	for x in [-9.0,-3.0,3.0,9.0]:
		for z in [-22.0,-11.0,0.0,11.0,22.0]:
			station_box(root,Vector3(4.6,0.10,2.5),Vector3(x,1.0,z),Color(0.025,0.12,0.24))
			station_box(root,Vector3(0.12,1.0,0.12),Vector3(x,0.5,z),Color(0.42,0.45,0.47))

func create_rest_area_180(pos:Vector3):
	var root=Node3D.new(); root.position=pos; add_child(root)
	station_box(root,Vector3(24,0.10,44),Vector3(0,0.08,0),Color(0.18,0.19,0.20))
	station_box(root,Vector3(15,4.2,8),Vector3(2,2.1,-12),Color(0.74,0.72,0.66))
	station_box(root,Vector3(15.3,0.28,8.3),Vector3(2,4.32,-12),Color(0.12,0.14,0.16))
	var lab=Label3D.new(); lab.text="AUTO BOSS  RASTPARK"; lab.font_size=30; lab.outline_size=5; lab.position=Vector3(2,3.1,-16.15); root.add_child(lab)
	for z in [-2.0,6.0,14.0]:
		station_box(root,Vector3(5.2,0.06,0.14),Vector3(-5,0.16,z),Color(0.90,0.90,0.88))

func create_industry_180(pos:Vector3):
	var root=Node3D.new(); root.position=pos; add_child(root)
	for data in [[-10.0,6.0,10.0],[2.0,8.0,14.0],[12.0,5.0,-7.0]]:
		station_box(root,Vector3(10,float(data[1]),14),Vector3(float(data[0]),float(data[1])/2.0,float(data[2])),Color(0.42,0.46,0.48))
	for x in [-12.0,10.0]:
		var stack=MeshInstance3D.new(); var cm=CylinderMesh.new(); cm.top_radius=0.7; cm.bottom_radius=1.0; cm.height=12.0; stack.mesh=cm; stack.position=Vector3(x,6,-14); stack.material_override=material(Color(0.56,0.57,0.56)); root.add_child(stack)

func create_vehicle_model_180(parent,color_value):
	# 18.0: breiter, flacher, deutlich mehr Pkw-Details und weniger Block-Look.
	station_box(parent,Vector3(2.02,0.16,3.75),Vector3(0,0.42,0.08),Color(0.018,0.021,0.026))
	station_box(parent,Vector3(1.96,0.42,3.72),Vector3(0,0.68,0.02),color_value.darkened(0.08))
	station_box(parent,Vector3(1.88,0.30,3.95),Vector3(0,0.91,-0.05),color_value)
	# Motorhaube, Kofferraum und Schulterlinie
	station_box(parent,Vector3(1.80,0.18,1.28),Vector3(0,1.10,-1.47),color_value.lightened(0.055))
	station_box(parent,Vector3(1.82,0.17,0.92),Vector3(0,1.05,1.55),color_value.darkened(0.025))
	station_box(parent,Vector3(1.92,0.055,2.65),Vector3(0,1.03,0.10),color_value.lightened(0.09))
	# Dach + dunkles Panorama-Glas
	station_box(parent,Vector3(1.55,0.14,1.82),Vector3(0,1.61,0.18),color_value.darkened(0.14))
	station_box(parent,Vector3(1.49,0.055,1.48),Vector3(0,1.70,0.18),Color(0.035,0.065,0.09))
	rotated_box(parent,Vector3(1.52,0.70,0.07),Vector3(0,1.38,-0.77),Color(0.035,0.075,0.105),0.0)
	rotated_box(parent,Vector3(1.52,0.55,0.07),Vector3(0,1.35,0.98),Color(0.035,0.070,0.095),0.0)
	for x in [-0.82,0.82]:
		station_box(parent,Vector3(0.055,0.50,1.35),Vector3(x,1.35,0.13),Color(0.035,0.075,0.105))
	# Front/Heck: Grill, Diffusor, Kennzeichen, LED-Bänder
	station_box(parent,Vector3(1.88,0.16,0.13),Vector3(0,0.52,-2.02),Color(0.025,0.028,0.032))
	station_box(parent,Vector3(1.05,0.26,0.055),Vector3(0,0.69,-2.10),Color(0.012,0.016,0.020))
	station_box(parent,Vector3(0.44,0.14,0.035),Vector3(0,0.49,-2.115),Color(0.90,0.90,0.84))
	station_box(parent,Vector3(1.90,0.17,0.13),Vector3(0,0.52,2.02),Color(0.025,0.028,0.032))
	station_box(parent,Vector3(1.28,0.07,0.045),Vector3(0,0.86,2.095),Color(0.80,0.015,0.012))
	for x in [-0.62,0.62]:
		light_box(parent,Vector3(x,0.88,-2.09),Color(0.88,0.96,1.0))
		light_box(parent,Vector3(x,0.82,2.09),Color(1.0,0.025,0.018))
	# Spiegel und Türgriffe
	for x in [-1.02,1.02]:
		station_box(parent,Vector3(0.19,0.10,0.30),Vector3(x,1.27,-0.58),Color(0.025,0.03,0.035))
	for x in [-0.94,0.94]:
		station_box(parent,Vector3(0.035,0.055,0.34),Vector3(x,1.08,0.25),Color(0.60,0.62,0.63))
	# Räder mit Felgen und Nabenkern
	for wx in [-1.0,1.0]:
		for wz in [-1.28,1.28]:
			var wheel=MeshInstance3D.new(); var wm=CylinderMesh.new(); wm.top_radius=0.40; wm.bottom_radius=0.40; wm.height=0.31; wheel.mesh=wm; wheel.position=Vector3(wx,0.45,wz); wheel.rotation_degrees=Vector3(0,0,90); wheel.material_override=material(Color(0.012,0.014,0.017)); parent.add_child(wheel)
			var rim=MeshInstance3D.new(); var rm=CylinderMesh.new(); rm.top_radius=0.245; rm.bottom_radius=0.245; rm.height=0.325; rim.mesh=rm; rim.position=Vector3(wx,0.45,wz); rim.rotation_degrees=Vector3(0,0,90); rim.material_override=material(Color(0.48,0.51,0.55)); parent.add_child(rim)
			var hub=MeshInstance3D.new(); var hm=CylinderMesh.new(); hm.top_radius=0.075; hm.bottom_radius=0.075; hm.height=0.335; hub.mesh=hm; hub.position=Vector3(wx,0.45,wz); hub.rotation_degrees=Vector3(0,0,90); hub.material_override=material(Color(0.10,0.11,0.12)); parent.add_child(hub)
