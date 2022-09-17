package;

import openfl.Lib;

class WindowTitle {
	public static var DEFAULT(get, null):String = "";

	public static function changeTitle(text:String) {
		Lib.application.window.title = text;
	}

	public static function progress(_progress:Int) {
		var progress:Float = _progress / 100;
		var length = 10;
		var act = "#";
		var unt = "_";

		var str = "[";

		var filled = Math.floor(length * progress);

		for(i in 0...filled) {
			str += act;
		}
		for(i in 0...length-filled) {
			str += unt;
		}
		str += "]";

		Lib.application.window.title = DEFAULT + " - " + str;
	}
	public static inline function defaultTitle() {
		changeTitle(DEFAULT);
	}

	static function get_DEFAULT() {
		if(DEFAULT == "") {
			DEFAULT = Lib.application.meta["name"];
		}
		return DEFAULT;
	}
}