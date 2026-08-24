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
	{"name":"Stuttgart → Köln","distance":366.0,"reward":450},
	{"name":"Stuttgart → München","distance":220.0,"reward":280},
	{"name":"Stuttgart → Frankfurt","distance":205.0,"reward":260},
	{"name":"Stuttgart → Hamburg","distance":630.0,"reward":720}
]

var cars=[
	{"name":"Transporter","max_speed":42.0,"color":Color(0.08,0.22,0.55)},
	{"name":"Limousine","max_speed":48.0,"color":Color(0.08,0.08,0.10)},
	{"name":"Sportwagen","max_speed":55.0,"color":Color(0.75,0.08,0.08)}
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


func _ready():
	randomize()
	load_save()
	create_environment()
	create_ground()
	create_road()
	create_scenery()
	create_road_features()
	create_service_station_at(Vector3(13.0,0,-520.0),"SERVICE SÜD",1.79)
	create_service_station_at(Vector3(13.0,0,-1120.0),"SERVICE MITTE",1.89)
	create_service_station_at(Vector3(13.0,0,-1720.0),"SERVICE NORD",1.84)
	create_player()
	create_ui()
	show_main_menu()


func _physics_process(delta):
	if game_state!="driving":
		return

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
	cfg.save("user://autoboss.cfg")


func load_save():
	var cfg=ConfigFile.new()
	if cfg.load("user://autoboss.cfg")==OK:
		money=int(cfg.get_value("player","money",5000))
		reputation=int(cfg.get_value("player","reputation",15))
		selected_car=int(cfg.get_value("player","selected_car",0))


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


func show_main_menu():
	game_state="menu"
	menu_root.visible=true
	game_root.visible=false
	clear_menu()

	var title=Label.new()
	title.text="AUTO BOSS 1.5"
	title.position=Vector2(430,70)
	title.add_theme_font_size_override("font_size",46)
	menu_root.add_child(title)

	var sub=Label.new()
	sub.text="Fahrzeugüberführung • Karriere"
	sub.position=Vector2(455,130)
	sub.add_theme_font_size_override("font_size",22)
	menu_root.add_child(sub)

	menu_button("AUFTRAG STARTEN",Vector2(420,220),func(): show_routes())
	menu_button("GARAGE / FAHRZEUG",Vector2(420,300),func(): show_garage())
	menu_button("SPIELSTAND SPEICHERN",Vector2(420,380),func(): save_game())

	var stats=Label.new()
	stats.text="Geld: "+str(money)+" €     Reputation: "+str(reputation)
	stats.position=Vector2(430,490)
	stats.add_theme_font_size_override("font_size",22)
	menu_root.add_child(stats)


func show_routes():
	clear_menu()

	var title=Label.new()
	title.text="AUFTRAG AUSWÄHLEN"
	title.position=Vector2(420,55)
	title.add_theme_font_size_override("font_size",34)
	menu_root.add_child(title)

	for i in range(routes.size()):
		var r=routes[i]
		var b=Button.new()
		b.text=r["name"]+"   •   "+str(int(r["distance"]))+" km   •   "+str(r["reward"])+" €"
		b.position=Vector2(325,135+i*82)
		b.size=Vector2(630,60)
		b.add_theme_font_size_override("font_size",19)

		var idx=i
		b.pressed.connect(func():
			selected_route=idx
			start_mission()
		)
		menu_root.add_child(b)

	menu_button("← ZURÜCK",Vector2(420,520),func(): show_main_menu())


func show_garage():
	clear_menu()

	var title=Label.new()
	title.text="GARAGE"
	title.position=Vector2(535,55)
	title.add_theme_font_size_override("font_size",36)
	menu_root.add_child(title)

	for i in range(cars.size()):
		var c=cars[i]
		var b=Button.new()
		var prefix="✓ " if i==selected_car else ""
		b.text=prefix+c["name"]+"   •   Vmax "+str(int(c["max_speed"]*3.6))+" km/h"
		b.position=Vector2(385,150+i*90)
		b.size=Vector2(510,65)
		b.add_theme_font_size_override("font_size",20)

		var idx=i
		b.pressed.connect(func():
			selected_car=idx
			save_game()
			show_garage()
		)
		menu_root.add_child(b)

	menu_button("← ZURÜCK",Vector2(420,500),func(): show_main_menu())


func start_mission():
	game_state="driving"
	menu_root.visible=false
	game_root.visible=true
	mission_finished=false
	speed=0.0
	fuel=100.0
	damage=0.0
	distance_left=routes[selected_route]["distance"]
	mission_start_money=money

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

	var max_speed=float(cars[selected_car]["max_speed"])

	if gas and fuel>0:
		speed=min(speed+18.0*delta,max_speed)
	else:
		speed=max(speed-5.0*delta,0.0)

	if brake:
		speed=max(speed-34.0*delta,0.0)

	car.velocity=Vector3(steer*5.5,0,-speed)
	car.move_and_slide()
	car.position.x=clamp(car.position.x,-7.0,7.0)
	car.position.y=0.0

	if speed>0:
		fuel=max(0.0,fuel-speed*0.00035*delta)



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
	cam.global_position=car.global_position+Vector3(0,4.3,8.8)
	cam.look_at(car.global_position+Vector3(0,0.7,-11),Vector3.UP)


func update_mission(delta):
	distance_left-=speed*3.6*delta/120.0

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
	var clean_bonus=100 if damage<10 else 0
	var fuel_bonus=50 if fuel>20 else 0
	var damage_penalty=int(round(damage*2.0))

	var reward=max(
		0,
		base_reward+clean_bonus+fuel_bonus-damage_penalty
	)

	var service_costs=max(
		0,
		mission_start_money-money
	)

	money+=reward

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

	var real_profit=reward-service_costs

	settlement_details.text=(
		"Grundvergütung:        "+str(base_reward)+" €\n"
		+"Sauberkeitsbonus:     +"+str(clean_bonus)+" €\n"
		+"Tankbonus:            +"+str(fuel_bonus)+" €\n"
		+"Schaden-Abzug:        -"+str(damage_penalty)+" €\n"
		+"Tank/Werkstatt:       -"+str(service_costs)+" €\n"
		+"────────────────────────\n"
		+"Auszahlung:            "+str(reward)+" €\n"
		+"Tatsächlicher Gewinn:  "+str(real_profit)+" €\n"
		+"Kontostand:            "+str(money)+" €\n"
		+"Reputation:            "+str(reputation)
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

	add_child(t)

	if randi()%5==0:
		create_truck_model(t)
		t.set_meta("traffic_speed",randf_range(14.0,22.0))
	else:
		var colors=[
			Color(0.75,0.08,0.08),
			Color(0.08,0.25,0.8),
			Color(0.85,0.85,0.85),
			Color(0.05,0.05,0.06),
			Color(0.9,0.55,0.08),
			Color(0.15,0.65,0.25)
		]

		create_vehicle_model(t,colors[randi()%colors.size()])

	traffic.append(t)


func update_traffic(delta):
	traffic_timer+=delta

	if traffic_timer>2.7:
		traffic_timer=0
		if traffic.size()<14:
			spawn_traffic(car.position.z-190)

	for t in traffic.duplicate():
		if not is_instance_valid(t):
			traffic.erase(t)
			continue

		t.position.z-=float(t.get_meta("traffic_speed",22.0))*delta

		if t.position.z>car.position.z+100:
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
		damage=min(100.0,damage+randf_range(2.0,6.0))
		speed*=0.35

		if t.position.x<=car.position.x:
			t.position.x-=2.5
		else:
			t.position.x+=2.5


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
	add_child(world)

	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-25,0)
	sun.light_energy=1.35
	sun.light_color=Color(1.0,0.94,0.84)
	sun.shadow_enabled=true
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



func create_road_features():
	# Überführungen
	create_overpass(-760.0)
	create_overpass(-2140.0)

	# Zwei erkennbare Autobahn-Ausfahrten
	create_exit_area(-1380.0, "Ausfahrt 12  Heilbronn")
	create_exit_area(-2580.0, "Ausfahrt 29  Frankfurt")

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
	station_box(root,Vector3(1.0,5.0,1.0),Vector3(-10.5,2.5,0),Color(0.48,0.50,0.54))
	station_box(root,Vector3(1.0,5.0,1.0),Vector3(10.5,2.5,0),Color(0.48,0.50,0.54))
	# Brückendeck hoch genug für Fahrzeuge
	station_box(root,Vector3(30.0,0.75,5.0),Vector3(0,5.1,0),Color(0.30,0.31,0.34))
	station_box(root,Vector3(30.0,0.20,0.20),Vector3(0,5.75,-2.25),Color(0.72,0.74,0.77))
	station_box(root,Vector3(30.0,0.20,0.20),Vector3(0,5.75,2.25),Color(0.72,0.74,0.77))


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
	label.rotation_degrees.y=180
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
	station_box(root,Vector3(0.16,5.6,0.16),Vector3(-7.4,2.8,0),Color(0.72,0.74,0.76))
	station_box(root,Vector3(0.16,5.6,0.16),Vector3(7.4,2.8,0),Color(0.72,0.74,0.76))
	station_box(root,Vector3(15.0,0.16,0.16),Vector3(0,5.55,0),Color(0.72,0.74,0.76))
	station_box(root,Vector3(8.2,1.25,0.12),Vector3(0,5.15,-0.12),Color(0.02,0.28,0.55))
	var label=Label3D.new()
	label.text=text_value+"\n↓          ↓"
	label.font_size=26
	label.outline_size=5
	label.position=Vector3(0,5.15,-0.20)
	label.rotation_degrees.y=180
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
	sign.rotation_degrees.y=180
	station.add_child(sign)


func create_service_station_legacy_unused():
	var station=Node3D.new()
	station.position=Vector3(13.0,0,-520.0)
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
	sign.rotation_degrees.y=180
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
			and car.position.x > 5.3
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

	cam=Camera3D.new()
	cam.current=true
	add_child(cam)


func rebuild_player():
	for child in car.get_children():
		if child is MeshInstance3D:
			child.queue_free()

	create_vehicle_model(car,cars[selected_car]["color"])


func create_vehicle_model(parent,color_value):
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
	obj.material_override=material(color_value)
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

	money_label=Label.new()
	money_label.position=Vector2(1100,20)
	money_label.add_theme_font_size_override("font_size",24)
	game_root.add_child(money_label)

	route_progress=ProgressBar.new()
	route_progress.position=Vector2(350,88)
	route_progress.size=Vector2(430,12)
	route_progress.show_percentage=false
	game_root.add_child(route_progress)

	service_label=Label.new()
	service_label.position=Vector2(420,91)
	service_label.add_theme_font_size_override("font_size",15)
	game_root.add_child(service_label)

	refuel_button=Button.new()
	refuel_button.text="TANKEN"
	refuel_button.position=Vector2(885,545)
	refuel_button.size=Vector2(120,70)
	refuel_button.visible=false
	refuel_button.pressed.connect(func(): refuel_car())
	game_root.add_child(refuel_button)

	repair_button=Button.new()
	repair_button.text="REPARIEREN"
	repair_button.position=Vector2(885,620)
	repair_button.size=Vector2(120,70)
	repair_button.visible=false
	repair_button.pressed.connect(func(): repair_car())
	game_root.add_child(repair_button)

	pause_button=Button.new()
	pause_button.text="II"
	pause_button.position=Vector2(1185,130)
	pause_button.size=Vector2(70,55)
	pause_button.pressed.connect(func(): toggle_pause())
	game_root.add_child(pause_button)

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
	settlement_panel.position=Vector2(295,135)
	settlement_panel.size=Vector2(690,500)
	settlement_panel.visible=false
	game_root.add_child(settlement_panel)

	settlement_title=Label.new()
	settlement_title.position=Vector2(45,30)
	settlement_title.size=Vector2(600,85)
	settlement_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	settlement_title.add_theme_font_size_override("font_size",28)
	settlement_panel.add_child(settlement_title)

	settlement_details=Label.new()
	settlement_details.position=Vector2(95,125)
	settlement_details.size=Vector2(500,235)
	settlement_details.add_theme_font_size_override("font_size",20)
	settlement_panel.add_child(settlement_details)

	settlement_next_button=Button.new()
	settlement_next_button.text="NÄCHSTER AUFTRAG"
	settlement_next_button.position=Vector2(70,405)
	settlement_next_button.size=Vector2(260,60)
	settlement_next_button.add_theme_font_size_override("font_size",19)
	settlement_next_button.pressed.connect(func(): settlement_next_job())
	settlement_panel.add_child(settlement_next_button)

	settlement_home_button=Button.new()
	settlement_home_button.text="HAUPTMENÜ"
	settlement_home_button.position=Vector2(360,405)
	settlement_home_button.size=Vector2(260,60)
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
	speed_label.text="AUTO BOSS 1.5\n"+str(int(speed*3.6))+" km/h"
	mission_label.text="AUFTRAG: "+routes[selected_route]["name"]
	info_label.text=str(int(distance_left))+" km   •   Tank "+str(int(fuel))+"%   •   Schaden "+str(int(damage))+"%"
	money_label.text=str(money)+" €"
	if route_progress!=null:
		var total=float(routes[selected_route]["distance"])
		route_progress.value=clamp((1.0-distance_left/total)*100.0,0.0,100.0)


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
