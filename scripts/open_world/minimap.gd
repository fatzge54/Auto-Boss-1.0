extends Control
const Data=preload("res://scripts/open_world/world_data.gd")
var car:Node3D
var target:Vector2=Vector2.ZERO
var has_target:bool=false
var scale_factor:float=0.14
var track:Array[Vector2]=[]

func _process(_delta:float)->void:
	queue_redraw()

func project_position(world:Vector2,player:Vector2)->Vector2:
	var relative:Vector2=(world-player)*scale_factor
	return Vector2(size.x*0.5+relative.x,size.y*0.5+relative.y)

func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.025,0.09,0.115,0.90),true)
	if car==null:return
	var p:=Vector2(car.position.x,car.position.z)
	var spacing:float=Data.CHUNK_SIZE
	var x0:int=floori((p.x-1000)/spacing)
	var z0:int=floori((p.y-1000)/spacing)
	for xi in range(x0,x0+9):
		var x:float=xi*spacing
		var x_screen:float=project_position(Vector2(x,p.y),p).x
		if x_screen>=0.0 and x_screen<=size.x:
			draw_line(Vector2(x_screen,0),Vector2(x_screen,size.y),Color(0.35,0.41,0.43),2.0)
	for zi in range(z0,z0+9):
		var z:float=zi*spacing
		var z_screen:float=project_position(Vector2(p.x,z),p).y
		if z_screen>=0.0 and z_screen<=size.y:
			draw_line(Vector2(0,z_screen),Vector2(size.x,z_screen),Color(0.35,0.41,0.43),2.0)
	for i in range(1,track.size()):
		draw_line(project_position(track[i-1],p),project_position(track[i],p),Color(0.28,0.86,1.0,0.82),3.0,true)
	if has_target:
		var dot:=project_position(target,p)
		draw_circle(dot,7.0,Color(1.0,0.73,0.17))
	var angle:float=car.rotation.y
	var c:=Vector2(size.x*0.5,size.y*0.5)
	var f:=Vector2(-sin(angle),-cos(angle))
	var n:=Vector2(f.y,-f.x)
	var polygon:=PackedVector2Array([c+f*13,c-f*8+n*7,c-f*8-n*7])
	var colors:=PackedColorArray([Color(0.36,0.95,0.49),Color(0.15,0.75,0.34),Color(0.15,0.75,0.34)])
	draw_polygon(polygon,colors)
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.24,0.55,0.69),false,2.0)
