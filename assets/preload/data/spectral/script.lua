local story = false
local transforming = false
local roared = false
local slammed = false
local ending = false
local frame = 0
local frameTime = 1/24

-- Ending Cutscene Variables
local debris = 0
local onFire = false
local exploded = false
local shakeIntensity = 0
local shaderDestroyed = false
local outroFinished = false
local stoppedAnim = false

local tbcFinished = false

-- use backgroundLevel for background settings

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
function deb()
	debris = debris + 1
end

function onTweenCompleted(tag)
	if tag == 'byeLogo' then
		removeFromTracked('logo')
		removeLuaSprite('logo')
		clearUnusedMemory()
	end

	if tag == 'eh' then
		runTimer('ensou', 5.5, 0)
	end
end

local origCamZoom = 1

function onTimerCompleted(tag, loops, loopsLeft)
	if tag == 'playAnim' then
		runTimer('framy', frameTime, 0)
		objectPlayAnimation('retro-tf', 'tf', true)
		set('retro-tf.animation.paused', false)
		transforming = true
		set('canPause', false)
		playSound('Growl')
		playSound('ground shake')
		--set('isCameraOnForcedPos', true)
		set('camFollow.x', getMidpointX('dad')+150)
		set('camFollow.y', getMidpointY('dad')-100)
	end
	if transforming and tag == 'framy' then
		frame = frame + 1
	end

	if tag == 'finaleTime' then
		doTweenAlpha('eh', 'TBC', 1, 2.5, 'linear')
		playSound('FinalRoar')
		tbcFinished = true
	end

	if tag == 'ensou' then
		endSong()
	end
end

function onCreate()
	story = isStoryMode and not seenCutscene and firstTry
end

function onCreatePost()
	origCamZoom = get('defaultCamZoom')
	if story then
		set('dad.alpha', HIDDEN)
		set('dad.shaderEnabled', false)
		makeAnimatedLuaSprite('retro-tf','characters/retro-tf', get('dad.x')-136, get('dad.y')-237)
		addAnimationByPrefix('retro-tf', 'tf', 'transformation', 24, false)
		setWrathShader('retro-tf', 'wrath')
		set('retro-tf.shader.direction', 90)
		set('retro-tf.shader.overlay', 0.5)
		set('retro-tf.animation.paused', true)
		set('retro-tf.graphic.persist', false)
		setObjectOrder('retro-tf', getObjectOrder('dadGroup')+1)

		makeAnimatedLuaSprite('logo', 'characterLogo', 0, 200)
		addAnimationByPrefix('logo', 'zerktro', 'BERSERKER-RETRO-Instanz-1', 24, false)
		scaleObject('logo', 0.75, 0.75)
		screenCenter('logo', 'X')
		set('logo.alpha', HIDDEN)
		setObjectCamera('logo', 'camHUD')
		addLuaSprite('logo')

		set('healthBarBG.alpha', HIDDEN)
		set('healthBar.alpha', HIDDEN)
		set('scoreTxt.alpha', HIDDEN)
		set('iconP1.alpha', HIDDEN)
		set('iconP2.alpha', HIDDEN)
		set('poisonIcon.alpha', HIDDEN)
		set('botplayTxt.exists', false)
		set('poisonTxt.alpha', HIDDEN)
		set('camZooming', true)
	end

	if isStoryMode then
		addCharacterToList('retro2-wrath-outro', 'dad')

		--makeLuaSprite('TBC', '', 0, 0)
		--makeSolid('TBC', 1, 1, '000000')

		makeLuaSprite('TBC', 'outroTBC', 0, 0)
		setObjectCamera('TBC', 'other')
		set('TBC.alpha', HIDDEN)
		--scaleObject('TBC', 0.5, 0.5)
		screenCenter('TBC')
	end
end

function onSongStart()
	if isStoryMode then
		setPropertyFromClass('flixel.FlxG', 'sound.music.onComplete', nil)
	end
end

function onStartCountdown()
	if not allowCountDown and story then
		setProperty('inCutscene', true)
		runTimer('playAnim', 0.2)
		allowCountDown = true
		return Function_Stop
	end
	setPropertyFromClass('PlayState', 'seenCutscene', true)
	--firstTry = true

	set('defaultCamZoom', 0.525) -- 0.685
	set('camZooming', true)
	clearUnusedMemory()
	return Function_Continue
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

function onUpdate(elapsed)
	if transforming and get('inCutscene') and not ending then
		local lerpVal = boundTo(elapsed * 2.4 * get('cameraSpeed'), 0, 1)
		if get('cameraMoving') then
			set('camFollowPos.x', lerp(get('camFollowPos.x'), get('camFollow.x'), lerpVal))
			set('camFollowPos.y', lerp(get('camFollowPos.y'), get('camFollow.y'), lerpVal))
		end
	end
end

function onUpdatePost(elapsed)
	if transforming and not ending and story then
		--debugPrint(get('dad.animation.curAnim.curFrame'), " ", frame)
		local bad = get('retro-tf.animation.curAnim.curFrame')
		local zoom = getProperty('defaultCamZoom')
		local z = 'defaultCamZoom'

		if bad >= 0 and bad < 24 and zoom < 0.9 then
			addRel(z, 0.5*elapsed)
		elseif bad >= 0 and bad < 24 and zoom > 0.9 then
			set(z, 0.9)
		elseif bad >= 43 and bad < 72 and zoom > 0.685 then
			addRel(z, -0.5*elapsed)
		elseif bad >= 43 and bad < 72 and zoom < 0.685 then
			set(z, 0.685)
		elseif bad >= 77 and bad < 105 then
			set('camFollow.x', getMidpointX('dad')+150)
			set('camFollow.y', getMidpointY('dad')-275)

			if zoom > 0.525 then addRel(z, -0.33*elapsed)
			elseif zoom < 0.525 then set(z, 0.525)
			end
			if screenShake then
				cameraShake('camGame', 0.025, 0.35)
			end

			if windowShake then
				local shakeXBool = math.random(0,1)
				local shakeXAmount = 1
				if shakeXBool == 0 then shakeXAmount = -1 end

				local shakeYBool = math.random(0,1)
				local shakeYAmount = 1
				if shakeYBool == 0 then shakeYAmount = -1 end

				addcRel("openfl.Lib", "application.window.x",shakeXAmount*3)
				addcRel("openfl.Lib", "application.window.y",shakeYAmount*3)
			end

			if backgroundLevel > 1 and get('flames.alpha') == HIDDEN then
				doTweenY('f1','flames', get('flames.y')-1000, 0.5, 'cubeOut')
				--doTweenY('f2','flamesChange', get('flames.y')-1000, 0.5, 'cubeOut')
				doTweenAlpha('f1a','flames', 1, 0.5, 'cubeOut')
			end
			if not roared then roared = true playSound('roar') end
		end
		if bad >= 58 and not slammed then
			slammed = true
			if screenShake then
			cameraShake('camGame', 0.075, 0.5)
			end

			if windowShake then
				addcRel("openfl.Lib", "application.window.y",100)
			end
			playSound('Fist slam')
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
					doTweenAlpha('vort', 'vortex', 1, 0.15, 'linear')
					for i=0,8-1 do
						local id = "crystal"..tostring(i)
						set(id..".alpha", 1)
						doTweenY('crystal'..tostring(i), id, get(id..'.y')-1500, math.random(1,4)/2)
					end
				end

				set('logo.alpha', 1)
				objectPlayAnimation('logo', 'zerktro', true)
			end
		end
		if bad >= 116 then
			doTweenAlpha('byeLogo', 'logo', 0, 0.5, 'cubeInOut')
			transforming = false
			set('dad.alpha', 1)
			set('dad.shaderEnabled', true)
			set('inCutscene', false)
			removeShader('retro-tf')
			showHUD()
			removeFromTracked('retro-tf')
			removeLuaSprite('retro-tf')
			startCountdown('var')
			cancelTimer('framy')
			set('canPause', true)
			--bad = 0
			slammed = false
		end

		if backgroundLevel > 0 then
			if bad >= 43 and bad < 72 and get('rocks.scale.x') == 1 then
				addRel("rocks.scale.x", 0.1)
				addRel("rocks.scale.y", 0.1)
				addRel("rocksLeft.scale.x", 0.1)
				addRel("rocksLeft.scale.y", 0.1)
			end
		end
	end

	if transforming and ending and isStoryMode then
		local frim = get('dad.animation.curAnim.curFrame')
		cameraSetTarget('dad')
		set('camFollow.x', getMidpointX('dad')-680)
		set('camFollow.y', getMidpointY('dad')-600)
		if frim >= 29 and not slammed then
			slammed = true
			playSound('AngySlam')

			if screenShake then
				cameraShake('camGame', 0.05, 0.5)
			end

			if windowShake then
				addcRel("openfl.Lib", "application.window.y",50)
			end
		elseif slammed and debris == 0 then
			deb()
			playSound('Debris1')
		end

		if frim >= 58 and not shaderDestroyed then
			shaderDestroyed = true
			removeShader('dad')
		end

		if not onFire and frim >= 63 then
			onFire = true
			playSound('fire')
		end

		if not exploded and frim >= 74 then
			exploded = true
			playSound('FireBoom')
		elseif exploded and debris == 1 then
			deb()
			playSound('Debris2')
			playSound('FireRoar')
		end

		if frim >= 79 and frim <= 116 then
			local perc = (116-frim)/(116-79)
			local invi = (1-perc)*255

			set('dad.colorTransform.redMultiplier', perc)
			set('dad.colorTransform.greenMultiplier', perc)
			set('dad.colorTransform.blueMultiplier', perc)
			set('dad.colorTransform.redOffset', invi)
			set('dad.colorTransform.greenOffset', invi)
			set('dad.colorTransform.blueOffset', invi)
		end

		if frim >= 81 and frim < 121 and screenShake then
			shakeIntensity = shakeIntensity + elapsed*0.025
			cameraShake('camGame', shakeIntensity, 0.1)
		end

		if frim >= 122 and not outroFinished then
			outroFinished = true
			--frame = 0
			if flashingLights then
				cameraFlash('camOther', 'FFFFFF', 1, true)
			end
			set('cameraMoving', true)
			playSound('Debris3')

			makeLuaSprite('BlackBG', '', -1000, -600)
			makeSolid('BlackBG', 4096, 4096, '000000')
			setObjectCamera('BlackBG', 'other')
			setScrollFactor('BlackBG', 0, 0)
			addLuaSprite('BlackBG', true)

			runTimer('finaleTime', 2)
			set('canResync', false)
			addLuaSprite('TBC', true)
		end

		if not(stoppedAnim) and get('dad.animation.curAnim.curFrame') >= 122 then
			set('dad.active', false)
			stoppedAnim = true
		end
	end
end

function onStepHit()
	if curStep >= 1856 and not ending and isStoryMode then
		ending = true
		transforming = true
		--set('inCutscene', true)
		set('canPause', false)
		set('camHUD.angle', 0)
		set('camGame.angle', 0)
		--set('cameraMoving', true)
		hideHUD()
		removeShader('dad')
		triggerEvent('Change Character', 'dad', 'retro2-wrath-outro')
		triggerEvent('Play Animation', 'idle', 'dad')
		set("dad.stunned", true)
		setWrathShader('dad', 'wrath')
		set('dad.shader.direction', 90)
		set('dad.shader.overlay', 0.5)

		playSound('AngyRoar')
		runTimer('framy', frameTime, 0)
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

function ocnEndSong()
	--if isStoryMode and not seenCutscene then
	--set('inCutscene', true)
	--seenCutscene = true
	--return Function_Stop
	--end

	--if isStoryMode and not tbcFinished then
	--return Function_Stop
	--end

	return Function_Continue
end