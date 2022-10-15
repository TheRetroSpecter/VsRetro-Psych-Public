package;

import flixel.FlxCamera;
import flixel.util.FlxSort;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.ColorTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end
import haxe.Json;

using StringTools;

// An enum that keeps track of which menu the current state is in.
enum abstract MenuState(Int)
{
	var Normal = 0;
	var Minus = 1;
	var Corrupt = 2;

	var None = -1;
}

class StoryMenuCharacter extends Character
{
	public var posOffset:FlxPoint; // X and Y offset of the character from where it should be positioned.
	public var focusScale:Float; // The X and Y scale for when the character is focused on.
	public var unfocusScale:Float; // The X and Y scale for when the character is on the side/off-screen.

	public var z:Int = 0;

	/** (Tech)
	 * Creates a new StoryMenuCharacter.
	 * @param x X position for character.
	 * @param y Y position for character.
	 * @param character Name of the character. Must be the same as in Character.hx
	 * @param isPlayer Is this a player character?
	 * @param offset FlxPoint offset for the character.
	 * @param bigScale The X and Y scale for when the character is focused on.
	 * @param smallScale The X and Y scale for when the character is on the side/off-screen.
	 */
	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false, ?offset:FlxPoint, ?bigScale:Float = 0.9, ?smallScale:Float = 0.5)
	{
		super(x, y, character, isPlayer);

		if (offset == null)
		{
			posOffset = new FlxPoint(0, 0);
		}
		else
		{
			posOffset = offset;
		}
		focusScale = bigScale;
		unfocusScale = smallScale;

		setSpecialCharacterTransforms(character);

		shader = null;
	}

	function setSpecialCharacterTransforms(character:String)
	{
		switch (character)
		{
			case 'corruptro' | 'story/corruptro':
				posOffset = new FlxPoint(-150, 70);
			case 'retro-minus' | 'story/retro-minus':
				posOffset = new FlxPoint(-150, -50);
				focusScale = 0.75;
				unfocusScale = 0.35;
			case 'sakuroma' | 'story/sakuroma':
				focusScale = 0.80;
				unfocusScale = 0.45;
			case 'izzurius' | 'story/izzurius':
				focusScale = 0.85;
		}
	}
}

// A data structure that holds all the data needed for navigating through a story menu.
class StoryMenuData
{
	// Initial Data
	public var weekSongNames:Array<Array<String>>; // An array of song names. Must match the JSON file song name.
	public var weekUnlocked:Array<Bool>; // A bool array checking for if the player can access the week.
	public var weekCharacters:Array<String>; // An array of character names. Must match the strings of characters in the Character.hx class.
	public var weekNames:Array<String>; // An array of week names. Must match the file name of the image name for that week.
	public var weekThemes:Array<String>; // An array of week songs. Must match the file name of the ogg name for that week.
	public var introThemes:Array<String>; // An array of week intro songs. Must match the file name of the ogg name for that week. Janky way of geting around the issue of getting to this menu during the intro part of the song.
	public var weekColors:Array<FlxColor>; // An array of week colors associated with the character. Used for the text color of week names when there's no file.
	public var bgColors:Array<FlxColor>; // An array of background colors associated with the character. Used for the color of the background.
	public var logoFileNames:Array<String>; // An array of names that represent the file name of the logo that matches the week's character.
	public var bgSymbols:Array<String>; // An array of names that represent the file name of the background symbol that matches the week's character.
	public var scoreNames:Array<String>; // An array of names that represent the name that should be stored in scores.

	// Object groups
	public var weekSongs:FlxTypedGroup<FlxSound>;
	public var grpWeekBGs:FlxTypedGroup<FlxTypedGroup<FlxSprite>>;
	public var grpWeekText:FlxTypedGroup<FlxSprite>;
	public var grpWeekTitles:FlxTypedGroup<FlxSprite>;
	public var grpVisibleWeekCharacters:FlxTypedGroup<StoryMenuCharacter>;
	public var grpWeekCharacters:FlxTypedGroup<StoryMenuCharacter>;

	// Dynamic Data
	public var weekTitleOriginalScales:Array<FlxPoint>;

	// Point to other structures for navigation
	public var nextMenu:StoryMenuData;
	public var prevMenu:StoryMenuData;

	/** (Tech)
	 * Used to define data fo a week
	 * @param songs An array containing the song names for the week. Must match the JSON file song name.
	 * @param unlocked Is week unlocked by default or not.
	 * @param characters An array of character names. Must match the strings of characters in the Character.hx class.
	 * @param names An array of week names. Must match the file name of the image name for that week.
	 * @param themes An array of week songs. Must match the file name of the ogg name for that week.
	 * @param intros An array of week intro songs. Must match the file name of the ogg name for that week. Janky way of geting around the issue of getting to this menu during the intro part of the song.
	 * @param colors An array of week colors associated with the character. Used for the text color of week names when there's no file.
	 * @param bgColors An array of background colors associated with the character. Used for the color of the background.
	 * @param logos An array of names that represent the file name of the logo that matches the week's character.
	 * @param symbols An array of names that represent the file name of the background symbol that matches the week's character.
	 * @param scoreNames An array of names that represent the name that should be stored in scores.
	 */
	public function new(?songs:Array<Array<String>>, ?unlocked:Array<Bool>, ?characters:Array<String>, ?names:Array<String>, ?themes:Array<String>, ?intros:Array<String>, ?colors:Array<FlxColor>, ?bgColors:Array<FlxColor>, ?logos:Array<String>, ?symbols:Array<String>, ?scoreNames:Array<String>)
	{
		weekSongNames = songs;
		weekUnlocked = unlocked;
		weekCharacters = characters;
		weekNames = names;
		weekThemes = themes;
		introThemes = intros;
		weekColors = colors;
		this.bgColors = bgColors;
		logoFileNames = logos;
		bgSymbols = symbols;
		this.scoreNames = scoreNames;
	}

	public function init()
	{
		createObjectGroups();
		setupCharacters();
	}

	public function setCurrentWeek(curWeek:Int) {
		// Make first background symbols visible
		if (grpWeekBGs.length > curWeek)
		{
			if(grpWeekBGs.members[curWeek].length > 0) {
				for (i in 0...grpWeekBGs.members[curWeek].length)
				{
					grpWeekBGs.members[curWeek].members[i].alpha = 1;
				}
			}
		}

		// Make first logos visible
		if (grpWeekText.length > curWeek)
		{
			grpWeekText.members[curWeek].visible = true;
		}

		// Make first titles visible
		if (grpWeekTitles.length > curWeek)
		{
			grpWeekTitles.members[curWeek].visible = true;
		}
	}

	public function setVisibility(isVisible:Bool)
	{
		grpWeekBGs.visible = isVisible;
		grpWeekText.visible = isVisible;
		grpWeekTitles.visible = isVisible;
		grpVisibleWeekCharacters.visible = isVisible;
	}

	function createObjectGroups()
	{
		// Music themes for each week
		weekSongs = new FlxTypedGroup<FlxSound>();
		for (i in 0...weekThemes.length)
		{
			var music:FlxSound = new FlxSound().loadEmbedded(Paths.music(weekThemes[i]), true, true);
			weekSongs.add(music);
			FlxG.sound.list.add(music);
		}

		// Add scrolling backgrounds
		grpWeekBGs = new FlxTypedGroup<FlxTypedGroup<FlxSprite>>();
		for (i in 0...bgSymbols.length)
		{
			if (bgSymbols[i] != '')
			{
				var symbols:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
				var symbolImage = Paths.image('storymenu/' + bgSymbols[i], 'preload');
				// 6 columns across
				for (j in 0...6)
				{
					// 8 rows down
					for (k in 0...8)
					{
						var weekBG:FlxSprite = new FlxSprite(((k % 2 == 1) ? -300 : -150) + (j * 300),
							-150 + (k * 150)).loadGraphic(symbolImage);
						weekBG.antialiasing = ClientPrefs.globalAntialiasing;
						weekBG.alpha = 0;
						weekBG.active = false;
						symbols.add(weekBG);
					}
				}

				grpWeekBGs.add(symbols);
			}
			// No symbol name identified. Just add empty object
			else
			{
				grpWeekBGs.add(new FlxTypedGroup<FlxSprite>());
			}
		}

		// Create text/logos for each character
		grpWeekText = new FlxTypedGroup<FlxSprite>();
		for (i in 0...logoFileNames.length)
		{
			// Coming Soon placeholder
			if (logoFileNames[i] == 'ComingSoonLogo')
			{
				var weekThing:FlxSprite = new FlxSprite(FlxG.width * 0.7, -275).loadGraphic(Paths.image(logoFileNames[i]));
				weekThing.scale.set(0.125, 0.125);
				weekThing.screenCenter(X);
				weekThing.antialiasing = ClientPrefs.globalAntialiasing;
				weekThing.visible = false;
				weekThing.active = false;
				grpWeekText.add(weekThing);
			}
			// Regular logo
			// Oh fuck this is going to cause issues down the road
			else
			{
				var weekThing:FlxSprite = new FlxSprite(FlxG.width * 0.7, 215).loadGraphic(Paths.image(logoFileNames[i]));
				weekThing.scale.set(0.2, 0.2);
				// weekThing.y += ((weekThing.height + 20) * i);
				// weekThing.targetY = i;
				grpWeekText.add(weekThing);

				weekThing.screenCenter(X);
				weekThing.antialiasing = ClientPrefs.globalAntialiasing;
				// weekThing.updateHitbox();
				weekThing.visible = false;
				weekThing.active = false;
			}
		}

		// Create title text/graphics for each character
		grpWeekTitles = new FlxTypedGroup<FlxSprite>();
		weekTitleOriginalScales = new Array<FlxPoint>();
		for (i in 0...weekNames.length)
		{
			// Graphic
			if (weekNames[i].endsWith('title'))
			{
				var weekThing:FlxSprite = new FlxSprite(0, 400).loadGraphic(Paths.image('storymenu/' + weekNames[i]));

				weekThing.setGraphicSize(271, 144);
				weekThing.updateHitbox();

				weekThing.screenCenter(X);

				weekThing.antialiasing = ClientPrefs.globalAntialiasing;
				weekThing.visible = false;
				weekThing.active = false;

				grpWeekTitles.add(weekThing);
				weekTitleOriginalScales.push(new FlxPoint(weekThing.scale.x, weekThing.scale.y));
			}
			// Plain text
			else
			{
				var weekThing:FlxText = new FlxText(-50, 425, 0, weekNames[i], 28);
				weekThing.color = weekColors[i];
				weekThing.screenCenter(X);
				weekThing.visible = false;
				weekThing.active = false;
				weekThing.antialiasing = ClientPrefs.globalAntialiasing;

				grpWeekTitles.add(weekThing);
				weekTitleOriginalScales.push(new FlxPoint(weekThing.scale.x, weekThing.scale.y));
			}
		}

		// Create the characters
		grpWeekCharacters = new FlxTypedGroup<StoryMenuCharacter>();
		grpVisibleWeekCharacters = new FlxTypedGroup<StoryMenuCharacter>();
		for (i in 0...weekCharacters.length)
		{
			var char:StoryMenuCharacter = new StoryMenuCharacter(0, 0, weekCharacters[i]);
			grpWeekCharacters.add(char);
			grpVisibleWeekCharacters.add(char);
		}
	}

	function setupCharacters()
	{
		if (grpWeekCharacters.length > 0)
		{
			// Pretty much a pointer
			var charPointer:StoryMenuCharacter = grpWeekCharacters.members[0];

			// Put first character in the middle
			charPointer.setPosition(425 + charPointer.posOffset.x, -20 + charPointer.posOffset.y);
			charPointer.scale.x = charPointer.focusScale;
			charPointer.scale.y = charPointer.focusScale;

			if (grpWeekCharacters.length > 1)
			{
				charPointer = grpWeekCharacters.members[1];

				// Second character to the right
				charPointer.setPosition(825 + charPointer.posOffset.x, -25 + charPointer.posOffset.y);
				charPointer.scale.x = charPointer.unfocusScale;
				charPointer.scale.y = charPointer.unfocusScale;
				charPointer.color = FlxColor.BLACK;

				if (grpWeekCharacters.length > 2)
				{
					charPointer = grpWeekCharacters.members[grpWeekCharacters.length - 1];

					// Last character to the left
					charPointer.setPosition(-25 + charPointer.posOffset.x, -25 + charPointer.posOffset.y);
					charPointer.scale.x = charPointer.unfocusScale;
					charPointer.scale.y = charPointer.unfocusScale;
					charPointer.color = FlxColor.BLACK;

					// All other characters off-screen
					for (i in 2...grpWeekCharacters.length - 1)
					{
						grpWeekCharacters.members[i].setPosition(1450 + grpWeekCharacters.members[i].posOffset.x, -25 + grpWeekCharacters.members[i].posOffset.y);
						grpWeekCharacters.members[i].scale.x = grpWeekCharacters.members[i].unfocusScale;
						grpWeekCharacters.members[i].scale.y = grpWeekCharacters.members[i].unfocusScale;
						grpWeekCharacters.members[i].color = FlxColor.BLACK;
					}
				}
			}
		}
	}
}

// A small data structure that holds the text and sprites needed to change in the menu text navigation groups.
class MenuNavData
{
	public var text:FlxText;
	public var sticker:FlxSprite;

	public function new(txt:FlxText, stick:FlxSprite)
	{
		text = txt;
		sticker = stick;
	}
}

class StoryMenuState extends UnlockableMusicBeatState
{
	static var menuState:MenuState = None;

	private static var lastDifficultyName:String = '';

	var normalMenu:StoryMenuData; // Data container for the normal menu
	var minusMenu:StoryMenuData; // Data container for the minus menu
	var corruptMenu:StoryMenuData; // Data container for the corrupt menu
	var currentMenu:StoryMenuData; // Data container for the current menu that all visual logic draws from

	var scoreText:FlxFixedText;
	var txtWeekTitle:FlxFixedText;
	var controlsConfirmText:FlxText;
	var controlsBackText:FlxText;

	static var curWeek:Int = 0;
	static var curMode:Int = 0;
	static var curDifficulty:Int = 1;
	var curBF:Int = 0;
	var curGf:Int = 0;

	var weekSongs:FlxTypedGroup<FlxSound>;
	var grpWeekBGs:FlxTypedGroup<FlxTypedGroup<FlxSprite>>;
	var grpWeekText:FlxTypedGroup<FlxSprite>;
	var grpWeekTitles:FlxTypedGroup<FlxSprite>;
	var grpWeekCharacters:FlxTypedGroup<Character>;
	var bfCharacters:FlxTypedGroup<Character>;
	var gfIcons:FlxTypedGroup<HealthIcon>;
	var aboveNav:MenuNavData;
	var belowNav:MenuNavData;
	var aboveSpriteGroup:FlxTypedGroup<FlxSprite>;
	var belowSpriteGroup:FlxTypedGroup<FlxSprite>;

	var weekTitleOriginalScales:Array<FlxPoint>;

	var bg:FlxSpriteExtra;
	var blackCover:FlxSpriteExtra;
	var sprMode:FlxSprite;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	// Managers/Singletons
	//var unlockManager:UnlockablesManager;
	//var saveManager:SaveDataManager;

	var badge:StoryMedal;
	var badgeApoc:StoryMedal;

	var flamingCorruptroBadge:StoryMedal;
	var corruptroBadge:StoryMedal;

	var goop:FlxSprite;

	// Secrets
	var charInputs:String;
	static var cheatCode1:String = "MOMMYMOTHYMILKIES";
	static var cheatCode2:String = "DRYOCAMPARUBICUNDATHEROSYMAPLEMOTHISASMALLNORTHAMERICANMOTHINTHEFAMILYSATURNIIDAEALSOKNOWNASTHEGREATSILKMOTHSITWASFIRSTDESCRIBEDBYJOHANCHRISTIANFABRICIUSIN1793THESPECIESISKNOWNFORITSWOOLYBODYANDPINKANDYELLOWCOLORATIONWHICHVARIESFROMCREAMORWHITETOBRIGHTPINKORYELLOWMALESHAVEBUSHIERANTENNAETHANFEMALESWHICHALLOWTHEMTOSENSEFEMALEPHEROMONESFORMATING";
	static var cheatCode3:String = "MAGNIFICENTMAJESTICMARKETABLEMARVELOUSMEGAMOMMYMOTHYMILKIES";
	static var cheatCode4:String = "HEARTMELTER";

	// (Tech) Bool for checking if menu was on Saku while typing code in
	var sakuStart:Bool = false;

	public var obsFix:FlxCamera;
	public var camGame:FlxCamera;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.setCurrentLevel('shared');

		//PlayState.curSong = "";

		#if windows
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Story Mode Menu", null);
		#end

		if(Unlocks.newMenuItem.contains("story-mode")) {
			Unlocks.newMenuItem.remove("story-mode");
			Unlocks.saveUnlocks();
		}

		//weekUnlocked = unlockWeeks();
		if(menuState == None) {
			menuState = Normal; // Start with the normal menu state
		}
		initializeMenuData();
		Paths.currentTrackedAssets.remove('assets/music/${MainMenuState.songName}.ogg');

		obsFix = new FlxCamera();
		camGame = new FlxCamera();

		FlxG.cameras.reset(obsFix);
		FlxG.cameras.add(camGame, true);
		FlxG.camera = camGame;
		FlxG.cameras.setDefaultDrawTarget(obsFix, false);

		// Managers
		//saveManager = SaveDataManager.instance;
		//unlockManager = UnlockablesManager.instance;

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (TitleState.introMusic == null || !TitleState.introMusic.playing)
		{
			if (FlxG.sound.music != null && FlxG.sound.music.playing)
			{
				if (MainMenuState.songName != currentMenu.weekThemes[curWeek])
				{
					var songTime = FlxG.sound.music.time;
					FlxG.sound.playMusic(Paths.music(currentMenu.weekThemes[curWeek]), 0.75);
					FlxG.sound.music.time = songTime;
					MainMenuState.songName = currentMenu.weekThemes[curWeek];
					Conductor.changeBPM(102);
				}
			}
			else
			{
				FlxG.sound.playMusic(Paths.music(currentMenu.weekThemes[curWeek]), 0.75);
				MainMenuState.songName = currentMenu.weekThemes[curWeek];
				Conductor.changeBPM(102);
			}
		}

		Conductor.changeBPM(102);

		persistentUpdate = persistentDraw = true;

		scoreText = new FlxFixedText(10, FlxG.height + 40, 0, "SCORE: 0", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32);
		scoreText.active = false;

		txtWeekTitle = new FlxFixedText(FlxG.width * 0.7, 800, 0, "", 32);
		txtWeekTitle.text = "Select Mode";
		txtWeekTitle.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.screenCenter(X);
		txtWeekTitle.alpha = 0.7;
		txtWeekTitle.active = false;

		controlsConfirmText = new FlxFixedText(1090, FlxG.height + 30, 0, "ENTER - Confirm", 20);
		controlsConfirmText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
		controlsConfirmText.active = false;

		controlsBackText = new FlxFixedText(1150, FlxG.height + 55, 0, "ESC - Back", 20);
		controlsBackText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
		controlsBackText.active = false;

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		bg = new FlxSpriteExtra(0, 0).makeSolid(FlxG.width, FlxG.height, 0xFFFFFFFF);
		bg.color = currentMenu.bgColors[curWeek];
		bg.active = false;

		//if (currentMenu.grpWeekBGs.members[curWeek].length > 0)
		//{
		//	for (i in 0...currentMenu.grpWeekBGs.members[curWeek].length)
		//	{
		//		currentMenu.grpWeekBGs.members[curWeek].members[i].alpha = 1;
		//	}
		//}

		bfCharacters = new FlxTypedGroup<Character>();

		// Make a separate character for each bf instead of having to reload the assets every time it switches
		for (bf in Unlocks.allBfs)//saveManager.unlockData.bfs)
		{
			var bfChar:Character = new Character(FlxG.width + 200, 250, "story/" + bf, true);

			switch(bf)
			{
				case 'bf-minus':
					bfChar.addOffset('idle',6, 47);
					bfChar.addOffset('hey', 6, 47);
					bfChar.playAnim('idle', true);
				case 'bf-saku':
					bfChar.y -= 22;
					bfChar.addOffset('idle', 0, 66);
					//bfChar.addOffset('hey', 16, 86);
					bfChar.playAnim('idle', true);
			}

			bfChar.shader = null;
			bfChar.scale.set(0.5, 0.5);
			bfChar.x -= bfChar.width / 2;

			switch(bf)
			{
				case 'bf-minus' | 'bf-ace':
					bfChar.x += 40;
			}
			bfChar.visible = false;
			bfCharacters.add(bfChar);
		}

		if (Unlocks.unlockedGfs.length > 1)//saveManager.unlockData.gfs.filter(function(gf) return gf.unlocked).length > 1)
		{
			gfIcons = new FlxTypedGroup<HealthIcon>();

			for (gf in Unlocks.unlockedGfs)
			{
				var gfIcon:HealthIcon = new HealthIcon(gf, true);
				gfIcon.scale.set(0.75, 0.75);
				gfIcon.setPosition(FlxG.width + 200, 535);
				gfIcon.visible = false;
				gfIcons.add(gfIcon);
			}

			gfIcons.members[0].visible = true;
		}

		bfCharacters.members[0].visible = true;

		// Show only the first week
		currentMenu.grpWeekTitles.members[curWeek].visible = true;
		currentMenu.grpWeekText.members[curWeek].visible = true;

		leftArrow = new FlxSprite(300, 200);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.scale.set(0.5, 0.5);
		leftArrow.animation.play('idle');
		leftArrow.antialiasing = ClientPrefs.globalAntialiasing;

		// Game mode text
		sprMode = new FlxSprite(FlxG.width + 200, 100);
		sprMode.frames = ui_tex;
		sprMode.animation.addByPrefix('standard', 'STANDARD');
		sprMode.animation.addByPrefix('nofail', 'NO FAIL');
		sprMode.animation.addByPrefix('nofaillock', 'no fail lock');
		sprMode.animation.addByPrefix('freestyle', 'FREESTYLE');
		sprMode.animation.addByPrefix('freestylelock', 'freestyle lock');
		sprMode.animation.addByPrefix('randomized', 'RANDOMIZED');
		sprMode.animation.addByPrefix('randomizedlock', 'randomized lock');
		sprMode.animation.addByPrefix('insta-death', 'instadeathtext');
		sprMode.animation.addByPrefix('insta-deathlock', 'instadeathlocktext');
		sprMode.animation.play('standard');
		sprMode.antialiasing = ClientPrefs.globalAntialiasing;

		// Difficulty stuff
		sprDifficulty = new FlxSprite(sprMode.x, 225);
		sprDifficulty.frames = ui_tex;
		sprDifficulty.animation.addByPrefix('easy', 'EASY');
		sprDifficulty.animation.addByPrefix('normal', 'NORMAL');
		sprDifficulty.animation.addByPrefix('hard', 'HARD');
		sprDifficulty.animation.addByPrefix('hell', 'HELL');
		sprDifficulty.animation.play('easy');
		sprDifficulty.antialiasing = ClientPrefs.globalAntialiasing;

		Difficulty.difficulties = Difficulty.defaultDifficulties.copy();
		if(lastDifficultyName == '')
		{
			lastDifficultyName = Difficulty.defaultDifficulty;
		}
		Difficulty.difficulties = [
			'Easy',
			'Normal',
			'Hard',
			'Hell'
		];
		//Difficulty.remove(Difficulty.EASY);
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultDifficulties.indexOf(lastDifficultyName)));

		/*sprDifficulty = new FlxSprite(sprMode.x, 225);
		sprDifficulty.antialiasing = ClientPrefs.globalAntialiasing;*/
		//difficultySelectors.add(sprDifficulty);
		changeDifficulty(0, false);

		rightArrow = new FlxSprite(825, 200);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.scale.set(0.5, 0.5);
		rightArrow.animation.play('idle');
		rightArrow.antialiasing = ClientPrefs.globalAntialiasing;

		// (Arcy) UI stuff for showing navigation to the top menu
		aboveSpriteGroup = new FlxTypedGroup<FlxSprite>();
		aboveSpriteGroup.visible = false;

		var aboveWeekText:FlxFixedText = new FlxFixedText(0, 0, 0, 'Regular Story');
		aboveWeekText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE);
		aboveWeekText.screenCenter(X);
		aboveWeekText.active = false;
		aboveSpriteGroup.add(aboveWeekText);

		var aboveWeekLeftArrow:FlxText = new FlxText(aboveWeekText.x - 100, 0, 0, 'v');
		aboveWeekLeftArrow.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE);
		aboveWeekLeftArrow.angle = 180;
		aboveWeekLeftArrow.active = false;
		FlxTween.tween(aboveWeekLeftArrow, {y: 25}, 0.75, { type: FlxTweenType.PINGPONG, ease: FlxEase.cubeInOut }); // (Arcy) Boing!
		aboveSpriteGroup.add(aboveWeekLeftArrow);

		var aboveWeekRightArrow:FlxText = new FlxText(aboveWeekText.x + aboveWeekText.width + 100, aboveWeekText.y, 0, 'v');
		aboveWeekRightArrow.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE);
		aboveWeekRightArrow.angle = 180;
		aboveWeekRightArrow.active = false;
		FlxTween.tween(aboveWeekRightArrow, {y: 25}, 0.75, { type: FlxTweenType.PINGPONG, ease: FlxEase.cubeInOut }); // (Arcy) Boing!
		aboveSpriteGroup.add(aboveWeekRightArrow);

		var aboveSticker:FlxSprite = new FlxSprite(aboveWeekText.x + aboveWeekText.width - 100, aboveWeekText.y - 75);
		aboveSticker.frames = Paths.getSparrowAtlas('new_text', 'preload');
		aboveSticker.animation.addByPrefix('Animate', 'NEW', 24);
		aboveSticker.animation.play('Animate');
		aboveSticker.scale.set(0.33, 0.33);
		aboveSticker.antialiasing = ClientPrefs.globalAntialiasing;
		aboveSticker.visible = Unlocks.newWeeks.contains("corrupt"); // TODO: Make this better?
		aboveSpriteGroup.add(aboveSticker);

		aboveNav = new MenuNavData(aboveWeekText, aboveSticker);

		// (Arcy) UI stuff for showing navigation to the bottom menu
		belowSpriteGroup = new FlxTypedGroup<FlxSprite>();

		var belowWeekText:FlxFixedText = new FlxFixedText(0, 0, 0, 'Infernal Paradise');
		belowWeekText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE);
		belowWeekText.screenCenter(X);
		belowWeekText.y = FlxG.height - belowWeekText.height - 10;
		belowWeekText.active = false;
		belowSpriteGroup.add(belowWeekText);

		var belowWeekLeftArrow:FlxText = new FlxText(belowWeekText.x - 100, belowWeekText.y, 0, 'v');
		belowWeekLeftArrow.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE);
		belowWeekLeftArrow.active = false;
		FlxTween.tween(belowWeekLeftArrow, {y: belowWeekText.y - 25}, 0.75, { type: FlxTweenType.PINGPONG, ease: FlxEase.cubeInOut }); // (Arcy) Boing!
		belowSpriteGroup.add(belowWeekLeftArrow);

		var belowWeekRightArrow:FlxText = new FlxText(belowWeekText.x + belowWeekText.width + 100, belowWeekText.y, 0, 'v');
		belowWeekRightArrow.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE);
		belowWeekRightArrow.active = false;
		FlxTween.tween(belowWeekRightArrow, {y: belowWeekText.y - 25}, 0.75, { type: FlxTweenType.PINGPONG, ease: FlxEase.cubeInOut }); // (Arcy) Boing!
		belowSpriteGroup.add(belowWeekRightArrow);

		var belowSticker:FlxSprite = new FlxSprite(belowWeekText.x + belowWeekText.width - 100, belowWeekText.y - 100);
		belowSticker.frames = Paths.getSparrowAtlas('new_text', 'preload');
		belowSticker.animation.addByPrefix('Animate', 'NEW', 24);
		belowSticker.animation.play('Animate');
		belowSticker.scale.set(0.33, 0.33);
		belowSticker.antialiasing = ClientPrefs.globalAntialiasing;
		belowSticker.visible = Unlocks.newWeeks.contains("minus"); // TODO: Make this better?
		belowSpriteGroup.add(belowSticker);

		belowNav = new MenuNavData(belowWeekText, belowSticker);

		charInputs = "";

		add(bg);
		add(normalMenu.grpWeekBGs);
		add(minusMenu.grpWeekBGs);
		add(corruptMenu.grpWeekBGs);

		goop = new FlxSprite(Paths.image("goop", "shared"));
		goop.antialiasing = ClientPrefs.globalAntialiasing;
		add(goop);

		add(normalMenu.grpVisibleWeekCharacters);
		add(minusMenu.grpVisibleWeekCharacters);
		add(corruptMenu.grpVisibleWeekCharacters);
		add(sprMode);
		add(sprDifficulty);
		// add(bfCharacter);
		add(bfCharacters);
		if(gfIcons != null) {
			add(gfIcons);
		}

		blackCover = new FlxSpriteExtra(0, 400);
		blackCover.makeSolid(FlxG.width, FlxG.height - 300, FlxColor.BLACK);
		blackCover.active = false;
		add(blackCover);

		Difficulty.useAllDiffs = true;

		// Cheap, lazy way to check if Ectospasm was beaten
		if (Highscore.hasMedal('Ectospasm', Difficulty.APOCALYPSE)) {
			badgeApoc = new StoryMedal(1050, 475);
			badgeApoc.frames = Paths.getSparrowAtlas('medals/EctobadgeApoc');
			badgeApoc.animation.addByPrefix('shine', 'BopingSymbol', 24);
			badgeApoc.animation.play('shine');
			badgeApoc.antialiasing = ClientPrefs.globalAntialiasing;
			add(badgeApoc);
		}
		else if (Highscore.hasMedal('Ectospasm', Difficulty.HELL)) {
			badge = new StoryMedal(1150 - 12, 575 - 10);
			badge.frames = Paths.getSparrowAtlas('medals/Badge');
			badge.animation.addByPrefix('shine', 'Badge Shine', 24);
			badge.animation.play('shine');
			badge.antialiasing = ClientPrefs.globalAntialiasing;
			add(badge);
		}

		// Cheap, lazy way to check if Corruptro was beaten
		if (Highscore.hasMedal('Corruptro', Difficulty.HELL)) {
			flamingCorruptroBadge = new StoryMedal(1050 - 92 - 92 + 70 - 40, 475);
			flamingCorruptroBadge.frames = Paths.getSparrowAtlas('medals/Corruptro_Medal');
			flamingCorruptroBadge.animation.addByPrefix('shine', 'BopingSymbol', 24);
			flamingCorruptroBadge.animation.play('shine');
			flamingCorruptroBadge.antialiasing = ClientPrefs.globalAntialiasing;
			add(flamingCorruptroBadge);
		}
		else if (Highscore.hasMedal('Corruptro', Difficulty.HARD)) {
			corruptroBadge = new StoryMedal(1150 - 92 - 92 + 70 + 11 - 40, 575 + 15);
			corruptroBadge.frames = Paths.getSparrowAtlas('medals/Corruptro_Medal_withnodripsmh');
			corruptroBadge.animation.addByPrefix('shine', 'ShinySymbol dripless', 24);
			corruptroBadge.animation.play('shine');
			corruptroBadge.antialiasing = ClientPrefs.globalAntialiasing;
			add(corruptroBadge);
		}

		Difficulty.useAllDiffs = false;

		add(normalMenu.grpWeekTitles);
		add(minusMenu.grpWeekTitles);
		add(corruptMenu.grpWeekTitles);
		add(normalMenu.grpWeekText);
		add(minusMenu.grpWeekText);
		add(corruptMenu.grpWeekText);
		add(aboveSpriteGroup);
		add(belowSpriteGroup);
		add(leftArrow);
		add(rightArrow);

		

		add(scoreText);
		add(txtWeekTitle);
		add(controlsConfirmText);
		add(controlsBackText);

		// Unlock stuff covers over everything
		//unlockManager.create(this);

		updateText();
		if(menuState == Normal) normalBfWorkaround(); //temp?
		if(menuState == Minus) minusBfWorkaround(); //temp?
		if(menuState == Corrupt) corruptBfWorkaround(); //temp?

		changeWeek(0, false);

		updateMenuSprites();

		goop.alpha = curWeek == 0 && menuState == Normal ? 1 : 0;
		updateBadges();

		#if android
		addVirtualPad(LEFT_FULL, A_B);
		#end
			
		super.create();
		Paths.clearUnusedMemory();
		openfl.system.System.gc();
	}

	override function update(elapsed:Float)
	{
		//FlxG.watch.addQuick("Current week", curWeek);
		// Workaround to avoid sound stutter issue with time lost during loading
		if ((TitleState.introMusic == null || !TitleState.introMusic.playing) && FlxG.sound.music != null && FlxG.sound.music.playing && !movedBack)
		{
			currentMenu.weekSongs.members[curWeek].play(false, FlxG.sound.music.time % currentMenu.weekSongs.members[curWeek].length);
			currentMenu.weekSongs.members[curWeek].volume = 0.75;

			if (MainMenuState.songName != currentMenu.weekThemes[curWeek])
			{
				Paths.dumpExclusions.remove('assets/music/${MainMenuState.songName}.ogg');
				MainMenuState.songName = currentMenu.weekThemes[curWeek];
				Paths.dumpExclusions.push('assets/music/${MainMenuState.songName}.ogg');
				currentMenu.weekSongs.members[curWeek].fadeIn(0.5, 0, 0.75);
				FlxG.sound.music.fadeOut(0.5, 0, function(twn:FlxTween)
				{
					FlxG.sound.music.pause();
				});
			}
			else
			{
				FlxG.sound.music.pause();
			}
		}

		// Kept track for animations on beat
		if (TitleState.introMusic != null && TitleState.introMusic.playing)
		{
			Conductor.songPosition = TitleState.introMusic.time;
		}
		else
		{
			Conductor.songPosition = currentMenu.weekSongs.members[curWeek].time;
		}

		// Workaround for missing a beat animation on song loop
		if (Conductor.songPosition == 0)
		{
			beatHit();
		}

		// scoreText.setFormat(Paths.font("vcr.ttf"), 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.5));

		scoreText.text = "WEEK SCORE:" + lerpScore;

		// Cheat code for Fuzzy Feeling
		checkCodeInput();

		// Bogos Bumpin?
		if (currentMenu.weekNames[curWeek].endsWith('title') && currentMenu.grpWeekTitles.members[curWeek].scale.x > currentMenu.weekTitleOriginalScales[curWeek].x)
		{
			currentMenu.grpWeekTitles.members[curWeek].scale.x -= 0.5 * elapsed * currentMenu.weekTitleOriginalScales[curWeek].x;
			currentMenu.grpWeekTitles.members[curWeek].scale.y -= 0.5 * elapsed * currentMenu.weekTitleOriginalScales[curWeek].y;
		}
		if (currentMenu.logoFileNames[curWeek] == 'ComingSoonLogo' && currentMenu.grpWeekText.members[curWeek].scale.x > 0.125)
		{
			currentMenu.grpWeekText.members[curWeek].scale.x -= 0.25 * elapsed;
			currentMenu.grpWeekText.members[curWeek].scale.y -= 0.25 * elapsed;
		}
		else if (currentMenu.grpWeekText.members[curWeek].scale.x > 0.2)
		{
			currentMenu.grpWeekText.members[curWeek].scale.x -= 0.25 * elapsed;
			currentMenu.grpWeekText.members[curWeek].scale.y -= 0.25 * elapsed;
		}

		// Pan the background
		// Oh FUCK I have to do each one because the transitions show both NOOOOOO
		if (ClientPrefs.motion)
		{
			for (i in 0...currentMenu.grpWeekBGs.length)
			{
				if (currentMenu.grpWeekBGs.members[i].length > 0)
				{
					for (j in 0...currentMenu.grpWeekBGs.members[i].length)
					{
						var icon = currentMenu.grpWeekBGs.members[i].members[j];
						icon.x -= 100 * elapsed;
						icon.y += 100 * elapsed;

						// Reset position when end of the image is reached
						if (icon.x <= -300)
						{
							//icon.x = 1500;
							icon.x += 300+1500;
						}
						if (icon.y >= 1050)
						{
							//icon.y = -150;
							icon.y -= 150+1050;
						}
					}
				}
			}
		}

		if (unlocking)
		{
			//unlockManager.update(elapsed, this, controls);
		}
		else if (!movedBack && !stopspamming && finishedMovingMenus)
		{
			// Moved the control animations outside since it's shared with all selections
			if (controls.UI_RIGHT)
			{
				rightArrow.animation.play('press');
				rightArrow.offset.set(-20, -10);
			}
			else
			{
				rightArrow.animation.play('idle');
				rightArrow.offset.set(0, 0);
			}

			if (controls.UI_LEFT)
			{
				leftArrow.animation.play('press');
				leftArrow.offset.set(-25, -10);
			}
			else
			{
				leftArrow.animation.play('idle');
				leftArrow.offset.set(0, 0);
			}

			if(FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
			}

			if (!selectedWeek)
			{
				if (controls.ACCEPT)
				{
					selectWeek();
				}
				else if (controls.UI_RIGHT_P)
				{
					changeWeek(1);
				}
				else if (controls.UI_LEFT_P)
				{
					changeWeek(-1);
				}
				else if (controls.UI_UP_P)
				{
					changeMenu(false);
				}
				else if (controls.UI_DOWN_P)
				{
					changeMenu(true);
				}

				else if (controls.BACK)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					movedBack = true;

					// Keep the current theme going
					if (TitleState.introMusic == null || !TitleState.introMusic.playing)
					{
						FlxG.sound.music.loadEmbedded(Paths.music(currentMenu.weekThemes[curWeek]), true, true);
						FlxG.sound.music.play(false, currentMenu.weekSongs.members[curWeek].time % currentMenu.weekSongs.members[curWeek].length);
						currentMenu.weekSongs.members[curWeek].stop();
					}
					MusicBeatState.switchState(new MainMenuState());
				}
			}
			else if (selectedSettings)
			{
				if (controls.ACCEPT)
				{
					confirmWeek();
					//for (i in Paths.dumpExclusions) trace(i);
				}
				else if (controls.BACK)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					selectedSettings = false;

					// Don't break shit >:(
					stopspamming = true;

					// Bring those arrows back
					FlxTween.tween(leftArrow, {alpha: 1}, 0.5, {ease: FlxEase.cubeOut});
					FlxTween.tween(rightArrow, {alpha: 1}, 0.5, {ease: FlxEase.cubeOut});

					// Down and up
					FlxTween.tween(txtWeekTitle, {y: 750}, 0.25, {
						ease: FlxEase.cubeOut,
						onComplete: function(flx:FlxTween)
						{
							if (!selectedMode)
								txtWeekTitle.text = "Select Mode";
							else if (!selectedDifficulty)
								txtWeekTitle.text = "Select Difficulty";
							else
								txtWeekTitle.text = "Select Character";

							FlxTween.tween(txtWeekTitle, {y: 675}, 0.25, {
								ease: FlxEase.cubeOut,
								onComplete: function(flx:FlxTween)
								{
									stopspamming = false;
								}
							});
						}
					});
				}
			}
			else if (!selectedMode)
			{
				if (controls.ACCEPT)
				{
					selectSettings();
				}
				else if (controls.UI_RIGHT_P)
				{
					changeMode(1);
				}
				else if (controls.UI_LEFT_P)
				{
					changeMode(-1);
				}
				else if (controls.UI_DOWN_P)
				{
					selectMode();
				}
				else if (controls.BACK)
				{
					cancelStorySettings();
				}
			}
			else if (!selectedDifficulty)
			{
				if (controls.ACCEPT)
				{
					selectSettings();
				}
				else if (controls.UI_RIGHT_P)
				{
					changeDifficulty(1);
				}
				else if (controls.UI_LEFT_P)
				{
					changeDifficulty(-1);
				}
				else if (controls.UI_DOWN_P)
				{
					// (Arcy) Cuck them out of changing BF/GF for Minus menu
					if (currentMenu != minusMenu && currentMenu != corruptMenu)
					{
						selectDifficulty();
					}
				}
				else if (controls.UI_UP_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					selectedMode = false;

					// Don't break shit >:(
					stopspamming = true;
					txtWeekTitle.text = "Select Mode";
					txtWeekTitle.screenCenter(X);

					// Move the arrows back up
					FlxTween.tween(leftArrow, {x: 535, y: 90}, 0.15, {ease: FlxEase.cubeOut});
					FlxTween.tween(rightArrow, {x: 1100, y: 90}, 0.15, {
						ease: FlxEase.cubeOut,
						onComplete: function(flx:FlxTween)
						{
							stopspamming = false;
						}
					});
				}
				else if (controls.BACK)
				{
					cancelStorySettings();
				}
			}
			else if (!selectedCharacter)
			{
				if (controls.ACCEPT)
				{
					selectSettings();
				}
				else if (controls.UI_RIGHT_P)
				{
					changeCharacter(1);
				}
				else if (controls.UI_LEFT_P)
				{
					changeCharacter(-1);
				}
				else if (controls.UI_DOWN_P && gfIcons != null)
				{
					selectCharacter();
				}
				else if (controls.UI_UP_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					selectedDifficulty = false;

					// Don't break shit >:(
					stopspamming = true;
					txtWeekTitle.text = "Select Difficulty";
					txtWeekTitle.screenCenter(X);

					// Move the arrows back up
					FlxTween.tween(leftArrow, {x: 600, y: 215}, 0.15, {ease: FlxEase.cubeOut});
					FlxTween.tween(rightArrow, {x: 1025, y: 215}, 0.15, {
						ease: FlxEase.cubeOut,
						onComplete: function(flx:FlxTween)
						{
							stopspamming = false;
						}
					});
				}
				else if (controls.BACK)
				{
					cancelStorySettings();
				}
			}
			else
			{
				if (controls.ACCEPT)
				{
					selectSettings();
				}
				else if (controls.UI_RIGHT_P)
				{
					changeGirlfriend(1);
				}
				else if (controls.UI_LEFT_P)
				{
					changeGirlfriend(-1);
				}
				else if (controls.UI_UP_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					selectedCharacter = false;

					// Don't break shit >:(
					stopspamming = true;
					txtWeekTitle.text = "Select Character";
					txtWeekTitle.screenCenter(X);

					// Move the arrows back up
					FlxTween.tween(leftArrow, {x: 660, y: 415}, 0.15, {ease: FlxEase.cubeOut});
					FlxTween.tween(rightArrow, {x: 965, y: 415}, 0.15, {
						ease: FlxEase.cubeOut,
						onComplete: function(flx:FlxTween)
						{
							stopspamming = false;
						}
					});
				}
				else if (controls.BACK)
				{
					cancelStorySettings();
				}
			}
		}

		super.update(elapsed);
	}

	override function closeSubState() {
		persistentUpdate = true;
		super.closeSubState();
	}

	override function beatHit()
	{
		super.beatHit();

		// Characters dance on beat
		for (i in 0...currentMenu.grpWeekCharacters.length)
		{
			currentMenu.grpWeekCharacters.members[i].animation.play('idle', true);
		}

		// Same with bf
		if (bfCharacters.members[curBF].animation.name != 'hey')
		{
			bfCharacters.members[curBF].animation.play('idle', true);
		}

		// And the logos
		if (currentMenu.weekNames[curWeek].endsWith('title'))
		{
			var originalX = currentMenu.weekTitleOriginalScales[curWeek].x;
			var originalY = currentMenu.weekTitleOriginalScales[curWeek].y;

			FlxTween.tween(currentMenu.grpWeekTitles.members[curWeek], {'scale.x': originalX * 1.05, 'scale.y': originalY * 1.05}, 0.025);
		}

		if (currentMenu.logoFileNames[curWeek] == 'ComingSoonLogo')
		{
			FlxTween.tween(currentMenu.grpWeekText.members[curWeek], {'scale.x': 0.15, 'scale.y': 0.15}, 0.025);
		}
		else
		{
			FlxTween.tween(currentMenu.grpWeekText.members[curWeek], {'scale.x': 0.225, 'scale.y': 0.225}, 0.025);
		}

		// Let's do the badge too, why not
		if (badge != null && curBeat % 2 == 0) {
			badge.animation.play('shine', true);
		}
		if (badgeApoc != null && curBeat % 2 == 0) {
			badgeApoc.animation.play('shine', true);
		}

		if (corruptroBadge != null && curBeat % 2 == 0) {
			corruptroBadge.animation.play('shine', true);
		}
		if (flamingCorruptroBadge != null && curBeat % 2 == 0) {
			flamingCorruptroBadge.animation.play('shine', true);
		}
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var selectedMode:Bool = false;
	var selectedDifficulty:Bool = false;
	var selectedCharacter:Bool = false;
	var selectedSettings:Bool = false;
	var stopspamming:Bool = false;

	function initializeMenuData()
	{
		normalMenu = getStoryMenuData("main");
		minusMenu = getStoryMenuData("minus");
		corruptMenu = getStoryMenuData("corrupt");

		normalMenu.init();
		minusMenu.init();
		corruptMenu.init();

		normalMenu.setCurrentWeek(curWeek);
		minusMenu.setCurrentWeek(0);
		corruptMenu.setCurrentWeek(0);

		// Set up node connections
		normalMenu.nextMenu = minusMenu;
		minusMenu.prevMenu = normalMenu;

		normalMenu.prevMenu = corruptMenu;
		corruptMenu.nextMenu = normalMenu;

		// Make it show up
		corruptMenu.weekUnlocked[0] = true;

		// Start with normal menu and set other menus to invisible
		currentMenu = normalMenu;
		if(menuState == Minus) {
			currentMenu = minusMenu;
		}
		if(menuState == Corrupt) {
			currentMenu = corruptMenu;
		}

		updateMenuVisiblity();
	}

	function updateMenuVisiblity() {
		normalMenu.setVisibility(currentMenu == normalMenu);
		minusMenu.setVisibility(currentMenu == minusMenu);
		corruptMenu.setVisibility(currentMenu == corruptMenu);

		if(currentMenu == corruptMenu) {
			menuState = Corrupt;
		} else if(currentMenu == minusMenu) {
			menuState = Minus;
		} else {
			menuState = Normal;
		}
	}

	public static function getStoryMenuData(set:String) {
		var menuData = getWeekInfo(set);

		var songList:Array<Array<String>> = [];
		var unlocked:Array<Bool> = [];
		var charNames:Array<String> = [];
		var weekNames:Array<String> = [];
		var menuSongs:Array<String> = [];
		var introSongs:Array<String> = [];
		var nameColors:Array<FlxColor> = [];
		var bgColors:Array<FlxColor> = [];
		var logos:Array<String> = [];
		var symbols:Array<String> = [];
		var scoreNames:Array<String> = [];

		var order = menuData.order;
		var data = menuData.data;

		for(weekName in order) {
			if(data.exists(weekName)) {
				var week = data.get(weekName);
				songList.push(week.songs);
				unlocked.push(Unlocks.isWeekUnlocked(weekName));
				charNames.push(week.char);
				weekNames.push(week.name);
				menuSongs.push(week.menuSong);
				introSongs.push(week.introSong);
				nameColors.push(FlxColor.fromString(week.nameColor));
				bgColors.push(FlxColor.fromString(week.bgColor));
				logos.push(week.logo);
				symbols.push(week.bgSymbol);
				scoreNames.push(weekName);
			}
		}

		var menu = new StoryMenuData(
			songList,
			unlocked,
			charNames,
			weekNames,
			menuSongs,
			introSongs,
			nameColors,
			bgColors,
			logos,
			symbols,
			scoreNames
		);

		return menu;
	}

	public static function getWeekInfo(set:String):WeekInfo {
		var rawJson:String = null;
		var path:String = Paths.getPreloadPath('data/' + set + 'weeks.json');

		#if MODS_ALLOWED
		var modPath:String = Paths.modFolders('data/' + set + 'weeks.json');
		if(OpenFlAssets.exists(modPath)) {
			rawJson = File.getContent(modPath);
		} else if(OpenFlAssets.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if(Assets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end
		else
		{
			return null;
		}

		var week:WeekInfo = cast Json.parse(rawJson);
		return week;
	}

	function updateMenuSprites() {
		aboveSpriteGroup.exists = true;
		if(menuState == Minus) {
			minusBfWorkaround();

			// And change the text/visibility for menu stuff
			aboveNav.text.text = "Regular Story";
			aboveNav.sticker.exists = false;
			updateText();

			FlxTween.tween(camera, {y: 0}, 1, {ease: FlxEase.cubeOut, onComplete: function(flx:FlxTween) { stopspamming = false; }});
		} else if(menuState == Normal) {
			normalBfWorkaround();

			// And change the text/visibility for menu stuff
			//aboveNav.text.text = "???";
			belowNav.text.text = "Infernal Paradise";
			belowNav.sticker.exists = false;
			//aboveNav.sticker.exists = true;
			updateText();
			aboveSpriteGroup.exists = false;

			FlxTween.tween(camera, {y: 0}, 1, {ease: FlxEase.cubeOut, onComplete: function(flx:FlxTween) { stopspamming = false; }});
		} else if(menuState == Corrupt) {
			corruptBfWorkaround();

			// And change the text/visibility for menu stuff
			belowNav.text.text = "Regular Story";
			belowNav.sticker.exists = false;
			updateText();

			FlxTween.tween(camera, {y: 0}, 1, {ease: FlxEase.cubeOut, onComplete: function(flx:FlxTween) { stopspamming = false; }});
		}

		goop.alpha = curWeek == 0 && menuState == Normal ? 1 : 0;
		bg.color = currentMenu.bgColors[curWeek];
	}

	function updateMusicSwitch(oldMenu:StoryMenuData) {
		if (TitleState.introMusic != null && TitleState.introMusic.playing)
		{
			// Play the week's associated intro
			var songTime = TitleState.introMusic.time;
			MainMenuState.songName = currentMenu.introThemes[curWeek];
			TitleState.introMusic.loadEmbedded(Paths.music(currentMenu.introThemes[curWeek]));
			TitleState.introMusic.play(false, songTime);
			TitleState.introMusic.onComplete = null;
			TitleState.introMusic.onComplete = function()
			{
				MainMenuState.songName = currentMenu.weekThemes[curWeek];
				FlxG.sound.music.volume = TitleState.introMusic.volume; // Shit workaround I guess
				FlxG.sound.music.loadEmbedded(Paths.music(currentMenu.weekThemes[curWeek]));
				FlxG.sound.music.volume = TitleState.introMusic.volume; // Shit workaround I guess
				FlxG.sound.music.play(true);
				TitleState.introMusic.destroy();
				TitleState.introMusic = null;
			}
			TitleState.introMusic.volume = 0.75;
		}
		else
		{
			// Play the week's associated theme
			Paths.dumpExclusions.remove('assets/music/${MainMenuState.songName}.ogg');
			MainMenuState.songName = currentMenu.weekThemes[curWeek];
			Paths.dumpExclusions.push('assets/music/${MainMenuState.songName}.ogg');
			currentMenu.weekSongs.members[curWeek].volume = 0;
			currentMenu.weekSongs.members[curWeek].play(false, oldMenu.weekSongs.members[curWeek].time % currentMenu.weekSongs.members[curWeek].length);
			currentMenu.weekSongs.members[curWeek].volume = 0;
			currentMenu.weekSongs.members[curWeek].fadeIn(0.25, 0, 0.75);
			oldMenu.weekSongs.members[curWeek].fadeOut(0.25, 0);
		}
	}

	var finishedMovingMenus = true;

	var corruptUpsLeft = 7;

	// Arcy
	// Direction parameter: Moves up if false, moves down if true
	function changeMenu(dir:Bool)
	{
		if(menuState == Normal && curWeek == 0 && !dir) { // Go to corruptro
			FlxG.sound.play(Paths.sound('Menu_FX1'));
			if(!Unlocks.unlockedWeeks.contains("corrupt") && corruptUpsLeft > 0) {
				corruptUpsLeft--;
				if(corruptUpsLeft > 0) {
					FlxG.camera.shake(0.01, 0.06);
					return;
				}
				Unlocks.unlock(WEEK, 'corrupt');
				//Unlocks.setNew(WEEK, 'corrupt');
				corruptMenu.weekUnlocked[0] = true;
			}
		}

		if (dir && currentMenu.nextMenu != null && currentMenu.nextMenu.weekSongNames.length > curWeek)
		{
			stopspamming = true;
			finishedMovingMenus = false;

			FlxTween.tween(camera, {y: -2000}, 1, {ease: FlxEase.cubeIn, onComplete: function(flx:FlxTween)
			{
				camera.y = 2000;

				currentMenu = currentMenu.nextMenu;
				updateMenuVisiblity();
				finishedMovingMenus = true;

				updateMusicSwitch(currentMenu.prevMenu);

				updateMenuSprites();
			}});
		}
		else if (!dir && currentMenu.prevMenu != null && currentMenu.prevMenu.weekSongNames.length > curWeek)
		{
			stopspamming = true;
			finishedMovingMenus = false;

			FlxTween.tween(camera, {y: 2000}, 1, {ease: FlxEase.cubeIn, onComplete: function(flx:FlxTween)
			{
				camera.y = -2000;

				currentMenu = currentMenu.prevMenu;
				updateMenuVisiblity();
				finishedMovingMenus = true;

				updateMusicSwitch(currentMenu.nextMenu);

				updateMenuSprites();
			}});
		}
	}

	function normalBfWorkaround()
	{
		// (Arcy) This is a shitty workaround. Please fix this later and I'm sorry for being lazy af
		// Change boyfriend for Normal Menu
		bfCharacters.members[0] = new Character(FlxG.width + 200, 250, 'story/bf', true); // Hard-coding garbage
		bfCharacters.members[0].scale.set(0.5, 0.5);
		bfCharacters.members[0].x -= bfCharacters.members[0].width / 2;
		bfCharacters.members[0].shader = null;

		leftArrow.alpha = 1;
		rightArrow.alpha = 1;
		if (gfIcons != null)
			gfIcons.visible = true; // Also gf icons
		if (badge != null)
			badge.visible = true; // And badge
		if (badgeApoc != null)
			badgeApoc.visible = true; // And badgeApoc
		if (corruptroBadge != null)
			corruptroBadge.visible = true; // And corruptroBadge
		if (flamingCorruptroBadge != null)
			flamingCorruptroBadge.visible = true; // And flamingCorruptroBadge
	}

	function minusBfWorkaround()
	{
		// (Arcy) This is a shitty workaround. Please fix this later and I'm sorry for being lazy af
		// Change boyfriend for Minus Menu
		bfCharacters.members[0] = new Character(FlxG.width + 200, 250, "story/bf-minus", true); // Hard-coding garbage
		bfCharacters.members[0].scale.set(0.5, 0.5);
		bfCharacters.members[0].x -= bfCharacters.members[0].width / 2;
		bfCharacters.members[0].offset.set(45, 50);
		bfCharacters.members[0].shader = null;

		leftArrow.alpha = 0;
		rightArrow.alpha = 0;
		if (gfIcons != null)
			gfIcons.visible = false; // Also gf icons
		if (badge != null)
			badge.visible = false; // And badge
		if (badgeApoc != null)
			badgeApoc.visible = false; // And badgeApoc
		if (corruptroBadge != null)
			corruptroBadge.visible = false; // And corruptroBadge
		if (flamingCorruptroBadge != null)
			flamingCorruptroBadge.visible = false; // And flamingCorruptroBadge
	}

	function corruptBfWorkaround()
	{
		// (Arcy) This is a shitty workaround. Please fix this later and I'm sorry for being lazy af
		// Change boyfriend for Corrupt Menu
		bfCharacters.members[0] = new Character(FlxG.width + 200, 250, 'story/bf-corrupt', true); // Hard-coding garbage
		bfCharacters.members[0].scale.set(0.5, 0.5);
		bfCharacters.members[0].x -= bfCharacters.members[0].width / 2;
		bfCharacters.members[0].offset.set(50, 0);
		bfCharacters.members[0].shader = null;

		leftArrow.alpha = 0;
		rightArrow.alpha = 0;
		if (gfIcons != null)
			gfIcons.visible = false; // Also gf icons
		if (badge != null)
			badge.visible = false; // And badge
		if (badgeApoc != null)
			badgeApoc.visible = false; // And badgeApoc
		if (corruptroBadge != null)
			corruptroBadge.visible = false; // And corruptroBadge
		if (flamingCorruptroBadge != null)
			flamingCorruptroBadge.visible = false; // And flamingCorruptroBadge
	}

	function selectWeek()
	{
		if (currentMenu.weekUnlocked[curWeek] && !stopspamming)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));

			// grpWeekText.members[curWeek].startFlashing();
			// grpWeekCharacters.members[1].animation.play('bfConfirm');
			stopspamming = true;

			// (Arcy) Jank workaround to get Minus BF/GF as the only playable character/girlfriend
			if (currentMenu == minusMenu)
			{
				curBF = 0;
				curGf = 0;
			}
			if (currentMenu == corruptMenu)
			{
				curBF = 0;
				curGf = 0;
			}

			// Make the arrows fade away
			FlxTween.tween(leftArrow, {alpha: 0}, 0.5, {ease: FlxEase.cubeOut});
			FlxTween.tween(rightArrow, {alpha: 0}, 0.5, {ease: FlxEase.cubeOut});

			FlxTween.tween(goop, {y: -goop.height - 10}, 0.5, {ease: FlxEase.cubeOut});

			// Taking the lazy way out and making the navigation texts fade too
			if (aboveSpriteGroup.visible)
			{
				for (spr in aboveSpriteGroup)
				{
					FlxTween.tween(spr, {alpha: 0}, 0.15, {ease: FlxEase.cubeOut});
				}
			}
			if (belowSpriteGroup.visible)
			{
				for (spr in belowSpriteGroup)
				{
					FlxTween.tween(spr, {alpha: 0}, 0.15, {ease: FlxEase.cubeOut});
				}
			}

			var previousWeek:Int = curWeek - 1;
			if (previousWeek < 0)
			{
				previousWeek = currentMenu.grpWeekCharacters.length - 1;
			}
			var nextWeek:Int = curWeek + 1;
			if (nextWeek >= currentMenu.grpWeekCharacters.length)
			{
				nextWeek = 0;
			}

			if (currentMenu.grpWeekCharacters.length > 2)
			{
				// Move side characters off-screen
				FlxTween.tween(currentMenu.grpWeekCharacters.members[previousWeek], {x: -600 + currentMenu.grpWeekCharacters.members[previousWeek].posOffset.x}, 0.5, {ease: FlxEase.cubeOut});
				FlxTween.tween(currentMenu.grpWeekCharacters.members[nextWeek], {x: 1450 + currentMenu.grpWeekCharacters.members[nextWeek].posOffset.x}, 0.5, {
					ease: FlxEase.cubeOut,
					onComplete: function(flx:FlxTween)
					{
						// Move vs character to the left
						FlxTween.tween(currentMenu.grpWeekCharacters.members[curWeek], {x: 50 + currentMenu.grpWeekCharacters.members[curWeek].posOffset.x}, 0.5, {ease: FlxEase.cubeOut});

						// Move the black rect cover down off-screen, along with the elements on it
						FlxTween.tween(blackCover, {y: 660}, 0.75, {
							ease: FlxEase.cubeOut,
							onComplete: function(flx:FlxTween)
							{
								// Move text back up
								txtWeekTitle.color = FlxColor.WHITE;
								txtWeekTitle.text = "Select Mode";
								FlxTween.tween(txtWeekTitle, {y: 675}, 0.5, {ease: FlxEase.cubeOut});
								// txtWeekTitle.Translate(0, -70);

								// Move score text up
								FlxTween.tween(scoreText, {y: 675}, 0.5, {ease: FlxEase.cubeOut});
								FlxTween.tween(controlsConfirmText, {y: 665}, 0.5, {ease: FlxEase.cubeOut});
								FlxTween.tween(controlsBackText, {y: 685}, 0.5, {ease: FlxEase.cubeOut});

								// Re-position arrows
								leftArrow.x = sprDifficulty.x - sprDifficulty.width + 70;
								leftArrow.y = sprMode.y - 10;
								rightArrow.x = sprDifficulty.x + sprDifficulty.width - 40;
								rightArrow.y = sprMode.y - 10;
								leftArrow.alpha = 1;
								rightArrow.alpha = 1;

								// Move the difficulty over on-screen
								FlxTween.tween(sprMode, {x: 725}, 0.5, {ease: FlxEase.cubeOut});
								FlxTween.tween(leftArrow, {x: 545}, 0.5, {ease: FlxEase.cubeOut});
								FlxTween.tween(rightArrow, {x: 1100}, 0.5, {ease: FlxEase.cubeOut});
								FlxTween.tween(sprDifficulty, {x: 850}, 0.75, {ease: FlxEase.cubeOut});
								FlxTween.tween(bfCharacters.members[curBF], {x: 725}, 1, {
									ease: FlxEase.cubeOut,
									onComplete: function(flx:FlxTween)
									{
										// Good enough
										stopspamming = false;
									}
								});
								if (gfIcons != null)
								{
									FlxTween.tween(gfIcons.members[curGf], {x: 860}, 1.25, {ease: FlxEase.cubeOut});
								}
							}
						});
						FlxTween.tween(currentMenu.grpWeekTitles.members[curWeek], {y: 790}, 0.75, {ease: FlxEase.cubeOut});
						FlxTween.tween(currentMenu.grpWeekText.members[curWeek], {y: 890}, 0.75, {ease: FlxEase.cubeOut});
						if (badge != null) {
							FlxTween.tween(badge, {y: 1320}, 0.75, {ease: FlxEase.cubeOut});
						}
						if (badgeApoc != null) {
							FlxTween.tween(badgeApoc, {y: 1320}, 0.75, {ease: FlxEase.cubeOut});
						}
						if (flamingCorruptroBadge != null) {
							FlxTween.tween(flamingCorruptroBadge, {y: 1320}, 0.75, {ease: FlxEase.cubeOut});
						}
						if (corruptroBadge != null) {
							FlxTween.tween(corruptroBadge, {y: 1320}, 0.75, {ease: FlxEase.cubeOut});
						}
					}
				});
			}
			else
			{
				// Move vs character to the left
				FlxTween.tween(currentMenu.grpWeekCharacters.members[curWeek], {x: 50 + currentMenu.grpWeekCharacters.members[curWeek].posOffset.x}, 0.5, {ease: FlxEase.cubeOut});

				// Move the black rect cover down off-screen, along with the elements on it
				FlxTween.tween(blackCover, {y: 660}, 0.75, {
					ease: FlxEase.cubeOut,
					onComplete: function(flx:FlxTween)
					{
						// Move text back up
						txtWeekTitle.color = FlxColor.WHITE;
						txtWeekTitle.text = "Select Mode";
						FlxTween.tween(txtWeekTitle, {y: 675}, 0.5, {ease: FlxEase.cubeOut});
						// txtWeekTitle.Translate(0, -70);

						// Move score text up
						FlxTween.tween(scoreText, {y: 675}, 0.5, {ease: FlxEase.cubeOut});
						FlxTween.tween(controlsConfirmText, {y: 665}, 0.5, {ease: FlxEase.cubeOut});
						FlxTween.tween(controlsBackText, {y: 685}, 0.5, {ease: FlxEase.cubeOut});

						// Re-position arrows
						leftArrow.x = sprDifficulty.x - sprDifficulty.width + 70;
						leftArrow.y = sprMode.y - 10;
						rightArrow.x = sprDifficulty.x + sprDifficulty.width - 40;
						rightArrow.y = sprMode.y - 10;
						leftArrow.alpha = 1;
						rightArrow.alpha = 1;

						// Move the difficulty over on-screen
						FlxTween.tween(sprMode, {x: 725}, 0.5, {ease: FlxEase.cubeOut});
						FlxTween.tween(leftArrow, {x: 545}, 0.5, {ease: FlxEase.cubeOut});
						FlxTween.tween(rightArrow, {x: 1100}, 0.5, {ease: FlxEase.cubeOut});
						FlxTween.tween(sprDifficulty, {x: 850}, 0.75, {ease: FlxEase.cubeOut});
						FlxTween.tween(bfCharacters.members[curBF], {x: 725}, 1, {
							ease: FlxEase.cubeOut,
							onComplete: function(flx:FlxTween)
							{
								// Good enough
								stopspamming = false;
							}
						});
						if (gfIcons != null)
						{
							FlxTween.tween(gfIcons.members[curGf], {x: 860}, 1.25, {ease: FlxEase.cubeOut});
						}
					}
				});
				FlxTween.tween(currentMenu.grpWeekTitles.members[curWeek], {y: 790}, 0.75, {ease: FlxEase.cubeOut});
				FlxTween.tween(currentMenu.grpWeekText.members[curWeek], {y: 890}, 0.75, {ease: FlxEase.cubeOut});
				if (badge != null) {
					FlxTween.tween(badge, {y: 1320}, 0.75, {ease: FlxEase.cubeOut});
				}
				if (badgeApoc != null) {
					FlxTween.tween(badgeApoc, {y: 1320}, 0.75, {ease: FlxEase.cubeOut});
				}
				if (flamingCorruptroBadge != null) {
					FlxTween.tween(flamingCorruptroBadge, {y: 1320}, 0.75, {ease: FlxEase.cubeOut});
				}
				if (corruptroBadge != null) {
					FlxTween.tween(corruptroBadge, {y: 1320}, 0.75, {ease: FlxEase.cubeOut});
				}
			}

			selectedWeek = true;
		}
	}

	function selectMode()
	{
		if (selectedWeek && !stopspamming)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));

			stopspamming = true;
			txtWeekTitle.text = "Select Difficulty";
			txtWeekTitle.screenCenter(X);

			// Move arrows down to next section
			FlxTween.tween(leftArrow, {x: 600, y: 215}, 0.15, {ease: FlxEase.cubeOut});
			FlxTween.tween(rightArrow, {x: 1025, y: 215}, 0.15, {
				ease: FlxEase.cubeOut,
				onComplete: function(flx:FlxTween)
				{
					stopspamming = false;
				}
			});

			selectedMode = true;
		}
	}

	function selectDifficulty()
	{
		if (selectedMode && !stopspamming)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));

			stopspamming = true;
			txtWeekTitle.text = "Select Character";
			txtWeekTitle.screenCenter(X);

			// Move arrows down to next section
			FlxTween.tween(leftArrow, {x: 660, y: 415}, 0.15, {ease: FlxEase.cubeOut});
			FlxTween.tween(rightArrow, {x: 965, y: 415}, 0.15, {
				ease: FlxEase.cubeOut,
				onComplete: function(flx:FlxTween)
				{
					stopspamming = false;
				}
			});

			selectedDifficulty = true;
		}
	}

	function selectCharacter()
	{
		if (selectedDifficulty && !stopspamming)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));

			stopspamming = true;
			txtWeekTitle.text = "Select Girlfriend";
			txtWeekTitle.screenCenter(X);

			// Move arrows down to next section
			FlxTween.tween(leftArrow, {x: 690, y: 575}, 0.15, {ease: FlxEase.cubeOut});
			FlxTween.tween(rightArrow, {x: 940, y: 575}, 0.15, {
				ease: FlxEase.cubeOut,
				onComplete: function(flx:FlxTween)
				{
					stopspamming = false;
				}
			});

			selectedCharacter = true;
		}
	}

	function selectSettings()
	{
		//if (saveManager.unlockData.bfs[curBF].unlocked && saveManager.unlockData.modes[curMode].unlocked && !stopspamming)
		if (Unlocks.isBFUnlockedIdx(curBF) && Unlocks.isModeUnlockedIdx(curMode) && !stopspamming)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));

			// Make the arrows fade away
			FlxTween.tween(leftArrow, {alpha: 0}, 0.5, {ease: FlxEase.cubeOut});
			FlxTween.tween(rightArrow, {alpha: 0}, 0.5, {ease: FlxEase.cubeOut});

			// Down and up
			FlxTween.tween(txtWeekTitle, {y: 750}, 0.25, {
				ease: FlxEase.cubeOut,
				onComplete: function(flx:FlxTween)
				{
					txtWeekTitle.text = "Ready to Battle?";
					txtWeekTitle.screenCenter(X);
					FlxTween.tween(txtWeekTitle, {y: 675}, 0.25, {
						ease: FlxEase.cubeOut,
						onComplete: function(flx:FlxTween)
						{
							stopspamming = false;
						}
					});
				}
			});

			selectedSettings = true;
		}
	}

	var confirmedWeek = false;

	function confirmWeek()
	{
		if(confirmedWeek)
			return;

		// (Arcy) Can't play with locked settings
		//if (!saveManager.unlockData.bfs[curBF].unlocked || !saveManager.unlockData.modes[curMode].unlocked)
		if (!Unlocks.isBFUnlockedIdx(curBF) || !Unlocks.isModeUnlockedIdx(curMode))
			return;

		var diffic = Difficulty.getDifficultyFilePath(curDifficulty);
		if(diffic == null) diffic = '';

		// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
		var songArray:Array<String> = [];
		var missingSongs:Array<String> = [];
		var leWeek = currentMenu.weekSongNames[curWeek];
		for (i in 0...leWeek.length) {
			var song = leWeek[i];
			var chart = Song.getChartPath(song + diffic, song);
			if(Paths.doesFileExist(chart, TEXT)) {
				songArray.push(song);
			} else {
				chart = CoolUtil.trimTextStart(chart, "assets/data/");
				missingSongs.push(chart);
			}
		}

		if(songArray.length == 0) {
			showMessage("The following charts are missing\n\n" + missingSongs.join("\n"), 1, 1);
			return;
		}

		Unlocks.newWeeks.remove(currentMenu.scoreNames[curWeek]);

		FlxG.sound.play(Paths.sound('confirmMenu'));
		stopspamming = true;

		// (Arcy) Get rid of new notifications
		/*if (currentMenu == normalMenu)
		{
			if (SaveDataManager.instance.newContent.normalWeeks[curWeek])
			{
				SaveDataManager.instance.newContent.setNormalWeekFlag(false, curWeek);
			}
		}
		else if (currentMenu == minusMenu)
		{
			if (SaveDataManager.instance.newContent.minusWeeks[curWeek])
			{
				SaveDataManager.instance.newContent.setMinusWeekFlag(false, curWeek);
			}
		}*/

		var extendWait:Float = 0;

		if(missingSongs.length != 0) {
			extendWait = 2;
			showMessage("Skipping the following charts since they are missing\n\n" + missingSongs.join("\n"), 2, 2);
		}

		PlayState.storyPlaylist = songArray;
		PlayState.firstTry = true;
		PlayState.isStoryMode = true;
		PlayState.weekScoreName = currentMenu.scoreNames[curWeek];

		PlayState.randomMode = false;
		if(Unlocks.allModes[curMode] == "randomized") {
			PlayState.randomMode = true;
		}

		PlayState.instadeathMode = false;
		if (Unlocks.allModes[curMode] == "insta-death")
			PlayState.instadeathMode = true;

		//PlayState.storyMode = curMode;
		//PlayState.bfCharacter = saveManager.unlockData.bfs[curBF].name;
		//PlayState.gfCharacter = saveManager.unlockData.getGfNameByUnlockedIndex(curGf);
		//PlayState.foeCharacter = '';

		Unlocks.bfName = '';
		Unlocks.gfName = '';
		Unlocks.foeName = '';
		Unlocks.bfName = Unlocks.allBfs[curBF];
		if (Unlocks.unlockedGfs.length > 1)// && songs[curSelected].songGfs.length > 1)
			Unlocks.gfName = Unlocks.unlockedGfs[curGf];


		if (Unlocks.bfName == 'bf')
			Unlocks.bfName == 'bf-wrath';

		if (Unlocks.gfName == 'gf')
			Unlocks.gfName == 'gf-wrath';

		//band-aidy fix for minus
		if (menuState == Minus)
		{
			Unlocks.bfName = 'bf-minus';
			Unlocks.gfName = 'gf-minus';
		}

		if (menuState == Corrupt)
		{
			Unlocks.bfName = 'bf-corrupt';
		}

		trace(Unlocks.bfName);
		trace(Unlocks.gfName);
		trace(Unlocks.foeName);

		// Show bf being ready
		if(bfCharacters.members[curBF].animation.getByName("hey") != null) {
			bfCharacters.members[curBF].animation.play("hey");
		}

		confirmedWeek = true;

		if(menuState == Corrupt) {
			MusicBeatState.songLoadingScreen = "story/corruptro";
		}
		if(menuState == Minus) {
			MusicBeatState.songLoadingScreen = "story/minus";
		}
		if(menuState == Normal && curWeek == 0) {
			MusicBeatState.songLoadingScreen = "story/wrath";
		}

		PlayState.storyDifficulty = curDifficulty;

		PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + diffic, PlayState.storyPlaylist[0]);
		//PlayState.SONG2 = Song.loadFromJson(PlayState.storyPlaylist[0] + diffic + '-2', PlayState.storyPlaylist[0]);
		PlayState.storyWeek = curWeek;
		PlayState.campaignScore = 0;
		PlayState.campaignMisses = 0;
		new FlxTimer().start(1 + extendWait, function(tmr:FlxTimer)
		{
			if (TitleState.introMusic != null && TitleState.introMusic.playing)
				TitleState.introMusic.stop();
			for (i in getUnusedSongs())
				Paths.localTrackedAssets.remove(i);
			if(FlxG.sound.music != null) {
				FlxG.sound.music.stop();
				FlxG.sound.music.persist = false;
				FlxG.sound.music.destroy();
				FlxG.sound.music = null;
			}
			LoadingState.loadAndSwitchState(new PlayState(), true);
			FreeplayState.destroyFreeplayVocals();
		});
	}

	private function getUnusedSongs():Array<String>
	{
		var songList:Array<String> = Paths.localTrackedAssets;

		return songList.filter(function(x:String) {return (x.startsWith('assets/music/Menu_') && !x.endsWith(MainMenuState.songName.replace('Intro', 'Menu')));});
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	public var instantTween:Bool = false;

	public function tween(Object:Dynamic, Values:Dynamic, Duration:Float = 1, ?Options:TweenOptions)
	{
		if(instantTween) {
			var fieldPaths:Array<String>;
			if (Reflect.isObject(Values))
				fieldPaths = Reflect.fields(Values);
			else
				throw "Unsupported properties container - use an object containing key/value pairs.";

			for (fieldPath in fieldPaths)
			{
				var target = Object;
				var path = fieldPath.split(".");
				var field = path.pop();
				for (component in path)
				{
					target = Reflect.getProperty(target, component);
					if (!Reflect.isObject(target))
						throw 'The object does not have the property "$component" in "$fieldPath"';
				}

				Reflect.setProperty(target, field, Reflect.getProperty(Values, fieldPath));
			}
			return null;
		}
		return FlxTween.tween(Object, Values, Duration, Options);
	}

	public static inline function byZ(Order:Int, Obj1:StoryMenuCharacter, Obj2:StoryMenuCharacter):Int
	{
		return FlxSort.byValues(Order, Obj1.z, Obj2.z);
	}

	function changeWeek(change:Int = 0, playSound:Bool = true):Void
	{
		// Check if changing the week is even possible
		if (currentMenu.grpWeekCharacters.length < 2)
			return;

		// Again, don't break things
		if(change != 0) {
			stopspamming = true;
		}

		// Make text (actually an image) invisible
		currentMenu.grpWeekTitles.members[curWeek].visible = false;
		currentMenu.grpWeekText.members[curWeek].visible = false;

		// Make current character a silhouette
		if(change != 0) {
			FlxTween.color(currentMenu.grpWeekCharacters.members[curWeek], 1, currentMenu.grpWeekCharacters.members[curWeek].color, FlxColor.BLACK, {ease: FlxEase.cubeOut});
		} else {
			currentMenu.grpWeekCharacters.members[curWeek].color = FlxColor.BLACK;
		}

		// I wanna throw up
		if (currentMenu.grpWeekBGs.members[curWeek].length > 0)
		{
			for (i in 0...currentMenu.grpWeekBGs.members[curWeek].length)
			{
				if(change != 0) {
					FlxTween.tween(currentMenu.grpWeekBGs.members[curWeek].members[i], {alpha: 0}, 0.25);
				} else {
					currentMenu.grpWeekBGs.members[curWeek].members[i].alpha = 0;
				}
			}
		}

		var oldWeek:Int = curWeek;

		curWeek += change;

		if (curWeek >= currentMenu.grpWeekCharacters.length)
		{
			curWeek = 0;
		}
		if (curWeek < 0)
		{
			curWeek = currentMenu.grpWeekCharacters.length - 1;
		}
		updateBadges();

		if(change != 0) {
			FlxTween.tween(goop, {alpha: curWeek == 0 && menuState == Normal ? 1 : 0}, 0.3);
		} else {
			goop.alpha = curWeek == 0 && menuState == Normal ? 1 : 0;
		}

		// And now make new character visible
		if(change != 0) {
			FlxTween.color(currentMenu.grpWeekCharacters.members[curWeek], 1, currentMenu.grpWeekCharacters.members[curWeek].color, FlxColor.WHITE, {ease: FlxEase.cubeOut});
		} else {
			currentMenu.grpWeekCharacters.members[curWeek].color = FlxColor.WHITE;
		}

		// Make scrolling bg visible
		if (currentMenu.grpWeekBGs.members[curWeek].length > 0)
		{
			for (i in 0...currentMenu.grpWeekBGs.members[curWeek].length)
			{
				if(change != 0) {
					FlxTween.tween(currentMenu.grpWeekBGs.members[curWeek].members[i], {alpha: 1}, 0.25);
				} else {
					currentMenu.grpWeekBGs.members[curWeek].members[i].alpha = 1;
				}
			}
		}

		// Change background color
		if(change != 0) {
			FlxTween.color(bg, 1, bg.color, currentMenu.bgColors[curWeek], {ease: FlxEase.cubeOut});
		} else {
			bg.color = currentMenu.bgColors[curWeek];
		}

		if(playSound) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		instantTween = change == 0;

		for(char in currentMenu.grpWeekCharacters.members) {
			if(char != null) {
				char.visible = false;
				char.z = 0;
			}
		}

		// Move characters
		if (change > 0) // Left
		{
			var weekCharacters = currentMenu.grpWeekCharacters;

			var previous2Weeks:Int = curWeek - 2;
			if (previous2Weeks < 0)
			{
				previous2Weeks = weekCharacters.length + previous2Weeks;
			}
			var previousWeek:Int = curWeek - 1;
			if (previousWeek < 0)
			{
				previousWeek = weekCharacters.length - 1;
			}
			var nextWeek:Int = curWeek + 1;
			if (nextWeek >= weekCharacters.length)
			{
				nextWeek = 0;
			}

			tween(weekCharacters.members[previous2Weeks], {
				x: -600 + weekCharacters.members[previous2Weeks].posOffset.x
			}, 0.5, {ease: FlxEase.cubeOut});
			tween(weekCharacters.members[previousWeek], {
				x: -25 + weekCharacters.members[previousWeek].posOffset.x,
				y: -25 + weekCharacters.members[previousWeek].posOffset.y,
				'scale.x': weekCharacters.members[previousWeek].unfocusScale,
				'scale.y': weekCharacters.members[previousWeek].unfocusScale
			}, 0.5, {ease: FlxEase.cubeOut});
			tween(weekCharacters.members[curWeek], {
				x: 425 + weekCharacters.members[curWeek].posOffset.x,
				y: -20 + weekCharacters.members[curWeek].posOffset.y,
				'scale.x': weekCharacters.members[curWeek].focusScale,
				'scale.y': weekCharacters.members[curWeek].focusScale
			}, 0.5, {
				ease: FlxEase.cubeOut,
				onComplete: function(flx:FlxTween)
				{
					stopspamming = false;
				}
			});
			weekCharacters.members[nextWeek].x = 1450 + weekCharacters.members[nextWeek].posOffset.x;
			tween(weekCharacters.members[nextWeek], {
				x: 825 + weekCharacters.members[nextWeek].posOffset.x
			}, 0.5, {ease: FlxEase.cubeOut});

			weekCharacters.members[previous2Weeks].visible = true;
			weekCharacters.members[previousWeek].visible = true;
			weekCharacters.members[curWeek].visible = true;
			weekCharacters.members[nextWeek].visible = true;
		}
		else if (change < 0)// Right
		{
			var weekCharacters = currentMenu.grpWeekCharacters;

			var previousWeek:Int = curWeek - 1;
			if (previousWeek < 0)
			{
				previousWeek = weekCharacters.length - 1;
			}
			var nextWeek:Int = curWeek + 1;
			if (nextWeek >= weekCharacters.length)
			{
				nextWeek = 0;
			}
			var next2Weeks:Int = curWeek + 2;
			if (next2Weeks >= weekCharacters.length)
			{
				next2Weeks = next2Weeks - weekCharacters.length;
			}

			weekCharacters.members[previousWeek].x = -600 + weekCharacters.members[previousWeek].posOffset.x;
			tween(weekCharacters.members[previousWeek], {
				x: -25 + weekCharacters.members[previousWeek].posOffset.x
			}, 0.5, {ease: FlxEase.cubeOut});
			tween(weekCharacters.members[curWeek], {
				x: 425 + weekCharacters.members[curWeek].posOffset.x,
				y: -20 + weekCharacters.members[curWeek].posOffset.y,
				'scale.x': weekCharacters.members[curWeek].focusScale,
				'scale.y': weekCharacters.members[curWeek].focusScale
			}, 0.5, {
				ease: FlxEase.cubeOut,
				onComplete: function(flx:FlxTween)
				{
					stopspamming = false;
				}
			});
			tween(weekCharacters.members[nextWeek], {
				x: 825 + weekCharacters.members[nextWeek].posOffset.x,
				y: -25 + weekCharacters.members[nextWeek].posOffset.y,
				'scale.x': weekCharacters.members[nextWeek].unfocusScale,
				'scale.y': weekCharacters.members[nextWeek].unfocusScale
			}, 0.5, {ease: FlxEase.cubeOut});
			tween(weekCharacters.members[next2Weeks], {
				x: 1450 + weekCharacters.members[next2Weeks].posOffset.x
			}, 0.5, {ease: FlxEase.cubeOut});

			weekCharacters.members[previousWeek].visible = true;
			weekCharacters.members[curWeek].visible = true;
			weekCharacters.members[nextWeek].visible = true;
			weekCharacters.members[next2Weeks].visible = true;
		}
		else //Zero
		{
			var weekCharacters = currentMenu.grpWeekCharacters;

			var previousWeek:Int = curWeek - 1;
			if (previousWeek < 0)
			{
				previousWeek = weekCharacters.length - 1;
			}
			var nextWeek:Int = curWeek + 1;
			if (nextWeek >= weekCharacters.length)
			{
				nextWeek = 0;
			}

			var nextScale = weekCharacters.members[nextWeek].unfocusScale;
			var prevScale = weekCharacters.members[previousWeek].unfocusScale;
			var curScale = weekCharacters.members[curWeek].focusScale;

			weekCharacters.members[nextWeek].scale.set(nextScale, nextScale);
			weekCharacters.members[curWeek].scale.set(curScale, curScale);
			weekCharacters.members[previousWeek].scale.set(prevScale,prevScale);

			weekCharacters.members[nextWeek].color = FlxColor.BLACK;
			weekCharacters.members[curWeek].color = FlxColor.WHITE;
			weekCharacters.members[previousWeek].color = FlxColor.BLACK;

			//reposition shit
			var prevOffset:FlxPoint = weekCharacters.members[previousWeek].posOffset;
			var curOffset:FlxPoint = weekCharacters.members[curWeek].posOffset;
			var nextOffset:FlxPoint = weekCharacters.members[nextWeek].posOffset;

			weekCharacters.members[previousWeek].setPosition(-25+prevOffset.x, -25+prevOffset.y);
			weekCharacters.members[curWeek].setPosition(425+curOffset.x, -20+curOffset.y);
			weekCharacters.members[nextWeek].setPosition(825+nextOffset.x,-25+nextOffset.y);

			weekCharacters.members[previousWeek].visible = true;
			weekCharacters.members[curWeek].visible = true;
			weekCharacters.members[nextWeek].visible = true;
		}

		currentMenu.grpWeekCharacters.members[curWeek].z = 1;
		currentMenu.grpVisibleWeekCharacters.sort(byZ, FlxSort.ASCENDING);

		// Fix for static curWeek
		for(char in currentMenu.grpWeekCharacters.members) {
			if(char != null && !char.visible) {
				char.scale.set(char.unfocusScale, char.unfocusScale);
				char.color = FlxColor.BLACK;
			}
		}

		instantTween = false;

		//CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		Difficulty.difficulties = [
			'Easy',
			'Normal',
			'Hard',
			'Hell'
		];
		/*var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5
		//difficultySelectors.visible = unlocked;

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}

		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}*/

		if(oldWeek != curWeek) {
			updateTheme(oldWeek);
		}
		updateText();
	}

	function updateBadges()
	{
		// Hard coded badge stuff
		if(menuState == Normal) {
			if (badge != null) {
				badge.visible = curWeek == 0;
			}

			if (badgeApoc != null) {
				badgeApoc.visible = curWeek == 0;
			}

			if (flamingCorruptroBadge != null) {
				flamingCorruptroBadge.visible = curWeek == 0;
			}

			if (corruptroBadge != null) {
				corruptroBadge.visible = curWeek == 0;
			}
		}
	}

	function changeMode(change:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));

		curMode += change;

		var modes = Unlocks.allModes;

		if (curMode < 0)
		{
			curMode = modes.length - 1;
		}
		if (curMode >= modes.length)
		{
			curMode = 0;
		}

		switch (modes[curMode])//saveManager.unlockData.modes[curMode].name)
		{
			case 'standard':
				sprMode.animation.play('standard');
				sprMode.offset.x = 0;
				sprMode.offset.y = 0;
				sprMode.scale.x = 1;
			//case 'No Fail':
			//	sprMode.offset.x = -50;
			//	sprMode.scale.x = 1;
			//	/*if (!saveManager.unlockData.checkModeUnlocked('No Fail'))
			//	{
			//		sprMode.animation.play('nofaillock');
			//		sprMode.offset.y = 40;
			//	}
			//	else
			//	{*/
			//		sprMode.animation.play('nofail');
			//		sprMode.offset.y = 0;
			//	//}
			//case 'Freestyle':
			//	sprMode.offset.x = 17.5;
			//	sprMode.scale.x = 0.9;
			//	/*if (!saveManager.unlockData.checkModeUnlocked('Freestyle'))
			//	{
			//		sprMode.animation.play('freestylelock');
			//		sprMode.offset.y = 45;
			//	}
			//	else
			//	{*/
			//		sprMode.animation.play('freestyle');
			//		sprMode.offset.y = 0;
			//	//}
			case 'randomized':
				sprMode.offset.x = 30;
				sprMode.scale.x = 0.8;
				if (!Unlocks.isModeUnlocked('randomized'))
				{
					sprMode.animation.play('randomizedlock');
					sprMode.offset.y = 45;
				}
				else
				{
					sprMode.animation.play('randomized');
					sprMode.offset.y = 0;
				}
			case 'insta-death':
				sprMode.offset.x = 33;
				sprMode.scale.x = 0.8;
				if (!Unlocks.isModeUnlocked('insta-death'))
				{
					sprMode.animation.play('insta-deathlock');
					sprMode.offset.y = 45;
				}
				else
				{
					sprMode.animation.play('insta-death');
					sprMode.offset.y = 0;
				}
		}
	}

	function changeDifficulty(change:Int = 0, playSound:Bool = true):Void
	{
		if(playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		curDifficulty += change;

		if (curDifficulty < 1)
			curDifficulty = Difficulty.difficulties.length-1;
		if (curDifficulty >= Difficulty.difficulties.length)
			curDifficulty = 1;

		sprDifficulty.offset.x = 0;

		switch (Difficulty.difficulties[curDifficulty].toLowerCase())
		{
			case 'easy':
				sprDifficulty.animation.play('easy');
				sprDifficulty.offset.x = 20;
			case 'normal':
				sprDifficulty.animation.play('normal');
				sprDifficulty.offset.x = 70;
			case 'hard':
				sprDifficulty.animation.play('hard');
				sprDifficulty.offset.x = 20;
			case 'hell':
				sprDifficulty.animation.play('hell');
				sprDifficulty.offset.x = 20;
		}

		// (tsg - 6/7/21) TODO: see if its possible to get bf anim from here, and allow the shiver anim to play when hell is selected.
		// trace(bfCharacter.animation.curAnim);

		sprDifficulty.alpha = 0;

		// USING THESE WEIRD VALUES SO THAT IT DOESNT FLOAT UP

		#if !switch
		intendedScore = Highscore.getWeekScore(currentMenu.scoreNames[curWeek], curDifficulty);
		#end

		FlxTween.tween(sprDifficulty, {alpha: 1}, 0.07);
	}

	function changeCharacter(change:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));

		bfCharacters.members[curBF].visible = false;
		var oldPos = bfCharacters.members[curBF].x;

		curBF += change;

		// Wrapping selection
		if (curBF < 0)
		{
			curBF = bfCharacters.members.length - 1;
		}
		if (curBF >= bfCharacters.members.length)
		{
			curBF = 0;
		}

		// Third time's a charm?
		bfCharacters.members[curBF].x = oldPos;
		bfCharacters.members[curBF].visible = true;

		// Show silhouette if locked
		if (Unlocks.isBFUnlocked(Unlocks.allBfs[curBF]))
		{
			bfCharacters.members[curBF].color = FlxColor.WHITE;
		}
		else
		{
			bfCharacters.members[curBF].color = FlxColor.BLACK;
		}
	}

	function changeGirlfriend(change:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));

		gfIcons.members[curGf].visible = false;
		var oldPos = gfIcons.members[curGf].x;

		curGf += change;

		// Wrapping selection
		if (curGf < 0)
		{
			curGf = gfIcons.length - 1;
		}
		if (curGf >= gfIcons.length)
		{
			curGf = 0;
		}

		// Third time's a charm?
		gfIcons.members[curGf].x = oldPos;
		gfIcons.members[curGf].visible = true;
	}

	function updateTheme(lastWeek:Int)
	{
		if (TitleState.introMusic != null && TitleState.introMusic.playing)
		{
			// Play the week's associated intro
			var songTime = TitleState.introMusic.time;
			MainMenuState.songName = currentMenu.introThemes[curWeek];
			TitleState.introMusic.loadEmbedded(Paths.music(currentMenu.introThemes[curWeek]));
			TitleState.introMusic.play(false, songTime);
			TitleState.introMusic.onComplete = null;
			TitleState.introMusic.onComplete = function()
			{
				MainMenuState.songName = currentMenu.weekThemes[curWeek];
				FlxG.sound.music.loadEmbedded(Paths.music(currentMenu.weekThemes[curWeek]));
				FlxG.sound.music.volume = TitleState.introMusic.volume; // Shit workaround I guess
				FlxG.sound.music.play(true);
				TitleState.introMusic.destroy();
				TitleState.introMusic = null;
			}
			TitleState.introMusic.volume = 0.75;
		}
		else
		{
			// Play the week's associated theme
			MainMenuState.songName = currentMenu.weekThemes[curWeek];
			currentMenu.weekSongs.members[curWeek].play(false, currentMenu.weekSongs.members[lastWeek].time % currentMenu.weekSongs.members[curWeek].length);
			currentMenu.weekSongs.members[curWeek].fadeIn(0.25, 0, 0.75);
			currentMenu.weekSongs.members[lastWeek].fadeOut(0.25, 0);
		}
	}

	function updateText()
	{
		currentMenu.grpWeekTitles.members[curWeek].visible = true;
		currentMenu.grpWeekText.members[curWeek].visible = true;

		// (Arcy) Show that it's possible to go between menus if that story is unlocked.
		if (currentMenu.nextMenu != null && currentMenu.nextMenu.weekUnlocked[curWeek])
		{
			belowSpriteGroup.visible = true;

			// And check if it's new
			//if (currentMenu.nextMenu == normalMenu)
			//{
			//	belowNav.sticker.visible = SaveDataManager.instance.newContent.normalWeeks[curWeek];
			//}
			//else
			//{
			//	belowNav.sticker.visible = SaveDataManager.instance.newContent.minusWeeks[curWeek];
			//}
		}
		else
		{
			belowSpriteGroup.visible = false;
		}

		if (currentMenu.prevMenu != null && currentMenu.prevMenu.weekUnlocked[curWeek])
		{
			aboveSpriteGroup.visible = true;

			// And check if it's new
			//if (currentMenu.prevMenu == normalMenu)
			//{
			//	aboveNav.sticker.visible = SaveDataManager.instance.newContent.normalWeeks[curWeek];
			//}
		}
		else
		{
			aboveSpriteGroup.visible = false;
		}

		aboveNav.text.screenCenter(X);
		belowNav.text.screenCenter(X);

		#if !switch
		intendedScore = Highscore.getWeekScore(currentMenu.scoreNames[curWeek], curDifficulty);
		#end
	}

	/**
	 * Function used to move everything back to the main state of the story menu.
	 */
	function cancelStorySettings()
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));
		selectedWeek = false;
		selectedMode = false;
		selectedDifficulty = false;

		// Don't break shit >:(
		stopspamming = true;

		var previousWeek:Int = curWeek - 1;
		if (previousWeek < 0)
		{
			previousWeek = currentMenu.grpWeekCharacters.length - 1;
		}
		var nextWeek:Int = curWeek + 1;
		if (nextWeek >= currentMenu.grpWeekCharacters.length)
		{
			nextWeek = 0;
		}

		// Move description text off
		FlxTween.tween(txtWeekTitle, {y: 750}, 0.5, {
			ease: FlxEase.cubeOut,
			onComplete: function(flx:FlxTween)
			{
				// Move the black rect cover back up, along with the elements on it
				FlxTween.tween(currentMenu.grpWeekCharacters.members[curWeek], {x: 425 + currentMenu.grpWeekCharacters.members[curWeek].posOffset.x}, 0.5, {ease: FlxEase.cubeOut});
				FlxTween.tween(blackCover, {y: 400}, 0.75, {
					ease: FlxEase.cubeOut,
					onComplete: function(flx:FlxTween)
					{
						if (currentMenu.grpWeekCharacters.length > 2)
						{
							// Move vs character back and other characters on-screen
							FlxTween.tween(currentMenu.grpWeekCharacters.members[previousWeek], {x: -25 + currentMenu.grpWeekCharacters.members[previousWeek].posOffset.x}, 0.5, {ease: FlxEase.cubeOut});
							FlxTween.tween(currentMenu.grpWeekCharacters.members[nextWeek], {x: 825 + currentMenu.grpWeekCharacters.members[nextWeek].posOffset.x}, 0.5, {ease: FlxEase.cubeOut});
						}

						// And bring the arrows back
						leftArrow.alpha = 0;
						rightArrow.alpha = 0;
						leftArrow.x = 300;
						leftArrow.y = 200;
						rightArrow.x = 825;
						rightArrow.y = 200;

						// Taking the lazy way out and making the navigation texts fade too
						if (aboveSpriteGroup.visible)
						{
							for (spr in aboveSpriteGroup)
							{
								FlxTween.tween(spr, {alpha: 1}, 0.15, {ease: FlxEase.cubeOut});
							}
						}
						if (belowSpriteGroup.visible)
						{
							for (spr in belowSpriteGroup)
							{
								FlxTween.tween(spr, {alpha: 1}, 0.15, {ease: FlxEase.cubeOut});
							}
						}

						// Temporary
						// Don't do this for Minus menu
						if (currentMenu.grpWeekCharacters.length > 1)
						{
							FlxTween.tween(leftArrow, {alpha: 1}, 0.5, {ease: FlxEase.cubeOut});
							FlxTween.tween(rightArrow, {alpha: 1}, 0.5, {
								ease: FlxEase.cubeOut,
								onComplete: function(flx:FlxTween)
								{
									stopspamming = false;
								}
							});
						}
						else
						{
							stopspamming = false;
						}
					}
				});
				FlxTween.tween(currentMenu.grpWeekTitles.members[curWeek], {y: 400}, 0.75, {ease: FlxEase.cubeOut});
				FlxTween.tween(currentMenu.grpWeekText.members[curWeek], {y: 215}, 0.75, {ease: FlxEase.cubeOut});
				if (badge != null) {
					FlxTween.tween(badge, {y: badge.originalY}, 0.75, {ease: FlxEase.cubeOut});
				}
				if (badgeApoc != null) {
					FlxTween.tween(badgeApoc, {y: badgeApoc.originalY}, 0.75, {ease: FlxEase.cubeOut});
				}
				if (corruptroBadge != null) {
					FlxTween.tween(corruptroBadge, {y: corruptroBadge.originalY}, 0.75, {ease: FlxEase.cubeOut});
				}
				if (flamingCorruptroBadge != null) {
					FlxTween.tween(flamingCorruptroBadge, {y: flamingCorruptroBadge.originalY}, 0.75, {ease: FlxEase.cubeOut});
				}
			}
		});

		// Move score text off
		FlxTween.tween(scoreText, {y: 750}, 0.5, {ease: FlxEase.cubeOut});
		FlxTween.tween(controlsConfirmText, {y: 740}, 0.5, {ease: FlxEase.cubeOut});
		FlxTween.tween(controlsBackText, {y: 760}, 0.5, {ease: FlxEase.cubeOut});

		// Move the difficulty and bf back off-screen
		if (gfIcons != null)
		{
			FlxTween.tween(gfIcons.members[curGf], {x: 1585}, 0.5, {ease: FlxEase.cubeOut});
		}
		FlxTween.tween(bfCharacters.members[curBF], {x: 1450}, 0.5, {ease: FlxEase.cubeOut});
		FlxTween.tween(sprDifficulty, {x: 1575}, 0.5, {ease: FlxEase.cubeOut});
		FlxTween.tween(sprMode, {x: 1450}, 0.5, {ease: FlxEase.cubeOut});
		FlxTween.tween(leftArrow, {x: 1325}, 0.5, {ease: FlxEase.cubeOut});
		FlxTween.tween(rightArrow, {x: 1850}, 0.5, {ease: FlxEase.cubeOut});

		FlxTween.tween(goop, {y: 0}, 0.5, {ease: FlxEase.cubeOut});
	}

	/**
	 * Deciphers the last pressed keys to see if a secret code was typed out.
	 */
	function checkCodeInput()
	{
		//if (FlxG.keys.justPressed.ANY && (!saveManager.unlockData.freeplaySongs[saveManager.unlockData.getSongIndex('Fuzzy Feeling')].unlocked
		//	 || !saveManager.unlockData.freeplaySongs[saveManager.unlockData.getSongIndex('Heartmelter')].unlocked))
		if (FlxG.keys.justPressed.ANY && (!Unlocks.hasUnlockedSong('Fuzzy Feeling') || !Unlocks.hasUnlockedSong('Heartmelter') || !Unlocks.unlockedWeeks.contains("corrupt")))
		{
			var lastInputs = charInputs;

			if (FlxG.keys.justPressed.A) charInputs += 'A';
			else if (FlxG.keys.justPressed.B) charInputs += 'B';
			else if (FlxG.keys.justPressed.C) charInputs += 'C';
			else if (FlxG.keys.justPressed.D) charInputs += 'D';
			else if (FlxG.keys.justPressed.E) charInputs += 'E';
			else if (FlxG.keys.justPressed.F) charInputs += 'F';
			else if (FlxG.keys.justPressed.G) charInputs += 'G';
			else if (FlxG.keys.justPressed.H) charInputs += 'H';
			else if (FlxG.keys.justPressed.I) charInputs += 'I';
			else if (FlxG.keys.justPressed.J) charInputs += 'J';
			else if (FlxG.keys.justPressed.K) charInputs += 'K';
			else if (FlxG.keys.justPressed.L) charInputs += 'L';
			else if (FlxG.keys.justPressed.M) charInputs += 'M';
			else if (FlxG.keys.justPressed.N) charInputs += 'N';
			else if (FlxG.keys.justPressed.O) charInputs += 'O';
			else if (FlxG.keys.justPressed.P) charInputs += 'P';
			else if (FlxG.keys.justPressed.Q) charInputs += 'Q';
			else if (FlxG.keys.justPressed.R) charInputs += 'R';
			else if (FlxG.keys.justPressed.S) charInputs += 'S';
			else if (FlxG.keys.justPressed.T) charInputs += 'T';
			else if (FlxG.keys.justPressed.U) charInputs += 'U';
			else if (FlxG.keys.justPressed.V) charInputs += 'V';
			else if (FlxG.keys.justPressed.W) charInputs += 'W';
			else if (FlxG.keys.justPressed.X) charInputs += 'X';
			else if (FlxG.keys.justPressed.Y) charInputs += 'Y';
			else if (FlxG.keys.justPressed.Z) charInputs += 'Z';
			else if (FlxG.keys.justPressed.ZERO) charInputs += '0';
			else if (FlxG.keys.justPressed.ONE) charInputs += '1';
			else if (FlxG.keys.justPressed.TWO) charInputs += '2';
			else if (FlxG.keys.justPressed.THREE) charInputs += '3';
			else if (FlxG.keys.justPressed.FOUR) charInputs += '4';
			else if (FlxG.keys.justPressed.FIVE) charInputs += '5';
			else if (FlxG.keys.justPressed.SIX) charInputs += '6';
			else if (FlxG.keys.justPressed.SEVEN) charInputs += '7';
			else if (FlxG.keys.justPressed.EIGHT) charInputs += '8';
			else if (FlxG.keys.justPressed.NINE) charInputs += '9';

			FlxG.watch.addQuick("charInputs", charInputs);

			// (Tech) Hacky way to check if current week is Saku while also handling old cheats
			if (cheatCode1.startsWith(charInputs) || cheatCode2.startsWith(charInputs) || cheatCode3.startsWith(charInputs) || cheatCode4.startsWith(charInputs))
			{
				if(cheatCode3.startsWith(charInputs) || cheatCode4.startsWith(charInputs) && curWeek == 1) {
					sakuStart = true;
				}
				//if(isInputtingCorruptro && lastInputs != charInputs)
				//	FlxG.camera.shake(0.01, 0.06);
				if (cheatCodeUnlock(charInputs, sakuStart))
					charInputs = '';
			}
			else
			{
				if (charInputs.length >= 5)
					FlxG.sound.play(Paths.sound('RON', 'shared'));

				charInputs = '';
			}
		}
	}

	/**
	 * (Arcy)
	 * Used to check for cheat codes that unlock stuff.
	 * @param code		The string to check for matching cheat codes.
	 * @param sakuStart	Checks if the code was started while on Saku's week
	 * @return			Returns `true` if a successful cheat code was found. Otherwise returns `false`. Used for handling things in other classes.
	 **/
	public function cheatCodeUnlock(code:String, sakuStart:Bool):Bool
	{
		switch (code)
		{
			case 'MOMMYMOTHYMILKIES':
				uniqueUnlockText = "You've unlocked the secret song in Freeplay. Good job cheater!";

				FlxTween.tween(unlockFadeBG, {alpha: 0.9}, 0.5);

				Unlocks.unlock(SONG, 'Fuzzy Feeling');
				Unlocks.setNew(SONG, 'Fuzzy Feeling');
				//saveDataManager.newContent.setFreeplayFlag(true, saveDataManager.unlockData.getSongIndex('Fuzzy Feeling'));

				displayUnlocks();
				return true;
			case 'DRYOCAMPARUBICUNDATHEROSYMAPLEMOTHISASMALLNORTHAMERICANMOTHINTHEFAMILYSATURNIIDAEALSOKNOWNASTHEGREATSILKMOTHSITWASFIRSTDESCRIBEDBYJOHANCHRISTIANFABRICIUSIN1793THESPECIESISKNOWNFORITSWOOLYBODYANDPINKANDYELLOWCOLORATIONWHICHVARIESFROMCREAMORWHITETOBRIGHTPINKORYELLOWMALESHAVEBUSHIERANTENNAETHANFEMALESWHICHALLOWTHEMTOSENSEFEMALEPHEROMONESFORMATING':
				uniqueUnlockText = "You could've just typed \'mommymothymilkies\' instead.";

				FlxTween.tween(unlockFadeBG, {alpha: 0.9}, 0.5);

				Unlocks.unlock(SONG, 'Fuzzy Feeling');
				Unlocks.setNew(SONG, 'Fuzzy Feeling');
				//saveDataManager.newContent.setFreeplayFlag(true, saveDataManager.unlockData.getSongIndex('Fuzzy Feeling'));

				displayUnlocks();
				return true;
			// (Tech) This is shell code, fill it in when heartmelter is implemented.
			case 'MAGNIFICENTMAJESTICMARKETABLEMARVELOUSMEGAMOMMYMOTHYMILKIES':
				if (sakuStart) {
					uniqueUnlockText = "You could've just typed \'Heartmelter\' instead.";

					FlxTween.tween(unlockFadeBG, {alpha: 0.9}, 0.5);

					Unlocks.unlock(SONG, 'Heartmelter');
					Unlocks.setNew(SONG, 'Heartmelter');
					//saveDataManager.unlockData.unlockSong('Heartmelter');
					//saveDataManager.newContent.setFreeplayFlag(true, saveDataManager.unlockData.getSongIndex('Heartmelter'));

					displayUnlocks();
					return true;
				}
				else
					return false;

			case 'HEARTMELTER':
				if (sakuStart) {
					uniqueUnlockText = "You've unlocked another secret song in Freeplay.";

					FlxTween.tween(unlockFadeBG, {alpha: 0.9}, 0.5);

					Unlocks.unlock(SONG, 'Heartmelter');
					Unlocks.setNew(SONG, 'Heartmelter');
					//saveDataManager.unlockData.unlockSong('Heartmelter');
					//saveDataManager.newContent.setFreeplayFlag(true, saveDataManager.unlockData.getSongIndex('Heartmelter'));

					displayUnlocks();
					return true;
				}
				else
					return false;
		}

		return false;
	}
}

typedef WeekInfo = {
	var order:Array<String>;
	var data:haxe.DynamicAccess<WeekInfoWeek>;
}

typedef WeekInfoWeek = {
	var songs:Array<String>;
	var char:String;
	var name:String;
	var menuSong:String;
	var introSong:String;
	var nameColor:String;
	var bgColor:String;
	var logo:String;
	var bgSymbol:String;
}
