package options;

import flash.text.TextField;
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

using StringTools;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Mechanics',
			'Uncheck this if you just want a standard rhythm game with no added mechanics.',
			'mechanics',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Modcharts',
			'Uncheck this if you just want a normal playthrough without modcharts',
			'modcharts',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Controller Mode',
			'Check this if you want to play with\na controller instead of using your Keyboard.',
			'controllerMode',
			'bool',
			false);
		addOption(option);

		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', //Name
			'If checked, notes go Down instead of Up, simple enough.', //Description
			'downScroll', //Save data variable name
			'bool', //Variable type
			false); //Default value
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			'bool',
			false);
		addOption(option);
		
		var option:Option = new Option('Opponent Notes',
			'If unchecked, opponent notes get hidden.',
			'opponentStrums',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Note Quantization',
			"If checked, notes will be colored based on the song's beat instead of note direction.",
			'noteQuantization',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Open Quant Colors',
			"",
			'',
			'bool',
			false);
		option.onSet = (variable:String, value:Dynamic) -> {
			NotesSubState.isShowingQuant = true;
			openSubState(new options.NotesSubState());
		};
		option.onGet = (variable:String) -> {
			return false;
		};
		option.checkboxVisible = false;
		option.playSound = false;
		addOption(option);


		var option:Option = new Option('Opponent Quants',
			'If checked, the opponent will the quant colors. Only applies if Note Quantization is checked',
			'opponentQuants',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Input System',
			"Which input system the game should use, changes some difficulty",
			'inputSystem',
			'string',
			'Kade',
			['Kade', 'Psych']);
		addOption(option);

		var option:Option = new Option('Health System',
			"Which health system the game should use, changes some difficulty",
			'healthSystem',
			'string',
			'Kade',
			['Kade', 'Psych']);
		addOption(option);

		var option:Option = new Option('Botplay', '', 'botplay', 'bool', false);
		option.onSet = (variable:String, value:Dynamic) -> {
			ClientPrefs.gameplaySettings.set(variable, value);
		};
		option.onGet = (variable:String) -> {
			return ClientPrefs.gameplaySettings.get(variable);
		};
		addOption(option);

		var goption:Option = new Option('Scroll Type', '', 'scrolltype', 'string', 'multiplicative', ["multiplicative", "constant"]);
		goption.onSet = (variable:String, value:Dynamic) -> {
			var soption = getSetting("scrollspeed");
			if(soption != null) {
				if(value == "constant") {
					soption.displayFormat = "%v";
					soption.maxValue = 6;
				}
				else
				{
					soption.displayFormat = "%vX";
					soption.maxValue = 3;
					if(soption.getValue() > 3) soption.setValue(3);
				}
				updateTextFrom(soption);
			}

			ClientPrefs.gameplaySettings.set(variable, value);
		};
		goption.onGet = (variable:String) -> {
			return ClientPrefs.gameplaySettings.get(variable);
		};
		addOption(goption);

		var option:Option = new Option('Scroll Speed', '', 'scrollspeed', 'float', 1);
		option.id = "scrollspeed";
		option.onSet = (variable:String, value:Dynamic) -> {
			ClientPrefs.gameplaySettings.set(variable, value);
		};
		option.onGet = (variable:String) -> {
			return ClientPrefs.gameplaySettings.get(variable);
		};
		option.scrollSpeed = 1.5;
		option.minValue = 0.5;
		option.changeValue = 0.1;
		if (goption.getValue() != "constant")
		{
			option.displayFormat = '%vX';
			option.maxValue = 3;
		}
		else
		{
			option.displayFormat = "%v";
			option.maxValue = 6;
		}
		addOption(option);

		var option:Option = new Option('Disable Reset Button',
			"If checked, pressing Reset won't do anything.",
			'noReset',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Hitsound Volume',
			'Funny notes does \"Tick!\" when you hit them."',
			'hitsoundVolume',
			'percent',
			0);
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;

		var option:Option = new Option('Rating Offset',
			'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.',
			'ratingOffset',
			'int',
			0);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option('Sick! Hit Window',
			'Changes the amount of time you have\nfor hitting a "Sick!" in milliseconds.',
			'sickWindow',
			'int',
			45);
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15;
		option.maxValue = 45;
		addOption(option);

		var option:Option = new Option('Good Hit Window',
			'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.',
			'goodWindow',
			'int',
			90);
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15;
		option.maxValue = 90;
		addOption(option);

		var option:Option = new Option('Bad Hit Window',
			'Changes the amount of time you have\nfor hitting a "Bad" in milliseconds.',
			'badWindow',
			'int',
			135);
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 135;
		addOption(option);

		var option:Option = new Option('Safe Frames',
			'Changes how many frames you have for\nhitting a note earlier or late.',
			'safeFrames',
			'float',
			10);
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		super();
	}
}