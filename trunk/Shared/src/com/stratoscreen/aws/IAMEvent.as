package com.stratoscreen.aws
{
	import flash.events.Event;
	
	public class IAMEvent extends Event
	{
		public static const IAM_EVENT:String = "IAM_EVENT";
		
		public var success:Boolean;
		public var result:Object;
		public var code:String = "";
		public var message:String = "";
		
		public function IAMEvent(bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.result = null;
			
			super(IAM_EVENT, bubbles, cancelable);
		}
	}
}