"""Offline structural smoke tests; NOT a substitute for parsing with Godot."""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
script_dir=ROOT/'scripts'/'open_world'
scripts={p.name:p.read_text(encoding='utf-8') for p in script_dir.glob('*.gd')}
expected=['game.gd','world_data.gd','world_streamer.gd','vehicle.gd','career.gd','traffic.gd','hud.gd','minimap.gd']
assert all(x in scripts for x in expected), 'Missing GDScript module'
assert 'res://scripts/open_world/game.gd' in (ROOT/'main.tscn').read_text()
assert 'res://scripts/main.gd' in (ROOT/'legacy_main.tscn').read_text()
assert 'wrap_road(' not in scripts['game.gd'], 'Old 3 km reset still active'
assert 'const HALF_EXTENT: float = 12500.0' in scripts['world_data.gd']
assert 'const CHUNK_SIZE: float = 400.0' in scripts['world_data.gd']
assert 'var stream_radius:int=2' in scripts['world_streamer.gd']
assert 'const TRAFFIC_LIMIT:int=16' in scripts['traffic.gd']
assert 'for i in range(32)' in scripts['career.gd']
assert (ROOT/'assets'/'open_world'/'engine_loop.wav').exists()
for filename,src in scripts.items():
    # Strip GDScript comments and string literals before checking matching tokens.
    stripped=''
    in_string=False
    escaped=False
    for line in src.splitlines():
        for char in line:
            if in_string:
                if escaped: escaped=False
                elif char=='\\': escaped=True
                elif char=='"': in_string=False
                continue
            if char=='"': in_string=True;continue
            if char=='#':break
            stripped+=char
        stripped+='\n'
    stack=[]
    pair={')':'(',']':'[','}':'{'}
    for tok in stripped:
        if tok in '([{':stack.append(tok)
        elif tok in ')]}':
            assert stack and stack[-1]==pair[tok], (filename,'unbalanced',tok)
            stack.pop()
    assert not stack, (filename,'unbalanced',stack)
    assert 'extends ' in src.splitlines()[0], (filename,'missing extends')
    for m in re.finditer(r'res://([^"\s]+)',src):
        assert (ROOT/m.group(1)).exists(), (filename,'missing resource',m.group(1))
print(f'PASS: {len(scripts)} Open-World GDScript files, resource references, scene links, 25km coordinates, fixed limits and basic token structure')
print('NOTE: GDScript grammar and Android runtime must still be tested in Godot 4.7.2.')
