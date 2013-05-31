package com.stratoscreen.components
{
	import flash.net.NetConnection;
	
	public class NetConnection_ extends NetConnection
	{
		public function NetConnection_()
		{
			super();
		}
		
		// There is a bug with the NetConnection object it is missing the follow function
		public function onBWDone():void
		{
		}	
	}
}