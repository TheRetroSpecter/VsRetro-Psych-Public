package;

using StringTools;

class Difficulty {
	public static inline final EASY = 0;
	public static inline final NORMAL = 1;
	public static inline final HARD = 2;
	public static inline final HELL = 3;
	public static inline final APOCALYPSE = 4;

	public static var defaultDifficulties:Array<String> = [
		'Easy',
		'Normal',
		'Hard',
		'Hell',
		'Apocalypse'
	];

	public static var defaultDifficulty:String = 'Normal'; //The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var difficulties:Array<String> = [];

	public inline static function get(val:Int) {
		return defaultDifficulties[val];
	}

	public inline static function remove(val:Int) {
		return difficulties.remove(get(val));
	}

	public static var useAllDiffs = false;

	public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if(num == null) num = PlayState.storyDifficulty;

		var difficulties = useAllDiffs ? defaultDifficulties : Difficulty.difficulties;

		var fileSuffix:String = difficulties[num];
		if(fileSuffix != defaultDifficulty)
		{
			fileSuffix = '-' + fileSuffix;
		}
		else
		{
			fileSuffix = '';
		}
		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString():String
	{
		return difficulties[PlayState.storyDifficulty].toUpperCase();
	}
}