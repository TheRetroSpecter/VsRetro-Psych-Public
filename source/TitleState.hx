package;

import flixel.addons.display.FlxBackdrop;
import openfl.system.System;
#if desktop
import sys.thread.Thread;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.effects.particles.FlxEmitter;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import options.GraphicsSettingsSubState;
//import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import OutdatedState;

using StringTools;

typedef TitleData = {
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Float
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;

	var blackScreen:FlxSpriteExtra;
	var credGroup:FlxGroup;
	
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	static var menuLoad = "icebreaker";

	var curWacky:Array<String> = [];

	var mustUpdate:Bool = false;

	var titleJSON:TitleData;

	public static var updateVersion:String = '';

	override public function create():Void
	{
		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end
		
		

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();

		trace("Hello, Mortals");

		
		#if windows 
		if(!closedState || customUpdateScreen) {
			if(!customUpdateScreen) {
				var http = new haxe.Http("https://raw.githubusercontent.com/TheRetroSpecter/VsRetro-Internet-Stuff/main/version.txt");
	
				http.onData = function (data:String)
				{
					updateVersion = data.replace("\n", "").replace("\r", "");
	
					var curVersion:String = MainMenuState.retroVer.trim();
					trace('version online: ' + updateVersion + ', your version: ' + curVersion);
					if(updateVersion != curVersion) {
						trace('versions arent matching!');
						mustUpdate = true;
					}
				}
	
				http.onError = function (error) {
					trace('error: $error');
				}
				http.request();
			} else {
				mustUpdate = true;
			}

			OutdatedState.initHaxeModule();
			
			/*#if LOCAL_UPDATE_FILES 
			var str:String = File.getContent('updateScreen.hscript');
			if(str == null) str = 'version = ' + MainMenuState.retroVer + ';';
			try {
				OutdatedState.hscript.execute(str);
			} catch(e:Dynamic) {
				trace('error parsing: ' + e);
			}
			updateVersion = OutdatedState.hscript.variables.get('version');
			if(updateVersion == null)
				updateVersion = MainMenuState.retroVer;

			trace('version on file: ' + updateVersion + ', your version: ' + MainMenuState.retroVer);
			if(MainMenuState.retroVer != updateVersion)
			{
				trace('updateScreen.hscript not found!');
				mustUpdate = true;
				OutdatedState.leftState = false;
			}
			#else
			trace('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/TheRetroSpecter/VsRetro-Internet-Stuff/main/updateScreen.hscript");

			http.onData = function (data:String)
			{
				try {
					OutdatedState.hscript.execute(data);
				} catch(e:Dynamic) {
					trace('error parsing: ' + e);
				}
				updateVersion = OutdatedState.hscript.variables.get('version');

				var curVersion:String = MainMenuState.retroVer.trim();
				trace('version online: ' + updateVersion + ', your version: ' + curVersion);
				if(updateVersion != curVersion) {
					trace('versions arent matching!');
					mustUpdate = true;
				}
			}

			http.onError = function (error) {
				trace('error: $error');
			}

			http.request();
			#end*/
		}
		#end
		//#end

		//FlxG.game.focusLostFramerate = 60;
		//FlxG.sound.muteKeys = muteKeys;
		//FlxG.sound.volumeDownKeys = volumeDownKeys;
		//FlxG.sound.volumeUpKeys = volumeUpKeys;
		//FlxG.keys.preventDefaultKeys = [TAB];

		//PlayerSettings.init();

		curWacky = FlxG.random.getObject(getIntroTextShit());

		// DEBUG BULLSHIT

		swagShader = new ColorSwap();
		super.create();

		// (Tech) Changing save binding for new engine
		//FlxG.save.bind('vsretrospecterV2', 'FNF Vs Retrospecter Psych');

		//ClientPrefs.loadPrefs();
		//Unlocks.loadUnlocks();

		//Highscore.load();

		//Unlocks.loadUnlocks();

		// IGNORE THIS!!!
		titleJSON = Json.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));

		if(!initialized && FlxG.save.data != null && FlxG.save.data.fullscreen)
		{
			FlxG.fullscreen = FlxG.save.data.fullscreen;
			//trace('LOADED FULLSCREEN SETTING!!');
		}

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {
			#if desktop
			if (!DiscordClient.isInitialized)
			{
				DiscordClient.initialize();
				Application.current.onExit.add(function(exitCode) {
					DiscordClient.shutdown();
				});
			}
			#end

			new FlxTimer().start(0.5, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}
		#end

		#if windows 
		FlxG.console.registerClass(Paths);
		#end
	}

	var logoBl:FlxSprite;
	var menuBG:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	var snowfgweak:FlxBackdrop;
	var snowfgmid:FlxBackdrop;
	var snowfgstrong:FlxBackdrop;
	var snowfgweak2:FlxBackdrop;
	var snowfgmid2:FlxBackdrop;
	var snowfgstrong2:FlxBackdrop;
	var snowfgstrongest:FlxBackdrop;
	var snowstorm:FlxBackdrop;
	var snowstorm2:FlxBackdrop;
	var snowstorm3:FlxBackdrop;

	var isIceBreaker:Bool = false;
	var isWrath:Bool = false;

	public static var introMusic:FlxSound;

	function startIntro()
	{
		if (!initialized)
		{
			/*var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
				new FlxRect(-300, -300, FlxG.width * 1.8, FlxG.height * 1.8));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
				{asset: diamond, width: 32, height: 32}, new FlxRect(-300, -300, FlxG.width * 1.8, FlxG.height * 1.8));

			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;*/

			// HAD TO MODIFY SOME BACKEND SHIT
			// IF THIS PR IS HERE IF ITS ACCEPTED UR GOOD TO GO
			// https://github.com/HaxeFlixel/flixel-addons/pull/348

			// var music:FlxSound = new FlxSound();
			// music.loadStream(Paths.music('Menu_Wrath'));
			// FlxG.sound.list.add(music);
			// music.play();



			// if(FlxG.sound.music == null) {
			// 	FlxG.sound.playMusic(Paths.music('Menu_Wrath'), 0);

			// 	FlxG.sound.music.fadeIn(4, 0, 0.7);
			// }
		}

		Conductor.changeBPM(102);
		persistentUpdate = true;

		isIceBreaker = menuLoad == "icebreaker";
		isWrath = menuLoad == "wrath";

		var bg = new FlxSpriteExtra();

		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none") {
			bg.loadGraphic(Paths.image(titleJSON.backgroundSprite));
		} else {
			bg.makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		}

		// bg.antialiasing = ClientPrefs.globalAntialiasing;
		// bg.setGraphicSize(Std.int(bg.width * 0.6));
		// bg.updateHitbox();
		add(bg);

		if(isIceBreaker) {
			menuBG = new FlxSprite().loadGraphic(Paths.image('titleScreenBgIce'));
		} else {
			menuBG = new FlxSprite().loadGraphic(Paths.image('titleScreenBgP1'));
		}
		menuBG.antialiasing = ClientPrefs.globalAntialiasing;
		menuBG.screenCenter();
		add(menuBG);

		if(isIceBreaker) {
			var speed = 0.75;
			var snowstormspeed = 1;

			snowfgweak = new FlxBackdrop(Paths.image('iceolation/weak', 'shared'), 0.2, 0, true, true);
			snowfgweak.velocity.set(100, 110).scale(speed);
			snowfgweak.updateHitbox();
			snowfgweak.screenCenter(XY);
			snowfgweak.alpha = 1;
			snowfgweak.antialiasing = ClientPrefs.globalAntialiasing;

			snowfgweak2 = new FlxBackdrop(Paths.image('iceolation/weak2', 'shared'), 0.2, 0, true, true);
			snowfgweak2.velocity.set(-100, 110).scale(speed);
			snowfgweak2.updateHitbox();
			snowfgweak2.screenCenter(XY);
			snowfgweak2.alpha = 1;
			snowfgweak2.antialiasing = ClientPrefs.globalAntialiasing;

			snowfgmid = new FlxBackdrop(Paths.image('iceolation/mid', 'shared'), 0.2, 0, true, true);
			snowfgmid.velocity.set(400, 210).scale(speed);
			snowfgmid.updateHitbox();
			snowfgmid.screenCenter(XY);
			snowfgmid.alpha = 1;
			snowfgmid.antialiasing = ClientPrefs.globalAntialiasing;

			snowfgmid2 = new FlxBackdrop(Paths.image('iceolation/mid2', 'shared'), 0.2, 0, true, true);
			snowfgmid2.velocity.set(-400, 210).scale(speed);
			snowfgmid2.updateHitbox();
			snowfgmid2.screenCenter(XY);
			snowfgmid2.alpha = 1;
			snowfgmid2.antialiasing = ClientPrefs.globalAntialiasing;

			snowfgstrong = new FlxBackdrop(Paths.image('iceolation/strong', 'shared'), 0.2, 0, true, true);
			snowfgstrong.velocity.set(900, 410).scale(speed);
			snowfgstrong.updateHitbox();
			snowfgstrong.screenCenter(XY);
			snowfgstrong.alpha = 1;
			snowfgstrong.antialiasing = ClientPrefs.globalAntialiasing;

			snowfgstrong2 = new FlxBackdrop(Paths.image('iceolation/strong2', 'shared'), 0.2, 0, true, true);
			snowfgstrong2.velocity.set(-900, 410).scale(speed);
			snowfgstrong2.updateHitbox();
			snowfgstrong2.screenCenter(XY);
			snowfgstrong2.alpha = 1;
			snowfgstrong2.antialiasing = ClientPrefs.globalAntialiasing;

			snowstorm = new FlxBackdrop(Paths.image('iceolation/storm', 'shared'), 0.2, 0, true, false);
			snowstorm.velocity.set(-5000, 0).scale(snowstormspeed);
			snowstorm.updateHitbox();
			snowstorm.screenCenter(XY);
			snowstorm.alpha = 1;
			snowstorm.antialiasing = ClientPrefs.globalAntialiasing;

			snowstorm2 = new FlxBackdrop(Paths.image('iceolation/storm2', 'shared'), 0.2, 0, true, true);
			snowstorm2.velocity.set(-3700, 0).scale(snowstormspeed);
			snowstorm2.updateHitbox();
			snowstorm2.screenCenter(XY);
			snowstorm2.alpha = 1;
			snowstorm2.antialiasing = ClientPrefs.globalAntialiasing;

			snowstorm3 = new FlxBackdrop(Paths.image('iceolation/storm', 'shared'), 0.2, 0, true, false);
			snowstorm3.velocity.set(-2800, 0).scale(snowstormspeed);
			snowstorm3.updateHitbox();
			snowstorm3.screenCenter(XY);
			snowstorm3.alpha = 1;
			snowstorm3.antialiasing = ClientPrefs.globalAntialiasing;

			//snowfgstrongest = new FlxBackdrop(Paths.image('iceolation/strongest', 'shared'), 0.2, 0, true, true);
			//snowfgstrongest.velocity.set(-1100, 500).scale(speed);
			//snowfgstrongest.updateHitbox();
			//snowfgstrongest.screenCenter(XY);
			//snowfgstrongest.alpha = 1;
			//snowfgstrongest.antialiasing = ClientPrefs.globalAntialiasing;

			add(snowfgweak);
			add(snowfgweak2);
			add(snowfgmid);
			add(snowfgmid2);
			add(snowfgstrong);
			add(snowfgstrong2);

			snowstorm.alpha = 0;
			snowstorm2.alpha = 0;
			snowstorm3.alpha = 0;
			add(snowstorm);
			add(snowstorm2);
			add(snowstorm3);
		}

		logoBl = new FlxSprite(-150, -4).loadGraphic(Paths.image('logoBumpin-2'));
		logoBl.antialiasing = ClientPrefs.globalAntialiasing;
		logoBl.scale.x = minScale;
		logoBl.scale.y = minScale;
		logoBl.screenCenter();
		logoBl.y -= 65;


		swagShader = new ColorSwap();
		add(logoBl);
		logoBl.shader = swagShader.shader;

		if(isWrath) {
			// (Tech) We need to add a particles option to the menu, then i'll check the bool here
			for (i in 0...6)
			{
				var emitter:FlxEmitter = new FlxEmitter(0, 720);
				emitter.launchMode = FlxEmitterMode.SQUARE;
				emitter.velocity.set(-50, -150, 50, -750, -100, 0, 100, -100);
				emitter.scale.set(0.5, 0.5, 1, 1, 0.5, 0.5, 0.75, 0.75);
				emitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
				emitter.width = 1280;
				emitter.alpha.set(1, 1, 0, 0);
				emitter.lifespan.set(3, 5);
				emitter.loadParticles(Paths.image('Particles/Particle' + i), 500, 16, true);

				emitter.start(false, FlxG.random.float(0.1, 0.2), 100000);
				add(emitter);
			}
		}

		titleText = new FlxSprite(titleJSON.startx, titleJSON.starty);
		#if (desktop && MODS_ALLOWED)
		var path = "mods/" + Paths.currentModDirectory + "/images/titleEnter.png";
		if (!OpenFlAssets.exists(path)){
			path = "mods/images/titleEnter.png";
		}
		if (!OpenFlAssets.exists(path)){
			path = "assets/images/titleEnter.png";
		}
		titleText.frames = FlxAtlasFrames.fromSparrow(BitmapData.fromFile(path),File.getContent(StringTools.replace(path,".png",".xml")));
		#else
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		#end
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = ClientPrefs.globalAntialiasing;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		titleText.screenCenter(X);
		add(titleText);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSpriteExtra().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.globalAntialiasing;

		if (initialized) {
			skipIntro();
		} else {
			MainMenuState.songName = "Intro_" + Music.defaultMusic;
			introMusic = FlxG.sound.play(Paths.music('Intro_' + Music.defaultMusic), 0);
			introMusic.persist = true;
			FlxG.sound.music = new FlxSound();
			FlxG.sound.music.persist = true;
			FlxG.sound.music.loadEmbedded(Paths.music('Menu_' + Music.defaultMusic), true);

			introMusic.onComplete = function():Void {
				FlxG.sound.music.volume = introMusic.volume; // Shit workaround I guess
				FlxG.sound.music.play(true);
				MainMenuState.songName = 'Menu_' + Music.defaultMusic;
				if (!skippedIntro)
				{
					skipIntro(); // Hits right when the intro ends
				}
				introMusic.destroy();
				introMusic = null;
			}

			introMusic.fadeIn(4, 0, 0.75);

			Conductor.changeBPM(102);
			initialized = true;
		}
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	public var minScale:Float = 0.19; // 0.13
	public var toScale:Float = 0.21; // 0.15
	public var decScale:Float = 0.055;

	override function update(elapsed:Float)
	{
		// if (FlxG.sound.music != null)
		// 	Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);
		if (introMusic != null && introMusic.playing)
			Conductor.songPosition = introMusic.time;
		else if (FlxG.sound.music != null)
		{
			Conductor.songPosition = FlxG.sound.music.time;

			// Workaround for missing a beat animation on song loop
			if (Conductor.songPosition == 0)
			{
				beatHit();
			}
		}

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		// (Tech) Fake beat animation
		if (logoBl != null && logoBl.scale.x > minScale) {
			logoBl.scale.x -= decScale * elapsed;
			logoBl.scale.y -= decScale * elapsed;
		}

		#if android
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		// EASTER EGG

		if (initialized && !transitioning && skippedIntro)
		{
			if(pressedEnter)
			{
				if(titleText != null) titleText.animation.play('press');

				FlxG.camera.flash(FlxColor.WHITE, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;
				// FlxG.sound.music.stop();

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					if (mustUpdate) {
						MusicBeatState.switchState(new OutdatedState());
					} else {
						MusicBeatState.switchState(new MainMenuState());
						OutdatedState.hscript = null;
					}
					closedState = true;
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		if(swagShader != null)
		{
			if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		if(credGroup != null && textGroup != null) {
			for (i in 0...textArray.length)
			{
				var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
				money.screenCenter(X);
				money.y += (i * 60) + 200 + offset;
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			var letter = textGroup.members[0];
			credGroup.remove(letter, true);
			textGroup.remove(letter, true);
			letter.destroy();
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();

		if(logoBl != null)
			FlxTween.tween(logoBl, {'scale.x': toScale, 'scale.y': toScale}, 0.025);
			//logoBl.animation.play('bump', true);

		if(!closedState) {
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					// #if PSYCH_WATERMARKS
					// createCoolText(['Psych Engine by'], 15);
					// #else
					createCoolText(['Retro Mod Team']);
					//#end
				case 3:
					// #if PSYCH_WATERMARKS
					// addMoreText('Shadow Mario', 15);
					// addMoreText('RiverOaken', 15);
					// addMoreText('shubs', 15);
					// #else
					deleteCoolText();
					createCoolText(['Retro Mod Team']);

					addMoreText('presents');
					// #end
				case 4:
					deleteCoolText();
				case 5:
					// #if PSYCH_WATERMARKS
					// createCoolText(['Not associated', 'with'], -40);
					// #else
					// createCoolText(['In association', 'with'], -40);
					// #end

					createCoolText(['Based on a game by']);
				case 7:
					// addMoreText('newgrounds', -40);
					// ngSpr.visible = true;

					deleteCoolText();
					createCoolText([
						'Based on a game by',
						'ninjamuffin99',
						'phantomArcade',
						'kawaisprite',
						'evilsk8er'
					]);
				case 8:
					deleteCoolText();
					//ngSpr.visible = false;
				case 9:
					createCoolText([curWacky[0]]);
				case 11:
					addMoreText(curWacky[1]);
				case 12:
					deleteCoolText();
				case 13:
					addMoreText('Friday Night Funkin');
				case 14:
					addMoreText('Vs RetroSpecter');
				case 15:
					addMoreText('Icebreaker 1.75');

				case 16:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			ngSpr.exists = false;
			credGroup.exists = false;
			FlxG.camera.flash(FlxColor.WHITE, 4);
			skippedIntro = true;

			if(isIceBreaker) {
				new FlxTimer().start(10, function(t10:FlxTimer) {
					FlxTween.tween(snowstorm, {alpha: 0.3}, 0.4);
					FlxTween.tween(snowstorm2, {alpha: 0.3}, 0.4);
					FlxTween.tween(snowstorm3, {alpha: 0.3}, 0.4, {
						onComplete: function(twn:FlxTween) {
							new FlxTimer().start(10, function(t10off:FlxTimer) {
								FlxTween.tween(snowstorm, {alpha: 0}, 0.4);
								FlxTween.tween(snowstorm2, {alpha: 0}, 0.4);
								FlxTween.tween(snowstorm3, {alpha: 0}, 0.4, {
									onComplete: function(twn:FlxTween) {
										t10.reset(10);
									}
								});
							});
						}
					});
				});
			}
		}
	}
}
