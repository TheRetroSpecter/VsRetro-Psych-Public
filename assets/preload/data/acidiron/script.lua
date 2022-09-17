function set(key, val)
	setProperty(key, val)
end
function get(key)
	return getProperty(key)
end
function addRel(key, val)
	setProperty(key, getProperty(key) + val)
end


local confettiTimes = {}
local hugefetti = {}

local offsets = {
	['danceLeft'] = {0, 0},
	['danceRight'] = {0, 0},
	['cheer'] = {70, 113}
}

local cheerStart = 32
local repp = 30
local space = 2

local cheer2 = 322
local rep2 = 8 
local space2 = 4

local cheer3 = 386
local rep3 = 16
local space3 = 4

local cheer4 = 514
local rep4 = 31
local space4 = 2

local exhausted = false
local altered = false
local zoomed = false
local arrgh = false

function onCreate()
	for i=2,31 do
		table.insert(confettiTimes, i)
	end
	for i=32,92,2 do
		table.insert(confettiTimes, i)
	end
	for i=322,341 do
		table.insert(confettiTimes, i)
	end
	for i=392,451 do
		table.insert(confettiTimes, i)
	end
	for i=514,576,2 do
		table.insert(confettiTimes, i)
	end

	for i=590,600 do
		table.insert(confettiTimes, i)
	end
	for i=578,589 do
		table.insert(hugefetti, i)
	end

	set('camZooming', true)
	set('canPause', true)
	set('cameraMoving', true)
	addCharacterToList('retro-minus-sweat', 'dad')
end

function dance()
	danced = not danced
	if danced then objectPlayAnimation('sakuBop','danceRight')
	else objectPlayAnimation('sakuBop', 'danceLeft')
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

	if curBeat % 2 == 0 then dance() end

	isInCheer = false

	cheer(cheerStart, space, repp, true, false)
	cheer(cheer2, space2, rep2, true, true)
	cheer(cheer3, space3, rep3, true, true)
	cheer(cheer4, space4, rep4, false, false)

	if isInCheer then
		set('gf.stunned', true)
	else
		set('gf.stunned', false)
	end

	local anim = get('sakuBop.animation.curAnim.name')
	set('sakuBop.offset.x', offsets[anim][1])
	set('sakuBop.offset.y', offsets[anim][2])

	if not exhausted then
		if curBeat >= 317 and not zoomed then
			set('camZooming', false)
			set('canPause', false)
			--lerpCamera(cameraX +75,cameraY -150, elapsed*2.4)
			doTweenZoom('zoom', 'camGame', 1.3, 0.3, 'linear')

			set('isCameraOnForcedPos', true)
			set('camFollow.x', getMidpointX('dad')-75 + 150)
			set('camFollow.y', getMidpointY('dad')-300 + 150)
			setObjectCamera('comboLayer', 'camOther')
			doTweenAlpha('comboHide', 'camOther', 0, 0.2)

			zoomed = true
		end

		if curBeat >= 321 and not arrgh then
			triggerEvent('Change Character', 'dad', 'retro-minus-sweat')
			triggerEvent('Play Animation', 'grunt', 'dad')
			arrgh = true
		end

		if curBeat >= 322 and not altered then
			set('camGame.zoom', get('defaultCamZoom'))

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
			set('cameraMoving', true)

			set('canPause', true)
			doTweenAlpha('comboHide', 'camOther', 1, 0.01)
			set('camOther.alpha', 1)
			setObjectCamera('comboLayer', 'hud')

			finishedTaunt = true

			altered = true
			exhausted = true
		end
	end
end

function cheer(start, spacing, repeet, saku, dancefix)
	if curBeat >= start and curBeat <= start + (spacing * repeet) then
		isInCheer = spacing == 2 or (curBeat - start) % spacing < 1
		if (curBeat - start) % spacing == 0 then
			if saku then
				objectPlayAnimation('sakuBop', 'cheer', true)
			end
			if dancefix then
				set("gf.danced", not(get("gf.danced")))
			end
			triggerEvent('Hey!', 'gf', crochet/1000)
		end
	end
end