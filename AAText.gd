
class AAFont:
	var texture: int
	var backup: int #images don't get erased by clearworld

	var x: PackedInt32Array #[128] #not going to bother with unicode
	var y: PackedInt32Array #[128]
	var w: PackedInt32Array #[128]
	var h: PackedInt32Array #[128]

	var lowResFont: int #for use on other buffers

	var mW: int
	var mH: int
	var texH: int

	var isAA: int

func InitAAFont() -> void:
	if AATextEnable:
		#Create Camera
		var cam: int = CreateCamera()
		CameraViewport(cam,0,0,10,10)

		CameraZoom(cam, 0.1)
		CameraClsMode(cam, 0, 0)
		CameraRange(cam, 0.1, 1.5)
		MoveEntity(cam, 0, 0, -20000)
		AATextCam = cam
		CameraProjMode(cam,0)

		#Create sprite
		var spr: int = CreateMesh(cam)
		var sf: int = CreateSurface(spr)
		AddVertex(sf, -1, 1, 0, 0, 0) #vertex 0# uv:0,0
		AddVertex(sf, 1, 1, 0, 1, 0)  #vertex 1# uv:1,0
		AddVertex(sf, -1, -1, 0, 0, 1)#vertex 2# uv:0,1
		AddVertex(sf, 1, -1, 0, 1, 1) #vertex 3# uv:1,1
		AddTriangle(sf, 0, 1, 2)
		AddTriangle(sf, 3, 2, 1)
		EntityFX(spr, 17+32)
		PositionEntity(spr, 0, 0, 1.0001)
		EntityOrder(spr, -100001)
		EntityBlend(spr, 1)
		AATextSprite[0] = spr
		HideEntity(AATextSprite[0])
		for i: int in range(1, 150):
			spr = CopyMesh(AATextSprite[0],cam)
			EntityFX(spr, 17+32)
			PositionEntity(spr, 0, 0, 1.0001)
			EntityOrder(spr, -100001)
			EntityBlend(spr, 1)
			AATextSprite[i] = spr
			HideEntity(AATextSprite[i])

func AASpritePosition(ind: int,x: int,y: int) -> void:
	#THE HORROR
	var nx: float = (((Float(x-(AACamViewW/2))/Float(AACamViewW))*2))
	var ny: float = -(((Float(y-(AACamViewH/2))/Float(AACamViewW))*2))

	#how does this work pls help
	nx = nx-((1.0/Float(AACamViewW))*(((AACharW-2) % 2)))+(1.0/Float(AACamViewW))
	ny = ny-((1.0/Float(AACamViewW))*(((AACharH-2) % 2)))+(1.0/Float(AACamViewW))

	PositionEntity(AATextSprite[ind],nx,ny,1.0)

func AASpriteScale(ind: int,w: int,h: int) -> void:
	ScaleEntity(AATextSprite[ind],1.0/Float(AACamViewW)*Float(w), 1/Float(AACamViewW)*Float(h), 1)
	AACharW = w
	AACharH = h

func ReloadAAFont() -> void: #CALL ONLY AFTER CLEARWORLD
	if AATextEnable:
		InitAAFont()
		for font: AAFont in EachAAFont:
			if font.isAA:
				font.texture = CreateTexture(1024,1024,3)
				LockBuffer(ImageBuffer(font.backup))
				LockBuffer(TextureBuffer(font.texture))
				for ix: int in range(1024):
					for iy: int in range(font.texH + 1):
						px = ReadPixelFast(ix,iy,ImageBuffer(font.backup)) << 24
						WritePixelFast(ix,iy,0xFFFFFF+px,TextureBuffer(font.texture))

				UnlockBuffer(TextureBuffer(font.texture))
				UnlockBuffer(ImageBuffer(font.backup))

func AASetFont(fnt: int) -> void:
	AASelectedFont = fnt
	var font: AAFont = Object.AAFont(AASelectedFont)
	if AATextEnable and font.isAA:
		for i: int in range(150):
			EntityTexture(AATextSprite[i],font.texture)

func AAStringWidth(txt: String) -> int:
	var font: AAFont = Object.AAFont(AASelectedFont)
	if AATextEnable and font.isAA:
		var retVal: int = 0
		for i: int in range(1, Len(txt) + 1):
			var char: int = Asc(Mid(txt,i,1))
			if char>=0 and char<=127:
				retVal=retVal+font.w[char]-2

		return retVal+2
	else:
		SetFont(font.lowResFont)
		return StringWidth(txt)

func AAStringHeight(txt: String) -> int:
	var font: AAFont = Object.AAFont(AASelectedFont)
	if (AATextEnable) and (font.isAA):
		return font.mH
	else:
		SetFont(font.lowResFont)
		return StringHeight(txt)

func AAText(x: int, y: int, txt: String, cx: bool = false,cy: bool = false, a: float=1.0) -> void:
	if Len(txt) == 0:
		return

	var font: AAFont = Object.AAFont(AASelectedFont)

	if (GraphicsBuffer() != BackBuffer()) or !AATextEnable or !font.isAA:
		SetFont(font.lowResFont)
		var oldr: int = ColorRed()
		var oldg: int = ColorGreen()
		var oldb: int = ColorBlue()
		Color(oldr*a,oldg*a,oldb*a)
		Text(x,y,txt,cx,cy)
		Color(oldr,oldg,oldb)
		return

	if cx:
		x=x-(AAStringWidth(txt)/2)

	if cy:
		y=y-(AAStringHeight(txt)/2)

	if Camera != 0:
		HideEntity(Camera)
	if ark_blur_cam != 0:
		HideEntity(ark_blur_cam)

	var tX: int = 0
	CameraProjMode(AATextCam,2)

	var char: int

	var tw: int = 0
	for i: int in range(1, Len(txt) + 1):
		char = Asc(Mid(txt,i,1))
		if char>=0 and char<=127:
			tw=tw+font.w[char]

	AACamViewW = tw
	AACamViewW = AACamViewW+(AACamViewW % 2)
	AACamViewH = AAStringHeight(txt)
	AACamViewH = AACamViewH+(AACamViewH % 2)

	var vx: int = x
	if vx<0:
		vx=0
	var vy: int = y
	if vy<0:
		vy=0
	var vw: int = AACamViewW+(x-vx)
	if vw+vx>GraphicWidth:
		vw=GraphicWidth-vx
	var vh: int = AACamViewH+(y-vy)
	if vh+vy>GraphicHeight:
		vh=GraphicHeight-vy
	vw = vw-(vw % 2)
	vh = vh-(vh % 2)
	AACamViewH = AACamViewH+(AACamViewH % 2)
	AACamViewW = vw
	AACamViewH = vh

	CameraViewport(AATextCam,vx,vy,vw,vh)
	for i: int in range(1, Len(txt) + 1):
		EntityAlpha(AATextSprite[i-1],a)
		EntityColor(AATextSprite[i-1],ColorRed(),ColorGreen(),ColorBlue())
		ShowEntity(AATextSprite[i-1])
		char = Asc(Mid(txt,i,1))
		if char>=0 and char<=127:
			AASpriteScale(i-1,font.w[char],font.h[char])
			AASpritePosition(i-1,tX+(x-vx)+(font.w[char]/2),(y-vy)+(font.h[char]/2))
			VertexTexCoords(GetSurface(AATextSprite[i-1],1),0,Float(font.x[char])/1024.0,Float(font.y[char])/1024.0)
			VertexTexCoords(GetSurface(AATextSprite[i-1],1),1,Float(font.x[char]+font.w[char])/1024.0,Float(font.y[char])/1024.0)
			VertexTexCoords(GetSurface(AATextSprite[i-1],1),2,Float(font.x[char])/1024.0,Float(font.y[char]+font.h[char])/1024.0)
			VertexTexCoords(GetSurface(AATextSprite[i-1],1),3,Float(font.x[char]+font.w[char])/1024.0,Float(font.y[char]+font.h[char])/1024.0)
			tX = tX+font.w[char]-2

	RenderWorld()
	CameraProjMode(AATextCam,0)

	for i: int in range(1, Len(txt) + 1):
		HideEntity(AATextSprite[i-1])

	if Camera != 0:
		ShowEntity(Camera)
	if ark_blur_cam != 0:
		ShowEntity(ark_blur_cam)

func AALoadFont(file: String="Tahoma", height=13, bold=0, italic=0, underline=0, AATextScaleFactor: int=2) -> int:
	var newFont: AAFont = AAFont.new()

	newFont.lowResFont = LoadFont(file,height,bold,italic,underline)

	SetFont(newFont.lowResFont)
	newFont.mW = FontWidth()
	newFont.mH = FontHeight()

	if AATextEnable and AATextScaleFactor>1:
		var hResFont: int = LoadFont(file,height*AATextScaleFactor,bold,italic,underline)
		var tImage: int = CreateTexture(1024,1024,3)
		var tX: int = 0
		var tY: int = 1

		SetFont(hResFont)
		var tCharImage: int = CreateImage(FontWidth()+2*AATextScaleFactor,FontHeight()+2*AATextScaleFactor)
		ClsColor(0,0,0)
		LockBuffer(TextureBuffer(tImage))

		var miy: int = newFont.mH*((newFont.mW*95/1024)+2)
		DebugLog(miy)

		newFont.mW = 0

		for ix: int in range(1024):
			for iy: int in range(miy + 1):
				WritePixelFast(ix,iy,0xFFFFFF,TextureBuffer(tImage))

		for i: int in range(32, 127):
			SetBuffer(ImageBuffer(tCharImage))
			Cls()

			Color(255,255,255)
			SetFont(hResFont)
			Text(AATextScaleFactor/2,AATextScaleFactor/2,Chr(i))
			var tw: int = StringWidth(Chr(i))
			var th: int = FontHeight()
			SetFont(newFont.lowResFont)
			var dsw: int = StringWidth(Chr(i))
			var dsh: int = FontHeight()

			var wRatio: float = Float(tw)/Float(dsw)
			var hRatio: float = Float(th)/Float(dsh)

			SetBuffer(BackBuffer())

			LockBuffer(ImageBuffer(tCharImage))

			for iy: int in range(dsh):
				for ix: int in range(dsw):
					var rsx: int = Int(Float(ix)*wRatio-(wRatio*0.0))
					if (rsx<0):
						rsx=0
					var rsy: int = Int(Float(iy)*hRatio-(hRatio*0.0))
					if (rsy<0):
						rsy=0
					var rdx: int = Int(Float(ix)*wRatio+(wRatio*1.0))
					if (rdx>tw):
						rdx=tw-1
					var rdy: int = Int(Float(iy)*hRatio+(hRatio*1.0))
					if (rdy>th):
						rdy=th-1
					var ar: int = 0
					if Abs(rsx-rdx)*Abs(rsy-rdy)>0:
						for iiy: int in range(rsy, rdy):
							for iix: int in range(rsx, rdx):
								ar=ar+((ReadPixelFast(iix,iiy,ImageBuffer(tCharImage)) and 0xFF))

						ar = ar/(Abs(rsx-rdx)*Abs(rsy-rdy))
						if ar>255:
							ar=255
						ar = ((Float(ar)/255.0)^(0.5))*255

					WritePixelFast(ix+tX,iy+tY,0xFFFFFF+(ar << 24),TextureBuffer(tImage))

			UnlockBuffer(ImageBuffer(tCharImage))

			newFont.x[i]=tX
			newFont.y[i]=tY
			newFont.w[i]=dsw+2

			if newFont.mW<newFont.w[i]-3:
				newFont.mW=newFont.w[i]-3

			newFont.h[i]=dsh+2
			tX=tX+newFont.w[i]+2
			if (tX>1024-FontWidth()-4):
				tX=0
				tY=tY+FontHeight()+6

		newFont.texH = miy

		var backup: int = CreateImage(1024,1024)
		LockBuffer(ImageBuffer(backup))
		for ix: int in range(1024):
			for iy: int in range(newFont.texH + 1):
				px = ReadPixelFast(ix,iy,TextureBuffer(tImage)) >> 24
				px=px+(px << 8)+(px << 16)
				WritePixelFast(ix,iy,0xFF000000+px,ImageBuffer(backup))

		UnlockBuffer(ImageBuffer(backup))
		newFont.backup = backup

		UnlockBuffer(TextureBuffer(tImage))

		FreeImage(tCharImage)
		FreeFont(hResFont)
		newFont.texture = tImage
		newFont.isAA = True
	else:
		newFont.isAA = False

	return Handle(newFont)
