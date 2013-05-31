package com.stratoscreen.model
{
	public class ResubmitSDBRequest
	{
		private var _created:Date;

		public var requestId:String;
		public var endpoint:String;
		public var action:String;
		public var pairs:Array;
		public var callback:Function;
		public var format:Class

		public function get created():Date
		{
			return _created;
		}
		
		public function ResubmitSDBRequest()
		{
			_created = new Date();
		}
	}
}