-- Backwards compatability

function setActorX(val, i)
	setPropertyFromGroup("strumLineNotes", i, "x", val)
end
function setActorY(val, i)
	setPropertyFromGroup("strumLineNotes", i, "y", val)
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
function tweenPos(id, x, y, time, onComplete)
	noteTweenX("strumX"..id, id, x, time)
	noteTweenY("strumY"..id, id, y, time)

	--if onComplete ~= nil then
	--	trackedTag = "strumY"..id
	--	trackedTagFunc = onComplete
	--	trackedTagParam = id
	--end
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

--local trackedTag = ""
--local trackedTagFunc = ""
--local trackedTagParam = 0
--function onTweenCompleted(tag)
--	if tag == trackedTag then
--		if trackedTagFunc ~= "" then
--			_G[trackedTagFunc]()
--			trackedTag = ""
--		end
--	end
--end

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

	onSongStart()
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
function onStepHit()
	stepHit(curStep)
end

-- Actual code

function laugh(id)
	if (laughState == 0) then
		laughState = 1
		tweenAngle(0, 25, 0.1)
		tweenAngle(3, -25, 0.1)
		--tweenPos(0, _G['defaultStrum0X'] + 40, _G['defaultStrum0Y'] + 40, 0.1)
		tweenPos(1, _G['defaultStrum1X'], _G['defaultStrum1Y'] + 25, 0.1)
		tweenPos(2, _G['defaultStrum2X'], _G['defaultStrum2Y'] + 25, 0.1)
		--tweenPos(2, _G['defaultStrum2X'], _G['defaultStrum2Y'] + 25, 0.1, 'laugh')
		--tweenPos(3, _G['defaultStrum3X'] - 40, _G['defaultStrum3Y'] + 40, 0.1)
	elseif (laughState == 1) then
		laughState = 2
		tweenPos(0, _G['defaultStrum0X'], _G['defaultStrum0Y'] + 5, 0.05)
		tweenPos(1, _G['defaultStrum1X'], _G['defaultStrum1Y'] + 30, 0.05)
		tweenPos(2, _G['defaultStrum2X'], _G['defaultStrum2Y'] + 30, 0.05)
		tweenPos(3, _G['defaultStrum3X'], _G['defaultStrum3Y'] + 5, 0.05, 'laugh')
	elseif (laughState == 2) then
		laughState = 3
		tweenPos(0, _G['defaultStrum0X'], _G['defaultStrum0Y'], 0.05)
		tweenPos(1, _G['defaultStrum1X'], _G['defaultStrum1Y'] + 25, 0.05)
		tweenPos(2, _G['defaultStrum2X'], _G['defaultStrum2Y'] + 25, 0.05)
		tweenPos(3, _G['defaultStrum3X'], _G['defaultStrum3Y'], 0.05, 'laugh')
	elseif (laughState == 3) then
		laughState = 4
		tweenPos(0, _G['defaultStrum0X'], _G['defaultStrum0Y'] + 5, 0.05)
		tweenPos(1, _G['defaultStrum1X'], _G['defaultStrum1Y'] + 30, 0.05)
		tweenPos(2, _G['defaultStrum2X'], _G['defaultStrum2Y'] + 30, 0.05)
		tweenPos(3, _G['defaultStrum3X'], _G['defaultStrum3Y'] + 5, 0.05, 'laugh')
	elseif (laughState == 4) then
		laughState = 5
		tweenPos(0, _G['defaultStrum0X'], _G['defaultStrum0Y'], 0.05)
		tweenPos(1, _G['defaultStrum1X'], _G['defaultStrum1Y'] + 25, 0.05)
		tweenPos(2, _G['defaultStrum2X'], _G['defaultStrum2Y'] + 25, 0.05)
		tweenPos(3, _G['defaultStrum3X'], _G['defaultStrum3Y'], 0.05, 'laugh')
	elseif (laughState == 5) then
		laughState = 6
		tweenPos(0, _G['defaultStrum0X'], _G['defaultStrum0Y'] + 5, 0.05)
		tweenPos(1, _G['defaultStrum1X'], _G['defaultStrum1Y'] + 30, 0.05)
		tweenPos(2, _G['defaultStrum2X'], _G['defaultStrum2Y'] + 30, 0.05)
		tweenPos(3, _G['defaultStrum3X'], _G['defaultStrum3Y'] + 5, 0.05, 'laugh')
	elseif (laughState == 6) then
		laughState = 7
		tweenPos(0, _G['defaultStrum0X'], _G['defaultStrum0Y'], 0.05)
		tweenPos(1, _G['defaultStrum1X'], _G['defaultStrum1Y'] + 25, 0.05)
		tweenPos(2, _G['defaultStrum2X'], _G['defaultStrum2Y'] + 25, 0.05)
		tweenPos(3, _G['defaultStrum3X'], _G['defaultStrum3Y'], 0.05, 'laugh')
	elseif (laughState == 7) then
		laughState = 8
		tweenPos(0, _G['defaultStrum0X'], _G['defaultStrum0Y'] + 5, 0.05)
		tweenPos(1, _G['defaultStrum1X'], _G['defaultStrum1Y'] + 30, 0.05)
		tweenPos(2, _G['defaultStrum2X'], _G['defaultStrum2Y'] + 30, 0.05)
		tweenPos(3, _G['defaultStrum3X'], _G['defaultStrum3Y'] + 5, 0.05, 'laugh')
	elseif (laughState == 8) then
		laughState = 0
		tweenPos(0, _G['defaultStrum0X'], _G['defaultStrum0Y'], 0.05)
		tweenPos(1, _G['defaultStrum1X'], _G['defaultStrum1Y'] + 25, 0.05)
		tweenPos(2, _G['defaultStrum2X'], _G['defaultStrum2Y'] + 25, 0.05)
		tweenPos(3, _G['defaultStrum3X'], _G['defaultStrum3Y'], 0.05)
	end
end

function reset()
	for i = 0,3 do
		tweenAngle(i, 0, 0.1)
		tweenPos(i, _G['defaultStrum'..i..'X'], _G['defaultStrum'..i..'Y'], 0.1)
	end
end

function resetPlayer()
	for i = 4,7 do
		--tweenAngle(i, 0, 0.1)
		tweenPos(i, _G['defaultStrum'..i..'X'], _G['defaultStrum'..i..'Y'], 0.1)
	end
end

function onSongStart (song)
	for i=0,7 do
		setActorAlpha(0, i)
	end

	laughState = 0
	actorScale = 0.7
	closeInDistance = 0
	middlePoint = ((_G['defaultStrum7X'] - _G['defaultStrum0X']) / 2) - 42 - 50-- - 150
	if middlescroll then
		middlePoint = ((_G['defaultStrum3X'] - _G['defaultStrum0X']) / 2) - 42 - 50-- - 150
	end
end

function update (elapsed)
	if (p1fly) then
		for i=0,3 do
			setActorX(_G['defaultStrum'..i..'X'] + 50 * math.sin((songPos / 1000) * math.pi), i)
			setActorY(_G['defaultStrum'..i..'Y'] + 30 * math.sin((songPos / 1000) * 2 * math.pi), i)
		end
	end

	if (p2fly) then
		for i=4,7 do
			setActorY(_G['defaultStrum'..i..'Y'] + -30 * math.sin((songPos / 1000) * 2 * math.pi), i)
		end
	end

	if (flyTogether) then
		for i=0,3 do
			setActorX(middlePoint + (i * 125) + (250 * math.sin((songPos / 1000) * math.pi)), i)
			setActorY(_G['defaultStrum'..i..'Y'] + 50 * math.sin((songPos / 1000) * 2 * math.pi), i)
		end
		for i=4,7 do
			setActorX(middlePoint + ((i - 4) * 125) + (250 * math.sin((-songPos / 1000) * math.pi)), i)
			setActorY(_G['defaultStrum'..i..'Y'] + 30 * math.sin((-songPos / 1000) * 2 * math.pi), i)
		end
	end

	-- Pulse effect
	if (p2HalfPulse or p2Pulse or p2FastPulse) then
		if (actorScale > 0.7) then
			actorScale = actorScale - elapsed
		end
		for i=0,3 do
			setActorScale(actorScale, i)
		end
	end

	if (p1HalfPulse or p1Pulse or p1FastPulse) then
		if (actorScale > 0.7) then
			actorScale = actorScale - elapsed
		end
		for i=4,7 do
			setActorScale(actorScale, i)
		end
	end

	-- Close in effect
	if (closeIn) then
		if not middlescroll then
			closeInDistance = closeInDistance + (2.75 * elapsed)
		end
		for i=0,3 do
			setActorX(_G['defaultStrum'..i..'X'] + closeInDistance, i)
		end
		for i=4,7 do
			setActorX(_G['defaultStrum'..i..'X'] - closeInDistance, i)
		end
	end
end

local s1fadein = false
local s2fadein = false
local s3fadein = false
local s4fadein = false

function beatHit (beat)
	-- Effect checks
	if not(s1fadein) and (beat >= 16) then
		if (getActorAlpha(0) == 0) then
			tweenFadeIn(0, opponentAlpha, 1)
		end
		if (getActorAlpha(7) == 0) then
			tweenFadeIn(7, 1, 1)
		end
		s1fadein = true
	end
	if not(s2fadein) and (beat >= 20) then
		if (getActorAlpha(1) == 0) then
			tweenFadeIn(1, opponentAlpha, 1)
		end
		if (getActorAlpha(6) == 0) then
			tweenFadeIn(6, 1, 1)
		end
		s2fadein = true
	end
	if not(s3fadein) and (beat >= 24) then
		if (getActorAlpha(2) == 0) then
			tweenFadeIn(2, opponentAlpha, 1)
		end
		if (getActorAlpha(5) == 0) then
			tweenFadeIn(5, 1, 1)
		end
		s3fadein = true
	end
	if not(s4fadein) and (beat >= 28) then
		if (getActorAlpha(3) == 0) then
			tweenFadeIn(3, opponentAlpha, 1)
		end
		if (getActorAlpha(4) == 0) then
			tweenFadeIn(4, 1, 1)
		end
		s4fadein = true
	end
	if (beat == 62) then -- Can't really prevent missing this. This sucks
		laugh(-1)
	elseif (beat >= 64 and beat < 128 and not p1fly) then
		reset()
		p1fly = true
	elseif (beat >= 192 and beat < 254 and not closeIn) then
		closeIn = true
		p2fly = true
	elseif (beat >= 224 and beat < 254 and not p1FastPulse) then
		p1Pulse = false
		p2Pulse = false
		p1FastPulse = true
		p2FastPulse = true
	elseif (beat >= 254 and beat < 256 and closeIn) then
		laugh(-1)
		closeIn = false
		p1fly = false
		p2fly = false
		p1FastPulse = false
		p2FastPulse = false
	elseif (beat >= 256 and beat < 288 and not flyTogether) then
		for i=0,3 do
			tweenFadeOut(i, 0.3, 0.4)
		end
		flyTogether = true
		p1Pulse = true
		p2Pulse = true
	elseif (beat >= 288 and flyTogether) then
		flyTogether = false
		for i=0,3 do
			tweenFadeIn(i, opponentAlpha, 0.4)
		end
		for i=0,7 do
			tweenPos(i, middlePoint + ((i % 4) * 125), _G['defaultStrum'..i..'Y'], 2)
		end
	end

	-- Pulse checks
	if (beat >= 64 and not p2HalfPulse and not p2Pulse) then
		p2HalfPulse = true
	elseif (beat >= 128 and not p2Pulse) then
		p2HalfPulse = false
		p2Pulse = true
	end

	if (beat >= 128 and not p1HalfPulse and not p1Pulse) then
		p1HalfPulse = true
	elseif (beat >= 192 and not p1Pulse) then
		p1HalfPulse = false
		p1Pulse = true
	end

	-- Pulsing effect
	if (p2HalfPulse and beat % 2 == 0) then
		actorScale = 0.85
		--triggerEvent("Add Camera Zoom", 0.03, 0.04)
		for i=0,3 do
			setActorScale(0.85, i)
		end
	elseif (p2Pulse) then
		actorScale = 0.85
		
		for i=0,3 do
			setActorScale(0.85, i)
		end
	end

	if (p1HalfPulse and beat % 2 == 0) then
		actorScale = 0.85
		for i=4,7 do
			setActorScale(0.85, i)
		end
	elseif (p1Pulse) then
		actorScale = 0.85
		if beat < 292 then
			triggerEvent("Add Camera Zoom", 0.03, 0.04)
		end
		for i=4,7 do
			setActorScale(0.85, i)
		end
	end
end

local didReset = false

function stepHit (step)
	if (curStep >= 1022) and not didReset then
		reset()
		for i=0,3 do
			tweenPosXAngle(i, middlePoint + (i * 125), 360, 0.25)
		end
		for i=4, 7 do
			tweenPosXAngle(i, middlePoint + ((i - 4) * 125), -360, 0.25)
		end

		didReset = true
	end

	-- Pulsing effect
	if (p2FastPulse and curStep % 2 == 0) then
		actorScale = 0.85
		for i=0,3 do
			setActorScale(0.85, i)
		end
	end

	if (p1FastPulse and curStep % 2 == 0) then
		actorScale = 0.85
		for i=4,7 do
			setActorScale(0.85, i)
		end
	end
end