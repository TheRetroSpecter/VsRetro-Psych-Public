package;

import options.QuickSettingsSubState;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxBasic;
import flixel.FlxSprite;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public var canQuickSettings:Bool = false;
	public var inQuickSettings:Bool = false;

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		curBeat = Math.floor(curStep / 4);

		if (oldStep != curStep && curStep > 0)
			stepHit();

		if(canQuickSettings) {
			if(FlxG.keys.pressed.ALT && FlxG.keys.justPressed.O) {
				if(subState == null) { // Prevent Broken Stuff
					openSubState(new QuickSettingsSubState());
				}
			}
			#if debug
			if(FlxG.keys.pressed.ALT && FlxG.keys.justPressed.U) {
				if(subState == null) { // Prevent Broken Stuff
					openSubState(new UnlocksDebug());
				}
			}
			#end
		}

		super.update(elapsed);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}


	override function openSubState(SubState:FlxSubState) {
		if((SubState is QuickSettingsSubState) #if debug || (SubState is UnlocksDebug) #end) {
			inQuickSettings = true;
		}
		super.openSubState(SubState);
	}

	override function closeSubState() {
		if((subState is QuickSettingsSubState) #if debug || (subState is UnlocksDebug) #end) {
			inQuickSettings = false;
		}
		super.closeSubState();
	}

	@:allow(flixel.FlxGame)
	override function tryUpdate(elapsed:Float):Void
	{
		if (!inQuickSettings && (persistentUpdate || subState == null))
			update(elapsed);

		if (_requestSubStateReset)
		{
			_requestSubStateReset = false;
			resetSubState();
		}
		if (subState != null)
		{
			subState.tryUpdate(elapsed);
		}
	}
}
