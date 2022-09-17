package;

import flixel.graphics.FlxGraphic;
import flixel.util.FlxDestroyUtil;
import haxe.Timer;
import flixel.FlxState;
import lime.utils.AssetLibrary;
import lime.utils.Assets as LimeAssets;
import openfl.utils.Assets as OpenFlAssets;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class ClearCacheState extends MusicBeatState
{
	var txt:FlxFixedText;

	var changes:Array<String> = [];
	var toAdd:Array<Array<Dynamic>> = [];

	static inline final SOUND = 0;
	static inline final FONT = 1;
	static inline final BMP = 2;
	static inline final OTHER = 3;

	static inline final OPENFL = 0;
	static inline final LIME = 1;
	static inline final FLIXEL = 2;
	static inline final ASSETLIBRARY = 3;

	static inline final FINISHED = -1;
	static inline final CLEAR_CACHE = 0;
	static inline final HAS_FINISHED = 1;

	var colorMarkers:Array<FlxTextFormatMarkerPair> = [];

	var finishState:Class<FlxState>;
	var stateArgs:Array<Dynamic> = [];

	public function new(?finishState:Class<FlxState>, ?arguments:Array<Dynamic>) {
		super();
		if(finishState == null)
			finishState = MainMenuState;
		this.finishState = finishState;

		if(arguments != null)
			this.stateArgs = arguments;
	}

	var oldPersist:Bool = false;

	override function create()
	{
		super.create();
		if(FlxG.sound.music != null) {
			FlxG.sound.music.stop();
			FlxG.sound.music.persist = false;
		}

		//Paths.clearStoredMemory();
		Paths.currentTrackedSounds = [];
		Paths.currentTrackedAssets = [];
		Paths.localTrackedAssets = [];
		//Paths.removeUnusedGraphics(true);
		oldPersist = FlxGraphic.defaultPersist;
		FlxGraphic.defaultPersist = false;

		// Do it here so it doesnt clean the text it made afterwards
		@:privateAccess {
			for (key in FlxG.bitmap._cache.keys())
			{
				toAdd.push([false, FLIXEL, BMP, key]);
			}
		}

		#if FLX_SOUND_SYSTEM
		FlxG.sound.destroy(true);
		#end

		var title = new FlxFixedText(0, 10, Std.int(FlxG.width/3), "Clearing Cache", 48);
		title.setFormat("VCR OSD Mono", 48, FlxColor.fromRGB(255, 255, 255), CENTER);
		title.borderColor = FlxColor.BLACK;
		title.borderSize = 3;
		title.borderStyle = FlxTextBorderStyle.OUTLINE;
		title.screenCenter(X);
		add(title);

		while(!(changes.length > 50)) changes.push("");

		txt = new FlxFixedText(0, title.y + title.height + 40, FlxG.width, "", 16);
		txt.setFormat("VCR OSD Mono", 16, FlxColor.fromRGB(200, 200, 200), CENTER);
		txt.borderColor = FlxColor.BLACK;
		txt.borderSize = 3;
		txt.borderStyle = FlxTextBorderStyle.OUTLINE;
		updateText();
		txt.screenCenter(X);
		add(txt);

		@:privateAccess {
			var greenFormat = new FlxTextFormat();
			greenFormat.format.color = FlxColor.LIME;
			var greenMarker = new FlxTextFormatMarkerPair(greenFormat, "<G>");

			var redFormat = new FlxTextFormat();
			redFormat.format.color = FlxColor.RED;
			var redMarker = new FlxTextFormatMarkerPair(redFormat, "<R>");

			colorMarkers.push(greenMarker);
			colorMarkers.push(redMarker);
		}

		{
			var soundCache = OpenFlAssets.cache.getSoundCache();
			var fontCache = OpenFlAssets.cache.getFontCache();
			var bmpCache = OpenFlAssets.cache.getBitmapDataCache();
			for(file in soundCache.keys()) {
				toAdd.push([false, OPENFL, SOUND, file]);
			}
			for(file in fontCache.keys()) {
				toAdd.push([false, OPENFL, FONT, file]);
			}
			for(file in bmpCache.keys()) {
				toAdd.push([false, OPENFL, BMP, file]);
			}
		}
		{
			var soundCache = LimeAssets.cache.audio;
			var fontCache = LimeAssets.cache.font;
			var bmpCache = LimeAssets.cache.image;
			for(file in soundCache.keys()) {
				toAdd.push([false, LIME, SOUND, file]);
			}
			for(file in fontCache.keys()) {
				toAdd.push([false, LIME, FONT, file]);
			}
			for(file in bmpCache.keys()) {
				toAdd.push([false, LIME, BMP, file]);
			}
		}

		if(toAdd.length > 0) {
			toAdd.reverse();
			state = CLEAR_CACHE;
		} else {
			state = HAS_FINISHED;
		}
	}

	override function destroy() {
		super.destroy();

		colorMarkers = null;
		toAdd = null;
		changes = null;
	}

	function fromLibrary(library:AssetLibrary, canHide:Bool = false) {
		@:privateAccess {
			fromMap(cast library.cachedText, ASSETLIBRARY, OTHER, canHide);
			fromMap(cast library.cachedBytes, ASSETLIBRARY, OTHER, canHide);
			fromMap(cast library.cachedFonts, ASSETLIBRARY, OTHER, canHide);
			fromMap(cast library.cachedImages, ASSETLIBRARY, OTHER, canHide);
			fromMap(cast library.cachedAudioBuffers, ASSETLIBRARY, OTHER, canHide);
		}
	}

	function fromMap(map:haxe.DynamicAccess<Dynamic>, cacheType:Int, dataType:Int, canHide:Bool = false) {
		for(key in map.keys())
			toAdd.push([canHide, cacheType, dataType, key, map]);
	}

	function removeKey(map:haxe.DynamicAccess<Dynamic>, key:Dynamic) {
		if(map.exists(key)) {
			map.remove(key);
			return true;
		}
		return false;
	}

	var state = CLEAR_CACHE;

	function switchBack() {
		MemoryUtils.clearMajor();
		FlxGraphic.defaultPersist = oldPersist;
		if (MainMenuState.songName.startsWith('Intro')) MainMenuState.songName = MainMenuState.songName.replace('Intro', 'Menu');
			FlxG.sound.playMusic(Paths.music(MainMenuState.songName));
			FlxG.sound.music.persist = true;
		FlxG.switchState(Type.createInstance(this.finishState, this.stateArgs));
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(state == CLEAR_CACHE) {
			var toRemove = toAdd.pop(); trace(toRemove);
			var canHide:Bool = toRemove[0];
			var cacheType:Int = toRemove[1];
			var dataType:Int = toRemove[2];
			var key = toRemove[3];

			if(toAdd.length == 0) {
				state = HAS_FINISHED;
			}

			var success = false;

			if(cacheType == OPENFL) {
				switch(dataType) {
					case SOUND:
						success = OpenFlAssets.cache.removeSound(key);
					case FONT:
						success = OpenFlAssets.cache.removeFont(key);
					case BMP:
						FlxDestroyUtil.dispose(OpenFlAssets.cache.getBitmapData(key));
						success = OpenFlAssets.cache.removeBitmapData(key);
				}
			} else if(cacheType == LIME) {
				switch(dataType) {
					case SOUND:
						success = removeKey(cast LimeAssets.cache.audio, key);
					case FONT:
						success = removeKey(cast LimeAssets.cache.font, key);
					case BMP:
						success = removeKey(cast LimeAssets.cache.image, key);
				}
			} else if(cacheType == FLIXEL) {
				@:privateAccess if(dataType == BMP) {
					var obj = FlxG.bitmap.get(key);
					FlxG.bitmap.removeKey(key);

					if (obj != null) {
						obj.destroy();
						success = true;
					}
				}
			} else if(cacheType == ASSETLIBRARY) {
				if(dataType == OTHER) {
					success = removeKey(cast toRemove[4], key);
				}
			}

			if(!(canHide && !success)) {
				var marker = success ? "<G>" : "<R>";

				changes.unshift(marker + key + marker);
				updateText();
			}
		} else if(state == HAS_FINISHED) {
			changes.unshift("");
			changes.unshift("");
			changes.unshift("<G>Cleared Cache<G>");
			state = FINISHED;
			MemoryUtils.clearMajor();
			Timer.delay(switchBack, 500);
			updateText();
		}
	}

	function updateText() {
		while(changes.length > 50) changes.pop();

		var text = changes.join("\n") + "\n";
		txt.applyMarkup(text, colorMarkers);
	}
}