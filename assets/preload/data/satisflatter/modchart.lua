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
function tweenPosX(id, x, time)
	noteTweenX("strumX"..id, id, x, time)
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
local showOnlyStrums = false

function onUpdate(elapsed)
	if isDead then return end
	songPos = getSongPosition()
	update(elapsed)
	setProperty("camHUD.angle", camHudAngle)

	local vis = not showOnlyStrums

	setProperty("healthBarBG.visible", vis)
	setProperty("healthBar.visible", vis)
	setProperty("iconP1.visible", vis)
	setProperty("iconP2.visible", vis)
	setProperty("scoreTxt.visible", vis)
end
function onBeatHit()
	beatHit(curBeat)
end
function onStepHit()
	stepHit(curStep)
end

-- Actual code

local sway = false
local quickdraw = false
local quickdraw2 = false
local quickdraw3 = false
local quickdraw4 = false
local crisscross = false
local crisscross2 = false
local speedy = false
local fadingCrissCross = false

function start (song)
end

function update (elapsed)
	local currentBeat = (songPos / 1000)*(bpm/60)

	if sway then
		camHudAngle = 5 * math.sin(currentBeat * 0.504)
	end

	if quickdraw then
		for i=0,7 do
			setActorX(_G['defaultStrum'..i..'X'] + 32 * math.sin((currentBeat + i*2) * math.pi), i)
			setActorY(_G['defaultStrum'..i..'Y'], i)
		end
	end

	if quickdraw2 then
		for i=0,7 do
			setActorX(_G['defaultStrum'..i..'X'], i)
			setActorY(_G['defaultStrum'..i..'Y'] + 16 * math.sin((currentBeat + i*2) * math.pi), i)
		end
	end

	if quickdraw3 then
		for i=0,3 do
			local oi = (i+4) % 8
			--setActorX(_G['defaultStrum'..i..'X'] + 32 * math.sin((currentBeat + i*2) * math.pi) + 700 - 42 - 42, i)
			setActorX(_G['defaultStrum'..oi..'X'] + 32 * math.sin((currentBeat + i*2) * math.pi), i)
			setActorY(_G['defaultStrum'..i..'Y'], i)
		end
		for i=4,7 do
			local oi = (i+4) % 8
			--setActorX(_G['defaultStrum'..i..'X'] + 32 * math.sin((currentBeat + i*2) * math.pi) - 550 - 42 - 42, i)
			setActorX(_G['defaultStrum'..oi..'X'] + 32 * math.sin((currentBeat + i*2) * math.pi), i)
			setActorY(_G['defaultStrum'..i..'Y'], i)
		end
	end

	if quickdraw4 then
		for i=0,3 do
			local oi = (i+4) % 8
			--setActorX(_G['defaultStrum'..i..'X'] + 700 - 42 - 42, i)
			setActorX(_G['defaultStrum'..oi..'X'], i)
			setActorY(_G['defaultStrum'..i..'Y'], i)
		end
		for i=4,7 do
			local oi = (i+4) % 8
			--setActorX(_G['defaultStrum'..i..'X'] - 550 - 42 - 42, i)
			setActorX(_G['defaultStrum'..oi..'X'], i)
			setActorY(_G['defaultStrum'..i..'Y'] + 16 * math.sin((currentBeat + i) * math.pi), i)
		end
	end

	if crisscross then
		if middlescroll then
			for i=4,7 do
				setActorX(_G['defaultStrum'..i..'X'] - 300 * math.sin((currentBeat+2.38848706) * 0.503), i)
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

	if crisscross2 then
		if middlescroll then
			for i=4,7 do
				setActorX(_G['defaultStrum'..i..'X'] - 300 * math.sin((currentBeat+3.9328377421) * 0.504), i)
				setActorY(_G['defaultStrum'..i..'Y'] + 16 * math.cos((currentBeat + i*5) * math.pi), i)
			end
		else
			for i=0,3 do
				setActorX(_G['defaultStrum'..i..'X'] + 300 * math.sin(currentBeat * 0.504) + 350 - 42, i)
				setActorY(_G['defaultStrum'..i..'Y'] + 16 * math.cos((currentBeat + i*5) * math.pi), i)
			end
			for i=4,7 do
				setActorX(_G['defaultStrum'..i..'X'] - 300 * math.sin(currentBeat * 0.504) - 275 - 42, i)
				setActorY(_G['defaultStrum'..i..'Y'] + 16 * math.cos((currentBeat + i*5) * math.pi), i)
			end
		end
	end

	if speedy then
		for i=0,7 do
			setActorY(_G['defaultStrum'..i..'Y'] + 16 * math.cos(currentBeat + i), i)
		end
	end
end

function beatHit (beat)
end

local didFinalFade = false

function stepHit (step)

	-- Separate these by ranges instead of on certain steps
	-- This is so that when steps are missed from lag, the effect still goes through

	-- fix for placement desync due to possible lag
	if (step >= 578 and step < 600) or (step >= 706 and step < 760) and (step >= 840 and step < 896) or (step >= 1030 and step < 1144) then
		for i=0,7 do
			setActorX(_G['defaultStrum'..i..'X'],i)
			setActorY(_G['defaultStrum'..i..'Y'], i)
			setActorAngle(0, i)
		end
	end


	-- "ENOUGH"
	if step == 176 then
		for i=0,3 do
			tweenFadeOut(i, 0, 0.4)
		end
	end
	if step == 188 then
		showOnlyStrums = true
	end
	if step == 192 then
		for i=0,7 do
			if i < 4 and middlescroll then
				tweenFadeIn(i, 0.35, 0.01)
			else
				tweenFadeIn(i, 1, 0.01)
			end
		end
		showOnlyStrums = false
	end

	-- Fade Out note timing
	if step == 1120 then
		for i=0,3 do
			tweenFadeOut(i, 0, 1)
		end
	end
	if randomMode then
		if not didFinalFade and step >= 1152 then
			tweenFadeOut(4, 0, 3)
			tweenFadeOut(5, 0, 3)
			tweenFadeOut(6, 0, 3)
			tweenFadeOut(7, 0, 3)
			didFinalFade = true
		end
	else
		if difficultyName == "Normal" then
			if step == 1148 then
				tweenFadeOut(5, 0, 0.2)
			end
			if step == 1150 then
				tweenFadeOut(6, 0, 0.2)
				tweenFadeOut(7, 0, 0.2)
			end
		else
			if step == 1146 then
				tweenFadeOut(5, 0, 0.2)
			end
			if step == 1148 then
				tweenFadeOut(6, 0, 0.2)
			end
			if step == 1150 then
				tweenFadeOut(7, 0, 0.2)
			end
		end
		if step == 1152 then
			tweenFadeOut(4, 0, 3)
			if middlescroll then
				tweenPosX(4, 200, 2)
			else
				tweenPosX(4, 600, 2)
			end
		end
	end


	-- Sway hud timing
	if (not sway) and ((step >= 192 and step < 320) or (step >= 448 and step < 576) or (step >= 832 and step < 1024)) then
		sway = true
	elseif sway and ((step >= 320 and step < 448) or (step >= 576 and step < 832) or (step >= 1024)) then
		sway = false
		camHudAngle = 0
	end


	-- Quickdraw note timing
	if (not quickdraw) and (step >= 320 and step < 448) then
		quickdraw = true
	elseif quickdraw and (step >= 448) then
		quickdraw = false
	end

	if (not quickdraw2) and (step >= 448 and step < 576) then
		quickdraw2 = true
	elseif quickdraw2 and (step >= 576) then
		quickdraw2 = false
		for i=0,7 do
			setActorY(_G['defaultStrum'..i..'Y'], i)
		end
	end

	if (not quickdraw3) and (step >= 960 and step < 992) then
		quickdraw3 = true
	elseif quickdraw3 and (step >= 992) then
		quickdraw3 = false
	end

	if (not quickdraw4) and (step >= 992 and step < 1024) then
		quickdraw4 = true
	elseif quickdraw4 and (step >= 1024) then
		quickdraw4 = false
	end


	--Criss-Cross note timing
	if (not fadingCrissCross) and ((step >= 640 and step < 704) or (step >= 832 and step < 960)) then
		local alphaVal = 0.3
		if middlescroll then
			alphaVal = 0
		end

		for i=0,3 do
			tweenFadeOut(i, alphaVal, 0.4)
		end

		fadingCrissCross = true
	end
	if fadingCrissCross and ((step >= 704 and step < 832) or (step >= 960 and step < 1024)) then
		local alphaVal = 1
		if middlescroll then
			alphaVal = 0.35
		end

		for i=0,3 do
			tweenFadeIn(i, alphaVal, 0.4)
		end
		fadingCrissCross = false
	end

	if (not crisscross) and (step >= 640 and step < 704) then
		crisscross = true
	elseif crisscross and (step >= 704 and step < 832) then
		crisscross = false
	end
	if (not crisscross2) and (step >= 832 and step < 960) then
		crisscross2 = true
	elseif crisscross2 and (step >= 960) then
		crisscross2 = false
	end



	-- Speedy note timing
	if (not speedy) and (step >= 768 and step < 832) then
		speedy = true
	elseif speedy and (step >= 832) then
		speedy = false
	end

	-- spin transitions
	if (step == 576) or (step == 704) or (step == 1024) then
		for i=0,7 do
			tweenPosXAngle(i, _G['defaultStrum'..i..'X'], getActorAngle(i) + 360, 0.2)
			setActorY(_G['defaultStrum'..i..'Y'], i) --  + 10
		end
	end
end