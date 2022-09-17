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

class QuickSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		doRPC = false;
		hasBG = false;
		title = 'Quick Settings';
		//rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Botplay', '', 'botplay', 'bool', false);
		option.onSet = (variable:String, value:Dynamic) -> {
			ClientPrefs.gameplaySettings.set(variable, value);
		};
		option.onGet = (variable:String) -> {
			return ClientPrefs.gameplaySettings.get(variable);
		};
		option.fontColor = 0xFFFFFF;
		addOption(option);

		var option:Option = new Option('Downscroll',
			'If checked, notes go Down instead of Up, simple enough.',
			'downScroll',
			'bool',
			false);
		option.fontColor = 0xFFFFFF;
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			'bool',
			false);
		option.fontColor = 0xFFFFFF;
		addOption(option);

		var option:Option = new Option('Background Level',
			"Determines the detail of the backgrounds based on its level.
			0 for no backgrounds, 1 for low detail backgrounds, and 2 for full backgrounds.",
			'background',
			'int',
			2);
		option.maxValue = 2;
		option.minValue = 0;
		option.fontColor = 0xFFFFFF;
		addOption(option);

		var option:Option = new Option('Particles',
			"If checked, all the particles and confetti will be present in the stage.",
			'particles',
			'bool',
			true);
		option.fontColor = 0xFFFFFF;
		addOption(option);

		var option:Option = new Option('Note Quantization',
			"If checked, notes will be colored based on the song's beat instead of note direction.",
			'noteQuantization',
			'bool',
			false);
		option.fontColor = 0xFFFFFF;
		addOption(option);

		//var option:Option = new Option('Open Quant Colors',
		//	"",
		//	'',
		//	'bool',
		//	false);
		//option.onSet = (variable:String, value:Dynamic) -> {
		//	NotesSubState.isShowingQuant = true;
		//	openSubState(new options.NotesSubState());
		//};
		//option.onGet = (variable:String) -> {
		//	return false;
		//};
		//addOption(option);

		var option:Option = new Option('Opponent Quants',
			'If checked, the opponent will the quant colors. Only applies if Note Quantization is checked',
			'opponentQuants',
			'bool',
			true);
		option.fontColor = 0xFFFFFF;
		addOption(option);

		var option:Option = new Option('Mechanics',
			'Uncheck this if you just want a standard rhythm game with no added mechanics.',
			'mechanics',
			'bool',
			true);
		option.fontColor = 0xFFFFFF;
		addOption(option);

		var option:Option = new Option('Modcharts',
			'Uncheck this if you just want a normal playthrough without modcharts',
			'modcharts',
			'bool',
			true);
		option.fontColor = 0xFFFFFF;
		addOption(option);

		var option:Option = new Option('Opponent Noteskins',
			'If unchecked, the opponent\'s notes will use the default Noteskin.',
			'opponentNoteskins',
			'bool',
			true);
		option.fontColor = 0xFFFFFF;
		addOption(option);
		
		var option:Option = new Option('Player Noteskins',
			'If unchecked, your notes will use the default Noteskin.',
			'playerNoteskins',
			'bool',
			true);
		option.fontColor = 0xFFFFFF;
		addOption(option);

		var option:Option = new Option('Shaders',
			'Disables all shaders if unchecked',
			'shaders',
			'bool',
			true);
		option.fontColor = 0xFFFFFF;
		addOption(option);

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate',
			'int',
			60);
		option.fontColor = 0xFFFFFF;
		addOption(option);

		option.minValue = 60;
		option.maxValue = 240;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		#end

		if(#if debug true || #end Unlocks.unlockedModes.contains("randomized")) {
			var option:Option = new Option('Random', '', 'random', 'bool', false);
			option.onSet = (variable:String, value:Dynamic) -> {
				PlayState.randomMode = value;
			};
			option.onGet = (variable:String) -> {
				return PlayState.randomMode;
			};
			option.fontColor = 0xFFFFFF;
			addOption(option);
		}

		if(#if debug true || #end Unlocks.unlockedModes.contains("insta-death")) {
			var option:Option = new Option('Insta Death', '', 'instaDeath', 'bool', false);
			option.onSet = (variable:String, value:Dynamic) -> {
				PlayState.instadeathMode = value;
			};
			option.onGet = (variable:String) -> {
				return PlayState.instadeathMode;
			};
			option.fontColor = 0xFFFFFF;
			addOption(option);
		}

		var option:Option = new Option('Input System',
			"Which input system the game should use, changes some difficulty",
			'inputSystem',
			'string',
			'Kade',
			['Kade', 'Psych']);
		option.fontColor = 0xFFFFFF;
		addOption(option);

		var option:Option = new Option('Health System',
			"Which health system the game should use, changes some difficulty",
			'healthSystem',
			'string',
			'Kade',
			['Kade', 'Psych']);
		option.fontColor = 0xFFFFFF;
		addOption(option);

		#if !final
		var option:Option = new Option('Death Count', "", 'deaths', 'int', 0);
		option.fontColor = 0xFFFFFF;
		option.minValue = 0;
		option.maxValue = 1000;
		option.displayFormat = '%v Deaths';
		option.onSet = (variable:String, value:Int) -> {
			PlayState.deaths = value - 1;
			PlayState.shownHint = true;
		};
		option.onGet = (variable:String) -> {
			return PlayState.deaths + 1;
		};
		addOption(option);
		#end

		super();

		var bg = new FlxSpriteExtra().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.scrollFactor.set();
		insert(0, bg);

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function close() {
		ClientPrefs.saveSettings();
		super.close();
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