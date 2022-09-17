package;

import flixel.FlxSprite;
import flixel.util.typeLimit.OneOfFour;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;

typedef GraphicAsset = OneOfFour<FlxSprite, FlxGraphic, BitmapData, String>;

// By Ne_Eo
class GPUTools {
	private static var _bitmap:BitmapData = new BitmapData(1, 1, true, 0);

	/**
	 * Uploads a graphic to the gpu to prevent lag when it loads in
	 * @param	Graphic	The graphic to be uploaded
	 * @param	Unique	If the cache should be used
	 * @param	Key		The cache key
	 */
	public static function uploadToGpu(Graphic:GraphicAsset, Unique:Bool = false, ?Key:String) {
		var graphic:FlxGraphic;
		if ((Graphic is FlxSprite))
		{
			var sprite:FlxSprite = cast Graphic;
			graphic = FlxGraphic.fromGraphic(sprite.graphic, Unique, Key);
		}
		else if ((Graphic is FlxGraphic))
		{
			graphic = FlxGraphic.fromGraphic(cast Graphic, Unique, Key);
		}
		else if ((Graphic is BitmapData))
		{
			graphic = FlxGraphic.fromBitmapData(cast Graphic, Unique, Key);
		}
		else
		{
			// String case
			graphic = FlxGraphic.fromAssetKey(Std.string(Graphic), Unique, Key);
		}

		if(graphic.bitmap == null) return;

		_bitmap.draw(graphic.bitmap, null, null, null, null, true);
	}
}