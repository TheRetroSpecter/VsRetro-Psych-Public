package shaders;

import flixel.system.FlxAssets.FlxShader;

class ChromaticAberrationShader extends FlxShader
{
	@:glFragmentSource('
#pragma header

uniform vec2 rOffset;
uniform vec2 gOffset;
uniform vec2 bOffset;

vec4 offsetColor(vec2 offset)
{
	return texture2D(bitmap, openfl_TextureCoordv.st - offset);
}

void main()
{
	vec4 base = texture2D(bitmap, openfl_TextureCoordv);
	base.r = offsetColor(rOffset).r;
	base.g = offsetColor(gOffset).g;
	base.b = offsetColor(bOffset).b;

	gl_FragColor = base * openfl_Alphav;
}')
	public function new()
	{
		super();

		this.rOffset.value = [0, 0];
		this.gOffset.value = [0, 0];
		this.bOffset.value = [0, 0];
	}
}
