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
function makeSprite(id, image, x, y)
	local im = image
	if im ~= "" then
		im = "iceolation/"..im
	end
	makeLuaSprite(id, im, x, y)
	set(id..".active", false)
end

function makeSolid(id, width, height, color)
	makeGraphic(id, 1, 1, color)
	scaleObject(id, width, height)
end

function makeAnimSprite(id, image, x, y, spriteType)
	makeAnimatedLuaSprite(id, "iceolation/"..image, x, y, spriteType)
end

function setVelocity(tag, x, y)
	setProperty(tag..".velocity.x", x)
	setProperty(tag..".velocity.y", y)
end

function makeSnow(tag, image, velx, vely)
	local im = image
	if im ~= "" then
		im = "iceolation/"..im
	end
	makeBackdrop(tag, im)
	setScrollFactor(tag, 0.2, 0)
	setVelocity(tag, velx, vely)
	screenCenter(tag)
	set(tag..'.alpha', 1)
	set(tag..".camZoom", 0.5)
end

local lSongName = ""

function onCreate()
	lSongName = string.lower(songName):gsub(" ", "-")

	setPropertyFromClass("PlayState", "currentWrath", "")

	if backgroundLevel > 0 then
		makeSprite('bg', 'IceBG1', -1594, -1560)
		setScrollFactor('bg', 0.9, 0.9)
		addLuaSprite('bg')

		makeSprite('snowlight', 'snowbridge1', -1589, -1558)
		setScrollFactor('snowlight', 0.9, 0.9)
		addLuaSprite('snowlight')

		makeSprite('snow', 'IceBridge1', -1594, -1560)
		setScrollFactor('snow', 0.9, 0.9)
		addLuaSprite('snow')

		makeSprite('fg', 'snowforeground1', -1588, -1559)
		setScrollFactor('fg', 0.9, 0.9)
		addLuaSprite('fg', true)

		makeSprite('icefg', 'IceForeground1', -1588, -1559)
		setScrollFactor('icefg', 0.9, 0.9)
		addLuaSprite('icefg', true)

		--set("snowlight.alpha", HIDDEN)
		--set("fg.alpha", HIDDEN)
		set("snow.alpha", HIDDEN)
		set("icefg.alpha", HIDDEN)
	end
end

function addBF_X(val)
	addRel("BF_X", val)
	set("boyfriendGroup.x", get("BF_X"))
end
function addBF_Y(val)
	addRel("BF_Y", val)
	set("boyfriendGroup.y", get("BF_Y"))
end

function addGF_X(val)
	addRel("GF_X", val)
	set("gfGroup.x", get("GF_X"))
end
function addGF_Y(val)
	addRel("GF_Y", val)
	set("gfGroup.y", get("GF_Y"))
end

function addDAD_X(val)
	addRel("DAD_X", val)
	set("dadGroup.x", get("DAD_X"))
end
function addDAD_Y(val)
	addRel("DAD_Y", val)
	set("dadGroup.y", get("DAD_Y"))
end

function onCreatePost()
	local hasSnowEvents = true

	for i = 0, getProperty("eventNotes.length")-1 do
		local name = getPropertyFromGroup("eventNotes", i, "event")
		if name == "Weak Snow" then
			hasSnowEvents = true
		end
		if name == "Mid Snow" then
			hasSnowEvents = true
		end
		if name == "Strong Snow" then
			hasSnowEvents = true
		end
		if name == "Snowstorm" then
			hasSnowEvents = true
		end
		if name == "Strongest Snow" then
			hasSnowEvents = true
		end
	end

	if hasSnowEvents and backgroundLevel > 1 then
		-- Backdrops
		makeSnow('snowfgweak', 'weak', 100, 110)
		makeSnow('snowfgweak2', 'weak2', -100, 110)
		makeSnow('snowfgmid', 'mid', 400, 210)
		makeSnow('snowfgmid2', 'mid2', -400, 210)
		makeSnow('snowfgstrong', 'strong', 900, 410)
		makeSnow('snowfgstrong2', 'strong2', -900, 410)
		makeSnow('snowstorm', 'storm', -5000, 0)
		makeSnow('snowstorm2', 'storm2', -3700, 0)
		makeSnow('snowstorm3', 'storm', -2800, 0)
		makeSnow('snowfgstrongest', 'strongest', -1100, 500)

		set('snowstorm.repeatX', true)
		set('snowstorm.repeatY', false)

		set('snowstorm3.repeatX', true)
		set('snowstorm3.repeatY', false)

		addBackdrop('snowfgweak', true)
		addBackdrop('snowfgweak2', true)

		addBackdrop('snowfgmid', true)
		addBackdrop('snowfgmid2', true)

		addBackdrop('snowfgstrong', true)
		addBackdrop('snowfgstrong2', true)

		addBackdrop('snowstorm', true)
		addBackdrop('snowstorm2', true)
		addBackdrop('snowstorm3', true)

		set("snowstorm.alpha", HIDDEN)
		set("snowstorm2.alpha", HIDDEN)
		set("snowstorm3.alpha", HIDDEN)

		set("snowfgstrong.alpha", HIDDEN)
		set("snowfgstrong2.alpha", HIDDEN)

		set("snowfgstrongest.alpha", HIDDEN)

		addRel('snowstorm.y', -580)
		addRel('snowstorm3.y', -580)

		addBackdrop('snowfgstrongest', true)
	end
end

function onEvent(ev, v1, v2)
	if ev == "Weak Snow" then
		local alpha = tonumber(v1)
		local time = tonumber(v2)
		if time <= 0 then
			set("snowfgweak.alpha", alpha)
			set("snowfgweak2.alpha", alpha)
		else
			doTweenAlpha('weak1', 'snowfgweak', alpha, time)
			doTweenAlpha('weak2', 'snowfgweak2', alpha, time)
		end
	elseif ev == "Mid Snow" then
		local alpha = tonumber(v1)
		local time = tonumber(v2)
		if time <= 0 then
			set("snowfgmid.alpha", alpha)
			set("snowfgmid2.alpha", alpha)
		else
			doTweenAlpha('mid1', 'snowfgmid', alpha, time)
			doTweenAlpha('mid2', 'snowfgmid2', alpha, time)
		end
	elseif ev == "Snowstorm" then
		local alpha = tonumber(v1)
		local time = tonumber(v2)
		if time <= 0 then
			set("snowstorm.alpha", alpha)
			set("snowstorm2.alpha", alpha)
			set("snowstorm3.alpha", alpha)
		else
			doTweenAlpha('storm1', 'snowstorm', alpha, time)
			doTweenAlpha('storm2', 'snowstorm2', alpha, time)
			doTweenAlpha('storm3', 'snowstorm3', alpha, time)
		end
	elseif ev == "Strong Snow" then
		local alpha = tonumber(v1)
		local time = tonumber(v2)
		if time <= 0 then
			set("snowfgstrong.alpha", alpha)
			set("snowfgstrong2.alpha", alpha)
		else
			doTweenAlpha('strong1', 'snowfgstrong', alpha, time)
			doTweenAlpha('strong2', 'snowfgstrong2', alpha, time)
		end
	elseif ev == "Strongest Snow" then
		local alpha = tonumber(v1)
		local time = tonumber(v2)
		if time <= 0 then
			set("snowfgstrongest.alpha", alpha)
		else
			doTweenAlpha('strong3', 'snowfgstrongest', alpha, time)
		end
	elseif ev == "Snowy Stage" then
		set("snowlight.alpha", HIDDEN)
		set("fg.alpha", HIDDEN)
		set("snow.alpha", 1)
		set("icefg.alpha", 1)
	end
end

--[[local toggle = true
local focus = true

function onUpdate(elapsed)
	if keyPressed("left") then
		toggle = true
	end
	if keyPressed("right") then
		toggle = false
	end
	if keyPressed("up") then
		focus = false
	end
	if keyPressed("down") then
		focus = true
	end

	set("cameraMoving", not focus)
	set("camZooming", not focus)
	set("isCameraOnForcedPos", focus)

	if focus then
		if toggle then
			set("camFollowPos.x", -700)
			set("camFollowPos.y", 296 - 510)
			set("camFollow.x", -700)
			set("camFollow.y", 296 - 510)
		else
			set("camFollowPos.x", 2200)
			set("camFollowPos.y", 500)
			set("camFollow.x", 2200)
			set("camFollow.y", 500)
		end

		set("camGame.zoom", 0.7)
	end
end]]

--function onUpdatePost(elapsed)
--	
--end

--function onStepHit()
--	
--end

--function onBeatHit()
--	if curBeat % 2 == 0 then
--		
--	end
--end