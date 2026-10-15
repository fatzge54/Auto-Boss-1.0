extends Node3D
## Cheap camera-local raindrop streaks for the GL compatibility renderer.
## No per-drop nodes, no texture atlas and zero work outside rain conditions.
var instance:MultiMeshInstance3D
var particles:MultiMesh
var offsets:Array[Vector3]=[]
var rng:=RandomNumberGenerator.new()
var elapsed:float=0.0
var rain_enabled:bool=false
var streak_count:int=70

func _ready()->void:
	rng.seed=20261064
	var needle:=BoxMesh.new()
	needle.size=Vector3(0.022,0.75,0.022)
	particles=MultiMesh.new()
	particles.transform_format=MultiMesh.TRANSFORM_3D
	particles.mesh=needle
	particles.instance_count=90
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color(0.66,0.80,0.96,0.33)
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test=false
	instance=MultiMeshInstance3D.new()
	instance.multimesh=particles
	instance.material_override=mat
	add_child(instance)
	for i in range(90):
		offsets.append(Vector3(rng.randf_range(-16.0,16.0),rng.randf_range(0.0,12.0),rng.randf_range(-19.0,17.0)))
		particles.set_instance_transform(i,Transform3D(Basis.IDENTITY,offsets[i]))
	particles.visible_instance_count=0

func tick(delta:float,center:Vector3,weather:String,quality:int)->void:
	rain_enabled=weather=="Regen" or weather=="Starkregen"
	if not rain_enabled:
		visible=false
		return
	visible=true
	global_position=center+Vector3(0.0,1.0,0.0)
	streak_count=40 if quality==0 else (70 if quality==1 else 90)
	particles.visible_instance_count=streak_count
	elapsed=fposmod(elapsed+delta*21.0,12.0)
	for i in range(streak_count):
		var orig:Vector3=offsets[i]
		var at:=Vector3(orig.x,fposmod(orig.y-elapsed,12.0)-1.2,orig.z)
		particles.set_instance_transform(i,Transform3D(Basis.IDENTITY,at))
