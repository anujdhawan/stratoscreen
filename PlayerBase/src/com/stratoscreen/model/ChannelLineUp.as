package com.stratoscreen.model
{
	public class ChannelLineUp
	{
		public var startTime:Date;
		public var channelId:String;

		public function ChannelLineUp(start:Date, id:String)
		{
			this.startTime = start;
			this.channelId = id;
		}
	}
}