package;

import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class HealthIcon extends FlxShakableSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';

	public var totalFrames = 0;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	public function swapOldIcon() {
		if(isOldIcon = !isOldIcon) changeIcon('bf-old');
		else changeIcon('bf');
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String) {
		if(this.char != char) {
			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			var file:Dynamic = Paths.image(name);

			//loadGraphic(file); //Load stupidly first for getting the file size
			//loadGraphic(file, true, Math.floor(width / 2), Math.floor(height)); //Then load it fr
			loadGraphic(file, true, 150, 150);
			iconOffsets[0] = (width - 150) / 2;
			iconOffsets[1] = (height - 150) / 2;
			updateHitbox();

			totalFrames = frames.frames.length;

			animation.add(char, CoolUtil.numberArray(frames.frames.length, 0), 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			if(char.endsWith('-pixel')) {
				antialiasing = false;
			} else {
				antialiasing = ClientPrefs.globalAntialiasing;
			}
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String {
		return char;
	}

	//use for optimize mode only since I have no clue how to do anything else
	public static function returnDefaultIcon(c:String):String
	{
		var newIcon = c;
		if (c.startsWith('retro'))
		{
			newIcon = 'retro';
			if(c.startsWith('retro2')) newIcon = 'zerktro';
			if(c.contains('minus')) newIcon = 'retro-minus';
		}
		if (c == 'bf-wrath') newIcon = 'bf';
		if (c.startsWith('sakuroma') && !c.endsWith('alt')) newIcon = 'sakuroma';

		trace('icon default set to ' + newIcon);

		return newIcon;
	}
}
