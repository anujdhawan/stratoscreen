package com.stratoscreen.components
{
	import flash.events.Event;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	public class NetStream_ extends NetStream
	{
		public static const PLAY_COMPLETE:String = "PLAY_COMPLETE";

		private var _metaData:Object; 
		
		public function NetStream_(connection:NetConnection, peerID:String="connectToFMS")
		{
			super(connection, peerID);
		}
		
		public function onMetaData(metaData:Object = null):void
		{
			_metaData = metaData;
		}
		
		
		// There is a bug with the NetConnection object it is missing the follow function
		public function onPlayStatus(event:Object):void
		{			
			if (event.code != null)
			{
				if (event.code == "NetStream.Play.Complete") 
				{
					this.dispatchEvent(new Event(PLAY_COMPLETE));
				}
			}
		}

	}
}