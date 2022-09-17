package;

import flixel.util.FlxColor;
import shaders.ChromaticAberrationShader;
import shaders.WrathShaderChromatic;
import shaders.WrathShader;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxPoint;
import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.FlxCamera;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var ?extraImages:Array<String>;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;
	var ?forceDance:Bool;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;

	var ?hasChromatic:Bool;
	var ?chromIntensity:Float;
	var ?danceChromatic:Float;
	var ?wrath:WrathSet;
	var ?disableWrath:Bool;
}

typedef WrathSet = {
	var ?wrath:WrathConfig;
	var ?suntime:WrathConfig;
	var ?night:WrathConfig;
}

typedef WrathConfig = {
	var ?dir:Float;
	var ?overlay:Float;
	var ?distance:Float;
	var ?choke:Float;
	var ?power:Float;
	var ?screen:Float;

	var ?shadeColor:String;
	var ?overlayColor:String;
	var ?screenColor:String;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var ?scale:Float;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Float>;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Float>>;
	public var animScales:Map<String, Float>;
	public var debugMode:Bool = false;

	public var characterScale:FlxPoint = new FlxPoint(1, 1);

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var forceDance:Bool = false;

	// Shader effects
	public var hasChromatic:Bool = false;
	public var chrom:ChromaticAberrationShader;
	public var chromIntensity:Float = 0;
	public var danceChromatic:Float = 0;

	// Light effect for wrath
	public var wrath:WrathShader;
	public var wrathChrom:WrathShaderChromatic;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	//Used on Character Editor
	public var imageFile:String = '';
	public var extraImages:Array<String> = [];
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];
	public var shaderEnabled:Bool = true;

	public var isGF:Bool = false;

	public static function doesCharExist(char:String) {
		var characterPath:String = 'characters/' + char + '.json';

		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getPreloadPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getPreloadPath(characterPath);
		if (!Assets.exists(path))
		#end
		{
			return false;
		}

		return true;
	}

	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place
	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Float>>();
		#end
		animScales = new Map<String, Float>();
		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;

		switch (curCharacter)
		{
			//case 'your character name in case you want to hardcode them instead':

			default:
				var characterPath:String = 'characters/' + curCharacter + '.json';

				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path)) {
					path = Paths.getPreloadPath(characterPath);
				}

				if (!FileSystem.exists(path))
				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:CharacterFile = cast Json.parse(rawJson);
				frames = getImage(json.image);
				if(json.extraImages != null) {
					var images:Array<String> = cast json.extraImages;
					extraImages = images;
					for (image in images) {
						addFrames(getImage(image));
					}
				}

				imageFile = json.image;

				if(json.scale != 1) {
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					characterScale.set(jsonScale, jsonScale);
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;
				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

				if(json.forceDance != null) forceDance = json.forceDance;

				hasChromatic = false;
				if(json.hasChromatic != null) hasChromatic = json.hasChromatic;
				if(!ClientPrefs.shaders || !ClientPrefs.chromatic) hasChromatic = false;

				if(hasChromatic) {
					if(json.chromIntensity != null) {
						chromIntensity = json.chromIntensity;
					}
					if(json.danceChromatic != null) {
						danceChromatic = json.danceChromatic;
					}
				}

				var disableWrath = false;
				if(json.disableWrath != null) disableWrath = json.disableWrath;
				if(!ClientPrefs.shaders) disableWrath = true;
				if(!ClientPrefs.wrathShader) disableWrath = true;

				if(!disableWrath && PlayState.currentWrath != "") {
					if(hasChromatic) {
						wrathChrom = new WrathShaderChromatic();
						wrathChrom.trackedSprite = this;
						shader = wrathChrom; // Equip Chrom

						wrathChrom.rOffset.value = [0, 0];
						wrathChrom.gOffset.value = [0, 0];
						wrathChrom.bOffset.value = [0, 0];
					} else {
						wrath = new WrathShader(WrathShader.fromString(PlayState.currentWrath));
						wrath.trackedSprite = this;
						shader = wrath;
					}

					if(json.wrath != null) {
						var ae = PlayState.currentWrath;
						if(ae == "corruptro") ae = "wrath";
						if(Reflect.hasField(json.wrath, ae)) {
							var config:WrathConfig = Reflect.field(json.wrath, ae);

							if(config != null) { // Failsafe
								if(config.dir != null) {
									if(hasChromatic)
										wrathChrom.direction = config.dir;
									else
										wrath.direction = config.dir;
								}

								if(config.overlay != null) {
									if(hasChromatic)
										wrathChrom.overlay = config.overlay;
									else
										wrath.overlay = config.overlay;
								}

								if(config.distance != null) {
									if(hasChromatic)
										false;//wrathChrom.distance = config.distance;
									else
										wrath.distance = config.distance;
								}

								if(config.choke != null) {
									if(hasChromatic)
										false;//wrathChrom.choke = config.choke;
									else
										wrath.choke = config.choke;
								}

								if(config.power != null) {
									if(hasChromatic)
										false;//wrathChrom.power = config.power;
									else
										wrath.power = config.power;
								}

								if(config.screen != null) {
									if(hasChromatic)
										false;//wrathChrom.screen = config.screen;
									else
										wrath.screenOpacity = config.screen;
								}

								if(config.shadeColor != null) {
									if(hasChromatic)
										false;//wrathChrom.shadeColor = FlxColor.fromString(config.shadeColor);
									else
										wrath.shadeColor = FlxColor.fromString(config.shadeColor);
								}

								if(config.overlayColor != null) {
									if(hasChromatic)
										false;//wrathChrom.overlayColor = FlxColor.fromString(config.overlayColor);
									else
										wrath.overlayColor = FlxColor.fromString(config.overlayColor);
								}

								if(config.screenColor != null) {
									if(hasChromatic)
										false;//wrathChrom.screenColor = FlxColor.fromString(config.screenColor);
									else
										wrath.screenColor = FlxColor.fromString(config.screenColor);
								}
							}
						}
					}
				} else {
					if(hasChromatic) {
						chrom = new ChromaticAberrationShader();
						shader = chrom; // Equip Chrom

						chrom.rOffset.value = [0, 0];
						chrom.gOffset.value = [0, 0];
						chrom.bOffset.value = [0, 0];
					}
				}

				if(json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = !noAntialiasing;
				if(!ClientPrefs.globalAntialiasing) antialiasing = false;

				animationsArray = json.animations;
				if(animationsArray != null && animationsArray.length > 0) {
					for (anim in animationsArray) {
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; //Bruh
						var animIndices:Array<Int> = anim.indices;
						if(animIndices != null && animIndices.length > 0) {
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						} else {
							animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}

						if(anim.offsets != null && anim.offsets.length > 1) {
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						}

						if(anim.scale != null) {
							addScale(anim.anim, anim.scale);
						}
					}
				} else {
					quickAnimAdd('idle', 'BF idle dance');
				}
				//trace('Loaded file to character ' + curCharacter);
		}
		originalFlipX = flipX;

		if(animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		isGF = curCharacter.startsWith('gf');

		if (isPlayer)
		{
			flipX = !flipX;

			/*// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf'))
			{
				// var animArray
				if(animation.getByName('singLEFT') != null && animation.getByName('singRIGHT') != null)
				{
					var oldRight = animation.getByName('singRIGHT').frames;
					animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
					animation.getByName('singLEFT').frames = oldRight;
				}

				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singLEFTmiss') != null && animation.getByName('singRIGHTmiss') != null)
				{
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldMiss;
				}
			}*/
		}
	}

	function getImage(imageName:String) {
		var spriteType = "sparrow";

		#if MODS_ALLOWED
		var modTxtToFind:String = Paths.modsTxt(imageName);
		var txtToFind:String = Paths.getPath('images/' + imageName + '.txt', TEXT);

		if (FileSystem.exists(modTxtToFind) || FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
		#else
		if (Assets.exists(Paths.getPath('images/' + imageName + '.txt', TEXT)))
		#end
		{
			spriteType = "packer";
		}

		#if MODS_ALLOWED
		var modAnimToFind:String = Paths.modFolders('images/' + imageName + '/Animation.json');
		var animToFind:String = Paths.getPath('images/' + imageName + '/Animation.json', TEXT);

		if (FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
		#else
		if (Assets.exists(Paths.getPath('images/' + imageName + '/Animation.json', TEXT)))
		#end
		{
			spriteType = "texture";
		}

		return switch (spriteType) {
			case "packer": Paths.getPackerAtlas(imageName);
			case "texture": AtlasFrameMaker.construct(imageName);
			case "sparrow": Paths.getSparrowAtlas(imageName, null, ClientPrefs.textureCompression);
			default: Paths.getSparrowAtlas(imageName);
		}
	}

	function addFrames(otherFrames:FlxFramesCollection, reload:Bool = true) {
		if(otherFrames == null) return;

		for(frame in otherFrames.frames) {
			this.frames.pushFrame(frame);
		}

		if(reload) {
			this.frames = this.frames;
		}
	}

	override function update(elapsed:Float)
	{
		if(!debugMode && animation.curAnim != null)
		{
			if(heyTimer > 0)
			{
				heyTimer -= elapsed;
				if(heyTimer <= 0)
				{
					if(specialAnim && (animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer'))
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if(specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			if (isGF && animation.curAnim.name.startsWith('hair') && animation.curAnim.finished)
				playAnim('dance' + animation.curAnim.name.substr(4));

			if (!isPlayer)
			{
				if (animation.curAnim.name.startsWith('sing'))
				{
					holdTimer += elapsed;
				}

				if (holdTimer >= Conductor.stepCrochet * 0.001 * singDuration)
				{
					dance();
					holdTimer = 0;
				}
			}

			if(animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
			{
				playAnim(animation.curAnim.name + '-loop');
			}
		}

		if (hasChromatic)
		{
			var chrom = (wrathChrom != null) ? wrathChrom.data : chrom.data;

			// (Arcy) Put Chrom back to normal
			if (chrom.gOffset.value[0] < 0)
			{
				chrom.gOffset.value[0] += 0.01 * elapsed;
			}
			else if (chrom.gOffset.value[0] > 0)
			{
				chrom.gOffset.value[0] = 0;
			}

			if (chrom.bOffset.value[0] > 0)
			{
				chrom.bOffset.value[0] -= 0.01 * elapsed;
			}
			else if (chrom.bOffset.value[0] < 0)
			{
				chrom.bOffset.value[0] = 0;
			}
		}

		super.update(elapsed);
	}

	public function updateWrath() {
		if(wrath != null) {
			wrath.update();
		}
		if(wrathChrom != null) {
			wrathChrom.update();
		}
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(forced:Bool = false)
	{
		if (!debugMode && !specialAnim)
		{
			if(danceIdle)
			{
				if (animation.curAnim == null || !animation.curAnim.name.startsWith('hair'))
				{
					danced = !danced;

					if (danced)
						playAnim('danceRight' + idleSuffix, forced || forceDance);
					else
						playAnim('danceLeft' + idleSuffix, forced || forceDance);
				}
			}
			else if(animation.getByName('idle' + idleSuffix) != null) {
				if (hasChromatic && danceChromatic != 0)
				{
					var chrom = (wrathChrom != null) ? wrathChrom.data : chrom.data;
					// (Arcy) Chrom gets colorful
					chrom.gOffset.value = [-danceChromatic, 0];
					chrom.bOffset.value = [danceChromatic, 0];
				}

				playAnim('idle' + idleSuffix, forced || forceDance);
			}
		}
	}

	public function playAnim(animName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if(hasChromatic && animName != animation.name) {
			var chrom = (wrathChrom != null) ? wrathChrom.data : chrom.data;
			// (Arcy) Chrom gets more colorful
			chrom.gOffset.value = [-chromIntensity, 0];
			chrom.bOffset.value = [chromIntensity, 0];
		}

		specialAnim = false;
		animation.play(animName, Force, Reversed, Frame);

		if (animOffsets.exists(animName))
		{
			var daOffset = animOffsets.get(animName);
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);

		if (animScales.exists(animName))
		{
			var daScale = animScales.get(animName);
			scale.set(daScale * characterScale.x, daScale * characterScale.y);
		}
		else
		{
			scale.set(characterScale.x, characterScale.y);
		}

		if (isGF)
		{
			if (animName == 'singLEFT')
			{
				danced = true;
			}
			else if (animName == 'singRIGHT')
			{
				danced = false;
			}

			else if (animName == 'singUP' || animName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}

		//if(curCharacter == "sakuroma" || curCharacter == "sakuroma-alt") {
		//	danceEveryNumBeats = 1;
		//}

		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function addScale(name:String, scale:Float)
	{
		animScales[name] = scale;
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
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

        camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shaderEnabled ? shader : null);
    }
}
