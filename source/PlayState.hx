package;

import flixel.util.FlxDestroyUtil;
import shaders.ChromaticAberrationShader;
import lime.app.Application;
import flixel.graphics.FlxGraphic;
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.effects.particles.FlxEmitter;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import flixel.util.FlxSave;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import ConfettiEmitter;
import ConfettiParticle;
#if sys
import sys.FileSystem;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartBackdrops:Map<String, ModchartBackdrop> = new Map<String, ModchartBackdrop>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var DAD2_X:Float = 100;
	public var DAD2_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public static var firstTry:Bool = true; // Used to skip cutscenes/dialogue when retrying in story mode

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var SONG2:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var weekScoreName:String = "";

	public static var splashSkin:String = null;
	public static var arrowSkinbf:String = null;
	public static var arrowSkindad:String = null;

	public var vocals:FlxSound;
	public var instToLoad:String;
	public var voicesToLoad:String;

	var particles:FlxTypedGroup<FlxEmitter>; // Particle emitters for fire sparks. Changes to hearts if Saku Note is hit
	var spectralBGEmitter:FlxEmitter; // Particle emitter for the lines in the moving effect

	public var dad:Character = null;
	public var dad2:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var notes:FlxTypedGroup<Note>;
	public var allNotes:Array<Note> = [];
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLineX:Float;
	private var strumLineY:Float;

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var comboLayer:FlxTypedGroup<FlxSprite>;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = true;
	public var enableCamZooming:Bool = true;
	private var curSong:String = "";
	public var formattedSong:String = "";
	public static var genericSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	public var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	public var healthBarOrigin:FlxPoint;
	var songPercent:Float = 0;

	public var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;
	public var cameraMoving:Bool = true;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public static var randomMode:Bool = false;
	public static var instadeathMode:Bool = false;
	//to do: make this toggable in story and freeplay menu, btw psych already has insta death mode

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxFixedText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	//var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;
	var dialogueBox:DialogueBox = null;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxFixedText;
	public var timeTxt:FlxFixedText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;
	public var hideGF:Null<Bool> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	var detailsSongName:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	// Enough! Text
	var enoughTxt:FlxFixedText;
	var enoughTxtOrigin:FlxPoint;

	// IS THAT ALL YOU GOT? Text
	var overtimeTxt:FlxFixedText;
	var overtimeTxtOrigin:FlxPoint;

	// effects
	var windowOrigin:FlxPoint;
	var spriteTrail:FlxTypedGroup<FlxSprite>;
	var chrom:ChromaticAberrationShader;

	public static var currentWrath:String;

	// (Tech) Confetti stuff
	public var confetti:ConfettiEmitter;

	var confettiSizeX:Int = 30;
	var confettiSizeY:Int = 10;

	//spectral and ectospasm mechanics
	public var poisonIcon:FlxSprite;
	public var poisonTxt:FlxFixedText;
	var healthDrainPoison:Float = 0.025;
	var poisonStacks:Int = 0;
	var noteFadeTime:Float = 0.025;
	var noteOpacity:Float = 0.5;
	var spectreHit:Bool = false;
	var enemySpectreHit:Bool = false;

	var hasWrathBar:Bool = false;
	var hasSpecterNoteMechanic:Bool = false;

	var cameraStartDad:Bool = false;

	static var freeplayDialogueSongs:Array<String> = ['fuzzy-feeling', 'postgame', 'icebreaker', 'mompoms', 'brawnstorm','corruptro'];

	// Spectral death dialogue
	public static var deaths:Int = 0;
	public static var shownHint:Bool = false;
	public var speechBubble:FlxSprite;
	public var retroPortrait:FlxSprite;
	//public static var hintText:FlxFixedTypeText;
	//public static var hintDropText:FlxFixedText;
	public static var trueEctospasm:Bool = false; // Used to take account of the bonus chart for Ectospasm

	var cutsceneSprite:Character;
	var bfBeepWake:FlxSound;
	var wrathIntroSnap:FlxSound;

	// some sounds
	var poisonSound:FlxSound;
	var spectreSound:FlxSound;
	var sakuLaugh:FlxSound;
	var sakuNote:FlxSound;

	var kadeHealthSystem:Bool = false;
	var kadeInputSystem:Bool = false;

	// Ace Frozen Notes Mechanic
	private var breakAnims:FlxTypedGroup<FlxSprite>;

	public var frozen:Array<Bool> = [false, false, false, false];
	public var strumsBlocked:Array<Bool> = [false, false, false, false];

	private var frozenTime:Float = 0; // Track time when frozen to prevent pause cheat
	public var hasIceNotes:Bool = false;

	var spritesToDestroy:Array<FlxBasic> = [];
	var notesToDestroy:Array<Note> = [];
	public static var announceStart:Bool = false;

	public static var bfVersion:String;
	public static var gfVersion:String;
	public static var foeVersion:String;

	var dialogueBf:String = "bf";
	var dialogueGf:String = "gf";

	public static function getGenericName(songName:String) {
		songName = Paths.formatToSongPath(songName);
		var weeks = WeekData.getWeekFiles(false);
		var weeksList = weeks.weeksList;

		for (i in 0...weeksList.length) {
			var leWeek:WeekData = weeks.weeksLoaded.get(weeksList[i]);
			for (song in leWeek.songs)
			{
				if(song.length > 3) {
					var metaSongs:Array<String> = song[3];
					for(s in metaSongs) {
						if(Paths.formatToSongPath(s) == songName) {
							return Paths.formatToSongPath(song[0]);
						}
					}
				}
			}
		}

		return songName;
	}

	override public function create()
	{
		Paths.clearStoredMemory();

		currentWrath = "";

		WindowTitle.progress(0);

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill_new', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		kadeHealthSystem = ClientPrefs.healthSystem == "Kade";
		kadeInputSystem = ClientPrefs.inputSystem == "Kade";

		if (isStoryMode && !instakillOnMiss){
			trace('detected instakillonmiss as ' + instakillOnMiss + 'while instadeathMode is' + instadeathMode);
			instakillOnMiss = instadeathMode;
		}

		camGame = new FlxCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		// Splashes
		arrowSkinbf = SONG.arrowSkinbf;
		arrowSkindad = SONG.arrowSkindad;
		splashSkin = SONG.splashSkin;

		if (!ClientPrefs.playerNoteskins)
			arrowSkinbf = 'NOTE_assets';
		if (!ClientPrefs.opponentNoteskins)
			arrowSkindad = 'NOTE_assets';

		formattedSong = Paths.formatToSongPath(SONG.song);
		genericSong = getGenericName(formattedSong);
		trace("Song: " + formattedSong + " | Generic: " + genericSong);

		hasSpecterNoteMechanic = genericSong == "ectospasm" || formattedSong == "corruptro";
		hasWrathBar = formattedSong == 'spectral' || genericSong == 'ectospasm' || formattedSong == 'corruptro';

		voicesToLoad = formattedSong;
		switch(voicesToLoad)
		{
			case 'acidiron':
				if(storyDifficulty == Difficulty.HELL) //Hell
				{
					voicesToLoad = 'acidiron-hell';
				}
			case 'ectospasm':
				if (storyDifficulty == Difficulty.APOCALYPSE || trueEctospasm)
				{
					//if (bfCharacter == 'bf-saku')
					//	voicesToLoad = 'ectogasm';
					//else
					voicesToLoad = 'ectospasm-apocalypse';
				}
		}

		instToLoad = formattedSong;
		switch(instToLoad)
		{
			case 'acidiron':
				if(storyDifficulty == Difficulty.HELL) //Hell
				{
					instToLoad = 'acidiron-hell';
				}
			case 'ectospasm' | 'ectogasm':
				if (storyDifficulty == Difficulty.APOCALYPSE || trueEctospasm)
					instToLoad = 'ectospasm-apocalypse';
				else if (instToLoad == 'ectogasm' && (storyDifficulty == Difficulty.HELL))
					instToLoad = 'ectogasm';
		}

		gfVersion = SONG.gfVersion;
		bfVersion = SONG.player1;
		foeVersion = SONG.player2;

		if(Unlocks.gfName != "" && Unlocks.gfName != null)
			gfVersion = Unlocks.gfName;
		if(Unlocks.bfName != "" && Unlocks.bfName != null)
			bfVersion = Unlocks.bfName;
		if(Unlocks.foeName != "" && Unlocks.foeName != null)
			foeVersion = Unlocks.foeName;

		var defaultFoe = foeVersion;

		GameOverSubstate.resetVariables();

		enableCamZooming = formattedSong != 'tutorial';

		if(formattedSong == "corruptro") {
			healthDrainPoison *= 1.5;
		}

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		if(!chartingMode) { // No cheating using chart editor
			Unlocks.playedSong(SONG.song);
		}

		trace('dadskin: ' + arrowSkindad + ' | bfskin: ' + arrowSkinbf);

		#if desktop
		storyDifficultyText = Difficulty.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			var week = WeekData.getCurrentWeek();
			var name = "Vs. Retrospecter";
			if(week != null) {
				name = week.weekName;
			}
			detailsText = "Story Mode: " + name;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		detailsSongName = SONG.song;
		#if !final
		// (neo) Remove this for release
		//detailsSongName = "song";
		#end
		#end

		var songName:String = formattedSong;

		curStage = SONG.stage;
		//trace('stage is: ' + curStage);
		if(SONG.stage == null || SONG.stage.length < 1) {
			switch (songName)
			{
				default:
					curStage = 'stage';
			}
		}

		if(curStage == 'wrath') {
			PauseSubState.songName = 'Snackrifice';
			GameOverSubstate.loopSoundName = 'Skill_Issue';
			GameOverSubstate.endSoundName = 'Skill_Issue_End';
		} else if(curStage.startsWith('minus')) {
			PauseSubState.songName = 'MPause_Ambience';
			GameOverSubstate.loopSoundName = 'School_Issue';
			GameOverSubstate.endSoundName = 'School_Issue_End';
		} else {
			PauseSubState.songName = 'Snackrifice';
			GameOverSubstate.loopSoundName = 'Skill_Issue';
			GameOverSubstate.endSoundName = 'Skill_Issue_End';
		}

		GameOverSubstate.characterName = bfVersion;
		if ((formattedSong == "preppy" || formattedSong == "overtime") && bfVersion == 'bf-minus')
			GameOverSubstate.characterName = "bf-minus-sakudeath"; //(BRN101) Hey, it works

		if ((formattedSong == "preseason" || formattedSong == "sigma" || formattedSong == "acidiron") && bfVersion == 'bf-minus')
			GameOverSubstate.characterName = "bf-minus-death";
		switch (GameOverSubstate.characterName)
		{
			case 'bf'|'bf-wrath':
				if (formattedSong == 'spectral' || formattedSong == 'ectospasm')
					GameOverSubstate.characterName = 'bf-wrath-death';
				else
					GameOverSubstate.characterName = 'bf-death';
			case 'retro-minus-player':
				GameOverSubstate.characterName = 'retro-minus-player-death';
				GameOverSubstate.deathSoundName = 'Metro_Death';
			case 'sakuroma-minus-player':
				GameOverSubstate.characterName = 'sakuroma-minus-death';
				GameOverSubstate.deathSoundName = 'Maku_Death';
			case 'bf-minus': //done when selected on other stages other than minus
				GameOverSubstate.characterName = 'bf-minus-death';
			case 'bf-ace':
				GameOverSubstate.characterName = 'bf-ace-death';
			case 'bf-saku':
				GameOverSubstate.characterName = 'bf-saku-death';
			case 'bf-retro':
				GameOverSubstate.characterName = 'bf-retro-death';
			case 'bf-corrupt':
				GameOverSubstate.characterName = 'bf-corrupt-death';
				GameOverSubstate.cameraOffset.set(0, -100);

				GameOverSubstate.deathSoundName = 'CBF_deeath';
				GameOverSubstate.loopSoundName = 'CorruptroDeath';
				GameOverSubstate.endSoundName = 'Skill_Issue_End';
			case 'zerktro-player':
				GameOverSubstate.characterName = 'zerktro-player-death';
				GameOverSubstate.cameraOffset.set(-100, 0);

				GameOverSubstate.deathSoundName = 'NO_MORE_MOUNTAIN_SPEW';
			default:
				// Special case for optimized mode
				if (ClientPrefs.optimize && (formattedSong == 'spectral' || formattedSong == 'ectospasm'))
					GameOverSubstate.characterName = 'bf-wrath-death';
		}

		// Changable Characters

		if (curStage == 'wrath')
		{
			if (bfVersion == 'bf')
				bfVersion = 'bf-wrath';
			if (gfVersion == 'gf')
				gfVersion = 'gf-wrath';
		}

		var defaultBf = bfVersion;
		var defaultGf = gfVersion;

		if(gfVersion == null || gfVersion.length < 1) {
			switch (curStage)
			{
				case 'minus_sigma'|'minus_preppy'|'minus_overtime':
					gfVersion = 'gf-minus';
				default:
					gfVersion = 'gf';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		if (ClientPrefs.optimize)
		{
			gfVersion = 'gf-optim';
			bfVersion = 'bf-optim';
			foeVersion = 'foe-optim';
		}

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				opponent2: [0, 0],
				hide_opponent2: true,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		DAD2_X = stageData.opponent2[0];
		DAD2_Y = stageData.opponent2[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		hideGF = false;
		if(stageData.hide_girlfriend != null)
			hideGF = stageData.hide_girlfriend;

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file) && !ClientPrefs.optimize)
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush && !ClientPrefs.optimize)
			luaArray.push(new FunkinLua(luaFile));
		#end

		if (!stageData.hide_opponent2)
			SONG2 = Song.loadFromJson(formattedSong + Difficulty.getDifficultyFilePath(storyDifficulty) + '-2', formattedSong);
		else
			SONG2 = null;

		WindowTitle.progress(10);

		// (Tech) Confetti emitter for Minus
		if (curStage.contains('minus') && !ClientPrefs.optimize && ClientPrefs.particles) {
			confetti = new ConfettiEmitter(confettiSizeX, confettiSizeY);
			// (Tech) Mostly written by Neo, calculates correct index
			var position:Int = members.indexOf(gfGroup);

			if(members.indexOf(boyfriendGroup) < position)
				position = members.indexOf(boyfriendGroup);

			else if(members.indexOf(dadGroup) < position)
				position = members.indexOf(dadGroup);

			insert(position, confetti.confettiColorPools);
			//add(confetti.confettiColorPools);
		}

		if (curStage == 'wrath' && !ClientPrefs.optimize && ClientPrefs.background >= 1) {
			if (formattedSong == 'spectral')
			{
				// Particles to make it look fast
				spectralBGEmitter = new FlxEmitter(3500, -1000);
				spectralBGEmitter.launchMode = FlxEmitterMode.SQUARE;
				spectralBGEmitter.velocity.set(-2500, -0, -5000, 0);
				spectralBGEmitter.height = 3000;

				//var particle = new FlxSpriteExtra().makeSolid(50, 5);
				spectralBGEmitter.makeParticles(50, 5, FlxColor.WHITE, 500);
				//spectralBGEmitter.loadParticles(particle.graphic, 500);

				var possy = 7;
				if (modchartSprites['spectralDarkScreen'] != null) possy = members.indexOf(modchartSprites['spectralDarkScreen'])+1;

				insert(possy, spectralBGEmitter);
				//add(spectralBGEmitter);
				trace('particles added');
				spectralBGEmitter.emitting = false;
				//spectralBGEmitter.start(false, 0.025, 10000);
			}
		}

		if (!ClientPrefs.optimize && ClientPrefs.particles && (formattedSong == 'spectral' || genericSong == 'ectospasm') && curStage == 'wrath')
		{
			particles = new FlxTypedGroup<FlxEmitter>();

			for (i in 0...6)
			{
				var emitter:FlxEmitter = new FlxEmitter(-1000, 1500);
				emitter.launchMode = FlxEmitterMode.SQUARE;
				emitter.velocity.set(-50, -150, 50, -750, -100, 0, 100, -100);
				emitter.scale.set(0.75, 0.75, 3, 3, 0.75, 0.75, 1.5, 1.5);
				emitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
				emitter.width = 3500;
				emitter.alpha.set(1, 1, 0, 0);
				emitter.lifespan.set(3, 5);
				emitter.loadParticles(Paths.image('Particles/Particle' + i, 'shared'), 500, 16, true);
				particles.add(emitter);
				//trace('added particle number $i');
			}

			add(particles);
		}

		if (!ClientPrefs.optimize && ClientPrefs.particles && (formattedSong == 'corruptro') && curStage == 'wrath')
		{
			particles = new FlxTypedGroup<FlxEmitter>();

			for (i in 0...6)
			{
				var emitter:FlxEmitter = new FlxEmitter(-1000, 1500);
				emitter.launchMode = FlxEmitterMode.SQUARE;
				emitter.velocity.set(-50, -150, 50, -750, -100, 0, 100, -100);
				emitter.scale.set(0.75, 0.75, 3, 3, 0.75, 0.75, 1.5, 1.5);
				emitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
				emitter.width = 3500;
				emitter.alpha.set(1, 1, 0, 0);
				emitter.lifespan.set(3, 5);
				emitter.loadParticles(Paths.image('Particles/CorruptParticle' + i, 'shared'), 500, 16, true);
				particles.add(emitter);
				//trace('added particle number $i');
			}

			add(particles);
		}

		if (!ClientPrefs.optimize && ClientPrefs.particles && (formattedSong == 'heartmelter' || genericSong == 'fuzzy-feeling') && curStage == 'wrath')
		{
			particles = new FlxTypedGroup<FlxEmitter>();

			for (i in 0...6)
			{
				var emitter:FlxEmitter = new FlxEmitter(-1000, 1500);
				emitter.launchMode = FlxEmitterMode.SQUARE;
				emitter.velocity.set(-50, -250, 50, -850, -100, 0, 100, -150);
				emitter.scale.set(2, 2, 10, 10, 0.75, 0.75, 1.5, 1.5);
				emitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
				emitter.width = 3500;
				emitter.alpha.set(1, 1, 0, 0);
				emitter.lifespan.set(3, 5);
				emitter.loadParticles(Paths.image('Particles/Heart' + i, 'shared'), 500, 16, true);
				particles.add(emitter);
			}

			add(particles);
		}

		/*if (curStage.startsWith('minus') && !curStage.endsWith('postgame'))
		{
			gfVersion = 'gf-minus';
			bfVersion = 'bf-minus';
		}
		else if (curStage == 'minus_postgame')
		{
			bfVersion = 'retro-minus-player';
		}*/

		WindowTitle.progress(15);

		if (!hideGF)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gfMap.set(gf.curCharacter, gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);
			WindowTitle.progress(30);
		}

		dad = new Character(0, 0, foeVersion);
		dadMap.set(dad.curCharacter, dad);

		if(ClientPrefs.optimize)
			dad.healthIcon = HealthIcon.returnDefaultIcon(defaultFoe);

		WindowTitle.progress(40);

		if (SONG2 != null)
		{
			var secFoe = SONG2.player2;
			if (ClientPrefs.optimize) secFoe = 'foe-optim';
			dad2 = new Character(0, 0, secFoe);
			dadGroup.add(dad2);
			dad2.setPosition(DAD2_X, DAD2_Y);
			startCharacterPos(dad2);
			dad.healthIcon = dad2.healthIcon;
			startCharacterLua(dad2.curCharacter);
			//if (secFoe.startsWith('sakuroma-minus')) {
			//	dad2.x -= 425;
			//	dad2.y += 20;
			//}

			//dad2 = new Character(0, 0, secFoe);
			//dadGroup.add(dad2);
			//dad.healthIcon = dad2.healthIcon;
			//if (secFoe.startsWith('sakuroma-minus')) {
			//	dad2.x -= 425;
			//	dad2.y += 20;
			//}

			WindowTitle.progress(55);
		}
		else
			dad2 = null;
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		if (ClientPrefs.ghostTrails)
		{
			spriteTrail = new FlxTypedGroup<FlxSprite>();
			var position:Int = members.indexOf(dadGroup);
			insert(position, spriteTrail);
		}

		boyfriend = new Boyfriend(0, 0, bfVersion);
		boyfriendMap.set(boyfriend.curCharacter, boyfriend);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);

		if(ClientPrefs.optimize)
			boyfriend.healthIcon = HealthIcon.returnDefaultIcon(defaultBf);

		WindowTitle.progress(60);

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(cameraStartDad) {
			camPos.set(opponentCameraOffset[0] + 150, opponentCameraOffset[1] - 100);
			camPos.x += dad.getMidpoint().x + dad.cameraPosition[0];
			camPos.y += dad.getMidpoint().y + dad.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}


		// Special effects stuff
		if (ClientPrefs.windowShake)
		{
			windowOrigin = new FlxPoint(Application.current.window.x, Application.current.window.y);
			Application.current.window.onMove.add(onWindowMove);
		}

		switch(curStage)
		{

		}

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		//var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		//if (OpenFlAssets.exists(file)) {
		//	dialogue = CoolUtil.coolTextFile(file);
		//}
		//var doof:DialogueBoxOld = new DialogueBoxOld(dialogue);
		//if(!doof.noDialogue) {
		//	doof.scrollFactor.set();
		//	doof.finishThing = startCountdown;
		//	doof.nextDialogueThing = startNextDialogue;
		//	doof.skipDialogueThing = skipDialogue;
		//}
		var dialogBf = defaultBf == 'bf-wrath' ? 'bf' : defaultBf;
		dialogueBf = dialogBf;
		dialogueGf = defaultGf;
		var doofus:DialogueBox = null;
		if((freeplayDialogueSongs.contains(genericSong) && firstTry && !seenCutscene) ||
			(isStoryMode && firstTry && ((formattedSong != 'satisfracture') || ClientPrefs.optimize) && !seenCutscene)) {
			//doofus = new DialogueBox(curSong, bfCharacter, storyDifficulty, SONG.gfVersion);
			doofus = new DialogueBox(formattedSong, dialogueBf, storyDifficulty, dialogueGf);
			if (!doofus.noDialogue)
				doofus.scrollFactor.set();

			doofus.cameras = [camOther];
			dialogueBox = doofus;

			doofus.nextDialogueThing = startNextDialogue;
			doofus.skipDialogueThing = skipDialogue;
		}

		GhostSprite.initialize();

		WindowTitle.progress(70);

		Conductor.songPosition = -5000;

		strumLineX = ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		strumLineY = ClientPrefs.downScroll ? FlxG.height - 150 : 50;

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxFixedText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		timeTxt.active = false;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 8000; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		comboLayer = new FlxTypedGroup<FlxSprite>();
		comboLayer.cameras = [camHUD];
		add(comboLayer);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		if(!ClientPrefs.optimizedNotes && ClientPrefs.noteQuantization) {
			//SONG.splashSkin = "noteSplashes_retrobf";
			arrowSkinbf = "NOTE_assets_quant";
			if(ClientPrefs.opponentQuants) {
				arrowSkindad = "NOTE_assets_quant";
			}
		}

		if(ClientPrefs.noteSplashes) {
			if(splashSkin == null) {
				if(arrowSkinbf == "NOTE_assets_retrobf") {
					splashSkin = "noteSplashes_retrobf";
				}
			}

			if(arrowSkinbf == "NOTE_assets_quant") {
				splashSkin = "noteSplashes_quant";
			}

			var splash:NoteSplash = new NoteSplash(100, 100, 0);
			grpNoteSplashes.add(splash);
			splash.alpha = 0.0;
		}

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong();

		WindowTitle.progress(80);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		#end

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		if (ClientPrefs.optimize && (formattedSong == 'spectral' || genericSong == 'ectospasm')) defaultCamZoom = 0.525;

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		healthBar.numDivisions = 10000;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxFixedText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		scoreTxt.active = false;
		add(scoreTxt);

		botplayTxt = new FlxFixedText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		botplayTxt.active = false;
		add(botplayTxt);
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		//if(!doof.noDialogue) doof.cameras = [camHUD];

		#if android
		addAndroidControls();
		androidControls.visible = true;
		#end
			
		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + formattedSong + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + formattedSong + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + formattedSong + '/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file) && !ClientPrefs.optimize)
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		hasIceNotes = noteTypeMap.exists('iceNote');

		WindowTitle.progress(90);

		//var daSong:String = Paths.formatToSongPath(curSong);

		trace(isStoryMode, firstTry, !seenCutscene, freeplayDialogueSongs.contains(genericSong));

		if (isStoryMode && firstTry && !seenCutscene)
		{
			switch (StringTools.replace(curSong, " ", "-").toLowerCase())
			{
				case 'satisfracture':
					//healthBar.visible = false;
					//healthBarBG.visible = false;
					//iconP1.visible = false;
					//iconP2.visible = false;
					//scoreTxt.visible = false;
					hideHUD();
					if(!ClientPrefs.optimize)
						introCutscene();
					else
					{
						if (doofus != null && !doofus.noDialogue)
						{
							hideHUD();
							startDialogueSimple(doofus);

							doofus.finishThing = function()
							{
								showHUD();
								startCountdown();
							};
						} else {
							startCountdown();
						}
					}
				case 'sigma':
					if (doofus != null && !doofus.noDialogue)
					{
						hideHUD();

						announceStart = true;
						inCutscene = true;

						var white = new FlxSpriteExtra(-300, -200).makeSolid(Std.int(FlxG.width * 1.5), Std.int(FlxG.height * 1.5), FlxColor.WHITE);
						white.cameras = [camHUD];
						white.scrollFactor.set();
						add(white);

						var textToType:String = '3 Weeks later...';
						var dropText = new FlxFixedText(5, 5, FlxG.width, " ", 80);
						dropText.setFormat(Paths.font('EastSeaDokdo.ttf'), 80, FlxColor.RED, CENTER);
						dropText.cameras = [camHUD];
						dropText.scrollFactor.set();
						dropText.screenCenter(Y);
						dropText.y += 5;
						add(dropText);
						var swagDialogue = new FlxFixedText(0, 0, FlxG.width, " ", 80);
						swagDialogue.setFormat(Paths.font('EastSeaDokdo.ttf'), 80, FlxColor.BLACK, CENTER);
						swagDialogue.cameras = [camHUD];
						swagDialogue.scrollFactor.set();
						swagDialogue.screenCenter(Y);
						add(swagDialogue);

						PlayState.instance.camFollow.y -= 500;

						new FlxTimer().start(0.1, function(tmr:FlxTimer) {
							//FlxG.sound.play(Paths.sound('retroText'));
							swagDialogue.text = textToType.substr(0, tmr.elapsedLoops);
							dropText.text = swagDialogue.text;
						}, textToType.length);

						FlxTween.color(dropText, 4, FlxColor.RED, FlxColor.CYAN, {onComplete:
							function (twn:FlxTween) {
								FlxTween.tween(dropText, {alpha: 0}, 1, {onComplete:
									function (subtwn:FlxTween) {
										remove(dropText, true);
										dropText.destroy();
									}
								});
								FlxTween.tween(swagDialogue, {alpha: 0}, 1, {onComplete:
									function (subtwn:FlxTween) {
										remove(swagDialogue, true);
										swagDialogue.destroy();
									}
								});
							}
						});

						FlxTween.tween(white, {alpha: 0}, 1, {startDelay: 4, onComplete:
							function (twn:FlxTween) {
								remove(white, true);
								white.destroy();
							}
						});

						new FlxTimer().start(5.0, function(tmr:FlxTimer) {

							// (Tech) Dialogue ambiaence is handled in DialogueBox.hx, no need to do it here
							// sigmaAmbiance = new FlxSound().loadEmbedded(Paths.music('Dialogue_Ambience', 'minus'), true, true);
							// sigmaAmbiance.volume = 0;
							// sigmaAmbiance.fadeIn(1, 0, 0.2);
							// FlxG.sound.list.add(sigmaAmbiance);

							startDialogueSimple(doofus);
							doofus.finishThing = function()
							{
								if(ClientPrefs.optimize) showHUD();
								startCountdown();
							}
						});
					}
					else
						startCountdown();
				default:
					if (doofus != null && !doofus.noDialogue)
					{
						hideHUD();
						startDialogueSimple(doofus);

						doofus.finishThing = function()
						{
							if ((curSong.toLowerCase() != 'spectral' && !ClientPrefs.optimize) || ClientPrefs.optimize) showHUD();
							inCutscene = false;
							startCountdown();
						};
					} else
						startCountdown();
			}
		}
		else if ((freeplayDialogueSongs.contains(genericSong) || freeplayDialogueSongs.contains(formattedSong)) && firstTry && !seenCutscene)
		{
			if (doofus != null && !doofus.noDialogue)
			{
				hideHUD();
				startDialogueSimple(doofus);

				doofus.finishThing = function()
				{
					showHUD();
					startCountdown();
				};
			} else {
				startCountdown();
			}
		}
		else
		{
			startCountdown();
		}

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) CoolUtil.precacheSound('hitsound');
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');

		if (PauseSubState.songName != null) {
			CoolUtil.precacheMusic(PauseSubState.songName);
		} else if(ClientPrefs.pauseMusic != 'None') {
			CoolUtil.precacheMusic(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, detailsSongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		if (isStoryMode && firstTry && !seenCutscene && !ClientPrefs.optimize)
		{
			if (firstTry && (formattedSong == 'satisfracture'))
			{
				dad.visible = false;
				cutsceneSprite = new Character(80, 60, 'IntroCutscene');
				startCharacterPos(cutsceneSprite);
				//cutsceneSprite.scale.set(2,2);
				cutsceneSprite.updateHitbox();
				cutsceneSprite.playAnim('IntroCutscene');
				cutsceneSprite.animation.paused = true;
				add(cutsceneSprite);
			}
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;

		for (n in unspawnNotes)
		{
			n.reloadNoteInfo();
		}

		if(noteTypeMap.exists('spectre')) {
			CoolUtil.precacheSound('SpectreArrow','shared');
			spectreSound = new FlxSound().loadEmbedded(Paths.sound('SpectreArrow', 'shared'));
			FlxG.sound.list.add(spectreSound);
			FlxG.bitmap.add(Paths.image('SpectreHit', 'shared'));
		}
		if(noteTypeMap.exists('poison')) {
			CoolUtil.precacheSound('acid','shared');
			poisonSound = new FlxSound().loadEmbedded(Paths.sound('acid', 'shared'));
			FlxG.sound.list.add(poisonSound);
			FlxG.bitmap.add(Paths.image('PoisonArrowHit', 'shared'));
		}
		if(noteTypeMap.exists('iceNote')) {
			CoolUtil.precacheSound('icey','shared');
			FlxG.bitmap.add(Paths.image('iceolation/IceBreakAnim', 'shared'));
		}
		if(noteTypeMap.exists('sakuNote')) {
			CoolUtil.precacheSound('sakulaff','shared');
			CoolUtil.precacheSound('sakuNote','shared');
			sakuLaugh = new FlxSound().loadEmbedded(Paths.sound('sakulaff', 'shared'));
			sakuNote = new FlxSound().loadEmbedded(Paths.sound('sakuNote', 'shared'));
			FlxG.sound.list.add(sakuLaugh);
			FlxG.sound.list.add(sakuNote);
		}

		if(formattedSong == 'icebreaker') {
			FlxG.bitmap.add(Paths.image('iceolation/happyending'));
			FlxG.bitmap.add(Paths.image('iceolation/angryending'));
		}

		if (hasWrathBar) {
			setWrathBar();
		}

		callOnLuas('onCreatePost', []);

		cachePopUpScore();

		WindowTitle.progress(100);

		// Game over hint stuff
		if(GameOverSubstate.shouldLoadGameOverDialogue()) {
			retroPortrait = GameOverSubstate.loadRetroPortrait();
			speechBubble = GameOverSubstate.loadSpeechBubble();

			retroPortrait.cameras = [camOther];
			speechBubble.cameras = [camOther];

			trace("Loaded Ectospasm Gameover");
		}

		if(ClientPrefs.precachedDeaths) {
			addCharacterToList(GameOverSubstate.characterName, 0);
		}

		updateHealthGraphics();

		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		super.create();

		Paths.clearUnusedMemory();

		CustomFadeTransition.nextCamera = camOther;
		openfl.system.System.gc();

		WindowTitle.defaultTitle();
	}

	/**	(Arcy)
	*	Method used to hide the HUD for cutscene stuff.
	*/
	function hideHUD()
	{
		healthBar.alpha = 0.000001;
		healthBarBG.alpha = 0.000001;
		iconP1.alpha = 0.000001;
		iconP2.alpha = 0.000001;
		scoreTxt.alpha = 0.000001;
		botplayTxt.visible = false;

		if (poisonTxt != null && poisonIcon != null)
		{
			poisonTxt.alpha = 0.000001;
			poisonIcon.alpha = 0.000001;
		}
	}

	/**	(Arcy)
	 *	Method used to reveal the hud, usually after cutscenes are done.
	 * @param	fadeIn	Flag for whether the HUD should fade in or not. Set to true by default.
	 */
	function showHUD(fadeIn:Bool = true)
	{
		var alpha = ClientPrefs.healthBarAlpha;

		if (fadeIn)
		{
			FlxTween.tween(healthBar, {alpha: alpha}, 0.5);
			FlxTween.tween(healthBarBG, {alpha: alpha}, 0.5);
			FlxTween.tween(iconP1, {alpha: alpha}, 0.5);
			FlxTween.tween(iconP2, {alpha: alpha}, 0.5);
			FlxTween.tween(scoreTxt, {alpha: 1}, 0.5);
			if (poisonTxt != null && poisonIcon != null)
			{
				FlxTween.tween(poisonTxt, {alpha: alpha}, 0.5);
				FlxTween.tween(poisonIcon, {alpha: alpha}, 0.5);
			}
		}
		else
		{
			healthBar.alpha = alpha;
			healthBarBG.alpha = alpha;
			iconP1.alpha = alpha;
			iconP2.alpha = alpha;
			scoreTxt.alpha = 1;
			if (poisonTxt != null && poisonIcon != null)
			{
				poisonTxt.alpha = alpha;
				poisonIcon.alpha = alpha;
			}
		}
		if (ClientPrefs.gameplaySettings['botplay']) botplayTxt.visible = true;
	}

	function onWindowMove(x:Float, y:Float):Void
	{
		windowOrigin.set(x, y);
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes)
			{
				if(note.isSustainNote && !note.isHoldEnd)
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if(note.isSustainNote && !note.isHoldEnd)
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			if(blah == null) {
				blah.destroy();
				luaDebugGroup.remove(blah, true);
			}
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarColors() {
		if(isWrathBar) return;

		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));

		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					newBoyfriend.shaderEnabled = false;
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					newDad.shaderEnabled = false;
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.shaderEnabled = false;
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush)
		{
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void {
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXT); #else ''; #end
		#if desktop
		if(FileSystem.exists(fileName)) {
			foundFile = true;
		}
		#end

		if(!foundFile) {
			fileName = Paths.video(name);
			#if desktop
			if(FileSystem.exists(fileName))
			#else
			if(OpenFlAssets.exists(fileName))
			#end
			{
				foundFile = true;
			}
		}

		if(foundFile) {
			inCutscene = true;
			var bg = new FlxSpriteExtra(-FlxG.width, -FlxG.height).makeSolid(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);
				startAndEnd();
			}
			return;
		}
		else
		{
			FlxG.log.warn('Couldnt find video file: ' + fileName);
			startAndEnd();
		}
		#end
		startAndEnd();
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					inDialogue = false;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					inDialogue = false;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			inDialogue = true;
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function startDialogueSimple(?dialogueBox:DialogueBox):Void
	{
		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			if (dialogueBox != null)
			{
				inDialogue = true;
				inCutscene = true;
				add(dialogueBox);
			}
			else
			{
				startCountdown();
			}
		});
	}

	var inDialogue:Bool = false;
	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		seenCutscene = true;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if (skipCountdown || startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 500);
				return;
			}

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', 'set', 'go']);
			introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var antialias:Bool = ClientPrefs.globalAntialiasing;
			if(isPixelStage) {
				introAlts = introAssets.get('pixel');
				antialias = false;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
				}

				if (dad2 != null && tmr.loopsLeft % dad2.danceEveryNumBeats == 0 && dad2.animation.curAnim != null && !dad2.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad2.dance();
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						add(countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								destroySprite(countdownReady);
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						add(countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								destroySprite(countdownSet);
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						add(countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								destroySprite(countdownGo);
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
				}

				if(genericSong != "fuzzy-feeling") {
					notes.forEachAlive(function(note:Note) {
						if(ClientPrefs.opponentStrums || note.mustPress)
						{
							note.copyAlpha = false;
							note.alpha = note.multAlpha;
							if(ClientPrefs.middleScroll && !note.mustPress) {
								note.alpha *= 0.35;
							}
						}
					});
				}
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
			}, 5);
		}
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 500 < time)
			{
				daNote.ignoreNote = true;
				destroyNoteUnspawn(daNote);
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 500 < time)
			{
				daNote.ignoreNote = true;
				destroyNote(daNote);
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		vocals.time = time;
		vocals.play();
		Conductor.songPosition = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;

		FlxG.sound.playMusic(Paths.inst(instToLoad), 1, false);
		FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		if (SONG.instVol == null)
		{
			SONG.instVol = 1;
		}
		if (SONG.vocalVol == null)
		{
			SONG.vocalVol = 1;
		}

		FlxG.sound.music.volume = SONG.instVol;
		vocals.volume = SONG.vocalVol;

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, detailsSongName + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);

		if (!ClientPrefs.optimize && ClientPrefs.particles && (formattedSong == 'spectral' || genericSong == 'ectospasm') && particles != null) {
			particles.forEach(function(emitter:FlxEmitter) {
				if (!emitter.emitting)
					emitter.start(false, FlxG.random.float(0.1, 0.2), 100000);
				//trace('now it emits lol');
			});
		}
		Paths.clearUnusedMemory();
		MemoryUtils.clearMajor();

		//trace(Paths.localTrackedAssets);
	}

	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	var vocalsFinished:Bool = false;

	private function generateSong():Void
	{
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		songSpeed *= (PlayState.storyDifficulty == Difficulty.APOCALYPSE && trueEctospasm) ? 1.4 : 1;

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(voicesToLoad));
		else
			vocals = new FlxSound();

		vocals.onComplete = function()
		{
			vocalsFinished = true;
		}

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(instToLoad)));

		notes = new FlxTypedGroup<Note>();
		notes.active = false;
		add(notes);

		var noteData:Array<SwagSection> = SONG.notes;

		var songName:String = formattedSong;
		var file:String = Paths.json(songName + '/events');
		#if desktop
		if ((FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) && !ClientPrefs.optimize)
		#else
		if (OpenFlAssets.exists(file) && !ClientPrefs.optimize)
		#end
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		addNotes(noteData, false);
		if (SONG2 != null)
		{
			noteData = SONG2.notes;
			addNotes(noteData, true);
		}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		if (!ClientPrefs.optimize && ClientPrefs.mechanics && formattedSong == 'icebreaker')
		{
			var iceAmount:Int = switch(Difficulty.difficultyString().toLowerCase()) {
				case "normal": 40; // original chart: 39
				case "hard": 50; // original chart: 41
				case "hell": 75;

				default: 0;
			}
			var validNotes:Array<Note> = [];
			var playerNotes:Array<Note> = [];
			for (i in 0...unspawnNotes.length)
			{
				if (unspawnNotes[i].mustPress && !unspawnNotes[i].isSustainNote && unspawnNotes[i].sustainLength == 0)
					validNotes.push(unspawnNotes[i]);
				if (unspawnNotes[i].mustPress)
					playerNotes.push(unspawnNotes[i]);
			}
			for (i in 0...iceAmount)
			{
				// No more ice notes can be added
				if (validNotes.length == 0)
					break;

				var targetNote = validNotes[FlxG.random.int(0, validNotes.length - 1)];
				var validArray:Array<Int> = [0, 1, 2, 3];

				// Check which notes we can use
				for (j in 0...playerNotes.length)
				{
					if (Math.abs(playerNotes[j].strumTime - targetNote.strumTime) < 0.25)
						validArray.remove(playerNotes[j].noteData);
				}

				// All four notes are being used. Skip this instance
				if (validArray.length == 0)
					continue;

				var noteData = validArray[FlxG.random.int(0, validArray.length - 1)];
				var isValid = true;

				// Check if there are notes nearby
				for (j in 0...playerNotes.length)
				{
					var timeDiff = playerNotes[j].strumTime - targetNote.strumTime;
					if (playerNotes[j].noteData == noteData && Math.abs(timeDiff) < 50) {
						isValid = false;
						break;
					}
					if (playerNotes[j].noteData == noteData && timeDiff >= 0 && timeDiff < 100) {
						isValid = false;
						break;
					}
				}

				if(!isValid)
					continue;

				// Add in the ice note
				var newNote:Note = new Note(targetNote.strumTime, noteData, true, null);
				newNote.mustPress = true;
				newNote.sustainLength = 0;
				newNote.gfNote = false;
				newNote.secondDad = false;
				newNote.noteType = "iceNote";
				newNote.playNoteAnim();

				newNote.scrollFactor.set();
				noteTypeMap.set(newNote.noteType, true);

				unspawnNotes.push(newNote);
				allNotes.push(newNote);
				playerNotes.push(newNote);
				validNotes.remove(targetNote);
			}
		}

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();

		if (randomMode || (PlayState.storyDifficulty == Difficulty.APOCALYPSE && trueEctospasm))
		{
			// Variables needed for any double/triple/quad notes
			var prevStrumTime:Float = -1;
			var validNotes:Array<Bool> = [true, true, true, true];
			var noteID:Int = 0;

			var newNote:Note;
			//var index:Int;
			var groupedNotes:Array<Note> = [];

			var holdNotes:Array<Note> = [];
			var playerNotes:Array<Note> = [];
			for (i in 0...unspawnNotes.length)
			{
				if (unspawnNotes[i].mustPress)
					playerNotes.push(unspawnNotes[i]);
				if (unspawnNotes[i].mustPress && (unspawnNotes[i].isSustainNote || unspawnNotes[i].children.length != 0))
					holdNotes.push(unspawnNotes[i]);
			}

			function randomizeNotes() {
				// Check which notes we can use
				//for (j in 0...holdNotes.length)
				//{
				//	if (Math.abs(holdNotes[j].strumTime - prevStrumTime) < Conductor.stepCrochet) {
				//		validNotes[holdNotes[j].noteData] = false;
				//	}
				//}
				

				// Set sustain notes first
				for (i in 0...groupedNotes.length)
				{
					if (groupedNotes[i].isSustainNote)
					{
						newNote = groupedNotes[i]; // Unchanged from normal chart
						//index = unspawnNotes.indexOf(newNote); // Store index for replacing later
						//newNote.changeNoteDirection(newNote.prevNote.noteData); // Set the new direction
						var noteData = newNote.parent.noteData;//newNote.prevNote.noteData;
						if (!newNote.prevNote.isSustainNote || newNote.isHoldEnd)
						newNote.changeNoteDirection(noteData); // Set the new direction
						newNote.prevNote.changeNoteDirection(noteData);
						if(newNote.parent.children[0] != newNote)
						validNotes[noteData] = false; // Eliminate this direction as a choice
						//unspawnNotes[index] = newNote; // Replace the note
						
					}
				}

				// TODO: Fix notes appearing over holds

				// Then randomized presses
				for (i in 0...groupedNotes.length)
				{
					if (!groupedNotes[i].isSustainNote)
					{
						newNote = groupedNotes[i]; // Unchanged from normal chart
						//index = unspawnNotes.indexOf(newNote); // Store index for replacing later
						noteID = CoolUtil.getRandomNoteData(validNotes); // Random direction
						validNotes[noteID] = false; // Eliminate this direction as a choice
						newNote.changeNoteDirection(noteID); // Change the direction
						//unspawnNotes[index] = newNote; // Replace the note

if(validNotes[noteID] == false) {
    trace("full array", newNote.noteType);
}

if(validNotes[noteID] == false) {
for(note in groupedNotes) {
    trace(note.noteData, note.noteType, note.isSustainNote, note.strumTime);

}
}
					}
				}

				/*for (i in 0...groupedNotes.length)
				{
					if (groupedNotes[i].isSustainNote)
					{
						newNote = groupedNotes[i]; // Unchanged from normal chart
						if(newNote.noteData != newNote.prevNote.noteData) {
							validNotes[newNote.prevNote.noteData] = false; // Eliminate this direction as a choice
						} else {
							validNotes[newNote.noteData] = false; // Eliminate this direction as a choice
						}
						//unspawnNotes[index] = newNote; // Replace the note
					}
				}

				// Then randomized presses
				for (i in 0...groupedNotes.length)
				{
					if (!groupedNotes[i].isSustainNote)
					{
						newNote = groupedNotes[i]; // Unchanged from normal chart

						// Check which notes we can use
						for (j in 0...holdNotes.length)
						{
							if (Math.abs(holdNotes[j].strumTime - newNote.strumTime) < Conductor.stepCrochet && newNote != holdNotes[j]) {
								validNotes[holdNotes[j].noteData] = false;
							}
						}

						for (j in 0...playerNotes.length)
						{
							if (Math.abs(playerNotes[j].strumTime - newNote.strumTime) < 10 && newNote != playerNotes[j]) {
								validNotes[playerNotes[j].noteData] = false;
							}
						}

						//index = unspawnNotes.indexOf(newNote); // Store index for replacing later
						noteID = CoolUtil.getRandomNoteData(validNotes); // Random direction
						validNotes[noteID] = false; // Eliminate this direction as a choice
						newNote.changeNoteDirection(noteID); // Change the direction
						for(sus in newNote.children) {
							sus.changeNoteDirection(noteID); // Change the direction
						}
						//unspawnNotes[index] = newNote; // Replace the note
					}
				}*/

				groupedNotes.splice(0, groupedNotes.length);
			}

			for(holdNote in playerNotes)
				if(holdNote.isSustainNote)
					holdNote.strumTime -= Conductor.stepCrochet / songSpeed;

			for (note in playerNotes)
			{
				// Skip Retro's notes
				if (!note.mustPress)
					continue;

				if (note.strumTime - prevStrumTime < 0.000000001)
				{
					groupedNotes.push(note);
				}
				else
				{
					randomizeNotes();

					// Now start the cycle again
					validNotes = [true, true, true, true];
					groupedNotes.push(note);
				}

				// And record last strum time for multi-notes
				prevStrumTime = note.strumTime;
			}

			randomizeNotes();
			for(holdNote in playerNotes)
				if(holdNote.isSustainNote)
					holdNote.strumTime += Conductor.stepCrochet / songSpeed;

		}

		for (n in unspawnNotes)
		{
			if (n.noteType == '')
				n.reloadNote();
		}
		generatedMusic = true;
	}

	function addNotes(noteData:Array<SwagSection>, secondDad:Bool = false) {
		var speed = FlxMath.roundDecimal(songSpeed, 2);

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				//continue;
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, gottaHitNote, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));
				swagNote.secondDad = secondDad;
				if(!Std.isOfType(songNotes[3], String))
					swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				else
					swagNote.noteType = songNotes[3];

				if (!ClientPrefs.mechanics && swagNote.isMechanicNote) continue; // (Arcy) Skip any special notes

				// Quantization colors need to be calculated before playing the note animation
				swagNote.playNoteAnim();

				swagNote.scrollFactor.set();

				oldNote = swagNote;

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);
				allNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					var susOffset = Conductor.stepCrochet / speed;
					for (susNote in 0...floorSus+1)
					{
						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + susOffset, daNoteData, gottaHitNote, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.secondDad = secondDad;

						// Quantization colors need to be calculated before playing the note animation
						sustainNote.playNoteAnim();
						oldNote.playNoteAnim();

						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);
						allNotes.push(sustainNote);

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}

						sustainNote.parent = swagNote;
						swagNote.children.push(sustainNote);

						oldNote = sustainNote;
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				noteTypeMap.set(swagNote.noteType, true);
			}
		}
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
		}

		eventPushedMap.set(event.event, true);
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		var skin = player == 1 ? arrowSkinbf : arrowSkindad;

		var targetAlpha:Float = 1;
		if (player < 1)
		{
			if(!ClientPrefs.opponentStrums) targetAlpha = 0;
			else if(ClientPrefs.middleScroll) targetAlpha = 0.35;
		}

		var dataDir = ["left", "down", "up", "right"];

		for (i in 0...4)
		{
			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLineY, i, player, skin);
			babyArrow.downScroll = ClientPrefs.downScroll;

			if (!isStoryMode && !skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for(camera in FlxG.cameras.list) {
				if(camera != null) {
					camera.shakeEnabled = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}

			for(camera in FlxG.cameras.list) {
				if(camera != null) {
					camera.shakeEnabled = true;
				}
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, detailsSongName + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, detailsSongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, detailsSongName + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, detailsSongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, detailsSongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();
		FlxG.sound.music.play();

		Conductor.songPosition = FlxG.sound.music.time;

		if (vocalsFinished)
			return;

		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	//public var loaded:Bool = false;

	override public function update(elapsed:Float)
	{
		//if(!loaded) return;

		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}*/

		callOnLuas('onUpdate', [elapsed]);

		switch (curStage)
		{

		}

		if(!inCutscene || inDialogue) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			if(cameraMoving)
				camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		updateWrathBar(elapsed);
		super.update(elapsed);

		if (ClientPrefs.windowShake && (Application.current.window.x != windowOrigin.x || Application.current.window.y != windowOrigin.y))
		{
			if (Application.current.window.x < windowOrigin.x)
				Application.current.window.x++;
			else
				Application.current.window.x--;

			if (Application.current.window.y < windowOrigin.y)
				Application.current.window.y++;
			else
				Application.current.window.y--;
		}

		if(ratingName == '?') {
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName;
		} else {
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;//peeps wanted no integer rating
		}

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (startedCountdown && canPause && controls.PAUSE)
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if(ret != FunkinLua.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				openSubState(new PauseSubState());

				#if desktop
				DiscordClient.changePresence(detailsPausedText, detailsSongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		if (!endingSong && !inCutscene && FlxG.keys.anyJustPressed(debugKeysChart))
		{
			openChartEditor();
		}
		#if debug
		if(FlxG.keys.justPressed.F5) {
			persistentUpdate = false;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new ClearCacheState(PlayState));
		}
		#end

		var lerpVal = CoolUtil.boundTo(1 - (elapsed * 9), 0, 1);

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, lerpVal);
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, lerpVal);
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		if ((
			(formattedSong == 'satisfracture-remix' && curStep >= 252 && curStep < 256) ||
			((formattedSong == 'satisfracture' || formattedSong == 'satisflatter') && curStep >= 188 && curStep < 192)
			) && enoughTxt != null)
		{
			// (neo) Shouldnt this be 15?
			// (candy) ya
			enoughTxt.setPosition(FlxG.random.float(-15, 15) + enoughTxtOrigin.x, FlxG.random.float(-15, 15) + enoughTxtOrigin.y);
		}

		if ((
			(formattedSong == 'overtime' && curStep >= 1790.2 && curStep < 1802)
		) && overtimeTxt != null)
		{
			overtimeTxt.setPosition(FlxG.random.float(-7, 7) + overtimeTxtOrigin.x, FlxG.random.float(-7, 7) + overtimeTxtOrigin.y);
		}


		if (ClientPrefs.shaders && ClientPrefs.chromatic && chrom != null)
		{
			if (chrom.rOffset.value[1] > 0)
			{
				chrom.rOffset.value[1] -= 0.01 * elapsed;
			}
			else if (chrom.rOffset.value[1] < 0)
			{
				chrom.rOffset.value[1] = 0;
			}

			if (chrom.gOffset.value[0] < 0)
			{
				chrom.gOffset.value[0] += 0.01 * elapsed;
			}
			else if (chrom.gOffset.value[0] > 0)
			{
				chrom.gOffset.value[0] = 0;
			}

			if (chrom.gOffset.value[1] < 0)
			{
				chrom.gOffset.value[1] += 0.01 * elapsed;
			}
			else if (chrom.gOffset.value[1] > 0)
			{
				chrom.gOffset.value[1] = 0;
			}

			if (chrom.bOffset.value[0] > 0)
			{
				chrom.bOffset.value[0] -= 0.01 * elapsed;
			}
			else if (chrom.bOffset.value[0] < 0)
			{
				chrom.bOffset.value[0] = 0;
			}

			if (chrom.bOffset.value[1] < 0)
			{
				chrom.bOffset.value[1] += 0.01 * elapsed;
			}
			else if (chrom.bOffset.value[1] > 0)
			{
				chrom.bOffset.value[1] = 0;
			}
		}

		if (!endingSong && !inCutscene && FlxG.keys.anyJustPressed(debugKeysCharacter)) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(foeVersion));
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += elapsed * 1000;

			if (!paused)
			{
				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					if(ClientPrefs.timeBarType != 'Song Name') {
						var songCalc:Float = (songLength - curTime);
						if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

						var secondsTotal:Int = Math.floor(songCalc / 1000);
						if(secondsTotal < 0) secondsTotal = 0;

						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
					}
				}
			}
		}

		if (camZooming)
		{
			var lerpVal = CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1);
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, lerpVal);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, lerpVal);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes.length > 0)
		{
			var time:Float = 3000;//shit be werid on 4:3
			if(songSpeed < 1) time /= songSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			notes.update(elapsed);

			if (!inCutscene) {
				if(!cpuControlled) {
					keyShit();
				} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
					//boyfriend.animation.curAnim.finish();
				}
			}

			var isFakeNotesSatis = (genericSong == 'satisfracture' && curStep >= 187 && curStep <= 192);
			var isFakeNotesSatisRemix = (formattedSong == 'satisfracture-remix' && curStep >= 251 && curStep <= 256);
			var boundNoteOpacity = CoolUtil.boundTo(noteOpacity, 0, 1);
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if(!daNote.mustPress) strumGroup = opponentStrums;

				var strum = strumGroup.members[daNote.noteData];

				var strumX:Float = strum.x;
				var strumY:Float = strum.y;
				var strumAngle:Float = strum.angle;
				var strumDirection:Float = strum.direction;
				var strumAlpha:Float = strum.alpha;
				var strumScroll:Bool = strum.downScroll;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle + daNote.offsetAngleQuant;
				strumAlpha *= daNote.multAlpha;

				if (strumScroll) //Downscroll
				{
					daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
				}
				else //Upscroll
				{
					daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
				}

				// cool little effect on satisfracture :3
				if (daNote.mustPress && isFakeNotesSatis)
				{
					daNote.distance = ((0.45 * ((187 * Conductor.stepCrochet) - daNote.strumTime) * songSpeed) * (strumScroll ? 1:-1));
				}
				if (daNote.mustPress && isFakeNotesSatisRemix)
				{
					daNote.distance = ((0.45 * ((251 * Conductor.stepCrochet) - daNote.strumTime) * songSpeed) * (strumScroll ? 1:-1));
				}

				var angleDir = strumDirection * Math.PI / 180;
				if (daNote.copyAngle)
					daNote.angle = strumDirection - 90 + strumAngle;

				if(daNote.copyAlpha)
					daNote.alpha = strumAlpha;

				if (hasSpecterNoteMechanic && ClientPrefs.mechanics && daNote.sustainActive)
				{
					if(!daNote.isSpectreNote) {
						if (daNote.mustPress)
						{
							// Change opacity in Ectospasm
							daNote.alpha = boundNoteOpacity * strum.alpha;
						}
						else
						{
							if (!enemySpectreHit)
							{
								daNote.alpha = boundNoteOpacity * strum.alpha;
							}
							else if (daNote.alpha == boundNoteOpacity * strum.alpha)
							{
								FlxTween.tween(daNote, {alpha: 1}, 0.5);
							}
						}
					}
				}

				var specialOffsetX = daNote.specialOffsetX;

				if (!daNote.mustPress) specialOffsetX = 0;

				if(daNote.copyX)
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance + specialOffsetX;

				if(daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					if(strumScroll && daNote.isSustainNote)
					{
						if (daNote.isHoldEnd) {
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
							if(PlayState.isPixelStage) {
								daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
							} else {
								daNote.y -= 19;
							}
						}
						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				if (ClientPrefs.downScroll && daNote.isSpectreNote)
				{
					daNote.y -= daNote.height / 2;
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					opponentNoteHit(daNote);
				}

				if(daNote.mustPress && cpuControlled) {
					if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit)) {
						goodNoteHit(daNote);
					}
				}

				var center:Float = strumY + Note.swagWidth / 2;
				if(strum.sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
					(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(daNote.frame.offset.x, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(daNote.frame.offset.x, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
				{
					if (daNote.mustPress && !cpuControlled && !daNote.canMiss && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						if(!daNote.sustainActive && daNote.isSustainNote) {
							missAnimation(daNote);
						} else {
							noteMiss(daNote);
						}
					}

					destroyNote(daNote);
				}
			});
		}
		checkEventNote();

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);

		updateHealthGraphics();

		boyfriend.updateWrath();
		dad.updateWrath();
		if(dad2 != null) dad2.updateWrath();
		if(gf != null) gf.updateWrath();

		if (frozen.contains(true))
		{
			frozenTime += elapsed;
			if (frozenTime > (Conductor.stepCrochet / 1000) * 12)
			{
				for (i in 0...4)
				{
					frozen[i] = false;
					strumsBlocked[i] = false;
					playerStrums.members[i].frozen = false;
					playerStrums.members[i].playAnim('static');
					playerStrums.members[i].resetAnim = 0;
				}

				frozenTime = 0;
			}
		}
	}

	var iconOffset:Int = 26;

	function updateHealthGraphics()
	{
		if (health > 2)
			health = 2;

		var percent:Float = 1 - (health / 2);
		var bfPercent:Float = (health / 2);

		var remappedHealth:Float = healthBar.x + (healthBar.width * (percent));

		iconP1.x = remappedHealth + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = remappedHealth - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		/*if (bfPercent >= .99)
		{
			if(iconP1.totalFrames > 3) {
				iconP1.animation.curAnim.curFrame = 3; // Winning Extra
			}
		}
		else */if (bfPercent > .8 && iconP1.totalFrames > 2)
		{
			iconP1.animation.curAnim.curFrame = 2; // Winning
		}
		else if (bfPercent < .2)
		{
			iconP1.animation.curAnim.curFrame = 1; // Losing
		}
		else
		{
			iconP1.animation.curAnim.curFrame = 0; // Neutral
		}

		if (percent >= .99 && iconP2.totalFrames > 3)
		{
			iconP2.animation.curAnim.curFrame = 3; // Winning Extra
		}
		else if (percent > .8 && iconP2.totalFrames > 2)
		{
			iconP2.animation.curAnim.curFrame = 2; // Winning
		}
		else if (percent < .2)
		{
			iconP2.animation.curAnim.curFrame = 1; // Losing
		}
		else
		{
			iconP2.animation.curAnim.curFrame = 0; // Neutral
		}
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				firstTry = false;

				if(vocals != null) vocals.stop();
				if(FlxG.sound.music != null) FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, detailsSongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	function cameraFromString(cam:String):FlxCamera {
		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': return camHUD;
			case 'camother' | 'other': return camOther;
		}
		return camGame;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Set Default Zoom':
				var camZoom:Float = Std.parseFloat(value1);
				if(!Math.isNaN(camZoom)) {
					defaultCamZoom = camZoom;
				}
			case 'Flash':
				if(ClientPrefs.flashing) {
					var camera = cameraFromString(value1);

					var duration:Float = Std.parseFloat(value2);
					if(Math.isNaN(duration)) duration = 1;

					camera.flash(0xFFFFFFFF, duration, null, true);
					@:privateAccess camera.updateFlash(0);
				}

			case 'Play Animation':
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend.shaderEnabled = false;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							boyfriend.shaderEnabled = true;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad.shaderEnabled = false;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							dad.shaderEnabled = true;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf.shaderEnabled = false;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
								gf.shaderEnabled = true;
							}
							setOnLuas('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			// (Tech) 1 is the regular burst, 2 is the big burst
			case 'Confetti Burst':
				if (confetti != null) {
					switch(value1.toLowerCase().trim()) {
						case '1':
							confetti.throwConfetti(-200, 1900, -100, 500, 2, 5);

						case '2':
							confetti.throwConfetti(-1000, 2700, -100, 500, 5, 10);

					}
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;

		if (gf != null && SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			//tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			//tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			//if (formattedSong == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			//{
			//	cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
			//		function (twn:FlxTween)
			//		{
			//			cameraTwn = null;
			//		}
			//	});
			//}
		}
	}

	function tweenCamIn() {
		if (formattedSong == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	//Any way to do this without using a different function? kinda dumb
	private function onSongComplete()
	{
		finishSong(false);
	}
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				Highscore.saveMedal(SONG.song, storyDifficulty);
				#end
			}

			PlayState.trueEctospasm = false;

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
				Unlocks.finishedSong(formattedSong);

				if(sakuUnlocked) {
					Unlocks.unlock(Unlocks.UnlockType.SONG, "Fuzzy Feeling");
				}
			}

			if ((freeplayDialogueSongs.contains(genericSong) || freeplayDialogueSongs.contains(formattedSong)) || isStoryMode)
			{
				var doof:DialogueBox = new DialogueBox(formattedSong, dialogueBf, storyDifficulty, dialogueGf, true);
				if (doof.noDialogue)
					nextSong();
				else
				{
					dialogueBox = doof;
					doof.cameras = [camOther];
					doof.finishThing = nextSong;
					doof.nextDialogueThing = startNextDialogue;
					doof.skipDialogueThing = skipDialogue;

					startDialogueSimple(doof);
				}
			}
			else
				nextSong();
		}
	}

	function nextSong() {
		transitioning = true;

		if (isStoryMode)
		{
			campaignScore += songScore;
			campaignMisses += songMisses;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				if (MainMenuState.songName.startsWith('Intro')) MainMenuState.songName = MainMenuState.songName.replace('Intro', 'Menu');

				if ((FlxG.sound.music != null || FlxG.sound.music.playing) && !curStage.startsWith('minus') )
				{
					FlxG.sound.music.stop();
					FlxG.sound.music.persist = true;
					FlxG.sound.playMusic(Paths.music(MainMenuState.songName));
				}

				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}

				if (formattedSong == "overtime") {
					openSubState(new MinusEndingState());
				}
				else {
					MusicBeatState.nextGhostAllowed = true;
					MusicBeatState.songLoadingScreen = "loading";
					MusicBeatState.switchState(new StoryMenuState());
				}

				if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
					//StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

					if(!Unlocks.isModeUnlocked("randomized")) {
						Unlocks.unlock(MODE, "randomized");
					}

					if(!Unlocks.isModeUnlocked("insta-death")) {
						Unlocks.unlock(MODE, "insta-death");
					}

					if (SONG.validScore)
					{
						var weekName:String = weekScoreName;
						if(weekName == "") {
							weekName = WeekData.getWeekFileName();
						}
						Highscore.saveWeekScore(weekName, campaignScore, storyDifficulty);

						Unlocks.finishedStoryWeek(weekName);
					}

					//FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
					//FlxG.save.flush();

					Unlocks.saveUnlocks();
				}
				changedDifficulty = false;
			}
			else
			{
				firstTry = true;

				if (formattedSong == 'preseason')
				{
					persistentUpdate = false;
					persistentDraw = false;
					paused = true;
					vocals.stop();

					for (tween in modchartTweens) {
						tween.active = true;
					}
					for (timer in modchartTimers) {
						timer.active = true;
					}

					GameOverSubstate.loopSoundName = "minus/Preaseason_Ambience";
					GameOverSubstate.endSoundName = "minus/gameOverEndVanilla";
					GameOverSubstate.characterName = "bf-minus-death";

					prepareForTransition();
					openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y, true));
					FlxTween.tween(FlxG.camera, {zoom: 0.8}, 1.25, {startDelay: 0.5, ease: FlxEase.elasticOut});

					// Fix camera positions for the next song
					camFollow.x -= 250;
					camFollow.y -= 300;
					return;
				}

				FlxTween.tween(camHUD, {alpha: 0}, 1, {
					onComplete: function(flx:FlxTween)
					{
						if(formattedSong == 'satisfracture') {
							MusicBeatState.songLoadingScreen = "story/wrath";
						}
						prepareForTransition();
						cancelMusicFadeTween();

						LoadingState.loadAndSwitchState(new PlayState());
					}
				});
			}
		}
		else
		{
			/*if (formattedSong == 'icebreaker')
			{
				FlxTween.tween(camHUD, {alpha: 0}, 0.6, {
					onComplete: function(flx:FlxTween)
					{
						var angry = new FlxSprite(Paths.image("iceolation/angryending"));
						angry.screenCenter();
						angry.cameras = [camOther];
						angry.alpha = 0.00001;
						add(angry);
						FlxTween.tween(angry, {alpha: 1}, 0.4, {
							onComplete: function(flx:FlxTween)
							{
								var happy = new FlxSprite(Paths.image("iceolation/happyending"));
								happy.screenCenter();
								happy.cameras = [camOther];
								happy.alpha = 0.00001;
								add(happy);
								FlxTween.tween(happy, {alpha: 1}, 3, {
									startDelay: 1,
									onComplete: function(flx:FlxTween)
									{
										var black = new FlxSpriteExtra();
										black.makeSolid(1280*3, 720*3, 0xFF000000);
										black.screenCenter();
										black.cameras = [camOther];
										black.alpha = 0.00001;
										add(black);

										FlxTween.tween(black, {alpha: 1}, 0.6, {
											startDelay: 1,
											onComplete: function(flx:FlxTween)
											{
												trace('WENT BACK TO FREEPLAY??');
												cancelMusicFadeTween();
												if(FlxTransitionableState.skipNextTransIn) {
													CustomFadeTransition.nextCamera = null;
												}
												MusicBeatState.switchState(new FreeplayState());
												if (MainMenuState.songName.startsWith('Intro')) MainMenuState.songName = MainMenuState.songName.replace('Intro', 'Menu');
												FlxG.sound.music.persist = true;
												FlxG.sound.playMusic(Paths.music(MainMenuState.songName));
												changedDifficulty = false;
											}
										});
									}
								});
							}
						});
					}
				});
				persistentUpdate = false;
				persistentDraw = false;
				paused = true;
				vocals.stop();

				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}

				return;
			}*/

			trace('WENT BACK TO FREEPLAY??');
			cancelMusicFadeTween();
			if(FlxTransitionableState.skipNextTransIn) {
				CustomFadeTransition.nextCamera = null;
			}
			MusicBeatState.switchState(new FreeplayState());
			if (MainMenuState.songName.startsWith('Intro')) MainMenuState.songName = MainMenuState.songName.replace('Intro', 'Menu');
			FlxG.sound.music.persist = true;
			FlxG.sound.playMusic(Paths.music(MainMenuState.songName));
			changedDifficulty = false;
		}
	}

	private function prepareForTransition()
	{
		var difficulty:String = Difficulty.getDifficultyFilePath();

		trace('LOADING NEXT SONG');
		trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

		//var poop:String = Highscore.formatSong(storyPlaylist[0].toLowerCase().replace(' ','-'), storyDifficulty);

		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		prevCamFollow = camFollow;
		prevCamFollowPos = camFollowPos;

		PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
		//PlayState.SONG2 = Song.loadFromJson(poop + '-2', PlayState.storyPlaylist[0]);
		FlxG.sound.music.stop();
		//vocals.volume = 0;
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		if(notes != null) {
			while(notes.length > 0) {
				var daNote:Note = notes.members[0];
				destroyNote(daNote);
			}
		}
		//unspawnNotes = FlxDestroyUtil.destroyArray(unspawnNotes);
		unspawnNotes = [];
		eventNotes = [];
	}

	function destroyNote(note:Note) {
		//note.active = false;
		//note.visible = false;

		note.kill();
		notes.remove(note, true);
		//notesToDestroy.push(note);
	}

	function destroyNoteUnspawn(note:Note) {
		note.kill();
		unspawnNotes.remove(note);
		//notesToDestroy.push(note);
	}

	inline function destroySprite(sprite:FlxBasic) {
		sprite.active = false;
		remove(sprite, true);
		sprite.destroy();
	}

	inline function fastDestroySprite(sprite:FlxBasic) {
		sprite.active = false;
		remove(sprite, true);
		spritesToDestroy.push(sprite);
	}

	private function cachePopUpScore()
	{
		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';
		if (isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		Paths.image(pixelShitPart1 + "sick" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "good" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "bad" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "shit" + pixelShitPart2);

		for (i in 0...10) {
			Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2);
		}
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = true;
	public var showRating:Bool = true;

	private function popUpScore(note:Note):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);

		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(noteDiff);

		switch (daRating)
		{
			case 'shit':
				totalNotesHit += 0;
				note.ratingMod = 0;
				score = 50;
				if(kadeHealthSystem) {
					health -= 0.15 * healthGain;
				}
				if(!note.ratingDisabled) shits++;
			case 'bad':
				totalNotesHit += 0.5;
				note.ratingMod = 0.5;
				score = 100;
				if(kadeHealthSystem) {
					health -= 0.08 * healthGain;
				}
				if(!note.ratingDisabled) bads++;
			case 'good':
				totalNotesHit += 0.75;
				note.ratingMod = 0.75;
				score = 200;
				if(kadeHealthSystem) {
					health += 0.04 * healthGain;
				}
				if(!note.ratingDisabled) goods++;
			case 'sick':
				totalNotesHit += 1;
				note.ratingMod = 1;
				if(kadeHealthSystem) {
					health += 0.08 * healthGain;
				}
				if(!note.ratingDisabled) sicks++;
		}
		note.rating = daRating;

		if(!note.noteSplashDisabled && daRating == 'sick')
		{
			spawnNoteSplashOnNote(note);
		}

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating();
			}

			if(ClientPrefs.scoreZoom)
			{
				if(scoreTxtTween != null) {
					scoreTxtTween.cancel();
					scoreTxtTween.destroy();
				}
				scoreTxt.scale.set(1.075, 1.075);
				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween) {
						scoreTxtTween = null;
					}
				});
			}
		}

		if(ClientPrefs.hideHud || !(showCombo || showRating)) return;

		var coolTextX = FlxG.width * 0.35;

		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';

		if (isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		if(showRating) {
			var rating:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
			//rating.cameras = [camHUD];
			rating.screenCenter(Y);
			rating.x = coolTextX - 40;
			rating.y -= 60;
			rating.x += ClientPrefs.comboOffset[0];
			rating.y -= ClientPrefs.comboOffset[1];
			rating.acceleration.y = 550;
			rating.velocity.y -= FlxG.random.int(140, 175);
			rating.velocity.x -= FlxG.random.int(0, 10);
			rating.visible = (!ClientPrefs.hideHud && showRating);

			comboLayer.add(rating);

			if (!PlayState.isPixelStage)
			{
				rating.setGraphicSize(Std.int(rating.width * 0.7));
				rating.antialiasing = ClientPrefs.globalAntialiasing;
			}
			else
			{
				rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			}

			rating.updateHitbox();

			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					comboLayer.remove(rating, true);
					spritesToDestroy.push(rating);
				},
				startDelay: Conductor.crochet * 0.001
			});
		}

		if(!showCombo) return;

		var seperatedScore:Array<String> = (combo + "").split('');

		var xoff = seperatedScore.length - 3;

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2));
			//numScore.cameras = [camHUD];
			numScore.screenCenter(Y);
			numScore.x = coolTextX + (43 * (daLoop - xoff)) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = (!ClientPrefs.hideHud && showCombo);

			comboLayer.add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					comboLayer.remove(numScore, true);
					spritesToDestroy.push(numScore);
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		if(cpuControlled || paused)
			return;
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				if(FlxG.sound.music != null && FlxG.sound.music.playing) Conductor.songPosition = FlxG.sound.music.time;

				if(kadeInputSystem) {
					var dataNotes:Array<Note> = [];
					notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress && !strumsBlocked[daNote.noteData] && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
						{
							if(daNote.noteData == key)
							{
								dataNotes.push(daNote);
							}
						}
					});

					if (dataNotes.length != 0)
					{
						dataNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						var coolNote:Note = dataNotes[0];

						//for (i in dataNotes)
						//	if (!i.isSustainNote)
						//	{
						//		coolNote = i;
						//		break;
						//	}

						if (coolNote == null) // Note is null, which means it's probably a sustain note. Update will handle this (HOPEFULLY???)
						{
							Conductor.songPosition = lastTime;
							return;
						}

						if (dataNotes.length > 1) // stacked notes or really close ones
						{
							for (i in 0...dataNotes.length)
							{
								if (i == 0) // skip the first note
									continue;

								var note = dataNotes[i];

								if (!note.isSustainNote && (note.strumTime - coolNote.strumTime) < 2)
								{
									// just fuckin remove it since it's a stacked note and shouldn't be there
									destroyNote(note);
								}
							}
						}

						goodNoteHit(coolNote);
					}
					else if (!ClientPrefs.ghostTapping && !startingSong)
					{
						noteMissPress(key);
						callOnLuas('noteMissPress', [key]);
					}
				} else {
					var canMiss:Bool = !ClientPrefs.ghostTapping;

					// heavily based on my own code LOL if it aint broke dont fix it
					var pressNotes:Array<Note> = [];
					//var notesDatas:Array<Int> = [];
					var notesStopped:Bool = false;

					var sortedNotesList:Array<Note> = [];
					notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress && !strumsBlocked[daNote.noteData] && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
						{
							if(daNote.noteData == key)
							{
								sortedNotesList.push(daNote);
								//notesDatas.push(daNote.noteData);
							}
							canMiss = true;
						}
					});

					if (sortedNotesList.length > 0) {
						sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						for (epicNote in sortedNotesList)
						{
							for (doubleNote in pressNotes) {
								if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
									destroyNote(doubleNote);
								} else
									notesStopped = true;
							}

							// eee jack detection before was not super good
							if (!notesStopped) {
								goodNoteHit(epicNote);
								pressNotes.push(epicNote);
							}

						}
					}
					else if (canMiss) {
						noteMissPress(key);
						callOnLuas('noteMissPress', [key]);
					}
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(!strumsBlocked[key] && spr != null && !spr.isConfirm)
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				if(!spr.frozen) {
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			}
			callOnLuas('onKeyRelease', [key]);
		}
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i] && !strumsBlocked[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		if (!boyfriend.stunned && generatedMusic)
		{
			// HOLDING
			var up = controls.NOTE_UP;
			var right = controls.NOTE_RIGHT;
			var down = controls.NOTE_DOWN;
			var left = controls.NOTE_LEFT;
			var controlHoldArray:Array<Bool> = [left, down, up, right];

			var isHolding = controlHoldArray.contains(true);
			// rewritten inputs???
			if(isHolding) {
				notes.forEachAlive(function(daNote:Note)
				{
					// hold note functions
					if (daNote.isSustainNote && !strumsBlocked[daNote.noteData] && controlHoldArray[daNote.noteData] && daNote.canBeHit
					&& daNote.mustPress && !daNote.tooLate && daNote.sustainActive && !daNote.wasGoodHit) {
						goodNoteHit(daNote);
					}
				});
			}

			if (isHolding && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				//boyfriend.animation.curAnim.finish();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode || strumsBlocked.contains(true))
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i] || strumsBlocked[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				destroyNote(note);
			}
		});

		if(daNote.doesNothingIfMissed) return;

		combo = 0;

		var shouldChangeAlt = !daNote.didMakuMiss && boyfriend.curCharacter.startsWith('sakuroma-minus');
		var altValue = shouldChangeAlt && FlxG.random.bool(50);

		if(kadeHealthSystem) {
			if(daNote.sustainLength > 0) {
				health -= 0.15 * healthLoss;
				for (i in daNote.children)
				{
					i.alpha = 0.3;
					i.multAlpha = 0.3;
					i.sustainActive = false;
					if(shouldChangeAlt) {
						i.altAnimation = altValue;
						i.didMakuMiss = true;
					}
				}
			} else {
				if(daNote.isSustainNote) {
					if(!daNote.isHoldEnd) {
						health -= 0.20 * healthLoss;
						for (i in daNote.parent.children)
						{
							i.alpha = 0.3;
							i.multAlpha = 0.3;
							i.sustainActive = false;
							if(shouldChangeAlt) {
								i.altAnimation = altValue;
								i.didMakuMiss = true;
							}
						}
					}
				} else {
					health -= 0.10 * healthLoss;
				}
			}
		} else {
			health -= daNote.missHealth * healthLoss;
			if(shouldChangeAlt) {
				if(daNote.sustainLength > 0) {
					for (i in daNote.children)
					{
						i.altAnimation = altValue;
						i.didMakuMiss = true;
					}
				} else if(daNote.isSustainNote && !daNote.isHoldEnd) {
					for (i in daNote.parent.children)
					{
						i.altAnimation = altValue;
						i.didMakuMiss = true;
					}
				}
			}
		}
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		songMisses++;
		if (daNote.noteType == '')
			vocals.volume = 0;
		if(!practiceMode) songScore -= 10;

		totalPlayed++;
		RecalculateRating();

		missAnimation(daNote);

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function missAnimation(daNote:Note):Void {
		if(daNote.noAnimation) return;

		var char:Character = boyfriend;
		if(daNote.gfNote) {
			char = gf;
		}

		if(char != null && char.hasMissAnimations)
		{
			var daAlt = '';
			if(daNote.altAnimation) daAlt = '-alt';
			else if(daNote.didMakuMiss) {}
			//else if(daNote.noteType == 'Alt Animation') daAlt = '-alt';
			else if(FlxG.random.bool(50) && boyfriend.curCharacter.startsWith('sakuroma-minus')) daAlt = '-alt';

			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
			//char.playAnim(animToPlay, true);
			//char.playAnim(animToPlay, !daNote.isSustainNote);
			char.playAnim(animToPlay, true, false, daNote.isSustainNote ? 1 : 0);
		}
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			if(kadeHealthSystem) {
				health -= 0.15 * healthLoss;
			} else {
				health -= 0.05 * healthLoss;
			}
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if(ClientPrefs.ghostTapping) return;

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations) {
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
	}

	@:keep public var hasGhostSprite:Bool = false;
	@:keep public var shouldShake:Bool = false;
	@:keep public var windowShakeAmount:Int = 3;

	function opponentNoteHit(note:Note):Void
	{
		//if (enableCamZooming)
		//	camZooming = true;

		if (shouldShake)
		{
			// (Arcy) Shake the screen and window whenever Retro sings
			if (ClientPrefs.screenShake)
			{
				camera.shake(0.015, 0.05);
			}
			if (ClientPrefs.windowShake)
			{
				Application.current.window.x += (FlxG.random.int(0, 1) == 0 ? -1 : 1) * windowShakeAmount;
				Application.current.window.y += (FlxG.random.int(0, 1) == 0 ? -1 : 1) * windowShakeAmount;
			}
		}

		if (hasGhostSprite && ClientPrefs.ghostTrails)
		{
			if (!note.isSustainNote)
			{
				var trail:GhostSprite = GhostSprite.createGhostSprite(dad, 0.25, 0.33);
				spriteTrail.add(trail);
			}
		}

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = "";
			//var altAnim2:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (note.altAnimation || SONG.notes[curSection].altAnim) {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			//var char2:Character = dad2;
			if(note.secondDad) {
				char = dad2;
			}
			if(note.gfNote) {
				char = gf;
			}

			//if (dad2 != null && FlxG.random.bool(50) && dad2.curCharacter.startsWith('sakuroma-minus')) altAnim2 = '-alt';
			//var animToPlay2:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim2;

			if(char != null)
			{
				if (FlxG.random.bool(50) && char.curCharacter.startsWith('sakuroma-minus')) altAnim = '-alt';

				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;

				if(note.isSustainNote) {
					if(char.animation.name == 'idle' || char.animation.name.startsWith('dance')) {
						char.playAnim(animToPlay);
					}
				} else {
					char.playAnim(animToPlay, true);
				}
				char.holdTimer = 0;
			}
			//if(note.secondDad && char2 != null)
			//{
			//	if(note.isSustainNote) {
			//		if(char2.animation.name == 'idle' || char2.animation.name.startsWith('dance')) {
			//			char2.playAnim(animToPlay2);
			//		}
			//	} else {
			//		char2.playAnim(animToPlay2, true);
			//	}
			//	char2.holdTimer = 0;
			//}
		}

		if (note.isSustainNote && note.noteData == 3 && dad.curCharacter == "retro2-wrath" && gf != null && (gf.curCharacter == 'gf-wrath' || gf.curCharacter == 'gf-ace') && gf.animation.name.startsWith('dance'))
		{
			gf.playAnim('hair' + gf.animation.name.substr(5), true, false, gf.animation.frameIndex);
		}

		if (genericSong == 'ectospasm' && note.isSpectreNote)
		{
			enemySpectreHit = true;
			spectreSound.play(true);
			specialNoteHit(note);
		}

		if(!ClientPrefs.optimizedNotes && !note.isSustainNote && PlayState.arrowSkindad == "NOTE_assets_corruptro" && formattedSong == 'corruptro' && note.noteType == "poison") {
			note.colorSwap.hue = 0;
			note.colorSwap.saturation = 0;
			note.colorSwap.brightness = 0;
		}

		vocals.volume = SONG.vocalVol;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.isHoldEnd) {
			time += 0.15;
		}
		StrumPlayAnim(true, note, time);
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			destroyNote(note);
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
					case 'poison':
						poisonStacks++;
						poisonTxt.text = Std.string(poisonStacks);
						specialNoteHit(note);
						poisonSound.play(true);
					case 'iceNote':
						iceNoteHit(note);
						for (i in 0...4)
						{
							frozen[i] = true;
							strumsBlocked[i] = true;
							playerStrums.members[i].frozen = true;
							playerStrums.members[i].playAnim('frozen');
						}
						FlxG.sound.play(Paths.sound('icey'));

					case 'sakuNote':
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					destroyNote(note);
				}
				return;
			}
			else
			switch(note.noteType) {
				case 'spectre':
					spectreHit = true;
					if(spectreSound != null)
						spectreSound.play(true);
					specialNoteHit(note);
				case 'sakuNote':
					if(sakuLaugh != null) sakuLaugh.play(true);
					if(sakuNote != null) sakuNote.play(true);
					unlocksakuorsmth();//to do: add the clientdata n stuff to the func
					if (ClientPrefs.particles && !ClientPrefs.optimize)
					{
						for (i in 0...particles.length)
						{
							particles.members[i].emitting = false;

							var emitter:FlxEmitter = new FlxEmitter(-1000, 1500);
							emitter.launchMode = FlxEmitterMode.SQUARE;
							emitter.velocity.set(-50, -250, 50, -850, -100, 0, 100, -150);
							emitter.scale.set(2, 2, 5, 5, 0.75, 0.75, 1.5, 1.5);
							emitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
							emitter.width = 3500;
							emitter.alpha.set(1, 1, 0, 0);
							emitter.lifespan.set(3, 5);
							emitter.loadParticles(Paths.image('Particles/Heart' + i, 'shared'), 500, 16, true);

							emitter.start(false, FlxG.random.float(0.1, 0.2), 100000);
							particles.add(emitter);
						}
					}
			}

			if (!note.isSustainNote && note.countsForCombo)
			{
				combo += 1;
				popUpScore(note);
			}
			if(!kadeHealthSystem) {
				health += note.hitHealth * healthGain;
			}

			if(!note.noAnimation) {
				var daAlt = '';
				if(note.altAnimation) daAlt = '-alt';
				else if(FlxG.random.bool(50) && boyfriend.curCharacter.startsWith('sakuroma-minus')) daAlt = '-alt';

				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + daAlt;

				var char:Character = boyfriend;
				if(note.gfNote) {
					char = gf;
				}

				if(char != null) {
					if(note.isSustainNote) {
						if(char.animation.name == 'idle' || char.animation.name.startsWith('dance')) {
							char.playAnim(animToPlay);
						}
					} else {
						char.playAnim(animToPlay, true);
					}
					char.holdTimer = 0;
				}

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.isHoldEnd) {
					time += 0.15;
				}
				StrumPlayAnim(false, note, time);
			} else {
				playerStrums.members[Std.int(Math.abs(note.noteData))].playAnim('confirm', true, note);
			}
			note.wasGoodHit = true;
			vocals.volume = SONG.vocalVol;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				destroyNote(note);
			}
		}
	}

	function specialNoteHit(note:Note) {
		var notepop:FlxSprite = new FlxSprite();
		notepop.cameras = [camHUD];
		var isPoison = note.noteType == 'poison';
		notepop.frames = Paths.getSparrowAtlas((isPoison ? 'PoisonArrowHit' : 'SpectreHit'));
		var anims:Array<String> = ['Left', 'Down', 'Up', 'Right'];
		if(ClientPrefs.downScroll && note.isSpectreNote)
		{
			anims[1] = 'Up';
			anims[2] = 'Down';
			notepop.flipY = true;
			notepop.offset.y -= 70;
		}
		if(isPoison && formattedSong == "corruptro") {
			var colorSwap = new ColorSwap();
			colorSwap.hue = 180 / 360;
			notepop.shader = colorSwap.shader;
		}
		notepop.animation.addByPrefix('break', (isPoison ? 'Poison Arrow Hit ' : 'SpectreHit ')
		 + (isPoison ? anims[note.noteData] : anims[note.noteData].toLowerCase()), 24, false);
		notepop.animation.play('break');
		notepop.antialiasing = ClientPrefs.globalAntialiasing;
		notepop.setGraphicSize(Std.int(notepop.width * 0.7));
		add(notepop);

		notepop.x = note.x - note.width - (isPoison ? 12 : 9);
		notepop.y = note.y - (note.height / 2) - 20;
		notepop.angle = note.angle;

		notepop.animation.finishCallback = function(str:String)
		{
			fastDestroySprite(notepop);
		};
	}

	function iceNoteHit(note:Note) {
		var breakAnim:FlxSprite = new FlxSprite();
		breakAnim.cameras = [camHUD];
		breakAnim.frames = Paths.getSparrowAtlas("iceolation/IceBreakAnim", 'shared');
		var anims:Array<String> = ['left', 'down', 'up', 'right'];
		breakAnim.animation.addByPrefix('break', anims[note.noteData], 24, false);
		breakAnim.animation.play('break');
		breakAnim.antialiasing = ClientPrefs.globalAntialiasing;

		var strum:StrumNote = playerStrums.members[note.noteData];
		if(strum != null) {
			breakAnim.setGraphicSize(Std.int(strum.frameWidth * 1.15), Std.int(strum.frameHeight * 1.15));
		} else {
			breakAnim.setGraphicSize(Std.int(breakAnim.width * 0.7));
		}
		breakAnim.updateHitbox();

		add(breakAnim);

		breakAnim.x = note.x;// - 35;
		breakAnim.y = note.y;// - 35; //- (note.height / 2) - 20;
		breakAnim.angle = 0;

		breakAnim.animation.finishCallback = function(str:String)
		{
			fastDestroySprite(breakAnim);
		};
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.originColor, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(splashSkin != null && splashSkin.length > 0) skin = splashSkin;

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);

		if(note != null && note.isUsingColorChange) {
			splash.setupNoteSplashRGB(x, y, data, skin, note.colorSwap.red);
		} else {
			var hue:Float = 0;
			var sat:Float = 0;
			var brt:Float = 0;
			if(note != null) {
				skin = note.noteSplashTexture;
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			} else {
				var hsv = ClientPrefs.arrowHSV[data];
				hue = hsv[0] / 360;
				sat = hsv[1] / 100;
				brt = hsv[2] / 100;
			}

			splash.setupNoteSplashHSV(x, y, data, skin, hue, sat, brt);
		}

		grpNoteSplashes.add(splash);
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		if(ClientPrefs.windowShake) {
			Application.current.window.onMove.remove(onWindowMove);
		}
		allNotes = FlxDestroyUtil.destroyArray(allNotes);
		unspawnNotes = FlxDestroyUtil.destroyArray(unspawnNotes);
		if(modchartSprites != null) for(val in modchartSprites) val.destroy();
		if(modchartTweens != null) for(val in modchartTweens) val.destroy();
		if(boyfriendMap != null) for(val in boyfriendMap) val.destroy();
		if(dadMap != null) for(val in dadMap) val.destroy();
		if(gfMap != null) for(val in gfMap) val.destroy();

		//FlxG.sound.destroy(true);
		//FlxG.sound.list.clear();
		TitleState.introMusic = null;

		modchartSprites = null;
		modchartTweens = null;
		boyfriendMap = null;
		dadMap = null;
		gfMap = null;
		super.destroy();

		//notesToDestroy = FlxDestroyUtil.destroyArray(notesToDestroy);
		spritesToDestroy = FlxDestroyUtil.destroyArray(spritesToDestroy);

		MemoryUtils.clearMajor();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music == null) return;
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var startedHeartParticles:Bool = false;
	var startedCorruptParticles:Bool = false;

	var lastStepHit:Int = -1;
	@:keep var canResync:Bool = true;
	override function stepHit()
	{
		super.stepHit();
		if (canResync && (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (!vocalsFinished && SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20)))
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		if (!ClientPrefs.optimize && (formattedSong == 'satisfracture' || formattedSong == 'satisflatter'))
		{
			if (curStep >= 188 && curStep < 192 && enoughTxt == null)
			{
				enoughTxt = new FlxFixedText(0, 475, 0, "ENOUGH!", 100);
				enoughTxt.cameras = [camHUD];
				enoughTxt.screenCenter(X);
				enoughTxtOrigin = enoughTxt.getPosition();
				add(enoughTxt);
			}

			if (curStep >= 192 && enoughTxt != null)
			{
				fastDestroySprite(enoughTxt);
				enoughTxt = null;
			}
		}

		if (!ClientPrefs.optimize && formattedSong == 'overtime')
		{
			if (curStep >= 1790.2 && curStep < 1802 && overtimeTxt == null)
			{
				overtimeTxt = new FlxFixedText(0, 475, 0, "IS THAT ALL YOU GOT?", 70);
				overtimeTxt.cameras = [camHUD];
				overtimeTxt.screenCenter(X);
				overtimeTxtOrigin = overtimeTxt.getPosition();
				overtimeTxt.borderColor = FlxColor.BLACK;
				overtimeTxt.borderSize = 6;
				overtimeTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
				add(overtimeTxt);
			}

			if (curStep >= 1808 && overtimeTxt != null)
			{
				remove(overtimeTxt, true);
				overtimeTxt.destroy();
				overtimeTxt = null;
			}
		}

		if (!ClientPrefs.optimize && formattedSong == 'satisfracture-remix')
		{
			if (curStep >= 249 && curStep < 256 && enoughTxt == null)
			{
				enoughTxt = new FlxFixedText(0, 475, 0, "ENOUGH!", 100);
				enoughTxt.cameras = [camHUD];
				enoughTxt.screenCenter(X);
				enoughTxtOrigin = enoughTxt.getPosition();
				add(enoughTxt);
			}

			if (curStep >= 256 && enoughTxt != null)
			{
				fastDestroySprite(enoughTxt);
				enoughTxt = null;
			}
		}

		if (ClientPrefs.motion && ClientPrefs.particles && !ClientPrefs.optimize && formattedSong == 'spectral' && curStep >= 1536 && !spectralBGEmitter.emitting)
			spectralBGEmitter.start(false, 0.025, 10000);

		if (ClientPrefs.particles && !ClientPrefs.optimize && !startedHeartParticles && ( (formattedSong == 'heartmelter' && curStep >= 896) ||
			((genericSong == 'fuzzy-feeling') && curStep >= 768) )
			 && particles != null)
			{
				particles.forEach(function(emitter:FlxEmitter) {
					if (!emitter.emitting)
						emitter.start(false, FlxG.random.float(0.1, 0.2), 100000);
				});
				startedHeartParticles = true;
			}

		if (!ClientPrefs.optimize && ClientPrefs.particles && !startedCorruptParticles && (curStep >= 1824 && formattedSong == 'corruptro') && particles != null) {
			particles.forEach(function(emitter:FlxEmitter) {
				if (!emitter.emitting)
					emitter.start(false, FlxG.random.float(0.1, 0.2), 100000);
				//trace('now it emits lol');
			});
			startedCorruptParticles = true;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lastBeatHit:Int = -1;

	public var canCameraBop:Bool = true;

	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (ClientPrefs.shaders && ClientPrefs.chromatic && chrom != null && health <= 0.01)
		{
			chrom.rOffset.value = [0, -0.005];
			chrom.gOffset.value = [-0.005, -0.005];
			chrom.bOffset.value = [0.005, -0.005];
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		var section = SONG.notes[Math.floor(curStep / 16)];
		if (section != null)
		{
			if (section.changeBPM)
			{
				Conductor.changeBPM(section.bpm);
				//FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', section.mustHitSection);
			setOnLuas('altAnim', section.altAnim);
			setOnLuas('gfSection', section.gfSection);

			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection(Std.int(curStep / 16));
			}
		}

		if (camZooming && canCameraBop && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (curBeat % 2 == 0)
		{
			iconP1.scale.set(1.2, 1.2);
			iconP2.scale.set(1.2, 1.2);

			iconP1.updateHitbox();
			iconP2.updateHitbox();

			if (poisonIcon != null)
			{
				poisonIcon.setGraphicSize(130);
				poisonTxt.setGraphicSize(30);
				poisonIcon.updateHitbox();
				poisonTxt.updateHitbox();
			}
		}

		if (gf != null && !gf.stunned && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing"))
		{
			gf.dance();
		}
		if (!boyfriend.stunned && curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing'))
		{
			boyfriend.dance();
		}
		if (!dad.stunned && curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing'))
		{
			dad.dance();
			//if (FlxG.save.data.ghostTrails && (curSong.toLowerCase() == 'spectral' || curSong.toLowerCase() == 'ectospasm'))
			if (hasGhostSprite && ClientPrefs.ghostTrails)
			{
				var trail:GhostSprite = GhostSprite.createGhostSprite(dad, 0.25, 0.33);
				spriteTrail.add(trail);
			}
		}
		if (dad2 != null && !dad2.stunned && curBeat % dad2.danceEveryNumBeats == 0 && dad2.animation.curAnim != null && !dad2.animation.curAnim.name.startsWith('sing'))
		{
			dad2.dance();
		}

		switch (curStage)
		{

		}

		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	function introCutscene()
	{
		camFollow.set(800, 400);
		bfBeepWake = new FlxSound().loadEmbedded(Paths.sound("beep"));
		wrathIntroSnap = new FlxSound().loadEmbedded(Paths.sound("phase1intro"));
		inCutscene = true;

		new FlxTimer().start(1.6, function(tmr:FlxTimer)
		{
			bfBeepWake.play(true);
			wrathIntroSnap.play(true);
			boyfriend.playAnim("singUP");
			boyfriend.animation.finishCallback = function(str:String)
			{
				boyfriend.animation.finishCallback = null;
				boyfriend.playAnim("idle", true);
				boyfriend.animation.stop();
			};
		});

		//wrathIntroSnap.play(true);

		new FlxTimer().start(2.7, function(tmr:FlxTimer)
		{
			cutsceneSprite.animation.paused = false;
			cutsceneSprite.playAnim('IntroCutscene', true);
		});
		new FlxTimer().start(6.5, function(tmr:FlxTimer) // temporary workaround for now!!
		{
			cutsceneSprite.visible = false;
			remove(cutsceneSprite);
			Paths.localTrackedAssets.remove(cutsceneSprite.graphic.assetsKey);
			cutsceneSprite.destroy();
			Paths.clearUnusedMemory();
			dad.visible = true;

			var dialogBf = bfVersion == 'bf-wrath' ? 'bf' : bfVersion;
			//var doof:DialogueBox = new DialogueBox(SONG.song.toLowerCase(), bfCharacter, storyDifficulty, gf.curCharacter);
			var doof:DialogueBox = new DialogueBox(formattedSong, dialogBf, storyDifficulty, gfVersion);
			if(!doof.noDialogue) {
				dialogueBox = doof;
				doof.cameras = [camOther];
				doof.nextDialogueThing = startNextDialogue;
				doof.skipDialogueThing = skipDialogue;
				doof.finishThing = function()
				{
					showHUD();
					startCountdown();
				};

				startDialogueSimple(doof);
			} else {
				showHUD();
				startCountdown();
			}
		});
	}

	public var closeLuas:Array<FunkinLua> = [];
	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var ret:Dynamic = luaArray[i].call(event, args);
			if(ret != FunkinLua.Function_Continue) {
				returnVal = ret;
			}
		}

		for (i in 0...closeLuas.length) {
			luaArray.remove(closeLuas[i]);
			closeLuas[i].stop();
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, note:Note, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[note.noteData % 4];
		} else {
			spr = playerStrums.members[note.noteData % 4];
		}

		if(spr != null) {
			spr.playAnim('confirm', true, note);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
						if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
								case 'week7':
									if(achievementName == 'week7_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing) {
							unlock = true;
						}
					case 'debugger':
						if(formattedSong == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var isWrathBar = false;

	public static var customWrathBars = [
		'corruptro' => 'HealthBar_Placeholder_Corrupt',
		'bf-corrupt' => 'HealthBar_Placeholder_Red',
	];

	public var customBfWrath = "";
	public var customDadWrath = "";

	public function setWrathBar() {
		isWrathBar = true;
		healthBar.kill();
		remove(healthBar);
		healthBar.destroy();

		var dadImage = Paths.image(
			customDadWrath == "" ? 
				(customWrathBars.exists(dad.curCharacter) ? customWrathBars.get(dad.curCharacter) : 'HealthBar_Placeholder_Red') :
				customDadWrath 
		);
		var bfImage = Paths.image(
			customBfWrath == "" ?
				(customWrathBars.exists(boyfriend.curCharacter) ? customWrathBars.get(boyfriend.curCharacter) : 'HealthBar_Placeholder_Green') :
				customBfWrath
		);

		remove(healthBarBG);
		healthBarBG.loadGraphic(dadImage);

		healthBar = new FlxBar(healthBarBG.x, healthBarBG.y, RIGHT_TO_LEFT, Std.int(healthBarBG.width), Std.int(healthBarBG.height), this, 'health', 0, 2);
		healthBar.y -= 15;
		iconP1.y -= 15;
		iconP2.y -= 15;
		healthBar.scrollFactor.set();
		//healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		healthBar.createImageEmptyBar(dadImage, FlxColor.WHITE);
		healthBar.createImageFilledBar(bfImage, FlxColor.WHITE);
		healthBarOrigin = healthBar.getPosition();
		healthBar.numDivisions = 10000;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBar.cameras = [camHUD];

		/*
		if (PlayState.isStoryMode)
		{
			switch (StringTools.replace(PlayState.curSong, " ", "-").toLowerCase())
			{
				case 'spectral':
					if (PlayState.firstTry)
						healthBar.alpha = 0;
			}
		}*/

		var healthSplat = boyfriend.curCharacter == 'bf-corrupt' ? 'Health_Splat_Corrupt' : 'Health_Splat';

		var kamOffset = boyfriend.curCharacter == 'bf-ace' && !ClientPrefs.downScroll ? -10 : 0;

		poisonIcon = new FlxSprite(iconP1.x + 75,
			healthBar.y + (ClientPrefs.downScroll ? 0 : -90) + kamOffset).loadGraphic(Paths.image(healthSplat));
		poisonIcon.scale.set(0.2, 0.2);
		poisonIcon.alpha = ClientPrefs.healthBarAlpha;
		poisonIcon.cameras = iconP1.cameras;

		poisonTxt = new FlxFixedText(iconP1.x + 115, poisonIcon.y + 20, '0', 20);
		poisonTxt.color = FlxColor.BLACK;
		poisonTxt.alpha = ClientPrefs.healthBarAlpha;
		poisonTxt.cameras = iconP1.cameras;

		// Chromatic Aberration effect
		if (ClientPrefs.shaders && ClientPrefs.chromatic)
		{
			chrom = new ChromaticAberrationShader();
			iconP1.shader = chrom;
			iconP2.shader = chrom;
			healthBar.shader = chrom;
			poisonIcon.shader = chrom;

			chrom.rOffset.value = [0, 0];
			chrom.gOffset.value = [0, 0];
			chrom.bOffset.value = [0, 0];
		}
		if (ClientPrefs.optimize && isStoryMode && formattedSong == "spectral")
		{
			healthBar.alpha = 0.00001;
			poisonIcon.alpha = 0.00001;
			poisonTxt.alpha = 0.00001;
		}
		add(poisonIcon);
		add(poisonTxt);
	}

	public function updateWrathBar(e:Float) {
		if(hasSpecterNoteMechanic) {
			if (!spectreHit)
			{
				if (noteFadeTime * e > noteOpacity)
				{
					noteOpacity = 0;
				}
				else
				{
					noteOpacity -= noteFadeTime * e;
				}
			}
			else
			{
				if (noteOpacity > 1)
				{
					noteOpacity = 1;
					spectreHit = false;
				}
				else
				{
					noteOpacity += e;
				}
			}
		}

		if (poisonIcon != null)
		{
			if (ClientPrefs.mechanics && health > 0.01)
			{
				if (healthDrainPoison * poisonStacks * e > health)
				{
					health = 0.01;
				}
				else
				{
					health -= healthDrainPoison * poisonStacks * e; // Gotta make it fair with different framerates :)
				}
			}

			var lerpVal:Float = Math.max(0, 1 - (e * 9));
			poisonIcon.setGraphicSize(Std.int(FlxMath.lerp(100, poisonIcon.width, lerpVal)));
			poisonIcon.updateHitbox();
			poisonIcon.centerOrigin();

			poisonTxt.setGraphicSize(Std.int(FlxMath.lerp(20, poisonTxt.width, lerpVal)));
			poisonTxt.updateHitbox();

			poisonIcon.x = iconP1.x + 75;
			poisonTxt.x = iconP1.x + 115;
			poisonTxt.offset.set(0, 0);

			if (health <= 0.01)
			{
				healthBar.setPosition(FlxG.random.float(-5, 5) + healthBarOrigin.x, FlxG.random.float(-5, 5) + healthBarOrigin.y);
				iconP1.setPosition(healthBar.x + (healthBar.width * (1 - (health / 2)) - iconOffset), healthBar.y - 60);
				iconP2.setPosition(healthBar.x + (healthBar.width * (1 - (health / 2)) - (150 - iconOffset)), healthBar.y - 60);
				poisonIcon.setPosition(iconP1.x + 75, healthBar.y + (ClientPrefs.downScroll ? 25 : -75) + (boyfriend.curCharacter == 'bf-ace' && !ClientPrefs.downScroll ? -10 : 0));
				poisonTxt.setPosition(iconP1.x + 115, poisonIcon.y + 20);
			}
			else if (healthBar.x != healthBarOrigin.x || healthBar.y != healthBarOrigin.y)
			{
				healthBar.setPosition(healthBarOrigin.x, healthBarOrigin.y);
				iconP1.setPosition(healthBar.x + (healthBar.width * (1 - (health / 2)) - iconOffset), healthBar.y - 60);
				iconP2.setPosition(healthBar.x + (healthBar.width * (1 - (health / 2)) - (150 - iconOffset)), healthBar.y - 60);
				poisonIcon.setPosition(iconP1.x + 75, healthBar.y + (ClientPrefs.downScroll ? 25 : -75) + (boyfriend.curCharacter == 'bf-ace' && !ClientPrefs.downScroll ? -10 : 0));
				poisonTxt.setPosition(iconP1.x + 115, poisonIcon.y + 20);
			}
		}
	}

	var sakuUnlocked:Bool = false;

	public function unlocksakuorsmth() {
		trace('moth mommy unlocked');
		sakuUnlocked = true;
	}
}

class GhostSprite extends FlxSprite
{
	private static var poolSize = 5;
	private static var INVISIBLE_ALPHA = 0.00000000001;

	private static var instanceReserve:FlxTypedGroup<GhostSprite>;
	private static var usedInstances:FlxTypedGroup<GhostSprite>;

	private var time:Float;
	private var curTime:Float;
	private var aVal:Float;

	public static function initialize() {
		if(instanceReserve != null && usedInstances != null) {
			GhostSprite.cleanPools();
		}

		instanceReserve = new FlxTypedGroup();
		usedInstances = new FlxTypedGroup();

		for(i in 0...poolSize) {
			instanceReserve.add(new GhostSprite());
		}
	}

	/**
	 * Creates a new sprite that copies the sprite and will fade into nothing and die. Forever.
	 *
	 * @param	Sprite			The sprite to make a copy of.
	 * @param	FadeTime		The time it takes for the sprite to fade completely to transparent.
	 * @param	AlphaStart		The starting value of the alpha for the sprite.
	 */
	public static function createGhostSprite(Sprite:FlxSprite, ?FadeTime:Float = 1, ?AlphaStart:Float = 1) {
		var spookyGhost:GhostSprite;

		if (instanceReserve.length != 0) {
			spookyGhost = instanceReserve.members[instanceReserve.length - 1];

			instanceReserve.remove(spookyGhost, true);

			//trace(spookyGhost);
		} else {
			spookyGhost = new GhostSprite();

			poolSize++;
		}

		spookyGhost.frame = Sprite.frame;
		spookyGhost.scale = Sprite.scale;
		spookyGhost.width = Sprite.width;
		spookyGhost.frameWidth = Sprite.frameWidth;
		spookyGhost.height = Sprite.height;
		spookyGhost.frameHeight = Sprite.frameHeight;
		spookyGhost.setPosition(Sprite.getPosition().x, Sprite.getPosition().y);

		spookyGhost.updateHitbox();
		//spookyGhost.offset = Sprite.offset;
		spookyGhost.offset.x = Sprite.offset.x;
		spookyGhost.offset.y = Sprite.offset.y;

		spookyGhost.time = FadeTime;
		spookyGhost.curTime = spookyGhost.time;
		spookyGhost.aVal = AlphaStart;

		usedInstances.add(spookyGhost);

		return spookyGhost;
	}

	public static function destroyGhostSprite(sprite:GhostSprite) {
		sprite.alpha = INVISIBLE_ALPHA;
		sprite.setPosition(0, 0);
		usedInstances.remove(sprite);
		instanceReserve.add(sprite);
	}

	private static function cleanPools() {
		for(i in usedInstances) {
			i.destroy();
		}

		for(i in instanceReserve) {
			i.destroy();
		}
	}

	override function update(elapsed:Float)
	{
		curTime -= elapsed;

		if (curTime <= 0)
		{
			destroyGhostSprite(this);
		}
		else
		{
			alpha = (curTime / time) * aVal;
		}
	}
}
