package com.stratoscreen.model.domains
{
	[RemoteClass()]
	[Bindable] public class Screens extends DomainBase
	{	
		public static const OFFLINE_SECONDS:int = 1800;	// 30 minutes
		public static const ACTIVATION_CODE_LENGTH:int = 4;
		
		public static const TYPE_SCREEN:String = "S";
		public static const TYPE_SCREEN_GROUP:String = "G";
		
		public static const UPDATE_DAILY:String = "D";
		public static const UPDATE_HOURLY:String = "H";
		//public static const UPDATE_PER_LOOP:String = "L";
		
		// If a single TV the status will match the detail
		public static const STATUS_PENDING:String = "P";
		public static const STATUS_ACTIVE:String = "A";
		public static const STATUS_INACTIVE:String = "I";
		
		public static const DEVICE_PC:String = "PC";
		public static const DEVICE_ANDROID:String = "ANDROID";
		//public static const DEVICE_GOOGLE_TV:String = "GOOG_TV";
		//public static const DEVICE_SAMSUNG_TV:String = "SM_TV";
		//public static const DEVICE_SAMSUNG_BLU_RAY:String = "SM_BLU";
		public static const DEVICE_STAND_ALONE:String = "SA";
		public static const DEVICE_UNKNOWN:String = "";

		private var _activatedDateUTC:String;
		
		public var name:String;
		public var type:String = TYPE_SCREEN;
		public var device:String = "";
		public var code:String = "";
		public var viewMode:String = "";
		public var state:String = "";
		public var zip:String = "";
		public var screens:String = "1";	// How many screens are in the group
		public var activated:String = "0";
		public var status:String = STATUS_PENDING;
		public var currentMediaId:String = "";
		public var currentChannelId:String = "";
		public var currentChannelName:String = "";
		public var detailLastUpdateUTC:String = "";	
		public var detailStatus:String;
		public var updateFrequency:String = UPDATE_DAILY;
		public var updateTime:String = "2:00 am";
		public var pingFrequency:String = "1";
		public var requestTaskId:String = "";
		public var requestTask:String = "";
		public var requestTaskDate:String = "";
		public var screenWidth:String = "";
		public var screenHeight:String = "";
		public var os:String = "";
		public var version:String = "";
		public var spaceAvailable:String = "";
		public var userControl:String = "1";
		public var userChannelId:String = "";
		public var bandwidth:String = "0";
		
		public function get activatedBool():Boolean
		{
			return this.activated == "1";
		}
		
		public function get activatedDate():Date
		{
			return new Date(_activatedDateUTC);
		}
		
		public function set activatedDate(value:Date):void
		{
			_activatedDateUTC = value.toUTCString(); 
		}
		
		public function get activatedDateUTC():String
		{
			return _activatedDateUTC;
		}
		
		public function set activatedDateUTC(value:String):void
		{
			_activatedDateUTC = value;
		}
		
		public function get isOnline():Boolean
		{
			var now:Date = new Date();
			var lastUpdate:Date = new Date(this.detailLastUpdateUTC);
			var secondsDiff:Number = Math.abs(now.time - lastUpdate.time) / 1000;  							
			return  secondsDiff < OFFLINE_SECONDS;
		}
		
	}
}