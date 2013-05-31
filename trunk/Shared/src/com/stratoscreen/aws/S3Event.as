package com.stratoscreen.aws
{
	import flash.events.Event;
	
	public class S3Event extends Event
	{
		public static const S3_EVENT:String = "S3_EVENT";
		public var success:Boolean;
		public var result:Object = "";
		public var code:String = "";
		public var message:String = "";
		
		public function S3Event( bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(S3_EVENT, bubbles, cancelable);
		}
	}
}