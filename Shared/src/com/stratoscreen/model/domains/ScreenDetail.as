package com.stratoscreen.model.domains
{
	[RemoteClass()]
	[Bindable] public class ScreenDetail extends DomainBase
	{
		// The detail status for the invidual TV when this is used 
		// in a group the status will be merged
		public static const STATUS_NONE:String = "";
		public static const STATUS_DOWNLOADING:String = "D";
		public static const STATUS_PLAYING:String = "A";
		public static const STATUS_ERROR:String = "E";
		
		public var screenId:String;
		public var screenType:String = "";
		public var screenWidth:String = "";
		public var screenHeight:String = "";
		public var activated:String = "0";
		public var status:String = STATUS_NONE;
		public var currentMediaId:String = "";
		public var currentChannelId:String = "";
		public var lastUpdateUTC:String = "";	
		public var activatedDateUTC:String = "";
		public var viewMode:String = "";
		public var device:String = "";
		public var os:String = "";
		public var version:String = "";
		public var spaceAvailable:String = "";		
		public var userChannelId:String = "";
		public var bandwidth:String = "";
	}
}