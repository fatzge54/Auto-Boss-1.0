from pathlib import Path
import numpy as np
from scipy.ndimage import gaussian_filter, sobel
from PIL import Image, ImageDraw, ImageFilter
import math,random
OUT=Path(__file__).resolve().parents[1] / 'assets' / 'graphics50'
OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(508200)
n=1024

def layer(scale, amp=1.0):
    noise=rng.random((n,n),dtype=np.float32)
    return (gaussian_filter(noise,scale,mode='wrap')-0.5)*amp

def rescale(a):
    return (a-a.mean())/(a.std()+1e-5)

# Realistic fine aggregate and pigmented road texture; seamless stochastic wrap.
fine=rescale(layer(0.6)); mids=rescale(layer(2.5)); large=rescale(layer(19)); grain=rescale(layer(0.1))
salt=rng.random((n,n))
chips=np.maximum(0,(salt-0.973))*2.6
asphalt=np.zeros((n,n,3),dtype=np.float32)
base=np.array([107,110,113],np.float32)
shade=2.9*fine+3.8*mids+4.1*large+2.0*grain+chips*65
for c in range(3): asphalt[:,:,c]=base[c]+shade*(0.97+c*0.015)
asphalt=np.uint8(np.clip(asphalt,15,142))
Image.fromarray(asphalt,'RGB').save(OUT/'asphalt_albedo.png',optimize=True)
# Subtle normal from low strength heightfield; world-pos texture repeated ~ every 7 m
height=gaussian_filter(shade,0.6,mode='wrap')
dx=(np.roll(height,-1,axis=1)-np.roll(height,1,axis=1))*0.012
dy=(np.roll(height,-1,axis=0)-np.roll(height,1,axis=0))*0.012
nz=1.0/np.sqrt(1+dx*dx+dy*dy)
normal=np.uint8(np.clip(np.stack([(-dx*nz*.5+.5)*255,(-dy*nz*.5+.5)*255,(nz*.5+.5)*255],axis=-1),0,255))
Image.fromarray(normal,'RGB').save(OUT/'asphalt_normal.png',optimize=True)

# Grass texture: muted woodland green with earth microvariation; detail mipmaps.
large=rescale(layer(18)); small=rescale(layer(1.6)); tiny=rescale(layer(0.5)); special=rescale(layer(36))
veg=1.9*tiny+3.5*small+6.8*large+5.0*special
grass=np.zeros((n,n,3),dtype=np.float32)
for i,base in enumerate([95,135,84]): grass[:,:,i]=base+veg*[0.85,1.15,0.70][i]
# Gold and soil patches
brown=np.clip((special-0.7)*0.10,0,0.19)[:,:,None]
grass=grass*(1-brown)+np.array([104,91,57])*brown
Image.fromarray(np.uint8(np.clip(grass,20,185)),'RGB').save(OUT/'grass_albedo.png',optimize=True)

# Two detailed tree silhouettes; alpha-clipped crossed planes are extremely low-poly.
def draw_tree(seed,kind):
    r=random.Random(seed)
    canvas=Image.new('RGBA',(1024,1024),(0,0,0,0))
    d=ImageDraw.Draw(canvas,'RGBA')
    x0=512; y_bottom=1004
    if kind=='fir':
        # trunk and layered whorls: irregular needle clusters rather than geometric cones
        d.line((x0,990,x0-7,195),fill=(76,56,43,245),width=29)
        for level in range(9):
            yy=250+level*72
            radius=75+level*18
            for _ in range(22+level*5):
                xx=x0+r.uniform(-radius,radius)
                y=yy+r.uniform(-43,49)
                if abs(xx-x0)>radius*(0.94-(yy-y)/650): continue
                width=r.randint(12,48); hh=r.randint(22,65)
                green=r.choice([(31,69,42),(39,81,45),(52,96,53),(29,60,37),(64,105,58),(40,76,47)])
                d.ellipse((xx-width,y-hh,xx+width,y+hh),fill=(*green,r.randint(218,255)))
            # fan needle twigs
            for side in (-1,1):
                d.line((x0,yy+10,x0+side*(radius+10),yy+57),fill=(44,78,48,245),width=11)
        for _ in range(165):
            yy=r.uniform(188,891); frac=(yy-190)/700
            xx=x0+r.uniform(-1,1)*(42+frac*210)
            rr=r.uniform(4,13)
            d.ellipse((xx-rr,yy-rr,xx+rr,yy+rr),fill=r.choice([(79,121,68,200),(18,55,33,230),(68,105,55,225)]))
    else:
        # Brown branched trunk with asymmetric fine branches.
        d.polygon([(476,1004),(545,1004),(526,590),(507,580)],fill=(68,56,43,255))
        d.line((508,985,514,490),fill=(89,69,45,255),width=31)
        for _ in range(32):
            y=r.randint(380,735); side=r.choice([-1,1]); length=r.randint(78,208)
            d.line((509,y+70,509+side*length,y-r.randint(50,165)),fill=(79,62,44,255),width=r.randint(8,18))
        # Layered overlapping canopies leave a varied perimeter.
        centers=[(r.randint(290,740),r.randint(170,560),r.randint(85,155)) for _ in range(30)]
        palette=[(43,85,42),(60,104,45),(76,121,56),(31,70,38),(91,126,56),(49,92,45),(111,137,65)]
        for x,y,rad in centers:
            for _ in range(40):
                xx=x+r.gauss(0,rad*.55); yy=y+r.gauss(0,rad*.34)
                rr=r.uniform(12,39)
                if xx<58 or xx>960 or yy<40 or yy>740:continue
                col=r.choice(palette); a=r.randint(195,250)
                d.ellipse((xx-rr,yy-rr*.65,xx+rr,yy+rr*.65),fill=(*col,a))
                if r.random()<.3:
                    light=tuple(min(255,c+18) for c in col)
                    d.ellipse((xx-rr*.7,yy-rr*.55,xx+rr*.2,yy),fill=(*light,r.randint(130,220)))
    # Trim alpha artifacts near upper side, ensure transparency retained
    canvas.save(OUT/f'tree_{kind}.png',optimize=True)

draw_tree(721,'fir'); draw_tree(481,'oak')
# Small cloud decal for sky planes: noise-modulated soft streaked wisps (optional)
s=512
rr=np.random.default_rng(950)
xx,yy=np.meshgrid(np.linspace(-1,1,s),np.linspace(-1,1,s))
cloud=np.zeros((s,s),np.float32)
for j in range(17):
    cx,cy=rr.uniform(-.58,.58),rr.uniform(-.19,.21)
    ax,ay=rr.uniform(.15,.34),rr.uniform(.12,.27)
    cloud+=np.exp(-(((xx-cx)/ax)**2+((yy-cy)/ay)**2)*1.4)*rr.uniform(.2,.6)
cloud=np.clip((cloud-.13)*115,0,154)
cloud=gaussian_filter(cloud,3.5)
a=np.stack([np.full_like(cloud,248),np.full_like(cloud,251),np.full_like(cloud,250),cloud],axis=-1)
Image.fromarray(np.uint8(a),'RGBA').save(OUT/'soft_cloud.png',optimize=True)
for f in OUT.iterdir():print(f.name, f.stat().st_size)
# Natural shrub cutout, used in GPU instance groups in place of spherical primitives.
r=random.Random(44791)
bush=Image.new('RGBA',(512,512),(0,0,0,0))
d=ImageDraw.Draw(bush,'RGBA')
for k in range(750):
    xx=r.gauss(256,128); yy=r.gauss(338,71)
    if not 15<xx<498 or not 100<yy<483:continue
    if ((xx-256)/249)**2 + ((yy-360)/195)**2>1:continue
    radius=r.uniform(5,17)
    color=r.choice([(41,86,37),(46,98,41),(77,118,49),(29,64,31),(58,102,45),(94,126,60)])
    d.ellipse((xx-radius,yy-radius*.63,xx+radius,yy+radius*.63),fill=(*color,r.randrange(195,256)))
for k in range(420):
    xx=r.uniform(23,489); yy=r.uniform(210,465)
    if ((xx-256)/240)**2 + ((yy-350)/200)**2>1:continue
    rad=r.uniform(1.7,4.4)
    col=r.choice([(119,139,71),(91,143,60),(13,52,27)])
    d.ellipse((xx-rad,yy-rad,xx+rad,yy+rad),fill=(*col,215))
bush.save(OUT/'shrub_cutout.png',optimize=True)
print('shrub', (OUT/'shrub_cutout.png').stat().st_size)
