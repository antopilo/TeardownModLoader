#include "game.lua"
#include "options.lua"
#include "score.lua"
#include "map.lua"
#include "about.lua"
#include "modloader.lua"

function init()
	sFrame = 0
	sPlayFrame = 0

	gPaused = false
	gPauseHeight = 500
	gAlarm = false

	sTextCounter = 0
	
	gNotification = ""
	gNotificationTimer = 0

	gPickInfo = false
	gPickInfoText = ""
	gPickInfoAlpha = 0
	gPickInfoTimer = 0
	gPickInfoChars = 0

	gCashDisplay = GetInt("savegame.cash")
	gCashScale = 0
	gCashCount = 0
	gCashFlash = 0

	gScoreDisplay = GetInt("savegame.hub.score")
	gScoreDisplayTimer = 1
	gScoreCurrent = getTotalScore()
	gScoreRank = getRank(gScoreDisplay)
	gScoreRankScale = 0
	gScoreRankTimer = 0
	gScoreRankZoom = 0

	gTargetInfoScale = 0
	gTargetInfoText = ""
	gTargetInfoTimer = 0
	gRequiredTaken = 0
	gOptionalTaken = 0

	gEndScreenScale = 0
	gEndScreenHeight = 300
	gEndScreenTime = 0
	gEndScreenHintScale = 0

	endfade = 0
	pauseMenuAlpha = 0
	optionsAlpha = 0
	notificationAlpha = 0

	showTargets = false
	targetFade = 0

	showHealth = false
	healthFade = 0
	
	gShowTitle = true
	gSandboxMode = false
	gHubMode = false
	gUnlimited = false
	gAboutMode = false

	gHintInfoScale = 0
	gHintInfo = ""

	gMissionId = GetString("game.levelid")
	gLevelPath = GetString("game.levelpath")
	if string.find(gLevelPath, "data/level/../../create/") then
		gMissions[gMissionId] = {}
		gMissions[gMissionId].title="Custom level"
		gMissions[gMissionId].desc="This is a custom level provided with source files. You play this mode with the same tools you have unlocked in the campaign."
		gMissions[gMissionId].securityTitle=""
		gMissions[gMissionId].securityDesc=""
		gMissions[gMissionId].primary=0
		gMissions[gMissionId].secondary=0
		gMissions[gMissionId].required=0
		gMissions[gMissionId].bonus = {}
		gSandboxMode = true
		gUnlimited = true
	elseif gMissionId == "" then
		gMissionId = "tmp"
		gMissions[gMissionId] = {}
		gMissions[gMissionId].title="Mission title"
		gMissions[gMissionId].desc="Mission description only available when started as a mission from the terminal. Mission details are specified in mission.lua"
		gMissions[gMissionId].securityTitle="Unknown"
		gMissions[gMissionId].securityDesc="No info"
		gMissions[gMissionId].primary=GetInt("level.primary")
		gMissions[gMissionId].secondary=GetInt("level.secondary")
		gMissions[gMissionId].required=GetInt("level.required")
		gMissions[gMissionId].bonus = {}
	elseif string.sub(gMissionId,1,3)=="hub" then
		gMissions[gMissionId] = {}
		gMissions[gMissionId].title="Lockelle Teardown Services"
		gMissions[gMissionId].desc="Family owned demolition company and your home base. Through the computer terminal you can read messages, accept missions and upgrade your tools."
		gMissions[gMissionId].securityTitle=""
		gMissions[gMissionId].securityDesc=""
		gMissions[gMissionId].primary=0
		gMissions[gMissionId].secondary=0
		gMissions[gMissionId].required=0
		gMissions[gMissionId].bonus = {}
		gSandboxMode = true
		gHubMode = true
	elseif string.sub(gMissionId,1,5)=="about" then
		gMissions[gMissionId] = {}
		gMissions[gMissionId].title=""
		gMissions[gMissionId].desc=""
		gMissions[gMissionId].securityTitle=""
		gMissions[gMissionId].securityDesc=""
		gMissions[gMissionId].primary=0
		gMissions[gMissionId].secondary=0
		gMissions[gMissionId].required=0
		gMissions[gMissionId].bonus = {}
		gAboutMode = true
	elseif gMissions[gMissionId] then
		if gMissions[gMissionId].primary~=GetInt("level.primary") then
			print("Warning: Primary count in missions description does not match primary target count")
		end
		if gMissions[gMissionId].secondary~=GetInt("level.secondary") then
			print("Warning: Secondary count in missions description does not match secondary target count")
		end
		if gMissions[gMissionId].required~=GetInt("level.required") then
			print("Warning: Required count in missions description does not match required targets in heist script")
		end
		gShowTitle = true
	else 
		for i=1,#gSandbox do
			if gSandbox[i].id == gMissionId then
				gMissions[gMissionId] = {}
				gMissions[gMissionId].title = gSandbox[i].name
				gMissions[gMissionId].desc = "Free roam sandbox play with unlimited resources. You play sandbox mode with the same tools you have unlocked in the campaign."
				gMissions[gMissionId].securityTitle=""
				gMissions[gMissionId].securityDesc=""
				gMissions[gMissionId].primary=0
				gMissions[gMissionId].secondary=0
				gMissions[gMissionId].required=0
				gMissions[gMissionId].bonus = {}
				gSandboxMode = true
				gUnlimited = true
			end
		end
	end
	gPrimaryTargetCount = gMissions[gMissionId].primaryTargets
	gSecondaryTargetCount = gMissions[gMissionId].secondaryTargets
	gMissionTitle = gMissions[gMissionId].title

	spawnPos = GetPlayerPos()
	titleFade = 0
	titleTimer = 0
	if gShowTitle then
		titleFade = 1
		titleTimer = 3
	end

	gState = ""

	gFireMeterShown = false
	gFireMeterScale = 0

	mapInit(gMissionId)

	modloader.init()

end


function update()
	sFrame = sFrame + 1
end


function drawTool()
	UiPush()
		UiTranslate(0, UiHeight()-60)
		UiAlign("top left")

		local enabledTools = {}
		local c = GetInt("game.tool.count")
		for i=1, c do
			local id = GetString("game.tool."..i)
			if GetBool("game.tool."..id..".enabled") then
				enabledTools[#enabledTools+1] = id
			end
		end
	
		local currentTool = GetString("game.player.tool")
		if not oldTool then 
			toolX = UiCenter()
			toolAlpha = 0
			oldTool = currentTool
			previousTool = oldTool		
		end

		if currentTool ~= oldTool then
			oldTool = currentTool
			for i=1, #enabledTools do
				if enabledTools[i] == currentTool then
					SetValue("toolX", UiCenter()-150*(i-1), "cosine", 0.2)
				end
			end
		end
		
		UiTranslate(toolX, 45)
		
		for i=1, #enabledTools do
			local t = enabledTools[i]
			UiPush()
				local alpha = math.min(1.0, toolAlpha)
				UiFont("font/bold.ttf", 26)
				UiAlign("center")
				local w = currentTool
				if previousTool ~= w then
					toolAlpha = 4
					SetValue("toolAlpha", 0, "linear", 2)	
					previousTool = w
				end
				if w == t then
					UiScale(1)
					UiTextOutline(0,0,0,1, 0.1)
					UiColor(1, 1, 1, 1.0)
				else
					UiScale(0.6)
					UiTextOutline(0,0,0,1*alpha, 0.1)
					UiColor(0.7, 0.7, 0.7, alpha)
				end
				UiText(string.upper(GetString("game.tool."..t..".name")))

				UiTranslate(0, -24)
				if w == t then UiScale(1.6) end
				if not gUnlimited then
					if t=="blowtorch" then
						local a = GetFloat("game.tool."..t..".ammo")
						a = math.floor(a*10)/10
						UiText(a)
					elseif t~="sledge" and t ~= "spraycan" and t ~= "extinguisher" then
						local a = GetInt("game.tool."..t..".ammo")
						UiText(a)
					end
				end
			UiPop()
			UiTranslate(150, 0)
		end
	UiPop()
end


function crosshair()
	UiPush()
		UiAlign("center middle")
		UiTranslate(UiCenter(), UiMiddle());
		local grabbing = GetBool("game.player.grabbing")
		if grabbing then
			UiPush()
				UiColor(1,1,1,0.75)
				UiTranslate(-3, -6)
				UiImage("hud/crosshair-hand.png")
			UiPop()
		end
		if not grabbing and GetBool("game.player.picking") then
			if GetString("game.player.tool") ~= "plank" or GetBool("game.player.canusetool") then
			UiImage("hud/crosshair-ring.png")
			end
		end
		if not GetBool("game.player.grabbing") then
			UiPush()
				UiImage("hud/crosshair-dot.png")
			UiPop()
			if GetString("game.player.tool") == "gun" then
				UiImage("hud/crosshair-gun.png")
			end
			if GetString("game.player.tool") == "shotgun" then
				UiImage("hud/crosshair-shotgun.png")
			end
			if GetString("game.player.tool") == "rocket" then
				UiImage("hud/crosshair-launcher.png")
			end
			if GetString("game.player.tool") == "plank" then
				if GetBool("game.player.canusetool") then
					UiImage("hud/crosshair-ring.png")
				end
			end
		end
	UiPop()
end


function drawPickInfo()
	UiPush()
		local currentInfo = GetString("game.player.pickdesc")
		local extra = GetString("level.pickinfo")
		if extra ~= "" then
			currentInfo = currentInfo .. " - " .. extra
		end

		if GetBool("game.map.enabled") or GetBool("game.player.grabbing") or GetBool("game.player.usescreen") then
			currentInfo = ""
		end

		if currentInfo == "" then
			gPickInfoTimer = 0.5
		end
		if gPickInfoTimer > 0 then
			gPickInfoTimer = gPickInfoTimer - 0.01667
			currentInfo = ""
		end
		if currentInfo ~= "" then
			if gPickInfoText ~= currentInfo then
				gPickInfoText = currentInfo
				gPickInfoChars = 0
			end

			if GetBool("game.player.idling") then
				if not gPickInfo then
					SetValue("gPickInfoAlpha", 1, "linear", 0.2)
				end
				gPickInfo = true
			end
		else
			if gPickInfo then
				SetValue("gPickInfoAlpha", 0, "linear", 0.2)
			end
			gPickInfo = false
		end
		local alpha = gPickInfoAlpha
		if alpha > 0 then
			UiTranslate(UiCenter(), UiHeight()-150)
			UiFont("font/bold.ttf", 28)
			UiWordWrap(1000)
			local w, h = UiGetTextSize(gPickInfoText)
			UiAlign("center middle")
			UiColor(0.5, 0.5, 0.5, 0.5)
			UiScale(1, alpha*0.5 + 0.5)
			UiColor(1,1,1,alpha*0.8)
			UiImageBox("common/box-solid-shadow-50.png", w+10, h, -50, -50)
			UiWindow(w+10, h)
			UiAlign("left")
			UiColor(0,0,0)
			UiTranslate(0, 22)
			gPickInfoChars = gPickInfoChars + 1
			UiText(gPickInfoText, false, gPickInfoChars)
		end

		SetString("level.pickinfo", "")
	UiPop()
end


--Draw hint box with arrow to the left, pointing at cursor position
function drawHint(str)
	UiPush()
		UiAlign("middle left")
		UiColor(1,1,1, 0.7)
		local w,h = UiImage("common/arrow-left.png")
		UiTranslate(w-1, 0)
		UiFont("font/bold.ttf", 22)
		 w,h = UiGetTextSize(str)
		UiImageBox("common/box-solid-6.png", w+40, h+12, 6, 6)
		UiPush()
			UiColor(0,0,0)
			UiTranslate(20, 0)
			UiText(str)
		UiPop()
	UiPop()
end


function drawEndScreen(f, state)
	if f > 0 then
		gEndScreenTime = gEndScreenTime + GetTimeStep()
		if gEndScreenHintScale == 0.0 and gEndScreenTime > 2.0 then
			SetValue("gEndScreenHintScale", 1, "linear", 0.5)
		end
		if gEndScreenHintScale == 1.0 and gEndScreenTime > 10.0 then
			SetValue("gEndScreenHintScale", 0.0001, "linear", 0.5)
		end

		if state == "win" and gMissionId == "frustrum_chase" then
			UiPush()
				UiTranslate(UiCenter()+100, UiMiddle())
				UiAlign("center middle")
				UiFont("font/bold.ttf", 44)
				UiColor(1,1,1, f)
				UiScale(2)
				UiText("TO BE CONTINUED...")
			UiPop()
		end

		UiPush()
			UiTranslate(-300+300*f, 0)

			--Dialog
			UiAlign("top left")
			UiColor(0, 0, 0, 0.7*f)
			UiRect(400, UiHeight())
			UiWindow(400, UiHeight())
			UiColor(1,1,1)
			UiPush()
				UiTranslate(0, 50)
				if state == "win" then
					UiPush()
						UiTranslate(UiCenter(), 0)
						UiAlign("center top")
						UiFont("font/bold.ttf", 44)
						UiScale(2)
						UiText("MISSION")
						UiTranslate(0, 35)
						UiScale(0.7)
						UiText("COMPLETED")
					UiPop()

					UiTranslate(0, 0)

					UiPush()

						local primary = GetInt("level.clearedprimary")
						local secondary = GetInt("level.clearedsecondary")
						local timeLeft = getTimeLeft()
						local missionTime = GetFloat("level.missiontime")

						local score = computeScore(gMissionId, primary, secondary, timeLeft)

						local saveScore = false
						if gMissionId ~= "tmp" then
							local scoreKey = "savegame.mission."
							local bestScore = GetInt(scoreKey..gMissionId..".score")
							local bestTimeLeft = GetInt(scoreKey..gMissionId..".timeleft")
							local bestMissionTime = GetInt(scoreKey..gMissionId..".missiontime")
							if score > bestScore then
								saveScore = true
							elseif score == bestScore then
								if timeLeft > 0 then
									if timeLeft > bestTimeLeft then
										saveScore = true
									end
								else
									if missionTime < bestMissionTime then
										saveScore = true
									end
								end
							end
							if saveScore then
								if GetInt(scoreKey..gMissionId..".score") == 0 then
									SetString("savegame.lastcompleted", gMissionId)
								end
								SetInt(scoreKey..gMissionId..".score", score)
								SetFloat(scoreKey..gMissionId..".timeleft", timeLeft)
								SetFloat(scoreKey..gMissionId..".missiontime", missionTime)
								if timeLeft > 0 then
									Command("game.path.save", gMissionId.."-best")
								end
							end
						end

						UiTranslate(UiCenter(), 150)
						UiAlign("center")
						UiFont("font/bold.ttf", 32)
						if saveScore then
							UiText("New highscore "..score)
						else
							UiText("Score "..score)
						end

						UiTranslate(-210, 20)
						h = drawScore("Score", gMissionId, score, timeLeft, missionTime, true, false)
					UiPop()
					UiTranslate(0, h)
				else
					local h
					UiPush()
						UiTranslate(UiCenter(), 0)
						UiAlign("center top")
						UiPush()
							UiFont("font/bold.ttf", 44)
							UiScale(2)
							UiColor(.8, 0, 0)
							UiText("MISSION")
							UiTranslate(0, 32)
							UiScale(1.27)
							UiColor(1, 0, 0)
							UiText("FAILED")
						UiPop()
						UiFont("font/regular.ttf", 22)
						UiAlign("top left")
						UiTranslate(-144, 180)
						UiColor(.8, .8, .8)
						UiWordWrap(290)
						local reason = ""
						if state == "fail_dead" then
							reason = "You died. Explosions, fire, falling and bullets can hurt you. Keep an eye on the health meter"
						elseif state == "fail_sound" then
							reason = "You made too much sound. Keep an eye on the audio level."
						elseif state == "fail_alarmtimer" then
							reason = "You failed to escape before security arrived. Make sure to plan properly."
						elseif state == "fail_missiontimer" then
							reason = "You ran out of time. Try again and find better shortcuts."
						end
						_,h = UiText(reason)
					UiPop()
					UiTranslate(0, 40+h)
				end
			UiPop()
			UiTranslate(0, UiHeight()-gEndScreenHeight)
			
			--Buttons at bottom
			UiPush()
				UiTranslate(UiCenter(), 0)
				UiFont("font/regular.ttf", 26)
				UiAlign("center middle")
				UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1, 0.8)

				if state == "win" then
					UiPush()
						UiTranslate(0, -20)
						UiColor(.7, 1, .8, 0.2)
						UiImageBox("common/box-solid-6.png", 260, 40, 6, 6)
						UiColor(1,1,1)
						if UiTextButton("Continue", 260, 40) then
							if gMissionId == "lee_flooding" then
								Command("game.startmission", "frustrum_chase", "frustrum.xml", "frustrum_chase")
							elseif gMissionId == "frustrum_chase" then
								Command("game.startmission", "about", "about.xml")
							else
								exitMission()
							end
						end
					UiPop()
					UiTranslate(0, 47)
				end

				UiPush()
					if not GetBool("game.canquickload") then
						UiDisableInput()
						UiColorFilter(1,1,1,0.5)
					end
					if UiTextButton("Quick load", 260, 40) then
						Command("game.quickload")
					end
				UiPop()
				UiPush()
					if GetInt("savegame.mission.lee_tower.score")==0 and GetBool("game.canquickload")==false and state ~= "win" and gEndScreenHintScale > 0 then
						UiTranslate(170, 0)
						UiColorFilter(1,1,1,gEndScreenHintScale)
						drawHint("Use quicksave from pause menu\nwhen playing to enable quickload")
					end
				UiPop()
				UiTranslate(0, 47)

				if UiTextButton("Restart mission", 260, 40) then
					Command("game.restart")
					Command("game.unpause")
				end
				UiTranslate(0, 47)
					
				UiTranslate(0, 20)
				if state ~= "win" then
					if UiTextButton("Abort mission", 260, 40) then
						exitMission()
					end
					UiTranslate(0, 47)
				end
				if UiTextButton("Main menu", 220, 40) then
					Command("game.exitlevel")
				end
				UiTranslate(0, 47)

				UiTranslate(0, 40)

				_,gEndScreenHeight = UiGetRelativePos()
			UiPop()
		UiPop()
	end
end


function getTimeLeft()
	local timeLeft = 9999

	if GetBool("level.alarm") then
		timeLeft = GetFloat("level.alarmtimer")
	end

	local timeLimit = GetFloat("level.timelimit")
	if timeLimit > 0 then
		local missionTimeLeft = math.max(0, timeLimit - GetFloat("level.missiontime"))
		timeLeft = math.min(timeLeft, missionTimeLeft)
	end

	if timeLeft == 9999 then
		return -1
	else
		return timeLeft
	end
end


function exitMission()
	if gSandboxMode then
		Command("game.menu")
	else
		startHub()
	end
end


function drawHeist()
	if not GetBool("level.alarm") then
		local hits = GetInt("game.cctv.hits")
		if hits > 0 then
			UiPush()
				UiTranslate(UiCenter()-100, 100)
				UiColor(0,0,0, 0.5)
				UiRect(200, 20)
				UiColor(1,0.5,0.5)
				UiTranslate(2, 2, 0)
				for i=1, hits do
					UiRect(16, 16)
					UiTranslate(20, 0)
				end
			UiPop()
		end
	end

	local s = GetString("level.state")
	if gState ~= s then
		gState = s
		if s ~= "" then
			endfade = 0
			SetValue("endfade", 1, "linear", 4)
			gState = s
		else
			endfade = 0
		end
	end
	if endfade == 1 and not GetBool("game.paused") then
		Command("game.pause")
		if gSandboxMode then
			SetValue("endfade", 0, "linear", 1)
			SetString("level.state", "")
			Command("game.respawn")
			Command("game.unpause")
		end
	end
	if endfade > 0.8 and not gSandboxMode then
		if gEndScreenScale == 0 then
			SetValue("gEndScreenScale", 1, "easeout", 0.5)
			gEndScreenTime = 0
			hideNotifications()
			initDrawScore()
		end
	else
		SetValue("gEndScreenScale", 0)
	end

	UiPush()
		if gState == "" then
			UiFont("font/bold.ttf", 32)
			local timeLeft = getTimeLeft()
			if timeLeft >= 0 then
				UiPush()
					UiTranslate(UiCenter()-50, 65)
					UiAlign("left")
					UiTextOutline(0, 0, 0, 1)
					UiColor(1, 1, 1)
					UiScale(2.0)
					if timeLeft < 60 then
						UiText(math.ceil(timeLeft*10)/10)
					else
						local t = math.ceil(timeLeft)
						local m = math.floor(t/60)
						local s = math.ceil(t-m*60)
						if s < 10 then
							UiText(m .. ":0" .. s)
						else
							UiText(m .. ":" .. s)
						end
					end
				UiPop()
			end
		end
	UiPop()

	if endfade > 0 then
		if endfade >= 1.0 then
			flyover()
		else
			UiPush()
				local a = clamp((endfade - 0.5)*2, 0, 1)
				UiColor(0,0,0,a)
				UiRect(UiWidth(), UiHeight())
			UiPop()
		end
		UiMute(endfade)
	end
	if gEndScreenScale > 0 then
		drawEndScreen(gEndScreenScale, gState)
	end

end


function progressBar(w, h, t)
	UiPush()
		UiAlign("left top")
		UiColor(0, 0, 0, 0.5)
		UiImageBox("common/box-solid-10.png", w, h, 6, 6)
		if t > 0 then
			UiTranslate(2, 2)
			w = (w-4)*t
			if w < 12 then w = 12 end
			h = h-4
			UiColor(1,1,1,1)
			UiImageBox("common/box-solid-6.png", w, h, 6, 6)
		end
	UiPop()
end


function drawVehicle()
	UiPush()
		UiFont("font/bold.ttf", 20)
		UiTranslate(UiCenter(), UiHeight()-40)
		local health = GetFloat("game.vehicle.health")
		UiTranslate(-100, 0)
		progressBar(200, 20, health)
		UiColor(1,1,1)
		UiTranslate(100, -12)
		UiAlign("center middle")
		UiText("VEHICLE CONDITION")
	UiPop()

	local vehicle = GetPlayerVehicle()
	local info = {}
	info[#info+1] = {"W A S D", "Drive"}
	if HasTag(vehicle, "crane") then
		info[#info+1] = {"LMB RMB", "Arm"}
		info[#info+1] = {"SPACE", "Hook"}
	elseif HasTag(vehicle, "dumptruck") then
		info[#info+1] = {"LMB RMB", "Bed"}
		info[#info+1] = {"SPACE", "Brake"}
	elseif HasTag(vehicle, "frontloader") then
		info[#info+1] = {"LMB RMB", "Shovel"}
		info[#info+1] = {"SPACE", "Brake"}
	elseif HasTag(vehicle, "skylift") then
		info[#info+1] = {"LMB RMB", "Lift"}
		info[#info+1] = {"SPACE", "Brake"}
	elseif HasTag(vehicle, "forklift") then
		info[#info+1] = {"LMB RMB", "Fork"}
		info[#info+1] = {"SPACE", "Brake"}
	elseif HasTag(vehicle, "boat") then
	else
		info[#info+1] = {"SPACE", "Handbrake"}
	end
	info[#info+1] = {"E", "Exit vehicle"}
	UiPush()
	UiAlign("top left")
	local w = 250
	local h = #info*22 + 30
	UiTranslate(UiWidth()-w-20, UiHeight()-h-20-healthFade*50)
	UiColor(0,0,0,0.5)
	UiImageBox("common/box-solid-6.png", 250, h, 6, 6)
	UiTranslate(125, 32)
	UiColor(1,1,1)
	for i=1, #info do
		local key = info[i][1]
		local func = info[i][2]
		UiFont("font/bold.ttf", 22)
		UiAlign("right")
		UiText(key)
		UiTranslate(10, 0)
		UiFont("font/regular.ttf", 22)
		UiAlign("left")
		UiText(func)
		UiTranslate(-10, 22)
	end
	UiPop()
end


function toolTutorial()
	if GetBool("game.paused") then
		UiPush()
			local visible = 1
			if not toolTutorialStep then
				toolTutorialStep = 1
			end

			local img = "hud/plank/lift.jpg"
			local txt = "Planks can be used to build primitive ramps."

			if toolTutorialStep == 1 then
				img = "hud/plank/ramp.jpg"
				txt = "Planks can be used to build primitive ramps"
			elseif toolTutorialStep == 2 then
				img = "hud/plank/lift.jpg"
				txt = "You can also attach objects with planks to lift or drag heavy items"
			elseif toolTutorialStep == 3 then
				img = "hud/plank/complex.jpg"
				txt = "Use multiple planks to build complex structures"
			end

			UiBlur(visible)
			UiColor(0.7,0.7,0.7, 0.25*visible)
			UiRect(UiWidth(), UiHeight())
			UiColorFilter(1,1,1,visible)

			UiTranslate(UiCenter(), UiMiddle())
			UiAlign("center middle")
			UiColor(.0, .0, .0, 0.7*visible)
			UiScale(1, visible)
			UiImageBox("common/box-solid-shadow-50.png", 800, 620, -50, -50)
			UiWindow(800, 620)

			UiAlign("center")
			UiTranslate(UiCenter(), 60)

			UiPush()
				UiFont("ui/font/bold.ttf", 32)
				UiColor(1,1,1)
				UiScale(1.5)
				UiText("Plank tool")
			UiPop()

			UiFont("font/regular.ttf", 26)
			UiColor(1, 1, 1)

			UiTranslate(0, 40)
			UiImage(img)

			UiTranslate(0, 400)
			UiPush()
				UiFont("font/regular.ttf", 22)
				UiText(txt)
			UiPop()

			UiTranslate(0, 80)
			UiPush()
				UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1, 0.8)
				if toolTutorialStep < 3 then
					if UiTextButton("Next", 200, 40) then
						toolTutorialStep = toolTutorialStep + 1
					end
				else
					if UiTextButton("Close", 200, 40) then
						SetBool("hud.tooltutorial", false)
						Command("game.unpause")
					end
				end
			UiPop()
		UiPop()
	end
end


function pauseMenu()
	local paused = GetBool("game.paused")
	if paused and not gPaused then
		SetValue("pauseMenuAlpha", 1, "easeout", 0.25)
		gPaused = true
		UiSound("hud/pause-on.ogg")
		optionsAlpha = 0
	end
	if not paused and gPaused then
		SetValue("pauseMenuAlpha", 0, "easein", 0.25)
		gPaused = false
		UiSound("hud/pause-off.ogg")
	end
	local visible = pauseMenuAlpha
	if visible == 0 then return end

	UiModalBegin()

	--Mute world sound. Also mute music if in alarm mode
	UiMute(visible, GetBool("level.alarm"))
	
	UiPush()
		UiBlur(visible)
		UiColor(0.7,0.7,0.7, 0.25*visible)
		UiRect(UiWidth(), UiHeight())
		UiColorFilter(1,1,1,visible*(1-optionsAlpha))		

		UiTranslate(UiCenter(), UiMiddle())
		UiAlign("center middle")
		UiColor(.0, .0, .0, 0.7*visible)
		UiScale(1, visible)
		UiImageBox("common/box-solid-shadow-50.png", 350, gPauseHeight, -50, -50)
		UiWindow(350, gPauseHeight)

		UiAlign("top left")
		if optionsAlpha == 0 and not UiIsMouseInRect(UiWidth(), UiHeight()) and UiIsMousePressed() then
			Command("game.unpause")
		end

		UiPush()
			UiAlign("center middle")
			UiTranslate(UiWidth()/2, 80)

			UiFont("font/regular.ttf", 26)

			UiColor(1, 1, 1)

			local bw = 230
			local bh = 40
			local space = 7
			local sep = 20

			UiColor(.7, 1, .8, 0.2)
			UiImageBox("common/box-solid-6.png", 200, bh, 6, 6)
			UiColor(1,1,1)

			UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1, 0.8)
			if UiTextButton("Continue", 200, bh) then
				Command("game.unpause")
			end

			UiTranslate(0, bh+space)

			UiPush()
				if GetBool("level.alarm") or GetBool("level.dispatch") or GetBool("level.disablequicksave") then
					UiDisableInput()
					UiColorFilter(1,1,1,0.5)
				end
				if UiTextButton("Quick save", 200, bh) then
					UiSound("common/click.ogg")
					Command("game.quicksave")
					Command("game.unpause")
				end
				if GetBool("hud.quicksavehint") and not GetBool("game.canquickload") then
					UiTranslate(130, 0)
					drawHint("Use quicksave before triggering the alarm to\navoid starting over from scratch in case you fail.")
				end
			UiPop()
			UiTranslate(0, bh+space+sep)

			UiPush()
				if not GetBool("game.canquickload") then
					UiDisableInput()
					UiColorFilter(1,1,1,0.5)
				end
				if UiTextButton("Quick load", bw, bh) then
					stopRecording()
					UiSound("common/click.ogg")
					Command("game.quickload")
				end
			UiPop()
			UiTranslate(0, bh+space)

			if gSandboxMode then
				if UiTextButton("Restart", bw, bh) then
					UiSound("common/click.ogg")
					stopRecording()
					Command("game.restart")
					Command("game.unpause")
				end
				UiTranslate(0, bh+space)
			else
				if UiTextButton("Restart mission", bw, bh) then
					UiSound("common/click.ogg")
					stopRecording()
					Command("game.restart")
					Command("game.unpause")
				end
				UiTranslate(0, bh+space)

				if UiTextButton("Abort mission", bw, bh) then
					UiSound("common/click.ogg")
					stopRecording()
					exitMission()
				end
				UiTranslate(0, bh+space)
			end

			UiTranslate(0, sep)

			if UiTextButton("Options", 200, bh) then
				SetValue("optionsAlpha", 1, "easeout", 0.25)
			end
			UiTranslate(0, bh+space)

			if UiTextButton("Main menu", 200, bh) then
				UiSound("common/click.ogg")
				Command("game.exitlevel")
			end

			if GetBool("game.deploy")==false and hudDebugQuickload then
				hudDebugQuickload()
			end

			_,gPauseHeight = UiGetRelativePos()
			gPauseHeight = gPauseHeight + 80
		UiPop()
	UiPop()
	
	if not drawOptions(optionsAlpha, false) then
		SetValue("optionsAlpha", 0, "easein", 0.25)
	end

	UiModalEnd()
end


function notify(str, t)
	SetValue("notificationAlpha", 1, "linear", 0.25)
	gNotification = str
	gNotificationTimer = t
	gHidingNotifications = false
end

function hideNotifications()
	if notificationAlpha > 0 and not gHidingNotifications then
		SetValue("notificationAlpha", 0, "linear", 0.25)
		gHidingNotifications = true
	end
end

function notifications()
	local n = notificationAlpha
	SetBool("hud.hasnotification", n > 0)
	if n > 0 then
		UiPush()
			UiTranslate(UiCenter(), 100)
			UiAlign("center middle")

			UiFont("font/bold.ttf", 24)
			local w,h = UiGetTextSize(gNotification)
			UiColor(0,0,0, 0.7*n)
			UiImageBox("common/box-solid-10.png", w+32, h+16, 10, 10)
			UiColor(1,1,1, n)
			UiText(gNotification)
		UiPop()
	end

	if gNotificationTimer > 0 then
		gNotificationTimer = gNotificationTimer - GetTimeStep()
		if gNotificationTimer <= 0 then
			gNotificationTimer = 0
			SetValue("notificationAlpha", 0, "linear", 0.5)
		end
	end
end


function interactInfo()
	if GetBool("game.player.caninteract") then
		local info = ""
		local body = GetInteractBody()
		if body ~= 0 then
			if HasTag(body, "target") and GetTagValue(body, "target")=="" then
				info = "Pick up target"
			end
			if GetBodyVehicle(body) ~= 0 then
				info  = "Drive vehicle"
			end
			local str = GetString("level.interactinfo")
			if str ~= "" then
				info = str
			end
		end
		if info ~= "" then
			UiPush()
				local pos = Vec(GetFloat("game.player.caninteract.x"), GetFloat("game.player.caninteract.y"), GetFloat("game.player.caninteract.z"))
				local x, y, d = UiWorldToPixel(pos)
				if d > 0 then
					UiFont("font/bold.ttf", 24)
					UiAlign("center middle")
					UiTranslate(x, y)
					UiImageBox("common/box-solid-6.png", 34, 34, 6, 6)
					UiColor(0,0,0)
					UiText("E")

					UiFont("font/bold.ttf", 22)
					UiColor(1,1,1)
					UiTranslate(0, 34)
					UiText(info)
				end
			UiPop()
		end
	end
	SetString("level.interactinfo", "")
end


function handleCommand(cmd, arg0, arg1, arg2)
	if cmd == "quicksave" then
		notify("Progress saved", 1.4)
	end
	
	if cmd == "quickload" then
		notify("Progress restored", 1.4)
		titleFade = 0
		titleTimer = 0
	end
end


function drawDemolish()
	if HasKey("level.demolish") then
 		UiPush()
			local pos = Vec(GetFloat("level.demolish.x"), GetFloat("level.demolish.y"), GetFloat("level.demolish.z"))
			local cp = GetCameraTransform().pos
			local dx = pos[1]-cp[1]
			local dz = pos[3]-cp[3]
			local dist = math.sqrt(dx*dx+dz*dz)
			if dist < 25 then
				local h = GetFloat("level.demolish.h")
				local x, y, dist = UiWorldToPixel(pos)
				if dist > 0 then
					UiFont("font/regular.ttf", 20)
					UiTranslate(x, y)
					UiAlign("center middle")
					UiImage("common/dot.png")
					UiTranslate(0, -20)
					UiAlign("center middle")
					UiText(math.ceil(h*10)/10 .. " METERS TOO TALL")
				end
			end
		UiPop()
	end
end


function drawRacing()
	if not gAlarm and gEndScreenScale==0 then
		local state = GetString("level.track.state")
		if state == "race" then
			local timer = math.floor(GetFloat("level.track.timer") * 100) / 100
			gRaceFinishNotification = nil
			UiPush()
				UiTranslate(UiCenter()-40, UiHeight()-80)
				UiFont("ui/font/bold.ttf", 32)
				UiText(timer)
			UiPop()
		end
		if state == "finish" and not gRaceFinishNotification then
			gRaceFinishNotification = true
			local bestTime = math.floor(GetFloat("level.track.best") * 100) / 100
			local lastTime = math.floor(GetFloat("level.track.last") * 100) / 100
			if bestTime == lastTime then
				notify("New record "..bestTime, 2)
			else
				notify("Lap time "..lastTime, 2)
			end
		end
	end
end


function drawCash()
	local currentCash = GetInt("savegame.cash")
	if currentCash > 0 then
		if currentCash > gCashDisplay then
			if gCashScale == 0 then
				SetValue("gCashScale", 1, "easeout", 1)
				gCashCount = 0
			end
			if gCashScale == 1 and gCashCount==0 then
				SetValue("gCashCount", 1, "linear", 1.2)
				UiSound("terminal/cash-counter.ogg")
				gCashFlash = 1
				SetValue("gCashFlash", 0, "easeout", 1.0)
			end
			if gCashCount == 1 then
				gCashDisplay = currentCash
			end
		else
			if gCashScale == 1 then
				SetValue("gCashScale", 0, "easein", 1)
			end
		end
		if not gAlarm and gEndScreenScale==0 and not GetBool("game.player.usescreen") then
			if gHubMode then
				gCashScale = 1
			end
			if gCashScale > 0 then
				UiPush()
					UiTranslate(UiWidth()-180, -50+60*gCashScale)
					UiColor(1,1,1, 0.5+gCashFlash)
					UiImageBox("common/box-solid-10.png", 160, 34, 10, 10)
					UiColor(0,0,0)
					UiTranslate(30, 24)
					UiFont("font/bold.ttf", 22)
					UiText("Cash $" .. math.floor(gCashDisplay + (currentCash-gCashDisplay)*gCashCount))
				UiPop()
			end
		end
	end
end


function getTotalScore()
	local score = 0
	local missions = ListKeys("savegame.mission")
	for i=1,#missions do
		score = score + GetInt("savegame.mission."..missions[i]..".score")
	end
	return score
end


function getRank(score)
	local r = nil
	for i=1,#gRanks do
		if score >= gRanks[i].score then
			r = gRanks[i]
		end
	end
	return r
end


function drawRank()
	if not GetBool("game.player.usescreen") and gScoreCurrent > 0 then
		if gScoreDisplay < gScoreCurrent then
			if gScoreDisplayTimer > 0 then
				gScoreDisplayTimer = gScoreDisplayTimer - GetTimeStep()
				if gScoreDisplayTimer <= 0 then
					gScoreDisplay = gScoreDisplay + 1
					UiSound("common/score-target.ogg")
					if gScoreDisplay == gScoreCurrent then
						SetInt("savegame.hub.score", gScoreCurrent)
					end
					gScoreDisplayTimer = 0.2
				end
			end
		end
		UiPush()
			local r = getRank(gScoreDisplay)
			if r ~= gScoreRank then
				gScoreRank = r
				gScoreRankScale	= 0
				SetValue("gScoreRankScale", 1, "bounce", 0.5)
				gScoreRankTimer = 0
				gScoreRankZoom = 1
				UiSound("hud/new-rank.ogg")
			end
			UiFont("font/bold.ttf", 22)
			local w,h = UiGetTextSize(gScoreRank.name)
			w = w + 130
			h = 34
			UiTranslate(20+w/2, 10+h/2)
			UiColor(1,1,1, 0.5)
			UiAlign("center middle")
			UiImageBox("common/box-solid-10.png", w, h, 10, 10)
			UiWindow(w, h)
			UiAlign("left")
			UiColor(0,0,0)
			UiTranslate(30, 24)
			UiText("Score " .. gScoreDisplay)
			UiTranslate(90, 0)
			UiText(gScoreRank.name)
		UiPop()
		if gScoreRankScale > 0 then
			UiPush()
				local x = 190 * (1-gScoreRankZoom) + UiCenter() * gScoreRankZoom
				local y = 110 * (1-gScoreRankZoom) + UiMiddle() * gScoreRankZoom
				UiTranslate(x, y)
				UiColor(0,0,0, 0.5+gScoreRankZoom*0.5)
				UiAlign("center middle")
				UiScale(1,gScoreRankScale)
				UiScale(1+0.5*gScoreRankZoom)

				UiImageBox("common/box-solid-10.png", 340, 120, 10, 10)
				UiWindow(340, 120)
				UiFont("font/bold.ttf", 22)
				UiTranslate(UiCenter(), 30)
				UiAlign("center middle")
				UiPush()
					UiScale(1.5)
					UiColor(1, 1, .4)
					UiText(gScoreRank.name)
				UiPop()
				UiTranslate(0, 35)
				UiColor(1,1,1)
				UiText("You reached a new rank")
				UiTranslate(0, 22)
				UiColor(.7, .7, .7)
				if gScoreRank.tool then
					UiText("A new tool has been delivered")
				end
				if gScoreRank.cash then
					UiText("A cash reward has been delivered")
				end
			UiPop()
			gScoreRankTimer = gScoreRankTimer + GetTimeStep()
			if gScoreRankTimer > 3 and gScoreRankZoom == 1 then
				SetValue("gScoreRankZoom", 0, "cosine", 0.5)
			end
			local hide = false
			--Hide rank notification when picked up (if tool) or on timer (if cash)
			if gScoreRankTimer > 1 and gScoreRankScale == 1 and not GetBool("level.toolspawn") then
				SetValue("gScoreRankScale", 0, "easein", 0.25)
			end
		end
	end
end


function drawTargets()
	local primary = GetInt("level.primary")
	local primaryTaken = GetInt("level.clearedprimary")
	local secondary = GetInt("level.secondary")
	local secondaryTaken = GetInt("level.clearedsecondary")
	local required = GetInt("level.required")

	local requiredPrimary = primary
	local requiredPrimaryTaken = primaryTaken
	local requiredSecondary = required - primary
	local requiredSecondaryTaken = clamp(secondaryTaken, 0, requiredSecondary)
	local required = requiredPrimary + requiredSecondary
	local requiredTaken = requiredPrimaryTaken + requiredSecondaryTaken
	local optional = secondary - requiredSecondary
	local optionalTaken = clamp(secondaryTaken-requiredSecondary, 0, optional)

	if requiredTaken+optionalTaken > gRequiredTaken+gOptionalTaken then
		SetValue("gTargetInfoScale", 1, "easeout", 0.25)
		if requiredTaken == required and requiredTaken > gRequiredTaken then
			gTargetInfoText = "Mission complete"
		elseif requiredTaken+optionalTaken == required+optional then
			gTargetInfoText = "All targets cleared"
		else
			gTargetInfoText = "Target cleared"
		end
		gTargetInfoTimer = 3.0
	end
	gRequiredTaken = requiredTaken
	gOptionalTaken = optionalTaken

	local show = primaryTaken + secondaryTaken > 0
	if show and not showTargets then
		SetValue("targetFade", 1, "easeout", 0.5)
	elseif not show and showTargets then
		SetValue("targetFade", 0, "easein", 0.5)
	end
	showTargets = show

	local mapFade = GetFloat("game.map.fade")
	local visible = math.max(targetFade, mapFade)

	if visible == 0 or required+optional == 0 then
		return
	end

	UiPush()
		local y = 50
		if optional > 0 then
			y = y + 32
		end
		UiTranslate(20, UiHeight()-y*visible)

		if gTargetInfoScale > 0 then
			UiPush()
				UiFont("font/regular.ttf", 32)
				UiTranslate(10, -18)
				UiScale(1, gTargetInfoScale)
				UiAlign("left middle")
				UiText(gTargetInfoText)
				if gTargetInfoTimer > 0 then
					gTargetInfoTimer = gTargetInfoTimer - GetTimeStep()
					if gTargetInfoTimer <= 0 then
						SetValue("gTargetInfoScale", 0, "easein", 0.25)
					end
				end
			UiPop()
		end

		for i=1, 2 do
			if i == 1 or optional > 0 then
				UiPush()
					local w = 95 + 20
					if i==1 and required > 0 then
						w = w + required * 24
					end
					if i==2 and optional > 0 then
						w = w + optional * 24
					end

					UiColor(0,0,0, 0.35 + 0.65*mapFade)
					UiImageBox("common/box-solid-10.png", w, 30, 10, 10)

					UiPush()
						UiColor(1,1,1)
						UiFont("font/bold.ttf", 22)
						UiTranslate(15, 22)
						if i==1 then
							UiColor(1,1,1)
							UiText("Required")
						else
							UiColor(0.8,0.8,0.8)
							UiText("Optional")
						end
					UiPop()

					UiTranslate(120, 15)
					UiAlign("center middle")

					if i==1 then
						UiColor(1,1,0.5)
						for i=1, primary do
							if i <= primaryTaken then
								UiImage("hud/target-taken.png")
							else
								UiImage("hud/target.png")
							end
							UiTranslate(24, 0)
						end
						UiColor(1,1,1)
						for i=1, requiredSecondary do
							if i <= requiredSecondaryTaken then
								UiImage("hud/target-taken.png")
							else
								UiImage("hud/target.png")
							end
							UiTranslate(24, 0)
						end
					else
						UiColor(0.8,0.8,0.8)
						for i=1, optional do
							if i <= optionalTaken then
								UiImage("hud/target-taken.png")
							else
								UiImage("hud/target.png")
							end
							UiTranslate(24, 0)
						end
					end
				UiPop()
				UiTranslate(0, 32)
			end
		end
	UiPop()
end


function drawHealth()
	local health = GetFloat("game.player.health")
	local show = health < 1
	if show and not showHealth then
		SetValue("healthFade", 1, "easeout", 0.5)
	elseif not show and showHealth then
		SetValue("healthFade", 0, "easein", 0.5)
	end
	showHealth = show

	if healthFade == 0 then
		return
	end

	UiPush()
		UiTranslate(UiWidth() - 144, UiHeight() - 44*healthFade)

		UiColor(0,0,0, 0.5)
		--UiImageBox("common/box-solid-6.png", 180, 30, 6, 6)

		UiPush()
			UiColor(1,1,1)
			UiFont("font/bold.ttf", 24)
			UiTranslate(0, 22)
			if health < 0.1 then
				if math.mod(GetTime(), 1.0) < 0.5 then
					UiColor(1, 0, 0,  1.0)
				else
					UiColor(1, 0, 0,  0.1)
				end
			elseif health < 0.5 then
				UiColor(1, 0, 0)
			end
			UiAlign("right")
			UiText("HEALTH")
		UiPop()

		UiTranslate(10, 4)
		local w = 110
		local h = 20
		UiPush()
			UiAlign("left top")
			UiColor(0, 0, 0, 0.5)
			UiImageBox("common/box-solid-10.png", w, h, 6, 6)
			if health > 0 then
				UiTranslate(2, 2)
				w = (w-4)*health
				if w < 12 then w = 12 end
				h = h-4
				UiColor(1,health*2,health,1)
				UiImageBox("common/box-solid-6.png", w, h, 6, 6)
			end
		UiPop()

	UiPop()
end


function drawListeners()
	if HasKey("level.listener") then
		local list = ListKeys("level.listener")
		for i=1,#list do
			local key = "level.listener."..list[i]
			local name = GetString(key)
			local pos = Vec(GetFloat(key..".x"), GetFloat(key..".y"), GetFloat(key..".z"))
			local volume = GetFloat(key..".volume")
			local warnings = GetFloat(key..".warnings")
			local inRoom = GetBool(key..".inroom")
			local x, y, dist = UiWorldToPixel(pos)

			UiPush()
				local alpha = 1
				if inRoom then
					x = UiCenter()
					y = 60
				else
					local oldX=x
					local oldY=y
					x = clamp(x, 100, 1920-200)
					y = clamp(y, 50, 1080-100)
					local diff = math.max(math.abs(x-oldX), math.abs(y-oldY))
					alpha = clamp(1.0-diff/500, 0.0, 1.0)
					if dist < 0 then
						alpha = 0
					end
					local distToPlayer = VecLength(VecSub(GetPlayerPos(),pos))
					if distToPlayer > 30 then
						local distFade = clamp(1.0-(distToPlayer-30)/10, 0.0, 1.0)
						distFade = math.max(volume, distFade)
						alpha = alpha * distFade
					end
					UiColorFilter(1,1,1,alpha)
				end

				if alpha > 0 then
					UiTranslate(x, y)
					local w = 8
					local h = 10
					local count = 16
					--VU meter
					UiPush()
						UiColor(0,0,0, 0.5)
						local mw = (w+2)*count+2
						UiTranslate(-mw/2)
						UiRect(mw, h+4)
						UiTranslate(2,2)
						for i=1, count do
							local a = 0.2
							if i/count <= volume then a = 1 end
							if i <= count/2 then
								UiColor(0,1,0,a)
							elseif i <= count-2 then
								UiColor(1,1,0,a)
							else
								UiColor(1,0,0,a)
							end
							UiRect(w, h)
							UiTranslate(w+2, 0)
						end
					UiPop()
					UiColor(1,1,1)
					UiFont("font/bold.ttf", 24)
					UiAlign("center")
					UiTranslate(0, -10)
					name = name .. " "
					for i=1, warnings do
						name = name .. "!"
					end
					UiText(name)
				end
			UiPop()
		end
	end
end


function drawProgressbar()
	if HasKey("hud.progressbar") then
		local v = GetFloat("hud.progressbar")
		UiPush()
			UiTranslate(UiCenter()-100, UiHeight()-220)
			progressBar(200, 20, v)
			UiTranslate(100, -10)
			UiAlign("center")
			UiFont("font/bold.ttf", 24)
			UiText(GetString("hud.progressbar.title"))
		UiPop()
		ClearKey("hud.progressbar")
	end
end


function drawHurt()
	UiPush()
		local health = GetFloat("game.player.health")
		if health < 1 then
			local a = (1 - health) * 0.5
			UiColor(1, 0, 0, a)
			UiRect(UiWidth(), UiHeight())
		end
	UiPop()
end


function drawFireMeter()
	if not gAlarm and gEndScreenScale==0 and GetBool("level.firealarm") and not GetBool("level.dispatch") then
		local fireCount = GetFireCount()
		if gFireMeterShown then
			if fireCount == 0 then
				SetValue("gFireMeterScale", 0.0, "easein", 0.5)
				gFireMeterShown = false
			end
		else
			if fireCount > 10 then
				gFireMeterShown = true
				SetValue("gFireMeterScale", 1.0, "easeout", 0.5)
			end
		end
		if gFireMeterScale > 0 then
			UiPush()
				UiAlign("center top")
				UiTranslate(UiCenter(), -70 + 70*gFireMeterScale)
				UiWindow(200, 50)
				UiFont("font/bold.ttf", 24)
				UiTextOutline(0,0,0,1, 0.1)
				UiPush()
					UiTranslate(UiCenter(), 20)
					UiText("FIRE ALERT")
				UiPop()
				UiTranslate(0, 48)
				local t = fireCount/100
				progressBar(200, 20, math.min(t, 1.0))
			UiPop()
		end
	end
end

function tick()
	modloadertick()
	--Start recording when alarm goes off
	if not gAlarm and GetBool("level.alarm") then
		gAlarm = true
		startRecording()
	end

	--Stop recording if play state changes
	if gAlarm and GetString("level.state")~="" then
		stopRecording()
	end

	if gUnlimited then
		local tools = ListKeys("game.tool")
		for i=1,#tools do
			SetInt("game.tool."..tools[i]..".ammo", 99)
		end
	end
end


function flyoverInit(usePath)
	if not flyoverFirst then
		if usePath then
			flyoverHasPath = GetBool("game.path.loaded")
			if flyoverHasPath then
				Command("game.path.load", gMissionId.."-last")
				SetFloat("game.path.alpha", 1)
			end
		end
		flyoverFirst = true
	end

	flyoverUsePath = usePath
	if flyoverUsePath and not flyoverHasPath then
		flyoverUsePath = false
	end

	if flyoverUsePath then
		flyoverPos = 0
		flyoverLength = GetFloat("game.path.length")
	else
		if gState=="fail_dead" then
			flyoverBase = GetPlayerPos()
		else
			flyoverBase = Vec(math.random(-40,40), math.random(0,0), math.random(-40,40))
		end
		local dir = VecNormalize(Vec(math.random(-100, 100), 0.0, math.random(-100, 100)))
		flyoverOffsetStart = VecScale(dir, 30)
		flyoverOffsetEnd = VecAdd(flyoverOffsetStart, Vec(math.random(-10, 10), math.random(-10,10), math.random(-10,10)))
		flyoverPos = 0
		flyoverLength = 8
	end

	flyoverTargetPos = Vec(0,0,0)
	flyoverEyePos = Vec(0,0,0)

	flyoverAngle = math.random()*6.28
	flyoverAngVel = (math.random()-0.5)*0.2

	flyoverPos = 0
	flyoverFrame = 0
end


function flyover()
	if not flyoverFirst or flyoverPos == flyoverLength then
		flyoverInit(gState=="win")
	end

	flyoverPos = math.min(flyoverLength, flyoverPos + GetTimeStep())
	local alpha = 1.0
	if flyoverPos < 1.0 then alpha = flyoverPos end
	if flyoverPos > flyoverLength-1.0 then alpha = flyoverLength-flyoverPos end
	if alpha < 1 then
		UiPush()
		UiColor(0,0,0,1-alpha)
		UiRect(UiWidth(), UiHeight())
		UiPop()
	end

	local target, eye, t
	flyoverAngle = flyoverAngle + GetTimeStep()*flyoverAngVel
	if flyoverUsePath then
		target = Vec(GetFloat("game.path.current.x"), GetFloat("game.path.current.y"), GetFloat("game.path.current.z"))
		eye = VecAdd(target, Vec(math.sin(flyoverAngle)*20, 30, math.cos(flyoverAngle)*20))
		SetFloat("game.path.pos", flyoverPos)
	else
		local t = flyoverPos / flyoverLength
		target = Vec(flyoverBase)
		eye = VecAdd(target, VecScale(flyoverOffsetStart, 1-t))
		eye = VecAdd(eye, VecScale(flyoverOffsetEnd, t))
		eye = VecAdd(eye, Vec(math.sin(flyoverAngle)*0, 30, math.cos(flyoverAngle)*0))
	end
	if flyoverFrame < 2 then
		t = 1.0
	else
		t = 0.02
	end
	flyoverFrame = flyoverFrame + 1
	targetPos = VecAdd(VecScale(targetPos, 1-t), VecScale(target, t))
	eyePos = VecAdd(VecScale(eyePos, 1-t), VecScale(eye, t))
	SetCameraTransform(Transform(eyePos, QuatLookAt(eyePos, targetPos)))
end


function drawEndRun()
	local arrow = FindLocation("endarrow", true)
	local pos = GetLocationTransform(arrow).pos
	local x, y, dist = UiWorldToPixel(pos)
	if dist > 5 and gState=="" then
		UiPush()
		UiTranslate(x, y)
		UiAlign("bottom center")
		UiImage("hud/arrow.png")
		UiPop()
	end
end


function draw()
	if gAboutMode then
		drawAbout()
		return
	end

	UiButtonHoverColor(0.8,0.8,0.8,1)

	modloaderdraw()

	if gEndScreenScale == 0 then
		drawMap(gMissionId)
	end

	local mapFade = GetFloat("game.map.fade")
	if  mapFade > 0 and mapFade < 1 then
		hideNotifications()
	end
	if GetBool("game.map.enabled") then
		if titleTimer > 0.1 then titleTimer = 0.1 end		
	else
		drawDemolish()
	end

	if titleFade > 0 then
		if titleTimer > 0 then
			if VecLength(VecSub(GetPlayerPos(), spawnPos)) > 0.5 and gMissionId ~= "frustrum_chase" then
				titleTimer = 0
			end
			titleTimer = titleTimer - GetTimeStep()
			if titleTimer <= 0 then
				SetValue("titleFade", 0, "easein", 0.3)
			end
		end
		UiPush()
			UiTranslate(0, -(1-titleFade)*140)
			UiColor(0,0,0,0.7*titleFade)
			UiRect(UiWidth(), 140)
			UiFont("font/bold.ttf", 64)
			UiTranslate(UiCenter(), 70)
			UiAlign("center middle")
			UiScale(1.5)
			UiColor(1,1,1, titleFade)
			--UiTextOutline(0, 0, 0, titleFade, 0.2)
			UiText(string.upper(gMissionTitle))
		UiPop()
	end

	if GetBool("hud.hide") then
		SetBool("hud.hide", false)
		return
	end

	if gMissionId == "frustrum_chase" then
		drawEndRun()
	end
	
	local n = GetString("hud.notification") 
	if n~="" then
		notify(n, 4)
		SetString("hud.notification", "")
	end
	
	notifications()

	if not GetBool("game.map.enabled") then
		interactInfo()
	end

	if gState ~= "win" then
		local mapFade = GetFloat("game.map.fade")
		local pathAlpha = GetFloat("game.path.alpha")
		if pathAlpha > mapFade then
			SetFloat("game.path.alpha", mapFade)
		end
	end

	--SetString("level.state", "win")

	if not GetBool("game.map.enabled") and not GetBool("game.paused") and gState=="" then
		UiPush()
			if GetBool("game.player.usevehicle") then
				drawVehicle()
			elseif GetBool("game.player.usescreen") then

			else
				drawTool()
			end
		UiPop()
	end

	if not GetBool("game.player.usescreen") and not GetBool("game.player.usevehicle") and not GetBool("game.map.enabled") and not GetBool("game.paused") and GetString("level.state") == "" then
		crosshair()
	end

	drawPickInfo()

	if endfade < 1.0 then
		drawHurt()
	end

	if gState == "" then
		if not GetBool("game.paused") and not GetBool("game.map.enabled") then
			drawListeners()
			drawProgressbar()
		end
		drawHealth()
		drawTargets()
	end

	drawFireMeter()
	drawRacing()
	if not GetBool("game.map.enabled") then
		drawCash()
		if gHubMode then
			drawRank()
		end
	end
	drawHeist()

	local hintImage = GetString("hud.hintimage")
	if hintImage ~= "" then
		UiPush()
			local imgWidth, imgHeight = UiGetImageSize(hintImage)
			UiAlign("bottom right")
			UiTranslate(UiWidth() - 20, UiHeight() - 60)
			UiImageBox("hud/infobox.png", imgWidth, imgHeight, 7, 7)
			UiImage(hintImage)
		UiPop()
		SetString("hud.hintimage", "")
	end
	local hintInfo = GetString("hud.hintinfo")
	if hintInfo ~= gHintInfo then
		if gHintInfoScale == 1 then
			SetValue("gHintInfoScale", 0, "easein", 0.5)
		end
		if gHintInfoScale == 0 and GetTime() > 5 then
			gHintInfo = hintInfo
			if gHintInfo ~= "" then
				SetValue("gHintInfoScale", 1, "easeout", 0.5)
			end
		end
	end
	if gHintInfo ~= "" then
		UiPush()
			UiFont("font/bold.ttf", 32)
			local w, h = UiGetTextSize(gHintInfo)
			UiTranslate(UiCenter(), -40+gHintInfoScale*80)
			UiAlign("center middle")
			UiColor(0,0,0,0.75)
			UiImageBox("common/box-solid-10.png", w+50, 50, 10, 10)
			UiColor(1,1,1)
			UiText(gHintInfo)
		UiPop()
		SetString("hud.hintinfo", "")
	end

	if gEndScreenScale == 0.0 then
		if GetBool("hud.tooltutorial") then
			toolTutorial()
		else
			pauseMenu()
		end
	end

	if gHubMode and getTotalScore() == 0 and GetTime() < 3 then
		UiPush()
			UiColor(0,0,0)
			UiRect(UiWidth(), UiHeight())
			UiFont("font/bold.ttf", 64)
			UiTranslate(UiCenter(), UiMiddle())
			UiColor(1,1,1)
			UiScale(2)
			UiAlign("center middle")
			UiText("PART ONE")
			SetBool("game.disableinput", true)
		UiPop()
	end
end


function startRecording()
	Command("game.path.record")
end


function stopRecording()
	if GetBool("game.path.recording") then
		Command("game.path.stop")
		Command("game.path.save", gMissionId.."-last")
	end
end

