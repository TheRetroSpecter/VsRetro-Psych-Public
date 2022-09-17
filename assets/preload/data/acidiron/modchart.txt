-- Backwards compatability

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
function tweenPosXAngle(id, x, angle, time)
	noteTweenX("strumX"..id, id, x, time)
	noteTweenAngle("strumAngle"..id, id, angle, time)
end
function tweenPosX(id, x, time)
	noteTweenX("strumX"..id, id, x, time)
end
function tweenPos(id, x, y, time)
	noteTweenX("strumX"..id, id, x, time)
	noteTweenY("strumY"..id, id, y, time)
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
function tweenFadeOut(id, alpha, time)
	noteTweenAlpha("strumFade"..id, id, alpha, time, "circOut")
end
function tweenPosXIn(id, x, time)
	noteTweenX("strumXin"..id, id, x, time, "cubeIn")
end
function tweenPosYIn(id, y, time)
	noteTweenY("strumYin"..id, id, y, time, "cubeIn")
end
function setHudZoom(zoom)
	setProperty("camHUD.zoom", zoom)
end

local opponentAlpha = 1

function onCreate()
	if not modcharts then
		close(true)
		return
	end

	setProperty("skipArrowStartTween", true)
	setProperty("camZooming", true)

	opponentAlpha = 1
	if middlescroll then
		opponentAlpha = 0.35
	end

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
local showOnlyStrums = true
local showP1 = false
local showP2 = false

function onUpdate(elapsed)
	if isDead then return end
	songPos = getSongPosition()
	update(elapsed)
	--setProperty("camHUD.angle", camHudAngle)

	local vis = not showOnlyStrums

	setProperty("healthBarBG.visible", vis)
	setProperty("healthBar.visible", vis)
	setProperty("iconP1.visible", vis)
	setProperty("iconP2.visible", vis)
	setProperty("scoreTxt.visible", vis)
	for i=0,3 do
		local ri = i
		setPropertyFromGroup("opponentStrums", ri, "visible", showP2)
		if not showP2 then
			setPropertyFromGroup("opponentStrums", ri, "alpha", 0)
		end
	end
	for i=4,7 do
		local ri = i-4
		setPropertyFromGroup("playerStrums", ri, "visible", showP1)
		if not showP1 then
			setPropertyFromGroup("playerStrums", ri, "alpha", 0)
		end
	end
end
function onBeatHit()
	beatHit(curBeat)
end
function onStepHit()
	stepHit(curStep)
end

-- Actual code

local defzoom = 0
local exzoom = 0.1
local intro = true
local whitsle = false
local curArr = 0
local shakeMagnifier = 4
local arrowBeatposes = {}
local arrowbeatTime = 0.15

local bumpTimes = {
	404, 412, 420, 428, 436, 444,
	452, 460, 468, 476, 484, 492,
	500, 504, 508, 512, 514, 516,
	517, 518, 519, 520, 524, 532,
	540, 548, 556, 564, 572, 580,
	588, 596, 604, 612, 620, 628,
	636, 644, 652, 660, 668, 676,
	684, 692, 700, 708, 716, 724,
	732, 740, 748, 756, 760, 764,
	768, 770, 772, 773, 774, 775,
	776
}

local stepEvents = {
	{1288, "Lofty On"},
	{1544, "Lofty Off"},
	{1797, "Middle"},
	{1925, "Default Strums"},
	{2056, "Lofty On"},
	{2312, "Lofty Off"}
}

local doLoftyShakes = false
local tenseSpeed = 0.5
local mainspeed = 0.14

function start()
	ToCenterShit()
	showOnlyStrums = true
	for i=0,7 do
		setActorAlpha(0,i)
	end
	defzoom = getProperty("camHUD.zoom")
	genArrowposes(0)
	genArrowposes(4)
	--setHudPosition(getHudX()+50,getHudY())
	--setHudZoom(defzoom+exzoom)
end

local startedWhistle = false
local endedWhistle = false

function update(elapsed)
	local currentBeat = (songPos / 1000)*(bpm/60)
	--if intro == true then
	--	setHudZoom(defzoom+exzoom)
	--end

	if not showP2 and (curStep >= 120) then -- fade in retros notes
		showP2 = true
		for i=0,3 do
			tweenFadeIn(i,1,0.5)
		end
	end

	if not showP1 and (curStep >= 245) then -- fade in bfs notes
		showP1 = true
		for i=0,3 do
			tweenFadeIn(i,opponentAlpha,0.5)
		end
		for i=4,7 do
			tweenFadeIn(i,1,0.5)
		end
	end

	if not startedWhistle and (curStep >= 375) then -- whitsle thing
		whitsle = true
		startedWhistle = true
	end
	
	if not endedWhistle and (curStep >= 391) then
		arrowpo(1)
		setHudZoom(defzoom+exzoom)
		endedWhistle = true
		whitsle = false
		intro = false
		--setHudPosition(defProp[0],defProp[1])
		showOnlyStrums = false
	end

	while (0 < #bumpTimes and curStep >= bumpTimes[0+1]) do
		local event = table.remove(bumpTimes, 1)
		amogus(0)
		amogus(4)
		arrowbeatTime = 0.001
	end

	if whitsle then
		whitslething() -- it's a mess
	end

	--if (curStep == 776) then -- turn on arrow camera thingy i guess :/
	--	followchars = true
	--end

	--if (curStep == 1031) then -- turn off arrow camera thingy i guess :/
	--	followchars = false
	--end

	while (0 < #stepEvents and curStep >= stepEvents[0+1][0+1]) do
		local event = table.remove(stepEvents, 1)[1+1]
		triggerEvent(event, "", "")
	end

	--if (curStep == 1288) or (curStep == 2056) then -- reused lofty shakes lmfao
	--	doLoftyShakes = true
	--end

	--if (curStep == 1544) or (curStep == 2312) then -- turns off lofty shakes
	--	doLoftyShakes = false
	--	ToCenterShit()
	--end

	--if (curStep == 1544) then
	--	followchars = true
	--end
	
	if doLoftyShakes then -- does the shakes from vsjim lofty. Basicly was really fitting here And I will copy and paste my own code B)
		loftyShakes(0,true,currentBeat)
		loftyShakes(4,true,currentBeat)
	end

	--if not didBruh and (curStep >= 1797) then -- SPINSS IN MIDDLE SCROLL THINGGGG
	--	
	--	didBruh = true
	--end

	--if not didRetBruh and (curStep >= 1925) then -- SPINSS out of the MIDDLE SCROLL THINGGGG
	--	Returnbruh()
	--	didRetBruh = true
	--end

	--if (curStep == 1800) then -- turns off camera thingy 
	--	followchars = false
	--end
end

function onEvent(name)
	if name == "Lofty On" then
		doLoftyShakes = true
	elseif name == "Lofty Off" then
		doLoftyShakes = false
		ToCenterShit()
	elseif name == "Middle" then
		bruh()
	elseif name == "Default Strums" then
		Returnbruh()
	end
end

function stepHit (step)
	if not (arrowbeatTime > 0.15) then
		arrowbeatTime = arrowbeatTime+0.05
	end
end

function beatHit (beat)
end

--stupid functions

function bruh()
	if middlescroll then
		for i=0,3 do
			tweenFadeOut(i, -40, 8)
		end
	else
		for i=0,3 do
			tweenPosXAngle(i, _G['defaultStrum'..i..'X'] - 275, getActorAngle(i) + 360, tenseSpeed)
			tweenFadeOut(i, -40, 8)
		end
		for i=4,7 do
			tweenPosXAngle(i, _G['defaultStrum'..i..'X'] - 275 - 42, getActorAngle(i) + 360, tenseSpeed)
		end
	end
end

function Returnbruh()
	if middlescroll then
		for i=0,3 do
			--tweenFadeIn(i,255,8)
			tweenFadeIn(i,opponentAlpha,0.6)
		end
	else
		for i=0,3 do
			tweenPosXAngle(i, _G['defaultStrum'..i..'X'], getActorAngle(i) - 360, tenseSpeed)
			--tweenFadeIn(i,255,8)
			tweenFadeIn(i,opponentAlpha,0.6)
		end
		for i=4,7 do
			tweenPosXAngle(i, _G['defaultStrum'..i..'X'], getActorAngle(i) - 360, tenseSpeed)
		end
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

function genArrowposes(additive)
	arrowBeatposes[0+additive] = -50
	arrowBeatposes[1+additive] = -25
	arrowBeatposes[2+additive] = 25
	arrowBeatposes[3+additive] = 50
end

function amogus(additive)
	for i=0+additive,3+additive do
		setActorX(_G['defaultStrum'..i..'X'] + arrowBeatposes[i], i)
		tweenPosX(i, _G['defaultStrum'..i..'X'], arrowbeatTime)
	end
end

function whitslething()
	curArr = curArr+1
	if (curArr == 1) then
		arrowpo(1)
	elseif (curArr == 2) then
		arrowpo(2)
	elseif (curArr == 3) then
		arrowpo(-2)
	elseif (curArr == 4) then
		arrowpo(1)
	elseif (curArr == 5) then
		arrowpo(-1)
	elseif (curArr == 6) then
		arrowpo(1)
	elseif (curArr == 7) then
		arrowpo(-2)
	elseif (curArr == 8) then
		arrowpo(1)
	elseif (curArr == 9) then
		arrowpo(2)
	elseif (curArr == 10) then
		arrowpo(-2)
	elseif (curArr == 11) then
		arrowpo(1)
	elseif (curArr == 12) then
		arrowpo(-1)
	elseif (curArr == 13) then
		arrowpo(-1)
	elseif (curArr == 14) then
		arrowpo(1)
	elseif (curArr == 15) then
		arrowpo(-2)
		curArr = 0
	end
end

function arrowpo(leAdd)
	for i=0,7 do
		setActorX(_G['defaultStrum'..i..'X'] + leAdd*shakeMagnifier, i)
		setActorY(_G['defaultStrum'..i..'Y'] + (leAdd*-1)*shakeMagnifier, i)
	end
end

function setDefault(id)
	setActorAngle(0,id)
	_G['defaultStrum'..id..'X'] = getActorX(id)
end

function ToCenterShit()
	for i=0,7 do
		tweenPosXIn(i, _G['defaultStrum'..i..'X'], mainspeed)
		tweenPosYIn(i, _G['defaultStrum'..i..'Y'], mainspeed)
	end
end