extends Node3D
const Data = preload("res://scripts/open_world/world_data.gd")
var stream_radius:int=2
var detail_level:int=1
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
var field_material:StandardMaterial3D
var soil_material:StandardMaterial3D
var gravel_material:StandardMaterial3D
var forest_material:StandardMaterial3D
var window_material:StandardMaterial3D
var dark_material:StandardMaterial3D
var railing_material:StandardMaterial3D
var bark_material:StandardMaterial3D
var hedge_material:StandardMaterial3D
var crop_material:StandardMaterial3D
var wheelhouse_material:StandardMaterial3D
var roof_gable:Mesh
var road_sign_mat:StandardMaterial3D
var grass_detail_mat:StandardMaterial3D
var road_marking_red:StandardMaterial3D
var metal_dark_mat:StandardMaterial3D
var cobble_mat:StandardMaterial3D
var urban_grass:StandardMaterial3D
var field_grass:StandardMaterial3D
var pine_grass:StandardMaterial3D
var signal_h_red_mat:StandardMaterial3D
var signal_h_green_mat:StandardMaterial3D
var signal_v_red_mat:StandardMaterial3D
var signal_v_green_mat:StandardMaterial3D
var hay_mat:StandardMaterial3D
var freight_blue_mat:StandardMaterial3D
var freight_red_mat:StandardMaterial3D
var bale_mesh:CylinderMesh

func _ready() -> void:
	box_mesh=BoxMesh.new(); box_mesh.size=Vector3.ONE
	roof_gable=make_gable_mesh()
	tree_mesh=SphereMesh.new(); tree_mesh.radial_segments=7; tree_mesh.rings=4
	trunk_mesh=CylinderMesh.new(); trunk_mesh.radial_segments=5; trunk_mesh.rings=1
	bale_mesh=CylinderMesh.new();bale_mesh.top_radius=0.85;bale_mesh.bottom_radius=0.85;bale_mesh.height=1.55;bale_mesh.radial_segments=10
	hay_mat=make_mat(Color(0.68,0.56,0.26))
	freight_blue_mat=make_mat(Color(0.12,0.33,0.42))
	freight_red_mat=make_mat(Color(0.52,0.20,0.15))
	foliage_material=make_mat(Color(0.20,0.39,0.21))
	field_material=make_mat(Color(0.43,0.50,0.23))
	soil_material=make_mat(Color(0.38,0.31,0.23))
	forest_material=make_mat(Color(0.12,0.27,0.16))
	gravel_material=make_mat(Color(0.34,0.34,0.32))
	window_material=make_mat(Color(0.16,0.28,0.33))
	window_material.metallic=0.30
	window_material.roughness=0.29
	dark_material=make_mat(Color(0.12,0.13,0.13))
	railing_material=make_mat(Color(0.61,0.64,0.63))
	bark_material=make_mat(Color(0.25,0.19,0.12))
	hedge_material=make_mat(Color(0.15,0.35,0.16))
	crop_material=make_mat(Color(0.52,0.57,0.23))
	wheelhouse_material=make_mat(Color(0.25,0.29,0.28))
	road_sign_mat=make_mat(Color(0.08,0.28,0.50))
	grass_detail_mat=make_mat(Color(0.32,0.47,0.22))
	road_marking_red=make_mat(Color(0.48,0.14,0.11))
	metal_dark_mat=make_mat(Color(0.17,0.20,0.22))
	cobble_mat=make_mat(Color(0.38,0.39,0.37))
	urban_grass=make_mat(Color(0.43,0.52,0.39))
	field_grass=make_mat(Color(0.48,0.57,0.30))
	pine_grass=make_mat(Color(0.26,0.42,0.31))
	signal_h_red_mat=make_mat(Color(0.7,0.04,0.02))
	signal_h_green_mat=make_mat(Color(0.02,0.55,0.12))
	signal_v_red_mat=make_mat(Color(0.7,0.04,0.02))
	signal_v_green_mat=make_mat(Color(0.02,0.55,0.12))
	for mat in [signal_h_red_mat,signal_h_green_mat,signal_v_red_mat,signal_v_green_mat]:
		mat.emission_enabled=true
		mat.emission_energy_multiplier=1.8
	trunk_material=make_mat(Color(0.29,0.20,0.12))
	asphalt_material=make_mat(Color(0.38,0.40,0.41))
	ground_material=make_mat(Color(0.45,0.63,0.39))
	pavement_material=make_mat(Color(0.52,0.52,0.48))
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
		asphalt_material.uv1_scale=Vector3(0.14,0.14,0.14)
	var grass_path:String="res://assets/graphics50/grass_albedo.png"
	if ResourceLoader.exists(grass_path):
		ground_material.albedo_texture=load(grass_path)
		ground_material.uv1_triplanar=true
		ground_material.uv1_scale=Vector3(0.065,0.065,0.065)
		for region_mat in [urban_grass,field_grass,pine_grass]:
			region_mat.albedo_texture=ground_material.albedo_texture
			region_mat.uv1_triplanar=true
			region_mat.uv1_scale=Vector3(0.065,0.065,0.065)
	var roof_path:String="res://assets/graphics51/roof_tiles.png"
	if ResourceLoader.exists(roof_path):
		roof_material.albedo_texture=load(roof_path)
		roof_material.uv1_triplanar=true
		roof_material.uv1_scale=Vector3(0.09,0.09,0.09)

func update_visual_weather(daylight:float,rain:bool,signal_seconds:float)->void:
	# One material update affects every MultiMesh without per-building light objects.
	var night:float=1.0-clampf(daylight*1.6,0.0,1.0)
	window_material.albedo_color=Color(0.15,0.28,0.34).lerp(Color(0.82,0.61,0.31),night*0.76)
	window_material.emission_enabled=night>0.05
	window_material.emission=Color(0.74,0.54,0.25)*night
	window_material.emission_energy_multiplier=0.95
	lamp_material.emission_enabled=night>0.12
	lamp_material.emission=Color(1.0,0.79,0.43)*night
	lamp_material.emission_energy_multiplier=2.0
	asphalt_material.roughness=0.49 if rain else 0.92
	asphalt_material.metallic=0.035 if rain else 0.0
	var horizontal_green:bool=fposmod(signal_seconds,36.0)<18.0
	set_signal_color(signal_h_green_mat,Color(0.03,0.78,0.17),horizontal_green)
	set_signal_color(signal_h_red_mat,Color(0.88,0.05,0.02),not horizontal_green)
	set_signal_color(signal_v_green_mat,Color(0.03,0.78,0.17),not horizontal_green)
	set_signal_color(signal_v_red_mat,Color(0.88,0.05,0.02),horizontal_green)

func set_signal_color(mat:StandardMaterial3D,color:Color,active:bool)->void:
	mat.albedo_color=color if active else color.darkened(0.85)
	mat.emission=color if active else Color.BLACK

func make_gable_mesh()->ArrayMesh:
	# Reusable six-sided house roof in unit dimensions, instanced as one draw batch.
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a:=Vector3(-0.5,0.0,-0.5)
	var b:=Vector3(0.5,0.0,-0.5)
	var c:=Vector3(-0.5,0.0,0.5)
	var d:=Vector3(0.5,0.0,0.5)
	var e:=Vector3(0.0,0.35,-0.5)
	var f:=Vector3(0.0,0.35,0.5)
	for v in [a,c,f,a,f,e,e,f,d,e,d,b,a,e,b,c,d,f]:
		st.add_vertex(v)
	st.generate_normals()
	return st.commit()

func make_mat(c:Color) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=c
	m.roughness=0.88
	# Generated SurfaceTool triangles remain visible from both sides on GL Compatibility.
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	return m

func rebuild_for_quality(center:Vector3)->void:
	for key in chunks.keys():
		chunks[key].queue_free()
	chunks.clear()
	building_colliders.clear()
	pending.clear()
	last_center=Vector2i(9999,9999)
	force_spawn(center)

func force_spawn(center:Vector3) -> void:
	# 71.2: Create the player's sector immediately; stream the surrounding
	# sectors one at a time in _process instead of building 9–25 sectors
	# in the same startup frame on Android.
	update_stream(center)
	var player_cell:=Vector2i(roundi(center.x/Data.CHUNK_SIZE),roundi(center.z/Data.CHUNK_SIZE))
	if pending.has(player_cell):
		pending.erase(player_cell)
		spawn_chunk(player_cell)
	elif not pending.is_empty():
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
	rng.seed=int((key.x+128)*73856093+(key.y+128)*19349663+20261015)
	var p:=Vector2(root.position.x,root.position.z)
	var terrain_type:String=Data.city_type(p)
	make_terrain(root,p)
	make_landscape_patches(root,p,terrain_type,rng)
	make_roads(root,p,terrain_type)
	make_road_environment(root,p,terrain_type,rng)
	make_details(root,p,terrain_type,rng)
	make_street_life(root,p,terrain_type,rng)
	make_regional_character(root,p,terrain_type,rng)
	make_landmark(root,p)
	make_direction_sign(root,p,terrain_type)

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
	var bioregion:String=Data.region_at(center)
	terrain.material_override=urban_grass if Data.city_type(center)=="city" else (pine_grass if bioregion=="Mittelgebirge" else (field_grass if bioregion=="Wald- und Feldregion" else ground_material))
	terrain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(terrain)

func add_strip(st:SurfaceTool,center:Vector2,along_z:bool,offset:float,width:float,height_offset:float=0.12) -> void:
	var half:float=width*0.5
	for i in range(20):
		var v0:float=-200.0+i*20.0
		var v1:float=v0+20.0
		var a:Vector3
		var b:Vector3
		var c:Vector3
		var d:Vector3
		if along_z:
			a=Vector3(offset-half,Data.height_at(center.x+offset-half,center.y+v0)+height_offset,v0)
			b=Vector3(offset+half,Data.height_at(center.x+offset+half,center.y+v0)+height_offset,v0)
			c=Vector3(offset-half,Data.height_at(center.x+offset-half,center.y+v1)+height_offset,v1)
			d=Vector3(offset+half,Data.height_at(center.x+offset+half,center.y+v1)+height_offset,v1)
		else:
			a=Vector3(v0,Data.height_at(center.x+v0,center.y+offset-half)+height_offset,offset-half)
			b=Vector3(v0,Data.height_at(center.x+v0,center.y+offset+half)+height_offset,offset+half)
			c=Vector3(v1,Data.height_at(center.x+v1,center.y+offset-half)+height_offset,offset-half)
			d=Vector3(v1,Data.height_at(center.x+v1,center.y+offset+half)+height_offset,offset+half)
		st.add_vertex(a); st.add_vertex(c); st.add_vertex(b)
		st.add_vertex(b); st.add_vertex(c); st.add_vertex(d)

# ROAD SURFACE 71.6: Seam-free orthogonal intersections with shared terrain samples.
# The old full-length X and Z asphalt strips lay directly on top of one another,
# creating coplanar surfaces (flicker) at every intersection. Horizontal arms
# now stop precisely at the vertical road boundary; no triangles overlap.
func _road_quad(st:SurfaceTool,center:Vector2,x0:float,x1:float,z0:float,z1:float,lift:float) -> void:
	if x1-x0<=0.001 or z1-z0<=0.001:
		return
	# Small segments follow the terrain instead of cutting through its slopes.
	var nx:int=maxi(1,ceili((x1-x0)/8.0))
	var nz:int=maxi(1,ceili((z1-z0)/8.0))
	for ix in range(nx):
		var xa:float=lerpf(x0,x1,float(ix)/float(nx))
		var xb:float=lerpf(x0,x1,float(ix+1)/float(nx))
		for iz in range(nz):
			var za:float=lerpf(z0,z1,float(iz)/float(nz))
			var zb:float=lerpf(z0,z1,float(iz+1)/float(nz))
			var a:=Vector3(xa,Data.height_at(center.x+xa,center.y+za)+lift,za)
			var b:=Vector3(xb,Data.height_at(center.x+xb,center.y+za)+lift,za)
			var c:=Vector3(xa,Data.height_at(center.x+xa,center.y+zb)+lift,zb)
			var d:=Vector3(xb,Data.height_at(center.x+xb,center.y+zb)+lift,zb)
			st.add_vertex(a);st.add_vertex(c);st.add_vertex(b)
			st.add_vertex(b);st.add_vertex(c);st.add_vertex(d)

func _road_arms(st:SurfaceTool,center:Vector2,vertical_roads:Array[Dictionary],horizontal_roads:Array[Dictionary],extra_width:float,lift:float) -> void:
	# Continuous north/south corridors.
	for item in vertical_roads:
		var o:float=float(item["offset"])
		var half:float=float(item["width"])*0.5+extra_width
		_road_quad(st,center,o-half,o+half,-200.0,200.0,lift)
	# West/east corridors: clip out every vertical crossing exactly once.
	for horizontal in horizontal_roads:
		var hz:float=float(horizontal["offset"])
		var hh:float=float(horizontal["width"])*0.5+extra_width
		var cursor:float=-200.0
		for vertical in vertical_roads:
			var vx:float=float(vertical["offset"])
			var vh:float=float(vertical["width"])*0.5+extra_width
			_road_quad(st,center,cursor,vx-vh,hz-hh,hz+hh,lift)
			cursor=vx+vh
		_road_quad(st,center,cursor,200.0,hz-hh,hz+hh,lift)

# ROAD FINISH 71.7: White paint is clipped to exact crossing boundaries and
# dashed against global metre coordinates, not against the current streamed cell.
# Adjacent chunks therefore continue the same markings without broken dashes.
func _paint_stroke(st:SurfaceTool,center:Vector2,along_z:bool,across:float,start:float,stop:float,width:float)->void:
	if stop-start<=0.04:
		return
	if along_z:
		_road_quad(st,center,across-width*0.5,across+width*0.5,start,stop,0.262)
	else:
		_road_quad(st,center,start,stop,across-width*0.5,across+width*0.5,0.262)

# Slice a paint / kerb interval against complete intersection rectangles.
func _clip_crossings(start:float,stop:float,crossings:Array[Dictionary],margin:float)->Array[Vector2]:
	var kept:Array[Vector2]=[Vector2(start,stop)]
	for crossing in crossings:
		var half:float=float(crossing["width"])*0.5+margin
		var cut_min:float=float(crossing["offset"])-half
		var cut_max:float=float(crossing["offset"])+half
		var next:Array[Vector2]=[]
		for seg in kept:
			if seg.x<cut_min-0.02:
				next.append(Vector2(seg.x,minf(seg.y,cut_min)))
			if seg.y>cut_max+0.02:
				next.append(Vector2(maxf(seg.x,cut_max),seg.y))
		kept=next
		if kept.is_empty():
			break
	return kept

func _draw_road_marking(st:SurfaceTool,center:Vector2,along_z:bool,across:float,crossings:Array[Dictionary],width:float,paint_length:float=0.0,cycle_length:float=0.0)->void:
	var world_origin:float=center.y if along_z else center.x
	var candidates:Array[Vector2]=[]
	if cycle_length<=0.0:
		candidates.append(Vector2(-200.0,200.0))
	else:
		var first:int=floori((world_origin-200.0)/cycle_length)-1
		var last:int=ceili((world_origin+200.0)/cycle_length)+1
		for n in range(first,last+1):
			var a:float=maxf(-200.0,float(n)*cycle_length-world_origin)
			var b:float=minf(200.0,float(n)*cycle_length+paint_length-world_origin)
			if b-a>0.04:
				candidates.append(Vector2(a,b))
	for candidate in candidates:
		for clipped in _clip_crossings(candidate.x,candidate.y,crossings,2.5):
			_paint_stroke(st,center,along_z,across,clipped.x,clipped.y,width)

func make_roads(root:Node3D,center:Vector2,kind:String) -> void:
	# Corridor width is directional, so it remains consistent across chunk seams.
	var vertical_width:float=27.0 if absf(center.x)<100.0 else 13.0
	var horizontal_width:float=27.0 if absf(center.y)<100.0 else 13.0
	var vertical_roads:Array[Dictionary]=[{"offset":0.0,"width":vertical_width}]
	var horizontal_roads:Array[Dictionary]=[{"offset":0.0,"width":horizontal_width}]
	if kind!="rural":
		for offset in [-100.0,100.0]:
			vertical_roads.append({"offset":offset,"width":9.0})
			horizontal_roads.append({"offset":offset,"width":9.0})
	vertical_roads.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		return float(a["offset"])<float(b["offset"])
	)
	horizontal_roads.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		return float(a["offset"])<float(b["offset"])
	)
	var shoulder_surface:=SurfaceTool.new()
	shoulder_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_road_arms(shoulder_surface,center,vertical_roads,horizontal_roads,2.35,0.125)
	shoulder_surface.generate_normals()
	var shoulder:=MeshInstance3D.new()
	shoulder.mesh=shoulder_surface.commit()
	shoulder.material_override=gravel_material
	shoulder.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shoulder)
	var road_surface:=SurfaceTool.new()
	road_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_road_arms(road_surface,center,vertical_roads,horizontal_roads,0.0,0.22)
	road_surface.generate_normals()
	var asphalt:=MeshInstance3D.new()
	asphalt.mesh=road_surface.commit()
	asphalt.material_override=asphalt_material
	asphalt.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(asphalt)
	var paint_surface:=SurfaceTool.new()
	paint_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var curbs:Array[Transform3D]=[]
	for along_z in [true,false]:
		var road_defs:Array[Dictionary]=vertical_roads if along_z else horizontal_roads
		var crossings:Array[Dictionary]=horizontal_roads if along_z else vertical_roads
		for road_def in road_defs:
			var offset:float=float(road_def["offset"])
			var road_width:float=float(road_def["width"])
			var half_width:float=road_width*0.5
			# German-style solid outer lines remain 0.14m wide.
			for side in [-1.0,1.0]:
				_draw_road_marking(paint_surface,center,along_z,offset+side*(half_width-0.72),crossings,0.14)
			if road_width>20.0:
				# Six traffic lanes and a visible central double line.
				for division in [-0.30,0.30]:
					_draw_road_marking(paint_surface,center,along_z,offset+division,crossings,0.15)
				# Six metres of paint every twelve metres, world-aligned.
				for lane in [-8.45,-4.35,4.35,8.45]:
					_draw_road_marking(paint_surface,center,along_z,offset+lane,crossings,0.15,6.0,12.0)
			else:
				# Rural: 6/12 m; urban: 3/6 m; both stop at the real junction edge.
				var stripe:float=3.0 if kind!="rural" else 6.0
				_draw_road_marking(paint_surface,center,along_z,offset,crossings,0.15,stripe,stripe*2.0)
			if kind!="rural":
				# Side stones are cut to the junction boundary rather than intersecting it.
				for section in range(20):
					var a:float=-200.0+float(section)*20.0
					var b:float=a+19.0
					for seg in _clip_crossings(a,b,crossings,4.0):
						var length:float=seg.y-seg.x
						if length<0.2:
							continue
						var mid:float=(seg.x+seg.y)*0.5
						for side in [-1.0,1.0]:
							var edge:float=offset+side*(half_width+1.25)
							var px:float=edge if along_z else mid
							var pz:float=mid if along_z else edge
							var py:float=Data.height_at(center.x+px,center.y+pz)+0.205
							var scale:Vector3=Vector3(0.55,0.14,length) if along_z else Vector3(length,0.14,0.55)
							curbs.append(Transform3D(Basis.IDENTITY.scaled(scale),Vector3(px,py,pz)))
	paint_surface.generate_normals()
	var paint:=MeshInstance3D.new()
	paint.mesh=paint_surface.commit()
	paint.material_override=paint_material
	paint.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(paint)
	add_batch(root,box_mesh,pavement_material,curbs)

func make_road_environment(root:Node3D,center:Vector2,kind:String,rng:RandomNumberGenerator)->void:
	# German pedestrian crossings, stop-lines, sidewalks, bollards and road furniture.
	# Everything except road signs is MultiMesh-instanced to protect mobile draw calls.
	var crossing_paint:=SurfaceTool.new()
	crossing_paint.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pavement:Array[Transform3D]=[]
	var street_posts:Array[Transform3D]=[]
	var traffic_heads:Array[Transform3D]=[]
	var black_signs:Array[Transform3D]=[]
	var blue_signs:Array[Transform3D]=[]
	var white_strips:Array[Transform3D]=[]
	var parking_lines:Array[Transform3D]=[]
	var reflectors:Array[Transform3D]=[]
	var h_red:Array[Transform3D]=[]
	var h_green:Array[Transform3D]=[]
	var v_red:Array[Transform3D]=[]
	var v_green:Array[Transform3D]=[]
	# Major axis crossing is one per sector at its center; zebra stripes are
	# excluded in rural zones where zebra markings would be inappropriate.
	if kind!="rural":
		for approach in [-1.0,1.0]:
			for along_z in [true,false]:
				var offset:float=approach*24.0
				var crossing_width:float=13.0
				if (along_z and absf(center.x)<100.0) or (not along_z and absf(center.y)<100.0):
					crossing_width=27.0
				var stripes:int=11 if crossing_width>20.0 else 5
				for stripe in range(stripes):
					var side:float=(float(stripe)-float(stripes-1)*0.5)*2.2
					var x:float=side if along_z else offset
					var z:float=offset if along_z else side
					var wp:=Vector2(center.x+x,center.y+z)
					if along_z:
						_paint_stroke(crossing_paint,center,true,x,offset-1.55,offset+1.55,1.35)
					else:
						_paint_stroke(crossing_paint,center,false,z,offset-1.55,offset+1.55,1.35)
				var x2:float=0.0 if along_z else approach*33.0
				var z2:float=approach*33.0 if along_z else 0.0
				var stop_span:float=crossing_width-2.4
				if along_z:
					_paint_stroke(crossing_paint,center,false,z2,-stop_span*0.5,stop_span*0.5,0.48)
				else:
					_paint_stroke(crossing_paint,center,true,x2,-stop_span*0.5,stop_span*0.5,0.48)
		for road_dir in [true,false]:
			for sign in [-1.0,1.0]:
				for idx in range(6):
					var along:float=-168.0+idx*63.0
					var cross:float=sign*18.0
					var sx:float=cross if road_dir else along
					var sz:float=along if road_dir else cross
					var gp:=Vector2(center.x+sx,center.y+sz)
					var h:float=Data.height_at(gp.x,gp.y)
					street_posts.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.21,2.65,0.21)),Vector3(sx,h+1.325,sz)))
					blue_signs.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.11,0.64,0.75) if road_dir else Vector3(0.75,0.64,0.11)),Vector3(sx,h+2.6,sz)))
				# Central lanes get inset pavement pieces outside vehicle circulation.
		for along_z in [true,false]:
			for side in [-1.0,1.0]:
				for i in range(12):
					var along:float=-183.0+i*31.0
					if absf(along)<23.0 or absf(absf(along)-100.0)<16.0:continue
					var across:float=side*17.8
					var px:float=across if along_z else along
					var pz:float=along if along_z else across
					var point:=Vector2(center.x+px,center.y+pz)
					var surf:Basis=Basis.IDENTITY.scaled(Vector3(2.6,0.16,28.0) if along_z else Vector3(28.0,0.16,2.6))
					pavement.append(Transform3D(surf,Vector3(px,Data.height_at(point.x,point.y)+0.12,pz)))
		# Traffic lights deliberately at street corners instead of across the lane.
		for sx in [-17.5,17.5]:
			for sz in [-17.5,17.5]:
				var point:=Vector2(center.x+sx,center.y+sz)
				var y:float=Data.height_at(point.x,point.y)
				street_posts.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.25,5.2,0.25)),Vector3(sx,y+2.6,sz)))
				traffic_heads.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.7,1.65,0.55)),Vector3(sx,y+5.1,sz)))
				var red_marker:=Transform3D(Basis.IDENTITY.scaled(Vector3(0.42,0.42,0.08)),Vector3(sx,y+5.57,sz-0.34))
				var green_marker:=Transform3D(Basis.IDENTITY.scaled(Vector3(0.42,0.42,0.08)),Vector3(sx,y+4.64,sz-0.34))
				if sx*sz>0.0:
					h_red.append(red_marker);h_green.append(green_marker)
				else:
					v_red.append(red_marker);v_green.append(green_marker)
	else:
		# White reflective edge bollards every ~55 m on rural main roads.
		for along_z in [true,false]:
			for sign in [-1.0,1.0]:
				for idx in range(7):
					var along:float=-165.0+idx*55.0
					var cross:float=sign*16.2
					var bx:float=cross if along_z else along
					var bz:float=along if along_z else cross
					var wp:=Vector2(center.x+bx,center.y+bz)
					reflectors.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.20,1.05,0.25)),Vector3(bx,Data.height_at(wp.x,wp.y)+0.52,bz)))
	if kind!="rural":
		crossing_paint.generate_normals()
		var zebra:=MeshInstance3D.new()
		zebra.mesh=crossing_paint.commit()
		zebra.material_override=paint_material
		zebra.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(zebra)
	add_batch(root,box_mesh,cobble_mat,pavement)
	add_batch(root,box_mesh,metal_dark_mat,street_posts)
	add_batch(root,box_mesh,metal_dark_mat,traffic_heads)
	add_batch(root,box_mesh,road_sign_mat,blue_signs)
	add_batch(root,box_mesh,paint_material,reflectors)
	add_batch(root,box_mesh,signal_h_red_mat,h_red)
	add_batch(root,box_mesh,signal_h_green_mat,h_green)
	add_batch(root,box_mesh,signal_v_red_mat,v_red)
	add_batch(root,box_mesh,signal_v_green_mat,v_green)

func make_landscape_patches(root:Node3D,center:Vector2,kind:String,rng:RandomNumberGenerator)->void:
	# Muted agricultural and meadow variation without expensive terrain shaders.
	# Placed outside road clearance: the large visible white surfaces from 62.0
	# are replaced by recognizable materials and varied ground-level features.
	if kind=="city":return
	var meadows:Array[Transform3D]=[]
	var soil:Array[Transform3D]=[]
	var crop:Array[Transform3D]=[]
	var rows:Array[Transform3D]=[]
	var field_edges:Array[Transform3D]=[]
	for i in range(26 if kind=="rural" else 10):
		var x:float=rng.randf_range(-180.0,180.0)
		var z:float=rng.randf_range(-180.0,180.0)
		var point:=Vector2(center.x+x,center.y+z)
		if Data.road_distance(point)<44.0:continue
		var w:float=rng.randf_range(12.0,35.0)
		var d:float=rng.randf_range(16.0,45.0)
		var at:=Vector3(x,Data.height_at(point.x,point.y)-0.10,z)
		var transform:=Transform3D(Basis.IDENTITY.scaled(Vector3(w,0.10,d)),at)
		if i%5==0: soil.append(transform)
		elif i%3==0:crop.append(transform)
		else: meadows.append(transform)
		if i%3==0:
			for n in range(4):
				var rz:float=z+(float(n)-1.5)*(d*0.19)
				rows.append(Transform3D(Basis.IDENTITY.scaled(Vector3(w*0.86,0.19,0.55)),Vector3(x,at.y+0.20,rz)))
	add_batch(root,box_mesh,field_material,meadows)
	add_batch(root,box_mesh,soil_material,soil)
	add_batch(root,box_mesh,crop_material,crop)
	add_batch(root,box_mesh,grass_detail_mat,rows)

func make_details(root:Node3D,center:Vector2,kind:String,rng:RandomNumberGenerator) -> void:
	var building_groups:Array=[]
	var building_rects:Array[Rect2]=[]
	for i in range(building_materials.size()):building_groups.append([])
	var roof_instances:Array[Transform3D]=[]
	var roof_gables:Array[Transform3D]=[]
	var storefront_instances:Array[Transform3D]=[]
	var window_sills:Array[Transform3D]=[]
	var side_windows:Array[Transform3D]=[]
	var balcony_instances:Array[Transform3D]=[]
	var loading_doors:Array[Transform3D]=[]
	var vent_instances:Array[Transform3D]=[]
	var foundations:Array[Transform3D]=[]
	var tree_crowns:Array[Transform3D]=[]
	var tree_trunks:Array[Transform3D]=[]
	var fir_crowns:Array[Transform3D]=[]
	var window_instances:Array[Transform3D]=[]
	var door_instances:Array[Transform3D]=[]
	var hedge_instances:Array[Transform3D]=[]
	var rail_instances:Array[Transform3D]=[]
	var post_instances:Array[Transform3D]=[]
	var lamps:Array[Transform3D]=[]
	var lamp_heads:Array[Transform3D]=[]
	var building_count:int=65 if kind=="city" else (34 if kind=="industry" else (19 if kind=="village" else 3))
	if detail_level==0:building_count=roundi(float(building_count)*0.63)
	var tree_count:int=20 if kind=="city" else (12 if kind=="industry" else (36 if kind=="village" else 75))
	if detail_level==0:tree_count=roundi(float(tree_count)*0.65)
	if detail_level==2:tree_count=roundi(float(tree_count)*1.20)
	# Regular street-front lots make a recognisable German block structure.
	# The old completely random placement left vast, unconvincing blank gaps.
	var street_lots:Array[Vector2]=[]
	if kind=="city" or kind=="village":
		for side in [-1.0,1.0]:
			# Keep facade lots clear of the ±100 m local streets. Earlier
			# many candidates were rejected by road_distance(), leaving gaps.
			for slot in [-174.0,-144.0,-65.0,65.0,144.0,174.0]:
				street_lots.append(Vector2(side*44.0,slot))
				street_lots.append(Vector2(slot,side*44.0))
	if kind=="industry":
		for side in [-1.0,1.0]:
			for slot in [-143.0,-63.0,63.0,143.0]:
				street_lots.append(Vector2(side*65.0,slot))
	# Retry rejected lots; this preserves density without placing buildings on roads.
	var placed:int=0
	for i in range(building_count*5):
		if placed>=building_count:break
		var x:float=rng.randf_range(-187.0,187.0)
		var z:float=rng.randf_range(-187.0,187.0)
		if i<street_lots.size():
			x=street_lots[i].x+rng.randf_range(-2.0,2.0)
			z=street_lots[i].y+rng.randf_range(-2.0,2.0)
		var pos:=Vector2(center.x+x,center.y+z)
		if Data.road_distance(pos)<33.0:continue
		var wide:float=rng.randf_range(12.0,24.0) if kind=="industry" else rng.randf_range(9.0,16.0)
		var dep:float=rng.randf_range(13.0,27.0)
		var h:float=rng.randf_range(9.0,40.0) if kind=="city" else (rng.randf_range(8.0,15.0) if kind=="industry" else rng.randf_range(5.0,12.0))
		# Validate the whole footprint, not just its centre, and avoid interpenetrating houses.
		var footprint:=Rect2(pos-Vector2(wide,dep)*0.5,Vector2(wide,dep))
		var obstructed:bool=false
		for corner in [Vector2(-wide*0.5,-dep*0.5),Vector2(wide*0.5,-dep*0.5),Vector2(-wide*0.5,dep*0.5),Vector2(wide*0.5,dep*0.5)]:
			if Data.pavement_clearance(pos+corner)<2.2:
				obstructed=true
				break
		if obstructed:continue
		for occupied in building_rects:
			if occupied.grow(2.4).intersects(footprint):
				obstructed=true
				break
		if obstructed:continue
		placed+=1
		var y:float=Data.height_at(pos.x,pos.y)
		var m:Transform3D=Transform3D(Basis.IDENTITY.scaled(Vector3(wide,h,dep)),Vector3(x,y+h*0.5,z))
		var idx:int=rng.randi_range(0,building_materials.size()-1)
		building_rects.append(footprint)
		building_groups[idx].append(m)
		if kind=="village" or (kind=="rural" and i%2==0) or (kind=="city" and i%3==0):
			roof_gables.append(Transform3D(Basis.IDENTITY.scaled(Vector3(wide+1.5,6.0,dep+1.5)),Vector3(x,y+h,z)))
		else:
			roof_instances.append(Transform3D(Basis.IDENTITY.scaled(Vector3(wide+0.8,0.65,dep+0.8)),Vector3(x,y+h+0.3,z)))
		# Solid basement extends beneath the local mesh instead of hovering above slopes.
		foundations.append(Transform3D(Basis.IDENTITY.scaled(Vector3(wide+0.2,4.0,dep+0.2)),Vector3(x,y-1.2,z)))
		# Store-fronts, simple apartment windows and individual door accents.
		# These are batched and only face streets; distant blocks now read as houses.
		for level in range(1,mini(6,maxi(2,int(h/3.3)))):
			var win_y:float=y+minf(h-1.3,float(level)*3.05)
			for column in [-1.0,0.0,1.0]:
				var wx:float=x+column*wide*0.27
				window_instances.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.65,1.40,0.095)),Vector3(wx,win_y,z-dep*0.5-0.07)))
				window_instances.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.65,1.40,0.095)),Vector3(wx,win_y,z+dep*0.5+0.07)))
				window_sills.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.9,0.13,0.31)),Vector3(wx,win_y-0.73,z-dep*0.5-0.16)))
			for column in [-1.0,1.0]:
				var wz:float=z+column*dep*0.27
				side_windows.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.085,1.30,1.65)),Vector3(x-wide*0.5-0.06,win_y,wz)))
				side_windows.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.085,1.30,1.65)),Vector3(x+wide*0.5+0.06,win_y,wz)))
			if kind=="city" and level%2==0:
				balcony_instances.append(Transform3D(Basis.IDENTITY.scaled(Vector3(wide*0.43,0.16,1.4)),Vector3(x,y+float(level)*3.05-0.96,z-dep*0.5-0.70)))
		door_instances.append(Transform3D(Basis.IDENTITY.scaled(Vector3(2.15,2.60,0.13)),Vector3(x,y+1.35,z-dep*0.5-0.11)))
		if kind=="city" and h>13.0:
			storefront_instances.append(Transform3D(Basis.IDENTITY.scaled(Vector3(wide*0.54,2.75,0.16)),Vector3(x,y+1.55,z-dep*0.5-0.13)))
		if kind=="industry":
			loading_doors.append(Transform3D(Basis.IDENTITY.scaled(Vector3(wide*0.65,4.3,0.19)),Vector3(x,y+2.17,z-dep*0.5-0.13)))
			vent_instances.append(Transform3D(Basis.IDENTITY.scaled(Vector3(2.9,0.35,2.3)),Vector3(x+wide*0.2,y+h+0.74,z)))
	var tree_lots:Array[Vector2]=[]
	if kind=="city" or kind=="village":
		for side in [-1.0,1.0]:
			for slot in [-173.0,-127.0,-81.0,-35.0,35.0,81.0,127.0,173.0]:
				tree_lots.append(Vector2(side*26.0,slot))
				tree_lots.append(Vector2(slot,side*26.0))
	for i in range(tree_count):
		var x:float=rng.randf_range(-198.0,198.0)
		var z:float=rng.randf_range(-198.0,198.0)
		if i<tree_lots.size():
			x=tree_lots[i].x
			z=tree_lots[i].y
		var pos:=Vector2(center.x+x,center.y+z)
		if Data.road_distance(pos)<19.0: continue
		var h:float=rng.randf_range(5.0,13.0)
		var y:float=Data.height_at(pos.x,pos.y)
		tree_trunks.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.48,h*0.55,0.48)),Vector3(x,y+h*0.275,z)))
		if i%3==0:
			fir_crowns.append(Transform3D(Basis.IDENTITY.scaled(Vector3(h*0.35,h*0.48,h*0.35)),Vector3(x,y+h*0.74,z)))
		else:
			tree_crowns.append(Transform3D(Basis.IDENTITY.scaled(Vector3(h*0.29,h*0.36,h*0.29)),Vector3(x,y+h*0.74,z)))
	for i in range(building_materials.size()):
		add_batch(root,box_mesh,building_materials[i],building_groups[i])
	add_batch(root,box_mesh,dark_material,foundations)
	add_batch(root,box_mesh,roof_material,roof_instances)
	add_batch(root,roof_gable,roof_material,roof_gables)
	add_batch(root,box_mesh,window_material,side_windows)
	add_batch(root,box_mesh,pavement_material,window_sills)
	add_batch(root,box_mesh,pavement_material,balcony_instances)
	add_batch(root,box_mesh,window_material,storefront_instances)
	add_batch(root,box_mesh,metal_dark_mat,loading_doors)
	add_batch(root,box_mesh,metal_dark_mat,vent_instances)
	add_batch(root,box_mesh,window_material,window_instances)
	add_batch(root,box_mesh,dark_material,door_instances)
	add_batch(root,trunk_mesh,trunk_material,tree_trunks)
	add_batch(root,tree_mesh,foliage_material,tree_crowns)
	# Pointed silhouettes are distinct from deciduous canopies.
	var pine:=CylinderMesh.new();pine.top_radius=0.0;pine.bottom_radius=1.0;pine.height=2.0;pine.radial_segments=7
	add_batch(root,pine,forest_material,fir_crowns)
	# Simple roadside barriers, small bushes and reflectors along the major routes.
	for road_dir in [true,false]:
		for idx in range(6):
			var t:float=-172.0+float(idx)*62.0
			var side:float=-1.0 if idx%2==0 else 1.0
			var dist:float=19.0 if abs(center.x)<100.0 or abs(center.y)<100.0 else 12.0
			var px:float=side*dist if road_dir else t
			var pz:float=t if road_dir else side*dist
			var wp:=Vector2(center.x+px,center.y+pz)
			var py:float=Data.height_at(wp.x,wp.y)
			if kind=="rural":
				var hedge_basis:=Basis.IDENTITY.scaled(Vector3(1.9,1.3,4.5))
				hedge_instances.append(Transform3D(hedge_basis,Vector3(px,py+0.65,pz)))
			if abs(center.x)<100.0 or abs(center.y)<100.0:
				var rail_basis:=Basis.IDENTITY.scaled(Vector3(0.22,0.30,30.0) if road_dir else Vector3(30.0,0.30,0.22))
				rail_instances.append(Transform3D(rail_basis,Vector3(px,py+0.78,pz)))
				post_instances.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.22,1.6,0.22)),Vector3(px,py+0.80,pz)))
	add_batch(root,box_mesh,hedge_material,hedge_instances)
	add_batch(root,box_mesh,railing_material,rail_instances)
	add_batch(root,box_mesh,dark_material,post_instances)
	# Highway lamp silhouettes; emissive lamps are material-based (no costly point lights).
	if kind!="rural":
		for i in range(-1,2):
			var z:float=i*155.0+40.0
			lamps.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.26,8.0,0.26)),Vector3(18.0,Data.height_at(center.x+18,center.y+z)+4.0,z)))
			lamp_heads.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.7,0.4,0.65)),Vector3(16.8,Data.height_at(center.x+18,center.y+z)+8.2,z)))
	building_colliders[Vector2i(roundi(center.x/Data.CHUNK_SIZE),roundi(center.y/Data.CHUNK_SIZE))]=building_rects
	add_batch(root,box_mesh,pavement_material,lamps)
	add_batch(root,box_mesh,lamp_material,lamp_heads)

func make_street_life(root:Node3D,center:Vector2,kind:String,rng:RandomNumberGenerator)->void:
	# Lightweight stationary street traffic and bus shelters, batched for mobile GPUs.
	if kind=="rural":return
	var car_light:Array[Transform3D]=[]
	var car_dark:Array[Transform3D]=[]
	var car_glass:Array[Transform3D]=[]
	var car_lamps:Array[Transform3D]=[]
	var car_wheels:Array[Transform3D]=[]
	var shelter_posts:Array[Transform3D]=[]
	var shelter_roofs:Array[Transform3D]=[]
	var shelter_panels:Array[Transform3D]=[]
	var slots:int=3 if detail_level==0 else (5 if detail_level==1 else 7)
	for side in [-1.0,1.0]:
		for n in range(slots):
			var along:float=-165.0+float(n)*330.0/maxf(1.0,float(slots-1))
			along+=rng.randf_range(-7.0,7.0)
			if absf(along)<44.0:continue
			var across:float=side*23.5
			var point:=Vector2(center.x+across,center.y+along)
			var ground:float=Data.height_at(point.x,point.y)
			var origin:=Vector3(across,ground,along)
			var shell:=Transform3D(Basis.IDENTITY.scaled(Vector3(1.95,0.75,4.1)),origin+Vector3(0,0.59,0))
			if (n+int(side))%2==0:car_light.append(shell)
			else:car_dark.append(shell)
			car_glass.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.60,0.46,2.05)),origin+Vector3(0,1.18,0.12)))
			car_lamps.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.38,0.13,0.10)),origin+Vector3(0,0.77,2.07)))
			for wheel_side in [-1.0,1.0]:
				for wheel_z in [-1.25,1.25]:
					car_wheels.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.24,0.64,0.62)),origin+Vector3(wheel_side*0.98,0.35,wheel_z)))
	# Exactly one shelter per occupied sector: enough variety without heavy scene trees.
	if kind=="city" or kind=="village":
		var bx:float=29.0
		var bz:float=-112.0
		var shelter_ground:float=Data.height_at(center.x+bx,center.y+bz)
		for side in [-1.0,1.0]:
			shelter_posts.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.19,2.7,0.19)),Vector3(bx,shelter_ground+1.35,bz+side*2.2)))
		shelter_roofs.append(Transform3D(Basis.IDENTITY.scaled(Vector3(2.8,0.17,5.2)),Vector3(bx,shelter_ground+2.8,bz)))
		shelter_panels.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.10,2.1,4.4)),Vector3(bx+1.35,shelter_ground+1.13,bz)))
	add_batch(root,box_mesh,railing_material,car_light)
	add_batch(root,box_mesh,wheelhouse_material,car_dark)
	add_batch(root,box_mesh,window_material,car_glass)
	add_batch(root,box_mesh,road_marking_red,car_lamps)
	add_batch(root,box_mesh,wheelhouse_material,car_wheels)
	add_batch(root,box_mesh,metal_dark_mat,shelter_posts)
	add_batch(root,box_mesh,railing_material,shelter_roofs)
	add_batch(root,box_mesh,window_material,shelter_panels)

# Region-specific roadside objects using just a few MultiMesh draw calls.
# No expensive per-object scenes or lights; intentionally sparse on low quality.
func make_regional_character(root:Node3D,center:Vector2,kind:String,rng:RandomNumberGenerator)->void:
	var sector:Vector2i=Vector2i(roundi(center.x/Data.CHUNK_SIZE),roundi(center.y/Data.CHUNK_SIZE))
	if detail_level==0 and posmod(sector.x+sector.y,2)!=0:return
	if kind=="rural" or kind=="village":
		var bales:Array[Transform3D]=[]
		var fence_posts:Array[Transform3D]=[]
		var fence_rails:Array[Transform3D]=[]
		# Local field decor with valid asphalt clearance and reproducible positions.
		for i in range(12 if detail_level==2 else 7):
			var x:float=rng.randf_range(48.0,176.0)
			var z:float=rng.randf_range(48.0,176.0)
			var p:=Vector2(center.x+x,center.y+z)
			if Data.pavement_clearance(p)<7.0:continue
			var y:float=Data.height_at(p.x,p.y)
			var basis:=Basis(Vector3(0,0,1),PI*0.5).scaled(Vector3(1.0,1.0,1.0))
			bales.append(Transform3D(basis,Vector3(x,y+0.86,z)))
		# Simple wooden pasture enclosure, away from the arterial road.
		for i in range(8):
			var x:float=-145.0+float(i)*17.0
			var z:float=118.0
			var p:=Vector2(center.x+x,center.y+z)
			if Data.pavement_clearance(p)<5.0:continue
			var y:float=Data.height_at(p.x,p.y)
			fence_posts.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.23,1.4,0.23)),Vector3(x,y+0.7,z)))
			if i<7:
				fence_rails.append(Transform3D(Basis.IDENTITY.scaled(Vector3(17.0,0.15,0.17)),Vector3(x+8.5,y+1.05,z)))
		add_batch(root,bale_mesh,hay_mat,bales)
		add_batch(root,box_mesh,bark_material,fence_posts)
		add_batch(root,box_mesh,bark_material,fence_rails)
	elif kind=="industry":
		var containers_red:Array[Transform3D]=[]
		var containers_blue:Array[Transform3D]=[]
		for i in range(4):
			# Keep containers entirely clear of the 100 m urban road grid.
			var x:float=-52.0 if i%2==0 else 52.0
			var z:float=-52.0 if i<2 else 52.0
			var p:=Vector2(center.x+x,center.y+z)
			if Data.pavement_clearance(p)<14.0:continue
			var collider_key:=Vector2i(roundi(center.x/Data.CHUNK_SIZE),roundi(center.y/Data.CHUNK_SIZE))
			var solid_rects:Array=building_colliders.get(collider_key,[])
			var footprint:=Rect2(p-Vector2(3.9,7.0),Vector2(7.8,14.0))
			var blocked:bool=false
			for solid in solid_rects:
				if solid.grow(1.0).intersects(footprint):
					blocked=true
					break
			if blocked:continue
			solid_rects.append(footprint)
			building_colliders[collider_key]=solid_rects
			var y:float=Data.height_at(p.x,p.y)
			var item:=Transform3D(Basis.IDENTITY.scaled(Vector3(7.8,2.8,14.0)),Vector3(x,y+1.4,z))
			if i%2==0:containers_red.append(item)
			else:containers_blue.append(item)
		add_batch(root,box_mesh,freight_red_mat,containers_red)
		add_batch(root,box_mesh,freight_blue_mat,containers_blue)
	else:
		var benches:Array[Transform3D]=[]
		var bins:Array[Transform3D]=[]
		for z in [-146.0,-54.0,54.0,146.0]:
			var x:float=28.0
			var p:=Vector2(center.x+x,center.y+z)
			if Data.pavement_clearance(p)<5.0:continue
			var y:float=Data.height_at(p.x,p.y)
			benches.append(Transform3D(Basis.IDENTITY.scaled(Vector3(2.3,0.15,0.72)),Vector3(x,y+0.55,z)))
			bins.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.52,0.95,0.52)),Vector3(x+2.8,y+0.48,z)))
		add_batch(root,box_mesh,bark_material,benches)
		add_batch(root,box_mesh,metal_dark_mat,bins)

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

func make_direction_sign(root:Node3D,center:Vector2,kind:String)->void:
	# Small German-inspired wayfinding sign, placed at a road verge.
	# Only a subset of sectors gets one to preserve draw-call budget.
	var sx:int=roundi(center.x/Data.CHUNK_SIZE)
	var sz:int=roundi(center.y/Data.CHUNK_SIZE)
	if posmod(sx+sz,4)!=0:return
	var location:=Vector2(center.x+23.0,center.y-73.0)
	var base_y:float=Data.height_at(location.x,location.y)
	var sign_root:=Node3D.new()
	sign_root.position=Vector3(23.0,base_y,-73.0)
	root.add_child(sign_root)
	var support:=MeshInstance3D.new()
	var support_mesh:=BoxMesh.new();support_mesh.size=Vector3(0.14,3.1,0.14)
	support.mesh=support_mesh;support.position=Vector3(-1.0,1.55,0.0)
	support.material_override=metal_dark_mat;sign_root.add_child(support)
	var plate:=MeshInstance3D.new()
	var plate_mesh:=BoxMesh.new();plate_mesh.size=Vector3(3.25,1.15,0.12)
	plate.mesh=plate_mesh;plate.position=Vector3(0.0,3.0,0.0)
	plate.material_override=road_sign_mat;sign_root.add_child(plate)
	var name_label:=Label3D.new()
	name_label.text=str(Data.nearest_city(location)["name"]).to_upper()
	name_label.font_size=60
	name_label.pixel_size=0.006
	name_label.modulate=Color(0.96,0.98,1.0)
	name_label.position=Vector3(0.0,3.05,0.079)
	sign_root.add_child(name_label)

func hit_static(world_position:Vector3)->bool:
	var key:=Vector2i(roundi(world_position.x/Data.CHUNK_SIZE),roundi(world_position.z/Data.CHUNK_SIZE))
	var p:=Vector2(world_position.x,world_position.z)
	# Buildings can extend across chunk borders: check adjacent sectors too.
	for dx in range(-1,2):
		for dz in range(-1,2):
			var near_key:Vector2i=key+Vector2i(dx,dz)
			if not building_colliders.has(near_key):continue
			for rectangle in building_colliders[near_key]:
				if rectangle.grow(1.3).has_point(p):return true
	return false
