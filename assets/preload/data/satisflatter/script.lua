function set(key, val)
	setProperty(key, val)
end
function get(key)
	return getProperty(key)
end
function addRel(key, val)
	setProperty(key, getProperty(key) + val)
end

function onCreate()
	set('cameraMoving', true)
	addCharacterToList('retro-alt-wrath', 'dad')
	set('camZooming', true)
end

local doingEnough = false
local stoppedEnough = false
local saidEnough = false

function onBeatHit()
	if not(stoppedEnough) and curBeat >= 48 then
		if flashingLights then
			cameraFlash("camGame", '0xFFFFFFFF', 0.2, true)
		end

		triggerEvent('Play Animation', 'singLEFTmiss', 'bf')
		set('camGame.zoom', get("defaultCamZoom"))

		set('noteKillOffset', 350 / get('songSpeed'))
		set('opponentCameraOffset', {0, 0})
		set('camZooming', true)
		set('cameraMoving', true)
		set('canPause', true)
		doTweenAlpha('comboHide', 'camOther', 1, 0.01)
		set('camOther.alpha', 1)
		setObjectCamera('comboLayer', 'hud')

		doingEnough = true
		stoppedEnough = true
	end
end

function onStepHit()
	if not(doingEnough) and curStep >= 185 and curStep < 192 then --  and get('camZooming')
		doTweenZoom('zoom', 'camGame', 2.25, 0.5, 'linear')
		set('cameraMoving', false)
		set('canPause', false)
		setObjectCamera('comboLayer', 'camOther')
		doTweenAlpha('comboHide', 'camOther', 0, 0.2)
		doTweenX('camX', 'camFollowPos', getMidpointX('dad')-75, 1.75*crochet/1000, 'quadOut')
		--doTweenY('camY', 'camFollowPos', getMidpointY('dad')-300, 1.75*crochet/1000, 'quadOut')
		doTweenY('camY', 'camFollowPos', getMidpointY('dad')-250, 1.75*crochet/1000, 'quadOut')

		set('noteKillOffset', 30000)
		set('opponentCameraOffset', {0, 0})
		set('camZooming', false)
		doingEnough = true
	end

	if curStep >= 186 and not saidEnough then
		triggerEvent('Change Character', 'dad', 'retro-alt-wrath')

		triggerEvent('Play Animation', 'enough', 'dad')
		set('camZooming', false)
		saidEnough = true
	end

	if curStep >= 186 and curStep < 192 then
		set('camZooming', false)
	end
end