package;

import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.util.FlxColor;
import shaders.AmongUsColorSwapShader;
import flixel.FlxG;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite
{
	public var colorSwap:AUCSData;
	public static var staticColorSwap:AmongUsColorSwapShader;
	private var idleAnim:String;
	private var textureLoaded:String = null;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0) {
		super(x, y);

		var skin:String = 'noteSplashes';
		if(PlayState.splashSkin != null && PlayState.splashSkin.length > 0) skin = PlayState.splashSkin;

		loadAnims(skin);

		if(!ClientPrefs.optimizedNotes) {
			colorSwap = new AUCSData();
			if(staticColorSwap == null) {
				staticColorSwap = new AmongUsColorSwapShader();
			}
			shader = staticColorSwap;
		}

		moves = false;

		setupNoteSplashHSV(x, y, note);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function setupNoteSplashHSV(x:Float, y:Float, note:Int = 0, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0) {
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		alpha = 0.6;

		if(texture == null) {
			texture = 'noteSplashes';
			if(PlayState.splashSkin != null && PlayState.splashSkin.length > 0) texture = PlayState.splashSkin;
		}

		if(textureLoaded != texture) {
			loadAnims(texture);
		}

		if(!ClientPrefs.optimizedNotes) {
			colorSwap.active = false;
			colorSwap.hue = hueColor;
			colorSwap.saturation = satColor;
			colorSwap.brightness = brtColor;
		}

		offset.set(10, 10);

		var animNum:Int = FlxG.random.int(1, 2);
		animation.play('note' + note % 4 + '-' + animNum, true);
		if(animation.curAnim != null)animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
	}

	public function setupNoteSplashRGB(x:Float, y:Float, note:Int = 0, texture:String = null, redColor:FlxColor = 0) {
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		alpha = 0.6;

		if(texture == null) {
			texture = 'noteSplashes';
			if(PlayState.splashSkin != null && PlayState.splashSkin.length > 0) texture = PlayState.splashSkin;
		}

		if(textureLoaded != texture) {
			loadAnims(texture);
		}

		if(!ClientPrefs.optimizedNotes) {
			colorSwap.active = true;

			colorSwap.red = redColor;
			colorSwap.green = 0xffffff;
			colorSwap.blue = 0xffffff;

			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		}

		offset.set(10, 10);

		var animNum:Int = FlxG.random.int(1, 2);
		animation.play('note' + note % 4 + '-' + animNum, true);
		if(animation.curAnim != null)animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
	}

	function loadAnims(skin:String) {
		frames = Paths.getSparrowAtlas(skin);
		for (i in 1...3) {
			animation.addByPrefix("note0-" + i, "note splash purple " + i, 24, false);
			animation.addByPrefix("note1-" + i, "note splash blue " + i, 24, false);
			animation.addByPrefix("note2-" + i, "note splash green " + i, 24, false);
			animation.addByPrefix("note3-" + i, "note splash red " + i, 24, false);
		}

		textureLoaded = skin;
	}

	override function update(elapsed:Float) {
		if(animation.curAnim != null)if(animation.curAnim.finished) kill();

		super.update(elapsed);
	}

	@:noCompletion
	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}

		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader, colorSwap);
	}
}