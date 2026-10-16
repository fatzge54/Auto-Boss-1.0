extends Node3D
const Data=preload("res://scripts/open_world/world_data.gd")
const TRAFFIC_LIMIT:int=16
var active_count:int=12
var cars:Array[Node3D]=[]
var motion:Array[Vector3]=[]
var speeds:Array[float]=[]
var cruise_speeds:Array[float]=[]
var initialized:Array[bool]=[]
var light_clock:float=0.0
var rng:=RandomNumberGenerator.new()
var player
var collision_cooldown:float=0.0
var spawn_acc:float=0.0
var body_mesh:BoxMesh
var cabin_mesh:BoxMesh
var body_colors:Array[Material]=[]
var glass_mat:StandardMaterial3D
var tire_mat:StandardMaterial3D

func _ready()->void:
	rng.seed=20261015
	body_mesh=BoxMesh.new();body_mesh.size=Vector3(1.85,0.75,4.1)
	cabin_mesh=BoxMesh.new();cabin_mesh.size=Vector3(1.55,0.58,2.4)
	for col in [Color(0.7,0.76,0.75),Color(0.14,0.19,0.23),Color(0.45,0.13,0.12),Color(0.30,0.38,0.65),Color(0.69,0.57,0.37)]:
		var mat:=StandardMaterial3D.new();mat.albedo_color=col;mat.metallic=0.35;mat.roughness=0.52
		body_colors.append(mat)
	glass_mat=StandardMaterial3D.new();glass_mat.albedo_color=Color(0.12,0.22,0.28)
	tire_mat=StandardMaterial3D.new();tire_mat.albedo_color=Color(0.07,0.08,0.08)
	for i in range(TRAFFIC_LIMIT):
		var a:=make_car(i)
		cars.append(a);motion.append(Vector3.FORWARD);speeds.append(0.0);cruise_speeds.append(0.0);initialized.append(false)

func make_car(index:int)->Node3D:
	var root:=Node3D.new();add_child(root)
	var body:=MeshInstance3D.new();body.mesh=body_mesh
	body.material_override=body_colors[index%body_colors.size()];body.position.y=0.68;root.add_child(body)
	var glass:=MeshInstance3D.new();glass.mesh=cabin_mesh;glass.material_override=glass_mat
	glass.position=Vector3(0,1.24,0.18);root.add_child(glass)
	# Headlights, tail lights and bumper details are visible even on small screens.
	var light_front:=StandardMaterial3D.new();light_front.albedo_color=Color(0.97,0.92,0.72)
	var light_rear:=StandardMaterial3D.new();light_rear.albedo_color=Color(0.89,0.08,0.055)
	var bumper_mat:=StandardMaterial3D.new();bumper_mat.albedo_color=Color(0.12,0.14,0.16)
	for side in [-1.0,1.0]:
		for at_z in [-2.11,2.11]:
			var light:=MeshInstance3D.new();var light_box:=BoxMesh.new()
			light_box.size=Vector3(0.40,0.11,0.065)
			light.mesh=light_box;light.material_override=light_front if at_z<0.0 else light_rear
			light.position=Vector3(side*0.55,0.84,at_z)
			root.add_child(light)
	for at_z in [-2.12,2.12]:
		var bumper:=MeshInstance3D.new();var bumper_box:=BoxMesh.new()
		bumper_box.size=Vector3(1.65,0.15,0.11)
		bumper.mesh=bumper_box;bumper.material_override=bumper_mat
		bumper.position=Vector3(0,0.50,at_z)
		root.add_child(bumper)
	for side in [-1.0,1.0]:
		for z in [-1.28,1.32]:
			var wheel:=MeshInstance3D.new();var mesh:=CylinderMesh.new()
			mesh.top_radius=0.30;mesh.bottom_radius=0.30;mesh.height=0.16;mesh.radial_segments=7
			wheel.mesh=mesh;wheel.material_override=tire_mat;wheel.rotation.z=PI*0.5
			wheel.position=Vector3(side*0.9,0.32,z);root.add_child(wheel)
	return root

func update_movement(delta:float)->void:
	if player==null:return
	collision_cooldown=maxf(0.0,collision_cooldown-delta)
	light_clock+=delta
	for i in range(cars.size()):
		if i>=active_count:
			cars[i].visible=false
			continue
		var t:=cars[i]
		t.visible=true
		if not initialized[i] or t.position.distance_to(player.position)>680.0:
			reset_car(i)
		else:
			# Simplified virtual signals and vehicle following: far cheaper than
			# full physics for a phone, but traffic no longer crosses every junction
			# at full speed without ever yielding.
			var along_x:bool=absf(motion[i].x)>0.5
			var location:float=t.position.x if along_x else t.position.z
			var direction:float=motion[i].x if along_x else motion[i].z
			var to_junction:float=fposmod(-location*direction,Data.CHUNK_SIZE)
			var phase:float=fposmod(light_clock,36.0)
			var green:bool=(phase<18.0) if along_x else (phase>=18.0)
			# Traffic lights exist in towns, not on the rural through-roads.
			var has_signal:bool=Data.city_type(Vector2(t.position.x,t.position.z))!="rural"
			var stop:bool=has_signal and not green and to_junction<37.0 and to_junction>6.0
			for other in range(cars.size()):
				if other==i or other>=active_count or not initialized[other]:continue
				if motion[i].dot(motion[other])<0.92:continue
				var separation:Vector3=cars[other].position-t.position
				var ahead:float=separation.dot(motion[i])
				var lateral:float=(separation-motion[i]*ahead).length()
				if ahead>0.0 and ahead<22.0 and lateral<2.7:
					stop=true
					break
			# AI also yields to a stopped player vehicle in the same lane.
			var to_player:Vector3=player.position-t.position
			var player_ahead:float=to_player.dot(motion[i])
			if player_ahead>0.0 and player_ahead<24.0 and (to_player-motion[i]*player_ahead).length()<2.7:
				stop=true
			speeds[i]=move_toward(speeds[i],0.0 if stop else cruise_speeds[i],delta*(5.5 if stop else 2.5))
			t.position+=motion[i]*speeds[i]*delta
			t.position.y=Data.height_at(t.position.x,t.position.z)+0.04
			if absf(t.position.x)>Data.HALF_EXTENT or absf(t.position.z)>Data.HALF_EXTENT:reset_car(i)
		if collision_cooldown<=0.0 and t.position.distance_to(player.position)<2.65:
			if player.has_method("receive_impact"):
				# Use relative velocity vectors: head-on impacts must not cancel out.
				var player_velocity:=Vector3(-sin(player.yaw),0.0,-cos(player.yaw))*player.speed
				var relative_speed:float=(player_velocity-motion[i]*speeds[i]).length()
				player.receive_impact(relative_speed)
				collision_cooldown=1.7

func reset_car(i:int)->void:
	var t:=cars[i]
	var horizontal:bool=false
	var direction:float=1.0
	var road_x:float=roundf(player.position.x/Data.CHUNK_SIZE)*Data.CHUNK_SIZE
	var road_z:float=roundf(player.position.z/Data.CHUNK_SIZE)*Data.CHUNK_SIZE
	for attempt in range(12):
		horizontal=rng.randf()<0.50
		direction=-1.0 if rng.randf()<0.5 else 1.0
		var offset:float=rng.randf_range(135.0,520.0)
		if rng.randf()<0.5:offset=-offset
		if horizontal:
			t.position=Vector3(player.position.x+offset,0,road_z+(4.0 if direction>0.0 else -4.0))
			motion[i]=Vector3(direction,0,0)
			t.rotation.y=-PI*0.5*direction
		else:
			t.position=Vector3(road_x+(4.0 if direction>0.0 else -4.0),0,player.position.z+offset)
			motion[i]=Vector3(0,0,direction)
			t.rotation.y=0.0 if direction<0.0 else PI
		var safe:bool=true
		for j in range(cars.size()):
			if i==j or j>=active_count or not initialized[j]:continue
			if cars[j].position.distance_to(t.position)<20.0:
				safe=false
				break
		if safe:break
	t.position.y=Data.height_at(t.position.x,t.position.z)
	var urban:bool=Data.city_type(Vector2(t.position.x,t.position.z))!="rural"
	cruise_speeds[i]=rng.randf_range(8.0,16.0) if urban else rng.randf_range(14.0,23.0)
	speeds[i]=cruise_speeds[i]
	initialized[i]=true
