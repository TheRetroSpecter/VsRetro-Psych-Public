function set(key, val)
	setProperty(key, val)
end
function get(key)
	return getProperty(key)
end
function addRel(key, val)
	setProperty(key, getProperty(key) + val)
end

function onCreatePost()
	-- Prevent out of bounds camera
	set('camFollowPos.x', get('camFollow.x') - 100)
	set('camFollowPos.y', get('camFollow.y') - 100)

	makeLuaText('txt', "That's how you\ndo it, hun!\n", 1280, 0, 425)
	setTextBorder('txt', 6, '000000')
	setTextSize('txt', 70)
	screenCenter('txt', 'X')
	setObjectCamera('txt', 'camHUD')
end

local laughId = 0

local shownThats = false
local finishedEncourage = false
local didEncourageZoom = false
local didHideCombo = false

function onStepHit()
	if laughId == 0 and curStep >= 1130 then
		triggerEvent('Play Animation', 'laugh', 'dad')

		laughId = laughId + 1
	end

	--if curStep >= 1120 and curStep < 1152 then
	--	cameraSetTarget('dad')
	--end

	if laughId == 1 and curStep >= 1139 then
		triggerEvent('Play Animation', 'encourage', 'dad')

		laughId = laughId + 1
	end

	if laughId == 2 and curStep >= 2074 then
		triggerEvent('Play Animation', 'wink', 'bf')

		laughId = laughId + 1
	end

	if curStep >= 2048 then
		cameraSetTarget('bf')
	end


	if not finishedEncourage then
		if curStep >= 1130 and not didEncourageZoom then
			--set('cameraMoving', false)
			set('camZooming', false)
			--lerpCamera(cameraX +75,cameraY -150, elapsed*2.4)
			doTweenZoom('zoom', 'camGame', 1.3, (12/7), 'cubeOut')

			set('isCameraOnForcedPos', true)
			set('camFollow.x', getMidpointX('dad')-75 + 150)
			set('camFollow.y', getMidpointY('dad')-300 + 50)

			didEncourageZoom = true
		end

		if curStep >= 1138 and not shownThats then
			addLuaText('txt')

			shownThats = true
		end

		if curStep >= 1130 and not didHideCombo then
			set('canPause', false)
			setObjectCamera('comboLayer', 'camOther')
			doTweenAlpha('comboHide', 'camOther', 0, 0.2)

			didHideCombo = true
		end

		if curStep >= 1152 then
			set('camGame.zoom', get('defaultCamZoom'))

			cameraFlash("camGame", '0xFFFFFFFF', 1.2, true)

			removeLuaText('txt')

			set('isCameraOnForcedPos', false)
			cameraSetTarget('dad')

			set('camFollowPos.x', get('camFollow.x') + 50)
			set('camFollowPos.y', get('camFollow.y') + 50)

			set('camGame.scroll.x', get('camFollowPos.x'))
			set('camGame.scroll.y', get('camFollowPos.y'))

			set('camZooming', true)
			--set('cameraMoving', true)

			set('canPause', true)
			doTweenAlpha('comboHide', 'camOther', 1, 0.01)
			set('camOther.alpha', 1)
			setObjectCamera('comboLayer', 'hud')

			finishedEncourage = true
		end
	end
end