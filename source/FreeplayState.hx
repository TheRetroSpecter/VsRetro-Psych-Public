package;

import Song.SwagSong;
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
//import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import WeekData;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class FreeplayState extends UnlockableMusicBeatState
{
	var songs:Array<SongMetadata> = [];

	private static var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';
	public static var curBF:Int = 0;
	public static var curGf:Int = 0;
	public static var curFoe:Int = 0;

	public static var defaultWrathLoadingScreens:Array<String> = [
		"wrath/random1",
		"wrath/random2",
		"wrath/random3",
		"wrath/satisfracture",
		"wrath/ectospasm",
		"wrath/spectral",
		"wrath/retro",
	];
	
	public static var defaultMinusLoadingScreens:Array<String> = [
		"minus/random1",
		"minus/overtime",
		"minus/sigma",
		"minus/acidiron",
		"minus/preppy",
	];
	public static var bfName = 'bf';
	public static var gfName = 'gf';
	public static var foeName = '';

	var scoreBG:FlxSpriteExtra;
	var scoreText:FlxFixedText;
	var diffText:FlxFixedText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var charText:FlxFixedText;
	var charIcon:HealthIcon;
	var gfText:FlxFixedText;
	var gfIcon:HealthIcon;
	var foeText:FlxFixedText;
	var foeIcon:HealthIcon;
	var unlockText:FlxFixedText;
	var defaultBgHeight:Int = 66;

	public static var songData:Map<String, Array<SwagSong>> = [];
	public var songColors:Map<String, FlxColor> = [];
	public var songLoadingScreens:Map<String, Array<String>> = [];

	override function create()
	{
		canQuickSettings = true;

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		if(Unlocks.newMenuItem.contains("freeplay")) {
			Unlocks.newMenuItem.remove("freeplay");
			Unlocks.saveUnlocks();
		}

		PlayState.randomMode = false;
		PlayState.instadeathMode = false;

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		songData = [];

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			/*var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}*/

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];

				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}

				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]), song);
			}

			for (_data in leWeek.songColors)
			{
				var data = _data.split(":");
				var song = Paths.formatToSongPath(data[0]);
				var color:FlxColor = data.length > 1 ? FlxColor.fromString(data[1]) : 0xffffff;
				color.alpha = 255;

				songColors[song] = color;
			}

			for (_data in leWeek.loadingScreens)
			{
				var data = _data.split(":");
				var song = Paths.formatToSongPath(data[0]);
				var screens:Array<String> = [];
				if(data.length > 1 && data[1].toLowerCase() != 'minus-random' && data[1].toLowerCase() != 'wrath-random') {
					screens = data[1].split(";");
				}
				else if(data[1].toLowerCase() == 'minus-random')
					screens = defaultMinusLoadingScreens;
				else if(data[1].toLowerCase() == 'wrath-random')
					screens = defaultWrathLoadingScreens;

				songLoadingScreens[song] = screens;
			}
		}
		setSpecialColors();
		WeekData.loadTheFirstEnabledMod();

		/*		//KIND OF BROKEN NOW AND ALSO PRETTY USELESS//

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
		for (i in 0...initSonglist.length)
		{
			if(initSonglist[i] != null && initSonglist[i].length > 0) {
				var songArray:Array<String> = initSonglist[i].split(":");
				addSong(songArray[0], 0, songArray[1], Std.parseInt(songArray[2]));
			}
		}*/

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.setGraphicSize(Std.int(bg.width * 0.6));
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet;
			if (songs[i].songName == 'Fuzzy Feeling' && !Unlocks.hasUnlockedSong('Fuzzy Feeling'))
				songText = new Alphabet(0, (70 * i) + 30, 'Secret', true, false);
			else if (songs[i].songName == 'Corruptro' && !Unlocks.hasUnlockedSong('Corruptro'))
				songText = new Alphabet(0, (70 * i) + 30, '???', true, false);
			else
				songText = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			songs[i].textSprite = songText;
			grpSongs.add(songText);

			if (songText.width > 980)
			{
				var textScale:Float = 980 / songText.width;
				songText.scale.x = textScale;
				for (letter in songText.lettersArray)
				{
					letter.x *= textScale;
					letter.offset.x *= textScale;
				}
				//songText.updateHitbox();
				//trace(songs[i].songName + ' new scale: ' + textScale);
			}

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);

			if(songs[i].newSticker) {
				var newSticker:AttachedSprite = new AttachedSprite(/*songText.width, 70 * i*/);
				if(songs[i].newStickerVariant) {
					newSticker.frames = Paths.getSparrowAtlas('new_text_songvariant');
				} else {
					newSticker.frames = Paths.getSparrowAtlas('new_text');
				}
				newSticker.animation.addByPrefix('Animate', 'NEW', 24);
				newSticker.animation.play('Animate');
				newSticker.antialiasing = ClientPrefs.globalAntialiasing;
				newSticker.sprTracker = songText;
				//newSticker.sprTrackerOffset = new FlxPoint(-150, -100);
				newSticker.xAdd = -150;
				newSticker.yAdd = -100;
				newSticker.scale.set(0.5, 0.5);
				add(newSticker);
			}
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxFixedText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSpriteExtra(scoreText.x - 6, 0).makeSolid(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxFixedText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		unlockText = new FlxFixedText(diffText.x + 175, diffText.y, 0, "", 20);
		unlockText.font = scoreText.font;
		add(unlockText);

		// https://twitter.com/Saberspark/status/1423115380529278980?s=20
		// I'm so fucking tired man

		var xtraCharBind = ClientPrefs.keyBinds['change_bf'][1];
		var xtraGfBind = ClientPrefs.keyBinds['change_gf'][1];
		var xtraFoeBind = ClientPrefs.keyBinds['change_foe'][1];

		var	xtraCharText = '';
		var xtraGfText = '';
		var xtraFoeText =  '';

		if (xtraCharBind != NONE)
			xtraCharText = ' or ${InputFormatter.getKeyName(xtraCharBind)}';
		if (xtraGfBind != NONE)
			xtraGfText = ' or ${InputFormatter.getKeyName(xtraGfBind)}';
		if (xtraFoeBind != NONE)
			xtraFoeText = ' or ${InputFormatter.getKeyName(xtraFoeBind)}';

		charText = new FlxFixedText(diffText.x - 30, diffText.y + 65, 0, '${ClientPrefs.getKeyBind('change_bf', 0)}$xtraCharText to Select BF', 24);
		charText.font = diffText.font;
		charText.visible = false;
		add(charText);

		charIcon = new HealthIcon('bf', true);
		charIcon.animation.play('bf');
		charIcon.setPosition(charText.x - 110, diffText.y + 10);
		charIcon.scale.set(0.5, 0.5);
		charIcon.visible = false;
		add(charIcon);

		gfText = new FlxFixedText(diffText.x - 30, diffText.y + 65, 0, '${ClientPrefs.getKeyBind('change_gf', 0)}$xtraGfText to Select GF', 24);
		gfText.font = diffText.font;
		gfText.visible = false;
		add(gfText);

		gfIcon = new HealthIcon('gf', true);
		gfIcon.animation.play('gf');
		gfIcon.setPosition(gfText.x - 110, diffText.y + 10);
		gfIcon.scale.set(0.5, 0.5);
		gfIcon.visible = false;
		add(gfIcon);

		foeText = new FlxFixedText(diffText.x - 30, diffText.y + 65, 0, '${ClientPrefs.getKeyBind('change_foe', 0)}$xtraFoeText to Select FOE', 24);
		foeText.font = diffText.font;
		foeText.visible = false;
		add(foeText);

		foeIcon = new HealthIcon('retro');
		foeIcon.animation.play('retro');
		foeIcon.setPosition(foeText.x - 110, diffText.y + 10);
		foeIcon.scale.set(0.5, 0.5);
		foeIcon.visible = false;
		add(foeIcon);

		add(scoreText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if(lastDifficultyName == '')
		{
			lastDifficultyName = Difficulty.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultDifficulties.indexOf(lastDifficultyName)));

		changeSelection();
		changeDiff();

		var textBG = new FlxSpriteExtra(0, FlxG.height - 26).makeSolid(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
	  #if android
		var leText:String = "Press X to listen to the Song / Press C to open the Gameplay Changers Menu / Press Y to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#end
		#else
		var leText:String = "Press C to open the Gameplay Changers Menu / Press Y to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxFixedText = new FlxFixedText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

                #if android
                addVirtualPad(FULL, A_B_C_X_Y_Z);
                #end

		super.create();
	}

	function addChartsToMeta(meta:SongMetadata, ?customName:String = null):Bool
	{
		var variant:Bool = false;
		var format:String = meta.songName;
		if(customName != null && customName.length > 0) {
			format = customName;
			variant = true;
		}
		var formatPath:String = Paths.formatToSongPath(format);

		if(meta.unlocked) {
			meta.newSticker = meta.newSticker || Unlocks.newSongs.contains(formatPath);
			if(variant)
				meta.newStickerVariant = meta.newStickerVariant || Unlocks.newSongs.contains(formatPath);
		}

		var diffsThatExist:Array<String> = [];
		for (difficulty in Difficulty.defaultDifficulties)
		{
			var diffPath:String = '-${difficulty.toLowerCase().replace(' ', '-')}';
			if(diffPath == '-normal') diffPath = ''; //Normal difficulty uses no suffix

			#if sys
			if (FileSystem.exists('assets/data/${formatPath}/${formatPath + diffPath}.json'))
			#else
			if (Assets.exists('assets/data/${formatPath}/${formatPath + diffPath}.json', TEXT))
			#end
			{
				diffsThatExist.push(difficulty);
			}
		}

		if (diffsThatExist.length == 0)
		{
			//Application.current.window.alert("No difficulties found for chart, skipping.", format + " Chart");
			return false;
		}

		var loadedDiffs:Array<SwagSong> = [];
		for (difficulty in diffsThatExist)
		{
			FreeplayState.loadDiff(Difficulty.defaultDifficulties.indexOf(difficulty), formatPath, format, loadedDiffs);
		}

		meta.diffs = diffsThatExist;
		FreeplayState.songData.set(format, loadedDiffs);
		return true;
	}

	public static function loadDiff(diff:Int, format:String, name:String, array:Array<SwagSong>)
	{
		try
		{
			array[diff] = Song.loadFromJson(Highscore.formatSong(format, diff), name.toLowerCase());
		}
		catch(ex)
		{
			// do nada
		}
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int, song:Array<Dynamic>)
	{
		var format = Paths.formatToSongPath(songName);
		var meta = new SongMetadata(songName, weekNum, songCharacter, color);

		meta.newSticker = Unlocks.newSongs.contains(format);

		if(Unlocks.hasUnlockedSong(format)) {
			// Do nothing
		} else if(Unlocks.visibleSongs.contains(format)) {
			meta.color = 0xFF888888;
			meta.songCharacter = "lock";
			meta.unlocked = false;
			meta.newSticker = false;
		} else {
			return; // Hide the song
		}

		addChartsToMeta(meta);

		if(song.length > 3) {
			var metaSongs:Array<String> = song[3];
			for(s in metaSongs) {
				addChartsToMeta(meta, s);
			}
		}

		var defaultBfList = ['bf', 'bf-minus', 'bf-retro', 'bf-ace', 'bf-saku'];
		var defaultGfList = ['gf', 'gf-minus', 'gf-saku', 'gf-ace', 'gf-zerktro', 'gf-saku-goth'];

		var charList:Array<String> = CoolUtil.coolTextFileLegacy(Paths.txt(format + '/bfList'));
		if (charList != null)
		{
			meta.songBfs = [];
			for (bf in charList)
			{
				if(Unlocks.isBFUnlocked(bf))
					meta.songBfs.push(bf);
			}
		}
		else
			meta.songBfs = Unlocks.unlockedBfs;

		charList = CoolUtil.coolTextFileLegacy(Paths.txt(format + '/gfList'));
		if (charList != null)
		{
			meta.songGfs = [];
			for (gf in charList)
			{
				if(Unlocks.isGFUnlocked(gf))
					meta.songGfs.push(gf);
			}
		}
		else
			meta.songGfs = Unlocks.unlockedGfs;

		charList = CoolUtil.coolTextFileLegacy(Paths.txt(format + '/foeList'));
		if (charList != null)
		{
			meta.songFoes = [];
			for (foe in charList)
			{
				if(Unlocks.isFoeUnlocked(foe))
					meta.songFoes.push(foe);
			}
		}
		else
			meta.songFoes = [];

		songs.push(meta);
	}

	function weekIsLocked(name:String):Bool {
		return !(Unlocks.isWeekUnlocked(name));
		//var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		//return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	private static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
		{
			if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}

		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		if(unlocking) {
			super.update(elapsed);
			return;
		}

		#if debug
		if(FlxG.keys.justPressed.F5) {
			persistentUpdate = false;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new ClearCacheState(FreeplayState));
		}
		#end

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE #if android || _virtualpad.buttonX.justPressed #end;;
		var ctrl = FlxG.keys.justPressed.CONTROL #if android || _virtualpad.buttonC.justPressed #end;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT  #if android || _virtualpad.buttonZ.pressed #end) shiftMult = 3;

		if(songs.length > 1)
		{
			if (upP)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					changeDiff();
				}
			}
		}

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		else if (controls.UI_RIGHT_P)
			changeDiff(1);
		else if (upP || downP) changeDiff();

		if (controls.BACK)
		{
			persistentUpdate = false;
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
		else if (controls.CHANGE_BF && Unlocks.hasUnlockedSong(songs[curSelected].songName))
			changeChar();
		else if (controls.CHANGE_GF && Unlocks.hasUnlockedSong(songs[curSelected].songName))
			changeGf();
		else if (controls.CHANGE_FOE && Unlocks.hasUnlockedSong(songs[curSelected].songName))
			changeFoe();

		if(ctrl)
		{
		  #if android
			removeVirtualPad();
			#end
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(space)
		{
			if(instPlaying != curSelected)
			{
				playMusic();
			}
		}

		else if (accepted)
		{
			selectSong();
		}
		else if(controls.RESET #if android || _virtualpad.buttonY.justPressed #end)
		{
		 	#if android
			removeVirtualPad();
			#end
			var genericName = songs[curSelected].songName;

			if(!Unlocks.hasUnlockedSong(genericName)) {
				showMessage('Song isn\'t unlocked', 0);
				return;
			}

			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}


		super.update(elapsed);
	}

	function selectSong() {
		var genericName = songs[curSelected].songName;
		var song = getSpecial(curSelected); // songs[curSelected].songName
		var songLowercase:String = Paths.formatToSongPath(song);
		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

		if(!Unlocks.hasUnlockedSong(genericName)) {
			showMessage('Song isn\'t unlocked', 0);
			return;
		}

		if(!Song.doesChartExist(poop, songLowercase)) {
			var key = Song.getChartPath(poop, songLowercase);

			showMessage('Chart $key doesnt exist', 1);
			return;
		}

		Unlocks.bfName = '';
		Unlocks.gfName = '';
		Unlocks.foeName = '';
		if (songs[curSelected].songBfs != null)// && songs[curSelected].songBfs.length > 1)
			Unlocks.bfName = songs[curSelected].songBfs[curBF];
		if (songs[curSelected].songGfs != null)// && songs[curSelected].songGfs.length > 1)
			Unlocks.gfName = songs[curSelected].songGfs[curGf];
		if (songs[curSelected].songFoes != null)// && songs[curSelected].songFoes.length > 1)
			Unlocks.foeName = songs[curSelected].songFoes[curFoe];

		trace(Unlocks.bfName);
		trace(Unlocks.gfName);
		trace(Unlocks.foeName);

		persistentUpdate = false;
		trace(poop);

		PlayState.SONG = Song.loadFromJson(poop, songLowercase);
		PlayState.isStoryMode = false;
		PlayState.firstTry = true;
		PlayState.storyDifficulty = curDifficulty;
		FlxG.sound.music.volume = 0;
		FlxG.sound.music.persist = false;
		FlxG.sound.music.destroy();
		FlxG.sound.music = null;

		trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
		if(colorTween != null) {
			colorTween.cancel();
		}

		if(songLoadingScreens.exists(songLowercase)) {
			var screens = songLoadingScreens.get(songLowercase);
			if(screens.length == 0) {

			} else if(screens.length == 1) {
				MusicBeatState.songLoadingScreen = screens[0];
			} else {
				MusicBeatState.songLoadingScreen = FlxG.random.getObject(screens);
			}
		}
		//MusicBeatState.songLoadingScreen = "minus/"+songLowercase;

		if (FlxG.keys.pressed.SHIFT  || _virtualpad.buttonZ.pressed #end)) {
			LoadingState.loadAndSwitchState(new ChartingState());
		} else {
			LoadingState.loadAndSwitchState(new PlayState());
		}

		//FlxG.sound.music.volume = 0;

		if (TitleState.introMusic != null && TitleState.introMusic.playing)
			TitleState.introMusic.stop();

		destroyFreeplayVocals();
	}

	function playMusic() {
		#if PRELOAD_ALL
		destroyFreeplayVocals();
		FlxG.sound.music.volume = 0;
		Paths.currentModDirectory = songs[curSelected].folder;
		var genericName = songs[curSelected].songName;
		var song = getSpecial(curSelected); // songs[curSelected].songName
		var songName:String = Paths.formatToSongPath(song);
		var poop:String = Highscore.formatSong(songName, curDifficulty);

		if(!Unlocks.hasUnlockedSong(genericName)) {
			showMessage('Song isn\'t unlocked', 0);
			return;
		}

		if(!Song.doesChartExist(poop, songName)) {
			var key = Song.getChartPath(poop, songName);

			showMessage('Chart $key doesnt exist', 1);
			return;
		}
		PlayState.SONG = Song.loadFromJson(poop, songName);
		if (PlayState.SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
		vocals.play();
		vocals.persist = true;
		vocals.looped = true;
		vocals.volume = 0.7;
		instPlaying = curSelected;
		#end
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 1)
			curDifficulty = Difficulty.difficulties.length-1;
		if (curDifficulty >= Difficulty.difficulties.length)
			curDifficulty = 1;

		lastDifficultyName = Difficulty.difficulties[curDifficulty];

		updateScore();

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + Difficulty.difficultyString() + ' >';
		positionHighscore();
	}

	function updateScore() {
		#if !switch
		var songName = getSpecial(curSelected);

		intendedScore = Highscore.getScore(songName, curDifficulty);
		intendedRating = Highscore.getRating(songName, curDifficulty);
		#end
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		checkCharacters();

		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		// selector.y = (70 * curSelected) + 30;

		updateScore();

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}

		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		checkPossibleDifficulties();

		updateSongNames();
	}

	function checkPossibleDifficulties() {
		Difficulty.difficulties = Difficulty.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

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
				Difficulty.difficulties = diffs;
			}
		}

		if(Paths.formatToSongPath(songs[curSelected].songName) != "ectospasm") {
			Difficulty.remove(Difficulty.APOCALYPSE);
		}

		//Difficulty.remove(Difficulty.EASY);

		if(Difficulty.difficulties.contains(Difficulty.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(1, Difficulty.defaultDifficulties.indexOf(Difficulty.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 1;
		}

		var newPos:Int = Difficulty.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;

		//var l = charText.width;

		gfIcon.x = FlxG.width - scoreBG.scale.x -37;// - l *1.1;
		//trace(charText.x);
		charIcon.x = FlxG.width -scoreBG.scale.x-37;// -l*1.1;
		foeIcon.x = FlxG.width - scoreBG.scale.x-37;// - l*1.1;
		gfText.x = gfIcon.x + 110;
		charText.x = charIcon.x+110;
		foeText.x = foeIcon.x+110;
	}

	function getSpecial(songIdx:Int) {
		var songFormat = Paths.formatToSongPath(songs[songIdx].songName);

		switch(songFormat)
		{
			case 'ectospasm':
				if (bfName == 'bf-saku') //Ectogasm
					return 'Ectogasm';

			case 'satisfracture':
				if (bfName == 'bf-ace') //Satisfracture Remix
					return songs[songIdx].songName + ' Remix';
				else if (bfName == 'bf-saku') //Satisflatter
					return 'Satisflatter';

			case 'fuzzy-feeling':
				if (bfName == 'bf-retro' && gfName == 'gf-zerktro') //Scalie Feeling
					return 'Scalie Feeling';
				else if (bfName == 'bf-saku' && gfName.startsWith('gf-saku')) //Fuzziest Feeling
					return 'Fuzziest Feeling';
		}

		return songs[songIdx].songName;
	}

	function setSpecialColors() {
		//songColors.set('ectogasm', 0xfff79e9e);
		//songColors.set('satisflatter', 0xfff79e9e);
		//songColors.set('fuzziest-feeling',0xfff79e9e);
		//songColors.set('scalie-feeling', 0xff54e679);
		//songColors.set('satisfracture-remix', 0xffa09ef7);
	}

	function updateSongNames() {
		for(i in 0...songs.length) {
			if(songs[i].unlocked) {
				if(songs[i].textSprite != null) {
					var special = getSpecial(i);
					var songText = songs[i].textSprite;
					if(songText.changeTextIfDifferent(special)) {
						songText.x -= 400;
					}

					var color = 0xFFffffff;
					var formatted = Paths.formatToSongPath(special);
					if(songColors.exists(formatted)) {
						color = songColors[formatted];
					}
					songText.color = color;
				}
			}
		}
	}

	private function checkCharacters()
	{
		if (songs[curSelected].songBfs.length > 1 && Unlocks.hasUnlockedSong(songs[curSelected].songName))
		{
			charText.y = diffText.y + 65;

			if (!songs[curSelected].songBfs.contains(bfName))
				curBF = 0;
			else
				curBF = songs[curSelected].songBfs.indexOf(bfName);

			bfName = songs[curSelected].songBfs[curBF];

			charIcon.changeIcon(bfName);
			charIcon.y = diffText.y + 10;

			charText.visible = true;
			charIcon.visible = true;
		}
		else
		{
			charText.visible = false;
			charIcon.visible = false;
		}

		if (songs[curSelected].songGfs.length > 1 && Unlocks.hasUnlockedSong(songs[curSelected].songName))
		{
			gfText.y = diffText.y + 65;

			if (!songs[curSelected].songGfs.contains(gfName))
				curGf = 0;
			else
				curGf = songs[curSelected].songGfs.indexOf(gfName);

			gfName = songs[curSelected].songGfs[curGf];

			gfIcon.changeIcon(gfName);
			gfIcon.y = diffText.y + 10;

			gfText.visible = true;
			gfIcon.visible = true;

			if (charText.visible)
			{
				gfText.y += 70;
				gfIcon.y += 65;
			}
		}
		else
		{
			gfText.visible = false;
			gfIcon.visible = false;
		}

		if (songs[curSelected].songFoes != null && Unlocks.hasUnlockedSong(songs[curSelected].songName))
		{
			if (songs[curSelected].songFoes.length > 1)
			{
				foeText.y = diffText.y + 65;

				curFoe = 0;
				foeName = songs[curSelected].songFoes[curFoe];
				foeIcon.changeIcon(foeName);
				foeIcon.y = diffText.y + 10;

				foeText.visible = true;
				foeIcon.visible = true;

				if (charText.visible)
				{
					foeText.y += 70;
					foeIcon.y += 65;
				}
				if (gfText.visible)
				{
					foeText.y += 70;
					foeIcon.y += 65;
				}
			}
			else
			{
				foeName = '';
				foeText.visible = false;
				foeIcon.visible = false;
			}
		}
		else
		{
			foeName = '';
			foeText.visible = false;
			foeIcon.visible = false;
		}

		var bgHeight:Int = defaultBgHeight;

		var unlockCount:Int = 0;
		var typeUnlocks:Array<Bool> = [charText.visible, gfText.visible, foeText.visible];

		for (i in typeUnlocks)
			if (i) unlockCount++;

		// Override every check if nothing comes up
		if(!Unlocks.hasUnlockedSong(songs[curSelected].songName)) unlockCount = 0;

		switch (unlockCount)
		{
			default: bgHeight = defaultBgHeight;
			case 1: bgHeight += 90;
			case 2: bgHeight += 90 + 65;
			case 3: bgHeight += 90 + 65 + 65; 
		}
		/*
		if (charText.visible)
			bgHeight += 79;
		if (gfText.visible)
			bgHeight += 79;
		if (foeText.visible)
			bgHeight += 75;
		*/
		scoreBG.setGraphicSize(Std.int(scoreBG.width), bgHeight);
		scoreBG.updateHitbox();

		updateSongNames();
		updateScore();
	}

	private function changeChar() {
		var bfCount = songs[curSelected].songBfs.length;
		if (bfCount < 2) return;

		if (songs[curSelected].songBfs != null)
		{
			curBF++;
			//trace(curBF);
			if (curBF >= songs[curSelected].songBfs.length) curBF = 0;

			bfName = songs[curSelected].songBfs[curBF];
			charIcon.changeIcon(bfName);
		}

		trace('current bf: $bfName');

		updateSongNames();
		updateScore();
	}

	private function changeGf() {
		if (songs[curSelected].songGfs.length < 2) return;

		if (songs[curSelected].songGfs != null)
		{
			curGf++;
			//trace(curGf);
			if (curGf >= songs[curSelected].songGfs.length) curGf = 0;

			gfName = songs[curSelected].songGfs[curGf];
			gfIcon.changeIcon(gfName);
		}
		trace('current gf: $gfName');

		updateSongNames();
		updateScore();
	}

	private function changeFoe() {
		if (songs[curSelected].songFoes == null || songs[curSelected].songFoes.length < 2)
		{
			foeName = "";
			return;
		}
		else
		{
			curFoe++;

			if (curFoe >= songs[curSelected].songFoes.length) curFoe = 0;

			foeName = songs[curSelected].songFoes[curFoe];
			foeIcon.changeIcon(foeName);
		}
		trace('current foe: $foeName');

		updateSongNames();
		updateScore();
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";

	public var unlocked:Bool = true;
	public var newSticker:Bool = false;
	public var newStickerVariant:Bool = false;

	public var songBfs:Array<String>;
	public var songGfs:Array<String>;
	public var songFoes:Array<String>;

	public var diffs:Array<String> = [];

	public var textSprite:Alphabet;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}