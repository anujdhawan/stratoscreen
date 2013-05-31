package com.stratoscreen.aws
{
	import flash.events.Event;
	
	public class CFEvent extends Event
	{
		public static const CF_EVENT:String = "CF_EVENT";
		
		public var success:Boolean;
		public var result:Object;
		public var code:String = "";
		public var message:String = "";

		public function CFEvent( bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.result = null;
			
			super(CF_EVENT, bubbles, cancelable);
		}
	}
}