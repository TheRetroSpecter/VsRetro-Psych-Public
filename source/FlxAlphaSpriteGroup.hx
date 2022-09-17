package;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.math.FlxPoint;

class FlxAlphaSpriteGroup extends FlxSpriteGroup
{
	public var renderAlpha:Float = 1;

	override public function draw():Void
	{
		var i:Int = 0;
		var basic:FlxBasic = null;

		var oldDefaultCameras = @:privateAccess FlxCamera._defaultCameras;
		if (group.cameras != null)
		{
			@:privateAccess FlxCamera._defaultCameras = group.cameras;
		}

		while (i < group.length)
		{
			basic = group.members[i++];

			if (basic != null && basic.exists && basic.visible)
			{
				if((basic is FlxSprite)) {
					var basic:FlxSprite = cast basic;
					var oldAlpha = basic.alpha;
					basic.alpha *= renderAlpha;
					basic.draw();
					basic.alpha = oldAlpha;
				} else {
					basic.draw();
				}
			}
		}

		@:privateAccess FlxCamera._defaultCameras = oldDefaultCameras;

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}
}