extends RefCounted
const Data=preload("res://scripts/open_world/world_data.gd")
const SAVE_PATH="user://autoboss_open_world.cfg"
var money:int=5000
var reputation:int=15
var jobs_completed:int=0
var total_earnings:int=0
var depot_level:int=0
var staff:int=0
var engine_upgrade:int=0
var brake_upgrade:int=0
var active_job:Dictionary={}
var active_stage:String=""
var job_timer:float=0.0
var completed_by_class:Dictionary={}
var last_result:String=""
var contracts:Array[Dictionary]=[]

func _init()->void:
	create_contracts()
	generate_extra_contracts()
	set_contract_conditions()
	load_game()

func create_contracts()->void:
	var data:Array=[
		["Lindenfurt", "Lindenfurt", 0, 15, 280, "Stadtzustellung"],
		["Lindenfurt", "Lindenfurt", 1, 15, 390, "Geschäftskunde"],
		["Lindenfurt", "Bergstadt", 0, 16, 860, "Regionaltransfer"],
		["Lindenfurt", "Nordheide", 1, 18, 950, "Autohaus-Transfer"],
		["Lindenfurt", "Eisenhafen", 4, 20, 1340, "Gewerbetransfer"],
		["Lindenfurt", "Hafenwall", 3, 25, 1490, "Flottenwechsel"],
		["Bergstadt", "Lindenfurt", 2, 28, 1950, "Premium-Express"],
		["Nordheide", "Eisenhafen", 4, 30, 1790, "Nutzfahrzeug-Fahrt"],
		["Eisenhafen", "Bergstadt", 5, 36, 3300, "Schwertransport"],
		["Hafenwall", "Nordheide", 3, 40, 2550, "Spezialzustellung"],
		["Bergstadt", "Hafenwall", 2, 45, 3280, "Elite-Transfer"],
		["Eisenhafen", "Nordheide", 5, 55, 4400, "Logistik-Großauftrag"]
	]
	for i in range(data.size()):
		var d:Array=data[i]
		var start:Vector2=Data.destination(str(d[0]))
		var finish:Vector2=Data.destination(str(d[1]))
		var pickup:Vector2=start+Vector2(400,0)
		var destination:Vector2=finish+Vector2(-400,0)
		if i==0: destination=start+Vector2(0,-400)
		if i==1: destination=start+Vector2(-400,0)
		contracts.append({"id":i,"from":d[0],"to":d[1],"car":d[2],"required_rep":d[3],"reward":d[4],"title":d[5],"pickup_x":pickup.x,"pickup_z":pickup.y,"drop_x":destination.x,"drop_z":destination.y})


func generate_extra_contracts()->void:
	# Deterministic catalog with multiple route pairs; offers never require network.
	var rng:=RandomNumberGenerator.new()
	rng.seed=620026
	var places:Array=Data.CITY_CENTERS
	var variants:Array[String]=["Express-Überführung","Werkstattauftrag","Flottentausch","Langstreckentransfer","Premium-Zustellung","Sammlerauftrag","Firmenüberführung"]
	for i in range(32):
		var from_index:int=rng.randi_range(0,places.size()-1)
		var to_index:int=(from_index+rng.randi_range(1,places.size()-1))%places.size()
		var origin:Vector2=places[from_index]["pos"]
		var target:Vector2=places[to_index]["pos"]
		var cls:int=rng.randi_range(0,5)
		var dist:float=absf(origin.x-target.x)+absf(origin.y-target.y)
		var reward:int=roundi(350.0+dist*0.052+float(cls)*105.0)
		var rep:int=15+int(i/3)*3
		contracts.append({"id":100+i,"from":places[from_index]["name"],"to":places[to_index]["name"],"car":cls,
			"required_rep":rep,"reward":reward,"title":variants[i%variants.size()],
			"pickup_x":origin.x+400.0,"pickup_z":origin.y,"drop_x":target.x-400.0,"drop_z":target.y})

func set_contract_conditions()->void:
	# Conditions are deterministic and therefore survive saved active-job dictionaries.
	for i in range(contracts.size()):
		var contract:Dictionary=contracts[i]
		var urgency:bool= str(contract["title"]).contains("Express") or str(contract["title"]).contains("Eilige")
		var pickup:=Vector2(float(contract["pickup_x"]),float(contract["pickup_z"]))
		var drop:=Vector2(float(contract["drop_x"]),float(contract["drop_z"]))
		var direct_km:float=(absf(pickup.x-drop.x)+absf(pickup.y-drop.y))*0.001
		contract["urgent"]=urgency
		contract["deadline_minutes"]=roundi(maxf(9.0,direct_km/0.82+8.0)) if urgency else 0
		contract["damage_tolerance"]=2.0 if str(contract["title"]).contains("Premium") else 10.0
		contracts[i]=contract

func accept(index:int)->bool:
	if index<0 or index>=contracts.size() or active_stage!="":return false
	var job:Dictionary=contracts[index]
	if reputation<int(job["required_rep"]):return false
	active_job=job.duplicate(true)
	active_stage="pickup"
	job_timer=0.0
	save_game()
	return true

func target()->Vector2:
	if active_stage=="pickup":
		return Vector2(float(active_job["pickup_x"]),float(active_job["pickup_z"]))
	if active_stage=="delivery":
		return Vector2(float(active_job["drop_x"]),float(active_job["drop_z"]))
	return Vector2.ZERO

func destination_name()->String:
	if active_stage=="pickup":return "Abholung: "+str(active_job["from"])
	if active_stage=="delivery":return "Übergabe: "+str(active_job["to"])
	return "Freie Fahrt"

func pickup()->void:
	if active_stage!="pickup":return
	active_stage="delivery"
	job_timer=0.0
	save_game()

func finish(damage:float,fuel:float)->String:
	if active_stage!="delivery":return ""
	var base:int=int(active_job["reward"])
	var loss:int=roundi(float(base)*0.45*damage/100.0)
	var clean_bonus:int=roundi(float(base)*0.15) if damage<0.5 else 0
	var fuel_bonus:int=roundi(float(base)*0.05) if fuel>=20.0 else 0
	var on_time_bonus:int=0
	var deadline:int=int(active_job.get("deadline_minutes",0))
	if deadline>0 and job_timer<=float(deadline)*60.0:
		on_time_bonus=roundi(float(base)*0.18)
	var premium_bonus:int=0
	if damage<float(active_job.get("damage_tolerance",10.0)):
		premium_bonus=roundi(float(base)*0.06)
	var revenue:int=maxi(0,base-loss+clean_bonus+fuel_bonus+on_time_bonus+premium_bonus)
	money+=revenue
	total_earnings+=revenue
	jobs_completed+=1
	reputation+=3 if damage<5.0 else (1 if damage<25.0 else -2)
	var key:String=str(active_job["car"])
	completed_by_class[key]=int(completed_by_class.get(key,0))+1
	last_result="AUFTRAG ERFÜLLT!\nGrundlohn: %d €\nSchäden: −%d €\nSorgfalt: +%d €\nKraftstoff: +%d €\nPünktlichkeit: +%d €\nVertragsqualität: +%d €\nAUSZAHLUNG: %d €" % [base,loss,clean_bonus,fuel_bonus,on_time_bonus,premium_bonus,revenue]
	active_job={};active_stage="";job_timer=0.0
	save_game()
	return last_result

func invest(kind:String)->String:
	var cost:int=0
	match kind:
		"engine": cost=650+engine_upgrade*450
		"brakes": cost=540+brake_upgrade*400
		"depot": cost=7500+depot_level*9000
		"staff": cost=12500+staff*7500
		_: return "Unbekannte Investition"
	if money<cost:return "Zu wenig Kapital (%d € erforderlich)" % cost
	money-=cost
	match kind:
		"engine": engine_upgrade+=1
		"brakes": brake_upgrade+=1
		"depot": depot_level+=1
		"staff":staff+=1
	save_game()
	return "Investition erfolgreich: −%d €" % cost

func rank()->String:
	if jobs_completed>=45:return "Elite-Transporteur"
	if jobs_completed>=25:return "Regionalleiter"
	if jobs_completed>=12:return "Logistikunternehmer"
	if jobs_completed>=5:return "Berufsüberführer"
	return "Einsteiger"

func save_game()->void:
	var cfg:=ConfigFile.new()
	cfg.set_value("career","money",money)
	cfg.set_value("career","reputation",reputation)
	cfg.set_value("career","jobs_completed",jobs_completed)
	cfg.set_value("career","total_earnings",total_earnings)
	cfg.set_value("career","depot_level",depot_level)
	cfg.set_value("career","staff",staff)
	cfg.set_value("career","engine_upgrade",engine_upgrade)
	cfg.set_value("career","brake_upgrade",brake_upgrade)
	cfg.set_value("career","completed_by_class",completed_by_class)
	cfg.set_value("job","active",active_job)
	cfg.set_value("job","stage",active_stage)
	cfg.set_value("job","time",job_timer)
	cfg.save(SAVE_PATH)

func load_game()->void:
	var cfg:=ConfigFile.new()
	if cfg.load(SAVE_PATH)!=OK:return
	money=int(cfg.get_value("career","money",5000))
	reputation=int(cfg.get_value("career","reputation",15))
	jobs_completed=int(cfg.get_value("career","jobs_completed",0))
	total_earnings=int(cfg.get_value("career","total_earnings",0))
	depot_level=int(cfg.get_value("career","depot_level",0))
	staff=int(cfg.get_value("career","staff",0))
	engine_upgrade=int(cfg.get_value("career","engine_upgrade",0))
	brake_upgrade=int(cfg.get_value("career","brake_upgrade",0))
	completed_by_class=cfg.get_value("career","completed_by_class",{})
	active_job=cfg.get_value("job","active",{})
	active_stage=str(cfg.get_value("job","stage",""))
	job_timer=float(cfg.get_value("job","time",0.0))
	if active_job.is_empty():active_stage=""
