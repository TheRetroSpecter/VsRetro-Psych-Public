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

-- Actual code

local didFadeOut = false
local didFadeIn = false

function update(elapsed)
	-- "ENOUGH"
	if curStep >= 240 and not didFadeOut then
		for i=0,3 do
			tweenFadeOut(i, 0, 0.4)
		end
		didFadeOut = true
	end
	if curStep >= 252 and curStep < 255 then
		showOnlyStrums = true
	end
	if curStep >= 255 and not didFadeIn then
		for i=0,7 do
			if i < 4 and middlescroll then
				tweenFadeIn(i, 0.35, 0.01)
			else
				tweenFadeIn(i, 1, 0.01)
			end
		end
		showOnlyStrums = false
		didFadeIn = true
	end
end