package com.stratoscreen.components
{
	import flash.utils.Timer;
	
	public class TimerLocationChange extends Timer
	{
		public var location:String;
		public function TimerLocationChange(delay:Number, repeatCount:int=0)
		{
			super(delay, repeatCount);
		}
	}
}