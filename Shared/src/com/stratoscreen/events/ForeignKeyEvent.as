package com.stratoscreen.events
{
	import flash.events.Event;
	
	public class ForeignKeyEvent extends Event
	{
		public static const FOREIGN_KEY_EVENT:String = "FOREIGN_KEY_EVENT";
		
		public var success:Boolean;
		public var conflictFound:Boolean;
		public var displayName:String;	// Used for the message box
		public var message:String;
		
		public function ForeignKeyEvent(bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(FOREIGN_KEY_EVENT, bubbles, cancelable);
			this.success = false;
			this.conflictFound = true;
			this.message = "";
		}
	}
}