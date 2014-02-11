package 
{
	import flash.desktop.DockIcon;
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemTrayIcon;
	import flash.display.Bitmap;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.events.ScreenMouseEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author Leonid Trofimchuk
	 */
	//[SWF(width = "250", height = "400", backgroundColor = "#000000", frameRate = "30")]
	public class TrainerTimer extends Sprite 
	{
		[Embed(source="../lib/icon_16.png")]
		private const TrayIcon:Class;
		
		[Embed(source="../lib/icon_32.png")]
		private const DocIcon:Class;
		
		[Embed(source="../lib/background.jpg")]
		private const Background:Class;
		
		[Embed(source="../lib/close.png")]
		private const Close:Class;
		
		[Embed(source="../lib/complete.mp3")]
		private const Alarm:Class;
		
		static public const OFF_SET_X:int = 2;
		static public const OFF_SET_Y:int = 2;
		
		private var window:NativeWindow;
		
		private var title:InfoText;
		private var workTime:InfoText;
		private var breakTime:InfoText;
		
		private var startButton:SimpleButton;
		private var resetButton:SimpleButton;
		
		private var closeButton:Sprite;
		
		private var timer:Timer;
		
		private var workLeft:int = 0;
		private var breakLeft:int = 0;
		
		private var workSeconds:int = 0;
		private var breakSeconds:int = 0;
		
		private var sound:Sound;
		private var soundChannel:SoundChannel;
		
		private var playWorkEnd:Boolean;
		private var mouseX0:Number = 0;
		private var mouseY0:Number = 0;
		
		private var titlecontainer:Sprite;
		private var loaded:Boolean = false;	
		
		private var soundButton:SoundButton_graph;
		private var playSound:Boolean = true;
		
		private var roundText:InfoText;
		private var roundCount:int = 1;
		private var position:Point;
		
		public function TrainerTimer():void 
		{
			if (stage)
				addedToStage();
			else
				addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		private function addedToStage(e:Event= null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
			initTray();
			initWindow();
			initTextFields();
			initButtons();
			initClose();
			initSoundButton();
			initTimer();
			initSound();
		}
		
		private function initTray():void 
		{
			NativeApplication.nativeApplication.autoExit = false; 
			
            var iconMenu:NativeMenu = new NativeMenu(); 
            var startCommand:NativeMenuItem = iconMenu.addItem(new NativeMenuItem("Start")); 
            var resetCommand:NativeMenuItem = iconMenu.addItem(new NativeMenuItem("Reset")); 
            var openCommand:NativeMenuItem = iconMenu.addItem(new NativeMenuItem("Show")); 
            var minimizeCommand:NativeMenuItem = iconMenu.addItem(new NativeMenuItem("Hide")); 
            var aboutCommand:NativeMenuItem = iconMenu.addItem(new NativeMenuItem("About")); 
            var closeCommand:NativeMenuItem = iconMenu.addItem(new NativeMenuItem("Exit")); 
			
			startCommand.addEventListener(Event.SELECT, startButtonPressed); 
			resetCommand.addEventListener(Event.SELECT, resetButtonPressed);
			openCommand.addEventListener(Event.SELECT, systrayClick);
			minimizeCommand.addEventListener(Event.SELECT, minimizeButtonPressed);
			aboutCommand.addEventListener(Event.SELECT, aboutButtonPressed);
            closeCommand.addEventListener(Event.SELECT, closeApplication); 
			
            if (NativeApplication.supportsSystemTrayIcon)
			{ 
                NativeApplication.nativeApplication.autoExit = false; 
                 
                var systray:SystemTrayIcon = NativeApplication.nativeApplication.icon as SystemTrayIcon; 
                systray.tooltip = "Trainer Timer"; 
                systray.menu = iconMenu;
				systray.addEventListener(ScreenMouseEvent.CLICK , systrayClick);
				
				NativeApplication.nativeApplication.icon.bitmaps = [new TrayIcon() as Bitmap];
			}
			if (NativeApplication.supportsDockIcon)
			{ 
                var dock:DockIcon = NativeApplication.nativeApplication.icon as DockIcon;  
                dock.menu = iconMenu;
				NativeApplication.nativeApplication.icon.bitmaps = [new DocIcon() as Bitmap];
            } 
			
			
		}
		
		private function systrayClick(e:Event = null):void 
		{
			if (window)
			{
				window.x = position.x;
				window.y = position.y;
				
				window.activate();
				window.restore();
				window.alwaysInFront = true;
				window.alwaysInFront = false;
			}
			
			if(breakTime)
				alignInputText();
		}
		private function minimizeButtonPressed(e:Event):void 
		{
			if (window)
			{
				window.x = Capabilities.screenResolutionX - window.width - TrainerTimer.OFF_SET_X;
				window.y = Capabilities.screenResolutionY + TrainerTimer.OFF_SET_Y;
				//window.minimize();
			}
		}
		
		private function aboutButtonPressed(e:Event):void 
		{
			navigateToURL(new URLRequest("http://vk.com/stesel23"));
		}
		
		private function initClose():void 
		{
			closeButton = new Sprite();
			closeButton.addChild(new Close() as Bitmap);
			closeButton.x = stage.stageWidth - closeButton.width - 3 * OFF_SET_X;
			closeButton.y = 2 * OFF_SET_Y;
			closeButton.mouseChildren = false;
			closeButton.buttonMode = true;
			closeButton.addEventListener(MouseEvent.CLICK, closeApplication);
			this.addChild(closeButton);
		}
		
		private function initWindow():void 
		{
			window = stage.nativeWindow;
			window.title = "Trainer Timer";
			position = new Point();
			position.x = window.x;
			position.y = window.y;
			window.addEventListener(Event.CLOSING, closeApplication, false, 0, true);
			
			var background:Bitmap = new Background() as Bitmap;
			this.addChild(background);
			this.x = 0;
			this.y = 0;
		}
		
		private function initTextFields():void 
		{
			titlecontainer = new Sprite();
			
			title = new InfoText(26, 0xffd21e, true);
			title.setText("Trainer Timer");
			titlecontainer.addChild(title)
			titlecontainer.x = (stage.stageWidth - titlecontainer.width) >> 1;
			titlecontainer.y = OFF_SET_Y;
			titlecontainer.addEventListener(MouseEvent.MOUSE_DOWN, titleOnMouse);
			titlecontainer.addEventListener(MouseEvent.MOUSE_UP, titleOnMouse);
			titlecontainer.buttonMode = true;
			titlecontainer.mouseChildren = false;
			this.addChild(titlecontainer);
			
			roundText = new InfoText(22, 0x26e3db);
			roundText.name = "Round: ";
			roundText.setText( roundText.name );
			roundText.width = roundText.textWidth + OFF_SET_X;
			roundText.height = roundText.textHeight + OFF_SET_Y;
			roundText.x = (stage.stageWidth - roundText.width) >> 1;
			roundText.y = title.y + title.height + 1 * roundText.height;
			roundText.border = true;
			roundText.background = true;
			roundText.backgroundColor = 0x000000;
			roundText.type = TextFieldType.DYNAMIC;
			roundText.multiline = false;
			roundText.selectable = false;
			
			workTime = new InfoText(22, 0xffd21e);
			workTime.name = "Input Work Time";
			workTime.setText( workTime.name );
			workTime.width = workTime.textWidth + OFF_SET_X;
			workTime.height = workTime.textHeight + OFF_SET_Y;
			workTime.x = (stage.stageWidth - workTime.width) >> 1;
			workTime.y = title.y + title.height + 3 * workTime.height;
			workTime.border = true;
			workTime.background = true;
			workTime.backgroundColor = 0x000000;
			workTime.type = TextFieldType.INPUT;
			workTime.multiline = false;
			workTime.selectable = true;
			workTime.restrict = "0-9";
			workTime.maxChars = 4;
			workTime.addEventListener(FocusEvent.FOCUS_IN, textInFocus);
			workTime.addEventListener(FocusEvent.FOCUS_OUT, textOutFocus);
			workTime.addEventListener(Event.CHANGE, textChange);
			this.addChild(workTime);
			
			breakTime = new InfoText(22, 0xffd21e);
			breakTime.name = "Input Break Time";
			breakTime.setText( breakTime.name );
			//breakTime.autoSize = TextFieldAutoSize.NONE;
			breakTime.width = workTime.textWidth + OFF_SET_X;
			breakTime.height = workTime.textHeight + OFF_SET_Y;
			breakTime.x = (stage.stageWidth - breakTime.width) >> 1;
			breakTime.y = workTime.y + workTime.height + breakTime.height;
			breakTime.border = true;
			breakTime.background = true;
			breakTime.backgroundColor = 0x000000;
			breakTime.type = TextFieldType.INPUT;
			breakTime.multiline = false;
			breakTime.selectable = true;
			breakTime.restrict = "0-9";
			breakTime.maxChars = 4;
			breakTime.addEventListener(FocusEvent.FOCUS_IN, textInFocus);
			breakTime.addEventListener(FocusEvent.FOCUS_OUT, textOutFocus);
			breakTime.addEventListener(Event.CHANGE, textChange);
			this.addChild(breakTime);
		}
		
		private function titleOnMouse(e:MouseEvent):void 
		{
			if (e.type == MouseEvent.MOUSE_DOWN && loaded)
			{
				mouseX0 = stage.mouseX;
				mouseY0 = stage.mouseY;
				
				stage.addEventListener(MouseEvent.MOUSE_MOVE, titleMouseMove);
			}
			else
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, titleMouseMove);
			}
		}
		
		private function titleMouseMove(e:MouseEvent):void 
		{
			var bound:Rectangle = window.bounds;
			position.x = bound.x - mouseX0 + stage.mouseX;
			position.y = bound.y - mouseY0 + stage.mouseY;
			window.x = position.x;
			window.y = position.y;
		}
		
		private function initButtons():void 
		{
			startButton = new SimpleButton("Start");
			startButton.scaleX = startButton.scaleY = 0.7;
			startButton.x = stage.stageWidth >> 1;
			startButton.y = breakTime.y + breakTime.height + 2.5 * breakTime.height;
			startButton.addEventListener(ButtonEvent.BUTTON_PRESSED, startButtonPressed);
			this.addChild(startButton);
			
			resetButton = new SimpleButton("Reset");
			resetButton.scaleX = resetButton.scaleY = 0.7;
			resetButton.x = stage.stageWidth >> 1;
			resetButton.y = startButton.y + startButton.height + 0.5 * startButton.height;
			resetButton.addEventListener(ButtonEvent.BUTTON_PRESSED, resetButtonPressed);
			this.addChild(resetButton);
		}
		
		
		private function initTimer():void 
		{
			timer = new Timer(1000);
			timer.addEventListener(TimerEvent.TIMER, onTimer);
		}
		
		private function initSoundButton():void 
		{
			soundButton = new SoundButton_graph();
			soundButton.gotoAndStop(1);
			soundButton.scaleX = soundButton.scaleY = 0.5;
			soundButton.buttonMode = true;
			soundButton.x = stage.stageWidth - soundButton.width - 4 * OFF_SET_X;
			soundButton.y = stage.stageHeight - soundButton.height - 2 * OFF_SET_Y;
			this.addChild(soundButton);
			soundButton.addEventListener(MouseEvent.CLICK, soundButtonClick);
		}
		
		private function soundButtonClick(e:MouseEvent):void 
		{
			playSound = !playSound;
			soundButton.gotoAndStop(playSound ? 1 : 2);
		}
		
		
		private function initSound():void 
		{
			sound = new Alarm() as Sound;
			soundChannel = sound.play(0, 0, new SoundTransform(0));
			loaded = true;
		}
		
		///
		///Event Handlers
		///
		
		private function onTimer(e:TimerEvent):void 
		{
			if (workLeft > 0)
			{
				workTime.setText("Working: " + String(workLeft));
				breakTime.setText("Breaking: 0");
				
				workLeft --;
			}
			else if (breakLeft > 0)
			{
				workTime.setText("Working: 0");
				breakTime.setText("Breaking: " + String(breakLeft));
				
				breakLeft --;
				
				if (playWorkEnd)
				{
					playWorkEnd = false;
					onAlarm();
					window.notifyUser("Work End");
				}
			}
			else if (breakLeft == 0)
			{
				breakTime.setText("Breaking: " + String(breakLeft));
				workLeft = workSeconds;
				breakLeft = breakSeconds;
				workTime.setText("Working: " + String(workLeft));
				workLeft --;
				
				playWorkEnd = true;
				onAlarm();
				window.notifyUser("Break End");
				
				roundText.setText(roundText.name + String(roundCount+=1));
			}
			
			alignInputText();
		}
		
		private function onAlarm():void 
		{
			if (soundChannel)
				soundChannel.stop();
			if(playSound)
				soundChannel = sound.play();
			else if (window)
			{
				systrayClick();
			}
		}
		
		private function alignInputText():void
		{
			workTime.x = (stage.stageWidth - workTime.width) >> 1;
			breakTime.x = (stage.stageWidth - breakTime.width) >> 1;
			roundText.x = (stage.stageWidth - roundText.width) >> 1;
		}
		
		private function startButtonPressed(e:Event):void 
		{
			var workT:int = int(workTime.text);
			var breakT:int = int(breakTime.text);
			if ( workT > 0 && breakT > 0)
			{
				workTime.type = TextFieldType.DYNAMIC;
				breakTime.type = TextFieldType.DYNAMIC;
				workTime.selectable = false;
				breakTime.selectable = false;
				
				startButton.disable();
				
				workSeconds	 = workT;
				breakSeconds = breakT;
				
				workLeft = workSeconds;
				breakLeft = breakSeconds;
				
				timer.start();
				playWorkEnd = true;
				
				roundCount = 1;
				roundText.setText(roundText.name + String(roundCount));
				this.addChild(roundText);
				
				workTime.setText("Working: " + String(workLeft));
				breakTime.setText("Breaking: 0");
			}
			if (workT < 1)
			{
				workTime.setText("Invalid Time");
			}
			if (breakT < 1)
			{
				breakTime.setText("Invalid Time");
			}
			
			alignInputText();
		}
		
		private function resetButtonPressed(e:Event):void 
		{
			if (timer)
				timer.reset();
				
			if (soundChannel)
				soundChannel.stop();
				
			workSeconds		= 0;
			breakSeconds	= 0;
			workLeft		= 0;
			breakLeft 		= 0;
			
			workTime.type = TextFieldType.INPUT;
			breakTime.type = TextFieldType.INPUT;
			workTime.selectable = true;
			breakTime.selectable = true;
			
			workTime.setText(workTime.name);
			
			breakTime.setText(breakTime.name);
			
			alignInputText();
			
			startButton.enable();
			
			this.removeChild(roundText);
		}
		
		private function textChange(e:Event):void 
		{
			var textField:InfoText = e.target as InfoText;
			textField.x = (stage.stageWidth - textField.width) >> 1;
		}
		
		private function textInFocus(e:FocusEvent):void 
		{
			var textField:InfoText = e.target as InfoText;
			if (textField.text.indexOf("I") > -1)
			{
				textField.setText("");
				textField.x = (stage.stageWidth - textField.width) >> 1;
			}
		}
		
		private function textOutFocus(e:FocusEvent):void 
		{
			var textField:InfoText = e.target as InfoText;
			if (textField.text == "")
			{
				textField.setText(textField.name);
				textField.x = (stage.stageWidth - textField.width) >> 1;
			}
		}
		
		private function closeApplication(e:Event):void 
		{
			e.preventDefault();
			
			if (timer)
			{
				timer.stop();
				timer.removeEventListener(TimerEvent.TIMER, onTimer);
				timer = null;
			}
			if (soundChannel)
			{
				soundChannel.stop();
				soundChannel = null;
			}
			window.close();
			NativeApplication.nativeApplication.icon.bitmaps = [];
			NativeApplication.nativeApplication.exit();
		}
		
	}
	
}