package com.stratoscreen.aws
{
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class AWSURLLoader extends URLLoader
	{
		public var action:String;
		public var resultHandler:Function;
		public var faultHandler:Function;
		public var callback:Function;
		public var format:Class;
		public var requestId:String;
		
		public function AWSURLLoader(request:URLRequest=null)
		{
			super(request);
		}
	}
}