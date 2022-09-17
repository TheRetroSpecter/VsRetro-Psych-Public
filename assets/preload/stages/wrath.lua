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

local isCorruptro = false

function makeSprite(id, image, x, y)
	local im = image
	if im ~= "" then
		if isCorruptro and imageExists("wrath/"..im.."_corrupt") then
			im = "wrath/"..im.."_corrupt"
		else
			im = "wrath/"..im
		end
	end
	makeLuaSprite(id, im, x, y)
	set(id..".active", false)
end

function makeSolid(id, width, height, color)
	makeGraphic(id, 1, 1, color)
	scaleObject(id, width, height)
end

function makeAnimSprite(id, image, x, y, spriteType)
	local im = image
	if im ~= "" then
		if isCorruptro and imageExists("wrath/"..im.."_corrupt") then
			im = "wrath/"..im.."_corrupt"
		else
			im = "wrath/"..im
		end
	end
	makeAnimatedLuaSprite(id, im, x, y, spriteType)
end

local isSpectral = false
local isEctospasm = false
local isSpectspasm = false

local crystals = {}
local crystalPos = {
	{1600, 200},
	{1200, -100},
	{1400, -500},
	{800, -150},
	{-900, 0},
	{550, -200},
	{-300, -300},
	{100, -200}
}

local crystalFloatData = {
	{1500, 1},
	{2000, 0},
	{1000, 2},
	{2500, 1.5},
	{3000, 4},
	{1000, 3},
	{2500, 6},
	{2000, 2.5}
}

local runesCanGlow = false
local lSongName = ""
local isCrackVisible = true

function onCreate()
	lSongName = string.lower(songName):gsub(" ", "-")

	isCorruptro = lSongName == "corruptro"
	isSpectral = lSongName == "spectral"
	isEctospasm = lSongName == "ectospasm" or lSongName == "ectogasm"
	isSpectspasm = (isSpectral or isEctospasm) or isCorruptro

	if isCorruptro then
		set("hideGF", true)
		isStoryMode = false
	end

	if gfName == 'gf-zerktro' then
		set('cameraStartDad', true)
	end

	if not optimize then
		setPropertyFromClass("PlayState", "currentWrath", "wrath")
		if isCorruptro then
			setPropertyFromClass("PlayState", "currentWrath", "corruptro")
			isCrackVisible = false
		end

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
			if isCorruptro then
				setColorSwapShader("sky", 180, -40)
			end

			if backgroundLevel > 1 and isSpectspasm then
				makeAnimSprite('vortex', 'Vortex', 0, 0)
				scaleObject('vortex', 1/0.5, 1/0.5)
				setScrollFactor('vortex', 0.5, 0.5)
				addAnimationByPrefix('vortex', "speeen", "Vortex", 24)
				addRel("vortex.x", -100)
				addRel("vortex.y", -750)
				if (isStoryMode and not seenCutscene and firstTry) or isCorruptro then
					set("vortex.alpha", HIDDEN)
				end
				objectPlayAnimation("vortex", "speeen", true)
				if not motion then
					objectStopAnimation("vortex") -- (Arcy) Would be better to not make it an animated sprite, but some internal code messes up scaling and offsets
				end
				addLuaSprite('vortex')
				if isCorruptro then
					setColorSwapShader("vortex", 160, 25)
				end
			end

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
			if isCorruptro then
				setColorSwapShader("gem1", 180, -40)
			end


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
			if isCorruptro then
				setColorSwapShader("gem2", 180, -40)
			end

			if isSpectspasm then
				makeSprite('spectralDarkScreen', '', -1000, -1500)
				makeSolid("spectralDarkScreen", 4000, 3000, "0xFF000000")
				set("spectralDarkScreen.alpha", 0)
				addLuaSprite('spectralDarkScreen')

				if backgroundLevel > 1 then
					makeAnimSprite('flames', 'flames_colorchange', 0, 0)
					addAnimationByPrefix('flames', "greenFlame", "Symbol 1 Instanz 1", 24)
					screenCenter('flames')
					set("flames.scale.x", 1.6)
					set("flames.scale.y", 1.5)
					setScrollFactor('flames', 0.7, 0.7)
					addRel("flames.x", wrathXAdjust - 250)
					if (isStoryMode and not seenCutscene and firstTry) or isCorruptro then
						addRel("flames.y", wrathYAdjust + 1200)
						set("flames.alpha", HIDDEN)
					else
						addRel("flames.y", wrathYAdjust + 200)
					end
					objectPlayAnimation("flames", "greenFlame")
					addLuaSprite('flames')
					if isCorruptro then
						setColorSwapShader("flames", 180, -40)
					end

					--[[makeAnimSprite('flamesA', 'flames_colorchange', 0, 0)
					addAnimationByPrefix('flamesA', "greenFlame", "Symbol Ett", 24)
					screenCenter('flamesA')
					set("flamesA.scale.x", 1.6)
					set("flamesA.scale.y", 1.5)
					setScrollFactor('flamesA', 0.7, 0.7)
					addRel("flamesA.x", wrathXAdjust - 250)
					if isStoryMode and firstTry then
						addRel("flamesA.y", wrathYAdjust + 1200)
						set("flamesA.alpha", HIDDEN)
					else
						addRel("flamesA.y", wrathYAdjust + 200)
					end
					objectPlayAnimation("flamesA", "greenFlame")
					addLuaSprite('flamesA')]]

					--setAmongUsShader("flamesA", "#7bf9a8", "#73ff57", "#19f274")

					if flashingLights then
						makeAnimSprite('flamesChange', 'flames_colorchange', 0, 0)
						addAnimationByPrefix('flamesChange', "blueFlame", "Symbol 2 Instanz 1", 24)
						screenCenter('flamesChange')
						set("flamesChange.scale.x", 1.6)
						set("flamesChange.scale.y", 1.5)
						setScrollFactor('flamesChange', 0.7, 0.7)
						addRel("flamesChange.x", wrathXAdjust - 250)
						addRel("flamesChange.y", wrathYAdjust + 200)
						set("flamesChange.alpha", HIDDEN)
						objectPlayAnimation("flamesChange", "blueFlame")
						addLuaSprite('flamesChange')
						if isCorruptro then
							setColorSwapShader("flamesChange", 180, -40)
						end
					end
				end

				if isSpectspasm and gfName ~= "gf-saku" and boyfriendName ~= "bf-saku" and not isCorruptro then
					makeAnimSprite('sakuBop', 'SakuBop', 0, 0)
					addAnimationByPrefix('sakuBop', 'bop', 'SakuBop', 24, false)
					screenCenter('sakuBop')
					addRel("sakuBop.x", 690-30)
					addRel("sakuBop.y", -70+5)
					if isSpectral then
						set("sakuBop.alpha", HIDDEN)
					end
					setScrollFactor('sakuBop', 0.8, 0.8)
					addLuaSprite('sakuBop')
				end
			end

			-- cave 1
			--[[if isSpectspasm and backgroundLevel > 1 then
				makeAnimSprite('cave', 'runes_glow', 0, 0)
				addAnimationByPrefix('cave', "glow", "Glow", 24, false)
				addAnimationByPrefix('cave', "cave", "Cave", 24, false)

				if isStoryMode and firstTry then
					objectPlayAnimation("cave", "cave")
				else
					objectPlayAnimation("cave", "glow")
				end

				runesCanGlow = true
			elseif isSpectspasm and (not isStoryMode) and backgroundLevel == 1 then
				makeSprite('cave', 'wrath_runes', 0, 0)
			else
				makeSprite('cave', 'wrath_cave', 0, 0)
			end
			screenCenter('cave')
			setScrollFactor('cave', 0.8, 0.8)
			addRel("cave.x", wrathXAdjust - 317)
			addRel("cave.y", wrathYAdjust + 81)
			set("cave.flipX", true)
			addLuaSprite('cave')]]

			if isSpectspasm then
				makeSprite('caveL', 'runes/cave-left', 0, 0)
			else
				makeSprite('caveL', 'wrath_cave', 0, 0)
			end
			screenCenter('caveL')
			setScrollFactor('caveL', 0.8, 0.8)
			addRel("caveL.x", wrathXAdjust - 317)
			addRel("caveL.y", wrathYAdjust + 81)
			set("caveL.flipX", true)
			addLuaSprite('caveL')

			if isCorruptro then
				makeSprite('caveLGoop', 'wrath_cave_corruptgoop', 0, 0)
				screenCenter('caveLGoop')
				setScrollFactor('caveLGoop', 0.8, 0.8)
				addRel("caveLGoop.x", wrathXAdjust - 317)
				addRel("caveLGoop.y", wrathYAdjust + 81)
				set("caveLGoop.flipX", true)
				addLuaSprite('caveLGoop')
			end

			if isSpectspasm and backgroundLevel > 1 then
				runesCanGlow = true

				makeSprite('runesL', 'runes/runes-left', 0, 0)
				screenCenter('runesL')
				setScrollFactor('runesL', 0.8, 0.8)
				set("runesL.flipX", true)
				addRel("runesL.x", wrathXAdjust -686)
				addRel("runesL.y", wrathYAdjust + 450)
				scaleObject("runesL", 0.53, 0.53)
				addLuaSprite('runesL')

				if isCorruptro then
					setColorSwapShader("runesL", 180, 0)
				end

				for i = 1,2 do
					local id = 'glowL' .. i
					makeSprite(id, 'runes/runeGlow-left', 0, 0)
					screenCenter(id)
					setScrollFactor(id, 0.8, 0.8)
					set(id..".flipX", true)
					addRel(id..".x", wrathXAdjust -686)
					addRel(id..".y", wrathYAdjust + 450)
					scaleObject(id, 0.53, 0.53)
					addLuaSprite(id)
					if isCorruptro then
						setColorSwapShader(id, 180,  0)
					end
				end
			end

			if isCorruptro then
				makeSprite('caveLGoop', 'wrath_cave_corruptgoop', 0, 0)
				screenCenter('caveLGoop')
				setScrollFactor('caveLGoop', 0.8, 0.8)
				addRel("caveLGoop.x", wrathXAdjust - 317)
				addRel("caveLGoop.y", wrathYAdjust + 81)
				set("caveLGoop.flipX", true)
				addLuaSprite('caveLGoop')
			end

			-- cave 2
			--[[if isSpectspasm and backgroundLevel > 1 then
				makeAnimSprite('cave2', 'runes_glow2', 0, 0)
				addAnimationByPrefix('cave2', "glow", "Glow", 24, false)
				addAnimationByPrefix('cave2', "cave", "Cave", 24, false)

				if isStoryMode and firstTry then
					objectPlayAnimation("cave2", "cave")
				else
					objectPlayAnimation("cave2", "glow")
				end
			elseif isSpectspasm and (not isStoryMode) and backgroundLevel == 1 then
				makeSprite('cave2', 'wrath_runes2', 0, 0)
			else
				makeSprite('cave2', 'wrath_cave', 0, 0)
				-- What made these values
				set("cave2.scale.x", 1.24558452481)
				set("cave2.scale.y", 1.24558452481)
			end
			screenCenter('cave2')
			setScrollFactor('cave2', 0.8, 0.8)
			addRel("cave2.x", wrathXAdjust + 126)
			addRel("cave2.y", wrathYAdjust + 25)
			addLuaSprite('cave2')]]


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

			if isSpectspasm and backgroundLevel > 1 then
				makeSprite('runesR', 'runes/runes-right', 0, 0)
				screenCenter('runesR')
				setScrollFactor('runesR', 0.8, 0.8)
				addRel("runesR.x", wrathXAdjust + 1246 + 115)
				addRel("runesR.y", wrathYAdjust + -120 + 325)
				scaleObject("runesR", 0.65, 0.65)
				addLuaSprite('runesR')

				if isCorruptro then
					setColorSwapShader("runesR", 180, 0)
				end

				for i = 1,2 do
					local id = 'glowR' .. i

					makeSprite(id, 'runes/runeGlow-right', 0, 0)
					screenCenter(id)
					setScrollFactor(id, 0.8, 0.8)
					addRel(id..".x", wrathXAdjust + 1246 + 115)
					addRel(id..".y", wrathYAdjust + -120 + 325)
					scaleObject(id, 0.65, 0.65)
					addLuaSprite(id)
					if isCorruptro then
						setColorSwapShader(id, 180, 0)
					end
				end
			end

			if isCorruptro then
				makeSprite('caveRGoop', 'wrath_cave_corruptgoop', 0, 0)
				set("caveRGoop.scale.x", 2818/2376)
				set("caveRGoop.scale.y", 1726/1455)
				screenCenter('caveRGoop')
				setScrollFactor('caveRGoop', 0.8, 0.8)
				addRel("caveRGoop.x", wrathXAdjust + 126 - 1.5)
				addRel("caveRGoop.y", wrathYAdjust + 25)
				addLuaSprite('caveRGoop')
			end

			if flashingLights and isStoryMode and isSpectral then
				makeSprite('bgFlash', '', -1250, -100)
				makeSolid("bgFlash", 3000, 1000, "0xFFffffff")
				set("bgFlash.active", false)
				set("bgFlash.visible", false)
				addLuaSprite('bgFlash')
			end

			if backgroundLevel > 1 and isSpectspasm then
				for i=0,8-1 do
					local id = "crystal"..tostring(i)
					makeAnimSprite(id, 'Crystals', 0, 0)
					addAnimationByPrefix(id, 'idle', 'Crystal' .. tostring(i), 24)
					set(id..".x", crystalPos[i+1][1])
					set(id..".y", crystalPos[i+1][2])
					setScrollFactor(id, 0.9, 0.9)
					objectPlayAnimation(id, "idle")
					if (isStoryMode and not seenCutscene and firstTry) or isCorruptro then
						set(id..".alpha", HIDDEN)
						addRel(id..".y", 1500)
					end
					if isCorruptro then
						setColorSwapShader(id, 180, -40)
					end
					addLuaSprite(id)
					table.insert(crystals, id)
				end
			end

			makeAnimSprite('ground', 'ground', 0, 0)
			addAnimationByPrefix('ground', "green", "green", 0, false)
			addAnimationByPrefix('ground', "cyan", "cyan", 0, false)
			screenCenter('ground')
			set("ground.active", false)
			addRel("ground.x", wrathXAdjust)
			addRel("ground.y", wrathYAdjust+678)
			objectPlayAnimation("ground", "green")
			addLuaSprite('ground')

			if isSpectspasm then
				makeAnimSprite('crack', 'HellCrack', 0, 0)
				addAnimationByPrefix('crack', 'appear', 'HellcrackAppear', 24, false)
				addAnimationByPrefix('crack', 'bop', 'HellcrackBop', 24, false)
				screenCenter('crack')
				set("crack.active", false) -- To stop it from playing
				addRel("crack.x", 70-50)
				addRel("crack.y", 375+30)
				setObjectOrder("crack", getObjectOrder("dadGroup"))
				if isCorruptro then
					setColorSwapShader("crack", 180, -40)
				elseif not (isStoryMode and not seenCutscene and firstTry) then
					objectPlayAnimation('bop')
					set("crack.active", true)
				end
				--addLuaSprite('crack')
			end

			makeAnimSprite('rocks', 'frontRocks_1', 0, 0)
			addAnimationByPrefix('rocks', 'green', 'green', 0, false)
			addAnimationByPrefix('rocks', 'cyan', 'cyan', 0, false)
			screenCenter('rocks')
			setScrollFactor('rocks', 1.1, 1.1)
			set("rocks.active", false)
			addRel("rocks.x", wrathXAdjust + 25)
			addRel("rocks.y", wrathYAdjust + 175)
			objectPlayAnimation("rocks", "green")

			makeAnimSprite('rocksLeft', 'frontRocks_0', 0, 0)
			addAnimationByPrefix('rocksLeft', 'green', 'green', 0, false)
			addAnimationByPrefix('rocksLeft', 'cyan', 'cyan', 0, false)
			screenCenter('rocksLeft')
			setScrollFactor('rocksLeft', 1.1, 1.1)
			set("rocksLeft.active", false)
			addRel("rocksLeft.x", wrathXAdjust + 25)
			addRel("rocksLeft.y", wrathYAdjust + 175)
			objectPlayAnimation("rocksLeft", "green")

			setObjectOrder("rocks", getObjectOrder("boyfriendGroup")+1)
			setObjectOrder("rocksLeft", getObjectOrder("boyfriendGroup")+1)
		end

		local isSatisfracture = lSongName == "satisfracture" or lSongName == "satisfracture-remix"
		if lSongName == "retro" or isSatisfracture or genericSongName == "fuzzy-feeling" or lSongName == "heartmelter" then
			addRel("defaultCamZoom", -0.215)
			--set('boyfriendCameraOffset', {-220,20})
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
				set('boyfriendCameraOffset', {-50,0})
			end
		end
		if dadName == "sakuroma" or dadName == "sakuroma-alt" then
			addRel("defaultCamZoom", -0.115)
		end

		if isSpectspasm or isCorruptro then
			addRel("defaultCamZoom", -0.215)

			if not(isStoryMode and not seenCutscene and firstTry) then
				if backgroundLevel > 0 then
					addRel("rocks.scale.x", 0.1)
					addRel("rocks.scale.y", 0.1)
					addRel("rocksLeft.scale.x", 0.1)
					addRel("rocksLeft.scale.y", 0.1)
				end

				set("defaultCamZoom", 0.525)
			end
		end
	end

	if dadName == "retro2-wrath" then
		--set("opponentCameraOffset", {0, -200})
		set("boyfriendCameraOffset", {-50, -100})
	end

	if isSpectspasm then
		if boyfriendName == "bf-retro" then
			set('boyfriendCameraOffset', {-55,-100})
		end
	
		if boyfriendName == "bf-minus" then
			set('boyfriendCameraOffset', {-105,-100})
		end
		
		if boyfriendName == "bf-ace" then
			set('boyfriendCameraOffset', {-80,-100})
		end
		
		if boyfriendName == "bf-saku" then
			set('boyfriendCameraOffset', {-105,-100})
		end
	end

	if boyfriendName == "bf-corrupt" then
		set('boyfriendCameraOffset', {-65,0})
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

	if isCorruptro then
		set('dad.shaderEnabled', false)
		set('boyfriend.shaderEnabled', false)
	end

	if not(optimize) then
		makeSprite('overlay', 'wrath_overlay', 0, 0)
		screenCenter('overlay')
		setScrollFactor('overlay', 0.6, 0.6)
		setBlendMode('overlay', 'screen')
		addRel("overlay.y", -128)
		if isCorruptro then
			setColorSwapShader("overlay", 180, -40)
		end
		addLuaSprite("overlay", true)
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

function onUpdatePost(elapsed)
	--addRel("vortex.shader.hue", elapsed) -- Enable for GAY VORTEX on corruptro

	if isSpectspasm then
		-- Crystal floating movement
		if backgroundLevel > 1 and motion and not(get("inCutscene")) then
			local songPos = getSongPosition() / 1000
			for i = 1, #crystals do
				local id = crystals[i]
				addRel(id..".y", 50 * math.sin((songPos) + crystalFloatData[i][2]) * elapsed)

				-- Fancy moving effect during hardcore part of the song
				if (not isCorruptro and curStep >= 1536) or (isCorruptro and curStep >= 1824) then
					addRel(id..".x", -crystalFloatData[i][1] * elapsed)

					-- Wrap around the screen
					if get(id..".x") <= -1000 then
						set(id..".x", 2500)
					end
				end
			end
		end
	end
end

local rockColor = false -- false = green, true = cyan

function changeColor(id)
	if rockColor then
		objectPlayAnimation(id, "cyan")
	else
		objectPlayAnimation(id, "green")
	end
end

local didSakuFadeIn = false
local didDarkFadeIn = false
local flashCounter = 0

local stageTransformed = false
local secondCorruptRoar = false
local canBop = true

function colorChangeStuff()
	rockColor = not(rockColor)

	changeColor("ground")
	changeColor("rocks")
	changeColor("rocksLeft")
	changeColor("gem1")
	changeColor("gem2")

	if isEctospasm or (isCorruptro and stageTransformed and curBeat >= 220) then
		if backgroundLevel > 1 then
			set("flamesChange.alpha", 1)
			doTweenAlpha("flamesAlpha", "flamesChange", 0, 0.5)
		end
	end
end

function onStepHit()
	if isEctospasm then
		if flashingLights then
			if not(optimize) and backgroundLevel > 0 then
				if curStep >= 128 and curStep % 8 == 0 then
					colorChangeStuff()
				end
			end
		end
	end

	if isCorruptro then
		if curBeat > 808 then
			canBop = false
		end

		if flashingLights then
			if not(optimize) and backgroundLevel > 0 then
				if curStep >= 145 and curBeat <= 808 and curStep % 8 == 0 then
					colorChangeStuff()
				end
			end
		end
	end

	if isSpectral then
		if curStep >= 1024 and not didSakuFadeIn then
			doTweenAlpha("sakuFade", "sakuBop", 1, 1)
			didSakuFadeIn = true
		end

		if curStep >= 1536 and not didDarkFadeIn then
			doTweenAlpha("darkScreenFade", "spectralDarkScreen", 0.75, 0.2)
			didDarkFadeIn = true
		end

		-- TODO: Add particles lua api

		if flashingLights then
			if curStep >= 640 and flashCounter == 0 then
				cameraFlash("camGame", '0xFFFFFFFF', 0.25, true)
				flashCounter = flashCounter + 1
			end
			if curStep >= 1024 and flashCounter == 1 then
				cameraFlash("camGame", '0xFFFFFFFF', 0.25, true)
				flashCounter = flashCounter + 1
			end
			if curStep >= 1536 and flashCounter == 2 then
				cameraFlash("camGame", '0xFFFFFFFF', 0.25, true)
				flashCounter = flashCounter + 1
			end
			if curStep >= 1856 and flashCounter == 3 then
				cameraFlash("camGame", '0xFFFFFFFF', 0.25, true)
				flashCounter = flashCounter + 1
			end
		end
	end

	if isCorruptro and not(stageTransformed) and curBeat >= 228 then
		triggerEvent("Stage Transform", "", "")
		cameraFlash("camGame", '0xFFFFFFFF', 0.5, true)
		set('dad.shaderEnabled', backgroundLevel == 2)
		set('boyfriend.shaderEnabled', backgroundLevel == 2)
		isCrackVisible = true
		stageTransformed = true
	end

	if isCorruptro and not(secondCorruptRoar) and curStep >= 1824 then
		cameraFlash("camGame", '0xFFFFFFFF', 0.5, true)
		secondCorruptRoar = true
	end
end

function onBeatHit()
	if canBop and curBeat % 2 == 0 then
		objectPlayAnimation("sakuBop", "bop", true)
		set("crack.active", isCrackVisible)
		objectPlayAnimation("crack", "bop", true)
		if runesCanGlow then
			set("glowL1.alpha", 1)
			doTweenAlpha("glowL1Twn", "glowL1", 0, 13/24)
			set("glowL2.alpha", 1)
			doTweenAlpha("glowL2Twn", "glowL2", 0, 13/24)

			set("glowR1.alpha", 1)
			doTweenAlpha("glowR1Twn", "glowR1", 0, 13/24)
			set("glowR2.alpha", 1)
			doTweenAlpha("glowR2Twn", "glowR2", 0, 13/24)
			--objectPlayAnimation("cave", "glow", true)
			--objectPlayAnimation("cave2", "glow", true)
		end
	end
end