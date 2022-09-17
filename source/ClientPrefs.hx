package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import openfl.net.SharedObject;
import Controls;

class ClientPrefs {
	public static var mechanics:Bool = true;
	public static var screenShake:Bool = true; 
	public static var windowShake:Bool = true; 
	public static var ghostTrails:Bool = true;
	public static var textureCompression:Bool = false; // TODO: Add Setting
	public static var motion:Bool = true;
	public static var optimize:Bool = false;
	public static var background:Int = 2; 
	public static var particles:Bool = true; 
	public static var optimizedNotes:Bool = false;
	public static var modcharts:Bool = true;
	public static var precachedDeaths:Bool = false;
	public static var cacheStory:Bool = true;

	public static var wrathAngleOpt:Int = 17;
	public static var wrathExperimental:Bool = true;
	public static var chromatic:Bool = true;
	public static var wrathShader:Bool = true;
	public static var shaders:Bool = true;

	public static var empty:String = ''; // Empty - Ignore Me

	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var showFPS:Bool = true;
	public static var flashing:Bool = true;
	public static var globalAntialiasing:Bool = true;
	public static var noteSplashes:Bool = true;
	public static var lowQuality:Bool = false;
	public static var framerate:Int = 60;
	public static var camZooms:Bool = true;
	public static var hideHud:Bool = false;
	public static var noteOffset:Int = 0;
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	//public static var quantHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public static var quantColors:Array<Array<Int>> = [
		[0xC24B99, 0x3C1F56], // 4th
		[0x00FFFF, 0x1542B7], // 8th
		[0x12FA05, 0x0A4447], // 12th
		[0xF9393F, 0x651038], // 16th

		[0xC24B99, 0x3C1F56], // 20th
		[0x00FFFF, 0x1542B7], // 24th
		[0x12FA05, 0x0A4447], // 32nd
		[0xF9393F, 0x651038], // 48th

		[0xC24B99, 0x3C1F56], // 64th
		[0x00FFFF, 0x1542B7], // 192nd
	];
	public static var ghostTapping:Bool = true;
	public static var noteQuantization:Bool = false;
	public static var timeBarType:String = 'Disabled';
	public static var scoreZoom:Bool = true;
	public static var noReset:Bool = false;
	public static var healthBarAlpha:Float = 1;
	public static var controllerMode:Bool = false;
	public static var hitsoundVolume:Float = 0;
	public static var pauseMusic:String = 'Tea Time';
	public static var healthSystem:String = 'Kade';
	public static var inputSystem:String = 'Kade';
	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill_new' => false,
		'practice' => false,
		'botplay' => false
	];

	public static var opponentQuants:Bool = true;
	public static var opponentNoteskins:Bool = true;
	public static var playerNoteskins:Bool = true;
	public static var opponentStrums:Bool = true;
	public static var comboOffset:Array<Int> = [-407, -339, -321, -246];
	public static var ratingOffset:Int = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var safeFrames:Float = 10;

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_up'		=> [W, UP],
		'note_right'	=> [D, RIGHT],

		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_up'			=> [W, UP],
		'ui_right'		=> [D, RIGHT],

		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R, NONE],

		'volume_mute'	=> [ZERO, NONE],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],

		'debug_1'		=> [SEVEN, NONE],
		'debug_2'		=> [EIGHT, NONE],

		'change_gf'		=> [ALT, NONE],
		'change_bf'		=> [SHIFT, NONE],
		'change_foe'	=> [COMMA, NONE]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys() {
		defaultKeys = keyBinds.copy();
		//trace(defaultKeys);
	}

	public static function saveSettings() {

		FlxG.save.data.mechanics = mechanics;
		FlxG.save.data.screenShake = screenShake;
		FlxG.save.data.windowShake = windowShake;
		FlxG.save.data.ghostTrails = ghostTrails;
		FlxG.save.data.motion = motion;
		FlxG.save.data.optimize = optimize;
		FlxG.save.data.background = background;
		FlxG.save.data.particles = particles;
		FlxG.save.data.optimizedNotes = optimizedNotes;
		FlxG.save.data.modcharts = modcharts;
		FlxG.save.data.precachedDeaths = precachedDeaths;
		FlxG.save.data.cacheStory = cacheStory;
		FlxG.save.data.opponentQuants = opponentQuants;

		FlxG.save.data.inputSystem = inputSystem;
		FlxG.save.data.healthSystem = healthSystem;

		FlxG.save.data.downScroll = downScroll;
		FlxG.save.data.middleScroll = middleScroll;
		FlxG.save.data.showFPS = showFPS;
		FlxG.save.data.flashing = flashing;
		FlxG.save.data.globalAntialiasing = globalAntialiasing;
		FlxG.save.data.noteSplashes = noteSplashes;
		FlxG.save.data.lowQuality = lowQuality;
		FlxG.save.data.framerate = framerate;
		FlxG.save.data.camZooms = camZooms;
		FlxG.save.data.noteOffset = noteOffset;
		FlxG.save.data.hideHud = hideHud;
		FlxG.save.data.arrowHSV = arrowHSV;
		FlxG.save.data.quantColors = quantColors;
		FlxG.save.data.ghostTapping = ghostTapping;
		FlxG.save.data.noteQuantization = noteQuantization;
		FlxG.save.data.timeBarType = timeBarType;
		FlxG.save.data.scoreZoom = scoreZoom;
		FlxG.save.data.noReset = noReset;
		FlxG.save.data.healthBarAlpha = healthBarAlpha;
		FlxG.save.data.comboOffset = comboOffset;
		FlxG.save.data.opponentNoteskins = opponentNoteskins;
		FlxG.save.data.playerNoteskins = playerNoteskins;
		FlxG.save.data.opponentStrums = opponentStrums;
		FlxG.save.data.achievementsMap = Achievements.achievementsMap;

		FlxG.save.data.wrathAngleOpt = wrathAngleOpt < 0 ? 1 : wrathAngleOpt;
		FlxG.save.data.wrathExperimental = wrathExperimental;
		FlxG.save.data.chromatic = chromatic;
		FlxG.save.data.shaders = shaders;
		FlxG.save.data.wrathShader = wrathShader;

		FlxG.save.data.ratingOffset = ratingOffset;
		FlxG.save.data.sickWindow = sickWindow;
		FlxG.save.data.goodWindow = goodWindow;
		FlxG.save.data.badWindow = badWindow;
		FlxG.save.data.safeFrames = safeFrames;
		FlxG.save.data.gameplaySettings = gameplaySettings;
		FlxG.save.data.controllerMode = controllerMode;
		FlxG.save.data.hitsoundVolume = hitsoundVolume;
		FlxG.save.data.pauseMusic = pauseMusic;

		FlxG.save.flush();

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'ninjamuffin99'); //Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		save.data.customControls = keyBinds;
		save.flush();
		save.close();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		// Haxeflixel Stuff

		#if debug
		if (FlxG.save.data.windowSettings == null)
		{
			var maxWindows = 10; // arbitrary
			FlxG.save.data.windowSettings = [for (_ in 0...maxWindows) true];
		}
		#end

		// Psych Stuff

		if (FlxG.save.data.mechanics != null) {
			mechanics = FlxG.save.data.mechanics;
		}
		if (FlxG.save.data.screenShake != null) {
			screenShake = FlxG.save.data.screenShake;
		}
		if (FlxG.save.data.windowShake != null) {
			windowShake = FlxG.save.data.windowShake;
		}
		if (FlxG.save.data.ghostTrails != null) {
			ghostTrails = FlxG.save.data.ghostTrails;
		}
		if (FlxG.save.data.motion != null) {
			motion = FlxG.save.data.motion;
		}
		if (FlxG.save.data.optimize != null) {
			optimize = FlxG.save.data.optimize;
		}
		if (FlxG.save.data.background != null) {
			background = FlxG.save.data.background;
		}
		if (FlxG.save.data.optimizedNotes != null) {
			optimizedNotes = FlxG.save.data.optimizedNotes;
		}
		if (FlxG.save.data.modcharts != null) {
			modcharts = FlxG.save.data.modcharts;
		}
		if (FlxG.save.data.precachedDeaths != null) {
			precachedDeaths = FlxG.save.data.precachedDeaths;
		}
		if (FlxG.save.data.cacheStory != null) {
			cacheStory = FlxG.save.data.cacheStory;
		}
		if (FlxG.save.data.opponentQuants != null) {
			opponentQuants = FlxG.save.data.opponentQuants;
		}

		if (FlxG.save.data.inputSystem != null) {
			inputSystem = FlxG.save.data.inputSystem;
		}
		if (FlxG.save.data.healthSystem != null) {
			healthSystem = FlxG.save.data.healthSystem;
		}

		if(FlxG.save.data.downScroll != null) {
			downScroll = FlxG.save.data.downScroll;
		}
		if(FlxG.save.data.middleScroll != null) {
			middleScroll = FlxG.save.data.middleScroll;
		}

		if(FlxG.save.data.particles != null) {
			particles = FlxG.save.data.particles;
		}

		if(FlxG.save.data.showFPS != null) {
			showFPS = FlxG.save.data.showFPS;
			if(Main.fpsVar != null) {
				Main.fpsVar.visible = showFPS;
			}
		}
		if(FlxG.save.data.flashing != null) {
			flashing = FlxG.save.data.flashing;
		}
		if(FlxG.save.data.globalAntialiasing != null) {
			globalAntialiasing = FlxG.save.data.globalAntialiasing;
		}
		if(FlxG.save.data.noteSplashes != null) {
			noteSplashes = FlxG.save.data.noteSplashes;
		}
		if(FlxG.save.data.lowQuality != null) {
			lowQuality = FlxG.save.data.lowQuality;
		}
		if(FlxG.save.data.framerate != null) {
			framerate = FlxG.save.data.framerate;
			if(framerate > FlxG.drawFramerate) {
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			} else {
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		}
		if(FlxG.save.data.camZooms != null) {
			camZooms = FlxG.save.data.camZooms;
		}
		if(FlxG.save.data.hideHud != null) {
			hideHud = FlxG.save.data.hideHud;
		}
		if(FlxG.save.data.noteOffset != null) {
			noteOffset = FlxG.save.data.noteOffset;
		}
		if(FlxG.save.data.arrowHSV != null) {
			var oldArrowHSV:Array<Array<Int>> = FlxG.save.data.arrowHSV;
			//for (i in oldArrowHSV.length...arrowHSV.length) {
			//	oldArrowHSV.push(arrowHSV[i - 1]);
			//}
			while(oldArrowHSV.length > 4) {
				oldArrowHSV.pop();
			}
			arrowHSV = oldArrowHSV;
		}
		if(FlxG.save.data.quantColors != null) {
			//var oldArrowHSV:Array<Array<Int>> = FlxG.save.data.arrowHSV;
			//for (i in oldArrowHSV.length...arrowHSV.length) {
			//	oldArrowHSV.push(arrowHSV[i - 1]);
			//}
			//FlxG.save.data.quantHSV = quantHSV;
			quantColors = FlxG.save.data.quantColors;
		}
		if(FlxG.save.data.ghostTapping != null) {
			ghostTapping = FlxG.save.data.ghostTapping;
		}
		if(FlxG.save.data.noteQuantization != null) {
			noteQuantization = FlxG.save.data.noteQuantization;
		}
		if(FlxG.save.data.timeBarType != null) {
			timeBarType = FlxG.save.data.timeBarType;
		}
		if(FlxG.save.data.scoreZoom != null) {
			scoreZoom = FlxG.save.data.scoreZoom;
		}
		if(FlxG.save.data.noReset != null) {
			noReset = FlxG.save.data.noReset;
		}
		if(FlxG.save.data.healthBarAlpha != null) {
			healthBarAlpha = FlxG.save.data.healthBarAlpha;
		}
		if(FlxG.save.data.comboOffset != null) {
			comboOffset = FlxG.save.data.comboOffset;
		}
		if(FlxG.save.data.opponentNoteskins != null) {
			opponentNoteskins = FlxG.save.data.opponentNoteskins;
		}
		if(FlxG.save.data.playerNoteskins != null) {
			playerNoteskins = FlxG.save.data.playerNoteskins;
		}
		if(FlxG.save.data.opponentStrums != null) {
			opponentStrums = FlxG.save.data.opponentStrums;
		}

		if(FlxG.save.data.wrathAngleOpt != null) {
			wrathAngleOpt = FlxG.save.data.wrathAngleOpt;
			if(wrathAngleOpt < 0) wrathAngleOpt = 1;
		}
		if(FlxG.save.data.wrathExperimental != null) {
			wrathExperimental = FlxG.save.data.wrathExperimental;
		}
		if(FlxG.save.data.shaders != null) {
			shaders = FlxG.save.data.shaders;
		}
		if(FlxG.save.data.chromatic != null) {
			chromatic = FlxG.save.data.chromatic;
		}
		if(FlxG.save.data.wrathShader != null) {
			wrathShader = FlxG.save.data.wrathShader;
		}

		if(FlxG.save.data.ratingOffset != null) {
			ratingOffset = FlxG.save.data.ratingOffset;
		}
		if(FlxG.save.data.sickWindow != null) {
			sickWindow = FlxG.save.data.sickWindow;
		}
		if(FlxG.save.data.goodWindow != null) {
			goodWindow = FlxG.save.data.goodWindow;
		}
		if(FlxG.save.data.badWindow != null) {
			badWindow = FlxG.save.data.badWindow;
		}
		if(FlxG.save.data.safeFrames != null) {
			safeFrames = FlxG.save.data.safeFrames;
		}
		if(FlxG.save.data.controllerMode != null) {
			controllerMode = FlxG.save.data.controllerMode;
		}
		if(FlxG.save.data.hitsoundVolume != null) {
			hitsoundVolume = FlxG.save.data.hitsoundVolume;
		}
		if(FlxG.save.data.pauseMusic != null) {
			pauseMusic = FlxG.save.data.pauseMusic;
		}
		if(FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
			{
				gameplaySettings.set(name, value);
			}
		}

		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
		{
			FlxG.sound.volume = FlxG.save.data.volume;
		}
		if (FlxG.save.data.mute != null)
		{
			FlxG.sound.muted = FlxG.save.data.mute;
		}

		if (FlxG.save.data.portedFromOldVersion == null || FlxG.save.data.portedFromOldVersion == false)
		{
			portSettings();
			FlxG.save.data.portedFromOldVersion = true;
		}

		if (FlxG.save.data.firstBoot == null || FlxG.save.data.firstBoot == false)
		{
			Unlocks.firstBoot = true;
			FlxG.save.data.firstBoot = true;
		}

		if (FlxG.save.data.flashingLightsDisclaimer == null)
			FlxG.save.data.flashingLightsDisclaimer = true;

		if (FlxG.save.data.suggestiveContentDisclaimer == null)
			FlxG.save.data.suggestiveContentDisclaimer = true;

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'ninjamuffin99');
		if(save != null && save.data.customControls != null) {
			var loadedControls:Map<String, Array<FlxKey>> = save.data.customControls;
			for (control => keys in loadedControls) {
				keyBinds.set(control, keys);
			}
			reloadControls();
			save.close();
		}

		FlxG.save.flush();
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic {
		return /*PlayState.isStoryMode ? defaultValue : */ (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadControls() {
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);

		TitleState.muteKeys = copyKey(keyBinds.get('volume_mute'));
		TitleState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		TitleState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
	}
	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey> {
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len) {
			if(copiedArray[i] == NONE) {
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}

	public static function getKeyBind(name:String, i:Int = 0) {
		return InputFormatter.getKeyName(ClientPrefs.keyBinds.get(name)[i]);
	}

	private static var __aaa:UnlockStruct;

	static function portSettings()
	{
		if (FlxG.save.data.portedFromOldVersion) return;
		var oldSave:FlxSave = new FlxSave();

		// Prevent Removal
		var newTest = new UnlockStruct('', 0, true);
		__aaa = newTest;

		oldSave.bind('vsretrospecter', 'FNF Vs Retrospecter', true);

		if (oldSave.data.downscroll != null) {
			ClientPrefs.downScroll = oldSave.data.downscroll;
			Unlocks.portedFromOld = true;
		}

		if (oldSave.data.ghostTrails != null)
			ClientPrefs.ghostTrails = oldSave.data.ghostTrails;

		if (oldSave.data.botplay != null)
			ClientPrefs.gameplaySettings['botplay'] = oldSave.data.botplay; 

		//if (oldSave.data.scrollSpeed != null) {
		//	ClientPrefs.gameplaySettings['scrollspeed'] = oldSave.data.scrollSpeed;
		//	ClientPrefs.gameplaySettings['scrolltype'] = 'constant';
		//}

		if (oldSave.data.fps != null)
			ClientPrefs.showFPS = oldSave.data.fps;

		if (oldSave.data.optimize != null)
			ClientPrefs.optimize = oldSave.data.optimize;

		if (oldSave.data.background != null)
			ClientPrefs.background = oldSave.data.background;

		if (oldSave.data.ghost != null)
			ClientPrefs.ghostTapping = oldSave.data.ghost;

		if (oldSave.data.noteSplashes != null)
			ClientPrefs.noteSplashes = oldSave.data.noteSplashes;

		if (oldSave.data.windowShake != null)
			ClientPrefs.windowShake = oldSave.data.windowShake;

		if (oldSave.data.screenShake != null)
			ClientPrefs.screenShake = oldSave.data.screenShake;

		if (oldSave.data.flashing != null)
			ClientPrefs.flashing = oldSave.data.flashing;

		if (oldSave.data.motion != null)
			ClientPrefs.motion = oldSave.data.motion;

		if (oldSave.data.particles != null)
			ClientPrefs.particles = oldSave.data.particles;

		if (oldSave.data.chrom != null)
			ClientPrefs.chromatic = oldSave.data.chrom;

		if (oldSave.data.antialiasing != null)
			ClientPrefs.globalAntialiasing = oldSave.data.antialiasing;
		#if desktop
		if (oldSave.data.fpsCap != null)
			ClientPrefs.framerate = oldSave.data.fpsCap;
		#end
		if (oldSave.data.resetButton != null)
			ClientPrefs.noReset = !oldSave.data.resetButton;

		if (oldSave.data.stepMania != null)
			ClientPrefs.noteQuantization = oldSave.data.stepMania;

		if (oldSave.data.frames != null)
			ClientPrefs.safeFrames = oldSave.data.frames;

		if (oldSave.data.offset != null)
			ClientPrefs.noteOffset = oldSave.data.offset;

		//if (oldSave.data.songPosition != null && !oldSave.data.songPosition)
		//	ClientPrefs.timeBarType = 'Disabled';

		if (oldSave.data.camzoom != null)
			ClientPrefs.camZooms = oldSave.data.camzoom;

		if (oldSave.data.modChart != null)
			ClientPrefs.modcharts = oldSave.data.modChart;

		oldSave.close();
	}
}
/*
class OldPrefsUtil {
	// Binds the old setting data to our new version

	public static function portSettings()
	{
		var oldSave:FlxSave;
		
		oldSave.bind('vsretrospecter', 'FNF Vs Retrospecter');

		if (oldSave.data.downscroll != null)
			ClientPrefs.downScroll = oldSave.data.downscroll;

		if (oldSave.data.ghostTrails != null)
			ClientPrefs.ghostTrails = oldSave.data.ghostTrails;

		if (oldSave.data.botplay != null)
			ClientPrefs.gameplaySettings['botplay'] = oldSave.data.botplay; 

		if (oldSave.data.scrollSpeed != null)
			ClientPrefs.gameplaySettings['scrollspeed'] = oldSave.data.scrollSpeed; 

		if (oldSave.data.fps != null)
			ClientPrefs.showFPS = oldSave.data.fps;

		if (oldSave.data.optimize != null)
			ClientPrefs.optimize = oldSave.data.optimize;

		if (oldSave.data.background != null)
			ClientPrefs.background = oldSave.data.background;

		if (oldSave.data.ghost != null)
			ClientPrefs.ghostTapping = oldSave.data.ghost;

		if (oldSave.data.noteSplashes != null)
			ClientPrefs.noteSplashes = oldSave.data.noteSplashes;

		if (oldSave.data.windowShake != null)
			ClientPrefs.windowShake = oldSave.data.windowShake;
		
		if (oldSave.data.screenShake != null)
			ClientPrefs.screenShake = oldSave.data.screenShake;

		if (oldSave.data.flashing != null)
			ClientPrefs.flashing = oldSave.data.flashing;

		if (oldSave.data.motion != null)
			ClientPrefs.motion = oldSave.data.motion;

		if (oldSave.data.particles != null)
			ClientPrefs.particles = oldSave.data.particles;

		if (oldSave.data.chrom != null)
			ClientPrefs.chromatic = oldSave.data.chrom;

		if (oldSave.data.antialiasing != null)
			ClientPrefs.globalAntialiasing = oldSave.data.antialiasing;
		#if desktop
		if (oldSave.data.fpsCap != null)
			ClientPrefs.framerate = oldSave.data.fpsCap;
		#end
		if (oldSave.data.resetButton != null)
			ClientPrefs.noReset = !oldSave.data.resetButton;

		if (oldSave.data.stepMania != null)
			ClientPrefs.noteQuantization = oldSave.data.stepMania;

		if (oldSave.data.frames != null)
			ClientPrefs.safeFrames = oldSave.data.frames;

		if (oldSave.data.offset != null)
			ClientPrefs.noteOffset = oldSave.data.offset;

		if (oldSave.data.songPosition != null && !oldSave.data.songPosition)
			ClientPrefs.timeBarType = 'Disabled';
			
	}
}*/

//added this private class in case the serializer couldn't detect the class
@:keep class UnlockStruct
{
    public var name:String;
    public var index:Int;
    public var unlocked:Bool;

    public function new(name:String, index:Int, unlocked:Bool)
    {
        this.name = name;
        this.index = index;
        this.unlocked = unlocked;
    }
}