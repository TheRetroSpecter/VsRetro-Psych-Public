package;

import flixel.FlxCamera;
import flixel.FlxSubState;
import options.QuickSettingsSubState;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.text.FlxText;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxBasic;
#if android
import android.AndroidControls;
import android.flixel.FlxVirtualPad;
import flixel.input.actions.FlxActionInput;
import flixel.util.FlxDestroyUtil;
#end
class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	#if android
	var virtualPad:FlxVirtualPad;
	var androidControls:AndroidControls;
	var trackedinputsUI:Array<FlxActionInput> = [];
	var trackedinputsNOTES:Array<FlxActionInput> = [];

	public function addVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode)
	{
		virtualPad = new FlxVirtualPad(DPad, Action);
		add(virtualPad);

		controls.setVirtualPadUI(virtualPad, DPad, Action);
		trackedinputsUI = controls.trackedinputsUI;
		controls.trackedinputsUI = [];
	}

	public function removeVirtualPad()
	{
		if (trackedinputsUI != [])
			controls.removeFlxInput(trackedinputsUI);

		if (virtualPad != null)
			remove(virtualPad);
	}

	public function addAndroidControls()
	{
		androidControls = new AndroidControls();

		switch (AndroidControls.getMode())
		{
			case 0 | 1 | 2: // RIGHT_FULL | LEFT_FULL | CUSTOM
				controls.setVirtualPadNOTES(androidControls.virtualPad, RIGHT_FULL, NONE);
			case 3: // BOTH_FULL
				controls.setVirtualPadNOTES(androidControls.virtualPad, BOTH_FULL, NONE);
			case 4: // HITBOX
				controls.setHitBox(androidControls.hitbox);
			case 5: // KEYBOARD
		}

		trackedinputsNOTES = controls.trackedinputsNOTES;
		controls.trackedinputsNOTES = [];

		var camControls = new flixel.FlxCamera();
		FlxG.cameras.add(camControls);
		camControls.bgColor.alpha = 0;

		androidControls.cameras = [camControls];
		androidControls.visible = false;
		add(androidControls);
	}

	public function removeAndroidControls()
	{
		if (trackedinputsNOTES != [])
			controls.removeFlxInput(trackedinputsNOTES);

		if (androidControls != null)
			remove(androidControls);
	}

	public function addPadCamera()
	{
		if (virtualPad != null)
		{
			var camControls = new flixel.FlxCamera();
			FlxG.cameras.add(camControls);
			camControls.bgColor.alpha = 0;
			virtualPad.cameras = [camControls];
		}
	}
	#end

	override function destroy()
	{
		#if android
		if (trackedinputsNOTES != [])
			controls.removeFlxInput(trackedinputsNOTES);

		if (trackedinputsUI != [])
			controls.removeFlxInput(trackedinputsUI);
		#end

		super.destroy();

		#if android
		if (virtualPad != null)
		{
			virtualPad = FlxDestroyUtil.destroy(virtualPad);
			virtualPad = null;
		}

		if (androidControls != null)
		{
			androidControls = FlxDestroyUtil.destroy(androidControls);
			androidControls = null;
		}
		#end
	}
	override function create() {
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;
	}
	
	#if (VIDEOS_ALLOWED && windows)
	override public function onFocus():Void
	{
		FlxVideo.onFocus();
		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		FlxVideo.onFocusLost();
		super.onFocusLost();
	}
	#end

	public var canQuickSettings:Bool = false;
	public var inQuickSettings:Bool = false;

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

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

		#if debug
		if(FlxG.keys.justPressed.F3) {
			@:privateAccess
			for (key in FlxG.bitmap._cache.keys()) {
				var bitmap = FlxG.bitmap._cache.get(key);
				if(bitmap != null) {
					trace('"' + key + '" uses ${bitmap.width * bitmap.height * 4} (${bitmap.width}x${bitmap.height})');
				}
			}
		}
		#end

		super.update(elapsed);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
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
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor(((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / Conductor.stepCrochet);
	}

	public static var songLoadingScreen:String = "";
	public static var nextGhostAllowed:Bool = false;

	static function loadingScreen(leState:MusicBeatState, camera:FlxCamera, ?trans:CustomFadeTransition) {
		#if windows
		if(!nextGhostAllowed) {
			NoGhost.disable();
		}
		nextGhostAllowed = false;
                #end
		var loading = new FlxSprite().loadGraphic(Paths.image("loading/" + songLoadingScreen));
		loading.setGraphicSize(FlxG.width, FlxG.height);
		loading.updateHitbox();
		loading.screenCenter();
		loading.scrollFactor.set(0, 0);
		leState.add(loading);
		if(trans != null) {
			trans.add(loading);
			loading.cameras = trans.cameras;
		}
		if(camera != null) {
			loading.cameras = [camera];
		}
		loading.antialiasing = ClientPrefs.globalAntialiasing;
		loading.draw();
		songLoadingScreen = "";
	}

	public static function switchState(nextState:FlxState) {
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if(!FlxTransitionableState.skipNextTransIn) {
			var camera = CustomFadeTransition.nextCamera;
			var trans = new CustomFadeTransition(0.6, false);
			leState.openSubState(trans);
			if(nextState == FlxG.state) {
				CustomFadeTransition.finishCallback = function() {
					if(songLoadingScreen != "") {
						loadingScreen(leState, camera, trans);
					}
					FlxG.resetState();
				};
			} else {
				CustomFadeTransition.finishCallback = function() {
					if(songLoadingScreen != "") {
						loadingScreen(leState, camera, trans);
					}
					FlxG.switchState(nextState);
				};
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		if(songLoadingScreen != "") {
			loadingScreen(leState, FlxG.cameras.list[FlxG.cameras.list.length - 1]);
		}

		FlxG.switchState(nextState);
	}

	public static function resetState() {
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
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


	var _message:FlxFixedText;
	var message(get, null):FlxFixedText;
	function get_message() {
		if(_message == null) {
			_message = new FlxFixedText(0, 0, FlxG.width);
			_message.size = 26;
			_message.borderSize = 1.25;
			_message.alignment = CENTER;
			_message.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			_message.scrollFactor.set();
			_message.screenCenter();
			_message.alpha = 0;
		}

		return _message;
	}
	var messageTween:FlxTween;

	public function showMessage(text:String = "", level = 0, delayUntilFade:Float = 0.5) {
		// TODO: Add message queue
		message.alpha = 1;

		message.color = switch(level) {
			case 0: 0xFFffffff; // Info
			case 1: 0xFFff0000; // Error
			case 2: 0xFFffFF00; // Warning
			case 3: 0xFF00FF00; // Good
			default:0xFFffffff;
		}
		message.text = text;

		message.screenCenter();

		remove(message, true);
		add(message);

		message.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		if(messageTween != null) messageTween.cancel();
		messageTween = FlxTween.tween(message, {alpha: 0}, 1.3, {
			startDelay: delayUntilFade,
			onComplete: (v) -> {
				remove(message, true);
			}
		});
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
