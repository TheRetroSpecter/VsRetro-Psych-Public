package;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSubState;
import options.QuickSettingsSubState;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.text.FlxText;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxBasic;

using StringTools;

class UnlockableMusicBeatState extends MusicBeatState
{
	var unlockedSongs:Array<String>;
	var unlockedModes:Array<String>;
	var unlockedChars:Array<String>;

	// Stuff for displaying unlocks
	public var unlockFadeBG:FlxSpriteExtra;
	var unlockSprites:FlxTypedGroup<FlxSprite>;
	var unlockDescription:FlxFixedText;
	public var uniqueUnlockText:String;
	public var unlocking:Bool;

	var unlock_stopspamming:Bool = false;

	override function create() {
		super.create();

		unlockedSongs = Unlocks.recentlyUnlockedSongs;
		unlockedModes = Unlocks.recentlyUnlockedModes;
		unlockedChars = Unlocks.recentlyUnlockedChars;

		unlockFadeBG = new FlxSpriteExtra(0, 0).makeSolid(FlxG.width, FlxG.height);
		unlockFadeBG.color = FlxColor.BLACK;
		unlockFadeBG.alpha = 0.9;
		unlockFadeBG.visible = false;

		unlockSprites = new FlxTypedGroup<FlxSprite>();

		unlockDescription = new FlxFixedText(0, 600, FlxG.width, "", 32);
		unlockDescription.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		unlockDescription.screenCenter(X);
		unlockDescription.visible = false;

        add(unlockFadeBG);
		add(unlockSprites);
		add(unlockDescription);

		if (unlockedSongs.length > 0 || unlockedModes.length > 0 || unlockedChars.length > 0)
			displayUnlocks();
	}

	override function update(elapsed:Float)
	{
		if(unlocking) {
			if (controls.ACCEPT || controls.BACK)
			{
				unlock_stopspamming = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
	
				// Remove the unlock group
				if (unlockedSongs.length > 0)
				{
					//unlockedSongs = [];
					Unlocks.clearRecentType(SONG);
				}
				else if (unlockedModes.length > 0)
				{
					//unlockedModes = [];
					Unlocks.clearRecentType(MODE);
				}
				else if (unlockedChars.length > 0)
				{
					//unlockedChars = [];
					Unlocks.clearRecentType(CHAR);
				}
	
				for (i in 0...unlockSprites.length)
				{
					FlxTween.tween(unlockSprites.members[i], {alpha: 0}, 0.5);
				}
				FlxTween.tween(unlockDescription, {alpha: 0}, 0.5, {
					onComplete: function(flx:FlxTween)
					{
						unlockSprites.clear(); // (neo) maybe destroy this?
						displayUnlocks();
					}
				});
			}
		}
		super.update(elapsed);
	}

	/** (Arcy)
	* A somewhat recursive function (not really I just made it in a really fucking weird way) for displaying all new unlocks in its own UI.
	* This is only called within the logic of the update method.
	**/
	public function displayUnlocks()
	{
		Unlocks.fixOrder();
		unlocking = true;

		// Nothing left to unlock
		if (unlockedSongs.length == 0 && unlockedModes.length == 0 && unlockedChars.length == 0)
		{
			FlxTween.tween(unlockFadeBG, {alpha: 0}, 0.5);
			for (i in 0...unlockSprites.length)
			{
				FlxTween.tween(unlockSprites.members[i], {alpha: 0}, 0.5);
			}
			FlxTween.tween(unlockDescription, {alpha: 0}, 0.5, {
				onComplete: function(flx:FlxTween)
				{
					unlockFadeBG.visible = false;
					unlockSprites.visible = false;
					unlockDescription.visible = false;

					unlocking = false;
					unlock_stopspamming = false;
				}
			});
			return;
		}

		if (unlockedSongs.length > 0) {
			showUnlockedSongs();
		} else if (unlockedModes.length > 0) {
			showUnlockedModes();
		} else {
			showUnlockedCharacters();
		}
	}

	function showUnlockedSongs() {
		for (i in 0...unlockedSongs.length)
		{
			var unlockSprite = new Alphabet(0, 0, unlockedSongs[i], true, false);
			unlockSprite.screenCenter();
			if (unlockedSongs.length % 2 == 1)
			{
				unlockSprite.y += (i - (unlockedSongs.length - 1) / 2) * 100;
			}
			else
			{
				unlockSprite.y += 50 + ((i - (unlockedSongs.length / 2)) * 100);
			}
			unlockSprite.alpha = 0;
			unlockSprites.add(unlockSprite);

			if (unlockSprite.alpha == 0)
			{
				FlxTween.tween(unlockSprite, {alpha: 1}, 0.5);
			}
		}

		if (uniqueUnlockText != null)
		{
			unlockDescription.text = uniqueUnlockText;
		}
		else
		{
			unlockDescription.text = "New song" + (unlockedSongs.length == 1 ? '' : 's') + " unlocked in Freeplay!";
		}
		//unlockDescription.screenCenter(X);

		if (unlockDescription.alpha == 0)
		{
			FlxTween.tween(unlockDescription, {alpha: 1}, 0.5);
		}

		unlockFadeBG.visible = true;
		unlockDescription.visible = true;
		unlockSprites.visible = true;
		unlock_stopspamming = false;		
	}

	function showUnlockedModes() {
		for (i in 0...unlockedModes.length)
		{
			var unlockSprite = new FlxSprite();
			switch(Paths.formatToSongPath(unlockedModes[i]))
			{
				// Modes
				case 'no-fail':
					var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
					unlockSprite.frames = ui_tex;
					unlockSprite.animation.addByPrefix('nofail', 'NO FAIL');
					unlockSprite.animation.play('nofail');
					unlockSprite.offset.x = 25;
				case 'freestyle':
					var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
					unlockSprite = new FlxSprite(0, 0);
					unlockSprite.frames = ui_tex;
					unlockSprite.animation.addByPrefix('freestyle', 'FREESTYLE');
					unlockSprite.animation.play('freestyle');
					unlockSprite.offset.x = 100;
				case 'randomized':
					var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
					unlockSprite = new FlxSprite(0, 0);
					unlockSprite.frames = ui_tex;
					unlockSprite.animation.addByPrefix('randomized', 'RANDOMIZED');
					unlockSprite.animation.play('randomized');
					unlockSprite.offset.x = 125;
				case 'insta-death':
					var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
					unlockSprite = new FlxSprite(0, 0);
					unlockSprite.frames = ui_tex;
					unlockSprite.animation.addByPrefix('insta-death', 'instadeathtext');
					unlockSprite.animation.play('insta-death');
					unlockSprite.offset.x = 125;
			}

			unlockSprite.screenCenter();
			unlockSprite.alpha = 0;
			if (unlockedModes.length % 2 == 1)
			{
				unlockSprite.y += (i - (unlockedModes.length - 1) / 2) * 150;
			}
			else
			{
				unlockSprite.y += 75 + ((i - (unlockedModes.length / 2)) * 150);
			}
			unlockSprites.add(unlockSprite);

			if (unlockSprite.alpha == 0)
			{
				FlxTween.tween(unlockSprite, {alpha: 1}, 0.5);
			}
		}

		unlockDescription.text = "New mode" + (unlockedModes.length == 1 ? '' : 's') + " unlocked!";
		//unlockDescription.screenCenter(X);

		if (unlockDescription.alpha == 0)
		{
			FlxTween.tween(unlockDescription, {alpha: 1}, 0.5);
		}

		unlockFadeBG.visible = true;
		unlockDescription.visible = true;
		unlockSprites.visible = true;
		unlock_stopspamming = false;
	}

	function showUnlockedCharacters() {
		// Also using this for gfs
		for (i in 0...unlockedChars.length)
		{
			var unlockSprite:Character = null;

			var toShow = unlockedChars[i];
			if(Character.doesCharExist("story/" + unlockedChars[i])) {
				toShow = "story/" + unlockedChars[i]; // Optimization
			}

			unlockSprite = new Character(0, 0, toShow, unlockedChars[i].startsWith("bf"));
			//unlockSprite.animation.addByPrefix('idle', 'BF idle dance', 24, true); // Make it looped
			//unlockSprite.animation.play('idle');
			unlockSprite.animOffsets.clear();
			unlockSprite.animScales.clear();
			unlockSprite.shader = null;
			unlockSprite.dance();
			unlockSprite.scale.set(0.5, 0.5);
			unlockSprite.characterScale.set(0.5, 0.5);
			unlockSprite.updateHitbox();
			if(unlockSprite.animation.curAnim != null) {
				unlockSprite.animation.finishCallback = (_) -> {
					unlockSprite.dance();
					unlockSprite.scale.set(0.5, 0.5);
					unlockSprite.updateHitbox();
				}
			}

			/*switch(unlockedChars[i])
			{
				// Characters
				case 'bf-retro':
					unlockSprite = new Character(0, 0, 'bf-retro', true);
					unlockSprite.scale.set(0.5, 0.5);
					var tex = Paths.getSparrowAtlas('characters/RetroBF', 'shared');
					unlockSprite.frames = tex;
					unlockSprite.animation.addByPrefix('idle', 'BF idle dance', 24, true); // Make it looped
					unlockSprite.animation.play('idle');
				case 'bf-ace':
					unlockSprite = new Character(0, 0, 'bf-ace', true);
					var tex = Paths.getSparrowAtlas('characters/AceBF', 'shared');
					unlockSprite.scale.set(0.5, 0.5);
					unlockSprite.frames = tex;
					unlockSprite.animation.addByPrefix('idle', 'BF idle dance', 24, true); // Make it looped
					unlockSprite.animation.play('idle');
				case 'bf-minus':
					unlockSprite = new Character(0, 0, 'bf-minus', true);
					var tex = Paths.getSparrowAtlas('characters/minus/minus_bf', 'shared');
					unlockSprite.scale.set(0.5, 0.5);
					unlockSprite.frames = tex;
					unlockSprite.animation.addByPrefix('idle', 'BF idle dance', 24, true); // Make it looped
					unlockSprite.animation.play('idle');
				case 'bf-saku':
					unlockSprite = new Character(0, 0, 'bf-saku', true);
					var tex = Paths.getSparrowAtlas('characters/SakuBF', 'shared');
					unlockSprite.scale.set(0.5, 0.5);
					unlockSprite.frames = tex;
					unlockSprite.animation.addByPrefix('idle', 'BF idle dance', 24, true); // Make it looped
					unlockSprite.animation.play('idle');
				// Girlfriends
				//case 'gf-minus'|'gf-saku'|'gf-ace'|'gf-zerktro'|'gf-saku-goth': unlockSprite = new HealthIcon(unlockedChars[i]); unlockSprite.scale.set(2, 2);
				
				case 'gf-minus':
					unlockSprite = new Character(0, 0, 'gf-minus');
					var tex = Paths.getSparrowAtlas('characters/minus/minus_gf', 'shared');
					unlockSprite.frames = tex;
					unlockSprite.animation.addByIndices('idle', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, true);
					unlockSprite.animation.play('idle');
					unlockSprite.scale.set(0.5, 0.5);
					unlockSprite.updateHitbox();
				case 'gf-saku':
					unlockSprite = new Character(0, 0, 'gf-saku');
					var tex = Paths.getSparrowAtlas('characters/unshaded_wrath/Saku_GF', 'shared');
					unlockSprite.frames = tex;
					unlockSprite.animation.addByIndices('idle', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, true);
					unlockSprite.animation.play('idle');
					unlockSprite.scale.set(0.5, 0.5);
					unlockSprite.updateHitbox();
				case 'gf-ace':
					unlockSprite = new Character(0, 0, 'gf-ace');
					var tex = Paths.getSparrowAtlas('characters/unshaded_wrath/AceGF', 'shared');
					unlockSprite.frames = tex;
					unlockSprite.animation.addByIndices('idle', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, true);
					unlockSprite.animation.play('idle');
					unlockSprite.scale.set(0.5, 0.5);
					unlockSprite.updateHitbox();
				case 'gf-zerktro':
					unlockSprite = new Character(0, 0, 'gf-zerktro');
					var tex = Paths.getSparrowAtlas('characters/unshaded_wrath/WrathZerktroGF', 'shared');
					unlockSprite.frames = tex;
					unlockSprite.animation.addByIndices('idle', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, true);
					unlockSprite.animation.play('idle');
					unlockSprite.scale.set(0.5, 0.5);
					unlockSprite.updateHitbox();
				case 'gf-saku-goth':
					unlockSprite = new Character(0, 0, 'gf-saku-goth');
					var tex = Paths.getSparrowAtlas('characters/unshaded_wrath/SakuGothGF', 'shared');
					unlockSprite.frames = tex;
					unlockSprite.animation.addByIndices('idle', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, true);
					unlockSprite.animation.play('idle');
					unlockSprite.scale.set(0.5, 0.5);
					unlockSprite.updateHitbox();
			}*/

			if(unlockSprite == null) {
				trace("Character: " + unlockedChars[i] + " failed to load");
				continue;
			}

			unlockSprite.shader = null;
			unlockSprite.screenCenter();
			unlockSprite.alpha = 0;
			if (unlockedChars.length % 2 == 1)
			{
				unlockSprite.x += (i - (unlockedChars.length - 1) / 2) * 350;
			}
			else
			{
				unlockSprite.x += 175 + ((i - (unlockedChars.length / 2)) * 350);
			}
			unlockSprites.add(unlockSprite);

			if (unlockSprite.alpha == 0)
			{
				FlxTween.tween(unlockSprite, {alpha: 1}, 0.5);
			}
		}

		unlockDescription.text = "New character" + (unlockedChars.length == 1 ? '' : 's') + " unlocked!";
		//unlockDescription.screenCenter(X);

		if (unlockDescription.alpha == 0)
		{
			FlxTween.tween(unlockDescription, {alpha: 1}, 0.5);
		}

		unlockFadeBG.visible = true;
		unlockDescription.visible = true;
		unlockSprites.visible = true;
		unlock_stopspamming = false;
	}
}
