package;

class DialogueContext
{
	public var character:String;
	public var gf:String;
	public var foe:String;
	public var song:String;
	public var difficulty:Int;
	public var postSong:Bool = false;

	public function new(character:String, gf:String, foe:String, song:String, difficulty:Int, postSong:Bool)
	{
		this.character = character;
		this.gf = gf;
		this.foe = foe;
		this.song = song;
		this.difficulty = difficulty;
		this.postSong = postSong;
	}
}