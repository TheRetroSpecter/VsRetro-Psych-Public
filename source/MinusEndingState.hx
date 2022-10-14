package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup.FlxTypedGroup;

class MinusEndingState extends FlxSubState {
	var minusEndBG:FlxSprite;
	var minusEndingGroup:FlxTypedGroup<FlxSprite>;
	var minusCardGroup:FlxTypedGroup<FlxSprite>;
	var background:FlxSpriteExtra;
	var enterPressedOnce:Bool = false;

	override function create() {
		minusEndBG = new FlxSprite(0, 0).loadGraphic(Paths.image("minusEndBG"));
		minusEndBG.scrollFactor.set();
		minusEndBG.antialiasing = ClientPrefs.globalAntialiasing;
		minusEndBG.screenCenter();
		minusEndBG.alpha = 0;
		minusEndBG.scale.set(0.7, 0.7);
		add(minusEndBG);

		background = new FlxSpriteExtra(0,0).makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		background.scrollFactor.set();
		background.alpha = 0;
		add(background);

		// (Tech) Continue text and droptext

		minusCardGroup = new FlxTypedGroup<FlxSprite>();

		var continueText1 = new FlxText(902, 682, 0, "Press Enter to continue", 24);
		continueText1.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.BLACK);
		continueText1.alpha = 0;
		minusCardGroup.add(continueText1);

		var continueText2 = new FlxText(900, 680, 0, "Press Enter to continue", 24);
		continueText2.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE);
		continueText2.alpha = 0;
		minusCardGroup.add(continueText2);

		add(minusCardGroup);

		minusEndingGroup = new FlxTypedGroup<FlxSprite>();

		var thanksTextDrop:FlxText = new FlxText(3, 53, 0, "Thank you for playing the Minus story update!", 48);
		thanksTextDrop.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.BLACK);
		thanksTextDrop.screenCenter(X);
		thanksTextDrop.alpha = 0;
		minusEndingGroup.add(thanksTextDrop);

		var minusEndingDescription1Drop:FlxText = new FlxText(2, 202, 0, "Freeplay also has many added secrets and unlockables.", 26);
		minusEndingDescription1Drop.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.BLACK);
		minusEndingDescription1Drop.screenCenter(X);
		minusEndingDescription1Drop.alpha = 0;
		minusEndingGroup.add(minusEndingDescription1Drop);

		var minusEndingDescription2Drop:FlxText = new FlxText(2, 252, 0, "To start you off, type: ", 26);
		minusEndingDescription2Drop.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.BLACK);
		minusEndingDescription2Drop.alpha = 0;
		minusEndingDescription2Drop.screenCenter(X);
		minusEndingGroup.add(minusEndingDescription2Drop);

		var minusEndingDescription3Drop:FlxText = new FlxText(2, 302, 0, "MagnificentMajesticMarketableMarvelousMegaMommyMothyMilkies", 26);
		minusEndingDescription3Drop.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.BLACK);
		minusEndingDescription3Drop.alpha = 0;
		minusEndingDescription3Drop.screenCenter(X);
		minusEndingGroup.add(minusEndingDescription3Drop);

		var minusEndingDescription4Drop:FlxText = new FlxText(2, 352, 0, "on Sakuroma's story mode select screen. Please also check out the credits", 26);
		minusEndingDescription4Drop.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.BLACK);
		minusEndingDescription4Drop.alpha = 0;
		minusEndingDescription4Drop.screenCenter(X);
		minusEndingGroup.add(minusEndingDescription4Drop);

		var minusEndingDescription5Drop:FlxText = new FlxText(2, 402, 0, "to see everyone who worked on this mod. Enjoy the rest of 1.5!", 26);
		minusEndingDescription5Drop.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.BLACK);
		minusEndingDescription5Drop.alpha = 0;
		minusEndingDescription5Drop.screenCenter(X);
		minusEndingGroup.add(minusEndingDescription5Drop);

		var continueText = new FlxText(902, 682, 0, "Press Enter to continue", 24);
		continueText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.BLACK);
		continueText.alpha = 0;
		minusEndingGroup.add(continueText);

		// (Tech) SPLIT REAL TEXT

		var thanksText:FlxText = new FlxText(0, 50, 0, thanksTextDrop.text, 48);
		thanksText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE);
		thanksText.screenCenter(X);
		thanksText.alpha = 0;
		minusEndingGroup.add(thanksText);

		var minusEndingDescription1:FlxText = new FlxText(0, 200, 0, minusEndingDescription1Drop.text, 26);
		minusEndingDescription1.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE);
		minusEndingDescription1.screenCenter(X);
		minusEndingDescription1.alpha = 0;
		minusEndingGroup.add(minusEndingDescription1);

		var minusEndingDescription2:FlxText = new FlxText(0, 250, 0, minusEndingDescription2Drop.text, 26);
		minusEndingDescription2.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE);
		minusEndingDescription2.alpha = 0;
		minusEndingDescription2.screenCenter(X);
		minusEndingGroup.add(minusEndingDescription2);

		var minusEndingDescription3:FlxText = new FlxText(0, 300, 0, minusEndingDescription3Drop.text, 26);
		minusEndingDescription3.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE);
		minusEndingDescription3.alpha = 0;
		minusEndingDescription3.screenCenter(X);
		minusEndingGroup.add(minusEndingDescription3);

		var minusEndingDescription4:FlxText = new FlxText(0, 350, 0, minusEndingDescription4Drop.text, 26);
		minusEndingDescription4.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE);
		minusEndingDescription4.alpha = 0;
		minusEndingDescription4.screenCenter(X);
		minusEndingGroup.add(minusEndingDescription4);

		var minusEndingDescription5:FlxText = new FlxText(0, 400, 0, minusEndingDescription5Drop.text, 26);
		minusEndingDescription5.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE);
		minusEndingDescription5.alpha = 0;
		minusEndingDescription5.screenCenter(X);
		minusEndingGroup.add(minusEndingDescription5);

		var continueText = new FlxText(900, 680, 0, "Press Enter to continue", 24);
		continueText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE);
		continueText.alpha = 0;
		minusEndingGroup.add(continueText);


		add(thanksText);
		add(minusEndingGroup);

		FlxTween.tween(minusEndBG, {alpha: 1},1);
		fadeGroup(minusCardGroup, 1, null);

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		cameras[0].angle = 0;

		
			
		super.create();
	}

	override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.ENTER) {
			if (enterPressedOnce/* || PlayState.finishedMinus*/) {
				//SaveDataManager.instance.endingData.setFinishedMinusFlag(true);
				if(FlxG.sound.music != null) {
					FlxG.sound.music.persist = true;
				}
				MusicBeatState.nextGhostAllowed = true;
				MusicBeatState.songLoadingScreen = "loading";
				MusicBeatState.switchState(new StoryMenuState());
			}
			else {
				FlxTween.tween(background, {alpha: 0.6},1);
				fadeGroup(minusEndingGroup, 1, null);
				fadeGroup(minusCardGroup, 0, null);
				enterPressedOnce = true;
			}
		}
	}

	/*  (Arcy)
	*   Function used to tween the alpha of every sprite in the group to 0. Also sets stopspamming to false when done.
	*   @param  group               The group of FlxSprites to fade out by tweening the alpha of each sprite to 0.
	*   @param  alphaVal            The alpha for the group of FlxSprites to fade to.
	*   @param  stopSpammingFlag    Set to true if the stopspamming flag should be set to false when the tweens are complete.
	*/
	function fadeGroup(group:FlxTypedGroup<FlxSprite>, alphaVal:Float, callback:Null<TweenCallback>)
	{
		if (callback != null)
		{
			// (Arcy) This is odd to do, but it will reduce the amount of function creations and calls
			var firstMember = group.members[0];
			FlxTween.tween(firstMember, {alpha: alphaVal}, 1, {ease: FlxEase.cubeInOut, onComplete: callback});
			group.remove(firstMember);

			for (spr in group)
			{
				FlxTween.tween(spr, {alpha: alphaVal}, 1, {ease: FlxEase.cubeInOut});
			}

			group.insert(0, firstMember);
		}
		else
		{
			for (spr in group)
			{
				FlxTween.tween(spr, {alpha: alphaVal}, 1, {ease: FlxEase.cubeInOut});
			}
		}
	}
}
