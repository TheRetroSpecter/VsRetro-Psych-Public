package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;

using StringTools;

class Boyfriend extends Character
{
	public var startedDeath:Bool = false;

	public function new(x:Float, y:Float, ?char:String = 'bf')
	{
		super(x, y, char, true);
	}

	override function update(elapsed:Float)
	{
		if (!debugMode && animation.curAnim != null)
		{
			if (animation.curAnim.name.startsWith('sing'))
				holdTimer += elapsed;
			else
				holdTimer = 0;

			if (animation.curAnim.finished && animation.curAnim.name.endsWith('miss'))
			{
				if(danceIdle) {
					dance();
					if(animation.curAnim != null) {
						animation.curAnim.curFrame = 10;
					}
				} else {
					playAnim('idle', true, false, 10);
				}
			}

			if (startedDeath && animation.curAnim.finished && animation.curAnim.name == 'firstDeath')
			{
				playAnim('deathLoop');
			}
		}

		super.update(elapsed);
	}
}
