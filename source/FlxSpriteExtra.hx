package;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class FlxSpriteExtra extends FlxSprite
{
	override function makeGraphic(Width:Int, Height:Int, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):FlxSpriteExtra {
		return cast super.makeGraphic(Width, Height, Color, Unique, Key);
	}

	public function makeSolid(Width:Int, Height:Int, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):FlxSpriteExtra
	{
		var graph:FlxGraphic = FlxG.bitmap.create(1, 1, Color, Unique, Key);
		frames = graph.imageFrame;
		scale.set(Width, Height);
		updateHitbox();
		return this;
	}

	public inline function hide() {
		alpha = 0.0001;
	}
	public inline function show() {
		alpha = 1;
	}
}