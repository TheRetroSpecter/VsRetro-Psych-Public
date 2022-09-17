package;

import sys.FileSystem;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxBasic;

import sys.io.File;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import flash.media.Sound;
import lime.media.AudioBuffer;
import haxe.io.Bytes;

import hscript.Parser;
import hscript.Interp;

class OutdatedState extends MusicBeatState
{
	public static var leftState:Bool = false;

	public static var instance:OutdatedState = null;

	public var warnText:FlxFixedText;
	public var loadingText:FlxFixedText;

	public var failedDownload:Bool = false;

	public var customUpdateScreen = false;

	override function create()
	{
		super.create();

		OutdatedState.initHaxeModule();

		customUpdateScreen = FileSystem.exists('updateScreen.hscript');

		if(customUpdateScreen) {
			var str:String = File.getContent('updateScreen.hscript');
			if(str == null) str = 'version = ' + MainMenuState.retroVer + ';';
			try {
				OutdatedState.hscript.execute(str);
			} catch(e:Dynamic) {
				trace('error parsing: ' + e);
			}

			TitleState.updateVersion = OutdatedState.hscript.variables.get('version');
			if(TitleState.updateVersion == null)
				TitleState.updateVersion = MainMenuState.retroVer;
		} else {
			var http = new haxe.Http("https://raw.githubusercontent.com/TheRetroSpecter/VsRetro-Internet-Stuff/main/updateScreen.hscript");

			http.onData = function (data:String)
			{
				try {
					OutdatedState.hscript.execute(data);
				} catch(e:Dynamic) {
					trace('error parsing: ' + e);
				}

				TitleState.updateVersion = OutdatedState.hscript.variables.get('version');
				if(TitleState.updateVersion == null)
					TitleState.updateVersion = MainMenuState.retroVer;
			}

			http.onError = function (error) {
				trace('error: $error');
			}

			http.request();
		}

		//#if LOCAL_UPDATE_FILES
		//leftState = false;
		//#end

		instance = this;

		var bg:FlxSpriteExtra = new FlxSpriteExtra().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		warnText = new FlxFixedText(0, 0, FlxG.width,
			"The build you're playing is outdated (" + MainMenuState.retroVer + "),\n
please update to " + TitleState.updateVersion + "!\n
Press ESCAPE to proceed anyway.\n
\n
Thank you for playing!\n
- Retrospecter Team",
			32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		warnText.screenCenter(Y);
		warnText.y -= 40;
		add(warnText);

		loadingText = new FlxFixedText(0, 620, FlxG.width, "Unable to download Update card!", 24);
		loadingText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER);
		add(loadingText);

		var loadAssets:Map<String, Dynamic> = hscript.variables.get('loadAssets');
		for (file => type in loadAssets)
		{
			trace('Trying to download file: ' + file);
			downloadFile(file, type);
		}
		startLoad();
	}

	var updateFunc:Dynamic = null;
	var onBeatFunc:Dynamic = null;
	var onStepFunc:Dynamic = null;
	public var gottenAssets:Map<String, Dynamic> = new Map<String, Dynamic>();
	function downloadFile(file:String, type:String)
	{
		var http = new haxe.Http(file);
		//var loadAssets:Map<String, Dynamic> = hscript.variables.get('loadAssets');

		var split:Array<String> = file.split('/');
		var filename:String = split[split.length-1];
		http.onBytes = function (data:Bytes)
		{
			switch(type)
			{
				case 'image':
					gottenAssets.set(filename, BitmapData.fromBytes(data));
				case 'sound':
					var audioBuffer:AudioBuffer = AudioBuffer.fromBytes(data);
					gottenAssets.set(filename, Sound.fromAudioBuffer(audioBuffer));
				case 'text':
					gottenAssets.set(filename, data.toString());
			}
			trace('Received: $filename');
		}

		http.onError = function (error) {
			//#if LOCAL_UPDATE_FILES
			switch(type)
			{
				case 'image':
					gottenAssets.set(filename, BitmapData.fromFile(filename));
				case 'sound':
					gottenAssets.set(filename, Sound.fromFile(filename));
				case 'text':
					gottenAssets.set(filename, File.getContent(filename));
			}
			//#end
			trace('error: $error');

			if(gottenAssets.get(filename) == null) failedDownload = true;
		}

		http.request();
	}

	function startLoad()
	{
		if(!failedDownload) {
			trace('Starting load() function');
			warnText.screenCenter(Y);
			loadingText.visible = false;

			var func:Dynamic = hscript.variables.get('load');
			try {
				if(func != null)
					func();
			} catch(e:Dynamic) {
				trace('error running load: ' + e);
			}

			updateFunc = hscript.variables.get('update');
			onBeatFunc = hscript.variables.get('onBeat');
			onStepFunc = hscript.variables.get('onStep');
		}
	}

	override function update(elapsed:Float)
	{
		if (TitleState.introMusic != null && TitleState.introMusic.playing)
			Conductor.songPosition = TitleState.introMusic.time;
		else if (FlxG.sound.music != null)
		{
			Conductor.songPosition = FlxG.sound.music.time;

			// Workaround for missing a beat animation on song loop
			if (Conductor.songPosition == 0)
			{
				beatHit();
			}
		}

		if(updateFunc != null) {
			try {
				updateFunc(elapsed);
			} catch(e:Dynamic) {
				trace('error running update: ' + e);
			}
		}

		if(!leftState) {
			if (controls.ACCEPT || controls.BACK) {
				leftState = true;
				if(controls.ACCEPT)
					CoolUtil.browserLoad(hscript.variables.get('acceptLink'));
				loadingText.visible = false;
				warnText.screenCenter(Y);
			}

			if(controls.ACCEPT)
			{
				var func:Dynamic = hscript.variables.get('onAccept');
				if(func != null) func();
			}
			else if(controls.BACK)
			{
				var func:Dynamic = hscript.variables.get('onBack');
				if(func != null) func();
			}

			if(leftState)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if(hscript.variables.get('instantAccept')) {
					MusicBeatState.switchState(new MainMenuState());
				} else {
					FlxTween.tween(warnText, {alpha: 0}, hscript.variables.get('acceptFade'), {
						onComplete: function (twn:FlxTween) {
							MusicBeatState.switchState(new MainMenuState());
						}
					});
				}
			}
		}

		if(customUpdateScreen && FlxG.keys.justPressed.F5) {
			MusicBeatState.resetState();
			OutdatedState.hscript = null;
			leftState = false;
		}

		super.update(elapsed);
	}

	override function beatHit()
	{
		super.beatHit();

		hscript.variables.set('curBeat', curBeat);

		if(onBeatFunc != null) {
			try {
				onBeatFunc(curBeat);
			} catch(e:Dynamic) {
				trace('error running onBeat: ' + e);
			}
		}
	}

	override function stepHit()
	{
		super.stepHit();

		hscript.variables.set('curStep', curStep);

		if(onStepFunc != null) {
			try {
				onStepFunc(curStep);
			} catch(e:Dynamic) {
				trace('error running onStep: ' + e);
			}
		}
	}

	public static var hscript:HScript;
	public static function initHaxeModule()
	{
		if(hscript == null)
		{
			trace('initializing haxe interp');
			hscript = new HScript();
		}
	}
}

class HScript
{
	public static var parser:Parser = new Parser();
	public var interp:Interp;

	public var variables(get, never):Map<String, Dynamic>;

	public function get_variables()
	{
		return interp.variables;
	}

	public function new()
	{
		interp = new Interp();
		interp.variables.set('FlxG', FlxG);
		interp.variables.set('FlxSprite', FlxSprite);
		interp.variables.set('FlxCamera', FlxCamera);
		interp.variables.set('FlxTimer', FlxTimer);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxColor', FlxColor_Helper);
		interp.variables.set('FlxText', FlxFixedText);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('Paths', Paths);
		interp.variables.set('FlxTextBorderStyle', FlxTextBorderStyle);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('ClientPrefs', ClientPrefs);
		interp.variables.set('Character', Character);
		interp.variables.set('Alphabet', Alphabet);
		interp.variables.set('StringTools', StringTools);
		interp.variables.set('OutdatedState', OutdatedState);
		interp.variables.set('Reflect', Reflect);
		interp.variables.set('state', OutdatedState.instance);
		//interp.variables.set('FlxAtlasFrames', flixel.graphics.frames.FlxAtlasFrames);

		interp.variables.set('add', function(obj:FlxBasic)
		{
			OutdatedState.instance.add(obj);
		});
		interp.variables.set('insert', function(pos:Int, obj:FlxBasic)
		{
			OutdatedState.instance.insert(pos, obj);
		});
		interp.variables.set('remove', function(obj:FlxBasic)
		{
			OutdatedState.instance.remove(obj);
		});
		interp.variables.set('getDownloadedAsset', function(name:String)
		{
			return OutdatedState.instance.gottenAssets.get(name);
		});
		interp.variables.set('importLibrary', function(libName:String, ?libPackage:String = '')
		{
			var str:String = '';
			if(libPackage.length > 0)
				str = libPackage + '.';

			interp.variables.set(libName, Type.resolveClass(str + libName));
		});

		interp.variables.set('loadAssets', new Map<String, Dynamic>());
		interp.variables.set('acceptLink', "https://gamebanana.com/mods/317366");
		interp.variables.set('instantAccept', false);
		interp.variables.set('acceptFade', 1);
		interp.variables.set('IMAGE', 'image');
		interp.variables.set('IMG', 'image');
		interp.variables.set('SPRITE', 'image');
		interp.variables.set('SPR', 'image');
		interp.variables.set('TEXT', 'text');
		interp.variables.set('TXT', 'text');
		interp.variables.set('SOUND', 'sound');
		interp.variables.set('SND', 'sound');
		interp.variables.set('AUDIO', 'sound');
		interp.variables.set('MUSIC', 'sound');

		interp.variables.set('LEFT', 'left');
		interp.variables.set('RIGHT', 'right');
		interp.variables.set('JUSTIFY', 'justify');
		interp.variables.set('CENTER', 'center');

		interp.variables.set('OUTLINE', FlxTextBorderStyle.OUTLINE);
		interp.variables.set('OUTLINE_FAST', FlxTextBorderStyle.OUTLINE_FAST);
		interp.variables.set('SHADOW', FlxTextBorderStyle.SHADOW);
		interp.variables.set('TEXT_NONE', FlxTextBorderStyle.NONE);

		interp.variables.set('curBeat', 0);
		interp.variables.set('curStep', 0);
	}

	public function execute(codeToRun:String):Dynamic
	{
		@:privateAccess
		HScript.parser.line = 1;
		HScript.parser.allowTypes = true;
		return interp.execute(HScript.parser.parseString(codeToRun));
	}
}

// Taken from Yoshi Engine
class FlxColor_Helper {
    var fc:FlxColor;

    public var color(get, null):Int;
    public function get_color():Int {
        return fc;
    }

    public var alpha(get, set):Int;
    public function get_alpha():Int {return fc.alpha;}
    public function set_alpha(obj:Int):Int {return fc.alpha = obj;}

    public var alphaFloat(get, set):Float;
    public function get_alphaFloat():Float {return fc.alphaFloat;}
    public function set_alphaFloat(obj:Float):Float {return fc.alphaFloat = obj;}

    public var black(get, set):Float;
    public function get_black():Float {return fc.black;}
    public function set_black(obj:Float):Float {return fc.black = obj;}

    public var blue(get, set):Int;
    public function get_blue():Int {return fc.blue;}
    public function set_blue(obj:Int):Int {return fc.blue = obj;}

    public var blueFloat(get, set):Float;
    public function get_blueFloat():Float {return fc.blueFloat;}
    public function set_blueFloat(obj:Float):Float {return fc.blueFloat = obj;}

    public var brightness(get, set):Float;
    public function get_brightness():Float {return fc.brightness;}
    public function set_brightness(obj:Float):Float {return fc.brightness = obj;}

    public var cyan(get, set):Float;
    public function get_cyan():Float {return fc.cyan;}
    public function set_cyan(obj:Float):Float {return fc.cyan = obj;}

    public var green(get, set):Int;
    public function get_green():Int {return fc.green;}
    public function set_green(obj:Int):Int {return fc.green = obj;}

    public var greenFloat(get, set):Float;
    public function get_greenFloat():Float {return fc.greenFloat;}
    public function set_greenFloat(obj:Float):Float {return fc.greenFloat = obj;}

    public var hue(get, set):Float;
    public function get_hue():Float {return fc.hue;}
    public function set_hue(obj:Float):Float {return fc.hue = obj;}

    public var lightness(get, set):Float;
    public function get_lightness():Float {return fc.lightness;}
    public function set_lightness(obj:Float):Float {return fc.lightness = obj;}

    public var magenta(get, set):Float;
    public function get_magenta():Float {return fc.magenta;}
    public function set_magenta(obj:Float):Float {return fc.magenta = obj;}

    public var red(get, set):Int;
    public function get_red():Int {return fc.red;}
    public function set_red(obj:Int):Int {return fc.red = obj;}

    public var redFloat(get, set):Float;
    public function get_redFloat():Float {return fc.redFloat;}
    public function set_redFloat(obj:Float):Float {return fc.redFloat = obj;}

    public var saturation(get, set):Float;
    public function get_saturation():Float {return fc.saturation;}
    public function set_saturation(obj:Float):Float {return fc.saturation = obj;}

    public var yellow(get, set):Float;
    public function get_yellow():Float {return fc.yellow;}
    public function set_yellow(obj:Float):Float {return fc.yellow = obj;}

    public static function add(lhs:Int, rhs:Int):Int {return FlxColor.add(lhs, rhs);}
    public static function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float):FlxColor_Helper {return new FlxColor_Helper(FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha));}
    public static function fromHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha:Float = 1):FlxColor_Helper {return new FlxColor_Helper(FlxColor.fromHSB(Hue, Saturation, Brightness, Alpha));}
    public static function fromHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha:Float = 1):FlxColor_Helper {return new FlxColor_Helper(FlxColor.fromHSL(Hue, Saturation, Lightness, Alpha));}
    public static function fromInt(Value:Int):FlxColor_Helper {return new FlxColor_Helper(Value);}
    public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):FlxColor_Helper {return new FlxColor_Helper(FlxColor.fromRGB(Red, Blue, Green, Alpha));}
    public static function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):FlxColor_Helper {return new FlxColor_Helper(FlxColor.fromRGBFloat(Red, Blue, Green, Alpha));}
    public static function fromString(str:String):Null<FlxColor_Helper> {
        var color = FlxColor.fromString(str);
        if (color == null)
            return null;
        else
            return new FlxColor_Helper(color);
    }
    public function getAnalogousHarmony(Threshold:Int = 30) {return fc.getAnalogousHarmony(Threshold);}
    public function getColorInfo() {return fc.getColorInfo();}
    public function getComplementHarmony() {return fc.getComplementHarmony();}
    public function getDarkened(Factor:Float = 0.2) {return fc.getDarkened(Factor);}
    public function getInverted() {return fc.getInverted();}
    public function getLightened(Factor:Float = 0.2) {return fc.getLightened(Factor);}
    public function getSplitComplementHarmony(Threshold:Int = 30) {return fc.getSplitComplementHarmony(Threshold);}
    public function getTriadicHarmony() {return fc.getTriadicHarmony();}
    public static function gradient(color1:Int, color2:Int, steps:Int, ?ease:Float -> Float) {return FlxColor.gradient(color1, color2, steps, ease);}
    public static function interpolate(color1:Int, color2:Int, Factor:Float = 0.5) {return FlxColor.interpolate(color1, color2, Factor);}
    public static function multiply(color1:Int, color2:Int) {return FlxColor.multiply(color1, color2);}
    public function setCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1) {return fc.setCMYK(Cyan, Magenta, Yellow, Black, Alpha);}
    public function setHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha:Float) {return fc.setHSB(Hue, Saturation, Brightness, Alpha);}
    public function setHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha:Float) {return fc.setHSL(Hue, Saturation, Lightness, Alpha);}
    public function setRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int) {return fc.setRGB(Red, Green, Blue, Alpha);}
    public function setRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float) {return fc.setRGBFloat(Red, Green, Blue, Alpha);}
    public static function substract(color1:Int, color2:Int) {return FlxColor.subtract(color1, color2);}
    public function toHexString(Alpha:Bool = true, Prefix:Bool = true) {return fc.toHexString(Alpha, Prefix);}
    public function toWebString() {return fc.toWebString();}

    public function new(color:Int) {
        fc = new FlxColor(color);
    }

    public static final BLACK = 0xFF000000;
    public static final BLUE = 0xFF0000FF;
    public static final BROWN = 0xFF8B4513;
    public static final CYAN = 0xFF00FFFF;
    public static final GRAY = 0xFF808080;
    public static final GREEN = 0xFF008000;
    public static final LIME = 0xFF00FF00;
    public static final MAGENTA = 0xFFFF00FF;
    public static final ORANGE = 0xFFFFA500;
    public static final PINK = 0xFFFFC0CB;
    public static final PURPLE = 0xFF800080;
    public static final RED = 0xFFFF0000;
    public static final TRANSPARENT = 0x00000000;
    public static final WHITE = 0xFFFFFFFF;
    public static final YELLOW = 0xFFFFFF00;
}