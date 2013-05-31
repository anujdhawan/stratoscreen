package com.stratoscreen.aws
{
	import flash.events.Event;
	
	public class SESEvent extends Event
	{
		public static const SES_EVENT:String = "SES_EVENT";
		
		public var success:Boolean;
		public var result:Object;
		public var code:String = "";
		public var message:String = "";
		
		public function SESEvent( bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.result = null;
			
			super(SES_EVENT, bubbles, cancelable);
		}
	}
}