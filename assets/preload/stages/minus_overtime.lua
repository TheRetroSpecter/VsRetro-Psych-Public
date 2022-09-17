local bgX = -1100
local bgY = -1350
local scr = 0.92

function onCreate()
	if backgroundLevel == 0 then
		close(true)
		return
	end

	setPropertyFromClass("PlayState", "currentWrath", "night")

	makeLuaSprite('bg', 'minus/images/background_night', bgX, bgY)
	setScrollFactor('bg', scr, scr)
	setProperty('bg.active', false)
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

	scaleObject('bopL',1.04, 1.04)
	scaleObject('bopM',1.04, 1.04)
	scaleObject('bopR',1.04, 1.04)
	--scaleObject('bopT',1/0.9, 1/0.9)

	addLuaSprite('bopL')
	addLuaSprite('bopM')
	addLuaSprite('bopR')
	addLuaSprite('bopT')

	makeAnimatedLuaSprite('flag', 'minus/images/Flag', bgX + 1088*0.9, bgY + 130*0.9)
	addAnimationByPrefix('flag', 'day', 'Flag Wave Night', 12)
	setScrollFactor('flag', scr, scr)
	addLuaSprite('flag')

	makeAnimatedLuaSprite('glass', 'minus/images/mics', bgX + (1121 * 0.9), bgY + (455 * 0.9))
	addAnimationByPrefix('glass', 'day', 'Night', 0, false)
	setScrollFactor('glass', scr, scr)
	--scaleObject('glass',0.9, 0.9)
	addLuaSprite('glass')

	makeLuaSprite('dark', '', bgX, bgY)
	makeGraphic('dark', 1, 1, '000000')
	scaleObject('dark', 4177, 2530)
	setProperty('dark.alpha', 0.5)
	setProperty('dark.active', false)
	addLuaSprite('dark')

	makeLuaSprite('groundLight', 'minus/images/background_night_highlight', bgX+372, bgY+2054)
	setScrollFactor('groundLight', scr, scr)
	setProperty('groundLight.active', false)
	addLuaSprite('groundLight')

	makeLuaSprite('big1', 'minus/images/background_night_lightbeambig1', bgX-65, bgY+156)
	makeLuaSprite('big2', 'minus/images/background_night_lightbeambig1', bgX+1941, bgY+156)
	setScrollFactor('big1', 1.2, scr)
	setScrollFactor('big2', 1.2, scr)
	setBlendMode('big1', 'add')
	setBlendMode('big2', 'add')
	setProperty('big2.flipX', true)
	addLuaSprite('big1', true)
	addLuaSprite('big2', true)

	makeLuaSprite('lil1', 'minus/images/background_night_lightbeamsmall1', bgX+85, bgY)
	makeLuaSprite('lil2', 'minus/images/background_night_lightbeamsmall1', bgX+1825, bgY)
	setScrollFactor('lil1', scr, scr)
	setScrollFactor('lil2', scr, scr)
	setBlendMode('lil1', 'add')
	setBlendMode('lil2', 'add')
	setProperty('lil2.flipX', true)
	addLuaSprite('lil1', true)
	addLuaSprite('lil2', true)

	makeLuaSprite('overlay', 'minus/images/overlay1', bgX, bgY)
	setScrollFactor('overlay', scr, scr)
	setBlendMode('overlay', 'add')
	setProperty('overlay.active', false)
	addLuaSprite('overlay')
end

function onBeatHit()
	if curBeat%2 == 0 then
		objectPlayAnimation('bopL', 'bop')
		objectPlayAnimation('bopM', 'bop')
		objectPlayAnimation('bopR', 'bop')
		objectPlayAnimation('bopT', 'bop')
	end
end