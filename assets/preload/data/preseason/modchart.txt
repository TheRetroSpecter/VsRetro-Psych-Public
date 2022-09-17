local notemoe = false
local defHUDx = 0
local defHUDy = 0
local hudyadd = -600
local camtog = 1
function start(song)
	ToCenterShit()
	defHUDx = getHudX()
	defHUDy = getHudY()
	setHudPosition(defHUDx,defHUDy+hudyadd)
end

function update(elapsed)
	local currentBeat = (songPos / 1000)*(bpm/60)
	if not notemoe then
		for i=0,7 do
			setActorX(_G['defaultStrum'..i..'X'] + 6 * math.sin((currentBeat + i*0.2) * math.pi), i)
		end
	elseif notemoe then
		for i=0,3 do
			setActorX(_G['defaultStrum'..i..'X'] + 6 * math.sin((currentBeat + i*0.2) * math.pi), i)
		end
	end


	if curStep == 384 or curStep == 1023 then
		notemoe = true
	end

	if curStep == 768 or curStep == 1280 then
		notemoe = false
	end

	if (curStep == 123) then
		tweenHudPos(defHUDx,defHUDy,0.3)
	end
end

function beatHit (beat)
	if (beat % 4 == 0) then
		if notemoe then
			timezoomshit = 0.1
			if camtog == 1 then
				tweenCameraZoomIn(cameraZoom-0.02, timezoomshit)
			elseif camtog == -1 then
				tweenCameraZoomOut(cameraZoom+0.02, timezoomshit)
			end
			camtog = camtog*-1
		end
	end
end

function playerOneSing(data)
	if notemoe then
	noteburst(data+4)
	end
end

function playerTwoSing(data)
	--noteburst(data)
end




-- stupid functions

function noteburst(leid)
	notebump(leid,10)
	--notebump(leid-1,20)
	---notebump(leid+1,20)
	---notebump(leid+2,10)
	--notebump(leid-2,10)
end

function notebump(leid,strength)
	isopp = checkside(leid)
	if (leid >= 0 or leid < 4) and isopp == false or (leid >= 4 or leid < 8) and isopp == true then
		for i=leid,leid do
		tweenPos(i, _G['defaultStrum'..i..'X'], _G['defaultStrum'..i..'Y']+strength, 0.05, 'ToCenterShit')
		end
	end
end


function checkside(leid) -- checks if enemy(true) or player(false)
	if (leid >= 0 or leid < 4) then
		return true
	elseif (leid >= 4 or leid < 8) then 
		return false
	end
end

function setDefault(id)
	setActorAngle(0,id)
	_G['defaultStrum'..id..'X'] = getActorX(id)
end

function ToCenterShit()
	for i=0,7 do
	tweenPosXAngleIn(i, _G['defaultStrum'..i..'X'], getActorAngle(i), 0.25)
	tweenPosYAngleIn(i, _G['defaultStrum'..i..'Y'], getActorAngle(i), 0.25)
	end
end