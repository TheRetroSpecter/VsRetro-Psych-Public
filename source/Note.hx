package;

import flixel.graphics.frames.FlxFrame;
import flixel.FlxCamera;
import shaders.AmongUsColorSwapShader;
import shaders.AmongUsShader;
import flixel.math.FlxRect;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flash.display.BitmapData;
import editors.ChartingState;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var secondDad = false;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var isHoldEnd:Bool = false;
	public var noteType(default, set):String = null;
	public var isMechanicNote:Bool = false; // For Mechanics setting
	public var isSpectreNote:Bool = false;
	public var doesNothingIfMissed:Bool = false;
	public var canMiss:Bool = false;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var isUsingColorChange:Bool = false;
	public var colorSwap:AUCSData;
	public static var staticColorSwap:AmongUsColorSwapShader;

	public var inEditor:Bool = false;
	public var gfNote:Bool = false;

	private var lateHitMult:Float = 1;
	private var earlyHitMult:Float = 0.5;
	private var hittime = 1.0;

	// Note Constants
	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	static var notedir:Array<String> = ['Left', 'Down', 'Up', 'Right'];
	public static var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];

	// Note Quantization
	private static var quantDivisions:Array<Int> = [0, 1, 2, 3, 4, 5, 6, 7];
	public static var arrowAngles:Array<Int> = [180, 90, 270, 0];

	public var originColor:Int; // Mainly used for sustain notes
	public var quantColor:Int;
	public var quantEnabled(default, set):Bool; // For control on what notes are quantized, usually for exempting special note types
	public var forceDisableQuant:Bool = false;

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var holdOffsetX:Float = 0;
	public var specialOffsetX:Int = 0;
	public var noteOffsetX:Int = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var offsetAngleQuant:Float = 0;
	public var multAlpha:Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var countsForCombo:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000;

	public var hitsoundDisabled:Bool = false;

	public var parent:Note = null;
	public var children:Array<Note> = [];
	public var sustainActive:Bool = true;

	public var altAnimation:Bool = false;
	public var didMakuMiss:Bool = false;

	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote('', value);
		}
		texture = value;
		return value;
	}

	public var forcedHue:Float = 0;

	private function set_noteType(value:String):String {
		noteSplashTexture = PlayState.splashSkin;
		quantEnabled = value == "0" || value == "" || value == null;
		if(!ClientPrefs.optimizedNotes) {
			forcedHue = 0;
			if(!quantEnabled) {
				colorSwap.hue = ClientPrefs.arrowHSV[originColor % 4][0] / 360;
				colorSwap.saturation = ClientPrefs.arrowHSV[originColor % 4][1] / 100;
				colorSwap.brightness = ClientPrefs.arrowHSV[originColor % 4][2] / 100;
			} else {
				colorSwap.hue = 0;
				colorSwap.saturation = 0;
				colorSwap.brightness = 0;
			}
		}

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					reloadNote('HURT');
					noteSplashTexture = 'HURTnoteSplashes';
					if(!ClientPrefs.optimizedNotes) {
						colorSwap.hue = 0;
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;
					}
					if(isSustainNote) {
						missHealth = 0.1;
					} else {
						missHealth = 0.3;
					}
					hitCausesMiss = true;
					isMechanicNote = true;
				case 'poison':
					ignoreNote = mustPress;
					missHealth = 0;
					hitCausesMiss = true;
					doesNothingIfMissed = true;
					isMechanicNote = true;
					addCustomNote(value);
					hittime = 0.5;//smaller hit area
					hitsoundDisabled = true;
					noteSplashDisabled = true;

					if(!ClientPrefs.optimizedNotes) {
						colorSwap.hue = 0;
						if(PlayState.instance != null && PlayState.instance.formattedSong == "corruptro") {
							colorSwap.hue = 180/360;
							forcedHue = 180/360;
						}
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;

						colorSwap.active = false;
						colorSwap.red = 0x09F73C;
						colorSwap.blue = 0x099627;
						if(PlayState.instance != null && PlayState.instance.formattedSong == "corruptro") {
							colorSwap.red = 0xF709C4;
							colorSwap.blue = 0xA71186;
						}
					}

					if(ClientPrefs.downScroll) {earlyHitMult = 0.9; lateHitMult = 0.65; offsetY -= 70;}
					else {earlyHitMult = 0.65; lateHitMult = 0.9;}
				case 'spectre':
					//ignoreNote = mustPress;
					//hittime = 1.25;//larger hit area
					hitHealth = 0;
					missHealth = 0;
					countsForCombo = false;
					noAnimation = mustPress;
					noteSplashDisabled = true;
					isMechanicNote = true;
					isSpectreNote = true;
					canMiss = true;
					//doesNothingIfMissed = true;
					hitsoundDisabled = true;

					if(!ClientPrefs.optimizedNotes) {
						colorSwap.hue = 0;
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;

						colorSwap.active = false;
						colorSwap.red = 0xF1F1F1;
						colorSwap.blue = 0x8B8B8B;
					}

					addCustomNote(value);
				case 'sakuNote':
					ignoreNote = mustPress;
					isMechanicNote = true; // GOT EM
					//hittime = 1.25;//larger hit area
					doesNothingIfMissed = true;
					countsForCombo = false;

					if(!ClientPrefs.optimizedNotes) {
						colorSwap.hue = 0;
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;

						colorSwap.active = false;
						colorSwap.red = 0xFF38E4;
						colorSwap.blue = 0x9B1B8A;
					}

					addCustomNote(value);
				case 'iceNote':
					//ignoreNote = mustPress;
					isMechanicNote = true;
					//hittime = 1.25;//larger hit area
					hitHealth = 0;
					missHealth = 0;
					noAnimation = true;
					hitCausesMiss = true;
					ignoreNote = true;
					//doesNothingIfMissed = true;
					hitByOpponent = true;
					noteSplashDisabled = true;
					hitsoundDisabled = true;
					addCustomNote(value);

					if(!ClientPrefs.optimizedNotes) {
						colorSwap.hue = 0;
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;
					}

					//lateHitMult = 0.15;
					//earlyHitMult = 0.25;

					noteOffsetX -= 35;
					offsetX -= 35;
					offsetY -= 13;
				case 'No Animation':
					noAnimation = true;

					quantEnabled = true;
				case 'Alt Animation':
					altAnimation = true;

					quantEnabled = true;
				case 'GF Sing':
					gfNote = true;

					quantEnabled = true;
				case 'Fake Note':
					wasGoodHit = true;
					ignoreNote = true;

					quantEnabled = true;
			}
			noteType = value;
		}

		if(!ClientPrefs.optimizedNotes) {
			if(texture != 'NOTE_assets')
			{
				colorSwap.hue = forcedHue;
				colorSwap.saturation = 0;
				colorSwap.brightness = 0;
			}
			noteSplashHue = colorSwap.hue;
			noteSplashSat = colorSwap.saturation;
			noteSplashBrt = colorSwap.brightness;
		}
		return value;
	}

	/**
	 * Setter: Sets whether Note Quantization is enabled for this note and also calculates the note color.
	 *
	 * @param enabled		If true, changes the note color for quantization.
	 */
	private function set_quantEnabled(enabled:Bool) {
		if(!ClientPrefs.noteQuantization) enabled = false;
		if(ClientPrefs.optimizedNotes) enabled = false;
		if(!mustPress && !ClientPrefs.opponentQuants) enabled = false;
		if(forceDisableQuant) enabled = false;

		if(quantEnabled == enabled) return enabled;

		var oldOriginColor = originColor;

		if(enabled) {
			originColor = quantColor;
		} else {
			originColor = noteData % 4;
		}

		if(hasSetup && originColor != oldOriginColor) {
			playNoteAnim();
		}

		return quantEnabled = enabled;
	}

	var hasSetup:Bool = false;

	/**
	 * Plays the animation for this note based upon `noteData`, `isSustainNote`, and `prevNote`.
	 * Also calculates the animation to play for Note Quantization.
	 */
	public function playNoteAnim()
	{
		hasSetup = true;
		offsetX = noteOffsetX;
		// Determine the animation name depending on the color integer
		var animName:String = dataColor[originColor % 4];
		if (isSustainNote && prevNote != null)
		{
			if(isHoldEnd) {
				animName += 'holdend';
			} else {
				animName += 'hold';
			}
		}
		else
		{
			animName += 'Scroll';
		}

		offsetAngleQuant = 0;
		offsetAngleQuant -= arrowAngles[originColor % 4];
		offsetAngleQuant += arrowAngles[noteData % 4];

		animation.play(animName);

		if(!ClientPrefs.optimizedNotes) {
			if(quantEnabled) {
				//shader = colorChange;
				colorSwap.red = ClientPrefs.quantColors[originColor][0];
				colorSwap.blue = ClientPrefs.quantColors[originColor][1];
				colorSwap.green = 0xffffff;
				colorSwap.active = true;

				isUsingColorChange = true;
			} else {
				//shader = colorSwap;
				colorSwap.active = false;

				isUsingColorChange = false;
			}
		}

		if (isSustainNote)
		{
			updateHitbox();

			offsetX = holdOffsetX;

			x += offsetX;
		}
	}

	/**
	 * Determines the quantization color based on the song's BPM and using the `time` of the note passed in.
	 * @return		Returns the integer index of which note color to use in the `ClientPrefs.arrowHSV` array.
	 */
	private static function getQuantIndex(time:Float):Int
	{
		// This code is from Forever Engine
		final quantArray:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 192]; // different quants

		var curBPM:Float = Conductor.bpm;
		var newTime = time;
		for (i in 0...Conductor.bpmChangeMap.length) {
			if (time > Conductor.bpmChangeMap[i].songTime) {
				curBPM = Conductor.bpmChangeMap[i].bpm;
				newTime = time - Conductor.bpmChangeMap[i].songTime;
			}
		}

		final beatTimeSeconds:Float = (60 / curBPM); // beat in seconds
		final beatTime:Float = beatTimeSeconds * 1000; // beat in milliseconds
		final measureTime:Float = beatTime * 4; // assumed 4 beats per measure?

		final smallestDeviation:Float = measureTime / quantArray[quantArray.length - 1];

		for (quant in 0...quantArray.length)
		{
			// please generate this ahead of time and put into array :)
			// I dont think I will im scared of those
			final quantTime = (measureTime / quantArray[quant]);
			if ((newTime + smallestDeviation) % quantTime < smallestDeviation * 2)
			{
				// here it is, the quant, finally!
				return quant;
			}
		}

		return quantArray.length - 1;
	}

	public function new(strumTime:Float, noteData:Int, mustPress:Bool, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.mustPress = mustPress;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;

		x += (ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.noteOffset;

		this.noteData = noteData;

		moves = false;

		if(noteData > -1) {
			texture = '';
			if(!ClientPrefs.optimizedNotes) {
				//colorSwap = new AmongUsColorSwapShader();
				colorSwap = new AUCSData();
				if(staticColorSwap == null) {
					staticColorSwap = new AmongUsColorSwapShader();
				}
				//colorChange = colorSwap;
				shader = staticColorSwap;
			}

			x += swagWidth * (noteData % 4);

			// Calculate the quant color
			if(!ClientPrefs.optimizedNotes && ClientPrefs.noteQuantization) {
				if(!isSustainNote) {
					quantColor = getQuantIndex(strumTime);
				} else {
					// Copy origin color from previous note
					quantColor = prevNote.quantColor;
				}
			}

			originColor = noteData % 4;
		}

		// trace(prevNote);

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if(ClientPrefs.downScroll) flipY = true;

			holdOffsetX += width / 2;

			animation.play(dataColor[originColor % 4] + 'holdend');

			updateHitbox();

			holdOffsetX -= width / 2;

			if (PlayState.isPixelStage)
				holdOffsetX += 30;

			copyAngle = false;
			isHoldEnd = true;

			//if ((PlayState.arrowSkindad == "NOTE_assets_retro" && PlayState.arrowSkinbf == "NOTE_assets_retrobf"))
			//{
			//	switch (noteData)
			//	{
			//		case 0: specialOffsetX += 5;
			//		case 3: specialOffsetX += 5;
			//		case 1: specialOffsetX += 9;
			//		case 2: specialOffsetX += 8;
			//	}
			//}

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(dataColor[prevNote.originColor % 4] + 'hold');
				prevNote.isHoldEnd = false;

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(PlayState.instance != null)
				{
					prevNote.scale.y *= PlayState.instance.songSpeed;
				}

				if(PlayState.isPixelStage) {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); //Auto adjust note size
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if(PlayState.isPixelStage) {
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
		} else if(!isSustainNote) {
			earlyHitMult = 1;
		}
	}

	public function reloadNoteInfo() {
		if(texture == "NOTE_assets_retro") {
			forceDisableQuant = true;
			quantEnabled = false;
			offsetAngleQuant = 0;
		}
	}

	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	var lastNoteScaleToo:Float = 1;
	public var originalHeightForCalcs:Float = 6;
	public function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '') {
		if(prefix == null) prefix = '';
		if(texture == null) texture = '';
		if(suffix == null) suffix = '';

		var skin:String = texture;
		if(texture.length < 1) {
			if(PlayState.SONG != null) {
				if (mustPress)
					skin = PlayState.arrowSkinbf;
				else
					skin = PlayState.arrowSkindad;
			}
			if(skin == null || skin.length < 1) {
				skin = 'NOTE_assets';
			}
		}

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length-1] = prefix + arraySkin[arraySkin.length-1] + suffix;

		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');
		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'));
				width = width / 4;
				height = height / 2;
				originalHeightForCalcs = height;
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'), true, Math.floor(width), Math.floor(height));
			} else {
				loadGraphic(Paths.image('pixelUI/' + blahblah));
				width = width / 4;
				height = height / 5;
				loadGraphic(Paths.image('pixelUI/' + blahblah), true, Math.floor(width), Math.floor(height));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;

			if(isSustainNote) {
				offsetX += lastNoteOffsetXForPixelAutoAdjusting;
				lastNoteOffsetXForPixelAutoAdjusting = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= lastNoteOffsetXForPixelAutoAdjusting;

				/*if(animName != null && !animName.endsWith('end'))
				{
					lastScaleY /= lastNoteScaleToo;
					lastNoteScaleToo = (6 / height);
					lastScaleY *= lastNoteScaleToo;
				}*/
			}
		} else {
			frames = Paths.getSparrowAtlas(blahblah);
			if(this.texture == null || this.texture == "") {
				@:bypassAccessor this.texture = blahblah;
			}
			loadNoteAnims();
			antialiasing = ClientPrefs.globalAntialiasing;
		}
		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);

		if(inEditor) {
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}

	function loadNoteAnims() {
		animation.addByPrefix('greenScroll', 'green0');
		animation.addByPrefix('redScroll', 'red0');
		animation.addByPrefix('blueScroll', 'blue0');
		animation.addByPrefix('purpleScroll', 'purple0');

		if (isSustainNote)
		{
			animation.addByPrefix('purpleholdend', 'pruple end hold');
			animation.addByPrefix('greenholdend', 'green hold end');
			animation.addByPrefix('redholdend', 'red hold end');
			animation.addByPrefix('blueholdend', 'blue hold end');

			animation.addByPrefix('purplehold', 'purple hold piece');
			animation.addByPrefix('greenhold', 'green hold piece');
			animation.addByPrefix('redhold', 'red hold piece');
			animation.addByPrefix('bluehold', 'blue hold piece');
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if(isSustainNote) {
			animation.add('purpleholdend', [PURP_NOTE + 4]);
			animation.add('greenholdend', [GREEN_NOTE + 4]);
			animation.add('redholdend', [RED_NOTE + 4]);
			animation.add('blueholdend', [BLUE_NOTE + 4]);

			animation.add('purplehold', [PURP_NOTE]);
			animation.add('greenhold', [GREEN_NOTE]);
			animation.add('redhold', [RED_NOTE]);
			animation.add('bluehold', [BLUE_NOTE]);
		} else {
			animation.add('greenScroll', [GREEN_NOTE + 4]);
			animation.add('redScroll', [RED_NOTE + 4]);
			animation.add('blueScroll', [BLUE_NOTE + 4]);
			animation.add('purpleScroll', [PURP_NOTE + 4]);
		}
	}

	function addCustomNote(type:String) {// pain
		switch(type)
		{
			case 'poison':
				frames = Paths.getSparrowAtlas(ClientPrefs.downScroll ? 'PoisonNotes_down' : 'PoisonNotes_up');
				for (i in 0...4)
					animation.addByPrefix(dataColor[i] + 'Scroll', 'PoisonArrows ' + (ClientPrefs.downScroll ? 'Downscroll ' :'Upscroll ') + notedir[i], 24, true);
				if (isSustainNote && prevNote != null)
				{
					addFrames(Paths.getSparrowAtlas('PoisonHold'));
					for (i in 0...4)
					{
						animation.addByPrefix(dataColor[i] + 'holdend', 'hold end');
						animation.addByPrefix(dataColor[i] + 'hold', 'hold piece');
					}
				}
				setGraphicSize(Std.int(width * 0.7));
				//if(ClientPrefs.downScroll) offsetY -= 70;
				playNoteAnim();
			case 'spectre':
				frames = Paths.getSparrowAtlas(ClientPrefs.downScroll ? 'SpectreNoteDownscroll' :'SpectreNote');
				if (isSustainNote && prevNote != null)
				{
					addFrames(Paths.getSparrowAtlas('SpectreNoteTrail'));
					for (i in 0...4)
					{
						animation.addByPrefix(dataColor[i] + 'holdend', 'blue hold end');
						animation.addByPrefix(dataColor[i] + 'hold', 'blue hold piece');
					}
					//animation.play(dataColor[noteData] + 'holdend');
					//if (prevNote.isSustainNote)prevNote.animation.play(dataColor[noteData] + 'hold');
				}
				for (i in 0...4)
					animation.addByPrefix(dataColor[i] + 'Scroll', 'SpecterArrow' + notedir[i]);
				setGraphicSize(Std.int(width * 0.7));
				playNoteAnim();
			case 'iceNote':
				frames = Paths.getSparrowAtlas('iceolation/IceArrow_Assets');
				for (i in 0...4)
					animation.addByPrefix(dataColor[i] + 'Scroll', 'Ice Arrow ' + notedir[i].toUpperCase());
				setGraphicSize(Std.int(width * 0.66));
				playNoteAnim();
			case 'sakuNote':
				frames = Paths.getSparrowAtlas('NOTE_heart');
				for (i in 0...4)
					animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + '0');
				setGraphicSize(Std.int(width * 0.6));
				playNoteAnim();
				switch(noteData) {
					case 0: offsetAngle = 90;
					case 2: offsetAngle = 180;
					case 3: offsetAngle = -90;
				}
		}
		updateHitbox();
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			// ok river
			if (strumTime > Conductor.songPosition - ((Conductor.safeZoneOffset * lateHitMult) * hittime)
				&& strumTime < Conductor.songPosition + ((Conductor.safeZoneOffset * earlyHitMult) * hittime))
				{canBeHit = true; }//color = 0xff00ff00;}
			else
				{canBeHit = false;}//color = 0xffffffff;}

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			{
				if((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}

	/**
	* Changes the noteData to the value passed in and redoes the x position calculations.
	*
	* @param	noteDir			The value of the note to change to. Left = 0 | Down = 1 | Up = 2 | Right = 3
	*/
	public function changeNoteDirection(noteDir:Int)//(shadow): recoded this cus it was a mess lul
	{
		//x = 50; // Some hard-coded value I guess?? I don't wanna break anything
		//x += swagWidth * noteDir;
		if(quantEnabled) {
			originColor = quantColor;
		} else {
			originColor = noteDir % 4;
		}
		noteData = noteDir;
		playNoteAnim();
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

	override function destroy() {
		super.destroy();
		parent = null;
		children = null;
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
