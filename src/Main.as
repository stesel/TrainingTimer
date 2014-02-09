package 
{
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.system.Capabilities;
	/**
	 * ...
	 * @author Leonid Trofimchuk
	 */
	[SWF(width = "250", height = "400", backgroundColor = "#000000", frameRate = "30")]
	public class Main extends Sprite 
	{
		private var window:NativeWindow;
		
		public function Main():void 
		{
			initWindow();
			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			stage.nativeWindow.x = Capabilities.screenResolutionX - stage.nativeWindow.width - TrainerTimer.OFF_SET_X;
			stage.nativeWindow.y = TrainerTimer.OFF_SET_Y;
			stage.nativeWindow.close();
			
		}
		
		private function initWindow():void 
		{	
			var options:NativeWindowInitOptions = new NativeWindowInitOptions(); 
			options.systemChrome = NativeWindowSystemChrome.NONE; 
			options.type = NativeWindowType.UTILITY; 
			options.transparent = false; 
			options.resizable = false; 
			options.maximizable = false;
			
			window = new NativeWindow(options);
			window.width = 250;
			window.height = 400;
			window.x = Capabilities.screenResolutionX - window.width - TrainerTimer.OFF_SET_X;
			window.y = TrainerTimer.OFF_SET_Y;
			
			var trainerTimer:TrainerTimer = new TrainerTimer();
			window.stage.align = StageAlign.TOP_LEFT;
			window.stage.scaleMode = StageScaleMode.NO_SCALE;
			window.stage.addChild(trainerTimer);
			window.activate();
			
		}
		
	}
	
}