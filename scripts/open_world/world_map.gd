extends Control
const Data=preload("res://scripts/open_world/world_data.gd")
var game
var font:Font
const EDGE:float=34.0

func _ready()->void:
	font=ThemeDB.fallback_font
	custom_minimum_size=Vector2(810,465)
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func proj(p:Vector2)->Vector2:
	var bounds:Vector2=size-Vector2(EDGE*2,EDGE*2)
	return Vector2(EDGE,EDGE)+Vector2((p.x+Data.HALF_EXTENT)/(2.0*Data.HALF_EXTENT)*bounds.x,(p.y+Data.HALF_EXTENT)/(2.0*Data.HALF_EXTENT)*bounds.y)

func _process(_delta:float)->void:
	queue_redraw()

func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.03,0.085,0.095),true)
	draw_rect(Rect2(Vector2(EDGE,EDGE),size-Vector2(EDGE*2,EDGE*2)),Color(0.09,0.17,0.15),true)
	# Major grid represented in one overview; individual roads are rendered in the minimap.
	for i in range(-10,11):
		var world_pos:float=float(i)*1200.0
		var a:=proj(Vector2(world_pos,-Data.HALF_EXTENT))
		var b:=proj(Vector2(world_pos,Data.HALF_EXTENT))
		var c:=proj(Vector2(-Data.HALF_EXTENT,world_pos))
		var d:=proj(Vector2(Data.HALF_EXTENT,world_pos))
		if a.x>=EDGE and a.x<=size.x-EDGE:draw_line(a,b,Color(0.28,0.37,0.33,0.65),1.5)
		if c.y>=EDGE and c.y<=size.y-EDGE:draw_line(c,d,Color(0.28,0.37,0.33,0.65),1.5)
	for city in Data.CITY_CENTERS:
		var center:Vector2=proj(city["pos"])
		var tint:=Color(0.35,0.73,0.88) if str(city["kind"])=="city" else (Color(0.89,0.67,0.32) if str(city["kind"])=="industry" else Color(0.62,0.86,0.51))
		draw_circle(center,9.0,tint)
		draw_arc(center,15.0,0.0,TAU,32,tint.darkened(0.2),2.0)
		draw_string(font,center+Vector2(15,-11),str(city["name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(0.93,0.97,0.94))
	if game!=null and game.vehicle!=null:
		var player:=Vector2(game.vehicle.position.x,game.vehicle.position.z)
		var here:Vector2=proj(player)
		if game.career.active_stage!="":
			var target:Vector2=proj(game.career.target())
			var route_points:Array[Vector2]=Data.route_points(player,game.career.target())
			var before:Vector2=here
			for waypoint in route_points:
				var next:Vector2=proj(waypoint)
				draw_line(before,next,Color(0.08,0.88,1.0),3.5,true)
				before=next
			draw_circle(target,7.0,Color(1.0,0.77,0.16))
		draw_circle(here,8.0,Color(0.30,0.95,0.43))
		draw_arc(here,11.0,0.0,TAU,22,Color(0.07,0.2,0.11),2.0)
	draw_rect(Rect2(Vector2(EDGE,EDGE),size-Vector2(EDGE*2,EDGE*2)),Color(0.55,0.71,0.70),false,2.0)
	draw_string(font,Vector2(EDGE+10,size.y-12),"GRÜN: FAHRZEUG    GELB: AUFTRAGSZIEL    TÜRKIS: ROUTE",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(0.84,0.93,0.91))
