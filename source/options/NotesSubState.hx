package options;

import shaders.AmongUsShader;
import flixel.FlxObject;
import flixel.math.FlxPoint;
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

class NotesSubState extends MusicBeatSubstate
{
	private static var curSelected:Int = 0;
	private static var typeSelected:Int = 0;
	private static var defaultColors:Array<Array<Int>> = [
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 0],
	];
	public static var quantColors:Array<Array<Int>> = [
		[0xC24B99, 0x3C1F56], // 4th
		[0x00FFFF, 0x1542B7], // 8th
		[0x12FA05, 0x0A4447], // 12th
		[0xF9393F, 0x651038], // 16th

		[0xC24B99, 0x3C1F56], // 20th
		[0x00FFFF, 0x1542B7], // 24th
		[0x12FA05, 0x0A4447], // 32nd
		[0xF9393F, 0x651038], // 48th

		[0xC24B99, 0x3C1F56], // 64th
		[0x00FFFF, 0x1542B7], // 192nd
	];
	/*private static var foreverColors:Array<Array<Int>> = [
		[30, 10, 0],
		[25, 0, 0],
		[-180, -30, 0],
		[145, 20, 0],
		[0, -100, -40],
		[120, -40, 0],
		[-60, 20, 0],
		[-65, 5, 0],

		[-140, 50, 0], // 64th
		[30, -40, -50], // 192nd
	];*/
	private var grpQuantGuide:FlxTypedGroup<Alphabet>;
	private var grpNumbers:FlxTypedGroup<Alphabet>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;
	private var shaderNormalArray:Array<ColorSwap> = [];
	private var shaderQuantArray:Array<AmongUsShader> = [];
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var nextAccept:Int = 5;
	//var primaryNotes:Bool = true;

	var blackBG:FlxSpriteExtra;
	var hsbText:Alphabet;
	var quantText:FlxFixedText;
	var presetsText:FlxFixedText;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	public static var isShowingQuant:Bool = false;

	var bg:FlxSprite;

	var origCamFollow:FlxPoint = new FlxPoint();

	var posX = 230;
	public function new() {
		super();

		origCamFollow.copyFrom(FlxG.camera.scroll);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		bg = new FlxSprite().loadGraphic(Paths.image('menuOptions'));
		//bg.color = 0xFF09F25E;
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(bg.width * 0.6));
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.active = false;
		add(bg);

		blackBG = new FlxSpriteExtra(posX - 25).makeSolid(870, 200, FlxColor.BLACK);
		blackBG.alpha = 0.4;
		blackBG.active = false;
		add(blackBG);

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);
		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);
		grpQuantGuide = new FlxTypedGroup<Alphabet>();
		add(grpQuantGuide);

		FlxG.camera.follow(camFollowPos, null, 1);

		hsbText = new Alphabet(0, 0, "Hue    Saturation  Brightness", false, false, 0, 0.65);
		hsbText.x = posX + 240;
		add(hsbText);

		quantText = new FlxFixedText(10, FlxG.height - 50, 200, "Press CTRL for quant notes", 20);
		quantText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		quantText.scrollFactor.set(0, 0);
		quantText.active = false;
		add(quantText);

		presetsText = new FlxFixedText(10, FlxG.height - 120, 200, "Press ALT for presets", 20);
		presetsText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		presetsText.scrollFactor.set(0, 0);
		presetsText.active = false;
		add(presetsText);

		loadNotes();

		camFollowPos.setPosition(camFollow.x, camFollow.y);
	}

	var noteCount:Int = 4;

	var spacing:Float = 200;
	var off:Float = 250;

	function loadNotes() {
		var quantAngles = [0, 90, 270, 180];
		var animations:Array<String> = ['purple0', 'blue0', 'green0', 'red0'];
		var quantBeatText:Array<String> = ['4th', '8th', '12th', '16th', '20th', '24th', '32nd', '48th', '64th', '192nd'];

		shaderQuantArray.splice(0, shaderQuantArray.length);
		shaderNormalArray.splice(0, shaderNormalArray.length);
		grpNumbers.clear();
		grpNotes.clear();
		grpQuantGuide.clear();

		//var hsvSet = ClientPrefs.arrowHSV;
		//if(isShowingQuant) hsvSet = ClientPrefs.quantHSV;

		if (isShowingQuant) {
			quantText.text = "Press CTRL for primary notes";
			hsbText.changeText(" R       G       B");
			//hsbText.y = -20
			blackBG.scale.y = 200;
			presetsText.visible = true;
		}
		else
		{
			quantText.text = "Press CTRL for quant notes";
			hsbText.changeText("Hue    Saturation  Brightness");
			blackBG.scale.y = 200;
			presetsText.visible = false;
		}
		blackBG.updateHitbox();

		noteCount = isShowingQuant ? ClientPrefs.quantColors.length : ClientPrefs.arrowHSV.length;

		for (i in 0...noteCount) {
			var yPos:Float = (165 * i) + 35;
			if(isShowingQuant) {
				yPos = (195 * i) + 35;
				for (j in 0...6) {
					var set = ClientPrefs.quantColors[i];
					var color:FlxColor = set[Std.int(j/3)];
					var text = [color.red, color.green, color.blue][j%3];
					var optionText:Alphabet = new Alphabet(0, yPos + 60 - 20 + (70 * Std.int(j/3)), Std.string(text), true);
					optionText.x = posX + (spacing * (j % 3)) + off;
					updateOffset(optionText, text);
					grpNumbers.add(optionText);
				}
			} else {
				for (j in 0...3) {
					var val = ClientPrefs.arrowHSV[i][j];
					var optionText:Alphabet = new Alphabet(0, yPos + 60, Std.string(val), true);
					optionText.x = posX + (225 * j) + 250;
					updateOffset(optionText, val);
					grpNumbers.add(optionText);
				}
			}

			if(isShowingQuant) {
				var quantBeat:Alphabet = new Alphabet(0, yPos + 60, quantBeatText[i], true, false, 0.05, 0.8);
				quantBeat.x = posX - 30 - quantBeat.width;
				grpQuantGuide.add(quantBeat);
			}

			var note:FlxSprite = new FlxSprite(posX, yPos);
			if(isShowingQuant) {
				note.frames = Paths.getSparrowAtlas('NOTE_assets_quant');
			} else {
				note.frames = Paths.getSparrowAtlas('NOTE_assets');
			}
			note.animation.addByPrefix('idle', animations[i % animations.length]);
			note.animation.play('idle');
			note.antialiasing = ClientPrefs.globalAntialiasing;
			if(isShowingQuant) {
				note.angle = quantAngles[i % quantAngles.length];
			}
			grpNotes.add(note);

			if(isShowingQuant) {
				var newShader:AmongUsShader = new AmongUsShader();
				note.shader = newShader;
				newShader.red = ClientPrefs.quantColors[i][0];
				newShader.green = 0xffffff;
				newShader.blue = ClientPrefs.quantColors[i][1];
				shaderQuantArray.push(newShader);
			} else {
				var newShader:ColorSwap = new ColorSwap();
				note.shader = newShader.shader;
				newShader.hue = ClientPrefs.arrowHSV[i][0] / 360;
				newShader.saturation = ClientPrefs.arrowHSV[i][1] / 100;
				newShader.brightness = ClientPrefs.arrowHSV[i][2] / 100;
				shaderNormalArray.push(newShader);
			}
		}

		changeSelection();
	}

	var changingNote:Bool = false;
	override function update(elapsed:Float) {
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if(changingNote) {
			if(holdTime < 0.5) {
				if(controls.UI_LEFT_P) {
					updateValue(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.UI_RIGHT_P) {
					updateValue(1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.RESET) {
					resetValue(curSelected, typeSelected);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					holdTime = 0;
				} else if(controls.UI_LEFT || controls.UI_RIGHT) {
					holdTime += elapsed;
				}
			} else {
				var add:Float = 90;
				switch(typeSelected) {
					case 1 | 2: add = 50;
				}
				if(controls.UI_LEFT) {
					updateValue(elapsed * -add);
				} else if(controls.UI_RIGHT) {
					updateValue(elapsed * add);
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
		} else {
			if (controls.UI_UP_P) {
				changeSelection(-1);
			}
			if (controls.UI_DOWN_P) {
				changeSelection(1);
			}
			if (controls.UI_LEFT_P) {
				changeType(-1);
			}
			if (controls.UI_RIGHT_P) {
				changeType(1);
			}
			if(controls.RESET) {
				var perNums = isShowingQuant ? 6 : 3;
				for (i in 0...perNums) {
					resetValue(curSelected, i);
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (FlxG.keys.justPressed.CONTROL) {
				isShowingQuant = !isShowingQuant;
				if (isShowingQuant) {
					//noteSelected = curSelected;
				}
				else
				{
					if(curSelected > 4) curSelected = 0;
					//noteSelected = curSelected + 4;
				}
				typeSelected = 0;
				loadNotes();
				presetsText.visible = isShowingQuant;
				camFollowPos.setPosition(camFollow.x, camFollow.y);
				//swapNotes();
			}
			if (controls.ACCEPT && nextAccept <= 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changingNote = true;
				quantText.visible = false;
				presetsText.visible = false;
				holdTime = 0;
				var perNums = isShowingQuant ? 6 : 3;
				for (i in 0...grpNumbers.length) {
					var item = grpNumbers.members[i];
					item.alpha = 0;
					if ((curSelected * perNums) + typeSelected == i) {
						item.alpha = 1;
					}
				}
				for (i in 0...grpNotes.length) {
					var item = grpNotes.members[i];
					item.alpha = 0;
					if (curSelected == i) {
						item.alpha = 1;
					}
				}
				super.update(elapsed);
				return;
			}

			if(presetsText.visible) {
				if(FlxG.keys.justPressed.ALT) {
					openSubState(new NotesPresetSubSubState());
				}
			}
		}

		if (controls.BACK || (changingNote && controls.ACCEPT)) {
			if(!changingNote) {
				camFollowPos.setPosition(origCamFollow.x, origCamFollow.y);
				FlxG.camera.follow(null, null, 1);
				FlxG.camera.scroll.copyFrom(origCamFollow);
				close();
			} else {
				changeSelection();
			}
			changingNote = false;
			quantText.visible = true;
			presetsText.visible = isShowingQuant;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0, playSound:Bool = true) {
		if(isShowingQuant && !FlxG.keys.pressed.SHIFT) {
			if(change > 0) {
				if(typeSelected < 3) {
					changeType(3);
					return;
				} else {
					changeType(-3, false);
				}
			} else if(change < 0) {
				if(typeSelected >= 3) {
					changeType(-3);
					return;
				} else {
					changeType(3, false);
				}
			}
		}
		curSelected += change;
		if (curSelected < 0)
			curSelected = noteCount-1;
		if (curSelected >= noteCount)
			curSelected = 0;

		//if (primaryNotes)
		//	noteSelected = curSelected;
		//else
		//	noteSelected = curSelected + 4;

		if(isShowingQuant) {
			var set = ClientPrefs.quantColors[curSelected];
			var color:FlxColor = set[Std.int(typeSelected/3)];

			curValue = [color.red, color.green, color.blue][typeSelected%3];
		} else {
			curValue = ClientPrefs.arrowHSV[curSelected][typeSelected];
		}

		trace(curValue);

		updateValue();

		var perNums = isShowingQuant ? 6 : 3;

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * perNums) + typeSelected == i) {
				item.alpha = 1;
			}
		}
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			item.alpha = 0.6;
			item.scale.set(0.75, 0.75);
			if (curSelected == i) {
				item.alpha = 1;
				item.scale.set(1, 1);
				hsbText.y = item.y - 70 - (isShowingQuant ? 10 : 0);
				blackBG.y = item.y - 20;

				camFollow.setPosition(FlxG.width / 2, item.getGraphicMidpoint().y);
			}
		}

		if(playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeType(change:Int = 0, playSound:Bool = true) {
		var perNums = isShowingQuant ? 6 : 3;

		typeSelected += change;
		if (typeSelected < 0)
			typeSelected = perNums-1;
		if (typeSelected > perNums-1)
			typeSelected = 0;

		if(isShowingQuant) {
			var set = ClientPrefs.quantColors[curSelected];
			var color:FlxColor = set[Std.int(typeSelected/3)];

			curValue = [color.red, color.green, color.blue][typeSelected%3];
		} else {
			curValue = ClientPrefs.arrowHSV[curSelected][typeSelected];
		}
		trace(curValue);
		updateValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * perNums) + typeSelected == i) {
				item.alpha = 1;
			}
		}

		if(playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function resetValue(selected:Int, type:Int) {
		if(isShowingQuant) {
			var rbI = Std.int(type/3);
			var color:FlxColor = quantColors[selected][rbI];
			curValue = [color.red, color.green, color.blue][type%3];

			var red:FlxColor = ClientPrefs.quantColors[selected][0];
			var blue:FlxColor = ClientPrefs.quantColors[selected][1];

			var rounded = Math.round(curValue);

			trace(color.red, color.green, color.blue);

			switch(type) {
				case 0: red.red = rounded;
				case 1: red.green = rounded;
				case 2: red.blue = rounded;
				case 3: blue.red = rounded;
				case 4: blue.green = rounded;
				case 5: blue.blue = rounded;
			}

			trace(color.red, color.green, color.blue);

			ClientPrefs.quantColors[selected] = [red, blue];
		} else {
			curValue = defaultColors[selected][type];
			ClientPrefs.arrowHSV[selected][type] = defaultColors[selected][type];
		}
		trace(curValue);

		if(isShowingQuant) {
			shaderQuantArray[selected].red = ClientPrefs.quantColors[selected][0];
			shaderQuantArray[selected].green = 0xffffff;
			shaderQuantArray[selected].blue = ClientPrefs.quantColors[selected][1];
		} else {
			shaderNormalArray[selected].hue = ClientPrefs.arrowHSV[selected][0] / 360;
			shaderNormalArray[selected].saturation = ClientPrefs.arrowHSV[selected][1] / 100;
			shaderNormalArray[selected].brightness = ClientPrefs.arrowHSV[selected][2] / 100;
		}

		var perNums = isShowingQuant ? 6 : 3;

		var item = grpNumbers.members[(selected * perNums) + type];
		item.changeText(Std.string(curValue));
		updateOffset(item, Std.int(curValue));
	}

	function updateValue(change:Float = 0) {
		curValue += change;
		trace(curValue);
		var roundedValue:Int = Math.round(curValue);
		var max:Float = 180;
		var min:Float = 0;
		if(isShowingQuant) {
			max = 255;
		} else {
			switch(typeSelected) {
				case 1 | 2: max = 100;
			}
			min = -max;
		}

		if(roundedValue < min) {
			curValue = min;
		} else if(roundedValue > max) {
			curValue = max;
		}
		roundedValue = Math.round(curValue);

		//var colorSetC = isShowingQuant ? ClientPrefs.quantColors : ClientPrefs.arrowHSV;

		if(isShowingQuant) {
			var red:FlxColor = ClientPrefs.quantColors[curSelected][0];
			var blue:FlxColor = ClientPrefs.quantColors[curSelected][1];

			//var currentColor:FlxColor = ClientPrefs.quantColors[curSelected][Std.int(typeSelected/3)];

			switch(typeSelected) {
				case 0: red.red = roundedValue;
				case 1: red.green = roundedValue;
				case 2: red.blue = roundedValue;
				case 3: blue.red = roundedValue;
				case 4: blue.green = roundedValue;
				case 5: blue.blue = roundedValue;
			}

			ClientPrefs.quantColors[curSelected] = [red, blue];

			shaderQuantArray[curSelected].red = red;
			shaderQuantArray[curSelected].green = 0xffffff;
			shaderQuantArray[curSelected].blue = blue;
		} else {
			ClientPrefs.arrowHSV[curSelected][typeSelected] = roundedValue;

			switch(typeSelected) {
				case 0: shaderNormalArray[curSelected].hue = roundedValue / 360;
				case 1: shaderNormalArray[curSelected].saturation = roundedValue / 100;
				case 2: shaderNormalArray[curSelected].brightness = roundedValue / 100;
			}
		}

		var perNums = isShowingQuant ? 6 : 3;

		var item = grpNumbers.members[(curSelected * perNums) + typeSelected];
		item.changeText(Std.string(roundedValue));
		updateOffset(item, roundedValue);
	}

	function updateOffset(alph:Alphabet, value:Int) {
		alph.offset.x = (40 * (alph.lettersArray.length - 1)) / 2;
		if(value < 0) alph.offset.x += 10;
	}

	/*function swapNotes() {
		var indexStart:Int = primaryNotes ? 0 : 4;
		for (i in 0...noteCount) {
			shaderNormalArray[i].hue = ClientPrefs.arrowHSV[indexStart + i][0] / 360;
			shaderNormalArray[i].saturation = ClientPrefs.arrowHSV[indexStart + i][1] / 100;
			shaderNormalArray[i].brightness = ClientPrefs.arrowHSV[indexStart + i][2] / 100;

			for (j in 0...3)
			{
				var item = grpNumbers.members[(i * 3) + j];
				item.changeText(Std.string(ClientPrefs.arrowHSV[indexStart + i][j]));
				item.offset.x = (40 * (item.lettersArray.length - 1)) / 2;
			}
		}
		curValue = ClientPrefs.arrowHSV[indexStart + curSelected][typeSelected];
	}*/
}