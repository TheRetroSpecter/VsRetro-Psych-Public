package;

import flixel.util.FlxGradient;
import flixel.util.FlxColor;
import flixel.FlxG;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

using StringTools;

class CoolUtil
{
	public static function getRandomNoteData(legalNotes:Array<Bool>):Int
	{
		var availablePositions:Array<Int> = new Array<Int>();

		for(i in 0...legalNotes.length)
		{
			if(legalNotes[i])
			{
				availablePositions.push(i);
			}
		}

		var choice:Int = Math.floor(Std.int(Math.random() * availablePositions.length));

		return availablePositions[choice];
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if desktop
		if(OpenFlAssets.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if(Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function coolTextFileLegacy(path:String):Array<String>
	{
		#if desktop
		if(!OpenFlAssets.exists(path))
		#else
		if(!Assets.exists(path, TEXT))
		#end
		{
			return null;
		}

		var daList:Array<String> = [];
		#if desktop
		if(OpenFlAssets.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if(Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth) {
			for(row in 0...sprite.frameHeight) {
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if(colorOfThisPixel != 0) {
					if(countByColor.exists(colorOfThisPixel)) {
						countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
					} else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687)) {
						countByColor[colorOfThisPixel] = 1;
					}
				}
			}
		}
		var maxCount = 0;
		var maxKey:Int = 0;//after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for(key in countByColor.keys()) {
			if(countByColor[key] >= maxCount) {
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	public static function numberArray(max:Int, ?min:Int = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	//uhhhh does this even work at all? i'm starting to doubt
	public static function precacheSound(sound:String, ?library:String = null):Void {
		precacheSoundFile(Paths.sound(sound, library));
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void {
		precacheSoundFile(Paths.music(sound, library));
	}

	private static function precacheSoundFile(file:Dynamic):Void {
		if (Assets.exists(file, SOUND) || Assets.exists(file, MUSIC))
			Assets.getSound(file, true);
	}

	public inline static function trimTextStart(text:String, toRemove:String, unsafe:Bool = false):String
	{
		if(unsafe || text.startsWith(toRemove)) {
			return text.substr(toRemove.length);
		}
		return text;
	}

	/**
	 * Modulo that works for negative numbers
	 */
	 public inline static function mod(n:Int, m:Int) {
		return ((n % m) + m) % m;
	}

	public static function makeGradient(width:Int, height:Int, colors:Array<FlxColor>, chunkSize:UInt = 1, rotation:Int = 90, interpolate:Bool = true) {
		var gradWidth = width;
		var gradHeight = height;
		var gradXScale = 1;
		var gradYScale = 1;

		var modRotation = mod(rotation, 360);

		if(modRotation == 90 || modRotation == 270) {
			gradXScale = width;
			gradWidth = 1;
		}

		if(modRotation == 0 || modRotation == 180) {
			gradYScale = height;
			gradHeight = 1;
		}

		var gradient = FlxGradient.createGradientFlxSprite(gradWidth, gradHeight, colors, chunkSize, rotation, interpolate);
		gradient.scale.set(gradXScale, gradYScale);
		gradient.updateHitbox();
		return gradient;
	}

	public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}
}
