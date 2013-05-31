package com.stratoscreen.components
{
	import flash.utils.Timer;
	
	import mx.controls.SWFLoader;
	
	public class SWFLoaderTimeout extends Timer
	{
		public var swfLoader:SWFLoader;
		
		public function SWFLoaderTimeout(delay:Number = 2000, repeatCount:int=0)
		{
			super(delay, repeatCount);
		}
	}
}