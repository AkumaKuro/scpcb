extends Node


func _ready() -> void:
	Loadingwindow=CreateWindow("", GraphicsWidth()/2-160,GraphicsHeight()/2-120,320,260,winhandle,8)
	panelloading = CreatePanel(0,0,320,260,Loadingwindow,0)
	SetPanelImage(panelloading,"Assets/map_logo.jpg")

	# create a window to put the toolbar in
	WinHandle=CreateWindow("SCP-CB Map Creator "+versionnumber,GraphicsWidth()/2-ResWidth/2, GraphicsHeight()/2-ResHeight/2,ResWidth,ResHeight,0, 13)
	HideGadget(WinHandle)

	LoadRoomTemplates(FileLocation)

	# ein paar Eintrage hinzufugen
	for rt: RoomTemplates in EachRoomTemplates:
		if rt.MapGrid == 0:
			AddGadgetItem(listbox, rt.Name)

	SetGadgetLayout(listbox, 3,3,2,2)

	InitEvents("../Data/events.ini")
	AddEvents()

	SetGadgetLayout(room_desc , 3,3,2,2)

	SetGadgetLayout(grid_room_info , 3,3,2,2)

	SetGadgetLayout(event_desc , 3,3,2,2)

	SetGadgetLayout(event_prob , 3,3,2,2)
	SetSliderRange(event_prob,0,100)
	DisableGadget(event_prob)

	SetGadgetLayout(event_prob_label , 3,3,2,2)

	menu=WindowMenu(WinHandle)


	SetGadgetLayout(combobox, 3,3,2,2)
	DisableGadget(combobox)

	txtbox=CreateTextField(5,40,150,20,winhandle) #create #textfield in that window
	SetGadgetText(txtbox,"") #set #text in that #textfield for info
	ok=CreateButton("Search",155,40,50,20,winhandle) #create button
	clean_txt=CreateButton("X",210,40,20,20,winhandle) #create button

	map_2d = CreateCanvas(300,25,551,551,WinHandle)

	MapIcons[ROOM1][0] = load("Assets/room1.png")
	MapIcons[ROOM2][0] = load("Assets/room2.png")
	MapIcons[ROOM2C][0] = load("Assets/room2C.png")
	MapIcons[ROOM3][0] = load("Assets/room3.png")
	MapIcons[ROOM4][0] = load("Assets/room4.png")
	for i: int in range(ROOM1, ROOM4 + 1):
		MaskImage(MapIcons(i,0), 255,255,255)
		MidHandle(MapIcons(i,0))
		for n: int in range(1, 4):
			MapIcons[i][n]=CopyImage(MapIcons(i,0))
			MaskImage(MapIcons[i][n], 255,255,255)
			RotateImage(MapIcons[i][n],90*n)
			MidHandle(MapIcons[i][n])


	ForestIcons[ROOM1][0] = load("Assets/forest1.png")
	ForestIcons[ROOM2][0] = load("Assets/forest2.png")
	ForestIcons[ROOM2C][0] = load("Assets/forest2C.png")
	ForestIcons[ROOM3][0] = load("Assets/forest3.png")
	ForestIcons[ROOM4][0] = load("Assets/forest4.png")

	for i: int in range(ROOM1, ROOM4 + 1):
		MaskImage(ForestIcons(i,0), 255,255,255)
		MidHandle(ForestIcons(i,0))
		for n: int in range(1, 4):
			ForestIcons[i][n]=CopyImage(ForestIcons(i,0))
			MaskImage(ForestIcons[i][n], 255,255,255)
			RotateImage(ForestIcons[i][n],90*n)
			MidHandle(ForestIcons[i][n])


	SpecialIcons[1][0] = LoadImage("Assets/forest_exit.png")
	SpecialIcons[2][0] = LoadImage("Assets/room2elev.png")
	for i: int in range(1, 3):
		MaskImage(SpecialIcons(i,0), 255,255,255)
		MidHandle(SpecialIcons(i,0))
		for n: int in range(1, 4):
			SpecialIcons[i][n]=CopyImage(SpecialIcons(i,0))
			MaskImage(SpecialIcons[i][n], 255,255,255)
			RotateImage(SpecialIcons[i][n],90*n)
			MidHandle(SpecialIcons[i][n])


	Arrows[0] = LoadImage("Assets/arrows.png")
	HandleImage(Arrows[0],ImageWidth(Arrows[0])/2,ImageHeight(Arrows[0])/2)
	for i: int in range(1, 4):
		Arrows[i]=CopyImage(Arrows[0])
		HandleImage(Arrows(i), ImageWidth(Arrows(i))/2,ImageHeight(Arrows(i))/2)
		RotateImage(Arrows(i), i*90)

	PlusIcon = LoadImage("Assets/plus.png")
	MaskImage(plusicon,255,255,255)
	MidHandle(plusicon)

	SetGadgetLayout(txtbox , 3,3,3,3)
	SetGadgetLayout(ok , 3,3,3,3)
	SetGadgetLayout(clean_txt , 3,3,3,3)
	tab=CreateTabber(0,5,ResWidth/4+20,ResHeight-60,winhandle)

	InsertGadgetItem(tab,0,"2D/Map Creator")
	InsertGadgetItem(tab,1,"3D/Map Viewer")
	SetGadgetLayout(tab , 3,3,2,2)

	tab2=CreateTabber(300,5,ResWidth/4+20,ResHeight-100,winhandle)
	InsertGadgetItem(tab2,0,"Facility")
	InsertGadgetItem(tab2,1,"Forest")
	InsertGadgetItem(tab2,2,"Maintenance Tunnels")
	SetGadgetLayout(tab2 , 3,3,2,2)

	SetStatusText(Loadingwindow, "Starting up")
	# Now create a whole bunch of menus and sub-items - first of all the FILE menu
	file=CreateMenu("File",0,menu) # main menu
	CreateMenu("New",0,file) # child menu
	CreateMenu("Open",1,file) # child menu
	CreateMenu("",1000,file) # Use an empty string to generate separator bars
	CreateMenu("Save",2,file) # child menu
	CreateMenu("Save as...",3,file) # child menu
	CreateMenu("",1000,file) # Use an empty string to generate separator bars
	CreateMenu("Quit",10001,file) # another child menu

	options=CreateMenu("Options",0,menu)
	event_default = CreateMenu("Set the event for the rooms by default",15,options)

	CreateMenu("",1000,options)
	zone_trans = CreateMenu("Map Settings",18,options)
	author_descr = CreateMenu("Edit Author and Description",19,options)
	CreateMenu("",1000,options)
	CreateMenu("Edit Camera",17,options)

	if !option_event:
		UncheckMenu(event_default)
	else:
		CheckMenu(event_default)

	if !option_adjdoors:
		UncheckMenu(adjdoor_place)
	else:
		CheckMenu(adjdoor_place)

	# Now the Edit menu
	edit=CreateMenu("&Help",0,menu) # Main menu with Alt Shortcut - Use & to specify the shortcut key
	CreateMenu("Manual"+Chr(8)+"F1",6,edit) # Another Child menu with Alt Shortcut
	CreateMenu("About"+Chr(8)+"F12",40,edit) # Child menu with Alt Shortcut

	HotKeyEvent(59,0,0x1001,6)

	HotKeyEvent(88,0,0x1001,40)

	# Finally, once all menus are set up / updated, we call UpdateWindowMenu to tell the OS about the menu
	UpdateWindowMenu(WinHandle)

	SetStatusText(Loadingwindow, "Creating 2D scene...")
	Optionwin=CreateWindow("Edit Camera", GraphicsWidth()/2-160,GraphicsHeight()/2-120,300,280,winhandle,1)
	HideGadget(optionwin)
	LabelColor = CreateLabel("",5,5,285,60, optionwin,1)
	LabelColor2 = CreateLabel("",5,70,285,60,optionwin,1)
	LabelRange = CreateLabel("",5,135,285,60, optionwin,1) #70
	color_button = CreateButton("Change CameraFog Color", 25,20,150,30,optionwin)
	color_button2 = CreateButton("Change Cursor Color", 25,85,150,30,optionwin)

	labelfogR=CreateLabel("R "+GetINIInt("options.INI","3d scene","bg color R"),225,15,40,15, optionwin)
	labelfogG=CreateLabel("G "+GetINIInt("options.INI","3d scene","bg color G"),225,30,40,15, optionwin)
	labelfogB=CreateLabel("B "+GetINIInt("options.INI","3d scene","bg color B"),225,45,40,15, optionwin)

	labelcursorR=CreateLabel("R "+GetINIInt("options.INI","3d scene","cursor color R"),225,75,40,15, optionwin)
	labelcursorG=CreateLabel("G "+GetINIInt("options.INI","3d scene","cursor color G"),225,90,40,15, optionwin)
	labelcursorB=CreateLabel("B "+GetINIInt("options.INI","3d scene","cursor color B"),225,105,40,15, optionwin)


	labelrange=CreateLabel("Culling Range",10,170,80,20, optionwin)
	SetGadgetText(camerarange, GetINIInt("options.INI","3d scene","camera range"))


	SetButtonState(vsync, GetINIInt("options.INI","3d scene","vsync"))


	SetButtonState(showfps, GetINIInt("options.INI","3d scene","show fps"))

	cancelopt_button=CreateButton("Cancel",10,210,100,30,optionwin)
	saveopt_button=CreateButton("Save",185,210,100,30,optionwin) #create button

	map_settings=CreateWindow("Map Settings", GraphicsWidth()/2-120,GraphicsHeight()/2-80,240,160,winhandle,1)
	HideGadget(map_settings)

	zonetext = CreateLabel("Zone transition settings:",10,10,200,20,map_settings)
	labelzonetrans1 = CreateLabel("LCZ to HCZ transition",10,60,120,20,map_settings)

	SetGadgetText(zonetrans1,5)
	labelzonetrans2 = CreateLabel("HCZ to EZ transition",120,60,120,20,map_settings)

	SetGadgetText(zonetrans2,11)

	resetzonetrans = CreateButton("Reset",10,90,100,30,map_settings)
	applyzonetrans = CreateButton("Apply",120,90,100,30,map_settings)

	authordescr_settings=CreateWindow("Edit Author and Description", GraphicsWidth()/2-200,GraphicsHeight()/2-80,400,200,winhandle,1)
	HideGadget(authordescr_settings)

	map_author_label = CreateLabel("Map author:",140,10,160,20,authordescr_settings)

	descr_label = CreateLabel("Description:",140,60,160,20,authordescr_settings)

	SetStatusText(Loadingwindow, "Executing 3D viewer...")
	ExecFile("window3d.exe")

	while !(vwprt != 0):
		vwprt = FindWindow("Blitz Runtime Class" , "MapCreator 3d view")
		ShowGadget(Loadingwindow)

	SetStatusText(Loadingwindow, "Creating 3D scene...")

	SetParent(vwprt,MainHwnd)
	api_SetWindowPos( vwprt , 0 , 5 , 30 , 895 , 560 , 1)
	ShowWindow(vwprt ,0)

	HideGadget(Loadingwindow)
	ShowGadget(WinHandle)

	SetBuffer(CanvasBuffer(map_2d))

	while true:
		MouseHit1 = MouseHit(1)
		MouseHit2 = MouseHit(2)
		MouseDown1 = MouseDown(1)
		MouseDown2 = MouseDown(2)
		MouseHit3 = MouseHit(3)

		SetGadgetText(map_author_text,(Left(TextFieldText(map_author_text),15)))
		SetGadgetText(map_author_label,("Map author ("+(Len(TextFieldText(map_author_text)))+"/15) :"))

		if Len(TextAreaText(descr_text))>200:
			SetGadgetText(descr_text,(Left(TextAreaText(descr_text),200)))

		SetGadgetText(descr_label,("Description ("+(Len(TextAreaText(descr_text)))+"/200) :"))

		if FileType("CONFIG_TO2D.SI") == 1:
			f = ReadFile("CONFIG_TO2D.SI")

			Grid_SelectedX=ReadInt(f)
			Grid_SelectedY=ReadInt(f)

			ChangeGridGadget = True
			GridGadgetText = ""
			SelectGadgetItem(listbox,-1)
			HideGadget(listbox)
			ShowGadget(listbox)
			ClearGadgetItems(combobox)

			if CurrMapGrid == 0:
				var hasEvent: bool = False
				var currEventDescr: String = ""
				for rt: RoomTemplates in EachRoomTemplates:
					if rt == Map(Grid_SelectedX,Grid_SelectedY):
						for i: int in range(6):
							if rt.Events[i] != "":
								InsertGadgetItem(combobox, 0, "[none]")
								hasEvent=True
								break

						for i: int in range(6):
							if rt.events[i]!="":
								InsertGadgetItem(combobox, i+1, rt.events[i])

						SetGadgetText(room_desc,"Room description:"+Chr(13)+rt.Description)
						break

				if !hasEvent:
					DisableGadget(combobox)
					SetGadgetText(event_desc, "")
					SetGadgetText(event_prob_label, "")
					SetSliderValue(event_prob,99)
					DisableGadget(event_prob)
					GridGadgetText="Name: "+Map(Grid_SelectedX,Grid_SelectedY).Name+Chr(13)+"Angle: "+MapAngle(Grid_SelectedX,Grid_SelectedY)+"�"
				else:
					EnableGadget(combobox)
					if MapEvent(Grid_SelectedX,Grid_SelectedY) not in ["", "[none]"]:
						for ev: event in Eachevent:
							if ev.name == MapEvent(Grid_SelectedX,Grid_SelectedY):
								SetGadgetText(event_desc, "Event description:"+Chr(13)+ev.description)
								break

					else:
						SetGadgetText(event_desc, "")

					if MapEvent(Grid_SelectedX,Grid_SelectedY) != "" and MapEvent(Grid_SelectedX,Grid_SelectedY) != "[none]":
						SetGadgetText(event_prob_label, "Event chance: "+Int(MapEventProb(Grid_SelectedX,Grid_SelectedY)*100)+"%")
						SetSliderValue(event_prob,Int(MapEventProb(Grid_SelectedX,Grid_SelectedY)*100)-1)
						EnableGadget(event_prob)
						GridGadgetText="Name: "+Map(Grid_SelectedX,Grid_SelectedY).Name+Chr(13)+"Angle: "+MapAngle(Grid_SelectedX,Grid_SelectedY)+"�"+Chr(13)+"Event: "+MapEvent(Grid_SelectedX,Grid_SelectedY)+Chr(13)+"Event Chance: "+Int(MapEventProb(Grid_SelectedX,Grid_SelectedY)*100)+"%"
					else:
						SetGadgetText(event_prob_label, "")
						SetSliderValue(event_prob,99)
						DisableGadget(event_prob)
						GridGadgetText="Name: "+Map(Grid_SelectedX,Grid_SelectedY).Name+Chr(13)+"Angle: "+MapAngle(Grid_SelectedX,Grid_SelectedY)+"�"

				c = CountGadgetItems( combobox )
				if c >= 0:
					for e: int in range(c):
						if GadgetItemText(combobox,e) == MapEvent(Grid_SelectedX,Grid_SelectedY):
							SelectGadgetItem(combobox,e)

			elif CurrMapGrid == 1:
				for rt: RoomTemplates in EachRoomTemplates:
					if rt == ForestPlace(Grid_SelectedX,Grid_SelectedY):
						SetGadgetText(room_desc,"Room description:"+Chr(13)+rt.Description)
						break

				DisableGadget(combobox)
				SetGadgetText(event_desc, "")
				SetGadgetText(event_prob_label, "")
				SetSliderValue(event_prob,99)
				DisableGadget(event_prob)
				GridGadgetText="Name: "+ForestPlace(Grid_SelectedX,Grid_SelectedY).Name+Chr(13)+"Angle: "+ForestPlaceAngle(Grid_SelectedX,Grid_SelectedY)+"�"
			else:
				for rt: RoomTemplates in EachRoomTemplates:
					if rt == MTRoom(Grid_SelectedX,Grid_SelectedY):
						SetGadgetText(room_desc,"Room description:"+Chr(13)+rt.Description)
						break

				DisableGadget(combobox)
				SetGadgetText(event_desc, "")
				SetGadgetText(event_prob_label, "")
				SetSliderValue(event_prob,99)
				DisableGadget(event_prob)
				GridGadgetText="Name: "+MTRoom(Grid_SelectedX,Grid_SelectedY).Name+Chr(13)+"Angle: "+MTRoomAngle(Grid_SelectedX,Grid_SelectedY)+"�"

			CloseFile(f)
			DeleteFile("CONFIG_TO2D.SI")

		if ShowGrid:
			Cls()
			var width: float = GadgetWidth(map_2d)
			var height: float = GadgetHeight(map_2d)
			#Facility grid
			if CurrMapGrid == 0:
				for x: int in range(MapWidth + 1):
					for y: int in range(MapHeight + 1):

						if y < zonetransvalue2:
							Color(255,255,125)
						elif y == zonetransvalue2:
							Color(255,200,125)
						elif y > zonetransvalue2 and y < zonetransvalue1:
							Color(255,125,125)
						elif y == zonetransvalue1:
							Color(255,200,200)
						else:
							Color(255,255,255)

						Rect(Float(width)/Float(MapWidth+1)*x,Float(height)/Float(MapHeight+1)*y,(Float(width)/Float(MapWidth+1)),(Float(height)/Float(MapHeight+1)),True)

						var PrevSelectedX = Grid_SelectedX
						var PrevSelectedY=Grid_SelectedY

						if (MouseX()-GadgetX(map_2d))>(Float(width)/Float(MapWidth+1)*x+GadgetX(WinHandle)) and (MouseX()-GadgetX(map_2d))<((Float(width)/Float(MapWidth+1)*x)+(Float(width)/Float(MapWidth+1))+GadgetX(WinHandle)):
							var offset: int = 45
							if (MouseY()-GadgetY(map_2d))>(Float(height)/Float(MapHeight+1)*y+GadgetY(WinHandle)+offset) and (MouseY()-GadgetY(map_2d))<((Float(height)/Float(MapHeight+1)*y)+(Float(height)/Float(MapHeight+1))+GadgetY(WinHandle)+offset):
								Color(200,200,200)
								Rect(Float(width)/Float(MapWidth+1)*x,Float(height)/Float(MapHeight+1)*y,(Float(width)/Float(MapWidth+1)),(Float(height)/Float(MapHeight+1)),True)
								if !Map(x,y) and SelectedGadgetItem(listbox) > -1:
									x2 = Float(width)/Float(MapWidth+1)
									y2 = Float(height)/Float(MapHeight+1)
									DrawImage(PlusIcon,(x2*x)+(x2/2.0)+0.5,(y2*y)+(y2/2.0)+0.5)

								if MouseHit1:
									if !(Grid_SelectedX == x and Grid_SelectedY == y):

										item = SelectedGadgetItem( listbox )
										if Map(x,y):
											Grid_SelectedX=x
											Grid_SelectedY=y
											ChangeGridGadget = True
											GridGadgetText = ""
											SelectGadgetItem(listbox,-1)
											HideGadget(listbox)
											ShowGadget(listbox)

											ClearGadgetItems(combobox)

											hasEvent = False
											currEventDescr = ""
											for rt: RoomTemplates in EachRoomTemplates:
												if rt == Map(x,y):
													for i: int in range(6):
														if rt.Events[i]!="":
															InsertGadgetItem(combobox, 0, "[none]")
															hasEvent=True
															break

													for i: int in range(6):
														if rt.events[i]!="":
															InsertGadgetItem(combobox, i+1, rt.events[i])

													SetGadgetText(room_desc,"Room description:"+Chr(13)+rt.Description)
													break

											if !hasEvent:
												DisableGadget(combobox)
												SetGadgetText(event_desc, "")
												SetGadgetText(event_prob_label, "")
												SetSliderValue(event_prob,99)
												DisableGadget(event_prob)
											else:
												EnableGadget(combobox)
												if MapEvent(x,y) not in ["", "[none]"]:
													for ev: event in Eachevent:
														if ev.name == MapEvent(x,y):
															SetGadgetText(event_desc, "Event description:"+Chr(13)+ev.description)
															break

												else:
													SetGadgetText(event_desc, "")

												if MapEvent(x,y) not in ["", "[none]"]:
													SetGadgetText(event_prob_label, "Event chance: 100%")
													SetSliderValue(event_prob,99)
													EnableGadget(event_prob)
												else:
													SetGadgetText(event_prob_label, "")
													SetSliderValue(event_prob,99)
													DisableGadget(event_prob)

											c = CountGadgetItems( combobox )
											if c >= 0:
												for e: int in range(c):
													if GadgetItemText(combobox,e) == MapEvent(x,y):
														SelectGadgetItem(combobox,e)

										if item>=0:
											if !Map[x][y]:
												var room_name: String = GadgetItemText(listbox, item)
												for rt: RoomTemplates in EachRoomTemplates:
													if rt.Name == room_name:
														Map[x][y]=rt
														break

												if Map[x][y].Name in ["start", "checkpoint1", "checkpoint2"]:
													MapAngle[x][y]=180

												item2 = SelectedGadgetItem(combobox)
												if item2 >= 0:
													var event_name: String = GadgetItemText(combobox, item2)
													if event_name not in ["", "[none]"]:
														MapEvent[x][y]=event_name
														MapEventProb[x][y]=Float((SliderValue(event_prob)+1)/100.0)

								if MouseDown2:
									Grid_SelectedX=-1
									Grid_SelectedY=-1
									ChangeGridGadget = True
									GridGadgetText = ""
									SetSliderValue(event_prob,99)

									SetGadgetText(event_prob_label,"")
									DisableGadget(event_prob)
									SetGadgetText(event_desc,"")
									DisableGadget(combobox)
									ClearGadgetItems(combobox)
									if Map[x][y]:
										Map[x][y]=Null
										MapAngle[x][y]=0
										MapEvent[x][y]=""
										MapEventProb[x][y]=0.0

								if MouseHit3:
									Grid_SelectedX=-1
									Grid_SelectedY=-1
									ChangeGridGadget = True
									GridGadgetText = ""
									SetSliderValue(event_prob,99)
									SetGadgetText(event_prob_label,"")
									DisableGadget(event_prob)
									SetGadgetText(event_desc,"")
									DisableGadget(combobox)
									ClearGadgetItems(combobox)

						if Grid_SelectedX == x and Grid_SelectedY == y:
							Color(150,150,150)
							Rect(Float(width)/Float(MapWidth+1)*x,Float(height)/Float(MapHeight+1)*y,(Float(width)/Float(MapWidth+1)),(Float(height)/Float(MapHeight+1)),True)

						if !Map(x,y):
							Color(90,90,90)
							Rect(Float(width)/Float(MapWidth+1)*x+1,Float(height)/Float(MapHeight+1)*y+1,(Float(width)/Float(MapWidth+1))-1,(Float(height)/Float(MapHeight+1))-1,False)
						else:
							x2 = Float(width)/Float(MapWidth+1)
							y2 = Float(height)/Float(MapHeight+1)
							DrawImage(MapIcons(Map(x,y).Shape,Floor(MapAngle(x,y)/90.0)),(x2*x)+(x2/2.0)+0.5,(y2*y)+(y2/2.0)+0.5)

							if Grid_SelectedX == x and Grid_SelectedY == y:
								if Vector2i(PrevSelectedX, PrevSelectedY) != Vector2i(Grid_SelectedX, Grid_SelectedY):
									ChangeGridGadget = True
									if MapEvent(x,y) not in ["", "[none]"]:
										GridGadgetText = "Name: "+Map(x,y).Name+Chr(13)+"Angle: "+MapAngle(x,y)+"�"+Chr(13)+"Event: "+MapEvent(x,y)+Chr(13)+"Event Chance: "+Int(MapEventProb(x,y)*100)+"%"
										SetSliderValue(event_prob,Int(MapEventProb(x,y)*100)-1)
									else:
										GridGadgetText = "Name: "+Map(x,y).Name+Chr(13)+"Angle: "+MapAngle(x,y)+"�"

									if GadgetText(event_prob_label):
										SetGadgetText(event_prob_label,"Event chance: "+(SliderValue(event_prob)+1)+"%")

				if MouseDown1:
					if Grid_SelectedX > -1 and Grid_SelectedY > -1:
						if MouseX()>(GadgetX(map_2d)+GadgetX(WinHandle)) and MouseX()<((width)+GadgetX(map_2d)+GadgetX(WinHandle)):
							offset = 45
							if MouseY()>(GadgetY(map_2d)+GadgetY(WinHandle)+offset) and MouseY()<((height)+GadgetY(map_2d)+GadgetY(WinHandle)+offset):
								if Map(Grid_SelectedX,Grid_SelectedY).Name!="start":
									var prevAngle = MapAngle(Grid_SelectedX,Grid_SelectedY)
									#Left
									if (MouseX()-GadgetX(map_2d))<(Float(width)/Float(MapWidth+1)*Grid_SelectedX+GadgetX(WinHandle)):
										MapAngle[Grid_SelectedX][Grid_SelectedY] = 90

									#Right
									if (MouseX()-GadgetX(map_2d))>((Float(width)/Float(MapWidth+1)*Grid_SelectedX)+(Float(width)/Float(MapWidth+1))+GadgetX(WinHandle)):
										MapAngle[Grid_SelectedX][Grid_SelectedY] = 270

									#Up
									offset = 45
									if (MouseY()-GadgetY(map_2d))<(Float(height)/Float(MapHeight+1)*Grid_SelectedY+GadgetY(WinHandle)+offset):
										MapAngle[Grid_SelectedX][Grid_SelectedY] = 180

									#Down
									if (MouseY()-GadgetY(map_2d))>((Float(height)/Float(MapHeight+1)*Grid_SelectedY)+(Float(height)/Float(MapHeight+1))+GadgetY(WinHandle)+offset):
										MapAngle[Grid_SelectedX][Grid_SelectedY] = 0

									var width2 = Float(width)/Float(MapWidth+1)/2.0
									var height2 = Float(height)/Float(MapHeight+1)/2.0
									DrawImage(Arrows(Floor(MapAngle(Grid_SelectedX,Grid_SelectedY)/90)),Float(width)/Float(MapWidth+1)*Grid_SelectedX+width2,Float(height)/Float(MapHeight+1)*Grid_SelectedY+height2)
									if prevAngle!=MapAngle(Grid_SelectedX,Grid_SelectedY):
										ChangeGridGadget = True
										if MapEvent(Grid_SelectedX,Grid_SelectedY) in ["", "[none]"]:
											GridGadgetText="Name: "+Map(Grid_SelectedX,Grid_SelectedY).Name+Chr(13)+"Angle: "+MapAngle(Grid_SelectedX,Grid_SelectedY)+"�"+Chr(13)+"Event: "+MapEvent(Grid_SelectedX,Grid_SelectedY)+Chr(13)+"Event Chance: "+Int(MapEventProb(Grid_SelectedX,Grid_SelectedY)*100)+"%"
										else:
											GridGadgetText="Name: "+Map(Grid_SelectedX,Grid_SelectedY).Name+Chr(13)+"Angle: "+MapAngle(Grid_SelectedX,Grid_SelectedY)+"�"

			#Forest grid
			elif CurrMapGrid == 1:
				for x: int in range(ForestGridSize + 1):
					for y: int in range(ForestGridSize + 1):
						Color(125,255,255)
						if x == ForestGridSize or y == ForestGridSize:
							Rect(Float(width-1)/Float(ForestGridSize+1)*x,Float(height-1)/Float(ForestGridSize+1)*y,(Float(width-1)/Float(ForestGridSize+1))+1,(Float(height-1)/Float(ForestGridSize+1))+1,True)
						else:
							Rect(Float(width-1)/Float(ForestGridSize+1)*x,Float(height-1)/Float(ForestGridSize+1)*y,(Float(width-1)/Float(ForestGridSize+1)),(Float(height-1)/Float(ForestGridSize+1)),True)

						if !ForestPlace(x,y):
							Color(90,90,90)
							Rect(Float(width-1)/Float(ForestGridSize+1)*x+1,Float(height-1)/Float(ForestGridSize+1)*y+1,(Float(width-1)/Float(ForestGridSize+1))-1,(Float(height-1)/Float(ForestGridSize+1))-1,False)

				for x: int in range(ForestGridSize + 1):
					for y: int in range(ForestGridSize + 1):
						Color(255,255,255)
						if x == ForestGridSize or y == ForestGridSize:
							Rect(Float(width-1)/Float(ForestGridSize+1)*x,Float(height-1)/Float(ForestGridSize+1)*y,(Float(width-1)/Float(ForestGridSize+1))+1,(Float(height-1)/Float(ForestGridSize+1))+1,True)
						else:
							Rect(Float(width-1)/Float(ForestGridSize+1)*x,Float(height-1)/Float(ForestGridSize+1)*y,(Float(width-1)/Float(ForestGridSize+1)),(Float(height-1)/Float(ForestGridSize+1)),True)


						PrevSelectedX=Grid_SelectedX
						PrevSelectedY=Grid_SelectedY
						if (MouseX()-GadgetX(map_2d))>(Float(width-1)/Float(ForestGridSize+1)*x+GadgetX(WinHandle)) and (MouseX()-GadgetX(map_2d))<((Float(width-1)/Float(ForestGridSize+1)*x)+(Float(width-1)/Float(ForestGridSize+1))+GadgetX(WinHandle)):
							offset = 45
							if (MouseY()-GadgetY(map_2d))>(Float(height-1)/Float(ForestGridSize+1)*y+GadgetY(WinHandle)+offset) and (MouseY()-GadgetY(map_2d))<((Float(height-1)/Float(ForestGridSize+1)*y)+(Float(height-1)/Float(ForestGridSize+1))+GadgetY(WinHandle)+offset):
								Color(200,200,200)
								Rect(Float(width-1)/Float(ForestGridSize+1)*x,Float(height-1)/Float(ForestGridSize+1)*y,(Float(width-1)/Float(ForestGridSizee+1)),(Float(height-1)/Float(ForestGridSize+1)),True)
								if !ForestPlace[x][y] and SelectedGadgetItem(listbox) > -1:
									x2 = float(width)/float(ForestGridSize+1)
									y2 = float(height)/float(ForestGridSize+1)
									DrawImage(PlusIcon,(x2*x)+(x2/2.0)+0.5,(y2*y)+(y2/2.0)+0.5)

								if MouseHit1:
									if !(Grid_SelectedX == x and Grid_SelectedY == y):
										item = SelectedGadgetItem( listbox )
										if ForestPlace(x,y):
											Grid_SelectedX=x
											Grid_SelectedY=y
											ChangeGridGadget = True
											GridGadgetText = ""
											SelectGadgetItem(listbox,-1)
											HideGadget(listbox)
											ShowGadget(listbox)

											ClearGadgetItems(combobox)

											for rt: RoomTemplates in EachRoomTemplates:
												if rt == ForestPlace(x,y):
													SetGadgetText(room_desc,"Room description:"+Chr(13)+rt.Description)
													break

											DisableGadget(combobox)
											SetGadgetText(event_desc, "")
											SetGadgetText(event_prob_label, "")
											SetSliderValue(event_prob,99)
											DisableGadget(event_prob)

										if item >= 0:
											if !ForestPlace(x,y):
												room_name = GadgetItemText(listbox, item)
												for rt: RoomTemplates in EachRoomTemplates:
													if rt.Name == room_name:
														ForestPlace[x][y] = rt
														break

								if MouseDown2:
									Grid_SelectedX=-1
									Grid_SelectedY=-1
									ChangeGridGadget = True
									GridGadgetText = ""
									SetSliderValue(event_prob,99)
									SetGadgetText(event_prob_label,"")
									DisableGadget(event_prob)
									SetGadgetText(event_desc,"")
									DisableGadget(combobox)
									ClearGadgetItems(combobox)
									if ForestPlace[x][y]:
										ForestPlace[x][y]=Null
										ForestPlaceAngle[x][y]=0

								if MouseHit3:
									Grid_SelectedX=-1
									Grid_SelectedY=-1
									ChangeGridGadget = True
									GridGadgetText = ""
									SetSliderValue(event_prob,99)
									SetGadgetText(event_prob_label,"")
									DisableGadget(event_prob)
									SetGadgetText(event_desc,"")
									DisableGadget(combobox)
									ClearGadgetItems(combobox)

						if Grid_SelectedX == x and Grid_SelectedY == y:
							Color(150,150,150)
							Rect(Float(width-1)/Float(ForestGridSize+1)*x,Float(height-1)/Float(ForestGridSize+1)*y,(Float(width-1)/Float(ForestGridSize+1)),(Float(height-1)/Float(ForestGridSize+1)),True)

						if !ForestPlace(x,y):
							Color(90,90,90)
							Rect(Float(width-1)/Float(ForestGridSize+1)*x+1,Float(height-1)/Float(ForestGridSize+1)*y+1,(Float(width-1)/Float(ForestGridSize+1))-1,(Float(height-1)/Float(ForestGridSize+1))-1,False)
						else:
							x2 = Float(width-1)/Float(ForestGridSize+1)
							y2 = Float(height-1)/Float(ForestGridSize+1)
							if ForestPlace(x,y).Name == "SCP-860-1 door":
								DrawImage(SpecialIcons(1,Floor(ForestPlaceAngle(x,y)/90.0)),(x2*x)+(x2/2.0)+0.5,(y2*y)+(y2/2.0)+0.5)
							else:
								DrawImage(ForestIcons(ForestPlace(x,y).Shape,Floor(ForestPlaceAngle(x,y)/90.0)),(x2*x)+(x2/2.0)+0.5,(y2*y)+(y2/2.0)+0.5)

							if Grid_SelectedX == x and Grid_SelectedY == y:
								if PrevSelectedX != Grid_SelectedX or PrevSelectedY != Grid_SelectedY:
									ChangeGridGadget = True
									GridGadgetText = "Name: "+ForestPlace(x,y).Name+Chr(13)+"Angle: "+ForestPlaceAngle(x,y)+"�"

				if MouseDown1:
					if Grid_SelectedX > -1 and Grid_SelectedY > -1:
						if MouseX()>(GadgetX(map_2d)+GadgetX(WinHandle)) and MouseX()<((width)+GadgetX(map_2d)+GadgetX(WinHandle)):
							offset = 45
							if MouseY()>(GadgetY(map_2d)+GadgetY(WinHandle)+offset) and MouseY()<((height)+GadgetY(map_2d)+GadgetY(WinHandle)+offset):
								prevAngle = ForestPlaceAngle(Grid_SelectedX,Grid_SelectedY)
								#Left
								if (MouseX()-GadgetX(map_2d))<(Float(width-1)/Float(ForestGridSize+1)*Grid_SelectedX+GadgetX(WinHandle)):
									ForestPlaceAngle[Grid_SelectedX][Grid_SelectedY] = 90

								#Right
								if (MouseX()-GadgetX(map_2d))>((Float(width-1)/Float(ForestGridSize+1)*Grid_SelectedX)+(Float(width-1)/Float(ForestGridSize+1))+GadgetX(WinHandle)):
									ForestPlaceAngle[Grid_SelectedX][Grid_SelectedY] = 270

								#Up
								offset = 45
								if (MouseY()-GadgetY(map_2d))<(Float(height-1)/Float(ForestGridSize+1)*Grid_SelectedY+GadgetY(WinHandle)+offset):
									ForestPlaceAngle[Grid_SelectedX][Grid_SelectedY] = 180

								#Down
								if (MouseY()-GadgetY(map_2d))>((Float(height-1)/Float(ForestGridSize+1)*Grid_SelectedY)+(Float(height-1)/Float(ForestGridSize+1))+GadgetY(WinHandle)+offset):
									ForestPlaceAngle[Grid_SelectedX][Grid_SelectedY] = 0

								width2 = Float(width-1)/Float(ForestGridSize+1)/2.0
								height2 = Float(height-1)/Float(ForestGridSize+1)/2.0
								DrawImage(Arrows(Floor(ForestPlaceAngle(Grid_SelectedX,Grid_SelectedY)/90)),Float(width-1)/Float(ForestGridSize+1)*Grid_SelectedX+width2,Float(height-1)/Float(ForestGridSize+1)*Grid_SelectedY+height2)
								if prevAngle != ForestPlaceAngle(Grid_SelectedX,Grid_SelectedY):
									ChangeGridGadget = True
									GridGadgetText="Name: "+ForestPlace(Grid_SelectedX,Grid_SelectedY).Name+Chr(13)+"Angle: "+ForestPlaceAngle(Grid_SelectedX,Grid_SelectedY)+"�"

			#Maintenance tunnel grid
			else: #20*28
				for x: int in range(MT_GridSize + 1):
					for y: int in range(MT_GridSize + 1):
						Color(255,255,255)
						Rect(Float(width)/Float(MT_GridSize+1)*x,Float(height)/Float(MT_GridSize+1)*y,(Float(width)/Float(MT_GridSize+1)),(Float(height)/Float(MT_GridSize+1)),True)

						PrevSelectedX = Grid_SelectedX
						PrevSelectedY = Grid_SelectedY
						if (MouseX()-GadgetX(map_2d))>(Float(width)/Float(MT_GridSize+1)*x+GadgetX(WinHandle)) and (MouseX()-GadgetX(map_2d))<((Float(width)/Float(MT_GridSize+1)*x)+(Float(width)/Float(MT_GridSize+1))+GadgetX(WinHandle)):
							offset = 45
							if (MouseY()-GadgetY(map_2d))>(Float(height)/Float(MT_GridSize+1)*y+GadgetY(WinHandle)+offset) and (MouseY()-GadgetY(map_2d))<((Float(height)/Float(MT_GridSize+1)*y)+(Float(height)/Float(MT_GridSize+1))+GadgetY(WinHandle)+offset):
								Color(200,200,200)
								Rect(Float(width)/Float(MT_GridSize+1)*x,Float(height)/Float(MT_GridSize+1)*y,(Float(width)/Float(MT_GridSize+1)),(Float(height)/Float(MT_GridSize+1)),True)
								if !MTRoom[x][y] and SelectedGadgetItem(listbox) > -1:
									x2 = Float(width)/Float(MT_GridSize+1)
									y2 = Float(height)/Float(MT_GridSize+1)
									DrawImage(PlusIcon,(x2*x)+(x2/2.0)+0.5,(y2*y)+(y2/2.0)+0.5)

								if MouseHit1:
									if !(Grid_SelectedX == x and Grid_SelectedY == y):
										item = SelectedGadgetItem( listbox )
										if MTRoom[x][y]:
											Grid_SelectedX=x
											Grid_SelectedY=y
											ChangeGridGadget = True
											GridGadgetText = ""
											SelectGadgetItem(listbox,-1)
											HideGadget(listbox)
											ShowGadget(listbox)

											ClearGadgetItems(combobox)

											for rt: RoomTemplates in EachRoomTemplates:
												if rt == MTRoom[x][y]:
													SetGadgetText(room_desc,"Room description:"+Chr(13)+rt.Description)
													break

											DisableGadget(combobox)
											SetGadgetText(event_desc, "")
											SetGadgetText(event_prob_label, "")
											SetSliderValue(event_prob,99)
											DisableGadget(event_prob)

										if item>=0:
											if !MTRoom[x][y]:
												room_name = GadgetItemText(listbox, item)
												for rt: RoomTemplates in EachRoomTemplates:
													if rt.Name == room_name:
														MTRoom[x][y]=rt
														break

								if MouseDown2:
									Grid_SelectedX=-1
									Grid_SelectedY=-1
									ChangeGridGadget = True
									GridGadgetText = ""
									SetSliderValue(event_prob,99)
									SetGadgetText(event_prob_label,"")
									DisableGadget(event_prob)
									SetGadgetText(event_desc,"")
									DisableGadget(combobox)
									ClearGadgetItems(combobox)
									if MTRoom[x][y]:
										MTRoom[x][y]=Null
										MTRoomAngle[x][y]=0

								if MouseHit3:
									Grid_SelectedX=-1
									Grid_SelectedY=-1
									ChangeGridGadget = True
									GridGadgetText = ""
									SetSliderValue(event_prob,99)
									SetGadgetText(event_prob_label,"")
									DisableGadget(event_prob)
									SetGadgetText(event_desc,"")
									DisableGadget(combobox)
									ClearGadgetItems(combobox)

						if Grid_SelectedX == x and Grid_SelectedY == y:
							Color(150,150,150)
							Rect(Float(width)/Float(MT_GridSize+1)*x,Float(height)/Float(MT_GridSize+1)*y,(Float(width)/Float(MT_GridSize+1)),(Float(height)/Float(MT_GridSize+1)),True)

						if !MTRoom(x,y):
							Color(90,90,90)
							Rect(Float(width)/Float(MT_GridSize+1)*x+1,Float(height)/Float(MT_GridSize+1)*y+1,(Float(width)/Float(MT_GridSize+1))-1,(Float(height)/Float(MT_GridSize+1))-1,False)
						else:
							x2 = Float(width)/Float(MT_GridSize+1)
							y2 = Float(height)/Float(MT_GridSize+1)
							if MTRoom(x,y).Name == "Maintenance tunnel elevator":
								DrawImage(SpecialIcons(2,Floor(MTRoomAngle(x,y)/90.0)),(x2*x)+(x2/2.0)+0.5,(y2*y)+(y2/2.0)+0.5)
							else:
								DrawImage(MapIcons(MTRoom(x,y).Shape,Floor(MTRoomAngle(x,y)/90.0)),(x2*x)+(x2/2.0)+0.5,(y2*y)+(y2/2.0)+0.5)

							if Grid_SelectedX == x and Grid_SelectedY == y:
								if PrevSelectedX != Grid_SelectedX or PrevSelectedY != Grid_SelectedY:
									ChangeGridGadget = True
									GridGadgetText = "Name: "+MTRoom(x,y).Name+Chr(13)+"Angle: "+MTRoomAngle(x,y)+"�"

				if MouseDown1:
					if Grid_SelectedX > -1 and Grid_SelectedY > -1:
						if MouseX()>(GadgetX(map_2d)+GadgetX(WinHandle)) and MouseX()<((width)+GadgetX(map_2d)+GadgetX(WinHandle)):
							offset = 45
							if MouseY()>(GadgetY(map_2d)+GadgetY(WinHandle)+offset) and MouseY()<((height)+GadgetY(map_2d)+GadgetY(WinHandle)+offset):
								prevAngle = MTRoomAngle[Grid_SelectedX][Grid_SelectedY]
								#Left
								if (MouseX()-GadgetX(map_2d))<(Float(width)/Float(MT_GridSize+1)*Grid_SelectedX+GadgetX(WinHandle)):
									MTRoomAngle[Grid_SelectedX][Grid_SelectedY]=90

								#Right
								if (MouseX()-GadgetX(map_2d))>((Float(width)/Float(MT_GridSize+1)*Grid_SelectedX)+(Float(width)/Float(MT_GridSize+1))+GadgetX(WinHandle)):
									MTRoomAngle[Grid_SelectedX][Grid_SelectedY]=270

								#Up
								offset = 45
								if (MouseY()-GadgetY(map_2d))<(Float(height)/Float(MT_GridSize+1)*Grid_SelectedY+GadgetY(WinHandle)+offset):
									MTRoomAngle[Grid_SelectedX][Grid_SelectedY]=180

								#Down
								if (MouseY()-GadgetY(map_2d))>((Float(height)/Float(MT_GridSize+1)*Grid_SelectedY)+(Float(height)/Float(MT_GridSize+1))+GadgetY(WinHandle)+offset):
									MTRoomAngle[Grid_SelectedX][Grid_SelectedY]=0

								width2 = Float(width)/Float(MT_GridSize+1)/2.0
								height2 = Float(height)/Float(MT_GridSize+1)/2.0
								DrawImage(Arrows(Floor(MTRoomAngle(Grid_SelectedX,Grid_SelectedY)/90)),Float(width)/Float(MT_GridSize+1)*Grid_SelectedX+width2,Float(height)/Float(MT_GridSize+1)*Grid_SelectedY+height2)
								if prevAngle!=MTRoomAngle(Grid_SelectedX,Grid_SelectedY):
									ChangeGridGadget = True
									GridGadgetText="Name: "+MTRoom(Grid_SelectedX,Grid_SelectedY).Name+Chr(13)+"Angle: "+MTRoomAngle(Grid_SelectedX,Grid_SelectedY)+"�"

			FlipCanvas(map_2d)

		if -1 in [Grid_SelectedX, Grid_SelectedY]:
			var prevEvent = MapEvent(Grid_SelectedX,Grid_SelectedY)
			item2 = SelectedGadgetItem(combobox)
			if item2>=0:
				event_name = GadgetItemText(combobox, item2)
				if event_name != prevEvent:
					if event_name != "" and event_name != "[none]":
						MapEvent[Grid_SelectedX][Grid_SelectedY]=event_name
						MapEventProb[Grid_SelectedX][Grid_SelectedY]=Float((SliderValue(event_prob)+1)/100.0)
						GridGadgetText="Name: "+Map(Grid_SelectedX,Grid_SelectedY).Name+Chr(13)+"Angle: "+MapAngle(Grid_SelectedX,Grid_SelectedY)+"�"+Chr(13)+"Event: "+MapEvent[Grid_SelectedX][Grid_SelectedY]+Chr(13)+"Event Chance: "+Int(MapEventProb[Grid_SelectedX][Grid_SelectedY]*100)+"%"
						ChangeGridGadget=True
					else:
						MapEvent[Grid_SelectedX][Grid_SelectedY]=event_name
						MapEventProb[Grid_SelectedX][Grid_SelectedY]=0.0
						GridGadgetText="Name: "+Map(Grid_SelectedX,Grid_SelectedY).Name+Chr(13)+"Angle: "+MapAngle(Grid_SelectedX,Grid_SelectedY)+"�"
						ChangeGridGadget=True

		if ChangeGridGadget:
			SetGadgetText(grid_room_info, GridGadgetText)
			ChangeGridGadget=False

		id=WaitEvent()
		if ID == 803:
			if EventSource() == winhandle:
				break # Handle the close gadget on the window being hit
			if EventSource() == optionwin:
				HideGadget(optionwin)
			if EventSource() == map_settings:
				HideGadget(map_settings)
			if EventSource() == authordescr_settings:
				HideGadget(authordescr_settings)
		if ID == 1001:
		# extract the EventData as this will contain our unique id for the menu item
			EID=EventData()
			if EID == 0:

				result = Proceed("Save current map?",True)
				if result == 1:
					SetStatusText(winhandle, "Created new map and saving prev. map")
					if FileType(filename) != 1:
						filename = RequestFile("Open map","cbmap",True,"")

					if filename:
						SaveMap(filename)

					EraseMap()
					if !ShowGrid:
						SaveMap("CONFIG_MAPINIT.SI",True)

					filename = ""

				elif result == 0:
					SetStatusText(winhandle, "Created new map without saving prev. map")
					EraseMap()
					if !ShowGrid:
						SaveMap("CONFIG_MAPINIT.SI",True)

					filename = ""
				elif result == -1:
					SetStatusText(winhandle, "Creating new map has been cancelled")

			if EID == 1:
				filename = RequestFile("Open Map","*cbmap2#*cbmap,*cbmap2,*cbmap",False,"")
				if filename != "":
					LoadMap(filename)

			if EID == 2:
				if FileType(filename) != 1:
					filename = RequestFile("Save Map","cbmap2,cbmap",True,"")

				if filename:
					if Right(filename,5) == "cbmap":
						value = Confirm("cbmap is an outdated file format. Some data can be lost if you save your map to this file format."+Chr(13)+"Are you sure you want to proceed?",0)
						if value == 1:
							SaveMap(filename,False,1)

					else:
						SaveMap(filename)

			if EID == 3:
				while true:
					filename = RequestFile("Save Map","cbmap2,cbmap",True,"")
					if filename!="":
						if Right(filename,5) == "cbmap":
							value = Confirm("cbmap is an outdated file format. Some data can be lost if you save your map to this file format."+Chr(13)+"Are you sure you want to proceed?",0)
							if value == 0:
								continue

							SaveMap(filename,False,1)
						else:
							SaveMap(filename)
					break

			if EID == 6:
				ExecFile("Manual.pdf")
			if EID == 40:
				Notify("SCP Containement Breach Map Creator v"+versionnumber+""+Chr(13)+" created by Vane Brain and ENDSHN.")
			if EID == 17:
				ShowGadget(optionwin)

			if EID == 15:
				value=MenuChecked(event_default)
				if value == 0:
					CheckMenu(event_default)
				if value == 1:
					UncheckMenu(event_default)
				UpdateWindowMenu(winhandle)
				PutINIValue("options.INI","general","events_default", !value)

			if EID == 16:
				value=MenuChecked(adjdoor_place)
				if value == 0:
					CheckMenu(adjdoor_place)
				if value == 1:
					UncheckMenu(adjdoor_place)
				UpdateWindowMenu(winhandle)
				PutINIValue("options.INI","3d scene","adjdoors_place", !value)
				WriteOptions()

			if EID == 18:
				ShowGadget(map_settings)

			if EID == 19:
				ShowGadget(authordescr_settings)

			if EID == 10001:
				quit()

		DebugLog(EventData())
		if ID == 401:
			if EventSource() == tab:
				#in EventData steht das neue Item
				#also in Abhangigkeit des Gadgets zeigen und verstecken
				match EventData():
					0:
						ShowWindow(vwprt ,0)
						ShowGadget(listbox )
						ShowGadget(event_desc )
						ShowGadget(txtbox )
						ShowGadget(ok )
						ShowGadget(clean_txt)
						ShowGadget(combobox)
						ShowGadget(map_2d)
						ShowGadget(room_desc)
						ShowGadget(event_prob)
						ShowGadget(event_prob_label)
						ShowGadget(grid_room_info)
						ShowGadget(tab2)
						SetGadgetShape(tab, 0,5,ResWidth/4+20,ResHeight-60)
						ShowGrid = True
					1:
						ShowWindow(vwprt ,1)
						HideGadget(listbox )
						HideGadget(event_desc )
						HideGadget(txtbox )
						HideGadget(ok )
						HideGadget(clean_txt)
						HideGadget(combobox)
						HideGadget(map_2d)
						HideGadget(room_desc)
						HideGadget(event_prob)
						HideGadget(event_prob_label)
						HideGadget(grid_room_info)
						HideGadget(tab2)
						SetGadgetShape(tab, 0,5,ResWidth,ResHeight-60)
						ShowGrid = False
						SaveMap("CONFIG_MAPINIT.SI",True)

			if EventSource() == tab2:
				CurrMapGrid = EventData()
				ClearGadgetItems(listbox)
				for rt: RoomTemplates in EachRoomTemplates:
					if rt.MapGrid == CurrMapGrid:
						AddGadgetItem(listbox, rt.Name)

				ClearGadgetItems(combobox)
				DisableGadget(combobox)
				SetGadgetText(event_desc, "")
				SetGadgetText(event_prob_label, "")
				SetSliderValue(event_prob,99)
				DisableGadget(event_prob)
				SetGadgetText(room_desc,"Room description:")
				Grid_SelectedX=-1
				Grid_SelectedY=-1

			if EventSource() == color_button:
				if RequestColor(GetINIInt("options.INI","3d scene","bg color R"),GetINIInt("options.INI","3d scene","bg color G"),GetINIInt("options.INI","3d scene","bg color B")) == 1:
					redfog=RequestedRed()
					greenfog=RequestedGreen()
					bluefog=RequestedBlue()
					SetGadgetText(labelfogR, "R "+redfog)
					SetGadgetText(labelfogG, "G "+greenfog)
					SetGadgetText(labelfogB, "B "+bluefog)

			if EventSource() == color_button2:
				if RequestColor(GetINIInt("options.INI","3d scene","cursor color R"),GetINIInt("options.INI","3d scene","cursor color G"),GetINIInt("options.INI","3d scene","cursor color B")) == 1:
					redcursor=RequestedRed()
					greencursor=RequestedGreen()
					bluecursor=RequestedBlue()
					SetGadgetText(labelcursorR, "R "+redcursor)
					SetGadgetText(labelcursorG, "G "+greencursor)
					SetGadgetText(labelcursorB, "B "+bluecursor)

			if EventSource() == cancelopt_button:
				SetGadgetText(labelfogR,"R "+GetINIInt("options.INI","3d scene","bg color R"))
				SetGadgetText(labelfogG,"G "+GetINIInt("options.INI","3d scene","bg color G"))
				SetGadgetText(labelfogB,"B "+GetINIInt("options.INI","3d scene","bg color B"))
				SetGadgetText(labelcursorR,"R "+GetINIInt("options.INI","3d scene","cursor color R"))
				SetGadgetText(labelcursorG,"G "+GetINIInt("options.INI","3d scene","cursor color G"))
				SetGadgetText(labelcursorB,"B "+GetINIInt("options.INI","3d scene","cursor color B"))
				SetGadgetText(camerarange, GetINIInt("options.INI","3d scene","camera range"))
				SetButtonState(vsync, GetINIInt("options.INI","3d scene","vsync"))
				SetButtonState(showfps, GetINIInt("options.INI","3d scene","show fps"))
				HideGadget(optionwin)

			if EventSource() == saveopt_button:
				HideGadget(optionwin)
				SetStatusText(winhandle, "New settings are saved")
				PutINIValue("options.INI","3d scene","bg color R",redfog)
				PutINIValue("options.INI","3d scene","bg color G",greenfog)
				PutINIValue("options.INI","3d scene","bg color B",bluefog)
				PutINIValue("options.INI","3d scene","cursor color R",redcursor)
				PutINIValue("options.INI","3d scene","cursor color G",greencursor)
				PutINIValue("options.INI","3d scene","cursor color B",bluecursor)
				PutINIValue("options.INI","3d scene","camera range",TextFieldText(camerarange))
				PutINIValue("options.INI","3d scene","vsync",ButtonState(vsync))
				PutINIValue("options.INI","3d scene","show fps",ButtonState(showfps))
				WriteOptions()

			if EventSource() == resetzonetrans:
				SetGadgetText(zonetrans1,5)
				SetGadgetText(zonetrans2,11)
				zonetransvalue1 = (MapHeight)-Int(TextFieldText(zonetrans1))
				zonetransvalue2 = (MapHeight)-Int(TextFieldText(zonetrans2))

			if EventSource() == zonetrans1:
				SetGadgetText(zonetrans1,Int(TextFieldText(zonetrans1)))

			if EventSource() == zonetrans2:
				SetGadgetText(zonetrans2,Int(TextFieldText(zonetrans2)))

			if EventSource() == applyzonetrans:
				SetGadgetText(zonetrans2,Int(Min(Max(Int(TextFieldText(zonetrans2)),Int(TextFieldText(zonetrans1))+2),MapHeight-1)))
				SetGadgetText(zonetrans1,Int(Min(Max(Int(TextFieldText(zonetrans1)),1),Int(TextFieldText(zonetrans2))-2)))
				zonetransvalue1 = (MapHeight)-Int(TextFieldText(zonetrans1))
				zonetransvalue2 = (MapHeight)-Int(TextFieldText(zonetrans2))

			if EventSource() == ok:
				ClearGadgetItems(listbox)
				for rt: RoomTemplates in EachRoomTemplates:
					if rt.MapGrid == CurrMapGrid:
						if Instr(rt.Name,TextFieldText(txtbox)):
							AddGadgetItem(listbox, rt.Name)

			if EventSource() == clean_txt:
				SetGadgetText(txtbox, "")
				ClearGadgetItems(listbox)
				for rt: RoomTemplates in EachRoomTemplates:
					if rt.MapGrid == CurrMapGrid:
						AddGadgetItem(listbox, rt.Name)

			if EventSource() == combobox:
				item = SelectedGadgetItem( combobox )

				if item > -1:

					name = GadgetItemText(combobox,item)

					if item > 0:
						for ev: event in Eachevent:
							if ev.name == name:
								SetGadgetText(event_desc, "Event description:"+Chr(13)+ev.description)
								break

						SetGadgetText(event_prob_label,"Event chance: "+(SliderValue(event_prob)+1)+"%")
						EnableGadget(event_prob)
						SetSliderValue(event_prob,99)
					else:
						SetGadgetText(event_desc, "")
						SetGadgetText(event_prob_label, "")
						SetSliderValue(event_prob,99)
						DisableGadget(event_prob)

			if EventSource() == listbox:
				#In Abhangigkeit des Tabs den selektierten Eintrag herausfinden
				item = SelectedGadgetItem( listbox )

				Grid_SelectedX=-1
				Grid_SelectedY=-1
				ChangeGridGadget = True
				GridGadgetText = ""

				#Wenn ein Eintrag ausgewahlt wurde
				if item > -1:
					#Bezeichnung des Eintrags herausfinden
					name = GadgetItemText(listbox, item)

					ClearGadgetItems(combobox)

					hasEvent = False
					var currRT: RoomTemplates = Null

					for rt: RoomTemplates in EachRoomTemplates:
						if rt.Name == name:
							for i: int in range(6):
								if rt.Events[i]!="":
									InsertGadgetItem(combobox, 0, "[none]")
									hasEvent=True
									break

							for i: int in range(6):
								if rt.events[i]!="":
									InsertGadgetItem(combobox, i+1, rt.events[i])

							SetGadgetText(room_desc,"Room description:"+Chr(13)+rt.Description)
							currRT = rt
							break

					if CountGadgetItems( combobox ) > 0:
						if MenuChecked(event_default):
							SelectGadgetItem(combobox, 1)
						else:
							SelectGadgetItem(combobox, 0)

					if !hasEvent:
						DisableGadget(combobox)
						SetGadgetText(event_desc, "")
						SetGadgetText(event_prob_label, "")
						SetSliderValue(event_prob,99)
						DisableGadget(event_prob)
					else:
						EnableGadget(combobox)
						if SelectedGadgetItem(combobox) != 0:
							for ev: event in Eachevent:
								if ev.name == currRT.events[0]:
									SetGadgetText(event_desc, "Event description:"+Chr(13)+ev.description)
									break

							SetGadgetText(event_prob_label, "Event chance: 100%")
							SetSliderValue(event_prob,99)
							EnableGadget(event_prob)
						else:
							SetGadgetText(event_prob_label, "")
							SetSliderValue(event_prob,99)
							DisableGadget(event_prob)

					Grid_SelectedX=-1
					Grid_SelectedY=-1
					ChangeGridGadget = True
					GridGadgetText = ""

			if EventSource() == event_prob:
				SetGadgetText(event_prob_label,"Event chance: "+(SliderValue(event_prob)+1)+"%")
				if Grid_SelectedX != -1 and Grid_SelectedY != -1:
					x=Grid_SelectedX
					y=Grid_SelectedY
					MapEventProb[x][y]=Float((SliderValue(event_prob)+1)/100.0)
					if MapEvent[x][y] != "":
						GridGadgetText = "Name: "+Map[x][y].Name+Chr(13)+"Angle: "+MapAngle[x][y]+"�"+Chr(13)+"Event: "+MapEvent[x][y]+Chr(13)+"Event Chance: "+Int(MapEventProb[x][y]*100)+"%"

					SetGadgetText(grid_room_info, GridGadgetText)

	quit()


#------------------------------------------------------------------------------Facility
const MapWidth = 18
const MapHeight = 18





#------------------------------------------------------------------------------Forest
const ForestGridSize = 9



#------------------------------------------------------------------------------Maintenance Tunnels
const MT_GridSize = 18





var option_event = GetINIInt("options.INI","general","events_default")

var option_adjdoors = GetINIInt("options.INI","3d scene","adjdoors_place")


func StripPath(file: String) -> String:
	var name: String = ""
	if Len(file)>0:
		for i: int in range(Len(file) + 1, 1, -1):

			mi=Mid(file,i,1)
			if mi in ["\\", "/"]:
				return name

			name=mi+name

	return name

func Piece(s: String, entry, char: String = " ") -> String:
	while Instr(s,char+char):
		s=Replace(s,char+char,char)

	for n: int in range(1, entry):
		p=Instr(s,char)
		s=Right(s,Len(s)-p)

	p=Instr(s,char)
	if p < 1:
		a = s
	else:
		a = Left(s,p-1)

	return a

func GetINIString(file: String, section: String, parameter: String) -> String:
	var TemporaryString: String = ""
	var f: FileAccess = FileAccess.Open(file)

	while !Eof(f):
		if ReadLine(f) == "[%s]" % section:
			while !(Left(TemporaryString,1) == "[" or Eof(f)):
				TemporaryString = ReadLine(f)
				if Trim( Left(TemporaryString, Max(Instr(TemporaryString,"=")-1,0)) ) == parameter:
					CloseFile(f)
					return Trim( Right(TemporaryString,Len(TemporaryString)-Instr(TemporaryString,"=")) )

			CloseFile(f)
			return ""

	CloseFile(f)

func GetINIInt(file: String, section: String, parameter: String) -> int:
	var strtemp: String = Lower(GetINIString(file, section, parameter))

	match strtemp:
		"true":
			return 1
		"false":
			return 0
		_:
			return Int(strtemp)

	return

func GetINIFloat(file: String, section: String, parameter: String) -> float:
	return GetINIString(file, section, parameter)

func PutINIValue(INI_sAppName: String, INI_sSection: String, INI_sKey: String, INI_sValue: String) -> int:

# Returns: True (Success) or False (Failed)

	INI_sSection = "[%s]" % Trim(INI_sSection)
	INI_sUpperSection = Upper(INI_sSection)
	INI_sKey = Trim(INI_sKey)
	INI_sValue = Trim(INI_sValue)
	INI_sFilename = CurrentDir() + "/"  + INI_sAppName

# Retrieve the INI data (if it exists)

	INI_sContents = INI_FileToString(INI_sFilename)

# (Re)Create the INI file updating/adding the SECTION, KEY and VALUE

	INI_bWrittenKey = False
	INI_bSectionFound = False
	INI_sCurrentSection = ""

	INI_lFileHandle = WriteFile(INI_sFilename)
	if INI_lFileHandle == 0:
		return false # Create file failed!

	INI_lOldPos = 1
	INI_lPos = Instr(INI_sContents, Chr(0))

	while (INI_lPos != 0):

		INI_sTemp = Trim(Mid(INI_sContents, INI_lOldPos, (INI_lPos - INI_lOldPos)))

		if (INI_sTemp != ""):

			if Left(INI_sTemp, 1) == "[" and Right(INI_sTemp, 1) == "]":

				if (INI_sCurrentSection == INI_sUpperSection) and !INI_bWrittenKey:
					INI_bWrittenKey = INI_CreateKey(INI_lFileHandle, INI_sKey, INI_sValue)

				INI_sCurrentSection = Upper(INI_CreateSection(INI_lFileHandle, INI_sTemp))
				if (INI_sCurrentSection == INI_sUpperSection):
					INI_bSectionFound = True

			else:
				lEqualsPos = Instr(INI_sTemp, "=")
				if (lEqualsPos != 0):
					if (INI_sCurrentSection == INI_sUpperSection) and (Upper(Trim(Left(INI_sTemp, (lEqualsPos - 1)))) == Upper(INI_sKey)):
						if (INI_sValue != ""):
							INI_CreateKey(INI_lFileHandle, INI_sKey, INI_sValue)
						INI_bWrittenKey = True
					else:
						WriteLine(INI_lFileHandle, INI_sTemp)

		# Move through the INI file...

		INI_lOldPos = INI_lPos + 1
		INI_lPos = Instr(INI_sContents, Chr(0), INI_lOldPos)

	# KEY wasn't found in the INI file - Append a new SECTION if required and create our KEY=VALUE line

	if !INI_bWrittenKey:
		if !INI_bSectionFound:
			INI_CreateSection(INI_lFileHandle, INI_sSection)
		INI_CreateKey(INI_lFileHandle, INI_sKey, INI_sValue)

	CloseFile(INI_lFileHandle)

	return true

func INI_FileToString(INI_sFilename: String) -> String:

	INI_sString = ""
	INI_lFileHandle = ReadFile(INI_sFilename)
	if INI_lFileHandle != 0:
		while !Eof(INI_lFileHandle):
			INI_sString += ReadLine(INI_lFileHandle) + Chr(0)

		CloseFile(INI_lFileHandle)

	return INI_sString

func INI_CreateSection(INI_lFileHandle: int, INI_sNewSection: String) -> String:

	if FilePos(INI_lFileHandle) != 0:
		WriteLine(INI_lFileHandle, "") # Blank line between sections
	WriteLine(INI_lFileHandle, INI_sNewSection)
	return INI_sNewSection

func INI_CreateKey(INI_lFileHandle: int, INI_sKey: String, INI_sValue: String) -> int:

	WriteLine(INI_lFileHandle, INI_sKey + "=" + INI_sValue)
	return true

const ROOM1: int = 1
const ROOM2: int = 2
const ROOM2C: int = 3
const ROOM3: int = 4
const ROOM4: int = 5

const ZONEAMOUNT = 3


class RoomTemplates:
	var Shape: int
	var Name: String
	var Description: String
	var Large: int
	var id

	var events: PackedStringArray #[5]

	var MapGrid: int = 0

func CreateRoomTemplate() -> RoomTemplates:
	var rt: RoomTemplates = RoomTemplates.new()

	rt.id = RoomTempID
	RoomTempID += 1

	return rt

func LoadRoomTemplates(file: String) -> void:
	var TemporaryString: String
	var rt: RoomTemplates = Null
	var StrTemp: String = ""

	var f = OpenFile(file)

	#Facility rooms
	while !Eof(f):
		TemporaryString = Trim(ReadLine(f))
		if Left(TemporaryString,1) == "[":
			TemporaryString = Mid(TemporaryString, 2, Len(TemporaryString) - 2)

			var AddRoom: bool = True
			if TemporaryString in ["room ambience","173","pocketdimension","dimension1499","gatea"]:
				AddRoom = False

			if AddRoom:
				rt = CreateRoomTemplate()
				rt.Name = TemporaryString

				StrTemp = Lower(GetINIString(file, TemporaryString, "shape"))
				match StrTemp:
					"room1", "1":
						rt.Shape = ROOM1
					"room2", "2":
						rt.Shape = ROOM2
					"room2c", "2c":
						rt.Shape = ROOM2C
					"room3", "3":
						rt.Shape = ROOM3
					"room4", "4":
						rt.Shape = ROOM4

				rt.Description = GetINIString(file, TemporaryString, "descr")
				rt.Large = GetINIInt(file, TemporaryString, "large")

				rt.MapGrid = 0

	#Forest pieces
	var fr_prefix: String = "SCP-860-1 "
	rt = CreateRoomTemplate()
	rt.Name = fr_Prefix + "door"
	rt.Shape = ROOM1
	rt.Description = "FRDOOR"
	rt.MapGrid = 1
	rt = CreateRoomTemplate()
	rt.Name = fr_Prefix + "endroom"
	rt.Shape = ROOM1
	rt.Description = "FRENDROOM"
	rt.MapGrid = 1
	rt = CreateRoomTemplate()
	rt.Name = fr_Prefix + "path"
	rt.Shape = ROOM2
	rt.Description = "FRPATH"
	rt.MapGrid = 1
	rt = CreateRoomTemplate()
	rt.Name = fr_Prefix + "corner"
	rt.Shape = ROOM2C
	rt.Description = "FRCORNER"
	rt.MapGrid = 1
	rt = CreateRoomTemplate()
	rt.Name = fr_Prefix + "t-shaped path"
	rt.Shape = ROOM3
	rt.Description = "FRTSHAPE"
	rt.MapGrid = 1
	rt = CreateRoomTemplate()
	rt.Name = fr_Prefix + "4-way path"
	rt.Shape = ROOM4
	rt.Description = "FR4WAY"
	rt.MapGrid = 1

	#Maintenance tunnel rooms
	var mt_prefix: String = "Maintenance tunnel "
	rt = CreateRoomTemplate()
	rt.Name = mt_prefix + "endroom"
	rt.shape = ROOM1
	rt.Description = "MTENDROOM"
	rt.MapGrid = 2
	rt = CreateRoomTemplate()
	rt.Name = mt_prefix + "corridor"
	rt.shape = ROOM2
	rt.Description = "MTCORRIDOR"
	rt.MapGrid = 2
	rt = CreateRoomTemplate()
	rt.Name = mt_prefix + "corner"
	rt.shape = ROOM2C
	rt.Description = "MTCORNER"
	rt.MapGrid = 2
	rt = CreateRoomTemplate()
	rt.Name = mt_prefix + "t-shaped room"
	rt.shape = ROOM3
	rt.Description = "MTTSHAPE"
	rt.MapGrid = 2
	rt = CreateRoomTemplate()
	rt.Name = mt_prefix + "4-way room"
	rt.shape = ROOM4
	rt.Description = "MT4WAY"
	rt.MapGrid = 2
	rt = CreateRoomTemplate()
	rt.Name = mt_prefix + "elevator"
	rt.shape = ROOM2
	rt.Description = "MTELEVATOR"
	rt.MapGrid = 2
	rt = CreateRoomTemplate()
	rt.Name = mt_prefix + "generator room"
	rt.shape = ROOM1
	rt.Description = "MTGENERATOR"
	rt.MapGrid = 2

	CloseFile(f)

const MaxEvents = 9

class Event:
	var Name: String
	var Description: String
	var Room: PackedStringArray #[MaxEvents]

func InitEvents(file: String) -> void:
	var TemporaryString: String
	var e: Event = null
	var StrTemp: String = ""

	var f = OpenFile(file)

	while !Eof(f):
		TemporaryString = Trim(ReadLine(f))
		if Left(TemporaryString,1) == "[":
			TemporaryString = Mid(TemporaryString, 2, Len(TemporaryString) - 2)

			e = Event.new()
			e.Name = TemporaryString

			e.Description = GetINIString(file, TemporaryString, "descr")

			for i: int in range(1, MaxEvents + 1):
				e.Room[i] = GetINIString(file, TemporaryString, "room"+i)

	CloseFile(f)

func AddEvents() -> void:
	for rt: RoomTemplates in EachRoomTemplates:
		for e: Event in EachEvent:
			for i: int in range(1, MaxEvents + 1):
				if rt.Name == e.Room[i]:
					AssignEventToRoomTemplate(rt,e)

func AssignEventToRoomTemplate(rt: RoomTemplates, e: Event) -> void:
	for i: int in range(6):
		if rt.events[i] == "":
			rt.events[i] = e.Name
			break

func GetZone(y: int) -> void:
	return Min(Floor((Float(MapWidth-y)/MapWidth*ZONEAMOUNT)),ZONEAMOUNT-1)

func EraseMap() -> void:
	Grid_SelectedX=-1
	Grid_SelectedY=-1
	ChangeGridGadget = True
	GridGadgetText = ""

	var hasEvent: bool = False
	item = SelectedGadgetItem( listbox )
	if item > -1:
		name = GadgetItemText(listbox, item)
		for rt: RoomTemplates in EachRoomTemplates:
			if rt.Name == name:
				for i: int in range(6):
					if rt.events[i] != "":
						hasEvent = True

				break

	if !hasEvent:
		DisableGadget(combobox)
		SetGadgetText(event_desc, "")
		SetGadgetText(event_prob_label, "")
		SetSliderValue(event_prob,99)
		DisableGadget(event_prob)
	else:
		SetSliderValue(event_prob,99)
		SetGadgetText(event_prob_label,"Event chance: "+(SliderValue(event_prob)+1)+"%")

	for x: int in range(MapWidth + 1):
		for y: int in range(MapHeight + 1):
			Map[x][y]=Null
			MapAngle[x][y]=0
			MapEvent[x][y]=""
			MapEventProb[x][y]=0.0

	for x: int in range(ForestGridSize + 1):
		for y: int in range(ForestGridSize + 1):
			ForestPlace[x][y]=Null
			ForestPlaceAngle[x][y]=0

	for x: int in range(MT_GridSize + 1):
		for y: int in range(MT_GridSize + 1):
			MTRoom[x][y]=Null
			MTRoomAngle[x][y]=0

	zonetransvalue1 = 13
	zonetransvalue2 = 7
	SetGadgetText(zonetrans1,5)
	SetGadgetText(zonetrans2,11)
	MapAuthor = ""
	MapDescription = ""
	SetGadgetText(map_author_text,"")

func LoadMap(file: String) -> void:
	EraseMap()

	f = ReadFile(file)
	DebugLog(file)

	if Right(file,6) == "cbmap2":
		MapAuthor = ReadLine(f)
		MapDescription = ReadLine(f)

		if MapAuthor == "[Unknown]":
			MapAuthor = ""

		if MapDescription == "[No description]":
			MapDescription = ""

		SetGadgetText(map_author_text,MapAuthor)
		SetGadgetText(descr_text,MapDescription)
		zonetransvalue1 = ReadByte(f)
		zonetransvalue2 = ReadByte(f)
		SetGadgetText(zonetrans1,(MapHeight)-zonetransvalue1)
		SetGadgetText(zonetrans2,(MapHeight)-zonetransvalue2)
		var roomamount = ReadInt(f) #Amount of rooms
		var forestamount = ReadInt(f) #Amount of forest pieces
		var mtroomamount = ReadInt(f) #Amount of maintenance tunnel rooms

		#Facility rooms
		for i: int in range(roomamount):
			x = ReadByte(f)
			y = ReadByte(f)
			name = ReadString(f)
			DebugLog(x+", "+y+": "+name)
			for rt: roomtemplates in EachRoomTemplates:
				if Lower(rt.name) == name:
					DebugLog(rt.name)
					Map[x][y]=rt
					break

			MapAngle[x][y]=ReadByte(f)*90
			MapEvent[x][y] = ReadString(f)
			if MapEvent[x][y] == "":
				MapEvent[x][y]="[none]"

			MapEventProb[x][y] = ReadFloat(f)
			if MapEventProb[x][y] == 0.0:
				MapEventProb[x][y]=1.0

		#Forest pieces
		for i: int in range(forestamount):
			x = ReadByte(f)
			y = ReadByte(f)
			name = ReadString(f)
			DebugLog(x+", "+y+": "+name)
			for rt: roomtemplates in EachRoomTemplates:
				if Lower(rt.name) == name:
					DebugLog(rt.name)
					ForestPlace[x][y]=rt
					break

			ForestPlaceAngle[x][y]=ReadByte(f)*90

		#Maintenance tunnel pieces
		for i: int in range(mtroomamount):
			x = ReadByte(f)
			y = ReadByte(f)
			name = ReadString(f)
			DebugLog(x+", "+y+": "+name)
			for rt: roomtemplates in EachRoomTemplates:
				if Lower(rt.name) == name:
					DebugLog(rt.name)
					MTRoom[x][y]=rt
					break

			MTRoomAngle[x][y]=ReadByte(f)*90

	else:
		while !Eof(f):
			x = ReadByte(f)
			y = ReadByte(f)
			name = ReadString(f)
			DebugLog(x+", "+y+": "+name)
			for rt: roomtemplates in EachRoomTemplates:
				if Lower(rt.name) == name:
					DebugLog(rt.name)
					Map[x][y]=rt
					break

			MapAngle[x][y]=ReadByte(f)*90
			MapEvent[x][y] = ReadString(f)
			if !MapEvent[x][y]:
				MapEvent[x][y]="[none]"

			MapEventProb[x][y] = ReadFloat(f)
			if MapEventProb[x][y] == 0.0:
				MapEventProb[x][y]=1.0

	if !ShowGrid:
		SaveMap("CONFIG_MAPINIT.SI",True)

	CloseFile(f)

func SaveMap(file: String, streamtoprgm: bool = false, old: int = 0) -> void:
	f = WriteFile(file)

	if old == 0:
		MapAuthor = TextFieldText(map_author_text)
		if Trim(MapAuthor) == "":
			WriteLine(f,"[Unknown]")
		else:
			WriteLine(f,MapAuthor)

		MapDescription = TextAreaText(descr_text)
		if Trim(MapDescription) == "":
			WriteLine(f,"[No description]")
		else:
			WriteLine(f,MapDescription)

		WriteByte(f,zonetransvalue1)
		WriteByte(f,zonetransvalue2)
		#Facility room amount
		temp=0
		for x: int in range(MapWidth + 1):
			for y: int in range(MapHeight + 1):
				if Map(x,y):
					temp=temp+1

		WriteInt(f,temp)
		#Forest room amount
		temp=0
		for x: int in range(ForestGridSize + 1):
			for y: int in range(ForestGridSize + 1):
				if ForestPlace(x,y):
					temp += 1

		WriteInt(f,temp)
		#Maintenance tunnel room amount
		temp=0
		for x: int in range(MT_GridSize + 1):
			for y: int in range(MT_GridSize + 1):
				if MTRoom(x,y):
					temp += 1

		WriteInt(f,temp)

	if streamtoprgm:
		WriteInt(f,CurrMapGrid)

	for x: int in range(MapWidth):
		for y: int in range(MapHeight):
			if Map(x,y):
				WriteByte(f, x)
				WriteByte(f, y)
				WriteString(f, Lower(Map[x][y].Name))
				WriteByte(f, Floor(MapAngle(x,y)/90.0))
				if MapEvent(x,y)!="[none]":
					WriteString(f, MapEvent(x,y))
				else:
					WriteString(f, "")

				WriteFloat(f, MapEventProb(x,y))

				if streamtoprgm:
					if Grid_SelectedX == x and Grid_SelectedY == y:
						WriteByte(f,1)
					else:
						WriteByte(f,0)

	if old == 0:
		for x: int in range(ForestGridSize + 1):
			for y: int in range(ForestGridSize + 1):
				if ForestPlace(x,y):
					WriteByte(f, x)
					WriteByte(f, y)
					WriteString(f, Lower(ForestPlace(x,y).Name))
					WriteByte(f, Floor(ForestPlaceAngle(x,y)/90.0))

					if streamtoprgm:
						if Grid_SelectedX == x and Grid_SelectedY == y:
							WriteByte(f,1)
						else:
							WriteByte(f,0)

		for x: int in range(MT_GridSize + 1):
			for y: int in range(MT_GridSize + 1):
				if MTRoom(x,y):
					WriteByte(f, x)
					WriteByte(f, y)
					WriteString(f, Lower(MTRoom(x,y).Name))
					WriteByte(f, Floor(MTRoomAngle(x,y)/90.0))

					if streamtoprgm:
						if Grid_SelectedX == x and Grid_SelectedY == y:
							WriteByte(f,1)
						else:
							WriteByte(f,0)

	CloseFile(f)

func MilliSecs2() -> void:
	var retVal: int = MilliSecs()
	if retVal < 0:
		retVal += 2147483648
	return retVal

func WriteOptions() -> void:

	f = WriteFile("CONFIG_OPTINIT.SI")
	WriteInt(f,redfog)
	WriteInt(f,greenfog)
	WriteInt(f,bluefog)
	WriteInt(f,redcursor)
	WriteInt(f,greencursor)
	WriteInt(f,bluecursor)
	WriteInt(f,TextFieldText(camerarange))
	WriteByte(f,ButtonState(vsync))
	WriteByte(f,ButtonState(showfps))
	WriteByte(f,MenuChecked(adjdoor_place))
	CloseFile(f)
