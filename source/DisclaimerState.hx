import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup.FlxTypedGroup;

private enum State
{
	Flashing;
	Suggestive;
}

class DisclaimerState extends FlxState {
	var state:State = Flashing;

	var selectSprite:FlxSprite;
	var checkbox:FlxSprite;
	var checkboxOutline:FlxSprite;
	var checked:Bool = false;
	var isFlashing:Bool = true;
	var stopspamming:Bool = false;

	var flashingGroup:FlxTypedGroup<FlxSprite>;
	var suggestiveGroup:FlxTypedGroup<FlxSprite>;
	var confirmGroup:FlxTypedGroup<FlxSprite>;

	override function create()
	{
		var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
		var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
		var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

		FlxG.save.bind('vsretrospecterV2', 'FNF Vs Retrospecter Psych');

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		PlayerSettings.init();
		ClientPrefs.loadPrefs();
		Unlocks.loadUnlocks();
		Highscore.load();

		if (!FlxG.save.data.flashingLightsDisclaimer && !FlxG.save.data.suggestiveContentDisclaimer)
		{
			FlxG.switchState(new TitleState());
			return;
		}

		FlxG.mouse.visible = true;
	
		// Check if the warning even needs to be shown
		//if (!FlxG.save.data.flashing)
			//FlxG.switchState(new TitleState());

		// Suggestive Content
		suggestiveGroup = new FlxTypedGroup<FlxSprite>();

		var suggestiveText:FlxFixedText = new FlxFixedText(0, 50, 0, "Suggestive Content", 72);
		suggestiveText.setFormat(Paths.font("vcr.ttf"), 72, FlxColor.WHITE);
		suggestiveText.screenCenter(X);
		suggestiveText.alpha = 0;
		suggestiveGroup.add(suggestiveText);
		var suggestiveDescription1:FlxFixedText = new FlxFixedText(0, 200, 0, "This mod contains the sin of LUST, who has suggestive", 36);
		suggestiveDescription1.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE);
		suggestiveDescription1.screenCenter(X);
		suggestiveDescription1.alpha = 0;
		suggestiveGroup.add(suggestiveDescription1);
		var suggestiveDescription2:FlxFixedText = new FlxFixedText(0, 250, 0, " adult themes. If that type of stuff makes you", 36);
		suggestiveDescription2.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE);
		suggestiveDescription2.alpha = 0;
		suggestiveDescription2.screenCenter(X);
		suggestiveGroup.add(suggestiveDescription2);
		var suggestiveDescription3:FlxFixedText = new FlxFixedText(0, 300, 0, " uncomfortable, avoid the mommy moth. You have been warned.", 36);
		suggestiveDescription3.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE);
		suggestiveDescription3.alpha = 0;
		suggestiveDescription3.screenCenter(X);
		suggestiveGroup.add(suggestiveDescription3);
		
		var bgArtSuggestive = new FlxSprite().loadGraphic(Paths.image('beware_of_the_horny', 'preload'));
		bgArtSuggestive.alpha = 0;
		bgArtSuggestive.screenCenter(X);
		bgArtSuggestive.y = 325;
		suggestiveGroup.add(bgArtSuggestive);
		
		// Flashing lights warning
		flashingGroup = new FlxTypedGroup<FlxSprite>();

		var blackBg:FlxSprite = new FlxSpriteExtra(0, 0).makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		flashingGroup.add(blackBg);
		var warningText:FlxFixedText = new FlxFixedText(0, 50, 0, "WARNING", 72);
		warningText.setFormat(Paths.font("vcr.ttf"), 72, FlxColor.WHITE);
		warningText.screenCenter(X);
		flashingGroup.add(warningText);
		var description1:FlxFixedText = new FlxFixedText(0, 200, 0, "This mod contains flashing lights", 36);
		description1.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE);
		description1.screenCenter(X);
		flashingGroup.add(description1);
		var description2:FlxFixedText = new FlxFixedText(0, 250, 0, "and other effects that may trigger seizures", 36);
		description2.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE);
		description2.screenCenter(X);
		flashingGroup.add(description2);
		var description3:FlxFixedText = new FlxFixedText(0, 300, 0, "for people with photosensitive epilepsy.", 36);
		description3.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE);
		description3.screenCenter(X);
		flashingGroup.add(description3);

		var askText:FlxFixedText = new FlxFixedText(0, 400, 0, "Do you want to keep these flashy effects on?", 36);
		askText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE);
		askText.screenCenter(X);
		flashingGroup.add(askText);

		selectSprite = new FlxSpriteExtra(460, 495).makeSolid(140, 75, FlxColor.GRAY);
		flashingGroup.add(selectSprite);
		var yes:FlxFixedText = new FlxFixedText(470, 500, "YES", 64);
		yes.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE);
		flashingGroup.add(yes);
		var no:FlxFixedText = new FlxFixedText(690, 500, "NO", 64);
		no.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE);
		flashingGroup.add(no);

		var bgArt = new FlxSprite(0, 0).loadGraphic(Paths.image('neonBG', 'preload'));
		bgArt.antialiasing = ClientPrefs.globalAntialiasing;
		flashingGroup.add(bgArt);

		// Confirmation text/options
		confirmGroup = new FlxTypedGroup<FlxSprite>();

		var confirmText = new FlxFixedText(0, 650, 0, "Hit Enter to Confirm", 36);
		confirmText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE);
		confirmText.screenCenter(X);
		confirmGroup.add(confirmText);

		checkboxOutline = new FlxSpriteExtra(425, 590).makeSolid(40, 40, FlxColor.fromRGB(30, 30, 30));
		confirmGroup.add(checkboxOutline);
		checkbox = new FlxSpriteExtra(429, 594).makeSolid(32, 32, FlxColor.WHITE);
		confirmGroup.add(checkbox);

		var noRemindText:FlxFixedText = new FlxFixedText(475, 590, 0, "Don't tell me again", 36);
		noRemindText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE);
		confirmGroup.add(noRemindText);

		add(suggestiveGroup);
		add(flashingGroup);
		add(confirmGroup);

		// Go to suggestive disclaimer
		if (!FlxG.save.data.flashingLightsDisclaimer)
		{
			state = Suggestive;

			for (spr in flashingGroup)
			{
				spr.alpha = 0;
			}

			for (spr in suggestiveGroup)
			{
				spr.alpha = 1;
			}
		}
		// Go to flashing lights disclaimer
		else
		{
			state = Flashing;
		}

		
			
		super.create();
	}

	override function update(elapsed:Float) {
		if (state == Flashing && !stopspamming)
		{
			mouseStuff();

			if ((FlxG.keys.justPressed.LEFT || PlayerSettings.player1.controls.UI_LEFT_P) && selectSprite.x == 660)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				selectSprite.x = 460;
				isFlashing = true;
			}
			else if ((FlxG.keys.justPressed.RIGHT || PlayerSettings.player1.controls.UI_RIGHT_P) && selectSprite.x == 460)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				selectSprite.x = 660;
				isFlashing = false;
			}
			else if (FlxG.keys.justPressed.ENTER || PlayerSettings.player1.controls.ACCEPT)
			{
				if (checked)
				{
					FlxG.save.data.flashingLightsDisclaimer = false;
					FlxG.save.flush();
				}

				if (!FlxG.save.data.suggestiveContentDisclaimer) FlxG.switchState(new TitleState());
				else
				{
					state = Suggestive;
					stopspamming = true;

					ClientPrefs.flashing = isFlashing;
					ClientPrefs.chromatic = isFlashing;
					ClientPrefs.ghostTrails = isFlashing;

					fadeGroup(flashingGroup, 0, null);
					fadeGroup(confirmGroup, 0, function(flx:FlxTween)
					{
						if (checked)
						{
							checked = false;
							checkbox.color = FlxColor.WHITE;
						}

						fadeGroup(suggestiveGroup, 1, null);
						fadeGroup(confirmGroup, 1, function(flx:FlxTween) { stopspamming = false; });
					});

					FlxG.sound.play(Paths.sound('confirmMenu'), 0.25);

					ClientPrefs.saveSettings();
				}
			}
		}
		else if (state == Suggestive && !stopspamming)
		{
			mouseStuff();

			if (FlxG.keys.justPressed.ENTER || PlayerSettings.player1.controls.ACCEPT)
			{
				if (checked)
				{
					FlxG.save.data.suggestiveContentDisclaimer = false;
					FlxG.save.flush();
				}
				FlxG.switchState(new TitleState());
			}
		}
	}

	/*  (Arcy)
	*   Function that handles all mouse collision/pressed/over/etc. Called within the update function. 
	*/
	function mouseStuff()
	{
		// (Arcy) Check mouse collision with checkbox
		if (FlxG.mouse.x >= checkboxOutline.x && FlxG.mouse.x <= checkboxOutline.x + checkboxOutline.width &&
			FlxG.mouse.y >= checkboxOutline.y && FlxG.mouse.y <= checkboxOutline.y + checkboxOutline.height)
		{
			if (FlxG.mouse.justPressed)
			{
				checked = !checked;
			}

			if (checked)
			{
				checkbox.color = FlxColor.fromRGB(225, 200, 0);
			}
			else
			{
				checkbox.color = FlxColor.GRAY;
			}
		}
		else
		{
			if (!checked)
			{
				checkbox.color = FlxColor.WHITE;
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
