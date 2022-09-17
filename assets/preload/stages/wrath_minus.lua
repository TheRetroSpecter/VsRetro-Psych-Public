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
		im = "wrath/"..im
	end
	makeLuaSprite(id, im, x, y)
	set(id..".active", false)
end

function makeSolid(id, width, height, color)
	makeGraphic(id, 1, 1, color)
	scaleObject(id, width, height)
end

function makeAnimSprite(id, image, x, y, spriteType)
	makeAnimatedLuaSprite(id, "wrath/"..image, x, y, spriteType)
end

local isSpectral = false
local isEctospasm = false
local isSpectspasm = false

local lSongName = ""

function onCreate()
	lSongName = string.lower(songName):gsub(" ", "-")

	isSpectral = lSongName == "spectral"
	isEctospasm = lSongName == "ectospasm" or lSongName == "ectogasm"
	isSpectspasm = (isSpectral or isEctospasm)

	if not optimize then
		setPropertyFromClass("PlayState", "currentWrath", "wrath")

		if backgroundLevel > 0 then
			--local wrathBgScale = 0.72;
			local wrathXAdjust = 0;
			local wrathYAdjust = -128;

			makeSprite('sky', 'wrath_sky', 0, 0)
			screenCenter('sky')
			setScrollFactor('sky', 0.5, 0.5)
			addRel("sky.x", wrathXAdjust)
			addRel("sky.y", wrathYAdjust + 250)
			addLuaSprite('sky')

			makeSprite('gates', 'wrath_gates', 0, 0)
			screenCenter('gates')
			setScrollFactor('gates', 0.55, 0.55)


			--66%
			--addRel("gates.x", wrathXAdjust + 550)
			--addRel("gates.y", wrathYAdjust - 150 + 400)

			--75%
			scaleObject('gates', 1.5,1.5)
			addRel("gates.x", wrathXAdjust - 555)
			addRel("gates.y", wrathYAdjust - 150 - 305)

			--100%
			--addRel("gates.x", wrathXAdjust)
			--addRel("gates.y", wrathYAdjust - 150)
			--scaleObject('gates', 1.5,1.5)
			addLuaSprite('gates')
			--[[
			makeSprite('backrocks', 'wrath_backrocks', 0, 0)
			screenCenter('backrocks')
			setScrollFactor('backrocks', 0.6, 0.6)
			addRel("backrocks.x", wrathXAdjust)
			addRel("backrocks.y", wrathYAdjust)
			addLuaSprite('backrocks')
			]]


			makeSprite('backrocks1', 'wrath_backrocks_01', 0, 0)
			screenCenter('backrocks1')
			setScrollFactor('backrocks1', 0.6, 0.6)
			addRel("backrocks1.x", wrathXAdjust-1350)
			addRel("backrocks1.y", wrathYAdjust+80)
			addLuaSprite('backrocks1')

			makeSprite('backrocks2', 'wrath_backrocks_02', 0, 0)
			screenCenter('backrocks2')
			setScrollFactor('backrocks2', 0.6, 0.6)
			addRel("backrocks2.x", wrathXAdjust+725)
			addRel("backrocks2.y", wrathYAdjust+65)
			addLuaSprite('backrocks2')


			makeAnimSprite('gem1', 'gem1', 0, 0)
			setScrollFactor('gem1', 0.6, 0.6)
			addAnimationByPrefix('gem1', "green", "green", 0, false)
			addAnimationByPrefix('gem1', "cyan", "cyan", 0, false)
			screenCenter('gem1')
			set("gem1.active", false)
			addRel("gem1.x", wrathXAdjust - 600 - 410)
			addRel("gem1.y", wrathYAdjust - 500 - 30)
			objectPlayAnimation("gem1", "green")
			addLuaSprite('gem1')


			makeAnimSprite('gem2', 'gem2', 0, 0)
			setScrollFactor('gem2', 0.7, 0.7)
			addAnimationByPrefix('gem2', "green", "green", 0, false)
			addAnimationByPrefix('gem2', "cyan", "cyan", 0, false)
			screenCenter('gem2')
			set("gem2.active", false)
			addRel("gem2.x", wrathXAdjust - 200 - 630)
			addRel("gem2.y", wrathYAdjust - 150 - 150)
			objectPlayAnimation("gem2", "green")
			addLuaSprite('gem2')

			if isSpectspasm then
				makeSprite('caveR', 'runes/cave-right', 0, 0)
			else
				makeSprite('caveR', 'wrath_cave', 0, 0)
				-- What made these values
				set("caveR.scale.x", 1.24558452481)
				set("caveR.scale.y", 1.24558452481)
			end
			screenCenter('caveR')
			setScrollFactor('caveR', 0.8, 0.8)
			addRel("caveR.x", wrathXAdjust + 126 - 1.5)
			addRel("caveR.y", wrathYAdjust + 25)
			addLuaSprite('caveR')

			makeAnimSprite('ground', 'ground', 0, 0)
			addAnimationByPrefix('ground', "green", "green", 0, false)
			addAnimationByPrefix('ground', "cyan", "cyan", 0, false)
			screenCenter('ground')
			set("ground.active", false)
			addRel("ground.x", wrathXAdjust)
			addRel("ground.y", wrathYAdjust+678)
			objectPlayAnimation("ground", "green")
			addLuaSprite('ground')

			makeSprite('minus', 'wrath_minus', 0, 0)
			screenCenter('minus')
			addRel('minus.y',-500)
			addRel('minus.x', -(get('minus.width')/2+10))
			addLuaSprite('minus')

			if lSongName == "mompoms" then
				makeAnimSprite('seperator', 'mompomsseparater', 0, 0)
				addAnimationByPrefix('seperator', 'hearts', 'dividerbitch instance 1', 24)
			else
				makeAnimSprite('seperator', 'zerketballdivider', 0, 0)
				addAnimationByPrefix('seperator', 'balls', 'dividerbitch', 24)
			end
			screenCenter('seperator')
			addRel('seperator.y', -50)
			addRel('seperator.scale.y', 0.4)
			addLuaSprite("seperator");


			makeAnimSprite('rocks', 'frontRocks_1', 0, 0)
			addAnimationByPrefix('rocks', 'green', 'green', 0, false)
			addAnimationByPrefix('rocks', 'cyan', 'cyan', 0, false)
			screenCenter('rocks')
			setScrollFactor('rocks', 1.1, 1.1)
			set("rocks.active", false)
			addRel("rocks.x", wrathXAdjust + 25)
			addRel("rocks.y", wrathYAdjust + 175)
			objectPlayAnimation("rocks", "green")


			setObjectOrder("rocks", getObjectOrder("boyfriendGroup")+1)
		end

		local isSatisfracture = lSongName == "satisfracture" or lSongName == "satisfracture-remix"
		if lSongName == "retro" or isSatisfracture or genericSongName == "fuzzy-feeling" or lSongName == "heartmelter" then
			addRel("defaultCamZoom", -0.215)
			--set('boyfriendCameraOffset', {-220,20})
		end

		if lSongName == "mompoms" then
			addRel('defaultCamZoom', -0.37);
		end
		if lSongName == "brawnstorm" then
			addRel('defaultCamZoom', -0.37);
			set("boyfriendCameraOffset", {-300, 50})
		end

		if lSongName == "fuzzy-feeling" or lSongName == "fuzziest-feeling" or lSongName == "scalie-feeling" or lSongName == "heartmelter" then
			if boyfriendName == "bf-retro" then
				set('boyfriendCameraOffset', {-5,0})
			end

			if boyfriendName == "bf-minus" then
				set('boyfriendCameraOffset', {-60,0})
			end

			if boyfriendName == "bf-ace" then
				set('boyfriendCameraOffset', {-20,0})
			end

			if boyfriendName == "bf-saku" then
				set('boyfriendCameraOffset', {-20,0})
			end
		end
		if dadName == "sakuroma" or dadName == "sakuroma-alt" then
			addRel("defaultCamZoom", -0.115)
		end
	end

	if dadName == "retro2-wrath" then
		--set("opponentCameraOffset", {0, -200})
		set("boyfriendCameraOffset", {-50, -100})
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
	if lSongName == "retro" then
		-- camFollow.y -= 64;
	end

	if dadName == "retro-wrath" then
		addDAD_X(-250)
		addDAD_Y(-50)
	elseif dadName == "retro2-wrath" then
		addDAD_X(-30)
		addDAD_Y(50)
		set('opponentCameraOffset', {40,-50})
	elseif dadName == "sakuroma" then
		--addDAD_X(-580)
		--addDAD_Y(-225)
		addDAD_X(-250 - 150)
		addDAD_Y(-100)
		set('opponentCameraOffset', {140, -40})
	elseif dadName == "sakuroma-alt" then
		--addDAD_X(-300)
		--addDAD_Y(-250)
		addDAD_X(-300)
		addDAD_Y(-75)
		set('opponentCameraOffset', {200, -40})
	end

	if gfName == "gf-wrath" then
		addGF_X(-150)
		--addGF_Y(25)
	end
	if gfName == "gf-saku-goth" then
		addGF_X(-150)
	end
	if gfName == "gf-zerktro" then
		addGF_X(-150)
		addGF_X(-5)
	end
	if gfName == "gf-ace" then
		addGF_X(-150)
	end
	if gfName == "gf-saku" then
		addGF_X(-150)
	end
	if gfName == "gf-minus" then
		addGF_X(-150)
	end

	if boyfriendName == "bf-saku" then
		addBF_Y(23)
	end

	if not(optimize) then
		makeSprite('overlay', 'wrath_overlay', 0, 0)
		screenCenter('overlay')
		setScrollFactor('overlay', 0.6, 0.6)
		setBlendMode('overlay', 'screen')
		addRel("overlay.y", -128)
		addLuaSprite("overlay", true)
	end

	set("dad.shaderEnabled", false)
end

local rockColor = false -- false = green, true = cyan

function changeColor(id)
	if rockColor then
		objectPlayAnimation(id, "cyan")
	else
		objectPlayAnimation(id, "green")
	end
end

function onStepHit()

end

function onBeatHit()

end