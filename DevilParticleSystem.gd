#This is the include file for the "Devil Particle System" by "bytecode77"
#The link to the system's BlitzBasic.com page: "http://www.blitzbasic.com/toolbox/toolbox.php?tool=174"
#The link to the original page: "https://bytecode77.com/coding/devilengines/devilparticlesystem"
#All rights for this file go to "bytecode77"
#
#This file also has been modified a bit to suit better for SCP:CB


class Template:
	var sub_template: Array[Template] #[7]                                  #Sub templates
	var emitter_blend                                             #blendmode of emitter entity
	var interval
	var particles_per_interval                          #particle interval
	var max_particles                                             #max particles
	var emitter_max_time                                          #Emitter life time
	var min_time
	var max_time                                        #Particle life time
	var tex
	var animtex
	var texframe: float
	var maxtexframes
	var texspeed: float          #Texture
	var min_ox: float
	var max_ox: float
	var min_oy: float
	var max_oy: float
	var min_oz: float
	var max_oz: float      #Offset
	var min_xv: float
	var max_xv: float
	var min_yv: float
	var max_yv: float
	var min_zv: float
	var max_zv: float      #Velocity
	var rot_vel1: float
	var rot_vel2: float
	var align_to_fall
	var align_to_fall_offset #Rotation
	var gravity: float                                                  #Gravity
	var alpha: float
	var alpha_vel                                         #Alpha
	var sx: float
	var sy: float
	var size_multiplicator1: float
	var size_multiplicator2: float      #Size
	var size_add: float
	var size_mult: float                                     #Size velocity
	var r1
	var g1
	var b1
	var r2
	var g2
	var b2                                    #Colors
	var Brightness                                                #Brightness
	var floor_y: float
	var floor_bounce: float                                   #Floor
	var pitch_fix
	var yaw_fix                                        #Fix angles

	var yaw: float

class Emitter:
	var fixed
	var cnt_loop: float
	var age: float
	var max_time: float
	var tmp: Template
	var owner
	var ent
	var surf
	var del
	var frozen

class Particle:
	var emitter: Emitter
	var age
	var max_time  #Life time
	var x: float
	var y: float
	var z: float     #Position
	var xv: float
	var yv: float
	var zv: float  #Velocity
	var rot: float
	var rot_vel: float #Rotation
	var sx: float
	var sy: float       #Size



func InitParticles(cam) -> void:
	ParticleCam = cam
	ParticlePiv = CreatePivot()
	SeedRnd(MilliSecs())

func FreeParticles() -> void:
	for tmp: Template in EachTemplate:
		FreeTemplate(Handle(tmp))

	for e: Emitter in EachEmitter:
		FreeEmitter(e.ent)

	Delete(EachTemplate)
	Delete(EachEmitter)
	Delete(EachParticle)
	if ParticlePiv:
		FreeEntity(ParticlePiv)

func CreateTemplate() -> void:
	tmp.Template = Template.new()
	template = Handle(tmp)
	SetTemplateEmitterBlend(template, 3)
	SetTemplateInterval(template, 1)
	SetTemplateParticlesPerInterval(template, 1)
	SetTemplateMaxParticles(template, -1)
	SetTemplateEmitterLifeTime(template, 100)
	SetTemplateParticleLifeTime(template, 0, 20)
	SetTemplateAlpha(template, 1)
	SetTemplateSize(template, 1, 1)
	SetTemplateSizeVel(template, 0, 1)
	SetTemplateColors(template, 0xFFFFFF, 0xFFFFFF)
	SetTemplateBrightness(template, 1)
	SetTemplateFloor(template, -1000000)
	SetTemplateFixAngles(template, -1, -1)
	return Handle(tmp)

func FreeTemplate(template) -> void:
	tmp.Template = Object.Template(template)
	if tmp.tex:
		FreeTexture(tmp.tex)

	for i: int in range(8):
		if tmp.sub_template[i]:
			FreeTemplate(Handle(tmp.sub_template[i]))

	Delete(tmp)

func SetTemplateEmitterBlend(template, emitter_blend) -> void:
	tmp.Template = Object.Template(template)
	tmp.emitter_blend = emitter_blend

func SetTemplateInterval(template, interval) -> void:
	tmp.Template = Object.Template(template)
	tmp.interval = interval

func SetTemplateParticlesPerInterval(template, particles_per_interval) -> void:
	tmp.Template = Object.Template(template)
	tmp.particles_per_interval = particles_per_interval

func SetTemplateMaxParticles(template, max_particles) -> void:
	tmp.Template = Object.Template(template)
	tmp.max_particles = max_particles

func SetTemplateParticleLifeTime(template, min_time, max_time) -> void:
	tmp.Template = Object.Template(template)
	tmp.min_time = min_time
	tmp.max_time = max_time

func SetTemplateEmitterLifeTime(template, emitter_max_time) -> void:
	tmp.Template = Object.Template(template)
	tmp.emitter_max_time = emitter_max_time

func SetTemplateTexture(template, path: String, mode = 0, blend = 1) -> void:
	tmp.Template = Object.Template(template)
	tmp.tex = LoadTexture(path, mode)
	TextureBlend(tmp.tex, blend)

func SetTemplateAnimTexture(template, path: String, mode, blend, w, h, maxframes, speed: float = 1) -> void:
	tmp.Template = Object.Template(template)
	tmp.animtex = True
	tmp.maxtexframes = maxframes
	tmp.texspeed = speed
	tmp.tex = LoadAnimTexture(path, mode, w, h, 0, tmp.maxtexframes)
	TextureBlend(tmp.tex, blend)

func SetTemplateOffset(template, min_ox: float, max_ox: float, min_oy: float, max_oy: float, min_oz: float, max_oz: float) -> void:
	tmp.Template = Object.Template(template)
	tmp.min_ox = min_ox
	tmp.max_ox = max_ox
	tmp.min_oy = min_oy
	tmp.max_oy = max_oy
	tmp.min_oz = min_oz
	tmp.max_oz = max_oz

func SetTemplateVelocity(template, min_xv: float, max_xv: float, min_yv: float, max_yv: float, min_zv: float, max_zv: float) -> void:
	tmp.Template = Object.Template(template)
	tmp.min_xv = min_xv
	tmp.max_xv = max_xv
	tmp.min_yv = min_yv
	tmp.max_yv = max_yv
	tmp.min_zv = min_zv
	tmp.max_zv = max_zv

func SetTemplateRotation(template, rot_vel1: float, rot_vel2: float) -> void:
	tmp.Template = Object.Template(template)
	tmp.rot_vel1 = rot_vel1
	tmp.rot_vel2 = rot_vel2

func SetTemplateAlignToFall(template, align_to_fall, align_to_fall_offset = 0) -> void:
	tmp.Template = Object.Template(template)
	tmp.align_to_fall = align_to_fall
	tmp.align_to_fall_offset = align_to_fall_offset

func SetTemplateGravity(template, gravity: float) -> void:
	tmp.Template = Object.Template(template)
	tmp.gravity = gravity

func SetTemplateSize(template, sx: float, sy: float, size_multiplicator1: float = 1, size_multiplicator2: float = 1) -> void:
	tmp.Template = Object.Template(template)
	tmp.sx = sx
	tmp.sy = sy
	tmp.size_multiplicator1 = size_multiplicator1
	tmp.size_multiplicator2 = size_multiplicator2

func SetTemplateSizeVel(template, size_add: float, size_mult: float) -> void:
	tmp.Template = Object.Template(template)
	tmp.size_add = size_add
	tmp.size_mult = size_mult

func SetTemplateAlpha(template, alpha: float) -> void:
	tmp.Template = Object.Template(template)
	tmp.alpha = alpha

func SetTemplateAlphaVel(template, alpha_vel) -> void:
	tmp.Template = Object.Template(template)
	tmp.alpha_vel = alpha_vel

func SetTemplateColors(template, col1, col2) -> void:
	tmp.Template = Object.Template(template)
	tmp.r1 = (col1 & 0xFF0000) / 0x10000
	tmp.g1 = (col1 & 0xFF00) / 0x100
	tmp.b1 = col1 & 0xFF
	tmp.r2 = (col2 & 0xFF0000) / 0x10000
	tmp.g2 = (col2 & 0xFF00) / 0x100
	tmp.b2 = col2 & 0xFF

func SetTemplateBrightness(template, brightness) -> void:
	tmp.Template = Object.Template(template)
	tmp.brightness = brightness

func SetTemplateFloor(template, floor_y: float, floor_bounce: float = 0.5) -> void:
	tmp.Template = Object.Template(template)
	tmp.floor_y = floor_y
	tmp.floor_bounce = floor_bounce

func SetTemplateFixAngles(template, pitch_fix, yaw_fix) -> void:
	tmp.Template = Object.Template(template)
	tmp.pitch_fix = pitch_fix
	tmp.yaw_fix = yaw_fix

func SetTemplateSubTemplate(template, sub_template, for_each_particle: bool = false) -> void:
	tmp.Template = Object.Template(template)
	for i: int in range(8):
		if !tmp.sub_template[i]:
			tmp.sub_template[i] = Object.Template(sub_template)
			break

func SetEmitter(owner, template, fixed: bool = false) -> void:
	e.Emitter = Emitter.new()
	if fixed:
		e.owner = CreatePivot()
		PositionEntity(e.owner, EntityX(owner), EntityY(owner), EntityZ(owner))
		e.fixed = True
	else:
		e.owner = owner

	e.ent = CreateMesh()
	NameEntity(e.ent,"Emitter3")
	e.surf = CreateSurface(e.ent)
	e.tmp = Object.Template(template)
	e.max_time = e.tmp.emitter_max_time
	EntityBlend(e.ent, e.tmp.emitter_blend)
	EntityFX(e.ent, 34)
	if e.tmp.tex:
		EntityTexture(e.ent, e.tmp.tex)

	for i: int in range(8):
		if e.tmp.sub_template[i]:
			if e.tmp.sub_template[i].tex:
				SetEmitter(owner, Handle(e.tmp.sub_template[i]), fixed)

	return e.ent

func FreeEmitter(ent, delete_particles: bool = True) -> void:
	for e: Emitter in EachEmitter:
		if e.owner == ent:
			if delete_particles:
				for p: Particle in EachParticle:
					if p.emitter == e:
						Delete(p)

				FreeEntity(e.ent)
				if e.fixed and e.owner:
					FreeEntity(e.owner)

				Delete(e)
			else:
				e.del = True

func FreezeEmitter(ent) -> void:
	for e: Emitter in EachEmitter:
		if e.owner == ent:
			e.frozen = True

func UnfreezeEmitter(ent) -> void:
	for e: Emitter in EachEmitter:
		if e.owner == ent:
			e.frozen = False

func SetTemplateYaw(template,yaw: float) -> void:
	tmp.template = Object.Template(template)
	tmp.yaw = yaw

func UpdateParticles_Devil() -> void:

	for e: Emitter in EachEmitter:
		if e.tmp.max_particles > -1:
			cnt_particles = 0
			for p: Particle in EachParticle:
				if p.emitter == e:
					cnt_particles += 1

		ClearSurface(e.surf)
		if e.max_time > -1:
			if e.age > e.max_time:
				e.del = True
			else:
				e.age += 1

		if !e.frozen:
			e.cnt_loop = (e.cnt_loop + 1) % e.tmp.interval
			if e.cnt_loop == 0 and !e.del:
				for i: int in range(1, e.tmp.particles_per_interval + 1):
					if (e.tmp.max_particles > -1 and cnt_particles < e.tmp.max_particles) or e.tmp.max_particles == -1:
						p.Particle = Particle.new()
						p.emitter = e
						p.max_time = Rand(e.tmp.min_time, e.tmp.max_time)
						p.x = EntityX(e.owner, True) + Rnd(e.tmp.min_ox, e.tmp.max_ox)
						p.y = EntityY(e.owner, True) + Rnd(e.tmp.min_oy, e.tmp.max_oy)
						p.z = EntityZ(e.owner, True) + Rnd(e.tmp.min_oz, e.tmp.max_oz)
						p.xv = Rnd(e.tmp.min_xv, e.tmp.max_xv)
						p.yv = Rnd(e.tmp.min_yv, e.tmp.max_yv)
						p.zv = Rnd(e.tmp.min_zv, e.tmp.max_zv)
						p.rot_vel = Rnd(e.tmp.rot_vel1, e.tmp.rot_vel2)
						sm = Rnd(e.tmp.size_multiplicator1, e.tmp.size_multiplicator2)
						p.sx = p.emitter.tmp.sx * sm
						p.sy = p.emitter.tmp.sy * sm

		if e.tmp.animtex:
			e.tmp.texframe += e.tmp.texspeed
			if e.tmp.texframe > e.tmp.maxtexframes - 1:
				e.tmp.texframe = 0
			EntityTexture(e.ent, e.tmp.tex, e.tmp.texframe)

		frame += texspeed
		if e.del:
			del = True
			for p: Particle in EachParticle:
				if p.emitter == e:
					del = False

			if del:
				FreeEntity(e.ent)
				if e.fixed and e.owner:
					FreeEntity(e.owner)
				Delete(e)

	PositionEntity(ParticlePiv, EntityX(ParticleCam, True), EntityY(ParticleCam, True), EntityZ(ParticleCam, True))
	var cam_pitch: float = EntityPitch(ParticleCam, True)
	var cam_yaw: float = EntityYaw(ParticleCam, True)
	var cam_roll: float = EntityRoll(ParticleCam, True)
	for p: Particle in EachParticle:
		if p.age > p.max_time:
			Delete(p)
		else:
			if !p.emitter.frozen:
				p.age = p.age + 1
				if p.emitter.tmp.align_to_fall:
					p.rot = (p.emitter.tmp.align_to_fall_offset - ATan2(p.xv, p.yv))
				else:
					p.rot = (p.rot + p.rot_vel)

				p.yv = p.yv - p.emitter.tmp.gravity
				p.x = p.x + p.xv
				p.y = p.y + p.yv
				p.z = p.z + p.zv
				if p.y < p.emitter.tmp.floor_y:
					p.yv = p.yv * -p.emitter.tmp.floor_bounce
				p.sx = (p.sx + p.emitter.tmp.size_add) * p.emitter.tmp.size_mult
				p.sy = (p.sy + p.emitter.tmp.size_add) * p.emitter.tmp.size_mult

			RotateEntity(ParticlePiv, cam_pitch, cam_yaw, cam_roll + (p.rot + p.emitter.tmp.align_to_fall_offset))
			if p.emitter.tmp.pitch_fix > -1:
				RotateEntity(ParticlePiv, p.emitter.tmp.pitch_fix, EntityYaw(ParticlePiv), EntityRoll(ParticlePiv))
			if p.emitter.tmp.yaw_fix > -1:
				RotateEntity(ParticlePiv, EntityPitch(ParticlePiv), p.emitter.tmp.yaw_fix, EntityRoll(ParticlePiv))
			x = EntityX(p.emitter.ent) + p.x
			y = EntityY(p.emitter.ent) + p.y
			z = EntityZ(p.emitter.ent) + p.z
			sx = p.sx
			sy = p.sy
			TFormVector(sx, -sy, 0, ParticlePiv, 0)
			v1x = TFormedX() + x
			v1y = TFormedY() + y
			v1z = TFormedZ() + z
			TFormVector(-sx, -sy, 0, ParticlePiv, 0)
			v2x = TFormedX() + x
			v2y = TFormedY() + y
			v2z = TFormedZ() + z
			TFormVector(sx, sy, 0, ParticlePiv, 0)
			v3x = TFormedX() + x
			v3y = TFormedY() + y
			v3z = TFormedZ() + z
			TFormVector(-sx, sy, 0, ParticlePiv, 0)
			v4x = TFormedX() + x
			v4y = TFormedY() + y
			v4z = TFormedZ() + z
			v1 = AddVertex(p.emitter.surf, v1x, v1y, v1z, 0, 0)
			v2 = AddVertex(p.emitter.surf, v2x, v2y, v2z, 1, 0)
			v3 = AddVertex(p.emitter.surf, v3x, v3y, v3z, 0, 1)
			v4 = AddVertex(p.emitter.surf, v4x, v4y, v4z, 1, 1)
			r = p.emitter.tmp.r1 + (p.emitter.tmp.r2 - p.emitter.tmp.r1) * Float(p.age) / Float(p.max_time)
			g = p.emitter.tmp.g1 + (p.emitter.tmp.g2 - p.emitter.tmp.g1) * Float(p.age) / Float(p.max_time)
			b = p.emitter.tmp.b1 + (p.emitter.tmp.b2 - p.emitter.tmp.b1) * Float(p.age) / Float(p.max_time)
			if p.emitter.tmp.alpha_vel:
				a = (1 - Float(p.age) / Float(p.max_time)) * p.emitter.tmp.alpha
			else:
				a = p.emitter.tmp.alpha
			VertexColor(p.emitter.surf, v1, r, g, b, a)
			VertexColor(p.emitter.surf, v2, r, g, b, a)
			VertexColor(p.emitter.surf, v3, r, g, b, a)
			VertexColor(p.emitter.surf, v4, r, g, b, a)
			for i: int in range(1, p.emitter.tmp.Brightness + 1):
				AddTriangle(p.emitter.surf, v1, v2, v3)
				AddTriangle(p.emitter.surf, v3, v2, v4)
