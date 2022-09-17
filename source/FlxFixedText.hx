package;

import flixel.text.FlxText;
import flash.display.BitmapData;
import flixel.FlxG;
import flixel.util.FlxColor;

using flixel.util.FlxStringUtil;
using flixel.util.FlxUnicodeUtil;
using StringTools;

/**
 * Memory Leak fixed by Ne_Eo
 */
class FlxFixedText extends FlxText
{
	//public var init:Bool = true;

	override function regenGraphic():Void
	{
		if (textField == null || !_regen/* || init*/) {
			//init = false;
			return;
		}

		var oldWidth:Int = 0;
		var oldHeight:Int = FlxText.VERTICAL_GUTTER;

		if (graphic != null)
		{
			oldWidth = graphic.width;
			oldHeight = graphic.height;
		}

		var newWidth:Float = textField.width;
		// Account for gutter
		var newHeight:Float = textField.textHeight + FlxText.VERTICAL_GUTTER;

		// prevent text height from shrinking on flash if text == ""
		if (textField.textHeight == 0)
		{
			newHeight = oldHeight;
		}

		if (oldWidth != Std.int(newWidth) || oldHeight != Std.int(newHeight))
		{
			// Need to generate a new buffer to store the text graphic
			height = newHeight;
			var key:String = FlxG.bitmap.getUniqueKey("text");
			makeGraphic(Std.int(newWidth), Std.int(newHeight), FlxColor.TRANSPARENT, false, key);

			if (_hasBorderAlpha)
				_borderPixels = graphic.bitmap.clone();
			frameHeight = Std.int(height);
			textField.height = height * 1.2;
			_flashRect.x = 0;
			_flashRect.y = 0;
			_flashRect.width = newWidth;
			_flashRect.height = newHeight;
		}
		else // Else just clear the old buffer before redrawing the text
		{
			graphic.bitmap.fillRect(_flashRect, FlxColor.TRANSPARENT);
			if (_hasBorderAlpha)
			{
				if (_borderPixels == null)
					_borderPixels = new BitmapData(frameWidth, frameHeight, true);
				else
					_borderPixels.fillRect(_flashRect, FlxColor.TRANSPARENT);
			}
		}

		if (textField != null && textField.text != null && textField.text.length > 0)
		{
			// Now that we've cleared a buffer, we need to actually render the text to it
			copyTextFormat(_defaultFormat, _formatAdjusted);

			_matrix.identity();

			applyBorderStyle();
			applyBorderTransparency();
			applyFormats(_formatAdjusted, false);

			drawTextFieldTo(graphic.bitmap);
		}

		_regen = false;
		resetFrame();
	}
}
