package com.stratoscreen.controller
{
	import com.stratoscreen.model.ResubmitSDBRequest;
	
	import flash.utils.Timer;
	
	public class ResubmitTimer extends Timer
	{
		public var request:Object;
		
		public function ResubmitTimer(delay:Number, repeatCount:int = 0)
		{
			super(delay, repeatCount);
		}
	}
}