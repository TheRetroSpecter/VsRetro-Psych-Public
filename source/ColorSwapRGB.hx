package;

import shaders.AmongUsShader;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.system.FlxAssets.FlxShader;

class ColorSwapRGB {
	public var shader(default, null):AmongUsShader = new AmongUsShader();
	public var red(get, set):FlxColor;
	public var green(get, set):FlxColor;
	public var blue(get, set):FlxColor;

	inline function set_red(value:FlxColor) {
		shader.uRed.value = toVec3(value);
		return value;
	}
	inline function get_red() {
		var color = shader.uRed.value;
		return FlxColor.fromRGBFloat(color[0], color[1], color[2]);
	}

	inline function set_green(value:FlxColor) {
		shader.uGreen.value = toVec3(value);
		return value;
	}
	inline function get_green() {
		var color = shader.uGreen.value;
		return FlxColor.fromRGBFloat(color[0], color[1], color[2]);
	}

	inline function set_blue(value:FlxColor) {
		shader.uBlue.value = toVec3(value);
		return value;
	}
	inline function get_blue() {
		var color = shader.uBlue.value;
		return FlxColor.fromRGBFloat(color[0], color[1], color[2]);
	}

	static function toVec3(color:FlxColor) {
		return [
			color.redFloat,
			color.greenFloat,
			color.blueFloat
		];
	}

	public function new()
	{
	}
}