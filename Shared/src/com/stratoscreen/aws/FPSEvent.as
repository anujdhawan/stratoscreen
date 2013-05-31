package com.stratoscreen.aws
{
	import flash.events.Event;
	
	[Deprecated]
	public class FPSEvent extends Event
	{
		public static const FPS_EVENT:String = "FPS_EVENT";
		
		public var success:Boolean;
		public var result:Object;
		public var code:String = "";
		public var message:String = "";
		
		public function FPSEvent(bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(FPS_EVENT, bubbles, cancelable);
		}
	}
}