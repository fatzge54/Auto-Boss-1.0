extends Node3D
const Data=preload("res://scripts/open_world/world_data.gd")
const TRAFFIC_LIMIT:int=16
var active_count:int=12
var cars:Array[Node3D]=[]
var motion:Array[Vector3]=[]
var speeds:Array[float]=[]
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
		cars.append(a);motion.append(Vector3.FORWARD);speeds.append(0.0)

func make_car(index:int)->Node3D:
	var root:=Node3D.new();add_child(root)
	var body:=MeshInstance3D.new();body.mesh=body_mesh
	body.material_override=body_colors[index%body_colors.size()];body.position.y=0.68;root.add_child(body)
	var glass:=MeshInstance3D.new();glass.mesh=cabin_mesh;glass.material_override=glass_mat
	glass.position=Vector3(0,1.24,0.18);root.add_child(glass)
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
	for i in range(cars.size()):
		if i>=active_count:
			cars[i].visible=false
			continue
		var t:=cars[i]
		t.visible=true
		if t.position.distance_to(player.position)>680.0 or speeds[i]==0.0:
			reset_car(i)
		else:
			t.position+=motion[i]*speeds[i]*delta
			t.position.y=Data.height_at(t.position.x,t.position.z)+0.04
			if absf(t.position.x)>Data.HALF_EXTENT or absf(t.position.z)>Data.HALF_EXTENT:reset_car(i)
		if collision_cooldown<=0.0 and t.position.distance_to(player.position)<2.65:
			if player.has_method("receive_impact"):
				player.receive_impact(absf(player.speed-speeds[i]))
				collision_cooldown=1.7

func reset_car(i:int)->void:
	var t:=cars[i]
	var horizontal:bool=rng.randf()<0.50
	var direction:float=-1.0 if rng.randf()<0.5 else 1.0
	var offset:float=rng.randf_range(-520.0,520.0)
	var road_x:float=roundf(player.position.x/Data.CHUNK_SIZE)*Data.CHUNK_SIZE
	var road_z:float=roundf(player.position.z/Data.CHUNK_SIZE)*Data.CHUNK_SIZE
	if horizontal:
		t.position=Vector3(player.position.x+offset,0,road_z+(4.0 if direction>0.0 else -4.0))
		motion[i]=Vector3(direction,0,0)
		t.rotation.y=-PI*0.5*direction
	else:
		t.position=Vector3(road_x+(4.0 if direction>0.0 else -4.0),0,player.position.z+offset)
		motion[i]=Vector3(0,0,direction)
		t.rotation.y=0.0 if direction<0.0 else PI
	t.position.y=Data.height_at(t.position.x,t.position.z)
	speeds[i]=rng.randf_range(11.0,23.0)
