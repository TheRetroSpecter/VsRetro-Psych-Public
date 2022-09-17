-- Backwards compatability
local trackedTweens = {}
local twni = 0
function setActorX(val, i)
	setPropertyFromGroup("strumLineNotes", i, "x", val)
end
function setActorY(val, i)
	setPropertyFromGroup("strumLineNotes", i, "y", val)
end
function getActorX(i)
	return getPropertyFromGroup("strumLineNotes", i, "x")
end
function getActorY(i)
	return getPropertyFromGroup("strumLineNotes", i, "y")
end
function setActorAngle(val, i)
	setPropertyFromGroup("strumLineNotes", i, "angle", val)
end
function setActorScale(val, i)
	setPropertyFromGroup("strumLineNotes", i, "scale.x", val)
	setPropertyFromGroup("strumLineNotes", i, "scale.y", val)
end
function setActorAlpha(val, i)
	setPropertyFromGroup("strumLineNotes", i, "alpha", val)
end
function getActorAngle(i)
	return getPropertyFromGroup("strumLineNotes", i, "angle")
end
function getActorAlpha(i)
	return getPropertyFromGroup("strumLineNotes", i, "alpha")
end
function tweenPosXAngle(id, x, angle, time, onComplete)
	twni = twni + 1
	noteTweenX("twn"..twni.."strumX"..id, id, x, time)
	noteTweenAngle("twn"..twni.."strumAngle"..id, id, angle, time)

	if onComplete ~= nil then
		table.insert(trackedTweens, 0, {"twn"..twni.."strumX"..id, onComplete, id})
	end
end
function tweenPosX(id, x, time)
	noteTweenX("strumX"..id, id, x, time)
end
function tweenPos(id, x, y, time, onComplete)
	twni = twni + 1
	noteTweenX("twnP"..twni.."strumPX"..id, id, x, time)
	noteTweenY("twnP"..twni.."strumPY"..id, id, y, time)

	if onComplete ~= nil then
		table.insert(trackedTweens, 0, {"twnP"..twni.."strumPX"..id, onComplete, id})
	end
end

function tweenPosWithCentering(id, x, y, time)
	noteTweenX("twnP"..twni.."strumPX"..id, id, x, time)
	noteTweenY("twnP"..twni.."strumPY"..id, id, y, time)
	
	runTimer('centerShit', time)
end
function tweenAngle(id, angle, time)
	noteTweenAngle("strumAngle"..id, id, angle, time)
end
function setHudPosition(x, y)
	setProperty("camHUD.x", x)
	setProperty("camHUD.y", y)
end
function setCamPosition(x, y)
	setProperty("camGame.x", x)
	setProperty("camGame.y", y)
end
function tweenFadeIn(id, alpha, time)
	noteTweenAlpha("strumFade"..id, id, alpha, time, "circIn")
end
function tweenFadeOut(id, alpha, time, onComplete)
	twni = twni + 1
	noteTweenAlpha("twn"..twni.."strumFade"..id, id, alpha, time, "circOut")

	if onComplete ~= nil then
		table.insert(trackedTweens, 0, {"twn"..twni.."strumFade"..id, onComplete, id})
	end
end
function tweenPosXIn(id, x, time)
	noteTweenX("strumXin"..id, id, x, time, "cubeIn")
end
function tweenPosYIn(id, y, time)
	noteTweenY("strumYin"..id, id, y, time, "cubeIn")
end
function tweenAngleIn(id, angle, time)
	noteTweenAngle("strumAnglein"..id, id, angle, time, "cubeIn")
end
function tweenPosXAngleIn(id, x, angle, time)
	noteTweenX("strumXin"..id, id, x, time, "cubeIn")
	noteTweenAngle("strumAnglein"..id, id, angle, time, "cubeIn")
end
function tweenPosYAngleIn(id, y, angle, time)
	noteTweenY("strumYin"..id, id, y, time, "cubeIn")
	noteTweenAngle("strumAnglein"..id, id, angle, time, "cubeIn")
end
function setHudZoom(zoom)
	setProperty("camHUD.zoom", zoom)
end


function onTweenCompleted(tag)
	if #trackedTweens ~= 0 then
		for i = #trackedTweens,1,-1 do
			if trackedTweens[i][1] == tag then
				local trackedTag = table.remove(trackedTweens, i)
				local trackedTagFunc = trackedTag[2]
				--debugPrint("removed callback "..trackedTag[1])
				_G[trackedTagFunc](trackedTag[3])
				return
			end
		end
	end
end

function onTimerCompleted(tag, loops, loopsleft)
	if tag == 'centerShit' then
		ToCenterShit()
	end
end

local opponentAlpha = 1
local shouldSort = false

function onCreate()
	if not modcharts then
		close(true)
		return
	end

	--setProperty("skipArrowStartTween", true)
	setProperty("camZooming", true)

	opponentAlpha = 1
	if middlescroll then
		opponentAlpha = 0.35
	end

	shouldSort = true

	for i=0,7 do
		_G['defaultStrum'..i..'X'] = 0
		_G['defaultStrum'..i..'Y'] = 0
	end

	-- Incase the script loaded after the countdown, normally it would be 0
	if getProperty("startedCountdown") then
		for i=0,3 do
			local ri = i
			_G["defaultOpponentStrumX"..ri] = getPropertyFromGroup("opponentStrums", ri, "x")
			_G["defaultOpponentStrumY"..ri] = getPropertyFromGroup("opponentStrums", ri, "y")
			_G['defaultStrum'..i..'X'] = _G["defaultOpponentStrumX"..ri]
			_G['defaultStrum'..i..'Y'] = _G["defaultOpponentStrumY"..ri]
		end
		for i=4,7 do
			local ri = i-4
			_G["defaultPlayerStrumX"..ri] = getPropertyFromGroup("playerStrums", ri, "x")
			_G["defaultPlayerStrumY"..ri] = getPropertyFromGroup("playerStrums", ri, "y")
			_G['defaultStrum'..i..'X'] = _G["defaultPlayerStrumX"..ri]
			_G['defaultStrum'..i..'Y'] = _G["defaultPlayerStrumY"..ri]
		end
	end
end

function onCountdownStarted()
	for i=0,3 do
		local ri = i
		_G['defaultStrum'..i..'X'] = _G["defaultOpponentStrumX"..ri]
		_G['defaultStrum'..i..'Y'] = _G["defaultOpponentStrumY"..ri]
	end
	for i=4,7 do
		local ri = i-4
		_G['defaultStrum'..i..'X'] = _G["defaultPlayerStrumX"..ri]
		_G['defaultStrum'..i..'Y'] = _G["defaultPlayerStrumY"..ri]
	end

	start()
end

local isDead = false

function onGameOver()
	isDead = true
end

local songPos = 0

function onUpdate(elapsed)
	if isDead then return end
	songPos = getSongPosition()
	update(elapsed)
end
function onBeatHit()
	beatHit(curBeat)
end

-- Actual code

local curStepj = 1
local mainspeed = 0.14
local whichJump = 1
local playerTurn = false
local ignoreturns = true
local doStepper = true
local doEIGHTStepper = false
local stepperlast = true
local tempspeed = 1
local curBumpArrow = 0
local arrowStrength = 40
local camStrength = 20
local defCamx = 0
local defCamy = 0
local camspeed = 0.1
local doOverlap = false
local doLoftyShakes = false
function start(song)
	ToCenterShit()
	--defCamx = getCameraX()
	--defCamy = getCameraY()
end

local didFadeOut = false;

local stepEvents = {
	{126, "Player Turn"},
	{254, "Player Turn"},
	{702, "Player Turn"},
	{1022, "Player Turn"},

	{189, "Opponent Turn"},
	{318, "Opponent Turn"},
	{957, "Opponent Turn"},

	{383, "Disable Stepper"},

	{448, "Lofty On"},
	{576, "Lofty Off"},

	{62, "Ignore Turns Off"},
	{383, "Ignore Turns Off"},
	{831, "Ignore Turns Off"},
	{1086, "Ignore Turns Off"},

	{831, "Disable Eight"},
	{958, "Enable Eight"},
	{1086, "Disable Eight"},

	{580, "Speen BF"},
	{596, "Speen BF"},
	{612, "Speen BF"},
	{628, "Speen BF"},
	{644, "Speen BF"},
	{660, "Speen BF"},
	{676, "Speen BF"},
	{692, "Speen BF"},

	{708, "Speen Retro"},
	{716, "Speen Retro"},
	{724, "Speen Retro"},
	{732, "Speen Retro"},
	{740, "Speen Retro"},
	{748, "Speen Retro"},
	{756, "Speen Retro"},
	{764, "Speen Retro"},
	{766, "Speen Retro"},
	{772, "Speen Retro"},
	{780, "Speen Retro"},
	{788, "Speen Retro"},
	{796, "Speen Retro"},
	{798, "Speen Retro"},
	{804, "Speen Retro"},
	{812, "Speen Retro"},
	{820, "Speen Retro"},
	{828, "Speen Retro"},
	{830, "Speen Retro"}
}

local didStartOverlap = false
local didEndOverlap = false

function update(elapsed)
	if shouldSort then
		table.sort(stepEvents, function(a,b) return a[1] < b[1] end)
		shouldSort = false
	end
	local currentBeat = (songPos / 1000)*(bpm/60)

	while (0 < #stepEvents and curStep >= stepEvents[0+1][0+1]) do
		local event = table.remove(stepEvents, 1)[1+1]
		triggerEvent(event, "", "")
	end

	if not didStartOverlap and curStep >= 448 then -- turns on the funny move back and forth idk
		overlapshit(0.5,currentBeat+1400)
		didStartOverlap = true
	end

	if not didEndOverlap and curStep >= 576 then -- turns OFF the funny move back and forth idk
		doOverlap = false
		didEndOverlap = true
		for i=0,3 do
			tweenFadeIn(i,opponentAlpha,0.2)
		end
		ToCenterTime(0.4)
	end

	if doOverlap and not (curStep >= 576) then -- the funny move back and forth idk
		if middlescroll then
			--for i=0,3 do
			--	setActorX(_G['defaultStrum'..i..'X'] + 300 * math.sin(currentBeat * 0.503) + 350 - 42, i)
			--end
			for i=4,7 do
				setActorX(_G['defaultStrum'..i..'X'] + 300 * math.sin((currentBeat-5.897064980999998) * 0.503), i)
			end
		else
			for i=0,3 do
				setActorX(_G['defaultStrum'..i..'X'] + 300 * math.sin(currentBeat * 0.503) + 350 - 42, i)
			end
			for i=4,7 do
				setActorX(_G['defaultStrum'..i..'X'] - 300 * math.sin(currentBeat * 0.503) - 275 - 42, i)
			end
		end
	end

	if doLoftyShakes then -- does the shakes from vsjim lofty. Basicly was really fitting here And I will copy and paste my own code B)
		loftyShakes(0,false,currentBeat)
		loftyShakes(4,false,currentBeat)
	end

	if not didFadeOut and (curStep >= 1169) then
		for i=0,7 do
			tweenFadeOut(i,0,1)
		end
		didFadeOut = true
	end

	-- camera functions
	--if (curStep == 848) or (curStep == 880) or (curStep == 912) or (curStep == 944) or (curStep == 1096) or (curStep == 1112) or (curStep == 1128) then -- camera go to right
	--	tweenCameraPos(defCamx+camStrength+20,defCamY,camspeed)
	--elseif (curStep == 856) or (curStep == 920) or (curStep == 1104) or (curStep == 1120) or (curStep == 1152) then -- camera zoom out
	--	tweenCameraZoomOut(cameraZoom+0.02, camspeed)
	--elseif (curStep == 1144) then -- camera zoom in 
	--	tweenCameraZoomIn(cameraZoom-0.02, camspeed)
	--elseif (curStep == 888) or (curStep == 952) or (curStep == 1088) or (curStep == 1136) then -- camera go to left
	--	tweenCameraPos(defCamx-camStrength,defCamY,camspeed)
	--elseif (curStep == 864) or (curStep == 896) or (curStep == 928) or (curStep == 960) or (curStep == 1169) then -- camera go to center
	--	tweenCameraPos(defCamx,defCamY,camspeed)
	--	tweenCameraZoom(cameraZoom, camspeed)
	--end
end

function onEvent(name)
	if name == "Speen BF" then
		speen(4) -- spins on da heys
	elseif name == "Speen Retro" then
		speen(0) -- spins on da heys but for retro
	elseif name == "Player Turn" then
		playerTurn = true
	elseif name == "Opponent Turn" then
		playerTurn = false
	elseif name == "Lofty On" then
		doLoftyShakes = true
	elseif name == "Lofty Off" then
		doLoftyShakes = false
	elseif name == "Ignore Turns Off" then
		ignoreturns = false
	elseif name == "Ignore Turns On" then
		ignoreturns = true
	elseif name == "Enable Eight" then
		--debugPrint("The current curStepJ is "..curStepj)
		doEIGHTStepper = true
	elseif name == "Disable Eight" then
		doEIGHTStepper = false
		--curStepj = 0
		ToCenterShitAngleFix()
	elseif name == "Disable Stepper" then
		doStepper = false
		ToCenterShitAngleFix()
	end
end

function beatHit (beat)
	if doStepper then
		stepperthing()
	end
	if doEIGHTStepper then
		stepper2()
	end
end

-- stupid functions

function stepper2() -- basically the same stepper but works is different :>
	curStepj = curStepj+1
	whichJump = whichJump*-1
	if curStepj == 2 then
		nbump()
	elseif curStepj == 1 then
		njump()
	elseif curStepj == 3 then
		njump()
	elseif curStepj == 4 then
		nbump()
		curStepj = 0
	end
end

function stepperthing()
	curStepj = curStepj+1
	whichJump = whichJump*-1
	if curStepj == 2 then
		if ignoreturns == true then
			cross(0)
			cross(4)
		elseif ignoreturns == false and playerTurn == false then
			cross(4)
		elseif ignoreturns == false and playerTurn == true then
			cross(0)
		end
	elseif curStepj == 1 then
		njump()
	elseif curStepj == 3 then
		njump()
	elseif curStepj == 4 then
		njump()
		--stepperlast = true
		curStepj = 0
	end
end

function overlapshit(leTime,funnybeat)
	if middlescroll then
		for i=0,3 do
			--tweenPosX(i,(_G['defaultStrum'..i..'X'] + 300 * math.sin(funnybeat * 0.503) + 350 - 42),leTime)
			tweenFadeOut(i,0.0,leTime)
		end
		--for i=4,7 do
		--	tweenPosX(i,(_G['defaultStrum'..i..'X'] - 300 * math.sin(funnybeat * 0.503)),leTime)
		--end
		doOverlap = true
	else
		for i=0,3 do
			tweenPosX(i,(_G['defaultStrum'..i..'X'] + 300 * math.sin(funnybeat * 0.503) + 350 - 42),leTime)
			tweenFadeOut(i,0.4,leTime, 'finishedOverlapshit')
		end
		for i=4,7 do
			tweenPosX(i,(_G['defaultStrum'..i..'X'] - 300 * math.sin(funnybeat * 0.503) - 275 - 42),leTime)
		end
	end
end

function finishedOverlapshit()
	doOverlap = true
end

function speen(additive)
	for i=0+additive,3+additive do
		tweenPosXAngle(i, _G['defaultStrum'..i..'X'], getActorAngle(i) + 360, 0.2, 'setDefault')
		setActorY(_G['defaultStrum'..i..'Y'], i) --  + 10
	end
end

function nbump()
	if ignoreturns == true then
		automatedBump(0)
		automatedBump(4)
	elseif ignoreturns == false and playerTurn == false then
		automatedBump(4)
	elseif ignoreturns == false and playerTurn == true then
		automatedBump(0)
	end
end

function automatedBump(additive)
	if (curBumpArrow == 0) then
		notebump(additive+curBumpArrow,arrowStrength*-1,true)
	elseif (curBumpArrow == 1) then
		notebump(additive+curBumpArrow,arrowStrength*-1,false)
	elseif (curBumpArrow == 2) then
		notebump(additive+curBumpArrow,arrowStrength,false)
	elseif (curBumpArrow == 3) then
		notebump(additive+curBumpArrow,arrowStrength,true)
	elseif (curBumpArrow == 4) then
		notebump(additive+0,arrowStrength*-1,true)
		curBumpArrow = 0
	end
	curBumpArrow = curBumpArrow+1
end

function notebump(i,strength,leDir)
	if leDir then
		tweenPosWithCentering(i, _G['defaultStrum'..i..'X']+strength, _G['defaultStrum'..i..'Y'], 0.05)
	else
		tweenPosWithCentering(i, _G['defaultStrum'..i..'X'], _G['defaultStrum'..i..'Y']+strength, 0.05)
	end
end

function njump()
	if whichJump == 1 then
		if ignoreturns == true then
			jump(0,true)
			jump(4,false)
		elseif ignoreturns == false and playerTurn == false then
			jump(4,false)
		elseif ignoreturns == false and playerTurn == true then
			jump(0,true)
		end
	elseif whichJump == -1 then
		if ignoreturns == true then
			jump(0,false)
			jump(4,true)
		elseif ignoreturns == false and playerTurn == false then
			jump(4,true)
		elseif ignoreturns == false and playerTurn == true then
			jump(0,false)
		end
	end
end

function jump(additive,mright)
	if stepperlast == true then
		tempspeed = mainspeed
		mainspeed = mainspeed-0.1
	end

	if mright then
		for i=0+additive,1+additive do
			tweenPos(i,_G['defaultStrum'..i..'X']+75,_G['defaultStrum'..i..'Y']-75, mainspeed, 'ToCenterShitAngleFix')
			tweenAngle(i,45,mainspeed)
		end
		for i=2+additive,3+additive do
			tweenPos(i,_G['defaultStrum'..i..'X']-75,_G['defaultStrum'..i..'Y']+75, mainspeed, 'ToCenterShitAngleFix')
			tweenAngle(i,-45,mainspeed)
		end
		
	else
		for i=0+additive,1+additive do
			tweenPos(i,_G['defaultStrum'..i..'X']+75,_G['defaultStrum'..i..'Y']+75, mainspeed, 'ToCenterShitAngleFix')
			tweenAngle(i,-45,mainspeed)
		end
		for i=2+additive,3+additive do
			tweenPos(i,_G['defaultStrum'..i..'X']-75,_G['defaultStrum'..i..'Y']-75, mainspeed, 'ToCenterShitAngleFix')
			tweenAngle(i,45,mainspeed)
		end
	end

	if stepperlast == true then
		mainspeed = tempspeed
		stepperlast = false
	end
end

function cross(additive)
	for i=0+additive,1+additive do
		tweenPos(i,_G['defaultStrum'..i..'X']+115,_G['defaultStrum'..i..'Y'],mainspeed/2)
	end
	for i=2+additive,3+additive do
		tweenPos(i,_G['defaultStrum'..i..'X']-115,_G['defaultStrum'..i..'Y'],mainspeed/2)
	end
end

function loftyShakes(additive,usex,funnybeat)
	local aaaX = 32 * math.sin((funnybeat) * math.pi)
	local aaaY = 10 * math.cos((funnybeat) * math.pi)
	local offY = 0--32
	for i=0+additive,0+additive do
		if usex then
			setActorX(_G['defaultStrum'..i..'X'] + aaaX, i)
		end
		setActorY(_G['defaultStrum'..i..'Y'] + offY - aaaY, i)
	end
	for i=2+additive,2+additive do
		if usex then
			setActorX(_G['defaultStrum'..i..'X'] + aaaX, i)
		end
		setActorY(_G['defaultStrum'..i..'Y'] + offY - aaaY, i)
	end

	for i=1+additive,1+additive do
		if usex then
			setActorX(_G['defaultStrum'..i..'X'] + aaaX, i)
		end
		setActorY(_G['defaultStrum'..i..'Y'] + offY + aaaY, i)
	end
	for i=3+additive,3+additive do
		if usex then
			setActorX(_G['defaultStrum'..i..'X'] + aaaX, i)
		end
		setActorY(_G['defaultStrum'..i..'Y'] + offY + aaaY, i)
	end
end

function ToCenterShitAngleFix()
	for i=0,7 do
		tweenPosXAngleIn(i, _G['defaultStrum'..i..'X'], 0, mainspeed)
		tweenPosYAngleIn(i, _G['defaultStrum'..i..'Y'], 0, mainspeed)
	end
end

function setDefault(id)
	setActorAngle(0,id)
	--_G['defaultStrum'..id..'X'] = getActorX(id)
end

function ToCenterTime(leTime)
	for i=0,7 do
		tweenPosXIn(i, _G['defaultStrum'..i..'X'], leTime)
		tweenPosYIn(i, _G['defaultStrum'..i..'Y'], leTime)
		tweenAngleIn(i, getActorAngle(i), leTime)
	end
end

function ToCenterShit()
	for i=0,7 do
		tweenPosXIn(i, _G['defaultStrum'..i..'X'], mainspeed)
		tweenPosYIn(i, _G['defaultStrum'..i..'Y'], mainspeed)
		tweenAngleIn(i, getActorAngle(i), mainspeed)
	end
end