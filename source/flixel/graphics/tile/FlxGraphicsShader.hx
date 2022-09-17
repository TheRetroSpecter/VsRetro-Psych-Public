package flixel.graphics.tile;

#if FLX_DRAW_QUADS
import openfl.display.GraphicsShader;

class FlxGraphicsShader extends GraphicsShader
{
	@:glVertexSource("
#pragma header

attribute float alpha;
attribute vec4 colorMultiplier;
attribute vec4 colorOffset;
uniform bool hasColorTransform;

void main(void){
	#pragma body

openfl_Alphav=openfl_Alpha*alpha;

if(hasColorTransform){
	openfl_ColorOffsetv=colorOffset/255.0;
	openfl_ColorMultiplierv=colorMultiplier;
}
}")
	@:glFragmentHeader("
uniform bool hasTransform;
uniform bool hasColorTransform;

vec4 flixel_texture2D(sampler2D bitmap,vec2 coord){
	vec4 c=texture2D(bitmap,coord);
	if(!hasTransform){return c;}

	if(c.a==0.0){return vec4(0.0,0.0,0.0,0.0);}

	if(!hasColorTransform){return c*openfl_Alphav;}

	c=vec4(c.rgb/c.a,c.a);

	mat4 cm=mat4(0);
	cm[0][0]=openfl_ColorMultiplierv.x;
	cm[1][1]=openfl_ColorMultiplierv.y;
	cm[2][2]=openfl_ColorMultiplierv.z;
	cm[3][3]=openfl_ColorMultiplierv.w;

	c=clamp(openfl_ColorOffsetv+(c*cm),0.0,1.0);

	if(c.a>0.0){
		return vec4(c.rgb*c.a*openfl_Alphav,c.a*openfl_Alphav);
	}
	return vec4(0.0,0.0,0.0,0.0);
}
")
	@:glFragmentSource("
#pragma header

void main(void){
	gl_FragColor=flixel_texture2D(bitmap,openfl_TextureCoordv);
}")
	public function new()
	{
		super();
	}
}
#end
