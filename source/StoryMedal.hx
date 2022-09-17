package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

class StoryMedal extends FlxSprite
{
	public var originalY:Float = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
        originalY = y;
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
