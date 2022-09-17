package shaders;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxShader;

#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

using StringTools;

/**
 * Made by Ne_Eo for Retro
 */

class WrathShader extends FlxShader {
	@:glFragmentSource('
#pragma header

#define ANGLE ANGLE_OPT.0
WRATH_EXPERIMENTAL_DEFINE

uniform vec3 uShadeColor;
uniform vec3 uOverlayColor;
uniform float uDistance;
uniform float uChoke;
uniform float uPower;

uniform float uDirection;
uniform float uOverlayOpacity;

uniform vec3 uScreenColor;
uniform float uScreenOpacity;

uniform vec4 applyRect;

float blendLinearBurn(float base, float blend) {
	return max(base+blend-1.0,0.0);
}

vec3 blendLinearBurn(vec3 base, vec3 blend) {
	return max(base+blend-vec3(1.0),vec3(0.0));
}

vec3 blendLinearBurn(vec3 base, vec3 blend, float opacity) {
	return (blendLinearBurn(base, blend) * opacity + base * (1.0 - opacity));
}

float blendLinearDodge(float base, float blend) {
	return min(base+blend,1.0);
}

vec3 blendLinearDodge(vec3 base, vec3 blend) {
	return min(base+blend,vec3(1.0));
}

vec3 blendLinearDodge(vec3 base, vec3 blend, float opacity) {
	return (blendLinearDodge(base, blend) * opacity + base * (1.0 - opacity));
}

float blendLinearLight(float base, float blend) {
	return blend<0.5?blendLinearBurn(base,(2.0*blend)):blendLinearDodge(base,(2.0*(blend-0.5)));
}

vec3 blendLinearLight(vec3 base, vec3 blend) {
	return vec3(blendLinearLight(base.r,blend.r),blendLinearLight(base.g,blend.g),blendLinearLight(base.b,blend.b));
}

vec3 blendLinearLight(vec3 base, vec3 blend, float opacity) {
	return (blendLinearLight(base, blend) * opacity + base * (1.0 - opacity));
}

vec3 blendMultiply(vec3 base, vec3 blend) {
	return base*blend;
}

vec3 blendMultiply(vec3 base, vec3 blend, float opacity) {
	return blendMultiply(base.rgb, blend.rgb) * opacity + base.rgb * (1.0 - opacity);
}

float blendScreen(float base, float blend) {
	return 1.0-((1.0-base)*(1.0-blend));
}

vec3 blendScreen(vec3 base, vec3 blend) {
	return vec3(blendScreen(base.r,blend.r),blendScreen(base.g,blend.g),blendScreen(base.b,blend.b));
}

vec3 blendScreen(vec3 base, vec3 blend, float opacity) {
	return (blendScreen(base, blend) * opacity + base * (1.0 - opacity));
}

float texture2DAlphaCheck(vec2 uv) {
	#ifdef EXPERIMENTAL
	if(uv.x >= applyRect.x && uv.y >= applyRect.y && uv.x <= applyRect.z && uv.y <= applyRect.w) {
		return texture2D(bitmap, uv).a;
	} else {
		return 0.0;
	}
	#else
	return texture2D(bitmap, uv).a;
	#endif
}

vec4 flixel_texture2DShaded(sampler2D bitmap, vec2 uv) {
	vec4 color = texture2D(bitmap, uv);

	if(color.a == 0.0){return vec4(0.0, 0.0, 0.0, 0.0);}

	#ifdef EXPERIMENTAL
	if(uv.x >= applyRect.x && uv.y >= applyRect.y && uv.x <= applyRect.z && uv.y <= applyRect.w) {
	#endif
		float fshading = 0.0;
		float acu = 0.0;

		float direction = radians(mod(uDirection + 90.0, 360.0));
		vec2 diro = uChoke * vec2(cos(direction), sin(direction));

		for(float i = 0.0; i <= 360.0; i += ANGLE) {
			vec2 offo = uDistance * vec2(cos(radians(i)), sin(radians(i)));

			for(float power = 0.15; power <= 1.0; power += 0.15) {
				vec2 off = power * offo + diro;

				float alpha = texture2DAlphaCheck(uv - off/openfl_TextureSize.xy);
				fshading += power * (1.0 - alpha);
				acu += power;
			}
		}

		fshading /= acu;

		//fshading *= color.a; // Fix the overly green on transparent // BUG: Broken edges

		vec3 shading = (fshading) * uShadeColor;

		vec3 finalColor = blendMultiply(
			color.rgb +
				uPower * blendLinearLight(shading.rgb, color.rgb, (1.0 - color.a)),
			uOverlayColor, uOverlayOpacity
		);

		finalColor = blendScreen(finalColor, finalColor * uScreenColor, uScreenOpacity);//color.a);

		color = vec4(finalColor, color.a);
	#ifdef EXPERIMENTAL
	} else {
		color = color;
	}
	#endif

	if(!hasTransform){return color;}

	if(color.a == 0.0){return vec4(0.0, 0.0, 0.0, 0.0);}

	if(!hasColorTransform){return color * openfl_Alphav;}

	color = vec4(color.rgb / color.a, color.a);

	mat4 colorMultiplier = mat4(0);
	colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
	colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
	colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
	colorMultiplier[3][3] = openfl_ColorMultiplierv.w;

	color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);

	if(color.a > 0.0){
		return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}

void main() {
	vec2 uv = openfl_TextureCoordv.xy;
	vec2 fragCoord = uv * openfl_TextureSize.xy;

	vec4 color = flixel_texture2DShaded(bitmap, uv);

	gl_FragColor = color;
}')

	public function new(preset:WrathPreset = WRATH, angleOpt:Int = 17)
	{
		var aOpt = angleOpt;
		if(ClientPrefs.wrathAngleOpt > aOpt) aOpt = ClientPrefs.wrathAngleOpt;

		/*var src = #if sys
		File.getContent(Paths.txt("wrath"));
		#else
		Assets.getText(Paths.txt("wrath"));
		#end

		glFragmentSource = glFragmentSource.replace("AAAAAAA", src);*/
		glFragmentSource = glFragmentSource.replace("ANGLE_OPT", Std.string(aOpt));
		glFragmentSource = glFragmentSource.replace("WRATH_EXPERIMENTAL_DEFINE", ClientPrefs.wrathExperimental ? "#define EXPERIMENTAL" : "");
		//trace(glFragmentSource);
		super();

		this.preset = preset;
		this.applyRect.value = [0,0,1,1];

		//resetParams();
	}

	public var trackedSprite:FlxSprite;

	public function update():Void
	{
		if(trackedSprite != null && trackedSprite.frame != null) {
			var uv = trackedSprite.frame.uv;
			this.applyRect.value = [uv.x, uv.y, uv.width, uv.height];
		} else {
			this.applyRect.value = [0,0,1,1];
		}
	}

	public function resetParams() {
		this.preset = this.preset;
	}

	function set_preset(value:WrathPreset) {
		switch(value) {
			case WRATH:
				this.uDirection.value = [0.0];
				this.uOverlayOpacity.value = [0.35];
				this.uDistance.value = [21.];
				this.uChoke.value = [10.];
				this.uPower.value = [1.5];

				this.uScreenOpacity.value = [0.0];

				this.shadeColor = FlxColor.fromRGB(0, 196, 108);
				this.overlayColor = FlxColor.fromRGB(27, 104, 83);
			case CORRUPTRO:
				this.uDirection.value = [0.0];
				this.uOverlayOpacity.value = [0.35];
				this.uDistance.value = [21.];
				this.uChoke.value = [10.];
				this.uPower.value = [1.5];

				this.uScreenOpacity.value = [0.0];

				this.shadeColor = 0xC40058;
				this.overlayColor = FlxColor.fromRGB(27, 104, 83);
			case SUNSET:
				this.uDirection.value = [295.];
				this.uOverlayOpacity.value = [0.0];
				this.uDistance.value = [31.];
				this.uChoke.value = [26.];
				this.uPower.value = [0.3];
				this.uScreenOpacity.value = [1.0];

				this.shadeColor = FlxColor.fromRGB(242, 161, 199);
				this.overlayColor = FlxColor.fromRGB(27, 104, 83);
				this.screenColor = 0xF02000;
			case NIGHT:
				this.uDirection.value = [0.];
				this.uOverlayOpacity.value = [0.0];
				this.uDistance.value = [22.];
				this.uChoke.value = [31.];
				this.uPower.value = [0.3];
				this.uScreenOpacity.value = [0.0];

				this.shadeColor = FlxColor.fromRGB(242, 242, 242);
				this.overlayColor = FlxColor.fromRGB(27, 104, 83);
				this.screenColor = 0xF02000;
		}
		return preset = value;
	}

	/**
	 * The Overlay color
	 */
	public var preset(default, set):WrathPreset;

	/**
	 * The direction the glow is the most
	 */
	public var direction(get, set):Float;
	/**
	 * How soft it is
	 */
	public var distance(get, set):Float;
	/**
	 * How far in the shade goes
	 */
	public var choke(get, set):Float;
	/**
	 * The strength of the glow
	 */
	public var power(get, set):Float;
	/**
	 * The Shading color
	 */
	public var shadeColor(get, set):FlxColor;

	/**
	 * The opacity of the multiply color
	 */
	public var overlay(get, set):Float;
	/**
	 * The Overlay color
	 */
	public var overlayColor(get, set):FlxColor;

	/**
	 * The Screen Opacity
	 */
	public var screenOpacity(get, set):Float;
	/**
	 * The Screen color
	 */
	public var screenColor(get, set):FlxColor;

	inline function set_direction(value:Float) {
		return this.uDirection.value[0] = value;
	}
	inline function get_direction() {
		return this.uDirection.value[0];
	}

	inline function set_overlay(value:Float) {
		return this.uOverlayOpacity.value[0] = value;
	}
	inline function get_overlay() {
		return this.uOverlayOpacity.value[0];
	}

	inline function set_distance(value:Float) {
		return this.uDistance.value[0] = value;
	}
	inline function get_distance() {
		return this.uDistance.value[0];
	}

	inline function set_choke(value:Float) {
		return this.uChoke.value[0] = value;
	}
	inline function get_choke() {
		return this.uChoke.value[0];
	}

	inline function set_power(value:Float) {
		return this.uPower.value[0] = value;
	}
	inline function get_power() {
		return this.uPower.value[0];
	}

	inline function set_shadeColor(value:FlxColor) {
		this.uShadeColor.value = toVec3(value);
		return value;
	}
	inline function get_shadeColor() {
		var color = this.uShadeColor.value;
		return FlxColor.fromRGBFloat(color[0], color[1], color[2]);
	}

	inline function set_overlayColor(value:FlxColor) {
		this.uOverlayColor.value = toVec3(value);
		return value;
	}
	inline function get_overlayColor() {
		var color = this.uOverlayColor.value;
		return FlxColor.fromRGBFloat(color[0], color[1], color[2]);
	}

	inline function set_screenOpacity(value:Float) {
		return this.uScreenOpacity.value[0] = value;
	}
	inline function get_screenOpacity() {
		return this.uScreenOpacity.value[0];
	}

	inline function set_screenColor(value:FlxColor) {
		this.uScreenColor.value = toVec3(value);
		return value;
	}
	inline function get_screenColor() {
		var color = this.uScreenColor.value;
		return FlxColor.fromRGBFloat(color[0], color[1], color[2]);
	}

	static function toVec3(color:FlxColor) {
		return [
			color.redFloat,
			color.greenFloat,
			color.blueFloat
		];
	}

	public static function fromTimeOfDay(timeOfDay:String) {
		return switch (timeOfDay)
		{
			case 'Evening': SUNSET;
			//case 'Night': NIGHT;
			default: null;
		}
	}

	public static function fromString(preset:String) {
		return switch (preset.toLowerCase())
		{
			case 'evening' | 'sunset': SUNSET;
			case 'night': NIGHT;
			case 'wrath': WRATH;
			case 'corruptro': CORRUPTRO;
			default: WRATH;
		}
	}
}

enum WrathPreset {
	WRATH;
	SUNSET;
	NIGHT;
	CORRUPTRO;
}