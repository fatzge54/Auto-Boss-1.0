"""Offline consistency checks. Godot and Android runtime testing are still required."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
DIR=ROOT/'scripts'/'open_world'
scripts={p.name:p.read_text(encoding='utf8') for p in DIR.glob('*.gd')}
expected={'game.gd','world_data.gd','world_streamer.gd','vehicle.gd','career.gd','traffic.gd','hud.gd','minimap.gd','world_map.gd','rain_fx.gd','city_quarter.gd'}
assert set(scripts)==expected,(expected-set(scripts),set(scripts)-expected)
assert (ROOT/'project.godot').is_file()
assert (ROOT/'main.tscn').is_file()
assert 'res://scripts/open_world/game.gd' in (ROOT/'main.tscn').read_text(encoding='utf8')
for filename,src in scripts.items():
    stack=[]
    pairs={')':'(',']':'[','}':'{'}
    is_text=False
    is_escape=False
    for n,line in enumerate(src.splitlines(),1):
        assert '\t ' not in line[:len(line)-len(line.lstrip())],(filename,n,'mixed indentation')
        for ch in line:
            if is_text:
                if is_escape:is_escape=False
                elif ch=='\\':is_escape=True
                elif ch=='"':is_text=False
                continue
            if ch=='#':break
            if ch=='"':is_text=True;continue
            if ch in '([{':stack.append((ch,n))
            if ch in ')]}':
                assert stack and stack[-1][0]==pairs[ch],(filename,n,'unbalanced delimiter')
                stack.pop()
        assert not is_text,(filename,n,'string crosses line')
    assert not stack,(filename,stack[-1] if stack else None,'unclosed delimiter')
    assert src.startswith('extends '),(filename,'missing extends')
    for ref in re.findall(r'res://([^"\n]+)',src):
        assert (ROOT/ref).exists(),(filename,'missing resource',ref)
for fname,needles in {
    'world_streamer.gd':['func make_road_environment','func make_gable_mesh','func update_visual_weather','func update_stream','var detail_level:int'],
    'game.gd':['func next_instruction','func create_headlights','RainFX.new()','world.update_visual_weather','save_acc'],
    'career.gd':['set_contract_conditions()','deadline_minutes','on_time_bonus','cfg.set_value("job","time"'],
    'vehicle.gd':['make_tapered_shell','func drive','func receive_impact'],
    'traffic.gd':['light_clock','cruise_speeds','var stop:bool'],
    'hud.gd':['AUTO BOSS','WorldMap.new()'],
    'world_map.gd':['func _draw','proj('],
    'rain_fx.gd':['func tick','visible_instance_count'],
}.items():
    for needle in needles:assert needle in scripts[fname],(fname,'missing feature',needle)
assert 'const HALF_EXTENT: float = 12500.0' in scripts['world_data.gd']
assert 'const CHUNK_SIZE: float = 400.0' in scripts['world_data.gd']
assert 'for i in range(32)' in scripts['career.gd']
assert (ROOT/'assets/open_world/engine_loop.wav').is_file()
assert '.github/workflows/android-build.yml' in [str(p.relative_to(ROOT)) for p in ROOT.rglob('android-build.yml')]
print('PASS: 11 scripts, resources, delimiters, scene references, extended world features, workflows.')
print('LIMITATION: The scripts have NOT been parsed/executed in the Godot runtime here.')

for filename,features in {
    "vehicle.gd":["var offroad:bool", "surface_grip", "power_curve", "var allowed:float"],
    "game.gd":["func quick_action", "recovered_fuel", "cfg.set_value(\"vehicle\",\"damage\"", "var surface_warning:String"],
    "hud.gd":["ERSTEN TRANSPORT SOFORT STARTEN", "pickup_button.visible=game.career.active_stage", "game.quick_action()"],
    "world_streamer.gd":["street_lots", "tree_lots", "make_direction_sign(root,p,terrain_type)"],
}.items():
    for feature in features:
        assert feature in scripts[filename], (filename, "missing 71 feature", feature)
assert 'AUTO BOSS' in (ROOT/'project.godot').read_text(encoding='utf8')
print('PASS: version 71 features, roadside placement, offroad handling, direct first contract and save-data fields.')

# 71.2 build regression: a missing wheel batch variable previously stopped
# GDScript compilation. Keep these two tests independent of release numbers.
assert re.search(r"\bvar\s+car_wheels\s*:\s*Array\[Transform3D\]\s*=", scripts["world_streamer.gd"])
assert "add_batch(root,box_mesh,wheelhouse_material,car_wheels)" in scripts["world_streamer.gd"]
assert "spawn_chunk(player_cell)" in scripts["world_streamer.gd"]
assert "rng.randf_range(135.0,520.0)" in scripts["traffic.gd"]
print("PASS: 71.2 startup streaming, distant AI spawning and car_wheels build regression.")

# 71.3 physics and roadside-placement regressions (static checks only).
assert "static func pavement_clearance" in scripts["world_data.gd"]
assert "static func suggested_cruise_speed" in scripts["world_data.gd"]
vehicle=scripts["vehicle.gd"]
assert "var assisted_speed_cap:float=0.0" in vehicle
assert "var bicycle_rate:float" in vehicle and "var lateral_limit:float" in vehicle
assert vehicle.index("if braking>0.05:") < vehicle.index("elif throttle>0.05 and fuel>0.0:")
assert "offroad=edge>1.7" in vehicle
assert "speed_assist_enabled" in scripts["game.gd"]
assert "func toggle_speed_assist" in scripts["game.gd"]
assert 'cfg.set_value("world","speed_assist",speed_assist_enabled)' in scripts["game.gd"]
assert "LIMIT-HILFE AN" in scripts["hud.gd"]
assert "[-174.0,-144.0,-65.0,65.0,144.0,174.0]" in scripts["world_streamer.gd"]
print("PASS: 71.3 throttle/braking, lateral steering cap, street lots, and optional persisted driving assist.")

# 71.4 ambience / traffic regressions. These are source checks, not Godot builds.
world=scripts["world_streamer.gd"]
traffic=scripts["traffic.gd"]
for needle in ["func make_regional_character", "add_batch(root,bale_mesh,hay_mat,bales)", "add_batch(root,box_mesh,freight_blue_mat,containers_blue)", "if placed>=building_count:break", "occupied.grow(2.4).intersects(footprint)", "building_colliders[collider_key]=solid_rects"]:
    assert needle in world, ("71.4 world",needle)
for needle in ["var has_signal:bool", "var relative_speed:float=(player_velocity-motion[i]*speeds[i]).length()", "var player_ahead:float", "for attempt in range(12)"]:
    assert needle in traffic, ("71.4 traffic",needle)
assert "AUTO BOSS 71.4" in scripts["hud.gd"]
print("PASS: 71.4 regional props, building separation, traffic light and collision consistency.")

# 71.8: modular Lindenfurt district is sector-owned and shares collision rectangles.
city=scripts["city_quarter.gd"]
assert 'func build(world_center:Vector2,quality:int)->Array[Rect2]' in city
assert '_emit_batches()' in city and 'MultiMeshInstance3D.new()' in city
assert 'Data.pavement_clearance(center_p)' in city
assert 'building_colliders[Vector2i(' in scripts['world_streamer.gd']
assert 'quarter.build(center,detail_level)' in scripts['world_streamer.gd']
assert 'if kind=="city" and absf(center.x)<=400.0' in scripts['world_streamer.gd']
print("PASS: 71.8 streamed modular Lindenfurt, texture resources and collider registration.")
