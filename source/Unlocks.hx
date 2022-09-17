package;

import flixel.util.FlxSave;
import flixel.FlxG;

class Unlocks {
	// Changable Characters
	public static var bfName:String = "";
	public static var gfName:String = "";
	public static var foeName:String = "";

	// Full
	public static var allBfs:Array<String> = [
		"bf",
		"bf-minus",
		"bf-retro",
		"bf-ace",
		"bf-saku",
	];

	public static var allGfs:Array<String> = [
		"gf",
		"gf-minus",
		"gf-saku",
		"gf-ace",
		"gf-zerktro",
		"gf-saku-goth",
	];

	public static var allFoes:Array<String> = [
		"sakuroma",
		"sakuroma-alt"
	];

	public static var allModes:Array<String> = [
		"standard",
		"randomized",
		'insta-death'
	];

	public static var allWeeks:Array<String> = [
		"wrath",
		"lust",
		"pride",
		"gluttony",
		"greed",
		"envy",
		"sloth",
		"minus",
		"corrupt",
	];

	// Songs

	public static var allSongs:Array<String> = [
		"retro",
		"satisfracture",
		"spectral",
		"ectospasm",
		"fuzzy-feeling",
		"preseason",
		"sigma",
		"acidiron",
		"preppy",
		"overtime",
		"heartmelter",
		//"postgame",
		//"mompoms",
		"corruptro",
	];

	public static var unlockedSongs:Array<String> = [
		"retro",
	];

	public static var visibleSongs:Array<String> = [
		"fuzzy-feeling",
		"corruptro"
	];

	// Save data
	public static var unlockedWeeks:Array<String> = [
		"wrath",
		"minus",
	];

	public static var unlockedModes:Array<String> = [
		"standard",
	];

	public static var unlockedFoes:Array<String> = [
		"sakuroma",
		"sakuroma-alt"
	];

	public static var unlockedBfs:Array<String> = [
		"bf",
		//#if debug
		//"bf-retro",
		//"bf-ace",
		//"bf-minus",
		//"bf-saku",
		//#end
	];
	public static var unlockedGfs:Array<String> = [
		"gf",
		//#if debug
		//"gf-minus",
		//"gf-saku",
		//"gf-ace",
		//"gf-zerktro",
		//"gf-saku-goth",
		//#end
	];
	// Change this to be in the savedata later, this is just for testing currently

	private static var hasLoadedDefault:Bool = false;
	public static var isReset(get, never):Bool;

	private static function get_isReset() {
		var u = [];
		var d = [];
		u.push(unlockedSongs.join("|"));
		u.push(visibleSongs.join("|"));
		u.push(unlockedWeeks.join("|"));
		u.push(unlockedModes.join("|"));
		u.push(unlockedFoes.join("|"));
		u.push(unlockedBfs.join("|"));
		u.push(unlockedGfs.join("|"));

		d.push(defaultSongs.join("|"));
		d.push(defaultVSongs.join("|"));
		d.push(defaultWeeks.join("|"));
		d.push(defaultModes.join("|"));
		d.push(defaultFoes.join("|"));
		d.push(defaultBfs.join("|"));
		d.push(defaultGfs.join("|"));
		return u.join(";") == d.join(";");
	}

	public static var defaultSongs:Array<String> = [];
	public static var defaultVSongs:Array<String> = [];
	public static var defaultWeeks:Array<String> = [];
	public static var defaultModes:Array<String> = [];
	public static var defaultFoes:Array<String> = [];
	public static var defaultBfs:Array<String> = [];
	public static var defaultGfs:Array<String> = [];

	private static function defaultSetup() {
		if(hasLoadedDefault) {
			return;
		}

		defaultSongs = unlockedSongs.copy();
		defaultVSongs = visibleSongs.copy();
		defaultWeeks = unlockedWeeks.copy();
		defaultModes = unlockedModes.copy();
		defaultFoes = unlockedFoes.copy();
		defaultBfs = unlockedBfs.copy();
		defaultGfs = unlockedGfs.copy();

		hasLoadedDefault = true;
	}

	public static function resetProgress() {
		unlockedSongs = defaultSongs;
		visibleSongs = defaultVSongs;
		unlockedWeeks = defaultWeeks;
		unlockedModes = defaultModes;
		unlockedFoes = defaultFoes;
		unlockedBfs = defaultBfs;
		unlockedGfs = defaultGfs;
	}

	public static function saveUnlocks() {
		fixOrder();

		var save:FlxSave = new FlxSave();
		save.bind("vsretrospecterV2-unlocks", "FNF Vs Retrospecter Psych");

		save.data.bfs = unlockedBfs;
		save.data.gfs = unlockedGfs;
		save.data.foes = unlockedFoes;
		save.data.weeks = unlockedWeeks;
		save.data.songs = unlockedSongs;
		save.data.modes = unlockedModes;

		save.data.newSongs = newSongs;
		save.data.newWeeks = newWeeks;
		save.data.newMenuItem = newMenuItem;

		save.flush();
		save.close();
	}

	public static var init = false;
	public static var portedFromOld = false;
	public static var firstBoot = false;

	public static function loadUnlocks() {
		defaultSetup();

		var save:FlxSave = new FlxSave();
		save.bind("vsretrospecterV2-unlocks", "FNF Vs Retrospecter Psych");
		if(save != null) {
			if(!init) {
				#if debug
				FlxG.console.registerClass(Unlocks);
				#end
				init = true;
			}
			if (save.data.bfs != null) unlockedBfs = save.data.bfs;
			if (save.data.gfs != null) unlockedGfs = save.data.gfs;
			if (save.data.foes != null) unlockedFoes = save.data.foes;
			if (save.data.weeks != null) unlockedWeeks = save.data.weeks;
			if (save.data.songs != null) unlockedSongs = save.data.songs;
			if (save.data.modes != null) unlockedModes = save.data.modes;

			if (save.data.newSongs != null) newSongs = save.data.newSongs;
			if (save.data.newWeeks != null) newWeeks = save.data.newWeeks;
			if (save.data.newMenuItem != null) newMenuItem = save.data.newMenuItem;

			if(firstBoot) {
				setNew(MENU_ITEM, "options");
				setNew(MENU_ITEM, "freeplay");
				saveUnlocks();
			}
			if(portedFromOld) {
				setNew(MENU_ITEM, "options");
				setNew(MENU_ITEM, "credits");
				saveUnlocks();
			}
			progressCheck();
		}
		save.close();
	}

	// Unlock Utils

	public static var recentlyUnlockedChars:Array<String> = [];
	//public static var recentlyUnlockedBfs:Array<String> = [];
	//public static var recentlyUnlockedGfs:Array<String> = [];
	//public static var recentlyUnlockedFoes:Array<String> = [];
	public static var recentlyUnlockedWeeks:Array<String> = [];
	public static var recentlyUnlockedSongs:Array<String> = [];
	public static var recentlyUnlockedModes:Array<String> = [];

	public static function finishedStoryWeek(weekName:String) {
		if(weekName == "wrath") {
			//unlock(WEEK, "lust");
		}
		//if(weekName == "minus") {
		//	unlock(SONG, "Postgame");
		//}
		//saveUnlocks();
	}

	/** (Arcy)
	* Determines any content that should be unlocked after the specified song ends.
	* @param song   The name of the song to check for unlocked content.
	**/
	public static function finishedSong(song:String) {
		// (Arcy) Other special unlocks for completion of songs
		switch (song)
		{
			case 'satisfracture-remix':
				unlock(GF, 'gf-ace');
			case 'spectral':
				if (!hasUnlockedSong('ectospasm'))
				{
					//saveDataManager.newContent.setFreeplayFlag(true, saveDataManager.unlockData.getSongIndex('Ectospasm'));
					setNew(SONG, "Ectospasm");
					unlock(SONG, "Ectospasm");
				}

				if (!Unlocks.unlockedBfs.contains('bf-retro'))
				{
					//saveDataManager.newContent.setFreeplayFlag(true, saveDataManager.unlockData.getSongIndex('Fuzzy Feeling'));
					if(Unlocks.unlockedGfs.contains('gf-zerktro')) {
						setNew(SONG, "Scalie Feeling");
						saveUnlocks();
					}
					unlock(BF, 'bf-retro');
				}

				if (!Unlocks.unlockedBfs.contains('bf-ace'))
				{
					//saveDataManager.newContent.setFreeplayFlag(true, saveDataManager.unlockData.getSongIndex('Satisfracture'));
					setNew(SONG, "Satisfracture Remix");
					unlock(BF, 'bf-ace');
				}

				//if (PlayState.gfVersion == 'gf-saku' && !Unlocks.unlockedGfs.contains('gf-saku-goth'))
				//	unlock(GF, 'gf-saku-goth');
				//}
				//else
				//	saveDataManager.unlockData.setSongVisible('Ectospasm');
			case 'ectospasm':
				if(unlock(GF, 'gf-zerktro') && Unlocks.unlockedBfs.contains('bf-retro')) {
					setNew(SONG, "Scalie Feeling");
					saveUnlocks();
				}
			case 'fuzzy-feeling':
				var unlockedGFSaku = unlock(GF, 'gf-saku');

				if(unlockedGFSaku && Unlocks.unlockedBfs.contains('bf-saku')) {
					setNew(SONG, "Fuzziest Feeling");
					setNew(SONG, "Ectogasm");
					setNew(SONG, "Satisflatter");
					saveUnlocks();
				}

				//if (saveDataManager.unlockData.unlockGf('gf-saku') && saveDataManager.unlockData.unlockBf('bf-saku')) {
				//	
				//}
				//	saveDataManager.newContent.setFreeplayFlag(true, saveDataManager.unlockData.getSongIndex('Fuzzy Feeling'));
				//if (!Unlocks.unlockedGfs.contains('gf-saku-goth'))
				//	unlock(GF, 'gf-saku-goth');
			case 'fuzziest-feeling':
				//unlock(GF, 'gf-saku');

				unlock(GF, 'gf-saku-goth');
			case 'overtime':
				unlock(BF, 'bf-minus');
				unlock(GF, 'gf-minus');
			//case 'postgame':
			//	if(!hasUnlockedSong("mompoms")) {
			//		unlock(SONG, "mompoms");
			//		setNew(SONG, "mompoms");
			//	}
			case 'heartmelter':
				var unlockedBFSaku = unlock(BF, 'bf-saku');
				if(unlockedBFSaku && Unlocks.unlockedGfs.contains('gf-saku')) {
					setNew(SONG, "Fuzziest Feeling");
					setNew(SONG, "Ectogasm");
					setNew(SONG, "Satisflatter");
					saveUnlocks();
				}
				//if (saveDataManager.unlockData.unlockBf('bf-saku'))
				//{
				//	//saveDataManager.newContent.setFreeplayFlag(true, saveDataManager.unlockData.getSongIndex('Satisfracture'));
				//}
				//if (saveDataManager.unlockData.unlockGf('gf-saku') && saveDataManager.unlockData.unlockBf('bf-saku'))
				//	saveDataManager.newContent.setFreeplayFlag(true, saveDataManager.unlockData.getSongIndex('Fuzzy Feeling'));
		}
		//saveUnlocks();
	}

	public static function progressCheck() {
		// Save Data Port Check
		//for(song in allSongs) {
		//	if(!hasUnlockedSong(song) && (hasBeaten(song))) {
		//		unlock(SONG, song, true);
		//	}
		//}

		/// Unlock Checks

		// Wrath
		//if(!hasUnlockedSong("spectral") && (hasBeaten("satisfracture"))) {
		//	unlock(SONG, "spectral", true);
		//}

		// Minus
		//if(!hasUnlockedSong("sigma") && (hasBeaten("preseason"))) {
		//	unlock(SONG, "sigma", true);
		//}
		//if(!hasUnlockedSong("preppy") && (hasBeaten("sigma"))) {
		//	unlock(SONG, "preppy", true);
		//}
		//if(!hasUnlockedSong("overtime") && (hasBeaten("preppy"))) {
		//	unlock(SONG, "overtime", true);
		//}
		//if(!hasUnlockedSong("postgame") && (hasBeaten("overtime"))) {
		//	unlock(SONG, "Postgame");
		//}

		fixOrder();

		//saveUnlocks();
	}

	public static function playedSong(value:String) {
		value = Paths.formatToSongPath(value);

		if(!unlockedSongs.contains(value)) {
			unlockedSongs.push(value);

			unlockedSongs = _fixOrder(unlockedSongs, allSongs);

			trace("PLAYED: " + value);
		}

		newSongs.remove(value);
		saveUnlocks();
	}

	private static function add(arr:Array<String>, value:String):Bool {
		if(!arr.contains(value)) {
			arr.push(value);
			return true;
		}
		return false;
	}

	public static function unlock(type:UnlockType, _value:String, hidden:Bool = false) {
		var value = Paths.formatToSongPath(_value);

		var didAdd = switch(type) {
			case BF: add(unlockedBfs, value);
			case GF: add(unlockedGfs, value);
			case FOE: add(unlockedFoes, value);
			case WEEK: add(unlockedWeeks, value);
			case SONG: add(unlockedSongs, value);
			case MODE: add(unlockedModes, value);
			default: false;
		}

		trace("UNLOCKED:", type, value, hidden, didAdd);

		if(didAdd && !hidden) {
			switch(type) {
				case BF: recentlyUnlockedChars.push(value);//recentlyUnlockedBfs.push(value);
				case GF: recentlyUnlockedChars.push(value);//recentlyUnlockedGfs.push(value);
				case FOE: recentlyUnlockedChars.push(value);//recentlyUnlockedFoes.push(value);
				case WEEK: recentlyUnlockedWeeks.push(value);
				case SONG: recentlyUnlockedSongs.push(_value);
				case MODE: recentlyUnlockedModes.push(value);
				default:{};
			}
		}
		saveUnlocks();
		return didAdd;
	}

	public static var newWeeks:Array<String> = ["minus"];
	public static var newSongs:Array<String> = [
		"postgame",
		"mompoms",
		"icebreaker",
		"brawnstorm",
		//"corruptro",
	];
	public static var newMenuItem:Array<String> = [];

	public static function setNew(type:UnlockType, value:String) {
		value = Paths.formatToSongPath(value);

		var didAdd = switch(type) {
			case WEEK: add(newWeeks, value);
			case SONG: add(newSongs, value);
			case MENU_ITEM: add(newMenuItem, value);
			default: false;
		}

		return didAdd;
	}

	private static inline function clearArr(array:Array<String>) {
		array.splice(0, array.length);
	}

	public static function clearRecentType(type:UnlockType) {
		switch(type) {
			case BF: clearArr(recentlyUnlockedChars);
			case GF: clearArr(recentlyUnlockedChars);
			case FOE: clearArr(recentlyUnlockedChars);
			case CHAR: clearArr(recentlyUnlockedChars);
			case WEEK: clearArr(recentlyUnlockedWeeks);
			case SONG: clearArr(recentlyUnlockedSongs);
			case MODE: clearArr(recentlyUnlockedModes);
			default:{};
		}
	}

	// Utils

	public static function fixOrder() {
		unlockedBfs = _fixOrder(unlockedBfs, allBfs);
		unlockedGfs = _fixOrder(unlockedGfs, allGfs);
		unlockedFoes = _fixOrder(unlockedFoes, allFoes);
		unlockedSongs = _fixOrder(unlockedSongs, allSongs);
		unlockedModes = _fixOrder(unlockedModes, allModes);
		unlockedWeeks = _fixOrder(unlockedWeeks, allWeeks);
	}

	private static function _fixOrder(unlocked:Array<String>, all:Array<String>) {
		var newList:Array<String> = [];
		for(data in all) {
			if(unlocked.contains(data)) {
				newList.push(data);
			}
		}
		return newList;
	}

	public inline static function isBFUnlocked(name:String) {
		return Unlocks.unlockedBfs.contains(name);
	}
	public inline static function isBFUnlockedIdx(idx:Int) {
		return Unlocks.unlockedBfs.contains(Unlocks.allBfs[idx]);
	}

	public inline static function isGFUnlocked(name:String) {
		return Unlocks.unlockedGfs.contains(name);
	}
	public inline static function isGFUnlockedIdx(idx:Int) {
		return Unlocks.unlockedGfs.contains(Unlocks.allGfs[idx]);
	}

	public inline static function isFoeUnlocked(name:String) {
		return Unlocks.unlockedFoes.contains(name);
	}

	public inline static function isModeUnlocked(mode:String) {
		return Unlocks.unlockedModes.contains(mode);
	}
	public inline static function isModeUnlockedIdx(mode:Int) {
		return Unlocks.unlockedModes.contains(Unlocks.allModes[mode]);
	}

	public inline static function isWeekUnlocked(week:String) {
		if(!Unlocks.allWeeks.contains(week)) return true; // Assume Custom Week
		return Unlocks.unlockedWeeks.contains(week);
	}

	public static function hasBeaten(song:String, diff:Int = -1) {
		song = Paths.formatToSongPath(song);
		Difficulty.useAllDiffs = true;

		if(diff == -1) {
			for(i in 0...Difficulty.defaultDifficulties.length) {
				if(Highscore.getScore(song, i) > 0) {
					Difficulty.useAllDiffs = false;
					return true;
				}
			}
			Difficulty.useAllDiffs = false;
			return false;
		}
		var score = Highscore.getScore(song, diff) > 0;
		Difficulty.useAllDiffs = false;
		return score;
	}

	public static var debugAllSongs:Bool = false;

	public static function hasUnlockedSong(song:String) {
		if(Unlocks.debugAllSongs) return true;
		song = Paths.formatToSongPath(song);
		if(!Unlocks.allSongs.contains(song)) return true; // Assume Custom Song
		return Unlocks.unlockedSongs.contains(song);
	}
}

enum abstract UnlockType(Int) {
	var BF = 0;
	var GF = 1;
	var FOE = 2;
	var WEEK = 3;
	var SONG = 4;
	var MODE = 5;
	var CHAR = 6;

	// Unused in unlocks
	var MENU_ITEM = 7;
}