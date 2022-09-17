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
function tweenFadeOut(id, alpha, time)
	noteTweenAlpha("strumFade"..id, id, alpha, time, "circOut")
end

function onCreate()
	if not modcharts then
		close(true)
		return
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
end

local isDead = false

function onGameOver()
	isDead = true
end

local camHudAngle = 0
local songPos = 0

function onUpdate(elapsed)
	if isDead then return end
	songPos = getSongPosition()
	update(elapsed)
	setProperty("camHUD.angle", camHudAngle)
end
function onBeatHit()
	beatHit(curBeat)
end
function onStepHit()
	stepHit(curStep)
end

-- Actual code

function start (song)
end

function update (elapsed)
	local currentBeat = (songPos / 1000)*(bpm/60)

	if shakehorizontal then
		setHudPosition(6 * math.sin((currentBeat * 10) * math.pi), 0)
		setCamPosition(6 * math.sin((currentBeat * 10) * math.pi),0)
	end

	if shakehorizontalweak then
		setHudPosition(3 * math.sin((currentBeat * 10) * math.pi),0)
		setCamPosition(3 * math.sin((currentBeat * 10) * math.pi),0)
	end

	if shakenotep1 then
		for i=0,3 do
			setActorX(_G['defaultStrum'..i..'X'] + 3 * math.sin((currentBeat * 10 + i*0.25) * math.pi), i)
			setActorY(_G['defaultStrum'..i..'Y'] + 3 * math.cos((currentBeat * 10 + i*0.25) * math.pi), i) --  + 10
		end
	end
	if shakenotep2 then
		for i=4,7 do
			setActorX(_G['defaultStrum'..i..'X'] + 3 * math.sin((currentBeat * 10 + i*0.25) * math.pi), i)
			setActorY(_G['defaultStrum'..i..'Y'] + 3 * math.cos((currentBeat * 10 + i*0.25) * math.pi), i) --  + 10
		end
	end

	if crazy then
		if middlescroll then
			for i=4,7 do
				setActorX(_G['defaultStrum'..i..'X'] + 256 * math.sin((currentBeat + 8.6990817) / 5), i)
				setActorY(_G['defaultStrum'..i..'Y'] - 50 * math.cos(currentBeat),i) --  + 10
			end
		else
			for i=0,3 do
				setActorX(_G['defaultStrum'..i..'X'] - 256 * math.sin(currentBeat / 5) + 275, i)
				setActorY(_G['defaultStrum'..i..'Y'] - 50 * math.cos(currentBeat),i) --  + 10
			end
			for i=4,7 do
				setActorX(_G['defaultStrum'..i..'X'] + 256 * math.sin(currentBeat / 5) - 275, i)
				setActorY(_G['defaultStrum'..i..'Y'] - 50 * math.cos(currentBeat),i) --  + 10
			end
		end
	end

	if shakehud then
		for i=0,7 do
			setHudPosition(20 * math.sin((currentBeat * 10) * math.pi), 20 * math.cos((currentBeat * 10) * math.pi))
			setCamPosition(-20 * math.sin((currentBeat * 10) * math.pi), -20 * math.cos((currentBeat * 10) * math.pi))
		end
	end

	if sway then
		camHudAngle = 3 * math.sin(currentBeat)
	end

end

function beatHit (beat)
end

function stepHit (step)

	-- Separate these by ranges instead of on certain steps
	-- This is so that when steps are missed from lag, the effect still goes through

	-- Shake hud timings
	if not shakeHud and ((step >= 128 and step < 132) or (step >= 1024 and step < 1028)) then
		shakeHud = true
	elseif shakeHud and ((step < 128) or (step >= 132 and step < 1024) or (step >= 1028)) then
		shakeHud = false
	end

	-- Shake note timings
	if (not shakenotep1 or not shakenotep2) and ((step >= 128 and step < 640) or (step >= 1024 and step < 1528)) then
		shakenotep1 = true
		shakenotep2 = true
	elseif (shakenotep1 or shakenotep2) and ((step < 128) or (step >= 640 and step < 1024) or (step >= 1528)) then
		shakenotep1 = false
		shakenotep2 = false
	end

	-- Shake horizontal timings
	if not shakeHorizontal and (step >= 640 and step < 768) then
		shakeHorizontal = true
	elseif shakeHorizontal and (step < 640 or step >= 768) then
		shakeHorizontal = false
	end

	-- Shake horizontal weak timings
	if not shakeHorizontalweak and (step >= 768 and step < 1024) then
		shakeHorizontalweak = true
	elseif shakeHorizontalweak and (step < 768 or step >= 1024) then
		shakeHorizontalweak = false
	end

	-- Sway timings
	if not sway and (step >= 1536 and step < 1856) then
		sway = true
	elseif sway and (step < 1536 or step >= 1856) then
		sway = false
	end

	-- Crazy timings
	if not crazy and (step >= 1536 and step < 1856) then
		crazy = true

		if middlescroll then
			for i=0,3 do
				tweenFadeOut(i, 0, 0.4)
			end
		end

	elseif crazy and (step < 1536 or step >= 1856) then
		crazy = false

		if middlescroll then
			for i=0,3 do
				tweenFadeOut(i, 0.35, 0.4)
			end
		end
	end

	-- Prevent notes from not being faded
	for i=0,3 do
		if step > 1528 and getActorAlpha(i) == 1 then
			setActorAlpha(0.1, i)
		end
	end

	-- Prevent reset not going off
	if camHudAngle ~= 0 and step > 1857 then
		resetButtonPositions()
	end

	if step == 132 then
		--shakehud = false
		setCamPosition(0,0)
		setHudPosition(0,0)
	end
	if step == 1028 then
		--shakehud = false
		setCamPosition(0,0)
		setHudPosition(0,0)
	end
	if step == 1528 then
		--shakenotep1 = false
		--shakenotep2 = false
		for i=0,3 do
			tweenFadeOut(i,0.1,0.6)
		end
	end

	if step == 1857 then
		resetButtonPositions()
	end
end

function resetButtonPositions()
	for i=0,7 do
		setActorX(_G['defaultStrum'..i..'X'] + 3 * math.sin((i*0.25) * math.pi), i);
		setActorY(_G['defaultStrum'..i..'Y'], i); --  + 50
	end

	-- Also reset camera
	camHudAngle = 0
end