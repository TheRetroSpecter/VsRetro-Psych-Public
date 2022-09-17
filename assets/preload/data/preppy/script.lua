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

local confettiTimes = { 5, 6, 7, 17, 18, 19, 20, 21, 22, 356, 357, 358, 359, 360, 361, 404, 405, 406, 407, 408, 409, 410, 411, 412, 425, 426, 427, 428, 429, 430, 431, 432 }

local zoom = false
local didResetZoom = false
local stunned = false
local redanced = false

function OnCreate()
	set('camZooming', true)
	set('canPause', true)
end

function onBeatHit()
	while (0 < #confettiTimes and curBeat >= confettiTimes[0+1]) do
		local event = table.remove(confettiTimes, 1)
		triggerEvent('Confetti Burst', '1', '')
	end

	if curBeat >= 95 and not zoom then
		set('camZooming', false)
		set('canPause', false)
		doTweenZoom('zoom', 'camGame', 1.4, 0.8, 'linear')

		set('isCameraOnForcedPos', true)
		set('camFollow.x', getMidpointX('dad')-300)
		set('camFollow.y', getMidpointY('dad')-300 + 70)
		setObjectCamera('comboLayer', 'camOther')
		doTweenAlpha('comboHide', 'camOther', 0, 0.2)

		zoom = true
	end
	
	if curBeat >= 98 and not didResetZoom then
		cameraFlash("camGame", '0xFFFFFFFF', 1.2, true)
		set('camGame.zoom', get('defaultCamZoom'))

		set("isCameraOnForcedPos", false)
		cameraSetTarget("dad")

		set("camFollowPos.x", get("camFollow.x"))
		set("camFollowPos.y", get("camFollow.y"))

		set('camZooming', true)
		set('cameraMoving', true)
		set('canPause', true)
		doTweenAlpha('comboHide', 'camOther', 1, 0.01)
		set('camOther.alpha', 1)
		setObjectCamera('comboLayer', 'hud')

		didResetZoom = true
	end
	
	if curBeat >= 421 and not stunned then
		set('dad.stunned', true)
		stunned = true
	end
	
	if curBeat >= 424 and curBeat < 427 and not redanced then
		set('dad.stunned', false)
		redanced = true
	end
end