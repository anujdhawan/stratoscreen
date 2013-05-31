package com.stratoscreen.components
{
	import spark.effects.Fade;
	
	public class Fade_ extends Fade
	{
		public var callback:Function;
		
		public function Fade_(target:Object=null)
		{
			super(target);
		}
	}
}