package com.stratoscreen.events
{
	import flash.events.Event;
	
	public class InstallEvent extends Event
	{
		public static const SETUP_EVENT:String =  "SETUP_EVENT";
		public static const INFO:int = 0;
		public static const SUCCESS:int = 1;
		public static const WARNING:int = 2;
		public static const ERROR:int = 3;
		public static const COMPLETE:int = 99;
		
		public var success:Boolean = true;
		public var status:int;	// Used for Sub Controls. i.e. BucketControl.
		public var message:String;
		
		public function InstallEvent(status:int, message:String, success:Boolean = true, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.status = status;
			this.message = message;
			this.success = success;
			super(SETUP_EVENT, bubbles, cancelable);
		}
	}
}