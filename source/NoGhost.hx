@:headerCode('
#include "windows.h"
#include "winuser.h"
')
@:unreflective
@:nativeGen
class NoGhost {
	@:functionCode('
	DisableProcessWindowsGhosting();
	')
	public static function disable():Void {}
}