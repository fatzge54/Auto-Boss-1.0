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
var offroad:bool=false
var surface_grip:float=1.0


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

func add_body_panel(parent:Node3D,points:Array,color:Color,metallic:float=0.0)->void:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Each triangle has its own normals for sharp stamped-metal silhouette.
	for i in range(0,points.size(),3):
		surface.add_vertex(points[i])
		surface.add_vertex(points[i+1])
		surface.add_vertex(points[i+2])
	surface.generate_normals()
	var node:=MeshInstance3D.new()
	node.mesh=surface.commit()
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=color
	mat.metallic=metallic
	mat.roughness=0.24 if metallic>0.0 else 0.50
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.material_override=mat
	parent.add_child(node)

func make_tapered_shell(parent:Node3D,width:float,length:float,hood:float,paint:Color)->void:
	# A chamfered cross-section with different front/rear widths and deck heights.
	# This replaces the rectangular outer body of 63.0 with a single low-poly mesh.
	var coords:Array=[
		[-length*0.50,width*0.79,hood*0.94],
		[-length*0.40,width*0.96,hood*1.06],
		[-length*0.15,width,hood*1.02],
		[length*0.30,width*0.99,hood],
		[length*0.46,width*0.90,hood*0.96],
		[length*0.50,width*0.84,hood*0.89]
	]
	var verts:Array[Vector3]=[]
	for station in coords:
		var z:float=float(station[0])
		var w:float=float(station[1])*0.5
		var upper:float=0.50+float(station[2])*0.70
		verts.append_array([
			Vector3(-w,0.45,z),Vector3(w,0.45,z),
			Vector3(w*0.96,upper-0.09,z),Vector3(-w*0.96,upper-0.09,z),
			Vector3(-w*0.78,upper,z),Vector3(w*0.78,upper,z)
		])
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for step in range(coords.size()-1):
		var i:int=step*6
		var j:int=(step+1)*6
		for edge in [[0,1],[1,2],[2,5],[5,4],[4,3],[3,0]]:
			var a:int=int(edge[0]);var b:int=int(edge[1])
			for v in [verts[i+a],verts[i+b],verts[j+b],verts[i+a],verts[j+b],verts[j+a]]:
				surface.add_vertex(v)
	# Close front and rear end caps.
	for v in [verts[0],verts[3],verts[4],verts[0],verts[4],verts[5],verts[0],verts[5],verts[1]]:
		surface.add_vertex(v)
	var e:int=(coords.size()-1)*6
	for v in [verts[e+0],verts[e+4],verts[e+3],verts[e+0],verts[e+1],verts[e+5],verts[e+0],verts[e+5],verts[e+4]]:
		surface.add_vertex(v)
	surface.generate_normals()
	var mi:=MeshInstance3D.new();mi.mesh=surface.commit()
	var material:=StandardMaterial3D.new()
	material.albedo_color=paint;material.metallic=0.52;material.roughness=0.31
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	mi.material_override=material;parent.add_child(mi)

func build_model()->void:
	var info:Dictionary=CATALOG[class_index]
	var dims:Vector3=info["size"]
	var paint:Color=info["paint"]
	var width:float=dims.x
	var length:float=dims.z
	var height:float=dims.y
	var large:bool=class_index>=4
	var half:float=width*0.5
	var hood_height:float=0.86 if not large else 1.24
	# Lower chassis, metal body, horizontal bumpers and fascia accents.
	mesh_box(body_root,Vector3(width*0.94,0.24,length*0.97),Vector3(0,0.48,0),Color(0.075,0.09,0.11))
	make_tapered_shell(body_root,width,length,hood_height,paint)
	var z_front:float=-length*0.50
	var z_rear:float=length*0.50
	if large:
		var cabin_pos:float=-length*0.30
		mesh_box(body_root,Vector3(width*0.97,height*0.73,length*0.40),Vector3(0,height*0.53,cabin_pos),paint,0.35)
		mesh_box(body_root,Vector3(width*0.89,height*0.32,length*0.40+0.03),Vector3(0,height*0.70,cabin_pos),Color(0.10,0.18,0.23),0.19)
		mesh_box(body_root,Vector3(width*0.95,height*0.81,length*0.53),Vector3(0,height*0.53,length*0.22),Color(0.78,0.81,0.80),0.10)
	else:
		# The glasshouse is a six-sided sloping prism rather than stacked boxes.
		var low:float=1.03 if class_index!=3 else 1.21
		var roof:float=height+0.26
		var front_low:float=-length*0.30
		var rear_low:float=length*0.27
		var front_top:float=-length*0.09
		var rear_top:float=length*0.17
		var roof_half:float=half*0.73
		var base_half:float=half*0.93
		var polygons:Array[Vector3]=[]
		var a:=Vector3(-base_half,low,front_low)
		var b:=Vector3(base_half,low,front_low)
		var c:=Vector3(-base_half,low,rear_low)
		var d:=Vector3(base_half,low,rear_low)
		var e:=Vector3(-roof_half,roof,front_top)
		var f:=Vector3(roof_half,roof,front_top)
		var g:=Vector3(-roof_half,roof,rear_top)
		var h:=Vector3(roof_half,roof,rear_top)
		polygons.append_array([e,f,h,e,h,g,a,e,g,a,g,c,b,d,h,b,h,f])
		add_body_panel(body_root,polygons,paint.lightened(0.035),0.36)
		# Sloped glass areas take advantage of the same inexpensive low-poly prism.
		add_body_panel(body_root,[a,b,f,a,f,e],Color(0.085,0.19,0.24),0.24)
		add_body_panel(body_root,[c,g,h,c,h,d],Color(0.08,0.17,0.22),0.21)
		add_body_panel(body_root,[a,c,g,a,g,e],Color(0.10,0.21,0.25),0.20)
		add_body_panel(body_root,[b,f,h,b,h,d],Color(0.10,0.21,0.25),0.20)
		# Stamped window dividers, side mirrors, front grille and door trim.
		for side in [-1.0,1.0]:
			mesh_box(body_root,Vector3(0.07,0.35,0.11),Vector3(side*half*0.91,1.25,0),paint.darkened(0.10))
			mesh_box(body_root,Vector3(0.32,0.17,0.19),Vector3(side*(half+0.14),1.08,front_low+0.12),paint,0.32)
			mesh_box(body_root,Vector3(0.055,0.05,0.48),Vector3(side*(half+0.016),0.85,0.20),Color(0.54,0.55,0.56),0.6)
	mesh_box(body_root,Vector3(width*0.50,0.24,0.05),Vector3(0,0.69,z_front-0.055),Color(0.07,0.10,0.13))
	mesh_box(body_root,Vector3(width*0.92,0.13,0.15),Vector3(0,0.43,z_front-0.06),Color(0.15,0.17,0.18),0.30)
	mesh_box(body_root,Vector3(width*0.92,0.13,0.15),Vector3(0,0.43,z_rear+0.06),Color(0.15,0.17,0.18),0.30)
	# Wheels include silver hubs and a subtle dark wheel well.
	var radius:float=0.46 if large else (0.40 if class_index==3 else 0.34)
	for side in [-1.0,1.0]:
		for z in [-length*0.33,length*0.31]:
			var wheel:=MeshInstance3D.new()
			var tire:=CylinderMesh.new()
			tire.top_radius=radius;tire.bottom_radius=radius;tire.height=0.22;tire.radial_segments=11
			wheel.mesh=tire
			var wm:=StandardMaterial3D.new();wm.albedo_color=Color(0.055,0.061,0.065)
			wheel.material_override=wm
			wheel.rotation.z=PI*0.5
			wheel.position=Vector3(side*(half*0.95),radius,z)
			body_root.add_child(wheel)
			var hub:=MeshInstance3D.new();var disk:=CylinderMesh.new()
			disk.top_radius=radius*0.55;disk.bottom_radius=radius*0.55;disk.height=0.24;disk.radial_segments=9
			hub.mesh=disk
			var rim:=StandardMaterial3D.new();rim.albedo_color=Color(0.61,0.65,0.67);rim.metallic=0.68
			hub.material_override=rim;hub.rotation.z=PI*0.5
			hub.position=Vector3(side*(half+0.035),radius,z)
			body_root.add_child(hub)
		# Front LED strips / rear lights, light details stand out on mobile.
		mesh_box(body_root,Vector3(width*0.22,0.10,0.07),Vector3(side*width*0.33,0.85,z_front-0.09),Color(0.96,0.94,0.79))
		mesh_box(body_root,Vector3(width*0.21,0.12,0.08),Vector3(side*width*0.32,0.83,z_rear+0.09),Color(0.83,0.065,0.05))
	# Detailing: door outlines, chrome handles, roof rails, sport spoiler,
	# differentiated front fascia and reflectors for the vehicle silhouettes.
	if not large:
		for side in [-1.0,1.0]:
			mesh_box(body_root,Vector3(0.04,0.52,0.025),Vector3(side*(half+0.013),0.86,0.02),paint.darkened(0.35),0.30)
			for z in [-0.55,0.93]:
				mesh_box(body_root,Vector3(0.065,0.065,0.30),Vector3(side*(half+0.032),1.04,z),Color(0.67,0.69,0.66),0.80)
		if class_index==2:
			mesh_box(body_root,Vector3(width*0.89,0.12,0.49),Vector3(0,1.03,length*0.45),paint.darkened(0.14),0.64)
			mesh_box(body_root,Vector3(width*0.73,0.085,0.28),Vector3(0,1.16,length*0.45),Color(0.07,0.09,0.10),0.23)
		if class_index==3:
			for side in [-1.0,1.0]:
				mesh_box(body_root,Vector3(0.075,0.065,length*0.48),Vector3(side*half*0.70,height+0.35,-0.01),Color(0.16,0.18,0.19),0.30)
	else:
		for side in [-1.0,1.0]:
			mesh_box(body_root,Vector3(0.24,0.13,1.2),Vector3(side*half*0.81,0.56,-length*0.18),Color(0.26,0.28,0.29),0.50)
	# License plates identify the front and rear as complete vehicle silhouettes.
	mesh_box(body_root,Vector3(0.46,0.13,0.03),Vector3(0,0.54,z_front-0.11),Color(0.87,0.90,0.86))
	mesh_box(body_root,Vector3(0.46,0.13,0.03),Vector3(0,0.54,z_rear+0.12),Color(0.87,0.90,0.86))

func drive(delta:float,throttle:float,braking:float,steering:float,weather_grip:float)->void:
	var info:Dictionary=CATALOG[class_index]
	var max_speed:float=float(info["max_speed"])*(1.0+engine_mod*0.02-0.02)
	var accel:float=float(info["acceleration"])*engine_mod
	var brake_force:float=float(info["brakes"])*brake_mod*weather_grip
	var damage_penalty:float=maxf(0.58,1.0-damage*0.003)
	# Grass is drivable, but cannot be used as a 205-km/h shortcut.
	var road_gap:float=Data.road_distance(Vector2(position.x,position.z))
	var city_road:bool=Data.city_type(Vector2(position.x,position.z))!="rural"
	offroad=road_gap>(17.0 if city_road else 15.5)
	surface_grip=0.64 if offroad else 1.0
	var surface_limit:float=23.0 if offroad else max_speed
	var allowed:float=minf(max_speed*damage_penalty,surface_limit)
	if throttle>0.05 and fuel>0.0:
		# Reduced acceleration at high speed makes the 0–100 and 100–200 phases distinct.
		var speed_ratio:float=clampf(absf(speed)/maxf(allowed,1.0),0.0,1.0)
		var power_curve:float=0.52*(1.0-0.74*speed_ratio)
		var drive_accel:float=accel*power_curve*weather_grip*surface_grip
		if absf(speed)<allowed:
			speed=move_toward(speed,allowed,drive_accel*throttle*delta)
	elif braking>0.05:
		if speed>0.7:
			speed=move_toward(speed,0.0,brake_force*braking*delta)
		else:
			speed=move_toward(speed,-6.0,accel*0.43*delta)
	else:
		speed=move_toward(speed,0.0,(1.4+absf(speed)*0.018+absf(speed)*absf(speed)*0.0009)*delta)
	if offroad and absf(speed)>surface_limit:
		speed=move_toward(speed,0.0,(4.0+absf(speed)*0.05)*delta)
	# Steering responds to speed, grip and vehicle length.
	var turn_factor:float=clampf(absf(speed)/7.0,0.0,1.0)
	var steer_rate:float=float(info["steering"])*weather_grip*surface_grip*turn_factor/(1.0+absf(speed)*0.018)
	yaw+=steering*steer_rate*delta*(1.0 if speed>=0.0 else -1.0)
	rotation.y=yaw
	var forward:=Vector3(-sin(yaw),0.0,-cos(yaw))
	position+=forward*speed*delta
	position.x=clampf(position.x,-Data.HALF_EXTENT+50.0,Data.HALF_EXTENT-50.0)
	position.z=clampf(position.z,-Data.HALF_EXTENT+50.0,Data.HALF_EXTENT-50.0)
	position.y=Data.height_at(position.x,position.z)+0.02
	var drive_m:float=absf(speed)*delta
	odometer+=drive_m*0.001
	fuel=maxf(0.0,fuel-drive_m*0.0012*float(info["usage"])*(1.22 if offroad else 1.0))
	if engine_sound!=null:
		engine_sound.pitch_scale=clampf(0.8+absf(speed)*0.022,0.7,2.0)
		engine_sound.volume_db=-14.0 if absf(speed)<1.0 else -7.0

func receive_impact(relative_speed:float)->void:
	var hit:float=clampf(relative_speed*1.8,2.0,26.0)
	damage=minf(100.0,damage+hit)
	speed*=0.32

func kmh()->int:
	return roundi(absf(speed)*3.6)
