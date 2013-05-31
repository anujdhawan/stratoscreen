package com.stratoscreen.model.requests
{
	public class UpdateNow
	{				
		public var time:Number;	// Pass the milliseconds number it will be smaller
		
		public function UpdateNow( time:Number = 0)
		{
			this.time = time;
		}
	}
}