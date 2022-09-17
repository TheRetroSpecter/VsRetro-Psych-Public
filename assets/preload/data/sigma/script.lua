local confettiTimes = { 145, 146, 147, 148, 149, 150, 178, 179, 180, 181, 182, 183, 275, 276, 277, 278, 279, 280 }
local thrownBig = false

local danced = false

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

local allowCountDown = false

local offsets = {
	['danceLeft'] = {0, 0},
	['danceRight'] = {0, 0},
	['cheer'] = {70, 113}
}

local frameTime = 1/24

local frameNumber = 0

local introPlayed = false

local story = false --to initialize the bool

function onCreate()
	story = isStoryMode and not seenCutscene and firstTry
end

function onCreatePost()
	if story then
		--precacheSound('ClothesShuffle')
		--precacheSound('MicSpin')
		--precacheSound('MicGrab')
		--precacheSound('EyeGlare')

		set('dad.alpha', HIDDEN)

		set('healthBarBG.alpha', HIDDEN)
		set('healthBar.alpha', HIDDEN)
		set('scoreTxt.alpha', HIDDEN)
		set('iconP1.alpha', HIDDEN)
		set('iconP2.alpha', HIDDEN)
		set('botplayTxt.exists', false)

		makeAnimatedLuaSprite('inTro', 'characters/minus/Minus_Retro_Intro', getCharacterX('dad')+17, getCharacterY('dad')-8)
		addAnimationByPrefix('inTro', 'intro', 'Minus Retro Intro', 24, false)
		set('inTro.animation.paused', true)
		set('inTro.graphic.persist', false)
		setObjectOrder('inTro', getObjectOrder('dadGroup')+1)
	end
end

function onTimerCompleted(tag, loops, loopsLeft)
	if tag == 'playAnim' then
		runTimer('frame', frameTime, 0)
		objectPlayAnimation('inTro', 'intro', true)
		set('inTro.animation.paused', false)
	end
	if tag == 'frame' and not introPlayed then
		frameNumber = frameNumber + 1
	end
end

function onStartCountdown()
	if not allowCountDown and story then
		setProperty('inCutscene', true)
		runTimer('playAnim', 0.5)
		allowCountDown = true
		return Function_Stop
	end
	setPropertyFromClass('PlayState', 'seenCutscene', true)
	--firstTry = true
	showHUD()
	removeSoundFromTracked('ClothesShuffle')
	removeSoundFromTracked('MicSpin')
	removeSoundFromTracked('MicGrab')
	removeSoundFromTracked('EyeGlare')
	clearUnusedMemory()
	return Function_Continue
end

local clothesPlayed = false
local spinPlayed = false
local grabPlayed = false

function onUpdate(elapsed)
	if not introPlayed and story then
		if frameNumber >= 11 and frameNumber < 27 and not clothesPlayed then
			playSound('ClothesShuffle')
			clothesPlayed = true
		elseif frameNumber >= 27 and frameNumber < 38 and not spinPlayed then
			playSound('MicSpin')
			spinPlayed = true
		elseif frameNumber >= 38 and frameNumber < 50 and not grabPlayed then
			playSound('MicGrab')
			playSound('EyeGlare')
			grabPlayed = true
		elseif frameNumber >= 50 and not introPlayed then
			introPlayed = true
			seenCutscene = true
			set('dad.alpha', 1)
			setProperty('inCutscene', false)
			removeFromTracked('inTro')
			removeLuaSprite('inTro', true)
			startCountdown('var')
			cancelTimer('frame')
		end
	end
end

function dance()
	danced = not danced
	if danced then
		objectPlayAnimation('sakuBop', 'danceRight')
	else
		objectPlayAnimation('sakuBop', 'danceLeft')
	end
end

function showHUD()
	doTweenAlpha('barBG', 'healthBarBG', healthBarAlpha, 0.5, 'linear')
	doTweenAlpha('bar', 'healthBar', healthBarAlpha, 0.5, 'linear')
	doTweenAlpha('icon1', 'iconP1', healthBarAlpha, 0.5, 'linear')
	doTweenAlpha('icon2', 'iconP2', healthBarAlpha, 0.5, 'linear')
	doTweenAlpha('score', 'scoreTxt', 1, 0.5, 'linear')
	set('botplayTxt.exists', true)
end

local isInCheer = false

function onBeatHit()
	while (0 < #confettiTimes and curBeat >= confettiTimes[0+1]) do
		local event = table.remove(confettiTimes, 1)
		triggerEvent('Confetti Burst', '1', '')
	end

	if curBeat >= 292 and not thrownBig then
		triggerEvent('Confetti Burst', '2', '')
		thrownBig = true
	end

	if curBeat % 2 == 0 then dance() end

	isInCheer = false

	cheer(145, 4, 8, true)
	cheer(177, 2, 15, true)

	if isInCheer then
		set('gf.stunned', true)
	else
		set('gf.stunned', false)
	end

	local sakuAnim = get('sakuBop.animation.curAnim.name')
	set('sakuBop.offset.x', offsets[sakuAnim][1])
	set('sakuBop.offset.y', offsets[sakuAnim][2])
end

function cheer(start, spacing, repeet, saku)
	if curBeat >= start and curBeat <= start + (spacing * repeet) then
		isInCheer = spacing == 2 or (curBeat - start) % spacing < 1
		if (curBeat - start) % spacing == 0 then
			if saku then
				objectPlayAnimation('sakuBop', 'cheer', true)
				--dance()
			end
			if spacing == 4 then
				set("gf.danced", not(get("gf.danced")))
			end
			triggerEvent('Hey!', 'gf', crochet/1000)
		end
	end
end