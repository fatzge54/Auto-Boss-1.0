extends RefCounted
## Deterministic 25 x 25 km coordinate space for the new Open World.
## All world coordinates are meters; world generation is intentionally streamed.
const HALF_EXTENT: float = 12500.0
const CHUNK_SIZE: float = 400.0
const CITY_CENTERS: Array = [
	{"name":"Lindenfurt", "pos":Vector2(0,0), "radius":2500.0, "kind":"city"},
	{"name":"Eisenhafen", "pos":Vector2(8000,-6800), "radius":2200.0, "kind":"industry"},
	{"name":"Bergstadt", "pos":Vector2(-8400,-7600), "radius":2200.0, "kind":"city"},
	{"name":"Nordheide", "pos":Vector2(-7600,7200), "radius":1800.0, "kind":"village"},
	{"name":"Hafenwall", "pos":Vector2(8000,7600), "radius":1700.0, "kind":"industry"}
]

static func nearest_city(p:Vector2) -> Dictionary:
	var best:Dictionary = CITY_CENTERS[0]
	var nearest:float = INF
	for c in CITY_CENTERS:
		var d:float = p.distance_to(c["pos"])
		if d < nearest:
			nearest = d
			best = c
	return best

static func region_at(p:Vector2) -> String:
	var c:Dictionary = nearest_city(p)
	if p.distance_to(c["pos"]) < float(c["radius"]):
		return str(c["name"])
	if p.y < -3700.0 and p.x < -3400.0:
		return "Mittelgebirge"
	if p.x > 3500.0 and p.y < 1500.0:
		return "Industriekorridor"
	if p.y > 4200.0:
		return "Nordheider Seenland"
	return "Wald- und Feldregion"

static func city_type(p:Vector2) -> String:
	var c:Dictionary = nearest_city(p)
	if p.distance_to(c["pos"]) < float(c["radius"]):
		return str(c["kind"])
	return "rural"

static func grid_distance(value:float, spacing:float) -> float:
	return abs(fposmod(value + spacing * 0.5, spacing) - spacing * 0.5)

static func road_distance(p:Vector2) -> float:
	var dx:float = grid_distance(p.x,CHUNK_SIZE)
	var dz:float = grid_distance(p.y,CHUNK_SIZE)
	if city_type(p) != "rural":
		dx=min(dx,abs(dx-100.0))
		dz=min(dz,abs(dz-100.0))
	return min(dx,dz)

static func height_at(x:float,z:float) -> float:
	var p:=Vector2(x,z)
	var h:float = sin(x * 0.00082) * 9.0 + cos(z * 0.0011) * 7.0
	h += sin((x+z)*0.0037)*2.8 + cos(x*0.0041-z*0.0025)*1.9
	if p.x < -3400.0 and p.y < -3500.0:
		h += 10.0 + abs(sin(x*0.00048)*cos(z*0.00058))*35.0
	# Grade roads gently into the landscape. Roadbed stays continuous at intersections.
	var blend:float = clampf((road_distance(p)-9.0)/34.0,0.0,1.0)
	return h * (0.14 + blend*0.86)

static func in_bounds(p:Vector2) -> bool:
	return abs(p.x) <= HALF_EXTENT and abs(p.y) <= HALF_EXTENT

static func destination(name:String) -> Vector2:
	for c in CITY_CENTERS:
		if c["name"] == name:
			return c["pos"]
	return Vector2.ZERO

static func route_points(a:Vector2,b:Vector2, horizontal_first:bool=true) -> Array[Vector2]:
	# Major road graph. Every 400 m a connected arterial road exists.
	var snap_a:=Vector2(roundf(a.x/CHUNK_SIZE)*CHUNK_SIZE,roundf(a.y/CHUNK_SIZE)*CHUNK_SIZE)
	var snap_b:=Vector2(roundf(b.x/CHUNK_SIZE)*CHUNK_SIZE,roundf(b.y/CHUNK_SIZE)*CHUNK_SIZE)
	var pts:Array[Vector2]=[snap_a]
	if horizontal_first:
		if not is_equal_approx(snap_a.x,snap_b.x): pts.append(Vector2(snap_b.x,snap_a.y))
	else:
		if not is_equal_approx(snap_a.y,snap_b.y): pts.append(Vector2(snap_a.x,snap_b.y))
	if pts[pts.size()-1].distance_to(snap_b)>1.0: pts.append(snap_b)
	if pts[pts.size()-1].distance_to(b)>1.0: pts.append(b)
	return pts

static func route_length(pts:Array[Vector2]) -> float:
	var total:float=0.0
	for i in range(1,pts.size()): total+=pts[i-1].distance_to(pts[i])
	return total
