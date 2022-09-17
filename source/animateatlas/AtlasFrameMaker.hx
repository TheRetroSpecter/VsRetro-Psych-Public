package animateatlas;
import openfl.geom.Matrix;
import flixel.util.FlxDestroyUtil;
import openfl.geom.Rectangle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.Assets;
import haxe.Json;
import openfl.display.BitmapData;
import animateatlas.JSONData.AtlasData;
import animateatlas.JSONData.AnimationData;
import animateatlas.displayobject.SpriteAnimationLibrary;
import animateatlas.displayobject.SpriteMovieClip;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxFrame;
#if desktop
import sys.FileSystem;
import sys.io.File;
#else
import js.html.FileSystem;
import js.html.File;
#end

using StringTools;

@:access(openfl.geom.Matrix)
class AtlasFrameMaker extends FlxFramesCollection
{
	static inline final PADDING:Int = 1;

	/**
	
	* Creates Frames from TextureAtlas(very early and broken ok) Originally made for FNF HD by Smokey and Rozebud
	*
	* @param   key                 The file path.
	* @param   _excludeArray       Use this to only create selected animations. Keep null to create all of them.
	*
	*/
	public static function construct(key:String, ?_excludeArray:Array<String> = null, ?noAntialiasing:Bool = false):FlxFramesCollection
	{
		if (Paths.fileExists('images/$key/spritemap1.json', TEXT))
		{
			PlayState.instance.addTextToDebug("Only Spritemaps made with Adobe Animate 2018 are supported");
			trace("Only Spritemaps made with Adobe Animate 2018 are supported");
			return null;
		}

		var graphic:FlxGraphic = Paths.image('$key/spritemap');

		if(_excludeArray == null) {
			var frames:FlxFramesCollection = AtlasFrameMaker.findFrame(graphic);
			if (frames != null) {
				insertIntoPsychCache(frames);
				return frames;
			}
		}

		var animationData:AnimationData = Json.parse(Paths.getTextFromFile('images/$key/Animation.json'));
		var atlasData:AtlasData = Json.parse(Paths.getTextFromFile('images/$key/spritemap.json').replace("\uFEFF", ""));

		var ss:SpriteAnimationLibrary = new SpriteAnimationLibrary(animationData, atlasData, graphic.bitmap);
		var t:SpriteMovieClip = ss.createAnimation(noAntialiasing);
		if(_excludeArray == null)
		{
			_excludeArray = t.getFrameLabels();
			//trace('creating all anims');
		}
		trace('Creating: ' + _excludeArray);

		var frameCollection:FlxFramesCollection = new FlxFramesCollection(graphic, FlxFrameCollectionType.USER("ANIMATE"));//.IMAGE);

		for(x in _excludeArray) {
			var frames = getFramesArray(t, x, graphic);
			for(frame in frames) {
				frameCollection.pushFrame(frame);
			}
		}
		insertIntoPsychCache(frameCollection);
		return frameCollection;
	}

	static function insertIntoPsychCache(framesCollection:FlxFramesCollection) {
		for(frame in framesCollection.frames) {
			var graphic = frame.parent;
			var key = graphic.key;

			Paths.localTrackedAssets.push(key);
			if(!Paths.currentTrackedAssets.exists(key)) {
				Paths.currentTrackedAssets.set(key, graphic);
			}
		}
	}

	/**
	 * Returns the `FlxFramesCollection` of the specified `FlxGraphic` object.
	 *
	 * @param   graphic   `FlxGraphic` object to find the `FlxFramesCollection` collection for.
	 * @return  `FlxFramesCollection` collection for the specified `FlxGraphic` object
	 *          Could be `null` if `FlxGraphic` doesn't have it yet.
	 */
	public static function findFrame(graphic:FlxGraphic):FlxFramesCollection
	{
		var border = FlxPoint.get();

		var atlasFrames:Array<FlxFramesCollection> = cast graphic.getFramesCollections(FlxFrameCollectionType.USER("ANIMATE"));

		for (atlas in atlasFrames)
			if (atlas.border.equals(border)) {
				border.put();
				return atlas;
			}

		border.put();
		return null;
	}

	@:noCompletion static function getFramesArray(t:SpriteMovieClip, animation:String, parent:FlxGraphic):Array<FlxFrame>
	{
		var sizeInfo:Rectangle = new Rectangle(0, 0);
		t.currentLabel = animation;
		var frameArray:Array<Frame> = [];
		var firstPass = true;
		var frameSize:FlxPoint = FlxPoint.get(0, 0);
		var translate = Matrix.__pool.get();

		for (i in t.getFrame(animation)...t.numFrames)
		{
			t.currentFrame = i;
			if (t.currentLabel == animation)
			{
				sizeInfo = t.getBounds(t);

				var bitmapShit:BitmapData = new BitmapData(
					Std.int(sizeInfo.width) + PADDING*2,
					Std.int(sizeInfo.height) + PADDING*2,
					true, 0
				);

				// Translates by the padding.
				translate.tx = PADDING;
				translate.ty = PADDING;

				translate.translate(-sizeInfo.x, -sizeInfo.y);

				bitmapShit.draw(t, translate, null, null, null, true);
				frameArray.push(new Frame(bitmapShit, FlxPoint.weak(sizeInfo.x, sizeInfo.y)));

				if (firstPass) {
					frameSize.set(bitmapShit.width, bitmapShit.height);
					firstPass = false;
				}
			}
			else break;
		}

		Matrix.__pool.release(translate);

		var daFramez:Array<FlxFrame> = [];

		var parentName = parent.key;

		for (i in 0...frameArray.length) {
			var frame = frameArray[i];
			var bitmap = frame.bitmap;
			var b = FlxGraphic.fromBitmapData(bitmap, false, '${parentName}_${animation}_${i}');
			b.persist = true;
			var theFrame = new FlxFrame(b);
			theFrame.name = animation + i;
			theFrame.sourceSize.set(frameSize.x, frameSize.y);
			theFrame.offset.copyFrom(frame.offset);
			theFrame.frame = new FlxRect(PADDING, PADDING, bitmap.width, bitmap.height);
			daFramez.push(theFrame);
		}
		frameArray = null;
		frameSize = FlxDestroyUtil.put(frameSize);

		return daFramez;
	}
}

class Frame {
	public var bitmap:BitmapData;
	public var offset:FlxPoint;

	public function new(_bitmap:BitmapData, _offset:FlxPoint) {
		bitmap = _bitmap;
		offset = _offset;
	}
}