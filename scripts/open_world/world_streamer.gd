extends Node3D
const Data = preload("res://scripts/open_world/world_data.gd")
var stream_radius:int=2
var chunks:Dictionary={}
var building_colliders:Dictionary={}
var pending:Array[Vector2i]=[]
var last_center:Vector2i=Vector2i(9999,9999)
var box_mesh:BoxMesh
var tree_mesh:SphereMesh
var foliage_material:StandardMaterial3D
var trunk_material:StandardMaterial3D
var building_materials:Array[StandardMaterial3D]=[]
var asphalt_material:StandardMaterial3D
var ground_material:StandardMaterial3D
var pavement_material:StandardMaterial3D
var paint_material:StandardMaterial3D
var roof_material:StandardMaterial3D
var lamp_material:StandardMaterial3D
var trunk_mesh:CylinderMesh

func _ready() -> void:
	box_mesh=BoxMesh.new(); box_mesh.size=Vector3.ONE
	tree_mesh=SphereMesh.new(); tree_mesh.radial_segments=7; tree_mesh.rings=4
	trunk_mesh=CylinderMesh.new(); trunk_mesh.radial_segments=5; trunk_mesh.rings=1
	foliage_material=make_mat(Color(0.14,0.29,0.14))
	trunk_material=make_mat(Color(0.29,0.20,0.12))
	asphalt_material=make_mat(Color(0.18,0.195,0.21))
	ground_material=make_mat(Color(0.24,0.39,0.23))
	pavement_material=make_mat(Color(0.43,0.43,0.42))
	paint_material=make_mat(Color(0.92,0.91,0.79))
	roof_material=make_mat(Color(0.26,0.20,0.20))
	lamp_material=make_mat(Color(0.86,0.79,0.55))
	for col in [Color(0.69,0.65,0.54),Color(0.61,0.67,0.69),Color(0.81,0.79,0.69),Color(0.56,0.59,0.61),Color(0.64,0.44,0.38)]:
		building_materials.append(make_mat(col))
	# Reuse real materials from the 61.0 project. Triplanar mapping permits
	# consistent world-scale texture repetition across batched geometry.
	for i in range(building_materials.size()):
		var facade_paths:Array[String]=[
			"res://assets/graphics51/facade_cream.png",
			"res://assets/graphics51/facade_brick.png",
			"res://assets/graphics51/facade_warm.png",
			"res://assets/graphics51/facade_cream.png",
			"res://assets/graphics51/facade_brick.png"
		]
		if ResourceLoader.exists(facade_paths[i]):
			building_materials[i].albedo_texture=load(facade_paths[i])
			building_materials[i].uv1_triplanar=true
			building_materials[i].uv1_scale=Vector3(0.045,0.045,0.045)
	var asphalt_path:String="res://assets/graphics50/asphalt_albedo.png"
	if ResourceLoader.exists(asphalt_path):
		asphalt_material.albedo_texture=load(asphalt_path)
		asphalt_material.uv1_triplanar=true
		asphalt_material.uv1_scale=Vector3(0.17,0.17,0.17)
	var grass_path:String="res://assets/graphics50/grass_albedo.png"
	if ResourceLoader.exists(grass_path):
		ground_material.albedo_texture=load(grass_path)
		ground_material.uv1_triplanar=true
		ground_material.uv1_scale=Vector3(0.065,0.065,0.065)
	var roof_path:String="res://assets/graphics51/roof_tiles.png"
	if ResourceLoader.exists(roof_path):
		roof_material.albedo_texture=load(roof_path)
		roof_material.uv1_triplanar=true
		roof_material.uv1_scale=Vector3(0.09,0.09,0.09)

func make_mat(c:Color) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=c
	m.roughness=0.88
	return m

func force_spawn(center:Vector3) -> void:
	update_stream(center)
	for i in range(12):
		if pending.is_empty(): break
		spawn_chunk(pending.pop_front())

func update_stream(player:Vector3) -> void:
	var cell:=Vector2i(roundi(player.x/Data.CHUNK_SIZE),roundi(player.z/Data.CHUNK_SIZE))
	if cell == last_center: return
	last_center=cell
	var desired:Dictionary={}
	var want:Array[Vector2i]=[]
	for dz in range(-stream_radius,stream_radius+1):
		for dx in range(-stream_radius,stream_radius+1):
			var key:=cell+Vector2i(dx,dz)
			var center:=Vector2(key.x*Data.CHUNK_SIZE,key.y*Data.CHUNK_SIZE)
			if Data.in_bounds(center):
				desired[key]=true
				if not chunks.has(key): want.append(key)
	want.sort_custom(func(a:Vector2i,b:Vector2i)->bool:
		return (a-cell).length_squared()<(b-cell).length_squared()
	)
	pending=want
	for key in chunks.keys():
		if not desired.has(key):
			chunks[key].queue_free()
			chunks.erase(key)
			building_colliders.erase(key)

func _process(_delta:float) -> void:
	if not pending.is_empty():
		spawn_chunk(pending.pop_front())

func spawn_chunk(key:Vector2i) -> void:
	if chunks.has(key): return
	var root:=Node3D.new()
	root.name="Region_%s_%s" % [key.x,key.y]
	root.position=Vector3(float(key.x)*Data.CHUNK_SIZE,0,float(key.y)*Data.CHUNK_SIZE)
	add_child(root)
	chunks[key]=root
	var rng:=RandomNumberGenerator.new()
	rng.seed=int(abs(key.x)*73856093+abs(key.y)*19349663+20261015)
	var p:=Vector2(root.position.x,root.position.z)
	var terrain_type:String=Data.city_type(p)
	make_terrain(root,p)
	make_roads(root,p,terrain_type)
	make_details(root,p,terrain_type,rng)
	make_landmark(root,p)

func make_terrain(root:Node3D,center:Vector2) -> void:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells:int=20
	var step:float=Data.CHUNK_SIZE/float(cells)
	for iz in range(cells):
		for ix in range(cells):
			var x:float=-200.0+ix*step
			var z:float=-200.0+iz*step
			var a:=Vector3(x,Data.height_at(center.x+x,center.y+z)-0.25,z)
			var b:=Vector3(x+step,Data.height_at(center.x+x+step,center.y+z)-0.25,z)
			var c:=Vector3(x,Data.height_at(center.x+x,center.y+z+step)-0.25,z+step)
			var d:=Vector3(x+step,Data.height_at(center.x+x+step,center.y+z+step)-0.25,z+step)
			st.add_vertex(a);st.add_vertex(c);st.add_vertex(b)
			st.add_vertex(b);st.add_vertex(c);st.add_vertex(d)
	st.generate_normals()
	var terrain:=MeshInstance3D.new(); terrain.mesh=st.commit()
	terrain.material_override=ground_material
	root.add_child(terrain)

func add_strip(st:SurfaceTool,center:Vector2,along_z:bool,offset:float,width:float) -> void:
	var half:float=width*0.5
	for i in range(20):
		var v0:float=-200.0+i*20.0
		var v1:float=v0+20.0
		var a:Vector3
		var b:Vector3
		var c:Vector3
		var d:Vector3
		if along_z:
			a=Vector3(offset-half,Data.height_at(center.x+offset-half,center.y+v0)+0.10,v0)
			b=Vector3(offset+half,Data.height_at(center.x+offset+half,center.y+v0)+0.10,v0)
			c=Vector3(offset-half,Data.height_at(center.x+offset-half,center.y+v1)+0.10,v1)
			d=Vector3(offset+half,Data.height_at(center.x+offset+half,center.y+v1)+0.10,v1)
		else:
			a=Vector3(v0,Data.height_at(center.x+v0,center.y+offset-half)+0.10,offset-half)
			b=Vector3(v0,Data.height_at(center.x+v0,center.y+offset+half)+0.10,offset+half)
			c=Vector3(v1,Data.height_at(center.x+v1,center.y+offset-half)+0.10,offset-half)
			d=Vector3(v1,Data.height_at(center.x+v1,center.y+offset+half)+0.10,offset+half)
		st.add_vertex(a); st.add_vertex(c); st.add_vertex(b)
		st.add_vertex(b); st.add_vertex(c); st.add_vertex(d)

func make_roads(root:Node3D,center:Vector2,kind:String) -> void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var main_width:float=27.0 if abs(center.x)<100.0 or abs(center.y)<100.0 else 13.0
	add_strip(st,center,true,0.0,main_width)
	add_strip(st,center,false,0.0,main_width)
	if kind != "rural":
		for d in [-100.0,100.0]:
			add_strip(st,center,true,d,9.0)
			add_strip(st,center,false,d,9.0)
	st.generate_normals()
	var road:=MeshInstance3D.new();road.mesh=st.commit();road.material_override=asphalt_material;root.add_child(road)
	# Paint uses a handful of instanced meshes per sector.
	var paint_xforms:Array[Transform3D]=[]
	for i in range(20):
		if i%2==0:
			var t:float=-192.0+float(i)*20.0
			paint_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.26,0.025,9.0)),Vector3(0,Data.height_at(center.x,center.y+t)+0.18,t)))
			paint_xforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(9.0,0.025,0.26)),Vector3(t,Data.height_at(center.x+t,center.y)+0.18,0)))
	add_batch(root,box_mesh,paint_material,paint_xforms)

func make_details(root:Node3D,center:Vector2,kind:String,rng:RandomNumberGenerator) -> void:
	var building_groups:Array=[]
	var building_rects:Array[Rect2]=[]
	for i in range(building_materials.size()):building_groups.append([])
	var roof_instances:Array[Transform3D]=[]
	var tree_crowns:Array[Transform3D]=[]
	var tree_trunks:Array[Transform3D]=[]
	var lamps:Array[Transform3D]=[]
	var lamp_heads:Array[Transform3D]=[]
	var building_count:int=24 if kind=="city" else (20 if kind=="industry" else (11 if kind=="village" else 2))
	var tree_count:int=9 if kind=="city" else (5 if kind=="industry" else (17 if kind=="village" else 55))
	for i in range(building_count):
		var x:float=rng.randf_range(-187,187)
		var z:float=rng.randf_range(-187,187)
		var pos:=Vector2(center.x+x,center.y+z)
		if Data.road_distance(pos)<25.0:continue
		var wide:float=rng.randf_range(12.0,24.0) if kind=="industry" else rng.randf_range(9.0,16.0)
		var dep:float=rng.randf_range(13.0,27.0)
		var h:float=rng.randf_range(9.0,40.0) if kind=="city" else (rng.randf_range(8.0,15.0) if kind=="industry" else rng.randf_range(5.0,12.0))
		var y:float=Data.height_at(pos.x,pos.y)
		var m:Transform3D=Transform3D(Basis.IDENTITY.scaled(Vector3(wide,h,dep)),Vector3(x,y+h*0.5,z))
		var idx:int=rng.randi_range(0,building_materials.size()-1)
		building_rects.append(Rect2(Vector2(pos.x-wide*0.5,pos.y-dep*0.5),Vector2(wide,dep)))
		building_groups[idx].append(m)
		roof_instances.append(Transform3D(Basis.IDENTITY.scaled(Vector3(wide+0.8,0.75,dep+0.8)),Vector3(x,y+h+0.3,z)))
	for i in range(tree_count):
		var x:float=rng.randf_range(-198,198)
		var z:float=rng.randf_range(-198,198)
		var pos:=Vector2(center.x+x,center.y+z)
		if Data.road_distance(pos)<19.0: continue
		var h:float=rng.randf_range(5.0,13.0)
		var y:float=Data.height_at(pos.x,pos.y)
		tree_trunks.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.48,h*0.55,0.48)),Vector3(x,y+h*0.275,z)))
		tree_crowns.append(Transform3D(Basis.IDENTITY.scaled(Vector3(h*0.27,h*0.44,h*0.27)),Vector3(x,y+h*0.77,z)))
	for i in range(building_materials.size()):
		add_batch(root,box_mesh,building_materials[i],building_groups[i])
	add_batch(root,box_mesh,roof_material,roof_instances)
	add_batch(root,trunk_mesh,trunk_material,tree_trunks)
	add_batch(root,tree_mesh,foliage_material,tree_crowns)
	# Highway lamp silhouettes; emissive lamps are material-based (no costly point lights).
	if kind!="rural":
		for i in range(-1,2):
			var z:float=i*155.0+40.0
			lamps.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.26,8.0,0.26)),Vector3(18.0,Data.height_at(center.x+18,center.y+z)+4.0,z)))
			lamp_heads.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.7,0.4,0.65)),Vector3(16.8,Data.height_at(center.x+18,center.y+z)+8.2,z)))
	building_colliders[Vector2i(roundi(center.x/Data.CHUNK_SIZE),roundi(center.y/Data.CHUNK_SIZE))]=building_rects
	add_batch(root,box_mesh,pavement_material,lamps)
	add_batch(root,box_mesh,lamp_material,lamp_heads)

func add_batch(root:Node3D,mesh:Mesh,mat:Material,transforms:Array) -> void:
	if transforms.is_empty():return
	var multi:=MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.mesh=mesh
	multi.instance_count=transforms.size()
	for i in range(transforms.size()):multi.set_instance_transform(i,transforms[i])
	var inst:=MultiMeshInstance3D.new()
	inst.multimesh=multi
	inst.material_override=mat
	root.add_child(inst)

func make_landmark(root:Node3D,center:Vector2)->void:
	# Five different city anchors survive streaming and improve regional identity.
	var city:Dictionary={}
	for candidate in Data.CITY_CENTERS:
		if center.distance_to(candidate["pos"])<20.0:
			city=candidate
			break
	if city.is_empty():return
	var kind:String=str(city["kind"])
	var name:String=str(city["name"])
	var y:float=Data.height_at(center.x+147.0,center.y+145.0)
	var landmark:=Node3D.new()
	landmark.position=Vector3(147.0,y,145.0)
	root.add_child(landmark)
	var facade:StandardMaterial3D=building_materials[1] if kind=="city" else building_materials[3]
	var main:=MeshInstance3D.new();var shape:=BoxMesh.new()
	shape.size=Vector3(38.0,74.0 if kind=="city" else 28.0,35.0)
	main.mesh=shape;main.material_override=facade;main.position.y=37.0 if kind=="city" else 14.0
	landmark.add_child(main)
	var accent:=MeshInstance3D.new();var trim:=BoxMesh.new()
	trim.size=Vector3(43.0,2.0,40.0)
	accent.mesh=trim;accent.material_override=roof_material
	accent.position.y=76.0 if kind=="city" else 30.0
	landmark.add_child(accent)
	if kind=="industry":
		for offset in [-35.0,35.0]:
			var silo:=MeshInstance3D.new();var cylinder:=CylinderMesh.new()
			cylinder.top_radius=10.0;cylinder.bottom_radius=10.0;cylinder.height=34.0;cylinder.radial_segments=10
			silo.mesh=cylinder;silo.position=Vector3(offset,17.0,-23.0)
			silo.material_override=pavement_material;landmark.add_child(silo)
	elif kind=="village":
		var spire:=MeshInstance3D.new();var cone:=CylinderMesh.new()
		cone.top_radius=0.0;cone.bottom_radius=8.0;cone.height=20.0;cone.radial_segments=4
		spire.mesh=cone;spire.position.y=42.0;spire.material_override=roof_material;landmark.add_child(spire)
	var board:=Label3D.new();board.text=name.to_upper()
	board.font_size=65;board.pixel_size=0.009
	board.position=Vector3(0,79.0 if kind=="city" else 37.0,0)
	board.modulate=Color(0.92,0.94,0.98)
	landmark.add_child(board)

func hit_static(world_position:Vector3)->bool:
	var key:=Vector2i(roundi(world_position.x/Data.CHUNK_SIZE),roundi(world_position.z/Data.CHUNK_SIZE))
	if not building_colliders.has(key):return false
	var p:=Vector2(world_position.x,world_position.z)
	for rectangle in building_colliders[key]:
		if rectangle.grow(1.6).has_point(p):return true
	return false
