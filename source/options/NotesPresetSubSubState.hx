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

class NotesPresetSubSubState extends MusicBeatSubstate
{
	private var curSelected:Int = 0;
	private static var curPreset:Int = 0;

	private static var defaultColors:Array<Array<Int>> = [
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

	private static var foreverColors:Array<Array<Int>> = [
		[0xFF3535, 0x651038], // 4th
		[0x536BEF, 0x0F1C54], // 8th
		[0xC24B99, 0x3C1F56], // 12th
		[0x00E550, 0x0A4447], // 16th

		[0x606789, 0x232A4C], // 20th
		[0xFF7AD7, 0x4D0954], // 24th
		[0xFFE83D, 0x514100], // 32nd
		[0xAE36E6, 0x19246A], // 48th

		[0x0FEBFF, 0x153E72], // 64th
		[0x606789, 0x232A4C], // 192nd
	];

	private static var androColors:Array<Array<Int>> = [
		[0xFF412F, 0x47130D], // 4th
		[0x3E34FF, 0x110E47], // 8th
		[0x9434FF, 0x290E47], // 12th
		[0x00E656, 0x002E11], // 16th

		[0x606789, 0x232A4C], // 20th // NOT IN ANDRO
		[0x9434FF, 0x290E47], // 24th
		[0xD9C638, 0x474112], // 32nd
		[0x9434FF, 0x290E47], // 48th

		[0x02BCBF, 0x053133], // 64th
		[0x393745, 0x1A191F], // 192nd
	];

	private var presetMap:Map<String, Array<Array<Int>>> = [];
	private var presets:Array<String> = [];

	private var grpQuantGuide:FlxTypedGroup<AttachedText>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;

	var selectBG:FlxSpriteExtra;
	var blackBG:FlxSpriteExtra;
	var currentPreset:Alphabet;

	public function new() {
		presetMap.set("Default", defaultColors);
		presetMap.set("Forever", foreverColors);
		presetMap.set("Andromeda", androColors);

		presets = ["Default", "Forever", "Andromeda"];

		super();

		blackBG = new FlxSpriteExtra().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackBG.scrollFactor.set();
		blackBG.alpha = 0.0;
		blackBG.active = false;
		add(blackBG);

		FlxTween.tween(blackBG, {alpha: 0.6}, 0.3);

		selectBG = new FlxSpriteExtra().makeSolid(178, 178, FlxColor.WHITE);
		selectBG.alpha = 0.4;
		selectBG.scrollFactor.set();
		selectBG.active = false;
		add(selectBG);

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);
		grpQuantGuide = new FlxTypedGroup<AttachedText>();
		add(grpQuantGuide);

		//FlxG.camera.follow(camFollowPos, null, 1);

		currentPreset = new Alphabet(0, 0, "< Q   E >", true, false, 0, 1);
		currentPreset.screenCenter(X);
		currentPreset.y = 30;
		currentPreset.scrollFactor.set();
		add(currentPreset);

		var toset = new Alphabet(0, 0, "To set a color use " + ClientPrefs.getKeyBind("reset") + " on the color selector", true, false, 0, 0.5);
		toset.screenCenter(X);
		toset.y = FlxG.height - 20 - toset.height;
		toset.scrollFactor.set();
		add(toset);

		changePreset();

		//loadNotes();
	}

	function changePreset(change:Int = 0) {
		curPreset += change;
		if (curPreset < 0)
			curPreset = presets.length-1;
		if (curPreset > presets.length-1)
			curPreset = 0;

		loadNotes();

		NotesSubState.quantColors = presetMap[presets[curPreset]];

		currentPreset.changeText("< Q   " + presets[curPreset] + "   E >");
		//currentPreset = new Alphabet(0, 0, "< Q   Default   E >", true, false, 0, 1);
		currentPreset.screenCenter(X);
		currentPreset.y = 30;
	}

	static inline final PER_ROW = 4;

	function loadNotes() {
		var quantAngles = [0, 90, 270, 180];
		var animations:Array<String> = ['purple0', 'blue0', 'green0', 'red0'];
		var quantBeatText:Array<String> = ['4th', '8th', '12th', '16th', '20th', '24th', '32nd', '48th', '64th', '192nd'];

		grpNotes.clear();
		grpQuantGuide.clear();

		//var hsvSet = ClientPrefs.arrowHSV;
		//if(isShowingQuant) hsvSet = ClientPrefs.quantHSV;

		var preset = presetMap[presets[curPreset]];

		for (i in 0...preset.length) {
			var yPos:Float = (170 * Std.int(i / PER_ROW)) + 130;
			var xPos:Float = 240 + (200 * Std.int(i % PER_ROW));

			var quantBeat:AttachedText = new AttachedText(quantBeatText[i], 0, 80, true, 0.8);
			quantBeat.scrollFactor.set();
			grpQuantGuide.add(quantBeat);

			var note:FlxSprite = new FlxSprite(xPos, yPos);
			note.frames = Paths.getSparrowAtlas('NOTE_assets_quant');
			note.animation.addByPrefix('idle', animations[i % animations.length]);
			note.animation.play('idle');
			note.antialiasing = ClientPrefs.globalAntialiasing;
			note.angle = quantAngles[i % quantAngles.length];
			note.scrollFactor.set();
			quantBeat.sprTracker = note;
			quantBeat.offsetX = (note.width / 2) - (quantBeat.width / 2);
			grpNotes.add(note);

			var newShader:AmongUsShader = new AmongUsShader();
			note.shader = newShader;
			newShader.red = preset[i][0];
			newShader.green = 0xffffff;
			newShader.blue = preset[i][1];
		}

		changeSelection();
	}

	var changingNote:Bool = false;
	override function update(elapsed:Float) {
		if(controls.UI_LEFT_P) {
			changeSelection(-1);
		}
		if(controls.UI_RIGHT_P) {
			changeSelection(1);
		}
		if(controls.UI_UP_P) {
			changeSelection(-PER_ROW);
		}
		if(controls.UI_DOWN_P) {
			changeSelection(PER_ROW);
		}

		if(FlxG.keys.justPressed.Q) {
			changePreset(-1);
		}
		if(FlxG.keys.justPressed.E) {
			changePreset(1);
		}

		if (controls.BACK) {
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0, playSound:Bool = true) {
		var preset = presetMap[presets[curPreset]];

		curSelected += change;
		if (curSelected < 0)
			curSelected = preset.length-1;
		if (curSelected >= preset.length)
			curSelected = 0;

		//var perNums = isShowingQuant ? 6 : 3;

		for (i in 0...grpQuantGuide.length) {
			var item = grpQuantGuide.members[i];
			item.alpha = 0.6;
			if ((curSelected) == i) {
				item.alpha = 1;
			}
		}
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			if (curSelected == i) {
				selectBG.x = item.x + (item.width / 2) - (selectBG.width / 2);
				selectBG.y = item.y + (item.height / 2) - (selectBG.height / 2);
			}
		}

		if(playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}