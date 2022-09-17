local bgX = -1100
local bgY = -1350
local scr = 0.92

function onCreate()
	if backgroundLevel == 0 then
		close(true)
		return
	end

	setPropertyFromClass("PlayState", "currentWrath", "sunset")

	makeLuaSprite('bg', 'minus/images/background_preppy', bgX, bgY)
	setScrollFactor('bg', scr, scr)
	addLuaSprite('bg')

	makeAnimatedLuaSprite('bopL', 'minus/images/minus_back_characters_left', bgX-5, 293*0.9 + bgY+372/0.9-13)
	makeAnimatedLuaSprite('bopM', 'minus/images/minus_back_characters_middle', 900*0.9 + bgX*0.9 -45, 886+bgY-8)
	makeAnimatedLuaSprite('bopR', 'minus/images/minus_back_characters_right', 3727*0.9 - 6 +bgX*0.9+30, 212*0.9+bgY+372/0.9-16)
	makeAnimatedLuaSprite('bopT', 'minus/images/minus_back_characters_top', 1685*0.9 -170+bgX*0.9+12, 90*0.9 - 95+bgY+372/0.9)

	addAnimationByPrefix('bopL', 'bop', 'head', 24, false)
	addAnimationByPrefix('bopM', 'bop', 'head', 24, false)
	addAnimationByPrefix('bopR', 'bop', 'head', 24, false)
	addAnimationByPrefix('bopT', 'bop', 'head', 24, false)

	setScrollFactor('bopL', scr, scr)
	setScrollFactor('bopM', scr, scr)
	setScrollFactor('bopR', scr, scr)
	setScrollFactor('bopT', scr, scr)

	setWrathShader('bopL', 'sunset', 20)
	setWrathShader('bopM', 'sunset', 20)
	setWrathShader('bopR', 'sunset', 20)
	setWrathShader('bopT', 'sunset', 20)

	scaleObject('bopL',1.04, 1.04)
	scaleObject('bopM',1.04, 1.04)
	scaleObject('bopR',1.04, 1.04)
	--scaleObject('bopT',1/0.9, 1/0.9)

	addLuaSprite('bopL')
	addLuaSprite('bopM')
	addLuaSprite('bopR')
	addLuaSprite('bopT')

	makeAnimatedLuaSprite('flag', 'minus/images/Flag', bgX + 1088*0.9, bgY + 130*0.9)
	addAnimationByPrefix('flag', 'day', 'Flag Wave Evening', 12)
	setScrollFactor('flag', scr, scr)
	addLuaSprite('flag')

	makeAnimatedLuaSprite('glass', 'minus/images/mics', bgX + (1121 * 0.9), bgY + (455 * 0.9))
	addAnimationByPrefix('glass', 'day', 'Evening', 0, false)
	setScrollFactor('glass', scr, scr)
	--scaleObject('glass',0.9, 0.9)
	addLuaSprite('glass')

	makeLuaSprite('overlay', 'minus/images/overlay1', bgX, bgY)
	setScrollFactor('overlay', scr, scr)
	setBlendMode('overlay', 'add')
	addLuaSprite('overlay')

	makeLuaSprite('flare', 'minus/images/background_evening_flare', bgX, bgY)
	setScrollFactor('flare', scr, scr)
	setProperty('flare.alpha', 0.8)
	setBlendMode('flare', 'add')
	addLuaSprite('flare', true)

	makeAnimatedLuaSprite('sakuBop', 'characters/minus/Metro_BG', -1100, 45)
	addAnimationByPrefix('sakuBop', 'idle', 'Minus', 24, false)
	setWrathShader('sakuBop', 'sunset', 20)
	setScrollFactor('sakuBop', 0.95, 0.95)
	addLuaSprite('sakuBop')
end

function onBeatHit()
	if curBeat%2 == 0 then
		objectPlayAnimation('bopL', 'bop')
		objectPlayAnimation('bopM', 'bop')
		objectPlayAnimation('bopR', 'bop')
		objectPlayAnimation('bopT', 'bop')
		objectPlayAnimation('sakuBop', 'idle')
	end
end