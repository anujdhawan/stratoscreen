package org.bytearray.video.events
{
	import flash.events.Event;
	
	import org.bytearray.video.SimpleStageVideo;
	
	public class SimpleStageVideoToggleEvent extends Event
	{
		public static const TOGGLE:String = "toggle";
		public static const VIDEO:String = "video";
		public static const STAGEVIDEO:String = "stageVideo";
		
		private var _video:String;
		
		public function SimpleStageVideoToggleEvent(type:String, video:String)
		{
			super(type, false, false);
			_video = video;
		}
		
		public function get video():String
		{
			return _video;
		}

		public override function clone():Event
		{
			return new SimpleStageVideoToggleEvent(type, _video);
		}
		
		public override function toString():String
		{
			return "[SimpleStageVideoToggleEvent video="+_video+"]";	
		}
	}
}