"""Offline consistency checks. Godot and Android runtime testing are still required."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
DIR=ROOT/'scripts'/'open_world'
scripts={p.name:p.read_text(encoding='utf8') for p in DIR.glob('*.gd')}
expected={'game.gd','world_data.gd','world_streamer.gd','vehicle.gd','career.gd','traffic.gd','hud.gd','minimap.gd','world_map.gd','rain_fx.gd'}
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
    'hud.gd':['AUTO BOSS 71.0','WorldMap.new()'],
    'world_map.gd':['func _draw','proj('],
    'rain_fx.gd':['func tick','visible_instance_count'],
}.items():
    for needle in needles:assert needle in scripts[fname],(fname,'missing feature',needle)
assert 'const HALF_EXTENT: float = 12500.0' in scripts['world_data.gd']
assert 'const CHUNK_SIZE: float = 400.0' in scripts['world_data.gd']
assert 'for i in range(32)' in scripts['career.gd']
assert (ROOT/'assets/open_world/engine_loop.wav').is_file()
assert '.github/workflows/android-build.yml' in [str(p.relative_to(ROOT)) for p in ROOT.rglob('android-build.yml')]
print('PASS: 10 scripts, resources, delimiters, scene references, extended world features, workflows.')
print('LIMITATION: The scripts have NOT been parsed/executed in the Godot runtime here.')

for filename,features in {
    "vehicle.gd":["var offroad:bool", "surface_grip", "power_curve", "var surface_limit:float"],
    "game.gd":["func quick_action", "recovered_fuel", "cfg.set_value(\"vehicle\",\"damage\"", "var surface_warning:String"],
    "hud.gd":["ERSTEN TRANSPORT SOFORT STARTEN", "pickup_button.visible=game.career.active_stage", "game.quick_action()"],
    "world_streamer.gd":["street_lots", "tree_lots", "make_direction_sign(root,p,terrain_type)"],
}.items():
    for feature in features:
        assert feature in scripts[filename], (filename, "missing 71 feature", feature)
assert 'AUTO BOSS 71.0' in (ROOT/'project.godot').read_text(encoding='utf8')
print('PASS: version 71 features, roadside placement, offroad handling, direct first contract and save-data fields.')
