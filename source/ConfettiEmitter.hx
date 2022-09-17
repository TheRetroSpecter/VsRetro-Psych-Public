import flixel.FlxSprite;
import flixel.math.FlxRandom;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxBasic;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import ConfettiParticle;

class ConfettiEmitter
{
	public var confettiColorPools:FlxTypedGroup<FlxTypedGroup<ConfettiParticle>>;

	/*
	Creates a new ConfettiEmitter object.

	@param sizeX The width of the particle.
	@param sizeY The height of the particle.

	*/
	public function new(sizeX:Int, sizeY:Int)
	{
		var pinkPool:FlxTypedGroup<ConfettiParticle> = new FlxTypedGroup<ConfettiParticle>();
		var redPool:FlxTypedGroup<ConfettiParticle> = new FlxTypedGroup<ConfettiParticle>();
		var orangePool:FlxTypedGroup<ConfettiParticle> = new FlxTypedGroup<ConfettiParticle>();
		var yellowPool:FlxTypedGroup<ConfettiParticle> = new FlxTypedGroup<ConfettiParticle>();
		var greenPool:FlxTypedGroup<ConfettiParticle> = new FlxTypedGroup<ConfettiParticle>();
		var bluePool:FlxTypedGroup<ConfettiParticle> = new FlxTypedGroup<ConfettiParticle>();
		var purplePool:FlxTypedGroup<ConfettiParticle> = new FlxTypedGroup<ConfettiParticle>();
		var magentaPool:FlxTypedGroup<ConfettiParticle> = new FlxTypedGroup<ConfettiParticle>();

		for (i in 0...500)
		{
			pinkPool.add(new ConfettiParticle(FlxColor.PINK, sizeX, sizeY));
			redPool.add(new ConfettiParticle(FlxColor.RED, sizeX, sizeY));
			orangePool.add(new ConfettiParticle(FlxColor.ORANGE, sizeX, sizeY));
			yellowPool.add(new ConfettiParticle(FlxColor.YELLOW, sizeX, sizeY));
			greenPool.add(new ConfettiParticle(FlxColor.GREEN, sizeX, sizeY));
			bluePool.add(new ConfettiParticle(FlxColor.BLUE, sizeX, sizeY));
			purplePool.add(new ConfettiParticle(FlxColor.PURPLE, sizeX, sizeY));
			magentaPool.add(new ConfettiParticle(FlxColor.MAGENTA, sizeX, sizeY));
		}

		confettiColorPools = new FlxTypedGroup<FlxTypedGroup<ConfettiParticle>>();
		confettiColorPools.add(pinkPool);
		confettiColorPools.add(redPool);
		confettiColorPools.add(orangePool);
		confettiColorPools.add(yellowPool);
		confettiColorPools.add(greenPool);
		confettiColorPools.add(bluePool);
		confettiColorPools.add(purplePool);
		confettiColorPools.add(magentaPool);
	}

	/**	(Arcy)
	* Method used to spawn a bunch of different colored confetti at the given range.
	*
	* @param	minX		The minimum X coordinate for confetti to spawn at.
	* @param	maxX		The maximum X coordinate for confetti to spawn at.
	* @param	minY		The minimum Y coordinate for confetti to spawn at.
	* @param	maxY		The maximum Y coordinate for confetti to spawn at.
	* @param	minAmount	The minimum amount of each confetti color particle that can spawn.
	* @param	maxAmount	The maximum amount of each confetti color particle that can spawn.
	*/
	public function throwConfetti(minX:Float, maxX:Float, minY:Float, maxY:Float, minAmount:Int = 2, maxAmount:Int = 5)
	{
		var rand:FlxRandom = new FlxRandom();
		var amount:Int = 0;
		var curAmount:Int = 0;

		for (i in 0...confettiColorPools.length)
		{
			// (Arcy) Get a random amount in the range for this color
			curAmount = 0;
			amount = rand.int(minAmount, maxAmount);
			for (confetti in confettiColorPools.members[i])
			{
				// Only use those that aren't active
				if (!confetti.visible)
				{
					confetti.x = rand.float(minX, maxX);
					confetti.y = rand.float(minY, maxY);
					confetti.launchParticle();
					curAmount++;

					// Stop after the needed amount of this color
					if (curAmount >= amount)
					{
						break;
					}
				}
			}
		}
	}
}