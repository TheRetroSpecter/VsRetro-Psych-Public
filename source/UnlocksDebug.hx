package;

import options.Option;
import options.BaseOptionsMenu;
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

class UnlocksDebug extends BaseOptionsMenu
{
	public function new()
	{
		doRPC = false;
		hasBG = false;
		title = 'Unlock Debug Screen';
		//rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Debug Unlock All Songs', '', '', 'bool', Unlocks.debugAllSongs);
		option.onSet = (variable:String, value:Dynamic) -> {
			Unlocks.debugAllSongs = value;
		};
		option.onGet = (variable:String) -> {
			return Unlocks.debugAllSongs;
		};
		option.fontColor = 0xFFFFFF;
		addOption(option);

		var option:Option = new Option('Clear Unlocked Songs', '', '', 'bool', false);
		option.onSet = (variable:String, value:Dynamic) -> {
			Unlocks.unlockedSongs = ["retro"];
		};
		option.onGet = (variable:String) -> {
			return Unlocks.unlockedSongs.join("|") == "retro";
		};
		option.fontColor = 0xFFFFFF;
		addOption(option);

		var option:Option = new Option('Reset Progress', '', '', 'bool', Unlocks.isReset);
		option.onSet = (variable:String, value:Dynamic) -> {
			Unlocks.resetProgress();
		};
		option.onGet = (variable:String) -> {
			return Unlocks.isReset;
		};
		option.fontColor = 0xFF0000;
		addOption(option);

		for(gf in Unlocks.allGfs) {
			var option:Option = new Option('GF ' + gf, '', gf, 'bool', Unlocks.unlockedGfs.contains(gf));
			option.onSet = (variable:String, value:Dynamic) -> {
				Unlocks.unlockedGfs.remove(variable);
				if(value == true) {
					Unlocks.unlockedGfs.push(variable);
				}
				Unlocks.fixOrder();
			};
			option.onGet = (variable:String) -> {
				return Unlocks.unlockedGfs.contains(variable);
			};
			option.fontColor = 0xFFFFFF;
			addOption(option);
		}

		for(bf in Unlocks.allBfs) {
			var option:Option = new Option('BF ' + bf, '', bf, 'bool', Unlocks.unlockedBfs.contains(bf));
			option.onSet = (variable:String, value:Dynamic) -> {
				Unlocks.unlockedBfs.remove(variable);
				if(value == true) {
					Unlocks.unlockedBfs.push(variable);
				}
				Unlocks.fixOrder();
			};
			option.onGet = (variable:String) -> {
				return Unlocks.unlockedBfs.contains(variable);
			};
			option.fontColor = 0xFFFFFF;
			addOption(option);
		}

		for(foe in Unlocks.allFoes) {
			var option:Option = new Option('FOE ' + foe, '', foe, 'bool', Unlocks.unlockedFoes.contains(foe));
			option.onSet = (variable:String, value:Dynamic) -> {
				Unlocks.unlockedFoes.remove(variable);
				if(value == true) {
					Unlocks.unlockedFoes.push(variable);
				}
				Unlocks.fixOrder();
			};
			option.onGet = (variable:String) -> {
				return Unlocks.unlockedFoes.contains(variable);
			};
			option.fontColor = 0xFFFFFF;
			addOption(option);
		}

		for(mode in Unlocks.allModes) {
			var option:Option = new Option('Mode ' + mode, '', mode, 'bool', Unlocks.unlockedModes.contains(mode));
			option.onSet = (variable:String, value:Dynamic) -> {
				Unlocks.unlockedModes.remove(variable);
				if(value == true) {
					Unlocks.unlockedModes.push(variable);
				}
				Unlocks.fixOrder();
			};
			option.onGet = (variable:String) -> {
				return Unlocks.unlockedModes.contains(variable);
			};
			option.fontColor = 0xFFFFFF;
			addOption(option);
		}

		for(week in Unlocks.allWeeks) {
			var option:Option = new Option('Week ' + week, '', week, 'bool', Unlocks.unlockedWeeks.contains(week));
			option.onSet = (variable:String, value:Dynamic) -> {
				Unlocks.unlockedWeeks.remove(variable);
				if(value == true) {
					Unlocks.unlockedWeeks.push(variable);
				}
				Unlocks.fixOrder();
			};
			option.onGet = (variable:String) -> {
				return Unlocks.unlockedWeeks.contains(variable);
			};
			option.fontColor = 0xFFFFFF;
			addOption(option);
		}

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
}