-- CONSTANTS
local HIDDEN = 0.0000000001

-- UTILS
function set(key, val)
	setProperty(key, val)
end
function get(key)
	return getProperty(key)
end
function addRel(key, val)
	setProperty(key, getProperty(key) + val)
end
function addcRel(cl, key, val)
	setPropertyFromClass(cl, key, getPropertyFromClass(cl, key) + val)
end
function makeSolid(id, width, height, color)
	makeGraphic(id, 1, 1, color)
	scaleObject(id, width, height)
end

function makeSprite(id, image, x, y)
	local im = image
	makeLuaSprite(id, im, x, y)
	set(id..".active", false)
end

local origCamZoom = 1

function fire()
	if backgroundLevel > 1 and get('flames.alpha') == HIDDEN then
		--doTweenY('f1','flames', get('flames.y')-1000, 0.5, 'cubeOut')
		set("flames.y", get('flames.y')-1000)
		set("flames.alpha", 1)
		--doTweenAlpha('f1a','flames', 1, 0.5, 'cubeOut')
	end
end

function mainTrans()
	if backgroundLevel > 0 then
		--if backgroundLevel == 1 then
		--else
		if backgroundLevel > 1 then
			set("crack.active", true)
			objectPlayAnimation('crack', 'appear')
			objectPlayAnimation('cave', 'glow')
			objectPlayAnimation('cave2', 'glow')
			if flashingLights then
				set('bgFlash.visible', true)
				doTweenAlpha('flash', 'bgFlash', 0, 1, "linear")
			end
			--doTweenAlpha('vort', 'vortex', 1, 0.15, 'linear')
			set("vortex.alpha", 1)
			for i=0,8-1 do
				local id = "crystal"..tostring(i)
				set(id..".alpha", 1)
				--doTweenY('crystal'..tostring(i), id, get(id..'.y')-1500, math.random(1,4)/2)
				set(id..".y", get(id..'.y')-1500)
			end
		end
	end
end

function scaleRocks()
	if backgroundLevel > 0 then
		if get('rocks.scale.x') == 1 then
			addRel("rocks.scale.x", 0.1)
			addRel("rocks.scale.y", 0.1)
			addRel("rocksLeft.scale.x", 0.1)
			addRel("rocksLeft.scale.y", 0.1)
		end
	end
end

function onTimerCompleted(tag, loops, loopsLeft)
	if tag == "Fire" then
		fire()
	elseif tag == "Main Trans" then
		mainTrans()
	elseif tag == "Scale Rocks" then
		scaleRocks()
	end
end

function boundTo(val, min, max)
	if val > max then
		return max
	elseif val < min then
		return min
	end
	return val
end

function lerp(a, b, ratio)
	return a + ratio * (b - a)
end

function onCreatePost()
	-- Prevent out of bounds camera
	set('camFollowPos.x', get('camFollow.x') - 100)
	set('camFollowPos.y', get('camFollow.y') - 100)

	makeSprite('corruptroBlackCover', '', -1000, -1500)
	makeSolid('corruptroBlackCover', 1280*3, 720*3, '0xFF000000')
	screenCenter('corruptroBlackCover')
	setScrollFactor('corruptroBlackCover', 0, 0)
	addLuaSprite('corruptroBlackCover', true)
	print("AA")
end

local didTweenOut = false
local didFadeFlash = false
local didRoar = false
local didRoarShake = false
local didRoarOut = false

function onUpdate(elapsed)
	if not didTweenOut and not getProperty("startingSong") then
		doTweenAlpha('corruptroBlackCover', 'corruptroBlackCover', 0.4, 13)
		didTweenOut = true
	end

	if not didFadeFlash and curBeat >= 36 then
		cancelTween('corruptroBlackCover')
		set('corruptroBlackCover.alpha', 0)
		cameraFlash("camGame", '0xFFFFFFFF', 0.5, true)
		didFadeFlash = true
	end

	if not didRoar and curBeat >= 216 then
		addRel('defaultCamZoom', 0.2)
		didRoar = true
	end
	if not didRoarShake and curStep >= 216*4 + 1 then
		if screenShake then
			cameraShake('camGame', 0.01, 8)
		end
		didRoarShake = true
	end
	if curBeat >= 216 and curBeat < 228 then
		cameraSetTarget('dad')
		addRel('camFollow.x', -300)
	end
end

function onUpdatePost(elapsed)
	if not didRoarOut and curBeat >= 228 then
		addRel('defaultCamZoom', -0.2)
		set('camGame.zoom', get('defaultCamZoom'))
		cameraSetTarget('bf')
		set('camFollowPos.x', get('camFollow.x') - 50)
		set('camFollowPos.y', get('camFollow.y') - 50)
		set('camGame.scroll.x', get('camFollowPos.x'))
		set('camGame.scroll.y', get('camFollowPos.y'))
		cameraShake('camGame', 0, 0)
		didRoarOut = true
	end
end

function onEvent(ev, v1, v2)
	if ev == "Stage Transform" then
		--runTimer('Main Trans', 58/24 - 1.5)
		--runTimer('Fire', 58/24 - 1.5)
		--runTimer('Scale Rocks', 43/24 - 1.5)
		mainTrans()
		fire()
		scaleRocks()
	end
end

local stoppedBopping = false

function onBeatHit()
	if curBeat >= 616 and curBeat <= 808 then
		triggerEvent("Add Camera Zoom", 0.03, 0.04)
	end

	if not(stoppedBopping) and curBeat >= 808 then
		set('canCameraBop', false)
		stoppedBopping = true
	end
end

local secondCorruptRoar = false

function onStepHit()
	if not(secondCorruptRoar) and curStep >= 1824 then
		set('healthDrainPoison', get('healthDrainPoison') * 1.1)
		secondCorruptRoar = true
	end
end

function showHUD()
	doTweenAlpha('barBG', 'healthBarBG', healthBarAlpha, 0.5, 'linear')
	doTweenAlpha('bar', 'healthBar', healthBarAlpha, 0.5, 'linear')
	doTweenAlpha('score', 'scoreTxt', 1, 0.5, 'linear')
	doTweenAlpha('icon1', 'iconP1', healthBarAlpha, 0.5, 'linear')
	doTweenAlpha('icon2', 'iconP2', healthBarAlpha, 0.5, 'linear')
	doTweenAlpha('poise', 'poisonTxt', healthBarAlpha, 0.5, 'linear')
	doTweenAlpha('poision', 'poisonIcon', healthBarAlpha, 0.5, 'linear')
	set('botplayTxt.exists', true)
end

function hideHUD()
	--doTweenAlpha('byebarBG', 'healthBarBG', 0, 0.5, 'cubeInOut')
	doTweenAlpha('byebar', 'healthBar', 0, 0.5, 'cubeInOut')
	doTweenAlpha('byeicon1', 'iconP1', 0, 0.5, 'cubeInOut')
	doTweenAlpha('byeicon2', 'iconP2', 0, 0.5, 'cubeInOut')
	doTweenAlpha('byepoise', 'poisonTxt', 0, 0.5, 'cubeInOut')
	doTweenAlpha('byepoision', 'poisonIcon', 0, 0.5, 'cubeInOut')
	doTweenAlpha('byebyescore', 'scoreTxt', 0, 0.5, 'cubeInOut')
	doTweenAlpha('byebye', 'timeBar', 0, 0.5, 'cubeInOut')
	doTweenAlpha('byebyetc', 'timeTxt', 0, 0.5, 'cubeInOut')
	doTweenAlpha('byebyeP', 'timeBarBG', 0, 0.5, 'cubeInOut')
	for i=0,7 do
		noteTweenAlpha('strumFade'..i, i, 0, 0.5, 'cubeInOut')
	end
	set('botplayTxt.exists', false)
end