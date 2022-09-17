import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import flixel.math.FlxRandom;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxBasic;
import flixel.util.FlxColor;

class ConfettiParticle extends FlxSprite
{
	static var confettiBitmap:FlxGraphic;

	var velocityCap:Float = 200;
	var velocityRate:Float = 5000;
	var velocityBurst:Float = -3000;
	var rand:FlxRandom;

	/*
	Creates new confetti particle with paramaters sizeX and sizeY

	@param sizeX  width of the confetti particle
	@param sizeY  height of the confetti particle
	*/
	public function new(color:FlxColor, sizeX:Int, sizeY:Int)
	{
		super(0, 0);
		if(confettiBitmap == null || confettiBitmap.key == null) {
			confettiBitmap = FlxG.bitmap.create(1, 1, 0xFFffffff, false, "confetti");
		}
		this.color = color;
		frames = confettiBitmap.imageFrame;
		scale.set(sizeX, sizeY);
		updateHitbox();
		rand = new FlxRandom();
		visible = false; // Make particles off by default
		active = false;
		moves = false; // Disable physics logic while off
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// (Arcy) Make confetti fall faster till a point
		if (velocity.y < velocityCap)
		{
			velocity.y += velocityRate * elapsed;
		}

		// (Arcy) Disable particle once off-screen
		if (y > FlxG.height)
		{
			visible = false;
			moves = false;
			active = false;
			y = 0;
		}

		if (visible)
		{
			angle += rand.float(-5, 5);
		}
	}

	override function updateAnimation(elapsed:Float):Void {}

	/**	(Arcy)
	* Method used for launching the particle upwards when it is used in the scene.
	*/
	public function launchParticle()
	{
		velocity.y = velocityBurst;
		velocity.x = rand.float(-100, 100);
		visible = true; // Make visible again
		active = true;
		moves = true; // Enable physics logic
	}
}