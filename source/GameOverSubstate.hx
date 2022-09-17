package;

import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.system.FlxSound;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

using StringTools;

// (Arcy)
// A data container for storing the dialgoue string and a string for checking what mood portrait to use.
class DialogueData
{
	public var dialogue:String;
	public var mood:String;

	public function new(text:String, emotion:String)
	{
		dialogue = text;
		mood = emotion;
	}
}

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Boyfriend;
	var camFollowOrig:FlxPoint;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;

	static var ectospasmInitialDialogue:Array<DialogueData>;
	static var ectospasmDeathDialogue:Array<DialogueData>;

	public var hintText:FlxFixedTypeText;
	public var hintDropText:FlxFixedText;

	var stageSuffix:String = "";
	var isMinus:Bool = false;

	public static var characterName:String = 'bf';
	public static var animSuffix:String = '';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public static var cameraOffset:FlxPoint = new FlxPoint();

	public static var instance:GameOverSubstate;

	public static function resetVariables() {
		characterName = 'bf';
		animSuffix = '';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
		cameraOffset.set(0, 0);
	}

	override function create()
	{
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);

		super.create();
	}

	var deathInitialSfx:FlxSound;
	var deathLoopSfx:FlxSound;

	var allowRetry:Bool = true;
	var disableInput:Bool = false;
	var dialogueIndex:Int = 0;

	var isOnLoop = false;
	var startVibin:Bool = false;
	var isFakeDeath:Bool = false;
	var hasShaken:Bool = false;

	public static function shouldLoadGameOverDialogue() {
		var formattedSong = Paths.formatToSongPath(PlayState.genericSong);

		if(formattedSong == 'ectospasm') {
			return true;
		}
		return false;
	}

	public static function loadRetroPortrait() {
		var retroPortrait = new FlxSprite(20, 100);
		retroPortrait.frames = Paths.getSparrowAtlas('characters/portraits/Zerktro', 'shared');
		retroPortrait.animation.addByPrefix('Neutral', 'Neutral', 24, false);
		retroPortrait.animation.addByPrefix('Talking', 'Talking', 24, false);
		retroPortrait.animation.addByPrefix('Smug', 'Smug', 24, false);
		retroPortrait.animation.addByPrefix('Happy', 'Happy', 24, false);
		retroPortrait.animation.addByPrefix('Sad', 'Sad', 24, false);
		retroPortrait.animation.addByPrefix('Laugh', 'Laugh', 24, false);
		retroPortrait.animation.addByPrefix('Eyeroll', 'Eyeroll', 24, false);
		retroPortrait.animation.addByPrefix('Blush', 'Blush', 24, false);
		retroPortrait.antialiasing = ClientPrefs.globalAntialiasing;
		retroPortrait.scale.set(0.66, 0.66);

		return retroPortrait;
	}

	public static function loadSpeechBubble() {
		var speechBubble = new FlxSprite(25, 400);
		speechBubble.frames = Paths.getSparrowAtlas('speech_bubble_talking', 'shared');
		speechBubble.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
		speechBubble.antialiasing = ClientPrefs.globalAntialiasing;
		speechBubble.scale.set(0.9, 0.9);
		speechBubble.flipX = true;

		return speechBubble;
	}

	public var retroPortrait:FlxSprite;
	public var speechBubble:FlxSprite;

	public function new(x:Float, y:Float, camX:Float, camY:Float, ?isFakeDeath:Bool = false)
	{
		super();

		if(PlayState.instance.retroPortrait != null) {
			retroPortrait = PlayState.instance.retroPortrait;
		}
		if(PlayState.instance.speechBubble != null) {
			speechBubble = PlayState.instance.speechBubble;
		}

		CoolUtil.precacheMusic(loopSoundName);

		this.isFakeDeath = isFakeDeath;

		var formattedSong = PlayState.genericSong;//Paths.formatToSongPath(PlayState.SONG.song);

		if(formattedSong == 'ectospasm') {
			GameOverSubstate.loadEctospasmDialogue();
		}

		PlayState.instance.setOnLuas('inGameOver', true);

		Conductor.songPosition = 0;

		boyfriend = new Boyfriend(x, y, characterName);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		boyfriend.shader = null; // Removes any shading
		add(boyfriend);

		camFollowOrig = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);
		if(characterName == 'bf-wrath-death') {
			//boyfriend.updateHitbox();
			camFollowOrig.x -= 350;
			camFollowOrig.y -= 50;
		}
		camFollow = camFollowOrig.copyTo();

		if(characterName == 'bf-wrath-death') {
			deathInitialSfx = new FlxSound().loadEmbedded(Paths.sound("deathSfxInitial"));
			deathLoopSfx = new FlxSound().loadEmbedded(Paths.sound("bfDeathLoop"), true);
			FlxG.sound.list.add(deathInitialSfx);
			FlxG.sound.list.add(deathLoopSfx);

			deathInitialSfx.play();

			new FlxTimer().start(deathInitialSfx.length / 1000, (tmr:FlxTimer) -> {
				deathLoopSfx.play(true);
			});
		}
		switch (formattedSong)
		{
			default: FlxG.sound.play(Paths.sound(deathSoundName));
			case "preseason"|"acidiron"|"sigma":
				{
					isMinus = true;
					var hitinBalls = new FlxSound().loadEmbedded(Paths.sound('MetroFootballDeath'));
					hitinBalls.play();
					FlxG.sound.play(Paths.sound(deathSoundName));
				}
			case "preppy"|"pvertime": FlxG.sound.play(Paths.sound('MakuMetroDeath'));
		}

		if (!isMinus && characterName == 'bf-minus-death')
		{
			isMinus = true;
			var hitinBalls = new FlxSound().loadEmbedded(Paths.sound('MetroFootballDeath'));
			hitinBalls.play();
		}
		Conductor.changeBPM(100);
		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath' + animSuffix);

		if(shouldLoadGameOverDialogue()) {
			hintText = new FlxFixedTypeText(150, 560, 1050, "", 50);
			hintText.setFormat(Paths.font('aApiNyala.ttf'), 50, FlxColor.fromRGB(42, 136, 164), LEFT);
			hintText.sounds = [FlxG.sound.load(Paths.sound('retroAngryVoice'), 0.3)];
			hintText.antialiasing = ClientPrefs.globalAntialiasing;
			hintText.cameras = [PlayState.instance.camOther];

			hintDropText = new FlxFixedText(153, 562, 1050, "", 50);
			hintDropText.setFormat(Paths.font('aApiNyala.ttf'), 50, FlxColor.fromRGB(42, 136, 164), LEFT);
			hintDropText.color = FlxColor.BLACK;
			hintDropText.antialiasing = ClientPrefs.globalAntialiasing;
			hintDropText.cameras = [PlayState.instance.camOther];
		}

		if (characterName == 'bf-wrath-death')
		{
			boyfriend.animation.finishCallback = function(str:String)
			{
				boyfriend.animation.finishCallback = null;
				isOnLoop = true;
				startVibin = true;
				// This gets called before update
				FlxG.sound.playMusic(Paths.music('Skill_Issue'));
				//remove(boyfriend);
				//boyfriend = new Boyfriend(x, y, 'bf-wrath-death2');
				//boyfriend.playAnim('deathLoop');
				//add(boyfriend);

				if (formattedSong == 'ectospasm' && (PlayState.deaths >= 1 || PlayState.shownHint))
				{
					addDialogue();
				}
			};
		}
			
		else if (formattedSong == 'ectospasm')
		{
			boyfriend.animation.finishCallback = function(str:String)
			{
				boyfriend.animation.finishCallback = null;
				isOnLoop = true;
				startVibin = true;
				if (PlayState.deaths >= 1 || PlayState.shownHint)
				{
					addDialogue();
				}
			}
		}

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);

		if(isFakeDeath) {
			FlxG.camera.follow(camFollowPos, LOCKON, 1);
			updateCamera = true;
			isFollowingAlready = true;
		}

		// Count the deaths for Ectospasm
		if (formattedSong == 'ectospasm')
		{
			PlayState.deaths++;
			//if(PlayState.shownHint) trace('deaths: ' + (PlayState.deaths + 2)); //+2 because first death is not any dialogue ID, and death 2 is ID 0
			//else trace('First death');

			if (PlayState.deaths >= ectospasmDeathDialogue.length)
			{
				PlayState.deaths = 0;
			}
		}

		if (formattedSong == 'ectospasm' && PlayState.deaths >= 1 && !PlayState.shownHint)
		{
			PlayState.instance.camHUD.zoom = 1;
			disableInput = true;
			allowRetry = false;
		}

		// (Arcy) Don't allow skipping on the special chart dialogue
		if (formattedSong == 'ectospasm' && PlayState.deaths == 6 && PlayState.shownHint)
		{
			disableInput = true;
		}

		//if(allowRetry && !disableInput && ClientPrefs.instantRespawn)
		//{
		//	MusicBeatState.resetState();
		//}
	}

	function addDialogue() {
		add(retroPortrait);
		add(speechBubble);
		add(hintDropText);
		add(hintText);

		if (PlayState.deaths >= 1 && !PlayState.shownHint)
		{
			retroPortrait.animation.play(ectospasmInitialDialogue[dialogueIndex].mood);
		}
		else
		{
			retroPortrait.animation.play(ectospasmDeathDialogue[PlayState.deaths].mood);
		}
		FlxTween.tween(retroPortrait, {alpha: 1}, 0.1);
		speechBubble.animation.play('normalOpen');
		speechBubble.animation.finishCallback = function(anim:String):Void
		{
			if (PlayState.deaths >= 1 && !PlayState.shownHint)
			{
				hintText.resetText(ectospasmInitialDialogue[dialogueIndex].dialogue);
			}
			else
			{
				hintText.resetText(ectospasmDeathDialogue[PlayState.deaths].dialogue);
			}
			hintText.start(0.04, true);
			hintText.completeCallback = function()
			{
				disableInput = false;
			}
		}
	}

	var isFollowingAlready:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.curFrame >= 1 && characterName == 'zerktro-player-death' && !hasShaken)
			{
				FlxG.camera.shakeEnabled = true;
				FlxG.camera.shake(0.03, 0.5);
				hasShaken = true;
			}

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);
		if(updateCamera) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			//camFollow.copyFrom(camFollowOrig).add(-boyfriend.offset.x, -boyfriend.offset.y);
			camFollowPos.setPosition(
				FlxMath.lerp(camFollowPos.x, camFollow.x + cameraOffset.x, lerpVal),
				FlxMath.lerp(camFollowPos.y, camFollow.y + cameraOffset.y, lerpVal)
				);
		}

		if (controls.ACCEPT && allowRetry && !disableInput)
		{
			endBullshit();
		}
		else if (controls.ACCEPT && startVibin && !disableInput)
		{
			dialogueIndex++;
			if (dialogueIndex >= ectospasmInitialDialogue.length)
			{
				PlayState.shownHint = true;
				PlayState.deaths = -1;
				endBullshit();
			}
			else
			{
				FlxG.sound.play(Paths.sound('clickText'), 0.4);
				if(retroPortrait != null) {
					retroPortrait.animation.play(ectospasmInitialDialogue[dialogueIndex].mood);
				}
				if(hintText != null) {
					hintText.resetText(ectospasmInitialDialogue[dialogueIndex].dialogue);
					hintText.start(0.04, true);
				}
			}
		}
		//if (controls.ACCEPT)
		//{
		//	endBullshit();
		//}

		if (controls.BACK && !isFakeDeath)
		{
			FlxG.sound.music.stop();
			FlxG.sound.music.persist = false;
			FlxG.sound.music.destroy();
			FlxG.sound.music = null;
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.trueEctospasm = false;

			if(deathLoopSfx != null) {
				deathLoopSfx.stop();
			}

			if (PlayState.isStoryMode) {
				PlayState.randomMode = false;
				PlayState.instadeathMode = false;
				MusicBeatState.nextGhostAllowed = true;
				MusicBeatState.songLoadingScreen = "loading";
				MusicBeatState.switchState(new StoryMenuState());
			}
			else
				MusicBeatState.switchState(new FreeplayState());

			if (MainMenuState.songName.startsWith('Intro')) MainMenuState.songName = MainMenuState.songName.replace('Intro', 'Menu');
			FlxG.sound.playMusic(Paths.music(MainMenuState.songName));
			FlxG.sound.music.persist = true;
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
		}

		if (boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('firstDeath'))
		{
			if(boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				updateCamera = true;
				isFollowingAlready = true;
			}

			if (boyfriend.animation.curAnim.finished)
			{
				coolStartDeath();
				boyfriend.startedDeath = true;
				startVibin = true;
			}
		}

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);

		if(hintDropText != null && hintText != null) {
			if (hintDropText.text != hintText.text)
				hintDropText.text = hintText.text;
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (startVibin && !isEnding)
		{
			boyfriend.playAnim('deathLoop' + animSuffix, true);
		}

		//FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			var formattedSong = Paths.formatToSongPath(PlayState.genericSong);
			//// If they retry early, swap the sprite here.
			//if(!isOnLoop && boyfriend.curCharacter == 'bf-wrath-death')
			//{
			//	remove(boyfriend);
			//	boyfriend = new Boyfriend(boyfriend.x, boyfriend.y, 'bf-wrath-death2');
			//	boyfriend.playAnim('deathLoop');
			//	add(boyfriend);
			//}
			isEnding = true;
			boyfriend.playAnim('deathConfirm' + animSuffix, true);

			var loopSoundPath = 'assets/shared/music/$loopSoundName.ogg'; 

			if(FlxG.sound.music != null) FlxG.sound.music.stop();
			//FlxG.sound.music.persist = true;
			//FlxG.sound.music.destroy();
			//FlxG.sound.music = null;
			if(deathLoopSfx != null) {
				deathLoopSfx.stop();
			}

			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				var fadeInColor = isFakeDeath ? FlxColor.WHITE : FlxColor.BLACK;
				FlxG.cameras.list[FlxG.cameras.list.length - 1].fade(fadeInColor, 2, false);

				FlxG.camera.fade(fadeInColor, 2, false, function()
				{
					if(formattedSong == 'ectospasm') {
						if(PlayState.storyDifficulty == Difficulty.APOCALYPSE) {
							if (PlayState.deaths == 6 && PlayState.shownHint)
							{
								PlayState.trueEctospasm = true;
							}
							else if (PlayState.deaths == 7)
							{
								PlayState.trueEctospasm = false;
							}
						} else {
							if (PlayState.deaths == 6 && PlayState.shownHint)
							{
								// (Tech) Checks for true apocalyse and increases the difficulty by 1 if it is.
								var newDifficulty:Int;
								newDifficulty = PlayState.storyDifficulty < 4 ? PlayState.storyDifficulty + 1 : PlayState.storyDifficulty;
								PlayState.SONG = Song.loadFromJson(('ectospasm' +  Difficulty.getDifficultyFilePath(newDifficulty)), 'ectospasm');
								PlayState.trueEctospasm = true;
							}
							else if (PlayState.deaths == 7)
							{
								PlayState.SONG = Song.loadFromJson(('ectospasm' + Difficulty.getDifficultyFilePath(PlayState.storyDifficulty)), 'ectospasm');
								if (PlayState.storyDifficulty == 3) Paths.currentTrackedSounds = [];
								PlayState.trueEctospasm = false;
							}
						}
					}

					if(isFakeDeath) {
						new FlxTimer().start(0.75, function(tmr:FlxTimer) {
							FlxTransitionableState.skipNextTransIn = true;
							FlxTransitionableState.skipNextTransOut = true;
							LoadingState.loadAndSwitchState(new PlayState(), true);
							//MusicBeatState.resetState();
						});
					} else {
						MusicBeatState.resetState();
					}
				});
			});
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
		}
	}

	/**	(Arcy)
	 *	Method used to initiate the Ectospasm string arrays.
	 *	Call this once Ectospasm is played.
	 */
	public static function loadEctospasmDialogue()
	{
		if (ectospasmInitialDialogue == null)
		{
			ectospasmInitialDialogue = new Array<DialogueData>();

			// Initial dialogue
			var loadedDialogue:Array<String> = CoolUtil.coolTextFile(Paths.txt('ectospasm/dialogue-intro', 'preload'));
			for (str in loadedDialogue)
			{
				var split:Array<String> = str.split(':');
				ectospasmInitialDialogue.push(new DialogueData(split[1], split[0]));
			}
		}
		if (ectospasmDeathDialogue == null)
		{
			ectospasmDeathDialogue = new Array<DialogueData>();

			// Death dialogue
			var loadedDialogue:Array<String> = CoolUtil.coolTextFile(Paths.txt('ectospasm/dialogue-deathlines', 'preload'));
			for (str in loadedDialogue)
			{
				var split:Array<String> = str.split(':');
				ectospasmDeathDialogue.push(new DialogueData(split[1], split[0]));
			}
		}
	}
}
