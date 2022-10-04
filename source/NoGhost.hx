#if windows
@:headerCode('
#include "windows.h"
#include "winuser.h"
') 
#end 
@:unreflective
@:nativeGen
class NoGhost {
	@:functionCode('
	DisableProcessWindowsGhosting();
	')
	public static function disable():Void {}
}
