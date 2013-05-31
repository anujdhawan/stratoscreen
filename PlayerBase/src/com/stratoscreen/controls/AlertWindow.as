package com.stratoscreen.controls
{
	import flash.display.DisplayObjectContainer;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import spark.events.PopUpEvent;

	public class AlertWindow
	{
		private static var _appParent:DisplayObjectContainer;
		
		public static const YES:uint = 1;
		public static const NO:uint = 2;
		public static const OK:uint = 4;

		public var text:String;
		public var title:String;
		public var showYesNo:Boolean = false;
		public var closeHandler:Function;
		public var parent:DisplayObjectContainer;
		public var delay:int = 30;
		
		private var _alert:AlertWindowContainer;
		private var _timerClose:Timer;
		
		public static function setAppParent(value:DisplayObjectContainer):void
		{
			_appParent = value;
		}
		
		public function AlertWindow(text:String = "", title:String = "", showYesNo:Boolean = false, parent:DisplayObjectContainer = null, closeHandler:Function = null, autoClose:Boolean = false)
		{
			if (_appParent == null) {trace("static const appParent is not set ");}
			
			this.text = text;
			this.title = title;
			this.showYesNo = showYesNo;
			this.closeHandler = closeHandler;
			this.parent = parent;
			
			if (autoClose)
			{
				this.showBrief();	// Assume the vars are set	
			}
			else
			{
				if (text != null && text != "") {this.show();}
			}
		}
		
		public function show():void
		{
			_alert = new AlertWindowContainer();
			_alert.title = this.title;
			_alert.body = this.text;
			_alert.showYesNo = this.showYesNo;
			
			CONFIG::isDesktop {_alert.maxWidth = 600;}
			CONFIG::isApp {_alert.maxWidth = 400;}
			
			if (this.closeHandler != null) {_alert.addEventListener(PopUpEvent.CLOSE, closeHandler);}
			
			var alertParent:DisplayObjectContainer = this.parent == null ? _appParent : this.parent;
			
			_alert.open(alertParent, true);
		}
		
		public function close():void
		{
			if (_alert != null) {_alert.close();}	
			if (_timerClose != null) {_timerClose.stop();}
		}
		
		public function showBrief():void
		{
			this.show();
			
			_timerClose = new Timer(delay * 1000,1);
			_timerClose.addEventListener(TimerEvent.TIMER, timerHandler);
			_timerClose.start();
		}
		
		private function timerHandler(event:TimerEvent):void
		{
			_alert.close();
			
			// Send an event if the user is listent
			if (this.showYesNo && this.closeHandler != null)
			{
				var popUpEvent:PopUpEvent = new PopUpEvent(PopUpEvent.CLOSE);
				popUpEvent.data = NO;
				closeHandler(popUpEvent);
			}
		}

	}
}