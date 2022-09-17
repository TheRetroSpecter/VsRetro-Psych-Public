local trackedTweens = {}
local queuedTweens = {}
local queuedLuaTweens = {} --Used mainly for tweening lua shit

--Tween Info:
-- start, tweenStartStep
-- end, tweenEndStep
-- modName, modName
-- value, to which value to tween
-- player, to which player to assign mod
-- finished, tween finished?

local activeMods = {{},{}}
local ARROW_SIZE = 112
local inds = {0,1,2,3}

local modList = {
	drift = 0,
	float = 0,
	tornado = 0,
	wave = 0,
	transX = 0,
 	rev = 0
}

for pn=1,2 do
	for k, v in pairs(modList) do
		activeMods[pn][k] = v
	end
end

-- CONSTANTS
local HIDDEN = 0.0000000001


local stepEvents = {
	{64, 'Init Receptor'},
	{80, 'Init Receptor'},
	{92, 'Init Receptor'},
	{96, 'Init Receptor'},
	{112, 'Init HUD'},
	{256, "Clap On"},
	{380, "Clap Off"},
	{392, 'Rainbow Notes On'},
	{520, 'Rainbow Notes Off'}
}
local twni = 0
local rctr = 0

--Actual code, NotITG modifiers by NotITG team with permission granted from TaroNuke, referenced modcharts by SnowTheFox
local opponentAlpha = 1
local shouldSort = false
local rainbowNotes = false --Rainbow notes
local driftMod = 0 --Drift modifier from NotITG
local floatMod = 0 --Float modifier from NotITG
local waveMod = 0 --Wave modifier from NotITG
local tornadoMod = 0 --Tornado modifier from NotITG
local figures = false --Small Figure 8s from Fuzzy Feeling
local flying = false --Modchart that happens on Fuzzy Feeling right when particles happen.
local figureEight = false -- Big Figure 8 at the end of Fuzzy Feeling
local middlePoint = 0 --Midpoint of notes, useful for middlescroll ports.
local clapping = false --Intro Clapping
local clapScale = 0 --Amount of note move on Clapping.
local clapSide = -1
local winkState = 0 -- Wink
local increment = 0 --used for elapsed
local songPos = 0
local hueStop = false

function onUpdatePost(elapsed)
	if isDead then return end
	songPos = getSongPosition()
	update(elapsed)
end

function addRel(key, val)
	setProperty(key, getProperty(key) + val)
end

function setActorY(val, i)
	setPropertyFromGroup("strumLineNotes", i, "y", val)
end
function getActorY(i)
	return getPropertyFromGroup("strumLineNotes", i, "y")
end

local ltwi = 1

function e(hajime, en, name, val, p)
	table.insert(queuedLuaTweens, ltwi, {start=hajime, owari=en, modName=name, value=val, pn=p, finished=false})
	ltwi = ltwi + 1
end

function onCreate()
	if not modcharts then
		close(true)
		return
	end
	
	opponentAlpha = 1
	if middlescroll then
		opponentAlpha = 0.35
	end
	
	setProperty('healthBarBG.alpha', HIDDEN)
	setProperty('healthBar.alpha', HIDDEN)
	setProperty('scoreTxt.alpha', HIDDEN)
	setProperty('iconP1.alpha', HIDDEN)
	setProperty('iconP2.alpha', HIDDEN)

	shouldSort = true

	for i=0,7 do
		_G['defaultStrum'..i..'X'] = 0
		_G['defaultStrum'..i..'Y'] = 0
	end

	-- Incase the script loaded after the countdown, normally it would be 0
	if getProperty("startedCountdown") then
		for i=0,3 do
			local ri = i
			_G["defaultOpponentStrumX"..ri] = getPropertyFromGroup("opponentStrums", ri, "x")
			_G["defaultOpponentStrumY"..ri] = getPropertyFromGroup("opponentStrums", ri, "y")
			_G['defaultStrum'..i..'X'] = _G["defaultOpponentStrumX"..ri]
			_G['defaultStrum'..i..'Y'] = _G["defaultOpponentStrumY"..ri]
		end
		for i=4,7 do
			local ri = i-4
			_G["defaultPlayerStrumX"..ri] = getPropertyFromGroup("playerStrums", ri, "x")
			_G["defaultPlayerStrumY"..ri] = getPropertyFromGroup("playerStrums", ri, "y")
			_G['defaultStrum'..i..'X'] = _G["defaultPlayerStrumX"..ri]
			_G['defaultStrum'..i..'Y'] = _G["defaultPlayerStrumY"..ri]
		end
	end
	--e(392, 396, 'float', 100, 1)
end

--helpers
function setNote(i, property, val)
	setPropertyFromGroup("notes", i, property, val)
end
function getNote(i, property)
	return getPropertyFromGroup("notes", i, property)
end
function addToNote(i, property, val)
	setNote(i, property, getNote(i,property)+val)
end
function setActorX(val, i)
	setPropertyFromGroup("strumLineNotes", i, "x", val)
end

function getActorX(i)
	return getPropertyFromGroup("strumLineNotes", i, "x")
end

function setActorAngle(val, i)
	setPropertyFromGroup("strumLineNotes", i, "angle", val)
end
function setActorScale(val, i)
	setPropertyFromGroup("strumLineNotes", i, "scale.x", val)
	setPropertyFromGroup("strumLineNotes", i, "scale.y", val)
end
function setActorAlpha(val, i)
	setPropertyFromGroup("strumLineNotes", i, "alpha", val)
end
function getActorAngle(i)
	return getPropertyFromGroup("strumLineNotes", i, "angle")
end
function getActorAlpha(i)
	return getPropertyFromGroup("strumLineNotes", i, "alpha")
end

function tweenPosX(id, x, time)
	noteTweenX("strumX"..id, id, x, time)
end

function tweenPosYOut(id, y, time, onComplete)
	twni = twni+1
	noteTweenY("twn"..twni.."strumY"..id, id, y, time, "cubeOut")
	if onComplete ~= nil then
		table.insert(trackedTweens, 0, {"twn"..twni.."strumY"..id, onComplete, id})
	end
end

function tweenPos(id, x, y, time, onComplete)
	twni = twni + 1
	noteTweenX("twnP"..twni.."strumPX"..id, id, x, time)
	noteTweenY("twnP"..twni.."strumPY"..id, id, y, time)

	if onComplete ~= nil then
		table.insert(trackedTweens, 0, {"twnP"..twni.."strumPX"..id, onComplete, id})
	end
end

function tweenAngle(id, angle, time)
	noteTweenAngle("strumAngle"..id, id, angle, time)
end
function setHudPosition(x, y)
	setProperty("camHUD.x", x)
	setProperty("camHUD.y", y)
end
function setCamPosition(x, y)
	setProperty("camGame.x", x)
	setProperty("camGame.y", y)
end
function tweenFadeIn(id, alpha, time)
	noteTweenAlpha("strumFade"..id, id, alpha, time, "circIn")
end
function tweenFadeOut(id, alpha, time, onComplete)
	twni = twni + 1
	noteTweenAlpha("twn"..twni.."strumFade"..id, id, alpha, time, "circOut")

	if onComplete ~= nil then
		table.insert(trackedTweens, 0, {"twn"..twni.."strumFade"..id, onComplete, id})
	end
end
function tweenPosXIn(id, x, time)
	noteTweenX("strumXin"..id, id, x, time, "cubeIn")
end
function tweenPosYIn(id, y, time)
	noteTweenY("strumYin"..id, id, y, time, "cubeIn")
end
function tweenAngleIn(id, angle, time)
	noteTweenAngle("strumAnglein"..id, id, angle, time, "cubeIn")
end
function tweenPosXAngleIn(id, x, angle, time)
	noteTweenX("strumXin"..id, id, x, time, "cubeIn")
	noteTweenAngle("strumAnglein"..id, id, angle, time, "cubeIn")
end
function tweenPosYAngleIn(id, y, angle, time)
	noteTweenY("strumYin"..id, id, y, time, "cubeIn")
	noteTweenAngle("strumAnglein"..id, id, angle, time, "cubeIn")
end
function setHudZoom(zoom)
	setProperty("camHUD.zoom", zoom)
end

function onTweenCompleted(tag)
	if #trackedTweens ~= 0 then
		for i = #trackedTweens,1,-1 do
			if trackedTweens[i][1] == tag then
				local trackedTag = table.remove(trackedTweens, i)
				local trackedTagFunc = trackedTag[2]
				--debugPrint("removed callback "..trackedTag[1])
				_G[trackedTagFunc](trackedTag[3])
				return
			end
		end
	end
end

function arrowEffects(y, col, pn) --Necessary for hold angles

	local m = activeMods[pn]
	local c = (pn-1)*4 + col
	
	local xpos, ypos = 0, 0
	
	if clapping then
		ypos = ypos + getActorY(c) - _G['defaultStrum'..c..'Y']
	end
	
	if flying then
	end
	
	if figures then
	end
	
	if m.drift ~= 0 then
		xpos = xpos + m.drift * (math.cos(songPos*0.001+col*0.2+0.2+y*10/720) * ARROW_SIZE*0.5)
	end
	
	if m.float ~= 0 then
		ypos = ypos + m.float * (math.cos(songPos*0.001*1.2+col*2+0.2) * ARROW_SIZE*0.4)
	end
	
	if m.tornado ~= 0 then
		local iCol = col % 4
		local shit = iCol * math.pi / 3
		local phase = y/135
		local zeroer = (-math.cos(-shit)+1)/2*ARROW_SIZE*3
		local xOff = (-math.cos(phase-shit)+1)/2*ARROW_SIZE*3 - zeroer
		xpos = xpos + xOff * m.tornado
	end
	
	return xpos, ypos
end

function tweenLua(t, elapsed)
	-- hajime, start step
	-- owari, end step
	-- modName, name of mod from modList
	-- value, value to tween to 
	local m = activeMods[t.pn]
	local dur = (t.owari-t.start)*stepCrochet/1000
	local timeLeft = dur
	local str = 0
	
	timeLeft = timeLeft - elapsed
	str = str + elapsed
	
	local ratio = str / dur
	local vRatio = t.value + (m[t.modName]-t.value) * ratio
	
	m[t.modName] = vRatio
	
	if timeLeft <= 0 then
		t.finished = true
		m[t.modName] = t.value
		local tween = table.remove(queuedLuaTweens, 1)
	end
end

function getYOffset(y, col, pn)
	local m = activeMods[pn]
	
	local yadj = 0
	
	if m.wave ~= 0 then
		yadj = yadj + m.wave*20*math.sin((y+250/76))
	end
	
	y = y+yadj
	
	return y
end

function onCountdownStarted()
	for i=0,3 do
		local ri = i
		_G['defaultStrum'..i..'X'] = _G["defaultOpponentStrumX"..ri]
		_G['defaultStrum'..i..'Y'] = _G["defaultOpponentStrumY"..ri]
	end
	for i=4,7 do
		local ri = i-4
		_G['defaultStrum'..i..'X'] = _G["defaultPlayerStrumX"..ri]
		_G['defaultStrum'..i..'Y'] = _G["defaultPlayerStrumY"..ri]
	end

	--start()
end

local isDead = false

function onGameOver()
	isDead = true
end


function update(elapsed)
	increment = elapsed
	if shouldSort then
		table.sort(stepEvents, function(a,b) return a[1] < b[1] end)
		table.sort(queuedLuaTweens, function(a,b) return a['start'] < b['start'] end)
		shouldSort = false
	end
	local currentBeat = (songPos / 1000)*(bpm/60)

	while (0 < #stepEvents and curStep >= stepEvents[0+1][0+1]) do
		local event = table.remove(stepEvents, 1)[1+1]
		triggerEvent(event, "", "")
	end
	
	while (0 < #queuedLuaTweens and curStep >= queuedLuaTweens[1]) do
		tweenLua(queuedLuaTweens[1], elapsed);
	end
	
	if not noteInit then
		for i=0,7 do
			setActorY(getActorY(i)+720,i)
		end
		noteInit = true
	end
	
	if curStep >= 392 then
		activeMods[1]['float'] = 1
	end
	
	if curStep >= 391 then --NotITG effects start at step 391
		
		for pn=1,2 do
			for col=0,3 do
				local c = (pn-1)*4 + col
				local defaultx, defaulty = _G['defaultStrum'..c..'X'],_G['defaultStrum'..c..'Y']
				local xp, yp = arrowEffects(0, col, pn)
				
				setActorX(defaultx+xp, c)
				setActorY(defaulty+yp, c)
			end
		end
	
		for i = 0,getProperty("notes.members.length")-1 do
			local speed = scrollSpeed
			local pn = 1
			if getNote(i, "mustPress") then pn = 2 end
			local m = activeMods[pn]
			local isSus = getNote(i, "isSustainNote")
			local holdOffset = 0
			
			local rMult = 1-(2*m.rev)
			local col = getNote(i, "noteData")
			local c = (pn-1)*4 + col
			local targTime = getNote(i, 'strumTime')
			local defaultx, defaulty = _G['defaultStrum'..c..'X'],_G['defaultStrum'..c..'Y']
			
			local strumDirect = getPropertyFromGroup('strumLineNotes', c, 'direction') * math.pi/180
			--print('updating')
			local distance = math.sin(strumDirect) * speed * 0.45 * rMult
			local off = noteOffset * rMult
			
			
			local ypos = getYOffset(defaulty -(songPos - targTime),col,pn) * distance - off
			local xa, ya = arrowEffects(ypos-defaulty,col,pn)
			
			if rainbowNotes and flashingLights then
				addToNote(i, 'colorSwap.hue', elapsed)
				addToNote(i, "noteSplashHue", elapsed)
				addToNote(i, 'ratingMod', elapsed)
			end
			
			--if not rainbowNotes then
			--	setNote(i, 'colorSwap.hue', -getNote(i, 'ratingMod')%1+elapsed)
			--end
			
			local totalHue = getNote(i, "ratingMod") % 1
			if hueStop and not rainbowNotes then
				if totalHue > 0 then
					addToNote(i, "colorSwap.hue", -elapsed*2)
					addToNote(i, "noteSplashHue", -elapsed*2)
					addToNote(i, "ratingMod", -elapsed*2)
					totalHue = totalHue - elapsed*2
				
					if totalHue < 0 then
						addToNote(i, "colorSwap.hue", -totalHue)
						addToNote(i, "noteSplashHue", -totalHue)
						addToNote(i, "ratingMod", -totalHue)
					end
				end
			end

			
			if isSus then
				local ypos2 = getYOffset(defaulty -(songPos + 0.1 - targTime),col,pn) * distance - off
				local xa2, ya2 = arrowEffects(ypos2-defaulty,col,pn)
				holdOffset = getNote(i, "holdOffsetX")
				setNote(i, 'angle', math.deg(math.atan2(((ypos2+ya2)-(ypos+ya))*100,(xa2-xa)*100)+math.pi/2))
			end
			
			
			setNote(i,'x',defaultx+xa+holdOffset)
			setNote(i,'y',ypos+ya)
			
		end
	end
	--if (driftMod == 0 and tornadoMod == 0) then return end --Stop the function before individual notes are modified
end

function onEvent(name)
	if name == 'Clap On' then
		clapping = true
	elseif name == 'Clap Off' then
		clapping = false
	elseif name == 'Small Figure Eight On' then
		figures = true
	elseif name == 'Small Figure Eight Off' then
		figures = false
	elseif name == 'Flying Figure Eight On' then
		flying = true
	elseif name == 'Flying Figure Eight Off' then
		flying = false
	elseif name == 'Init Receptor' then
		local man = 7-rctr
		tweenPosYOut(rctr, _G['defaultStrum'..rctr..'Y'], crochet*4/1000)
		tweenPosYOut(man, _G['defaultStrum'..man..'Y'],  crochet*4/1000)
		rctr = rctr + 1
	elseif name == 'Init HUD' then
		doTweenAlpha('barBG', 'healthBarBG', healthBarAlpha, 0.5, 'linear')
		doTweenAlpha('bar', 'healthBar', healthBarAlpha, 0.5, 'linear')
		doTweenAlpha('icon1', 'iconP1', healthBarAlpha, 0.5, 'linear')
		doTweenAlpha('icon2', 'iconP2', healthBarAlpha, 0.5, 'linear')
		doTweenAlpha('score', 'scoreTxt', 1, 0.5, 'linear')
	elseif name == 'Rainbow Notes On' then
		rainbowNotes = true
		hueStop = false
	elseif name == 'Rainbow Notes Off' then
		rainbowNotes = false
		hueStop = true
		--for i = 0,getProperty("notes.members.length")-1 do
		--	setNote(i, 'ratingMod', getNote(i, 'ratingMod') % 1)
		--end
	end
end

function ToCenterShit()
	for i=0,7 do
		tweenPosXIn(i, _G['defaultStrum'..i..'X'], crochet/1000/2)
		tweenPosYIn(i, _G['defaultStrum'..i..'Y'], crochet/1000/2)
		tweenAngleIn(i, getActorAngle(i), crochet/1000/2)
	end
end

function onBeatHit()
	if clapping then
		clapScale = clapScale + 2.3
		inds = {0,1,2,3}
		local rcp1i = math.random(1,4)
		local rcp2i = math.random(1,3)
		local num1get = table.remove(inds, rcp1i)
		local num2get = table.remove(inds, rcp2i)
		local num3get = num1get+4
		local num4get = num2get+4
		tweenPosYOut(num1get, _G['defaultStrum'..num1get..'Y']+clapScale*clapSide, crochet/1000/2, 'ToCenterShit')
		tweenPosYOut(num2get, _G['defaultStrum'..num2get..'Y']+clapScale*clapSide, crochet/1000/2, 'ToCenterShit')
		tweenPosYOut(num3get, _G['defaultStrum'..num3get..'Y']+clapScale*clapSide, crochet/1000/2, 'ToCenterShit')
		tweenPosYOut(num4get, _G['defaultStrum'..num4get..'Y']+clapScale*clapSide, crochet/1000/2, 'ToCenterShit')
		clapSide = -clapSide
	end
end