package options;

import shaders.ChromaticAberrationShader;
import shaders.WrathShader;
import flash.text.TextField;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import openfl.Lib;

using StringTools;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	public var chrom:ChromaticAberrationShader = new ChromaticAberrationShader();

	public function new()
	{
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', //Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', //Description
			'lowQuality', //Save data variable name
			'bool', //Variable type
			false); //Default value
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'globalAntialiasing',
			'bool',
			true);
		option.showBoyfriend = true;
		option.onSelect = onChangeAntiAliasing;
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate',
			'int',
			60);
		addOption(option);

		option.minValue = 60;
		option.maxValue = 240;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		#end

		var option:Option = new Option('Shaders', '', 'empty', 'string', '', ['']);
		option.isHeader = true;
		option.showBoyfriend = false;
		addOption(option);

		var option:Option = new Option('Shaders',
			'Disables all shaders if unchecked.',
			'shaders',
			'bool',
			true);
		option.showBoyfriend = true;
		option.onSelect = onChangeShaders; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		option.onChange = onChangeShaders; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		var option:Option = new Option('Lighting',
			'If unchecked, disables lighting effects.',
			'wrathShader',
			'bool',
			true);
		option.id = "wrathShader";
		option.showBoyfriend = true;
		option.onSelect = onChangeShaders; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		option.onChange = onChangeShaders; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		var option:Option = new Option('Light Angle Opt',
			'Lower values = More GPU Usage, Higher Value = Less GPU Usage\nIncrease if you\'re lagging.\n(Check task manager > Performance > GPU, in the 3D graph)',
			'wrathAngleOpt',
			'int',
			17);
		option.id = "wrathAngle";
		option.showBoyfriend = true;
		option.minValue = 1;
		option.onSelect = onChangeShaders;
		option.onChange = onChangeShaders; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		var option:Option = new Option('Experimental Light',
			'Reduces GPU usage on specific GPUs.',
			'wrathExperimental',
			'bool',
			true);
		option.showBoyfriend = true;
		option.onSelect = onChangeShaders; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		option.onChange = onChangeShaders; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		var option:Option = new Option('Chromatic',
			'If unchecked, disables chromatic effect.',
			'chromatic',
			'bool',
			true);
		option.id = "chromatic";
		option.showBoyfriend = true;
		option.onSelect = onChangeChromatic; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		option.onChange = onChangeChromatic; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		var option:Option = new Option('Optimized Notes',
			'If checked, fully disables shaders affecting notes.',
			'optimizedNotes',
			'bool',
			false);
		//option.id = "chromatic";
		addOption(option);

		var option:Option = new Option('Precached Deaths',
			'If checked, removes the lag when dying, at the cost of RAM usage',
			'precachedDeaths',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Cached Story',
			'If checked, reduces the time between loading songs, at the cost of more RAM usage and loading time',
			'cacheStory',
			'bool',
			true);
		addOption(option);

		super();
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:Dynamic = sprite; //Make it check for FlxSprite instead of FlxBasic
			var sprite:FlxSprite = sprite; //Don't judge me ok
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.globalAntialiasing;
			}
			boyfriend.shader = null;
		}
	}

	override function update(elapsed:Float) {
		if (chrom != null)
		{
			// (Arcy) Put Chrom back to normal
			if (chrom.gOffset.value[0] < 0)
				chrom.gOffset.value[0] += 0.01 * elapsed;
			else if (chrom.gOffset.value[0] > 0)
				chrom.gOffset.value[0] = 0;

			if (chrom.bOffset.value[0] > 0)
				chrom.bOffset.value[0] -= 0.01 * elapsed;
			else if (chrom.bOffset.value[0] < 0)
				chrom.bOffset.value[0] = 0;
		}
		super.update(elapsed);

		if(wrath != null) {
			wrath.update();
		}
	}

	var wrath:WrathShader;

	function onChangeShaders()
	{
		if(boyfriend != null) {
			if(ClientPrefs.shaders && ClientPrefs.wrathShader) {
				boyfriend.shader = null;
				wrath = new WrathShader(WRATH, ClientPrefs.wrathAngleOpt);
				wrath.trackedSprite = boyfriend;
				boyfriend.shader = wrath;
			}
			else {
				boyfriend.shader = null;
			}
		}

		var option = getSetting("wrathShader");
		if(option != null) option.disabled = !ClientPrefs.shaders;

		var option = getSetting("wrathAngle");
		if(option != null) option.disabled = !ClientPrefs.shaders || !ClientPrefs.wrathShader;

		var option = getSetting("chromatic");
		if(option != null) option.disabled = !ClientPrefs.shaders;

		updateAlpha();
	}

	override function onDance() {
		if (chrom != null)
		{
			chrom.gOffset.value = [-0.002, 0];
			chrom.bOffset.value = [0.002, 0];
		}
	}

	override function reloadCheckboxes()
	{
		super.reloadCheckboxes();
		trace('test');
		if(curOption != null && curOption.onChange != null)
			curOption.onChange();
	}

	function onChangeChromatic()
	{
		if(boyfriend != null) {
			if(ClientPrefs.shaders && ClientPrefs.chromatic) {
				boyfriend.shader = chrom;
			}
			else {
				boyfriend.shader = null;
			}
		}
	}

	#if !html5
	function onChangeFramerate()
	{
		if(ClientPrefs.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.framerate;
			FlxG.drawFramerate = ClientPrefs.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.framerate;
			FlxG.updateFramerate = ClientPrefs.framerate;
		}
	}
	#end
}