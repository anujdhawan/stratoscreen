package com.stratoscreen.events
{
	import flash.events.Event;
	
	public class StepEvent extends Event
	{
		public static const STEP_EVENT:String =  "STEP_EVENT";
		public static const INFO:int = 0;
		public static const SUCCESS:int = 1;
		public static const WARNING:int = 2;
		public static const ERROR:int = 3;
		public static const PROGRESS:int = 4;
		public static const NOT_REGISTERED:int = 5;
		public static const USED_CODE:int = 6;
		public static const CHANNEL_READY:int = 7;
		public static const OFFLINE:int = 8;
		public static const INVALID_CODE:int = 9;
		public static const COMPLETE:int = 99;
		
		public var success:Boolean = true;
		public var status:int;	// Used for Sub Controls. i.e. BucketControl.
		public var message:String;
		public var percent:Number;
		public var errorId:int = 0;
		public var isMedia:Boolean = false;

		public function StepEvent(status:int, message:String, success:Boolean = true, percent:Number = 0, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.status = status;
			this.message = message;
			this.success = success;
			this.percent = percent;
			
			super(STEP_EVENT, bubbles, cancelable);
		}
	}
}