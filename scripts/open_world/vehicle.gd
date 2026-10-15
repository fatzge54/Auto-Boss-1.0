extends Node3D
const Data=preload("res://scripts/open_world/world_data.gd")
const CATALOG:Array = [
	{"name":"Kleinwagen", "max_speed":39.0,"acceleration":6.8,"brakes":10.0,"steering":2.1,"mass":1050.0,"usage":0.8,"size":Vector3(1.65,1.30,3.7),"paint":Color(0.85,0.36,0.22)},
	{"name":"Limousine", "max_speed":57.0,"acceleration":8.2,"brakes":10.2,"steering":1.85,"mass":1750.0,"usage":1.1,"size":Vector3(1.94,1.40,4.8),"paint":Color(0.13,0.22,0.34)},
	{"name":"Sportwagen", "max_speed":76.0,"acceleration":12.0,"brakes":13.1,"steering":2.30,"mass":1480.0,"usage":1.65,"size":Vector3(2.0,1.15,4.55),"paint":Color(0.82,0.13,0.11)},
	{"name":"SUV", "max_speed":53.0,"acceleration":6.9,"brakes":8.6,"steering":1.65,"mass":2400.0,"usage":1.45,"size":Vector3(2.08,1.82,4.7),"paint":Color(0.39,0.43,0.34)},
	{"name":"Transporter", "max_speed":40.0,"acceleration":5.5,"brakes":7.5,"steering":1.45,"mass":3200.0,"usage":1.7,"size":Vector3(2.10,2.55,5.5),"paint":Color(0.87,0.88,0.85)},
	{"name":"LKW", "max_speed":25.0,"acceleration":3.3,"brakes":6.3,"steering":1.15,"mass":12500.0,"usage":3.1,"size":Vector3(2.45,3.35,8.2),"paint":Color(0.20,0.55,0.63)}
]
var class_index:int=1
var speed:float=0.0  # signed meters/second
var yaw:float=0.0
var fuel:float=100.0
var damage:float=0.0
var odometer:float=0.0
var steer_visual:float=0.0
var body_root:Node3D
var engine_sound:AudioStreamPlayer3D
var engine_mod:float=1.0
var brake_mod:float=1.0

func _ready()->void:
	body_root=Node3D.new();body_root.name="Fahrzeugkarosserie";add_child(body_root)
	build_model()
	if ResourceLoader.exists("res://assets/open_world/engine_loop.wav"):
		engine_sound=AudioStreamPlayer3D.new()
		var loop_stream:AudioStreamWAV=load("res://assets/open_world/engine_loop.wav") as AudioStreamWAV
		if loop_stream!=null:
			loop_stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		engine_sound.stream=loop_stream
		engine_sound.unit_size=18.0;engine_sound.volume_db=-12.0
		add_child(engine_sound)
		engine_sound.play()

func configure(index:int)->void:
	class_index=clampi(index,0,CATALOG.size()-1)
	if body_root!=null:
		for child in body_root.get_children():child.queue_free()
		build_model()
	speed=0.0
	fuel=100.0
	damage=0.0

func mesh_box(p:Node3D,size:Vector3,at:Vector3,col:Color,metal:float=0.0)->void:
	var obj:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size;obj.mesh=box
	var mat:=StandardMaterial3D.new();mat.albedo_color=col;mat.metallic=metal;mat.roughness=0.35 if metal>0.0 else 0.70
	obj.material_override=mat;obj.position=at;p.add_child(obj)

func build_model()->void:
	var info:Dictionary=CATALOG[class_index]
	var dims:Vector3=info["size"]
	var paint:Color=info["paint"]
	var width:float=dims.x
	var length:float=dims.z
	var height:float=dims.y
	var is_large:bool=class_index>=4
	mesh_box(body_root,Vector3(width,height*0.52,length),Vector3(0,height*0.42,0),paint,0.42)
	var cabin_length:float=length*0.42 if not is_large else length*0.42
	var cab_z:float=0.30 if not is_large else -length*0.27
	mesh_box(body_root,Vector3(width*0.90,height*0.37,cabin_length),Vector3(0,height*0.85,cab_z),paint.lightened(0.045),0.28)
	mesh_box(body_root,Vector3(width*0.86,height*0.22,cabin_length*0.93),Vector3(0,height*0.87,cab_z),Color(0.095,0.16,0.21),0.15)
	if is_large:
		mesh_box(body_root,Vector3(width*0.98,height*0.67,length*0.52),Vector3(0,height*0.55,length*0.20),Color(0.79,0.81,0.82),0.20)
	for side in [-1.0,1.0]:
		for z in [-length*0.33,length*0.30]:
			var wheel:=MeshInstance3D.new();var tire:=CylinderMesh.new()
			tire.top_radius=0.43 if is_large else 0.33
			tire.bottom_radius=tire.top_radius;tire.height=0.20
			wheel.mesh=tire
			var wm:=StandardMaterial3D.new();wm.albedo_color=Color(0.07,0.07,0.075)
			wheel.material_override=wm
			wheel.rotation.z=PI*0.5
			wheel.position=Vector3(side*(width*0.48),0.44 if is_large else 0.34,z)
			body_root.add_child(wheel)
	for side in [-1.0,1.0]:
		mesh_box(body_root,Vector3(width*0.21,0.12,0.075),Vector3(side*width*0.32,0.53,-length*0.505),Color(0.98,0.93,0.77))
		mesh_box(body_root,Vector3(width*0.18,0.10,0.075),Vector3(side*width*0.34,0.53,length*0.505),Color(0.86,0.10,0.08))
	mesh_box(body_root,Vector3(width*0.75,0.11,0.09),Vector3(0,0.42,-length*0.515),Color(0.08,0.09,0.12))

func drive(delta:float,throttle:float,braking:float,steering:float,weather_grip:float)->void:
	var info:Dictionary=CATALOG[class_index]
	var max_speed:float=float(info["max_speed"])*(1.0+engine_mod*0.02-0.02)
	var accel:float=float(info["acceleration"])*engine_mod
	var brake_force:float=float(info["brakes"])*brake_mod*weather_grip
	var damage_penalty:float=maxf(0.58,1.0-damage*0.003)
	if throttle>0.05 and fuel>0.0:
		speed=move_toward(speed,max_speed*damage_penalty,accel*throttle*delta*weather_grip)
	elif braking>0.05:
		if speed>0.7:
			speed=move_toward(speed,0.0,brake_force*braking*delta)
		else:
			speed=move_toward(speed,-6.0,accel*0.43*delta)
	else:
		speed=move_toward(speed,0.0,2.2*delta)
	# Steering responds to speed, grip and vehicle length.
	var turn_factor:float=clampf(absf(speed)/7.0,0.0,1.0)
	var steer_rate:float=float(info["steering"])*weather_grip*turn_factor/(1.0+absf(speed)*0.018)
	yaw+=steering*steer_rate*delta*(1.0 if speed>=0.0 else -1.0)
	rotation.y=yaw
	var forward:=Vector3(-sin(yaw),0.0,-cos(yaw))
	position+=forward*speed*delta
	position.x=clampf(position.x,-Data.HALF_EXTENT+50.0,Data.HALF_EXTENT-50.0)
	position.z=clampf(position.z,-Data.HALF_EXTENT+50.0,Data.HALF_EXTENT-50.0)
	position.y=Data.height_at(position.x,position.z)+0.02
	var drive_m:float=absf(speed)*delta
	odometer+=drive_m*0.001
	fuel=maxf(0.0,fuel-drive_m*0.0012*float(info["usage"]))
	if engine_sound!=null:
		engine_sound.pitch_scale=clampf(0.8+absf(speed)*0.022,0.7,2.0)
		engine_sound.volume_db=-14.0 if absf(speed)<1.0 else -7.0

func receive_impact(relative_speed:float)->void:
	var hit:float=clampf(relative_speed*1.8,2.0,26.0)
	damage=minf(100.0,damage+hit)
	speed*=0.32

func kmh()->int:
	return roundi(absf(speed)*3.6)
