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

class VisualsUISubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Note Splashes',
			"If unchecked, hitting \"Sick!\" notes won't show particles.",
			'noteSplashes',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud',
			'bool',
			false);
		addOption(option);
		
		var option:Option = new Option('Time Bar:',
			"What should the Time Bar display?",
			'timeBarType',
			'string',
			'Time Left',
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights!",
			'flashing',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Screen Shake',
			"If checked, the screen will shake as a special effect for certain events.",
			'screenShake',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Window Shake',
			"If checked, the game window will shake or move around as a special effect for certain events.",
			'windowShake',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Trails',
			"If checked, some characters or images will have a trailing effect (Transparent frames of the image whenever it moves).",
			'ghostTrails',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Particles',
			"If checked, all the particles and confetti will be present in the stage.",
			'particles',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Motion',
			"If checked, certain objects or images will constantly move. Uncheck this if you get motion sickness easily.",
			'motion',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Background Level',
			"Determines the detail of the backgrounds based on its level.
			0 for no backgrounds, 1 for low detail backgrounds, and 2 for full backgrounds.",
			'background',
			'int',
			2);
		option.maxValue = 2;
		option.minValue = 0;
		addOption(option);

		var option:Option = new Option('Optimize',
			"If checked, disables everything. No modcharts, No backgrounds, no mid song events, Just a black screen with notes",
			'optimize',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Score Text Zoom on Hit',
			"If unchecked, disables the Score text zooming\neverytime you hit a note.",
			'scoreZoom',
			'bool',
			true);
		addOption(option);
		
		var option:Option = new Option('Opponent Noteskins',
			'If unchecked, the opponent\'s notes will use the default Noteskin.',
			'opponentNoteskins',
			'bool',
			true);
		addOption(option);
		
		var option:Option = new Option('Player Noteskins',
			'If unchecked, your notes will use the default Noteskin.',
			'playerNoteskins',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Health Bar Transparency',
			'How much transparent should the health bar and icons be.',
			'healthBarAlpha',
			'percent',
			1);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		
		#if !mobile
		var option:Option = new Option('FPS Counter',
			'If unchecked, hides FPS Counter.',
			'showFPS',
			'bool',
			true);
		addOption(option);
		option.onChange = onChangeFPSCounter;
		#end
		
		/*var option:Option = new Option('Pause Screen Song:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			'string',
			'Tea Time',
			['None', 'Breakfast', 'Tea Time']);
		addOption(option);
		option.onChange = onChangePauseMusic;*/

		super();
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic()
	{
		if(ClientPrefs.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)));

		changedMusic = true;
	}

	override function destroy()
	{
		if(changedMusic)
			{
				if (MainMenuState.songName.startsWith('Intro')) MainMenuState.songName = MainMenuState.songName.replace('Intro', 'Menu');
				FlxG.sound.music.persist = true;
				FlxG.sound.playMusic(Paths.music(MainMenuState.songName));
			}
		super.destroy();
	}

	#if !mobile
	function onChangeFPSCounter()
	{
		if(Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.showFPS;
	}
	#end
}