package;

import flixel.FlxSprite;

using StringTools;

class AttachedSpriteColor extends AttachedSprite
{
	public var colorSwap:ColorSwapRGB;

	public function new(?file:String = null, ?anim:String = null, ?library:String = null, ?loop:Bool = false)
	{
		super(file, anim, library, loop);
		colorSwap = new ColorSwapRGB();
		shader = colorSwap.shader;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
