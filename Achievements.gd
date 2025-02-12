extends Node

const MAXACHIEVEMENTS: int = 37

const Achv008: int = 0
const Achv012: int = 1
const Achv035: int = 2
const Achv049: int = 3
const Achv055: int = 4
const Achv079: int = 5
const Achv096: int = 6
const Achv106: int = 7
const Achv148: int = 8
const Achv205: int = 9
const Achv294: int = 10
const Achv372: int = 11
const Achv420: int = 12
const Achv427: int = 13
const Achv500: int = 14
const Achv513: int = 15
const Achv714: int = 16
const Achv789: int = 17
const Achv860: int = 18
const Achv895: int = 19
const Achv914: int = 20
const Achv939: int = 21
const Achv966: int = 22
const Achv970: int = 23
const Achv1025: int = 24
const Achv1048: int = 25
const Achv1123: int = 26

const AchvMaynard: int = 27
const AchvHarp: int = 28
const AchvSNAV: int = 29
const AchvOmni: int = 30
const AchvConsole: int = 31
const AchvTesla: int = 32
const AchvPD: int = 33

const Achv1162: int = 34
const Achv1499: int = 35

const AchvKeter: int = 36

func _ready() -> void:
	for i: int in range(MAXACHIEVEMENTS):
		var loc2: int = GetINISectionLocation("Data/achievementstrings.ini", "s"+Str(i))
		AchievementStrings[i] = GetINIString2("Data/achievementstrings.ini", loc2, "string1")
		AchievementDescs[i] = GetINIString2("Data/achievementstrings.ini", loc2, "AchvDesc")

		var image: String = GetINIString2("Data/achievementstrings.ini", loc2, "image")

		AchvIMG[i] = LoadImage_Strict("GFX/menu/achievements/"+image+".jpg")
		AchvIMG[i] = ResizeImage2(AchvIMG[i],ImageWidth(AchvIMG[i])*GraphicHeight/768.0,ImageHeight(AchvIMG[i])*GraphicHeight/768.0)

	AchvLocked = ResizeImage2(AchvLocked,ImageWidth(AchvLocked)*GraphicHeight/768.0,ImageHeight(AchvLocked)*GraphicHeight/768.0)

func GiveAchievement(achvname: int, showMessage: int=True) -> void:
	if !Achievements[achvname]:
		Achievements[achvname]=True
		if AchvMSGenabled and showMessage:
			var loc2: int = GetINISectionLocation("Data/achievementstrings.ini", "s"+achvname)
			var AchievementName: String = GetINIString2("Data/achievementstrings.ini", loc2, "string1")
			CreateAchievementMsg(achvname,AchievementName)

func AchievementTooltip(achvno: int) -> void:
	var scale: float = GraphicHeight/768.0

	AASetFont(Font3)
	var width = AAStringWidth(AchievementStrings(achvno))
	AASetFont(Font1)
	if (AAStringWidth(AchievementDescs(achvno))>width):
		width = AAStringWidth(AchievementDescs(achvno))

	width = width+20*MenuScale

	var height = 38*scale

	Color(25,25,25)
	Rect(ScaledMouseX()+(20*MenuScale),ScaledMouseY()+(20*MenuScale),width,height,True)
	Color(150,150,150)
	Rect(ScaledMouseX()+(20*MenuScale),ScaledMouseY()+(20*MenuScale),width,height,False)
	AASetFont(Font3)
	AAText(ScaledMouseX()+(20*MenuScale)+(width/2),ScaledMouseY()+(35*MenuScale), AchievementStrings(achvno), True, True)
	AASetFont(Font1)
	AAText(ScaledMouseX()+(20*MenuScale)+(width/2),ScaledMouseY()+(55*MenuScale), AchievementDescs(achvno), True, True)

func DrawAchvIMG(x: int, y: int, achvno: int) -> void:
	var row: int
	var scale: float = GraphicHeight/768.0
	var SeparationConst2 = 76 * scale

	row = achvno % 4
	Color(0,0,0)
	Rect((x+((row)*SeparationConst2)), y, 64*scale, 64*scale, True)
	if Achievements(achvno):
		DrawImage(AchvIMG(achvno),(x+(row*SeparationConst2)),y)
	else:
		DrawImage(AchvLocked,(x+(row*SeparationConst2)),y)

	Color(50,50,50)

	Rect((x+(row*SeparationConst2)), y, 64*scale, 64*scale, False)



class AchievementMsg:
	var achvID: int
	var txt: String
	var msgx: float
	var msgtime: float
	var msgID: int

func CreateAchievementMsg(id: int,txt: String) -> AchievementMsg:
	var amsg: AchievementMsg = AchievementMsg.new()

	amsg.achvID = id
	amsg.txt = txt
	amsg.msgx = 0.0
	amsg.msgtime = FPSfactor2
	amsg.msgID = CurrAchvMSGID
	CurrAchvMSGID += 1

	return amsg

func UpdateAchievementMsg() -> void:
	var scale: float = GraphicHeight/768.0
	var width: int = 264*scale
	var height: int = 84*scale
	var x: int
	var y: int

	for amsg: AchievementMsg in EachAchievementMsg:
		if amsg.msgtime != 0:
			x=GraphicWidth+amsg.msgx
			y=(GraphicHeight-height)
			for amsg2: AchievementMsg in EachAchievementMsg:
				if amsg2 != amsg:
					if amsg2.msgID > amsg.msgID:
						y=y-height

			DrawFrame(x,y,width,height)
			Color(0,0,0)
			Rect(x+10*scale,y+10*scale,64*scale,64*scale,True)
			DrawImage(AchvIMG(amsg.achvID),x+10*scale,y+10*scale)
			Color(50,50,50)
			Rect(x+10*scale,y+10*scale,64*scale,64*scale,False)
			Color(255,255,255)
			AASetFont(Font1)
			RowText("Achievement Unlocked - "+amsg.txt,x+84*scale,y+10*scale,width-94*scale,y-20*scale)
			if amsg.msgtime > 0.0 and amsg.msgtime < 70*7:
				amsg.msgtime = amsg.msgtime + FPSfactor2
				if amsg.msgx > -width:
					amsg.msgx = Max(amsg.msgx-4*FPSfactor2,-width)

			elif amsg.msgtime >= 70*7:
				amsg.msgtime = -1
			elif amsg.msgtime == -1:
				if amsg.msgx < 0.0:
					amsg.msgx = Min(amsg.msgx+4*FPSfactor2,0.0)
				else:
					amsg.msgtime = 0.0

		else:
			Delete(amsg)
