package com.stratoscreen.aws
{
	import flash.events.Event;
	
	public class SDBEvent extends Event
	{
		public static const DB_EVENT:String = "SDB_EVENT";
		
		public var success:Boolean;
		public var domain:String;
		public var result:Object;
		public var code:String = "";
		public var message:String = "";
		public var errorId:int = 0;
		
		public function SDBEvent(bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.result = null;
			
			super(DB_EVENT, bubbles, cancelable);
		}
	}
}