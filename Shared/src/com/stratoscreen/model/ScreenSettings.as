package com.stratoscreen.model
{
	[RemoteClass()]
	public class ScreenSettings
	{
		public var accountId:String
		public var screenId:String;
		public var screenDetailId:String;
		public var code:String;
		public var regionId:int;
		public var webBucket:String;
		public var accountBucket:String;
		public var encryptedAccessKey:String;
		public var encryptedSecretKey:String;
		public var lastSync:Date;
		public var videoDebug:Boolean = false;
		public var useAccel:Boolean = true;
	}
}