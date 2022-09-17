package shaders;

import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxShader;

using StringTools;

class WrathShaderChromatic extends FlxShader {
	@:glFragmentSource('
#pragma header

#define ANGLE ANGLE_OPT.0
WRATH_EXPERIMENTAL_DEFINE

uniform vec2 rOffset;
uniform vec2 gOffset;
uniform vec2 bOffset;

const vec3 shadeColor = vec3(0, 196, 108)/255.0;
const vec3 overlay = vec3(0.106,0.408,0.325);
const float distance = 21.0;

uniform float uDirection;
uniform float uOverlayOpacity;

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

vec3 offsetColor(vec2 offset) {
	vec2 uv = openfl_TextureCoordv.xy - offset;
	vec2 fragCoord = uv * openfl_TextureSize.xy;

	#ifdef EXPERIMENTAL
	if(uv.x >= applyRect.x && uv.y >= applyRect.y && uv.x <= applyRect.z && uv.y <= applyRect.w) {
	#endif
		vec4 color = texture2D(bitmap, uv);
		float fshading = 0.0;
		float acu = 0.0;

		float direction = radians(mod(uDirection + 90.0, 360.0));
		vec2 diro = 10.0 * vec2(cos(direction), sin(direction));

		for(float i = 0.0; i <= 360.0; i += ANGLE) {
			vec2 offo = distance * vec2(cos(radians(i)), sin(radians(i)));

			for(float power = 0.15; power <= 1.0; power += 0.15) {
				vec2 off = power * offo + diro;

				float alpha = texture2DAlphaCheck(uv - off/openfl_TextureSize.xy);
				fshading += power * (1.0 - alpha);
				acu += power;
			}
		}

		fshading /= acu;

		vec3 shading = fshading * shadeColor;

		vec3 finalColor = blendMultiply(
			color.rgb +
				1.5 * blendLinearLight(shading.rgb, color.rgb, (1.0 - color.a)),
			overlay, uOverlayOpacity
		);

		return finalColor;
	#ifdef EXPERIMENTAL
	} else {
		return vec3(0.0);
	}
	#endif
}

void main() {
	vec4 base = texture2D(bitmap, openfl_TextureCoordv);
	base.r = offsetColor(rOffset).r;
	base.g = offsetColor(gOffset).g;
	base.b = offsetColor(bOffset).b;

	gl_FragColor = base * openfl_Alphav;
}')

	public function new(angleOpt:Int = 17)
	{
		var aOpt = angleOpt;
		if(ClientPrefs.wrathAngleOpt > aOpt) aOpt = ClientPrefs.wrathAngleOpt;
		glFragmentSource = glFragmentSource.replace("ANGLE_OPT", Std.string(aOpt));
		glFragmentSource = glFragmentSource.replace("WRATH_EXPERIMENTAL_DEFINE", ClientPrefs.wrathExperimental ? "#define EXPERIMENTAL" : "");
		super();

		this.rOffset.value = [0, 0];
		this.gOffset.value = [0, 0];
		this.bOffset.value = [0, 0];
		this.applyRect.value = [0,0,1,1];

		resetParams();
	}

	public var trackedSprite:FlxSprite;

	public function update():Void
	{
		if(trackedSprite != null) {
			var uv = trackedSprite.frame.uv;
			this.applyRect.value = [uv.x, uv.y, uv.width, uv.height];
		} else {
			this.applyRect.value = [0,0,1,1];
		}
	}

	public function resetParams() {
		this.uDirection.value = [0.0];
		this.uOverlayOpacity.value = [0.35];
	}

	/**
	 * The direction the glow is the most
	 */
	public var direction(get, set):Float;
	/**
	 * The opacity of the multiply color
	 */
	public var overlay(get, set):Float;

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
}