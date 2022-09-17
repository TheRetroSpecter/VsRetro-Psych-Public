/**
	TSG here, this dialogue system was lifted from my Small Things engine mod, with the Small Things specific shit commented out.
	If you have any issues with the dialogue system at all, feel free to DM me.
**/

package;

import flixel.util.FlxDestroyUtil;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.math.FlxPoint;

using StringTools;

class DialogueBox extends FlxAlphaSpriteGroup
{
	var box:FlxSprite;

	var curMood:String = '';
	var curMood2:String = ''; // (Arcy) For multiple characters talking at the same time I GUESS. #STOPSPREADINGSAKUROMA
	var curMood3:String = ''; // (Donald Feury) #MOREMOTHMOMMYMILKIES
	var curCharacter:String = '';
	var lastCharacter:String = '';

	//var dialogue:Alphabet;
	var dialogueList:Array<String> = [];

	// SECOND DIALOGUE FOR THE PIXEL SHIT INSTEAD???
	var swagDialogue:FlxFixedTypeText;

	var dropText:FlxFixedText;
	var skipText:FlxFixedText;

	public var finishThing:Void->Void;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null; // TODO: Implement this

	var portraitRight:FlxSprite;
	var portraitBooba:FlxSprite;
	var secondPortrait:FlxSprite;
	var thirdPortrait:FlxSprite;

	var bgFade:FlxSpriteExtra;

	var music:FlxSound;
	var matroVoice:FlxSound;
	var musicPath:String = '';

	public var curVoice:FlxSound;

	public var noDialogue:Bool = false;

	var happyEnding:FlxSprite;
	var angryEnding:FlxSprite;

	override function set_cameras(val:Array<FlxCamera>) {
		if(happyEnding != null) happyEnding.cameras = val;
		if(angryEnding != null) angryEnding.cameras = val;
		return super.set_cameras(val);
	}

	var animList:Array<String> = [];

	// (Arcy) List of character strings that have expressions
	var expressionChars:Array<String> = [
		'bf', 'bf-og', 'bf-ace', 'bf-retro', 'bf-saku', 'gf', 'retro', 'ace', 'ace-L', 'sakuroma', 'sakuromaRight', 'sakuroma-gf','sakuroma-gf-L',
		'minus-bf', 'minus-gf', 'minus-retro', 'minus-sakuroma', 'minus-atrocean', 'minus-dozirc',
		'metro',
		'zerktro', 'zerktro-L', 'zerktro-R', 'iceolation', 'iceolation-L',
		'ace-left', 'retro-right',
		'corruptro', 'bf-corrupt', 'minus-sakuroma-P',
		'izzy-phone', 'izzy-phone-L',
		'metro-player'
	];
	var expressionCharsMultiple:Array<String> = ['sakuromas'];
	var expressionCharsAlot:Array<String> = ['sakuOrgy'];

	// Dialogue shake
	var amplitudeX:Float;
	var amplitudeY:Float;
	var textShake:Bool = false;

	var canAdvance = true;

	public function new(song:String, character:String, difficulty:Int, gf:String, postSong:Bool = false)
	{
		super();

		var context:DialogueContext = new DialogueContext(character, gf, null, song, difficulty, postSong);
		this.dialogueList = getDialogueFromContext(context);

		for (line in dialogueList)
		{
			var c = line.split(':');
			var a = [c[1], c[2]];
			animList.push(a.join('|'));
		}
		trace(animList);
		// this.dialogueList = getDialogue(song, character, difficulty, gf, postSong);
		var storia = (PlayState.isStoryMode && !PlayState.seenCutscene && PlayState.firstTry);
		var freeia = (!PlayState.isStoryMode && !PlayState.seenCutscene && PlayState.firstTry);
		// (Arcy) No dialogue found. Set this object to null and abort.
		if ((dialogueList == null || dialogueList.length == 0))
		{
			noDialogue = true;
			kill();
			if (music != null)
				music.stop();
			return;
		}
		
		switch (Paths.formatToSongPath(PlayState.SONG.song))
		{
			/*case 'retro':
				if (storia)
				{
					music = new FlxSound().loadEmbedded(Paths.music('wrath/dialogue_1'), true, true);
					music.volume = 0;
					music.fadeIn(1, 0, 0.2);
					FlxG.sound.list.add(music);
				}*/
			case 'icebreaker':
				if (freeia || postSong)
				{
					music = new FlxSound().loadEmbedded(Paths.music('wind'), true, true);
					music.volume = 0;
					music.persist = false;
					music.fadeIn(1, 0, 0.8);
					FlxG.sound.list.add(music);
					musicPath = 'assets/shared/music/wind.ogg';
				}
			case 'spectral':
				if (storia)
				{
					music = new FlxSound().loadEmbedded(Paths.music('wrath/dialogue_2'), true, true);
					music.volume = 0;
					music.persist = false;
					music.fadeIn(1, 0, 0.2);
					FlxG.sound.list.add(music);
					musicPath = 'assets/shared/music/wrath/dialogue_2.ogg';
				}
			case 'satisfracture':
				if (storia)
				{
					music = new FlxSound().loadEmbedded(Paths.music('wrath/dialogue_1'), true, true);
					music.volume = 0;
					music.persist = false;
					music.fadeIn(1, 0, 0.2);
					FlxG.sound.list.add(music);
					musicPath = 'assets/shared/music/wrath/dialogue_1.ogg';
				}
			case 'ectospasm':
				if (storia)
				{
					music = new FlxSound().loadEmbedded(Paths.music('wrath/dialogue_2'), true, true);
					music.volume = 0;
					music.persist = false;
					music.fadeIn(1, 0, 0.2);
					FlxG.sound.list.add(music);
					musicPath = 'assets/shared/music/wrath/dialogue_2.ogg';
				}
			case 'preppy' | 'acidiron' | 'sigma':
				if (storia)
				{
					music = new FlxSound().loadEmbedded(Paths.music('minus/Dialogue_Ambience'), true, true);
					music.volume = 0;
					music.persist = false;
					music.fadeIn(1, 0, 0.2);
					FlxG.sound.list.add(music);
					musicPath = 'assets/shared/music/minus/Dialogue_Ambience.ogg';
				}
			case 'preseason':
				if (storia)
				{
					music = new FlxSound().loadEmbedded(Paths.music('minus/Preaseason_Ambience'), true, true);
					music.volume = 0;
					music.persist = false;
					music.fadeIn(1, 0, 0.2);
					FlxG.sound.list.add(music);
					musicPath = 'assets/shared/music/minus/Preaseason_Ambience.ogg';
				}
			case 'overtime':
				if (PlayState.isStoryMode && postSong)
				{
					//MainMenuState.songName = 'Intro_Minus';
					//TitleState.afterDialogue = true; ???
					//TitleState.introMusic = FlxG.sound.play(Paths.music('Intro_Empty'), 0);
					//TitleState.introMusic.persist = true;
					FlxG.sound.playMusic(Paths.music('Menu_Minus'), 0);
					FlxG.sound.music.fadeIn(3, 0, 0.375);
					MainMenuState.songName = 'Menu_Minus';
					FlxG.sound.music.persist = false;
					/*
					TitleState.introMusic.onComplete = function():Void
					{
						FlxG.sound.music.volume = 0; // Shit workaround I guess
						FlxG.sound.music.play(true);
						FlxG.sound.music.fadeIn(3, 0, 0.375);
						MainMenuState.songName = 'Menu_Minus';
						TitleState.introMusic.destroy();
						TitleState.introMusic = null;
					}

					TitleState.introMusic.fadeIn(4, 0, 0);*/
				}
				else if (storia && !postSong)
				{
					music = new FlxSound().loadEmbedded(Paths.music('minus/Dialogue_Ambience'), true, true);
					music.volume = 0;
					music.fadeIn(1, 0, 0.2);
					FlxG.sound.list.add(music);
					musicPath = 'shared:assets/shared/music/minus/Dialogue_Ambience.ogg';
				}
			
		}

		var hasHappy = false;
		var hasAngry = false;

		for (line in dialogueList)
		{
			if(line == ':happyEnding:') hasHappy = true;
			if(line == ':angryEnding:') hasAngry = true;
		}

		if(hasHappy) {
			happyEnding = new FlxSprite().loadGraphic(Paths.image('iceolation/happyending'));
			happyEnding.scrollFactor.set();
			happyEnding.setGraphicSize(FlxG.width, FlxG.height);
			happyEnding.updateHitbox();
			happyEnding.screenCenter();
			happyEnding.antialiasing = ClientPrefs.globalAntialiasing;
			happyEnding.cameras = cameras;
			happyEnding.alpha = 0.00001;
		}

		if(hasAngry) {
			angryEnding = new FlxSprite().loadGraphic(Paths.image('iceolation/angryending'));
			angryEnding.scrollFactor.set();
			angryEnding.setGraphicSize(FlxG.width, FlxG.height);
			angryEnding.updateHitbox();
			angryEnding.screenCenter();
			angryEnding.antialiasing = ClientPrefs.globalAntialiasing;
			angryEnding.cameras = cameras;
			angryEnding.alpha = 0.00001;
		}

		bgFade = new FlxSpriteExtra(-200, -200).makeSolid(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
		bgFade.scrollFactor.set();
		bgFade.alpha = 0;
		add(bgFade);

		new FlxTimer().start(0.83, function(tmr:FlxTimer)
		{
			bgFade.alpha += (1 / 5) * 0.7;
			if (bgFade.alpha > 0.7)
			{
				bgFade.alpha = 0.7;
			}
		}, 5);

		box = new FlxSprite(-20, 45);
		box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
		box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
		//box.animation.addByPrefix('normal', 'Speech Bubble Normal Open', 24, false);
		box.animation.addByIndices('normal', 'Speech Bubble Normal Open', [4], '', 24, false);
		box.setGraphicSize(Std.int(box.width * 1 * 0.9));
		box.antialiasing = ClientPrefs.globalAntialiasing;
		box.y = (FlxG.height - box.height) + 80;

		portraitRight = new FlxSprite(0, 40);
		portraitRight.visible = false;
		add(portraitRight);

		portraitBooba = new FlxSprite(0, 40);

		if (
			animList.contains('sakuroma|Enraged') ||
			animList.contains('sakuromaRight|Enraged') ||
			animList.contains('sakuroma-gf-L|Enraged') ||
			animList.contains('sakuroma-gf|Enraged')
		) {
			portraitBooba.frames = Paths.getSparrowAtlas('characters/portraits/Sakuroma');
			portraitBooba.animation.addByPrefix('enter', 'Booba', 24, false);
			portraitBooba.setGraphicSize(Std.int(portraitBooba.width * 1 * 0.75));
			portraitBooba.antialiasing = ClientPrefs.globalAntialiasing;
			portraitBooba.updateHitbox();
			portraitBooba.scrollFactor.set();
			portraitBooba.animation.play('enter');
		}
		portraitBooba.visible = false;
		
		secondPortrait = new FlxSprite(0, 40);
		secondPortrait.visible = false;
		add(secondPortrait);

		thirdPortrait = new FlxSprite(0, 40);
		add(thirdPortrait);
		thirdPortrait.visible = false;

		box.animation.play('normalOpen');
		box.updateHitbox();
		add(box);
		add(portraitBooba);

		box.screenCenter(X);
		// portraitLeft.screenCenter(X);

		swagDialogue = new FlxFixedTypeText(200, 500, Std.int(FlxG.width * 0.7), "", 40);
		swagDialogue.setFormat(Paths.font('vcr.ttf'), 40, FlxColor.BLACK, LEFT);
		swagDialogue.antialiasing = ClientPrefs.globalAntialiasing;
		dropText = new FlxFixedText(202, 502, Std.int(FlxG.width * 0.7), "", 40);
		dropText.setFormat(Paths.font('vcr.ttf'), 40, FlxColor.BLACK, LEFT);
		dropText.antialiasing = ClientPrefs.globalAntialiasing;

		skipText = new FlxFixedText(1120, (FlxG.height * 0.9) + 50, 0, "Press Esc to skip", 16);
		skipText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		skipText.antialiasing = ClientPrefs.globalAntialiasing;

		add(dropText);
		add(swagDialogue);
		add(skipText);
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;

	override function kill()
	{
		for (i in Paths.localTrackedAssets)
			if (i.startsWith('shared:assets/shared/images/characters/portraits') || i == 'shared:assets/shared/images/speech_bubble_talking.png')
			{
				Paths.localTrackedAssets.remove(i);
				trace('removed $i');
			}
		
		super.kill();
		trace('dialogueBox kill success!');
		//group.clear();

		//trace('dialogueBox group success!');
		Paths.clearUnusedMemory();

		MemoryUtils.clearMajor();
		destroy();
	}

	override function destroy() {
		happyEnding = FlxDestroyUtil.destroy(happyEnding);
		angryEnding = FlxDestroyUtil.destroy(angryEnding);
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		dropText.text = swagDialogue.text;

		if (box.animation.curAnim != null)
		{
			if (box.animation.curAnim.finished && box.animation.curAnim.name == 'normalOpen')
			{
				box.animation.play('normal');
				dialogueOpened = true;
			}
		}

		// Dialogue shake
		if (textShake)
		{
			setTextOffset(amplitudeX, amplitudeY);
			// timeElapsed += elapsed;
		}

		if (dialogueOpened && !dialogueStarted)
		{
			startDialogue();
			dialogueStarted = true;
		}

		// Skip dialogue
		if (PlayerSettings.player1.controls.BACK && dialogueStarted && !isEnding)
		{
			isEnding = true;
			PlayState.announceStart = false;

			if (music != null && music.playing)
				music.fadeOut(2.2, 0, (_) -> {
					music.stop();
					music.persist = false;
					Paths.localTrackedAssets.remove(musicPath);
					Paths.currentTrackedSounds.remove(musicPath);
					//music.kill();
					var m = FlxG.sound.list.members.indexOf(music);
					FlxG.sound.list.members[m].destroy();
					music.destroy();
				});

			var isNarrators:Bool = (curCharacter == 'minus-atrocean' || curCharacter == 'minus-dozirc');
			if (isNarrators)
			{
				// trace('Camera going down! ' + lastCharacter);
				PlayState.instance.camFollow.y += 500;
			}

			new FlxTimer().start(0.2, function(tmr:FlxTimer)
			{
				box.alpha -= 1 / 5;
				bgFade.alpha -= 1 / 5 * 0.7;
				portraitRight.visible = false;
				portraitBooba.visible = false;
				secondPortrait.visible = false;
				thirdPortrait.visible = false;
				swagDialogue.alpha -= 1 / 5;
				dropText.alpha = swagDialogue.alpha;
				skipText.alpha -= 1 / 5;
			}, 5);

			new FlxTimer().start(1.2, function(tmr:FlxTimer)
			{
				finishThing();
				kill();
			});
		}
		else if (canAdvance && PlayerSettings.player1.controls.ACCEPT && dialogueStarted == true && !isEnding)
		{
			updateDialogue();
			PlayState.announceStart = false;
		}
		super.update(elapsed);
	}

	function setTextOffset(offsetX:Float = 0, offsetY:Float = 0)
	{
		swagDialogue.x = 240 + (offsetX * Math.sin(FlxG.random.float(0, 2 * Math.PI)));
		swagDialogue.y = 500 + (offsetY * Math.sin(FlxG.random.float(0, 2 * Math.PI)));
		dropText.x = 242 + (offsetX * Math.sin(FlxG.random.float(0, 2 * Math.PI)));
		dropText.y = 502 + (offsetY * Math.sin(FlxG.random.float(0, 2 * Math.PI)));
	}

	var isEnding:Bool = false;

	function updateDialogue(playSound:Bool = true):Void
	{
		// (Arcy) Stop making sounds!!!
		if (playSound && !isEnding)
		{
			FlxG.sound.play(Paths.sound('clickText'), 0.4);
		}

		if (dialogueList[1] == null && dialogueList[0] != null)
		{
			if (!isEnding)
			{
				isEnding = true;

				if (music != null && music.playing)
					music.fadeOut(2.2, 0, (_) -> {
						music.stop();
						music.persist = false;
						Paths.localTrackedAssets.remove(musicPath);
						Paths.currentTrackedSounds.remove(musicPath);
						//music.kill();
						var m = FlxG.sound.list.members.indexOf(music);
						FlxG.sound.list.members[m].destroy();
						music.destroy();
						
					});
					

				if(curVoice != null) {
					curVoice.fadeOut(2.2, 0, (_) -> {
						FlxG.sound.list.remove(curVoice);
						curVoice.stop();
						curVoice = null;
					});
				}
				/*
					switch (PlayState.SONG.song.toLowerCase())
					{
						case 'retro' | 'satisfracture' | 'spectral' | 'preppy' | 'sigma' |'preseason':
							music.fadeOut(2.2, 0);
				}*/

				new FlxTimer().start(0.2, function(tmr:FlxTimer)
				{
					box.alpha -= 1 / 5;
					bgFade.alpha -= 1 / 5 * 0.7;
					portraitRight.visible = false;
					portraitBooba.visible = false;
					secondPortrait.visible = false;
					thirdPortrait.visible = false;
					swagDialogue.alpha -= 1 / 5;
					dropText.alpha = swagDialogue.alpha;
					skipText.alpha -= 1 / 5;
				}, 5);

				new FlxTimer().start(1.2, function(tmr:FlxTimer)
				{
					finishThing();
					kill();
				});
			}
		}
		else
		{
			dialogueList.remove(dialogueList[0]);

			portraitRight.visible = false;
			portraitBooba.visible = false;
			secondPortrait.visible = false;
			thirdPortrait.visible = false;

			startDialogue();
		}
	}

	function startDialogue():Void
	{
		cleanDialog();
		// var theDialog:Alphabet = new Alphabet(0, 70, dialogueList[0], false, true);
		// dialogue = theDialog;
		// add(theDialog);

		// swagDialogue.text = ;
		swagDialogue.resetText(dialogueList[0]);
		dropText.text = '';
		swagDialogue.start(0.04, true);

		portraitRight.flipX = false;
		portraitBooba.flipX = false;
		secondPortrait.flipX = false;
		thirdPortrait.flipX = false;

		switch (curCharacter)
		{
			case 'bf':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('bfText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(80, 165, 235);
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Boyfriend');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 250;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'bf-og':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('bfText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(80, 165, 235);
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Boyfriend');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 250;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'bf-ace':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('bfText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(80, 165, 235);
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/AceBF');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();
					portraitRight.flipX = false;

					portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 200 -70;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'bf-retro':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('bfText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(80, 165, 235);
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/RetroBF');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 175 -93;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'bf-saku':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('sakuromaText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(247, 124, 216);
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/BF_Saku_Portrait');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 175 -95;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'gf':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('bfText'), 0.6)];
				swagDialogue.color = 0xFF0c0a16;
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Girlfriend');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();
					portraitRight.screenCenter(X);

					//portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 245 - 30;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'retro' | 'retro-right':
				if (curMood == 'Angry' || curMood == 'Enraged')
				{
					swagDialogue.sounds = [FlxG.sound.load(Paths.sound('retroAngryVoice'), 0.3)];
				}
				else
				{
					swagDialogue.sounds = [FlxG.sound.load(Paths.sound('retroText'), 0.6)];
				}
				swagDialogue.color = FlxColor.fromRGB(42, 136, 164);
				if (!portraitRight.visible)
				{
					if(curCharacter == "retro-right" && curMood == "Question") {
						portraitRight.loadGraphic(Paths.image('characters/portraits/RetroQuestionFlipped'));
					} else {
						portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/RetroSpecter');
						portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					}
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = box.x + 64;
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 260;
					portraitRight.y = box.y - 246;
					portraitRight.flipX = false;

					if(curCharacter == "retro-right") {
						portraitRight.flipX = true;
						portraitRight.x = box.x + box.width - portraitRight.width - 50;
					}

					portraitRight.visible = true;
					if(curCharacter == "retro-right" && curMood == "Question") {
						portraitRight.y -= 30;
					} else {
						portraitRight.animation.play('enter');
					}
				}
			case 'zerktro':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('retroAngryVoice'), 0.3)];
				swagDialogue.color = FlxColor.fromRGB(42, 136, 164);
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Zerktro');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.66));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.screenCenter(X);
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 260;
					portraitRight.y = box.y - 238;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}

			case 'zerktro-R':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('retroAngryVoice'), 0.3)];
				swagDialogue.color = FlxColor.fromRGB(42, 136, 164);
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Zerktro');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.66));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					//portraitRight.screenCenter(X);
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 260;
					portraitRight.y = box.y - 238;
					portraitRight.x = box.x + box.width - 580;
					portraitRight.flipX = true;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'zerktro-L':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('retroAngryVoice'), 0.3)];
				swagDialogue.color = FlxColor.fromRGB(42, 136, 164);
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Zerktro');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.66));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.screenCenter(X);
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 260;
					portraitRight.y = box.y - 238;
					portraitRight.flipX = true;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}

			case 'izzy-phone' | 'izzy-phone-L':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('IzzyPhoneVoice'), 0.3)];
				swagDialogue.color = 0xFF79F5E2;
				if (!portraitRight.visible)
				{
					portraitRight.loadGraphic(Paths.image('characters/portraits/IzzyPhone'));
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.66));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = box.x + 64;
					portraitRight.screenCenter(X);
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 260;
					portraitRight.y = box.y - portraitRight.height + 10 + 100;
					portraitRight.flipX = curCharacter == "izzy-phone-L";

					portraitRight.visible = true;
					//portraitRight.animation.play('enter');
				}

			case 'corruptro':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('CorruptroVoice'), 0.6)];
				swagDialogue.color = 0xFFE12979;
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Corruptro');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.66));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					//portraitRight.screenCenter(X);
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 260;
					portraitRight.y = box.y - portraitRight.height + 10 + 100;
					portraitRight.x = box.x + 64;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}

			case 'bf-corrupt':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('CrystalBFVoice'), 0.6)];
				swagDialogue.color = 0xFFE12979;
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/corruptBF');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.55));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					//portraitRight.screenCenter(X);
					
					//portraitRight.y = box.y - 238;
					portraitRight.y = box.y - portraitRight.height + 10 + 100;
					//portraitRight.x = box.x + box.width - 580;
					portraitRight.x = (box.x + box.width) - (portraitRight.width) - 100;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}

			case 'iceolation':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('IceolationVoice'), 0.6)];
				swagDialogue.color = 0xFFCAD9EA;
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Iceolation');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.45));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					//portraitRight.screenCenter(X);
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 260;
					portraitRight.y = box.y - 238;
					portraitRight.x = box.x + 100;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'iceolation-L':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('IceolationVoice'), 0.6)];
				swagDialogue.color = 0xFFCAD9EA;
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Iceolation');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.66));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					//portraitRight.screenCenter(X);
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 260;
					portraitRight.y = box.y - 238;
					portraitRight.x = box.x + 100;
					portraitRight.flipX = true;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}

			case 'ace' | 'ace-left':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('aceText'), 0.6)];

				swagDialogue.color = 0xFFA692D4;
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/AcePortraits');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();
					portraitRight.screenCenter(X);
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 260;
					portraitRight.y = box.y - 248;
					portraitRight.flipX = false;

					if(curCharacter == "ace-left") {
						portraitRight.x = box.x + 100;
					}

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}

			case 'ace-L':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('aceText'), 0.6)];

				swagDialogue.color = 0xFFA692D4;
				if (!portraitRight.visible)
				{
					if(curCharacter == "ace-L" && curMood == "Confused") {
						portraitRight.loadGraphic(Paths.image('characters/portraits/AceQuestionFlipped'));
					} else {
						portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/AcePortraits');
						portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					}
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();
					portraitRight.screenCenter(X);
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 260;
					portraitRight.y = box.y - 248;
					portraitRight.flipX = true;
					portraitRight.visible = true;
					if(curCharacter == "ace-L" && curMood == "Confused") {

					} else {
						portraitRight.animation.play('enter');
					}
				}

			case 'sakuroma':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('sakuromaText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(247, 124, 216);

				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Sakuroma');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = box.x + 64;
					//if (PlayState.gfCharacter.startsWith('gf-saku')) portraitRight.screenCenter(X);
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 248;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}

				if (curMood == 'Enraged')
				{
					portraitBooba.x = portraitRight.x + 103;
					// portraitBooba.x = (box.x + box.width) - (portraitBooba.width) - 105;
					portraitBooba.flipX = portraitRight.flipX;
					portraitBooba.y = portraitRight.y + 308;
					portraitBooba.visible = true;
				}
				else
					portraitBooba.visible = false;

			case 'sakuroma-gf':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('sakuromaText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(247, 124, 216);

				if (!thirdPortrait.visible)
				{
					thirdPortrait.frames = Paths.getSparrowAtlas('characters/portraits/Sakuroma');
					thirdPortrait.animation.addByPrefix('enter', curMood, 24, false);
					thirdPortrait.setGraphicSize(Std.int(thirdPortrait.width * 1 * 0.75));
					thirdPortrait.antialiasing = ClientPrefs.globalAntialiasing;
					thirdPortrait.updateHitbox();
					thirdPortrait.scrollFactor.set();

					//thirdPortrait.x = box.x + 64;
					thirdPortrait.screenCenter(X);
					thirdPortrait.y = box.y - 248;

					thirdPortrait.flipX = false;
					thirdPortrait.visible = true;
					thirdPortrait.animation.play('enter');
				}

				if (curMood == 'Enraged')
				{
					portraitBooba.x = thirdPortrait.x + 103;
					// portraitBooba.x = (box.x + box.width) - (portraitBooba.width) - 105;
					portraitBooba.flipX = thirdPortrait.flipX;
					portraitBooba.y = thirdPortrait.y + 308;
					portraitBooba.visible = true;
				}
				else
					portraitBooba.visible = false;

			case 'sakuroma-gf-L':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('sakuromaText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(247, 124, 216);

				if (!thirdPortrait.visible)
				{
					thirdPortrait.frames = Paths.getSparrowAtlas('characters/portraits/Sakuroma');
					thirdPortrait.animation.addByPrefix('enter', curMood, 24, false);
					thirdPortrait.setGraphicSize(Std.int(thirdPortrait.width * 1 * 0.75));
					thirdPortrait.antialiasing = ClientPrefs.globalAntialiasing;
					thirdPortrait.updateHitbox();
					thirdPortrait.scrollFactor.set();

					//thirdPortrait.x = box.x + 64;
					thirdPortrait.screenCenter(X);
					thirdPortrait.y = box.y - 248;

					thirdPortrait.flipX = true;
					thirdPortrait.visible = true;
					thirdPortrait.animation.play('enter');
				}

				if (curMood == 'Enraged')
				{
					portraitBooba.x = thirdPortrait.x + 103 - 10;
					// portraitBooba.x = (box.x + box.width) - (portraitBooba.width) - 105;
					portraitBooba.flipX = thirdPortrait.flipX;
					portraitBooba.y = thirdPortrait.y + 308;
					portraitBooba.visible = true;
				}
				else
					portraitBooba.visible = false;

			case 'sakuromas':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('sakuromaText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(247, 124, 216);

				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Sakuroma');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = box.x + 64;
					portraitRight.y = box.y - 248;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
				if (!secondPortrait.visible)
				{
					secondPortrait.frames = Paths.getSparrowAtlas('characters/portraits/Sakuroma');
					secondPortrait.animation.addByPrefix('enter', curMood2, 24, false);
					secondPortrait.setGraphicSize(Std.int(secondPortrait.width * 1 * 0.75));
					secondPortrait.antialiasing = ClientPrefs.globalAntialiasing;
					secondPortrait.updateHitbox();
					secondPortrait.scrollFactor.set();

					secondPortrait.x = box.x + portraitRight.width + 64;
					secondPortrait.y = box.y - 248;
					secondPortrait.flipX = false;

					secondPortrait.visible = true;
					secondPortrait.animation.play('enter');
				}
			case 'sakuOrgy':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('sakuromaText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(247, 124, 216);

				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Sakuroma');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = box.x + 64;
					portraitRight.y = box.y - 248;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
				if (!secondPortrait.visible)
				{
					secondPortrait.frames = Paths.getSparrowAtlas('characters/portraits/Sakuroma');
					secondPortrait.animation.addByPrefix('enter', curMood2, 24, false);
					secondPortrait.setGraphicSize(Std.int(secondPortrait.width * 1 * 0.75));
					secondPortrait.antialiasing = ClientPrefs.globalAntialiasing;
					secondPortrait.updateHitbox();
					secondPortrait.scrollFactor.set();

					secondPortrait.x = box.x + portraitRight.width - 16;
					secondPortrait.y = box.y - 248;

					secondPortrait.visible = true;
					secondPortrait.animation.play('enter');
				}
				if (!thirdPortrait.visible)
				{
					thirdPortrait.frames = Paths.getSparrowAtlas('characters/portraits/BF_Saku_Portrait');
					thirdPortrait.animation.addByPrefix('enter', curMood2, 24, false);
					thirdPortrait.setGraphicSize(Std.int(thirdPortrait.width * 1 * 0.75));
					thirdPortrait.antialiasing = ClientPrefs.globalAntialiasing;
					thirdPortrait.updateHitbox();
					thirdPortrait.scrollFactor.set();

					thirdPortrait.x = (box.x + box.width) - (portraitRight.width) - 60;
					thirdPortrait.y = box.y - 248;

					thirdPortrait.visible = true;
					thirdPortrait.animation.play('enter');
				}
			case 'sakuromaRight':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('sakuromaText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(247, 124, 216);

				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/SakuromaFlip');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 248;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}

				if (curMood == 'Enraged')
				{
					portraitBooba.x = box.x + (box.width - 110);
					portraitBooba.y = box.y - 259;
					portraitBooba.flipX = portraitRight.flipX;
					portraitBooba.visible = true;
				}
				else
					portraitBooba.visible = false;
			case 'mic':
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/mic_portrait');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 200;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			// Minus characters
			case 'minus-bf':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('bfText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(80, 165, 235);
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Minus_BF_Portrait');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 255;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'minus-gf':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('bfText'), 0.6)];
				swagDialogue.color = 0xFFa5004d;
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Minus_GF_Portrait');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.screenCenter(X);
					portraitRight.y = box.y - 245 -17;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'minus-retro' | 'metro':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('minusRetroText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(42, 136, 164);
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Minus_Retro_Portrait');
					portraitRight.animation.addByPrefix('enter', curMood, 16, true);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = box.x + 64;
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 260;
					portraitRight.y = box.y - 248;
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'metro-player':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('minusRetroText'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(42, 136, 164);
				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Minus_Retro_Player_Portrait');
					portraitRight.animation.addByPrefix('enter', curMood, 16, true);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					//portraitRight.x = box.x + 64;
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 260;
					//portraitRight.y = box.y - 248;
					portraitRight.y = box.y - portraitRight.height + 10 + 100;
					portraitRight.x = (box.x + box.width) - (portraitRight.width) - 40;
					portraitRight.flipX = true;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'minus-sakuroma':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('MakuVoice'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(247, 124, 216);

				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Minus_Saku_Portrait');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = box.x + 64;
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 276;
					switch (curMood.trim())
					{
						case 'Cheering':
							portraitRight.setGraphicSize(Std.int(portraitRight.width * 0.85));
							portraitRight.updateHitbox();
							portraitRight.x -= 75;
							portraitRight.y -= 72;
					}
					portraitRight.flipX = false;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'minus-sakuroma-P':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('MakuVoice'), 0.6)];
				swagDialogue.color = FlxColor.fromRGB(247, 124, 216);

				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Minus_Saku_Portrait');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					portraitRight.x = (box.x + box.width) - (portraitRight.width) + 220;
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 271;
					switch (curMood.trim())
					{
						case 'Cheering':
							portraitRight.setGraphicSize(Std.int(portraitRight.width * 0.85));
							portraitRight.updateHitbox();
							portraitRight.x -= 75;
							portraitRight.y -= 85;
					}
					portraitRight.flipX = true;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'minus-atrocean':
				if(matroVoice == null) {
					matroVoice = new FlxSound().loadEmbedded(Paths.sound('MatroVoice'));
					matroVoice.volume = 0.6;
				}
				swagDialogue.sounds = [matroVoice];
				swagDialogue.color = 0xFF12e476;

				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Minus_Atro_Portrait');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();
					portraitRight.flipX = false;
					portraitRight.x = box.x + 64;
					// portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 248;

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			case 'minus-dozirc':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('MozircVoice'), 0.6)];
				swagDialogue.color = 0xFFe39212;

				if (!portraitRight.visible)
				{
					portraitRight.frames = Paths.getSparrowAtlas('characters/portraits/Mozi_Portrait');
					portraitRight.animation.addByPrefix('enter', curMood, 24, false);
					portraitRight.setGraphicSize(Std.int(portraitRight.width * 1 * 0.75));
					portraitRight.antialiasing = ClientPrefs.globalAntialiasing;
					portraitRight.updateHitbox();
					portraitRight.scrollFactor.set();

					//portraitRight.x = box.x + 64;
					portraitRight.x = (box.x + box.width) - (portraitRight.width) - 60;
					portraitRight.y = box.y - 220;
					portraitRight.flipX = true;
					switch (curMood.trim())
					{
						case 'Confused':
							portraitRight.y += 85;
						case 'Awake':
							portraitRight.y += 81;
					}

					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			
			// Commands
			case 'angryEnding':
				// split arguments
				FlxTween.tween(box, {alpha: 0}, 0.3);
				FlxTween.tween(angryEnding, {alpha: 1}, 0.6);

				canAdvance = false;
	
				FlxTween.tween(this, {renderAlpha: 0}, 0.6, {onComplete: (_) -> {
					bgFade.visible = false;
					box.alpha = 0;
					FlxTween.tween(this, {renderAlpha: 1}, 0.6, {startDelay:2, onComplete: (_) -> {
						FlxTween.tween(box, {alpha: 1}, 0.3);

						canAdvance = true;

						// move the dialogue script ahead one line WITHOUT PLAYING THE ENTER SOUND
						updateDialogue(false);
					}});
				}});

				return;

			case 'happyEnding':
				// split arguments
				FlxTween.tween(box, {alpha: 0}, 0.3);
				FlxTween.tween(happyEnding, {alpha: 1}, 2.6, {startDelay:1});

				canAdvance = false;

				FlxTween.tween(this, {renderAlpha: 0}, 0.6, {onComplete: (_) -> {
					bgFade.visible = false;
					box.alpha = 0;
					FlxTween.tween(this, {renderAlpha: 1}, 0.6, {startDelay:6, onComplete: (_) -> {
						FlxTween.tween(box, {alpha: 1}, 0.3);

						canAdvance = true;

						// move the dialogue script ahead one line WITHOUT PLAYING THE ENTER SOUND
						updateDialogue(false);
					}});
				}});

				return;

			case 'fadeToBlack':
				// split arguments
				var black = new FlxSpriteExtra();
				black.makeSolid(1280*3, 720*3, 0xFF000000);
				black.screenCenter();
				black.cameras = [PlayState.instance.camOther];
				black.alpha = 0.00001;
				PlayState.instance.add(black);

				FlxTween.tween(box, {alpha: 0}, 0.3);

				FlxTween.tween(black, {alpha: 1}, 1.6, {
					startDelay: 1,
					onComplete: function(flx:FlxTween)
					{
						// move the dialogue script ahead one line WITHOUT PLAYING THE ENTER SOUND
						updateDialogue(false);
					}
				});

				return;

			// command: set font
			case 'setFont':
				// split arguments
				var splitArgs:Array<String> = dialogueList[0].split("|");

				// set the current dialogue font
				swagDialogue.setFormat(Paths.font(splitArgs[0]), Std.parseInt(splitArgs[1]), FlxColor.BLACK, LEFT);
				dropText.setFormat(Paths.font(splitArgs[0]), Std.parseInt(splitArgs[1]), FlxColor.BLACK, LEFT);

				// move the dialogue script ahead one line WITHOUT PLAYING THE ENTER SOUND
				updateDialogue(false);

				return;

			case 'shakeScreen':
				// split arguments
				var splitArgs:Array<String> = dialogueList[0].split(",");

				FlxG.camera.shake(Std.parseFloat(splitArgs[0]), Std.parseFloat(splitArgs[1]));

				// move the dialogue script ahead one line WITHOUT PLAYING THE ENTER SOUND
				updateDialogue(false);

				return;
			// command: start text shake
			case 'startTextShake':
				// split arguments
				var splitArgs:Array<String> = dialogueList[0].split("|");

				// set the frequency and amplitude of the waves
				amplitudeX = Std.parseFloat(splitArgs[0]);
				amplitudeY = Std.parseFloat(splitArgs[1]);

				// Enable shake
				textShake = true;

				// move the dialogue script ahead one line WITHOUT PLAYING THE ENTER SOUND
				updateDialogue(false);

				return;
			// command: stop text shake
			case 'stopTextShake':
				// Disable shake
				textShake = false;
				setTextOffset();
				updateDialogue(false);

				return;

			case 'setVoice':
				// NOT WORKING FOR SOME REASON
				var splitArgs:Array<String> = dialogueList[0].split("|");

				swagDialogue.sounds = [FlxG.sound.load(Paths.sound(splitArgs[0]), 0.6)];

				updateDialogue(false);

				return;

			case 'playVoice':
				var splitArgs:Array<String> = dialogueList[0].split("|");

				var wasNull = curVoice == null;
				if(curVoice != null && curVoice.playing) curVoice.stop();

				curVoice = new FlxSound().loadEmbedded(Paths.sound(splitArgs[0]));
				if(wasNull) FlxG.sound.list.add(curVoice);
				curVoice.play();

				updateDialogue(false);

				return;

			case 'stopVoice':
				if(curVoice != null && curVoice.playing)
					curVoice.stop();

				updateDialogue(false);

				return;
		}

		if(nextDialogueThing != null) {
			nextDialogueThing();
		}

		// (Shadow Mario)
		// Camera looks up on dialogue lines from commentators on Minus songs
		var isNarrators:Bool = (curCharacter == 'minus-atrocean' || curCharacter == 'minus-dozirc');
		var lastIsNarrators:Bool = (lastCharacter == 'minus-atrocean' || lastCharacter == 'minus-dozirc' || (lastCharacter == "" && PlayState.announceStart));
		if (isNarrators && !lastIsNarrators)
		{
			// trace('Camera going up! ' + curCharacter);
			PlayState.instance.camFollow.y -= 500;
		}
		else if (!isNarrators && lastIsNarrators)
		{
			// trace('Camera going down! ' + lastCharacter);
			PlayState.instance.camFollow.y += 500;
		}
		lastCharacter = curCharacter;
	}

	function cleanDialog():Void
	{
		var splitName:Array<String> = dialogueList[0].split(":");
		curCharacter = splitName[1];
		if (expressionChars.contains(curCharacter))
		{
			curMood = splitName[2];
			dialogueList[0] = dialogueList[0].substr(splitName[1].length + splitName[2].length + 3).trim();
		}
		else if (expressionCharsMultiple.contains(curCharacter))
		{
			curMood = splitName[2];
			curMood2 = splitName[3];
			dialogueList[0] = dialogueList[0].substr(splitName[1].length + splitName[2].length + splitName[3].length + 4).trim();
		}
		else if (expressionCharsAlot.contains(curCharacter))
		{
			curMood = splitName[2];
			curMood2 = splitName[3];
			curMood3 = splitName[4];
			dialogueList[0] = dialogueList[0].substr(
				splitName[1].length + splitName[2].length + splitName[3].length + splitName[4].length + 5
			).trim();
		}	
		else
		{
			dialogueList[0] = dialogueList[0].substr(splitName[1].length + 2).trim();
		}
		dialogueList[0] = dialogueList[0].replace('[Happy]', ':D').replace('[Smile]', ':)').replace('[Frown]', ':(').replace('[Sad]', 'D:').replace('[Cat]', ':3').replace('[CatWink]', ';3').replace('[Lick]', ':J').replace('[Tongue]', ':P').replace('[Grin]', ':]').replace('[WideGrin]', 'C:').replace('[Oh]', ":O");
	}

	/**
	 *	Load the dialogue for the specified context.
	 * @param	song			The song to retrieve dialogue for
	 * @param	character		The currently played Boyfriend
	 * @param	difficulty		The song difficulty
	 * @param	difficulty		The current Girlfriend
	 * @return	The dialogue read from the appropriate file, or null if no dialogue could be found.
	 */
	/*function getDialogue(song:String, character:String, difficulty:Int, gf:String, end:Bool = false):Array<String>
	{
		// Dialogue files are located within the song-name folder.
		// File names are of the name dialogue-[character]-[girlfriend]
		// Leave the girlfriend part empty if it's default girlfriend

		song = Paths.formatToSongPath(song);

		// Exception for bf-minus
		if (character == 'bf-minus')
		{
			character = 'bf';
		}

		var difficultyName:String;

		switch (difficulty)
		{
			case 0:
				difficultyName = "easy";

			case 1:
				difficultyName = "normal";

			case 2:
				difficultyName = "hard";

			case 3:
				difficultyName = "hell";

			default:
				difficultyName = "INVALID";
		}

		var basePath:String;
		if (end)
			basePath = 'data/${song}/dialogueEnd-${character}';
		else
			basePath = 'data/${song}/dialogue-${character}';
		var gfVariant = '${basePath}${gf.replace('gf', '')}';

		var loadedDialogue:Array<String> = null;

		loadedDialogue = CoolUtil.coolTextFile(Paths.txtRaw(gfVariant, 'preload'));

		if (loadedDialogue == null || loadedDialogue.length == 0)
		{
			var difficultyVariant = '${basePath}-${difficultyName}';

			loadedDialogue = CoolUtil.coolTextFile(Paths.txtRaw(difficultyVariant, 'preload'));

			if (loadedDialogue == null || loadedDialogue.length == 0)
			{
				loadedDialogue = CoolUtil.coolTextFile(Paths.txtRaw(basePath, 'preload'));

				if (loadedDialogue == null || loadedDialogue.length == 0)
				{
					if (end)
						basePath = 'data/${song}/dialogueEnd';
					else
						basePath = 'data/${song}/dialogue';

					loadedDialogue = CoolUtil.coolTextFile(Paths.txtRaw(basePath, 'preload'));
				}
			}
		}

		return loadedDialogue;
	}*/

	/**
	 * Load the dialogue for the specified context.
	 * @param	context			Which character, girlfriend, foe, song, difficulty, and song state the dialogue is for.
	 * @return	The dialogue read from the appropriate file, or null if no dialogue could be found.
	 */
	function getDialogueFromContext(context:DialogueContext):Array<String>
	{
		// Dialogue files are located within the song-name folder.
		// File names are of the format dialogue-[character]-[girlfriend]-[foe]-[difficulty]
		// File names meant for after a song are of the format dialogueEnd-[character]-[girlfriend]-[foe]-[difficulty]
		// Leave the girlfriend and foe parts empty if they are the default
		// Leave the difficulty part empty if that doesn't matter

		var song = Paths.formatToSongPath(context.song);

		// Goth Saku GF has same dialogue has Saku GF
		if (context.gf == 'gf-saku-goth')
			context.gf = 'gf-saku';

		var difficultyName:String;

		switch (context.difficulty)
		{
			case 0:
				difficultyName = "easy";

			case 1:
				difficultyName = "normal";

			case 2:
				difficultyName = "hard";

			case 3:
				difficultyName = "hell";

			default:
				difficultyName = "INVALID";
		}

		// Determine path to dialogue variants
		// TODO: Implement path variant for foe
		// TODO: Implement path variant for gf-foe
		// TODO: Implement path variant for gf-difficulty
		// TODO: Impelment path variant for foe-difficulty
		// TODO: Implement path variant for gf-foe-difficulty
		var defaultPathNoChar = 'data/${song}/dialogue';
		var defaultPath = 'data/${song}/dialogue-bf';
		var basePath = 'data/${song}/dialogue-${context.character}';
		if (context.postSong)
		{
			defaultPathNoChar = 'data/${song}/dialogueEnd';
			defaultPath = 'data/${song}/dialogueEnd-bf';
			basePath = 'data/${song}/dialogueEnd-${context.character}';
		}

		var difficultyVariant = '${basePath}-${difficultyName}';
		var gfVariant = '${basePath}-${context.gf}';

		var variantPaths:Array<String> = [gfVariant, difficultyVariant, basePath, defaultPath, defaultPathNoChar];

		var loadedDialogue:Array<String> = null;

		for (path in variantPaths)
		{
			loadedDialogue = CoolUtil.coolTextFile(Paths.txtRaw(path, 'preload'));
			if (loadedDialogue != null && loadedDialogue.length > 0) {
				break;
			}
		}

		var processed:Array<String> = [];

		for(line in loadedDialogue) {
			var tLine = line.trim();
			if(tLine != "" && tLine != "\n" && tLine != "\r\n" && tLine != "\r") {
				processed.push(line);
			}
		}

		return processed;
	}

	override public function draw():Void
	{
		if(angryEnding != null) angryEnding.draw();
		if(happyEnding != null) happyEnding.draw();
		super.draw();
	}
}
