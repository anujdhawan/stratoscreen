package com.stratoscreen.aws
{
	import flash.events.Event;
	
	public class SNSEvent extends Event
	{
		public static const SNS_EVENT:String = "SNS_EVENT";
		
		public var success:Boolean;
		public var result:Object;
		public var code:String = "";
		public var message:String = "";
		
		public function SNSEvent(bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.result = null;
			
			super(SNS_EVENT, bubbles, cancelable);
		}
	}
}