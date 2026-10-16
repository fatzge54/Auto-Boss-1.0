extends Node3D
## AUTO BOSS 71.9: compact street-facing German city blocks, shopfronts and entries.
## All repeatable facade parts are MultiMesh batches; no per-window nodes.
## The blocks belong to their parent streamed sector and unload with it.
const Data = preload("res://scripts/open_world/world_data.gd")

var parts:Dictionary={}
var materials:Dictionary={}
var cube:BoxMesh
var gable:ArrayMesh
var twig:CylinderMesh
var crown:SphereMesh
var detail_level:int=1

func material(color:Color)->StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=0.88
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	return m

func _setup()->void:
	cube=BoxMesh.new()
	cube.size=Vector3.ONE
	gable=_make_gable()
	twig=CylinderMesh.new()
	twig.top_radius=0.6
	twig.bottom_radius=0.8
	twig.height=1.0
	twig.radial_segments=6
	crown=SphereMesh.new()
	crown.radial_segments=7
	crown.rings=4
	materials={
		"facade_0":material(Color(0.75,0.71,0.61)),
		"facade_1":material(Color(0.62,0.67,0.66)),
		"facade_2":material(Color(0.69,0.51,0.42)),
		"facade_3":material(Color(0.78,0.75,0.66)),
		"facade_4":material(Color(0.55,0.62,0.65)),
		"facade_5":material(Color(0.66,0.58,0.49)),
		"facade_6":material(Color(0.76,0.73,0.68)),
		"facade_7":material(Color(0.52,0.59,0.58)),
		"base":material(Color(0.40,0.40,0.39)),
		"roof":material(Color(0.28,0.24,0.25)),
		"roof_red":material(Color(0.47,0.26,0.22)),
		"windows":material(Color(0.18,0.29,0.35)),
		"glass_shop":material(Color(0.21,0.37,0.40)),
		"shop_sign":material(Color(0.17,0.27,0.33)),
		"shop_trim":material(Color(0.78,0.68,0.44)),
		"flower":material(Color(0.46,0.26,0.22)),
		"frames":material(Color(0.77,0.77,0.70)),
		"shutters":material(Color(0.29,0.34,0.31)),
		"doors":material(Color(0.28,0.24,0.22)),
		"awning":material(Color(0.37,0.47,0.43)),
		"paving":material(Color(0.46,0.47,0.44)),
		"hedge":material(Color(0.23,0.40,0.23)),
		"tree":material(Color(0.24,0.44,0.26)),
		"tree_bark":material(Color(0.33,0.25,0.18)),
		"metal":material(Color(0.22,0.25,0.27)),
		"light":material(Color(0.94,0.83,0.57))
	}
	var facades:Array[String]=[
		"res://assets/graphics51/facade_cream.png",
		"res://assets/graphics51/facade_warm.png",
		"res://assets/graphics51/facade_brick.png",
		"res://assets/graphics51/facade_cream.png",
		"res://assets/graphics51/facade_warm.png",
		"res://assets/graphics51/facade_brick.png",
		"res://assets/graphics51/facade_cream.png",
		"res://assets/graphics51/facade_warm.png"
	]
	for i in range(8):
		var m:StandardMaterial3D=materials["facade_%d"%i]
		if ResourceLoader.exists(facades[i]):
			m.albedo_texture=load(facades[i])
			m.uv1_triplanar=true
			m.uv1_scale=Vector3(0.06,0.06,0.06)
	var roof_tex:String="res://assets/graphics51/roof_tiles.png"
	if ResourceLoader.exists(roof_tex):
		for k in ["roof","roof_red"]:
			var rm:StandardMaterial3D=materials[k]
			rm.albedo_texture=load(roof_tex)
			rm.uv1_triplanar=true
			rm.uv1_scale=Vector3(0.10,0.10,0.10)
	var glass:StandardMaterial3D=materials["windows"]
	glass.metallic=0.28
	glass.roughness=0.32
	var storefront:StandardMaterial3D=materials["glass_shop"]
	storefront.metallic=0.25
	storefront.roughness=0.28
	var warm:StandardMaterial3D=materials["light"]
	warm.emission_enabled=true
	warm.emission=Color(0.76,0.61,0.32)
	warm.emission_energy_multiplier=0.75

func _make_gable()->ArrayMesh:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a:=Vector3(-0.5,0.0,-0.5)
	var b:=Vector3(0.5,0.0,-0.5)
	var c:=Vector3(-0.5,0.0,0.5)
	var d:=Vector3(0.5,0.0,0.5)
	var e:=Vector3(0.0,0.36,-0.5)
	var f:=Vector3(0.0,0.36,0.5)
	for point in [a,c,f,a,f,e,e,f,d,e,d,b,a,e,b,c,d,f]:
		st.add_vertex(point)
	st.generate_normals()
	return st.commit()

func _part(bucket:String,position:Vector3,size:Vector3,yaw:float=0.0)->void:
	if not parts.has(bucket):parts[bucket]=[]
	var rotation:=Basis(Vector3.UP,yaw)
	parts[bucket].append(Transform3D(rotation * Basis.IDENTITY.scaled(size),position))

func _local(bucket:String,origin:Vector3,local_pos:Vector3,size:Vector3,yaw:float)->void:
	var rotation:=Basis(Vector3.UP,yaw)
	_part(bucket,origin+rotation*local_pos,size,yaw)

func _emit_batches()->void:
	for bucket in parts.keys():
		var transforms:Array=parts[bucket]
		if transforms.is_empty():continue
		var multimesh:=MultiMesh.new()
		multimesh.transform_format=MultiMesh.TRANSFORM_3D
		var source_mesh:Mesh=cube
		if bucket=="gable":source_mesh=gable
		if bucket=="tree_bark":source_mesh=twig
		if bucket=="tree":source_mesh=crown
		multimesh.mesh=source_mesh
		multimesh.instance_count=transforms.size()
		for i in range(transforms.size()):
			multimesh.set_instance_transform(i,transforms[i])
		var batch:=MultiMeshInstance3D.new()
		batch.name="Module_"+str(bucket)
		batch.multimesh=multimesh
		batch.material_override=materials["roof"] if bucket=="gable" else materials[bucket]
		if bucket=="light":batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(batch)

func _building(world_center:Vector2,x:float,z:float,w:float,d:float,floors:int,style:int,yaw:float,shop:bool,rng:RandomNumberGenerator)->Rect2:
	var at:=Vector2(world_center.x+x,world_center.y+z)
	var ground:float=Data.height_at(at.x,at.y)
	var height:float=float(floors)*3.22
	var org:=Vector3(x,ground,z)
	var rot:=Basis(Vector3.UP,yaw)
	var x_axis:Vector3=rot*Vector3.RIGHT
	var z_axis:Vector3=rot*Vector3.BACK
	var occupancy:Vector2=Vector2(absf(x_axis.x)*w+absf(z_axis.x)*d,absf(x_axis.z)*w+absf(z_axis.z)*d)
	# Foundation below the sloped ground avoids the floating-building effect.
	_local("base",org,Vector3(0,0.02,0),Vector3(w+0.4,2.2,d+0.4),yaw)
	_local("facade_%d"%style,org,Vector3(0,height*0.5,0),Vector3(w,height,d),yaw)
	_local("base",org,Vector3(0,0.60,-d*0.5-0.085),Vector3(w,1.2,0.18),yaw)
	var pitched:bool=(style%3!=1 and floors<=5)
	if pitched:
		_local("gable",org,Vector3(0,height+0.03,0),Vector3(w+1.4,5.5,d+1.4),yaw)
	else:
		_local("roof",org,Vector3(0,height+0.38,0),Vector3(w+1.0,0.76,d+1.0),yaw)
		_local("metal",org,Vector3(0,height+0.9,d*0.27),Vector3(1.6,0.75,1.9),yaw)
	# Four facade bays / one repeated floor module, from an actual shared 3D kit.
	var columns:int=3 if w<24.0 else 4
	var bay_width:float=w/float(columns)
	for floor_index in range(1,floors):
		var y:float=float(floor_index)*3.22+1.54
		for col in range(columns):
			var xx:float=(float(col)+0.5)*bay_width-w*0.5
			for face in [-1.0,1.0]:
				var face_z:float=face*(d*0.5+0.065)
				_local("windows",org,Vector3(xx,y,face_z),Vector3(1.78,1.61,0.14),yaw)
				_local("frames",org,Vector3(xx,y-0.88,face_z+face*0.11),Vector3(2.05,0.15,0.34),yaw)
				_local("frames",org,Vector3(xx,y+0.89,face_z),Vector3(2.04,0.11,0.24),yaw)
				if detail_level>0:
					for side in [-1.0,1.0]:
						_local("frames",org,Vector3(xx+side*0.94,y,face_z),Vector3(0.12,1.70,0.17),yaw)
		if detail_level>0 and floors>3 and floor_index%2==0:
			_local("paving",org,Vector3(0,y-1.04,-d*0.5-0.67),Vector3(w*0.42,0.16,1.26),yaw)
			_local("metal",org,Vector3(0,y-0.35,-d*0.5-1.25),Vector3(w*0.42,0.82,0.10),yaw)
	# Side-wall windows help buildings look finished from perpendicular streets.
	if detail_level>0:
		for floor_index in range(1,floors):
			for sx in [-1.0,1.0]:
				for sz in [-d*0.23,d*0.23]:
					_local("windows",org,Vector3(sx*(w*0.5+0.07),float(floor_index)*3.22+1.54,sz),Vector3(0.13,1.42,1.65),yaw)
	# The shop module is wider and glazed; residential variants use a framed door.
	if shop:
		_local("glass_shop",org,Vector3(0,1.70,-d*0.5-0.12),Vector3(w*0.74,2.58,0.18),yaw)
		_local("awning",org,Vector3(0,3.25,-d*0.5-0.93),Vector3(w*0.84,0.18,1.65),yaw)
		for x_bar in [-w*0.27,0.0,w*0.27]:
			_local("frames",org,Vector3(x_bar,1.70,-d*0.5-0.23),Vector3(0.13,2.5,0.18),yaw)
	else:
		_local("doors",org,Vector3(0,1.45,-d*0.5-0.11),Vector3(2.12,2.70,0.18),yaw)
		_local("frames",org,Vector3(0,2.84,-d*0.5-0.21),Vector3(2.48,0.19,0.23),yaw)
	# A compact pedestrian apron interrupts the monotonous green roadside.
	# Width stays inside the validated building lot; no overlap with asphalt.
	_local("paving",org,Vector3(0,0.10,-d*0.5-1.55),Vector3(w+1.6,0.16,2.85),yaw)
	_local("paving",org,Vector3(0,0.15,-d*0.5-1.16),Vector3(w*0.58,0.20,2.0),yaw)
	_local("frames",org,Vector3(0,3.40,-d*0.5-0.10),Vector3(w,0.16,0.2),yaw)
	if shop:
		# Distinct shop signs, entrance and fascia. No expensive decals/text nodes.
		_local("shop_sign",org,Vector3(0,3.05,-d*0.5-0.31),Vector3(w*0.68,0.46,0.15),yaw)
		_local("shop_trim",org,Vector3(0,3.38,-d*0.5-0.34),Vector3(w*0.70,0.08,0.18),yaw)
		_local("frames",org,Vector3(0,1.56,-d*0.5-0.31),Vector3(1.24,2.38,0.22),yaw)
	elif detail_level>0:
		# Low garden beds make residential entrances look inhabited.
		for side in [-1.0,1.0]:
			_local("flower",org,Vector3(side*w*0.32,0.33,-d*0.5-1.90),Vector3(w*0.20,0.47,0.66),yaw)
			_local("hedge",org,Vector3(side*w*0.32,0.73,-d*0.5-1.90),Vector3(w*0.18,0.40,0.55),yaw)
	return Rect2(at-occupancy*0.5,occupancy)

func _courtyard(world_center:Vector2,x:float,z:float,rng:RandomNumberGenerator)->void:
	var pos:=Vector2(world_center.x+x,world_center.y+z)
	if Data.pavement_clearance(pos)<8.0:return
	var y:float=Data.height_at(pos.x,pos.y)
	_part("paving",Vector3(x,y+0.04,z),Vector3(5.2,0.07,5.2))
	for sx in [-1.0,1.0]:
		_part("tree_bark",Vector3(x+sx*3.1,y+1.7,z),Vector3(0.44,3.4,0.44))
		_part("tree",Vector3(x+sx*3.1,y+4.0,z),Vector3(3.1,4.0,3.1))
	_part("metal",Vector3(x,y+0.62,z+2.4),Vector3(2.3,0.20,0.7))
	_part("hedge",Vector3(x,y+0.65,z-2.3),Vector3(4.8,1.2,0.65))

func _street_furniture(world_center:Vector2)->void:
	# Repeated modules with deterministic placement on verges, not on the asphalt.
	for sign in [-1.0,1.0]:
		for idx in range(6):
			var z:float=-174.0+float(idx)*66.0
			var x:float=sign*22.0
			var p:=Vector2(world_center.x+x,world_center.y+z)
			if Data.pavement_clearance(p)<4.0:continue
			var y:float=Data.height_at(p.x,p.y)
			_part("metal",Vector3(x,y+3.1,z),Vector3(0.20,6.2,0.20))
			_part("light",Vector3(x-0.64,y+6.18,z),Vector3(1.45,0.25,0.52))
			if idx%2==0:
				_part("hedge",Vector3(x+sign*2.2,y+0.55,z),Vector3(1.35,1.1,3.6))

func build(world_center:Vector2,quality:int)->Array[Rect2]:
	_setup()
	detail_level=quality
	var colliders:Array[Rect2]=[]
	var rng:=RandomNumberGenerator.new()
	var cell_x:int=roundi(world_center.x/Data.CHUNK_SIZE)
	var cell_z:int=roundi(world_center.y/Data.CHUNK_SIZE)
	rng.seed=int(20261016+cell_x*92321+cell_z*63719)
	# 71.9: compact but not uniform streets. Lots fill both sides of the
	# two intersecting local grids; 20-30 m between house centers instead of
	# hundred-meter grass fields. Gaps intentionally become tiny courtyards.
	# Sector-border lot coordinates are mirrored: no houses cross chunk edges.
	var positions:Array[Vector2]=[]
	var rows:Array[float]=[-171.0,-147.0,-69.0,-43.0,43.0,69.0,147.0,171.0]
	for x_slot in rows:
		for z_slot in rows:
			positions.append(Vector2(x_slot,z_slot))
	for i in range(positions.size()):
		var p:Vector2=positions[i]
		# A central existing landmark in Lindenfurt remains unobstructed.
		if cell_x==0 and cell_z==0 and p.x>110.0 and p.y>110.0:continue
		# Deterministic pockets of parks, but no huge vacant squares.
		if posmod(i+cell_x*7+cell_z*3,3)==0:continue
		if detail_level==0 and posmod(i+cell_x*2-cell_z,4)==0:continue
		var w:float=rng.randf_range(12.0,17.2)
		var d:float=rng.randf_range(12.0,17.0)
		var floors:int=rng.randi_range(2,5)
		if posmod(i+cell_x*2+cell_z,14)==0:floors=6
		var style:int=posmod(i+cell_x*2+cell_z*3,8)
		# Rotate shopfront/entrance toward the nearest actual main/local road.
		# Local roads are at world coordinates chunk-center +/- 100 m.
		var road_x:float=0.0 if absf(p.x)<50.0 else (100.0 if p.x>0.0 else -100.0)
		var road_z:float=0.0 if absf(p.y)<50.0 else (100.0 if p.y>0.0 else -100.0)
		var dist_x:float=absf(p.x-road_x)
		var dist_z:float=absf(p.y-road_z)
		var yaw:float=0.0
		if dist_x<dist_z:
			yaw=PI*0.5 if p.x>road_x else -PI*0.5
		else:
			yaw=0.0 if p.y>road_z else PI
		var center_p:=Vector2(world_center.x+p.x,world_center.y+p.y)
		var footprint_half:float=maxf(w,d)*0.5+3.0
		if Data.pavement_clearance(center_p)<footprint_half:continue
		var occupied_size:Vector2=Vector2(w,d) if is_zero_approx(yaw) or is_equal_approx(absf(yaw),PI) else Vector2(d,w)
		var candidate:=Rect2(center_p-occupied_size*0.5,occupied_size)
		# Validate corners too: a lot can straddle an angled road margin.
		var road_blocked:bool=false
		for corner in [Vector2(-occupied_size.x*0.5,-occupied_size.y*0.5),Vector2(occupied_size.x*0.5,-occupied_size.y*0.5),Vector2(-occupied_size.x*0.5,occupied_size.y*0.5),Vector2(occupied_size.x*0.5,occupied_size.y*0.5)]:
			if Data.pavement_clearance(center_p+corner)<2.5:
				road_blocked=true
				break
		if road_blocked:continue
		var blocked:bool=false
		for occupied in colliders:
			if occupied.grow(2.2).intersects(candidate):
				blocked=true
				break
		if blocked:continue
		var rect:Rect2=_building(world_center,p.x,p.y,w,d,floors,style,yaw,posmod(i,5)==0,rng)
		colliders.append(rect)
	for park_x in [-150.0,-55.0,55.0,150.0]:
		for park_z in [-151.0,-58.0,58.0,151.0]:
			if cell_x==0 and cell_z==0 and park_x>100.0 and park_z>100.0:continue
			var spot:=Vector2(world_center.x+park_x,world_center.y+park_z)
			var empty:bool=true
			for r in colliders:
				if r.grow(8.0).has_point(spot):empty=false
			if empty:_courtyard(world_center,park_x,park_z,rng)
	_street_furniture(world_center)
	_emit_batches()
	return colliders
