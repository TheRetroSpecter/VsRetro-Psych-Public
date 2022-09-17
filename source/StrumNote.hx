package;

import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.util.FlxColor;
import shaders.AmongUsColorSwapShader;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class StrumNote extends FlxShakableSprite
{
	public var colorSwap:AUCSData;
	public static var staticColorSwap:AmongUsColorSwapShader;

	public var resetAnim:Float = 0;
	private var noteData:Int = 0;

	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;

	public var isUsingColorChange:Bool = false;
	public var forceColorChange:Bool = false;

	public var isConfirm = false;

	public var frozen = false;

	private var player:Int;
	private var currentRed:FlxColor;

	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			if(texture == "NOTE_assets_quant") {
				forceColorChange = true;
			} else {
				forceColorChange = false;
			}
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int, ?skin:String = 'NOTE_assets') {
		if(!ClientPrefs.optimizedNotes) {
			colorSwap = new AUCSData();
			if(staticColorSwap == null) {
				staticColorSwap = new AmongUsColorSwapShader();
			}
			shader = staticColorSwap;
		}
		currentRed = 0xffffff;
		//colorChange.red = currentRed;
		noteData = leData;
		this.player = player;
		super(x, y);
		if (skin == '' || skin == null)
			skin = 'NOTE_assets';
		texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			switch (Math.abs(noteData))
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 24, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			var dataDir = ["left", "down", "up", "right"];

			frames = Paths.getSparrowAtlas(texture);

			if(PlayState.instance != null && PlayState.instance.hasIceNotes) {
				addFrames(Paths.getSparrowAtlas("iceolation/FrozenStrums"));
			}

			antialiasing = ClientPrefs.globalAntialiasing;
			setGraphicSize(Std.int(width * 0.7));

			var dir = dataDir[noteData].toLowerCase();
			animation.addByPrefix('static', 'arrow' + dir.toUpperCase());
			animation.addByPrefix('pressed', dir + ' press', 24, false);
			animation.addByPrefix('confirm', dir + ' confirm', 24, false);
			if(PlayState.instance != null && PlayState.instance.hasIceNotes) {
				animation.addByPrefix('frozen', 'arrowFrozen' + dir.toUpperCase(), 24, true);
				//trace("Added Frozen");
			}

			for(i in 0...4) {
				var dir = dataDir[i].toLowerCase();
				var color = Note.dataColor[i];
				//animation.addByPrefix('static' + color, 'arrow' + dir.toUpperCase());
				animation.addByPrefix('pressed' + color, dir + ' press', 24, false);
				animation.addByPrefix('confirm' + color, dir + ' confirm', 24, false);
			}
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		//if(animation.curAnim != null){ //my bad i was upset
		if(isConfirm && !PlayState.isPixelStage) {
			centerOrigin();
		//}
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false, ?note:Note = null) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();

		isConfirm = anim == "confirm";
		extraAngle = 0;

		if(!ClientPrefs.optimizedNotes)
			colorSwap.active = false;

		if(animation.curAnim == null || animation.curAnim.name == 'static') {
			if(!ClientPrefs.optimizedNotes) {
				colorSwap.hue = 0;
				colorSwap.saturation = 0;
				colorSwap.brightness = 0;
			}
		} else {
			if (note != null)
			{
				if(!ClientPrefs.optimizedNotes) {
					if(forceColorChange || note.isUsingColorChange) {
						currentRed = note.colorSwap.red;
						colorSwap.red = currentRed;
						colorSwap.green = 0xffffff;
						colorSwap.blue = note.colorSwap.blue;

						colorSwap.hue = 0;
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;

						colorSwap.active = true;
						isUsingColorChange = true;
					} else {
						if(texture == 'NOTE_assets')
						{
							colorSwap.hue = note.colorSwap.hue;
							colorSwap.saturation = note.colorSwap.saturation;
							colorSwap.brightness = note.colorSwap.brightness;
						}
						else
						{
							colorSwap.hue = 0;
							colorSwap.saturation = 0;
							colorSwap.brightness = 0;
						}

						colorSwap.active = false;
						isUsingColorChange = false;
					}
				}

				var visColor = note.originColor % 4;

				var quantAngle = -Note.arrowAngles[visColor];
				quantAngle += Note.arrowAngles[noteData % 4];

				extraAngle = quantAngle;

				if(noteData != visColor) {
					animation.play(anim + Note.dataColor[visColor], force);
					centerOffsets();
					centerOrigin();
				}
			}
			else
			{
				if(!ClientPrefs.optimizedNotes) {
					if(!isUsingColorChange && texture == 'NOTE_assets') {
						colorSwap.hue = ClientPrefs.arrowHSV[noteData % 4][0] / 360;
						colorSwap.saturation = ClientPrefs.arrowHSV[noteData % 4][1] / 100;
						colorSwap.brightness = ClientPrefs.arrowHSV[noteData % 4][2] / 100;
					} else {
						colorSwap.hue = 0;
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;
					}

					if(forceColorChange && animation.curAnim.name == 'pressed') {
						colorSwap.active = true;
						colorSwap.red = FlxColor.interpolate(currentRed, 0x9c9c9c, 0.6);
						colorSwap.blue = 0x201E31;
						colorSwap.green = 0xffffff;
					}
				}
			}

			if(isConfirm && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}
	}

	public function addFrames(otherFrames:FlxAtlasFrames, reload:Bool = true) {
		if(otherFrames == null) return;

		for(frame in otherFrames.frames) {
			this.frames.pushFrame(frame);
		}

		if(reload) {
			this.frames = this.frames;
		}
	}

	@:noCompletion
	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrigExtra();

			if (angle != 0 || extraAngle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);
		if(shakeDistance != 0) {
			_matrix.translate(FlxG.random.float(-shakeDistance, shakeDistance), FlxG.random.float(-shakeDistance, shakeDistance));
		}

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}

		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader, colorSwap);
	}
}
