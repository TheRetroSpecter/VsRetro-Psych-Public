package options;

import shaders.WrathShader;
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

class BaseOptionsMenu extends MusicBeatSubstate
{
	public var curOption:Option = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Option>;
	private var optionsMap:Map<String, Option>;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var boyfriend:Character = null;
	private var descBox:FlxSprite;
	private var descText:FlxText;

	public var title:String;
	public var rpcTitle:String;
	public var doRPC:Null<Bool>;

	public var hasBG:Null<Bool>;

	public function getSetting(id:String) {
		if(optionsMap.exists(id)) {
			return optionsMap.get(id);
		}
		return null;
	}

	public function new()
	{
		super();

		if(title == null) title = 'Options';
		if(rpcTitle == null) rpcTitle = 'Options Menu';
		if(doRPC == null) doRPC = true;
		if(hasBG == null) hasBG = true;

		#if desktop
		if(doRPC) {
			DiscordClient.changePresence(rpcTitle, null);
		}
		#end

		if(hasBG) {
			var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuOptions'));
			//bg.color = 0xFF09F25E;
			bg.setGraphicSize(Std.int(bg.width * 0.6));
			bg.screenCenter();
			bg.antialiasing = ClientPrefs.globalAntialiasing;
			bg.scrollFactor.set();
			add(bg);
		}

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);

		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		descBox.scrollFactor.set();
		add(descBox);

		var titleText:Alphabet = new Alphabet(0, 0, title, true, false, 0, 0.6);
		titleText.x += 60;
		titleText.y += 40;
		titleText.alpha = 0.4;
		titleText.scrollFactor.set();
		add(titleText);

		descText = new FlxFixedText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(0, 70 * i, optionsArray[i].name, optionsArray[i].isHeader, false);
			optionText.isMenuItem = true;
			optionText.fontColor = optionsArray[i].fontColor;
			optionText.x += 300;
			/*optionText.forceX = 300;
			optionText.yMult = 90;*/
			optionText.xAdd = 200;
			optionText.targetY = i;
			optionText.scrollFactor.set();
			optionsArray[i].setStatic(optionText);
			grpOptions.add(optionText);

			if(optionsArray[i].isHeader) {
				optionText.yAdd = 100;
			}

			if(optionsArray[i].type == 'bool') {
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
				checkbox.sprTracker = optionText;
				checkbox.ID = i;
				checkbox.scrollFactor.set();
				checkboxGroup.add(checkbox);
				optionsArray[i].setCheckbox(checkbox);
			} else {
				optionText.x -= 80;
				optionText.xAdd -= 80;
				var valueText:AttachedText = new AttachedText('' + optionsArray[i].getValue(), optionText.width + 80);
				valueText.sprTracker = optionText;
				valueText.fontColor = optionsArray[i].fontColor;
				valueText.copyAlpha = true;
				valueText.ID = i;
				valueText.scrollFactor.set();
				grpTexts.add(valueText);
				optionsArray[i].setChild(valueText);
			}

			if(optionsArray[i].showBoyfriend && boyfriend == null)
			{
				reloadBoyfriend();
			}
			updateTextFrom(optionsArray[i]);
		}

		changeSelection();
		reloadCheckboxes();
	}

	public function addOption(option:Option) {
		if(optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);

		if(option.id != "") {
			if(optionsMap == null) optionsMap = [];
			optionsMap.set(option.id, option);
		}
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;
	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		if (controls.BACK) {
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept <= 0)
		{
			var usesCheckbox = true;
			if(curOption.type != 'bool')
			{
				usesCheckbox = false;
			}

			if(usesCheckbox)
			{
				if(controls.ACCEPT && !curOption.disabled)
				{
					if(curOption.playSound) {
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
					curOption.setValue((curOption.getValue() == true) ? false : true);
					curOption.change();
					reloadCheckboxes();
				}
			} else {
				if(!curOption.disabled && (controls.UI_LEFT || controls.UI_RIGHT)) {
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
					if(holdTime > 0.5 || pressed) {
						if(pressed) {
							var add:Dynamic = null;
							if(curOption.type != 'string') {
								add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
							}

							switch(curOption.type)
							{
								case 'int' | 'float' | 'percent':
									holdValue = curOption.getValue() + add;
									if(holdValue < curOption.minValue) holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

									switch(curOption.type)
									{
										case 'int':
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);

										case 'float' | 'percent':
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
									}

								case 'string':
									var num:Int = curOption.curOption; //lol
									if(controls.UI_LEFT_P) --num;
									else num++;

									if(num < 0) {
										num = curOption.options.length - 1;
									} else if(num >= curOption.options.length) {
										num = 0;
									}

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]); //lol
									//trace(curOption.options[num]);
							}
							updateTextFrom(curOption);
							curOption.change();
							if(curOption.playSound) {
								FlxG.sound.play(Paths.sound('scrollMenu'));
							}
						} else if(curOption.type != 'string') {
							holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
							if(holdValue < curOption.minValue) holdValue = curOption.minValue;
							else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

							switch(curOption.type)
							{
								case 'int':
									curOption.setValue(Math.round(holdValue));
								
								case 'float' | 'percent':
									curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));
							}
							updateTextFrom(curOption);
							curOption.change();
						}
					}

					if(curOption.type != 'string') {
						holdTime += elapsed;
					}
				} else if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					clearHold();
				}
			}

			if(controls.RESET)
			{
				for (i in 0...optionsArray.length)
				{
					var leOption:Option = optionsArray[i];
					leOption.setValue(leOption.defaultValue);
					if(leOption.type != 'bool')
					{
						if(leOption.type == 'string')
						{
							leOption.curOption = leOption.options.indexOf(leOption.getValue());
						}
						updateTextFrom(leOption);
					}
					leOption.change();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if(boyfriend != null && boyfriend.animation.curAnim.finished) {
			boyfriend.dance();
			onDance();
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function onDance() {

	}

	function updateTextFrom(option:Option) {
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == 'percent') val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold()
	{
		if(holdTime > 0.5) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		holdTime = 0;
	}

	function isUnselectable() {
		return optionsArray[curSelected].isHeader;
	}

	public function updateAlpha() {
		var i:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = i - curSelected;

			if (item.targetY == 0) {
				item.alpha = 1 * optionsArray[i].alphaMul;
			} else {
				item.alpha = 0.6 * optionsArray[i].alphaMul;
			}

			i++;
		}

		i = 0;

		for (text in grpTexts) {
			if(text.ID == curSelected) {
				text.alpha = 1 * optionsArray[i].alphaMul;
			} else {
				text.alpha = 0.6 * optionsArray[i].alphaMul;
			}

			i++;
		}
	}
	
	function changeSelection(change:Int = 0)
	{
		var oldCur = curSelected;
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = optionsArray.length - 1;
			if (curSelected >= optionsArray.length)
				curSelected = 0;
		} while(isUnselectable());

		optionsArray[oldCur].unselect();

		var option = optionsArray[curSelected];

		if(option.description != "") {
			descText.text = option.description;
			descText.screenCenter(Y);
			descText.y += 270;
	
			descBox.setPosition(descText.x - 10, descText.y - 10);
			descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
			descBox.updateHitbox();

			descBox.exists = true;
			descText.exists = true;
		} else {
			descBox.exists = false;
			descText.exists = false;
		}

		updateAlpha();

		if(boyfriend != null)
		{
			boyfriend.visible = option.showBoyfriend;
		}
		option.select();
		curOption = option; //shorter lol
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	public function reloadBoyfriend()
	{
		var wasVisible:Bool = false;
		if(boyfriend != null) {
			wasVisible = boyfriend.visible;
			boyfriend.kill();
			remove(boyfriend);
			boyfriend.destroy();
		}

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.wrath = null;
		boyfriend.wrathChrom = null;
		boyfriend.chrom = null;
		boyfriend.hasChromatic = false;
		boyfriend.shader = ClientPrefs.shaders ? new WrathShader(WRATH) : null;
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		insert(1, boyfriend);
		boyfriend.visible = wasVisible;
	}

	function reloadCheckboxes() {
		for (checkbox in checkboxGroup) {
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
		}
	}
}