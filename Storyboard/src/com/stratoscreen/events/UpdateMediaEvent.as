package com.stratoscreen.events
{
	import flash.events.Event;
	
	public class UpdateMediaEvent extends Event
	{
		public static const SAVE_MEDIA_EVENT:String =  "SAVE_MEDIA_EVENT";

		public var success:Boolean = true;
		public var message:String = "";
		
		public function UpdateMediaEvent(bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(SAVE_MEDIA_EVENT, bubbles, cancelable);
		}
	}
}