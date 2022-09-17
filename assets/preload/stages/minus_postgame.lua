local bgX = -1100
local bgY = -1350
local scr = 0.92

function onCreate()
	if backgroundLevel == 0 then
		close(true)
		return
	end

	makeLuaSprite('bg', 'minus/images/background_autumn', bgX, bgY)
	setScrollFactor('bg', scr, scr)
	addLuaSprite('bg')

	makeAnimatedLuaSprite('flag', 'minus/images/Flag', bgX + 1088*0.9, bgY + 130*0.9)
	addAnimationByPrefix('flag', 'day', 'Flag Wave Day', 12)
	setScrollFactor('flag', scr, scr)
	addLuaSprite('flag')

	--makeAnimatedLuaSprite('glass', 'minus/images/mics', bgX + (1121 * 0.9), bgY + (455 * 0.9))
	--addAnimationByPrefix('glass', 'day', 'Day', 0, false)
	--setScrollFactor('glass', scr, scr)
	--scaleObject('glass',0.9, 0.9)
	--addLuaSprite('glass')

	makeLuaSprite('overlay', 'minus/images/overlay1', bgX, bgY)
	setScrollFactor('overlay', scr, scr)
	setBlendMode('overlay', 'add')
	addLuaSprite('overlay')

	close(true)
end