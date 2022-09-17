function set(key, val)
	setProperty(key, val)
end
function get(key)
	return getProperty(key)
end
function addRel(key, val)
	setProperty(key, getProperty(key) + val)
end


--[[
function confetti(start, owari, space, big)
	for i=start,owari,space do
		if big then table.insert(confettiTimes, i)
		else table.insert(hugefetti, i)
		end
	end
end
]]

local confettiTimes = {}
local hugefetti = {}

function onCreate()
	for i=0,95 do
	table.insert(confettiTimes, i)
	end
	for i=420,452,2 do
	table.insert(confettiTimes, i)
	end
	for i=840,908 do
	table.insert(confettiTimes, i)
	end
	for i=908,960 do
	table.insert(hugefetti, i)
	end
	--confetti(0, 95, 1, false)
	--confetti(840, 908, 1, false)
	--confetti(420, 452, 2, false)
	--confetti(908, 960, 1, true)
	set('camZooming', true)
	set('cameraMoving', true)
	addCharacterToList('retro-minus-taunt', 'dad')
end

local isTaunt = false
local finishedTaunt = false
local didTauntZoom = false
local didHideCombo = false

function onStepHit()
	if not finishedTaunt then
		if curStep >= 1776 and not didTauntZoom then
			--set('cameraMoving', false)
			set('camZooming', false)
			--lerpCamera(cameraX +75,cameraY -150, elapsed*2.4)
			doTweenZoom('zoom', 'camGame', 1.3, (8/7), 'cubeOut')

			set('isCameraOnForcedPos', true)
			set('camFollow.x', getMidpointX('dad')-75 + 150)
			set('camFollow.y', getMidpointY('dad')-300 + 150)

			didTauntZoom = true
		end

		if curStep >= 1790 and not didHideCombo then
			set('canPause', false)
			setObjectCamera('comboLayer', 'camOther')
			doTweenAlpha('comboHide', 'camOther', 0, 0.2)

			didHideCombo = true
		end

		if curStep >= 1808 and isTaunt then
			set('camGame.zoom', get('defaultCamZoom'))
			triggerEvent('Change Character', 'dad', 'retro-minus')

			cameraFlash("camGame", '0xFFFFFFFF', 1.2, true)

			set('isCameraOnForcedPos', false)
			addRel('camFollowPos.x',600)
			addRel('camFollowPos.y',-100)

			set('camFollow.x', get('camFollowPos.x'))
			set('camFollow.y', get('camFollowPos.y'))

			set('camGame.scroll.x', get('camFollowPos.x'))
			set('camGame.scroll.y', get('camFollowPos.y'))

			--addRel('camGame.scroll.x', 600)
			--addRel('camGame.scroll.y', -100)
			set('camZooming', true)
			--set('cameraMoving', true)

			set('canPause', true)
			doTweenAlpha('comboHide', 'camOther', 1, 0.01)
			set('camOther.alpha', 1)
			setObjectCamera('comboLayer', 'hud')

			finishedTaunt = true
			isTaunt = false
		elseif not(isTaunt) and curStep >= 1790 then
			triggerEvent('Change Character', 'dad', 'retro-minus-taunt')
			triggerEvent('Play Animation', 'idle','dad')
			isTaunt = true
		end
	end
end

local isInCheer = false

function onBeatHit()
	while (0 < #confettiTimes and curBeat >= confettiTimes[0+1]) do
		local event = table.remove(confettiTimes, 1)
		triggerEvent('Confetti Burst', '1', '')
	end

	while (0 < #hugefetti and curBeat >= hugefetti[0+1]) do
		local event = table.remove(hugefetti, 1)
		triggerEvent('Confetti Burst', '2', '')
	end

	isInCheer = false

	cheer(420, 2, 16)
	cheer(836, 2, 32)

	if isInCheer then
		set('gf.stunned', true)
	else
		set('gf.stunned', false)
	end
end

function onEndSong()
	runTimer('confetti', crochet/1000, 32)
	return Function_Continue
end

function onTimerCompleted(tag, loops, loopsleft)
	if tag == 'confetti' then
		local str = '2'
		if loopsleft < 16 then str = '1' end
		triggerEvent('Confetti Burst', str, '')
	end
end

function cheer(start, spacing, repeet)
	if curBeat >= start and curBeat <= start + (spacing * repeet) then
		isInCheer = spacing == 2 or (curBeat - start) % spacing < 1
		if (curBeat - start) % spacing == 0 then
			triggerEvent('Hey!', 'gf', crochet/1000)
		end
	end
end