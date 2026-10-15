extends Node3D
const Data=preload("res://scripts/open_world/world_data.gd")
const World=preload("res://scripts/open_world/world_streamer.gd")
const Vehicle=preload("res://scripts/open_world/vehicle.gd")
const Career=preload("res://scripts/open_world/career.gd")
const Traffic=preload("res://scripts/open_world/traffic.gd")
const HUD=preload("res://scripts/open_world/hud.gd")
const RainFX=preload("res://scripts/open_world/rain_fx.gd")
const POSITION_FILE="user://autoboss_world_position.cfg"
var world
var vehicle
var traffic
var career
var hud
var cam:Camera3D
var sun:DirectionalLight3D
var world_environment:WorldEnvironment
var destination_marker:Node3D
var headlights:SpotLight3D
var rain_fx:Node3D
var sky_update_acc:float=0.0
var weather_material_acc:float=0.0
var save_acc:float=0.0
var route:Array[Vector2]=[]
var stage_target:Vector2=Vector2.ZERO
var current_region:String="Lindenfurt"
var state:String="menu"
var weather:String="Klar"
var weather_timer:float=0.0
var clock:float=8.25
var runtime:float=0.0
var hud_update_acc:float=0.0
var world_acc:float=0.0
var camera_mode:int=0
var quality:int=0
var touch:Dictionary={"gas":false,"brake":false,"left":false,"right":false}

func _ready()->void:
	create_environment()
	world=World.new();world.name="Dynamisches_Open_World_Streaming";add_child(world)
	career=Career.new()
	vehicle=Vehicle.new();vehicle.name="Spielerfahrzeug";add_child(vehicle)
	vehicle.configure(1)
	create_headlights()
	load_position()
	if career.active_stage=="delivery": vehicle.configure(int(career.active_job["car"]))
	vehicle.position.y=Data.height_at(vehicle.position.x,vehicle.position.z)
	world.stream_radius=1 if quality==0 else 2
	world.detail_level=quality
	world.force_spawn(vehicle.position)
	traffic=Traffic.new();traffic.name="KI_Verkehr";add_child(traffic);traffic.player=vehicle
	traffic.active_count=8 if quality==0 else (12 if quality==1 else 16)
	rain_fx=RainFX.new();rain_fx.name="Regen_FX";add_child(rain_fx)
	cam=Camera3D.new();cam.fov=69.0;cam.far=1650.0;cam.current=true;add_child(cam)
	update_camera(1.0)
	create_destination_marker()
	refresh_destination()
	hud=HUD.new();hud.game=self;add_child(hud)
	# Start screen overlays the 3D world. All vehicle/world files from 61.0 remain intact.

func create_environment()->void:
	var environment:=Environment.new()
	var sky:=Sky.new()
	var proc:=ProceduralSkyMaterial.new()
	proc.sky_top_color=Color(0.13,0.34,0.59)
	proc.sky_horizon_color=Color(0.68,0.76,0.80)
	proc.ground_bottom_color=Color(0.17,0.20,0.17)
	proc.ground_horizon_color=Color(0.42,0.50,0.41)
	sky.sky_material=proc
	environment.background_mode=Environment.BG_SKY
	environment.sky=sky
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_BG
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled=true
	environment.fog_light_color=Color(0.53,0.62,0.65)
	environment.fog_density=0.00034
	world_environment=WorldEnvironment.new()
	world_environment.environment=environment
	add_child(world_environment)
	sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-35,0)
	sun.light_energy=1.12;sun.shadow_enabled=false
	add_child(sun)

func create_headlights()->void:
	headlights=SpotLight3D.new()
	headlights.name="Adaptive_Abblendlicht"
	headlights.light_color=Color(0.94,0.97,1.0)
	headlights.light_energy=0.0
	headlights.spot_range=45.0
	headlights.spot_angle=40.0
	headlights.shadow_enabled=false
	headlights.position=Vector3(0,1.18,-2.15)
	vehicle.add_child(headlights)

func create_destination_marker()->void:
	destination_marker=Node3D.new();add_child(destination_marker)
	var pole:=MeshInstance3D.new();var pole_mesh:=CylinderMesh.new()
	pole_mesh.top_radius=0.7;pole_mesh.bottom_radius=0.7;pole_mesh.height=25.0
	pole.mesh=pole_mesh;pole.position.y=12.5
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color(0.98,0.74,0.08,0.56)
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	pole.material_override=mat;destination_marker.add_child(pole)
	var pin:=MeshInstance3D.new();var ball:=SphereMesh.new();ball.radius=2.3;ball.height=4.6
	pin.mesh=ball;pin.position.y=25
	var gold:=StandardMaterial3D.new();gold.albedo_color=Color(1.0,0.74,0.15)
	gold.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	pin.material_override=gold;destination_marker.add_child(pin)

func _physics_process(delta:float)->void:
	if state!="driving":return
	var gas_input:float=1.0 if touch["gas"] or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) else 0.0
	var brake_input:float=1.0 if touch["brake"] or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_SPACE) else 0.0
	var left_input:float=1.0 if touch["left"] or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) else 0.0
	var right_input:float=1.0 if touch["right"] or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) else 0.0
	var grip:float=0.70 if weather=="Starkregen" else (0.85 if weather=="Regen" else 1.0)
	vehicle.engine_mod=1.0+0.10*career.engine_upgrade
	vehicle.brake_mod=1.0+0.13*career.brake_upgrade
	var previous_position:Vector3=vehicle.position
	vehicle.drive(delta,gas_input,brake_input,right_input-left_input,grip)
	if world.hit_static(vehicle.position):
		var impact:float=absf(vehicle.speed)
		vehicle.position=previous_position
		vehicle.receive_impact(impact)
	traffic.update_movement(delta)
	world_acc+=delta
	if world_acc>=0.12:
		world.update_stream(vehicle.position)
		current_region=Data.region_at(Vector2(vehicle.position.x,vehicle.position.z))
		world_acc=0.0
	if career.active_stage!="" and career.active_stage=="delivery":career.job_timer+=delta
	update_navigation(delta)
	save_acc+=delta
	if save_acc>=70.0:
		save_acc=0.0
		save_progress()

func _process(delta:float)->void:
	if state=="driving":
		clock=fposmod(clock+delta*0.014,24.0)
		weather_timer+=delta
		if weather_timer>170.0:
			weather_timer=0.0
			var weathers:Array[String]=["Klar","Wolkig","Regen","Starkregen","Nebel"]
			weather=weathers[randi()%weathers.size()]
		update_atmosphere(delta)
		update_camera(delta)
		if rain_fx!=null:rain_fx.tick(delta,vehicle.global_position,weather,quality)

func update_atmosphere(delta:float)->void:
	var daytime:float=clampf(sin((clock-5.5)/24.0*TAU),0.0,1.0)
	sun.rotation_degrees.x=-8.0-daytime*62.0
	sun.light_energy=0.27+daytime*0.89
	var fog:float=0.00185 if weather=="Nebel" else (0.00095 if weather=="Starkregen" else (0.00058 if weather=="Regen" else 0.00034))
	world_environment.environment.fog_density=fog
	if headlights!=null:
		headlights.light_energy=3.1 if clock>=19.0 or clock<6.2 else (1.0 if weather=="Starkregen" else 0.0)
	sun.light_color=Color(1.0,0.72,0.53).lerp(Color(1.0,0.98,0.91),daytime)
	weather_material_acc+=delta
	if weather_material_acc>=0.3:
		weather_material_acc=0.0
		world.update_visual_weather(daytime,weather=="Regen" or weather=="Starkregen",traffic.light_clock)
	sky_update_acc+=delta
	if sky_update_acc>=2.0:
		sky_update_acc=0.0
		var procedural:ProceduralSkyMaterial=world_environment.environment.sky.sky_material as ProceduralSkyMaterial
		if procedural!=null:
			procedural.sky_top_color=Color(0.018,0.035,0.095).lerp(Color(0.13,0.34,0.59),daytime)
			procedural.sky_horizon_color=Color(0.07,0.11,0.17).lerp(Color(0.68,0.76,0.80),daytime)


func update_camera(delta:float)->void:
	var f:=Vector3(-sin(vehicle.yaw),0.0,-cos(vehicle.yaw))
	var wanted:Vector3
	if camera_mode==0:
		wanted=vehicle.position-f*8.4+Vector3(0,3.65,0)
	else:
		wanted=vehicle.position+f*1.0+Vector3(0,1.65,0)
	cam.global_position=cam.global_position.lerp(wanted,clampf(delta*6.5,0.0,1.0))
	cam.look_at(vehicle.position+f*19.0+Vector3(0,1.35,0),Vector3.UP)

func toggle_camera()->void:
	camera_mode=(camera_mode+1)%2

func set_touch(which:String,pressed:bool)->void:
	touch[which]=pressed

func clear_touch()->void:
	for k in touch.keys():touch[k]=false

func set_quality(level:int)->void:
	quality=clampi(level,0,2)
	world.stream_radius=1 if quality==0 else 2
	world.detail_level=quality
	world.rebuild_for_quality(vehicle.position)
	traffic.active_count=8 if quality==0 else (12 if quality==1 else 16)
	save_progress()
	hud.show_menu("settings")

func pause_game()->void:
	state="paused";clear_touch();save_progress()
	hud.show_menu("pause")

func resume_driving()->void:
	state="driving";hud.show_driving()

func accept_contract(index:int)->void:
	if career.accept(index):
		refresh_destination()
		state="driving";hud.show_driving()
		hud.notify("Auftrag angenommen! Fahre zur gelben ABHOLUNG.",5.0)
	else:
		hud.notify("Auftrag noch nicht verfügbar.")

func refresh_destination()->void:
	if career.active_stage=="":
		destination_marker.visible=false;route.clear();return
	stage_target=career.target()
	destination_marker.visible=true
	destination_marker.position=Vector3(stage_target.x,Data.height_at(stage_target.x,stage_target.y),stage_target.y)
	route=Data.route_points(Vector2(vehicle.position.x,vehicle.position.z),stage_target)

func update_navigation(_delta:float)->void:
	if career.active_stage=="":return
	var p:=Vector2(vehicle.position.x,vehicle.position.z)
	if route.size()==0:refresh_destination()
	elif p.distance_to(route[0])>900.0:
		route=Data.route_points(p,stage_target)
	elif route.size()>1 and p.distance_to(route[0])<60.0:
		route.remove_at(0)

func remaining_meters()->float:
	if career.active_stage=="":return 0.0
	var p:=Vector2(vehicle.position.x,vehicle.position.z)
	var dist:float=0.0
	if route.size()>0:
		dist=p.distance_to(route[0])+Data.route_length(route)
	else:
		dist=p.distance_to(stage_target)
	return dist

func can_interact()->bool:
	if career.active_stage=="":return false
	return Vector2(vehicle.position.x,vehicle.position.z).distance_to(stage_target)<39.0 and absf(vehicle.speed)<2.3

func interact()->void:
	if not can_interact():
		hud.notify("Bitte innerhalb der Zielzone anhalten.")
		return
	if career.active_stage=="pickup":
		career.pickup()
		vehicle.configure(int(career.active_job["car"]))
		vehicle.engine_mod=1.0+0.10*career.engine_upgrade
		vehicle.brake_mod=1.0+0.13*career.brake_upgrade
		refresh_destination()
		hud.notify("Fahrzeug übernommen! Ziel: "+str(career.active_job["to"]),5.0)
	elif career.active_stage=="delivery":
		career.finish(vehicle.damage,vehicle.fuel)
		# Customer vehicle has been handed over; switch back to a neutral service car.
		vehicle.configure(1)
		refresh_destination()
		state="menu"
		hud.show_menu("result")
		save_progress()

func next_instruction()->String:
	if route.size()<2:return "Dem Ziel folgen"
	var p:=Vector2(vehicle.position.x,vehicle.position.z)
	var next:Vector2=route[0]
	var ahead:Vector2=route[1]
	var dist:float=p.distance_to(next)
	if dist>240.0:return "Geradeaus • Nächster Abzweig in %.0f m" % dist
	var forward:Vector2=(next-p).normalized()
	var outgoing:Vector2=(ahead-next).normalized()
	var cross:float=forward.x*outgoing.y-forward.y*outgoing.x
	if absf(cross)<0.38:return "Weiter geradeaus • %.0f m" % dist
	return ("Links abbiegen" if cross<0.0 else "Rechts abbiegen")+" • %.0f m" % dist

func navigation_text()->String:
	if career.active_stage=="":return "Kein Auftrag aktiv – MENÜ → AUFTRAGSBÖRSE"
	var meters:float=remaining_meters()
	var minutes:int=ceili(meters/maxf(13.0,absf(vehicle.speed))*1.0/60.0)
	var warning:String="  •  AM ZIEL ANHALTEN" if can_interact() else ""
	var deadline:int=int(career.active_job.get("deadline_minutes",0))
	var time_left:String="  •  Express: %d min" % maxi(0,deadline-ceili(career.job_timer/60.0)) if deadline>0 and career.active_stage=="delivery" else ""
	return "%s\n%.1f km  •  ETA %d min%s\n%s%s" % [career.destination_name(),meters*0.001,minutes,warning,next_instruction(),time_left]

func clock_text()->String:
	return "%02d:%02d" % [int(clock),int((clock-float(int(clock)))*60.0)]

func buy_upgrade(kind:String)->void:
	var message:String=career.invest(kind)
	hud.show_menu("company")
	# Investment result remains visible as transient feedback once driving resumes.
	hud.notify(message)

func service_vehicle()->void:
	if career.money<225:
		hud.notify("Nicht genug Geld für die Werkstatt.")
		return
	career.money-=225
	vehicle.damage=0.0;vehicle.fuel=100.0
	career.save_game();hud.show_menu("company");hud.notify("Fahrzeug gewartet und getankt.")

func save_progress()->void:
	career.save_game()
	var cfg:=ConfigFile.new()
	cfg.set_value("world","x",vehicle.position.x)
	cfg.set_value("world","z",vehicle.position.z)
	cfg.set_value("world","yaw",vehicle.yaw)
	cfg.set_value("world","clock",clock)
	cfg.set_value("world","weather",weather)
	cfg.set_value("world","quality",quality)
	cfg.save(POSITION_FILE)

func load_position()->void:
	var cfg:=ConfigFile.new()
	if cfg.load(POSITION_FILE)!=OK:
		vehicle.position=Vector3(0,0,0);return
	vehicle.position=Vector3(float(cfg.get_value("world","x",0.0)),0,float(cfg.get_value("world","z",0.0)))
	vehicle.yaw=float(cfg.get_value("world","yaw",0.0));vehicle.rotation.y=vehicle.yaw
	clock=float(cfg.get_value("world","clock",8.25))
	weather=str(cfg.get_value("world","weather","Klar"))
	quality=int(cfg.get_value("world","quality",0))

func _unhandled_key_input(event:InputEvent)->void:
	if not (event is InputEventKey):return
	var key_event:InputEventKey=event as InputEventKey
	if not key_event.pressed or key_event.echo:return
	match key_event.keycode:
		KEY_ESCAPE:
			if state=="driving":pause_game()
			elif state=="paused":resume_driving()
		KEY_C:toggle_camera()
		KEY_F:interact()
		KEY_M:
			if state=="driving":hud.map_view.scale_factor=0.04 if hud.map_view.scale_factor>0.08 else 0.12
