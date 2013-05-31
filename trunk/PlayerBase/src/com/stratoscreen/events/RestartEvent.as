package com.stratoscreen.events
{
	import flash.events.Event;
	
	
	public class RestartEvent extends Event
	{
		public static const RESTART_PLAYER:String = "RESTART_PLAYER";

		public var updateNow:Boolean = false;
		
		public function RestartEvent(type:String, updateNow:Boolean = false, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.updateNow = updateNow;
			super(type, bubbles, cancelable);
		}
	}
}