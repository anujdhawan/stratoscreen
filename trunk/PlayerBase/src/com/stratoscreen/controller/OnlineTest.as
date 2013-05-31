package com.stratoscreen.controller
{
	import com.stratoscreen.aws.AWSEndpoint;
	import com.stratoscreen.aws.AWSRegions;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.managers.DataManager;
	import com.stratoscreen.utils.LogUtils;
	
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	[Event(name="COMPLETE", type="com.stratoscreen.controller.OnlineTest")]
	public class OnlineTest extends EventDispatcher
	{		
		// Wait 5 minutes between test
		public var pause:int = 5 * 60 * 1000; 
			
		private var _dataManager:DataManager;
		private var _loader:URLLoader;
		private var _url:String;
		private var _online:Boolean = false;
		private var _attemptsMax:int = 2;
		private var _attemptsCount:int = 0;
		private var _lastTest:Date;
		
		public static const COMPLETE:String = "COMPLETE";
	
		public function OnlineTest(dataManager:DataManager, attempts:int = 2)
		{
			super(null);

			_dataManager = dataManager;
			_attemptsMax = attempts;					}
		
		public function get online():Boolean
		{
			return _online;
		}
		
		public function start():void
		{
			// Only check every 5 minutes
			if (_lastTest != null && !_online)
			{
				var diff:Number = (new Date()).time - _lastTest.time;
				if (diff < pause)
				{
					this.dispatchEvent(new Event(COMPLETE));
				}
			}
			
			_lastTest = new Date();
			_attemptsCount = 0;
			loadPkg();
		}
		
		public function dispose():void
		{
			removeListeners();
		}
		
		private function loadPkg():void
		{
			try
			{
				if (_loader == null)
				{
					// Attempt to download the signon package
					var bucket:String = _dataManager.accountHdr.bucket;
					if (bucket == "") {throw new Error("Legacy data found in AccountHdr");}
					
					var index:int =  bucket.toUpperCase().charCodeAt(0) - 64;	// 65 = 'A'						
					var endpoint:AWSEndpoint = AWSRegions.getAWSEndpoint(index);
		
					_url = "https://" + endpoint.s3 + "/" + bucket  + "/" + bucket;
					
					_loader = new URLLoader();
					_loader.addEventListener(Event.COMPLETE, pkgHandler, false, 0, true);
					_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, pkgErrorHandler, false, 0, true);
					_loader.addEventListener(IOErrorEvent.IO_ERROR, pkgErrorHandler, false, 0, true);
				}
				
				_loader.load(new URLRequest(_url));		
			}
			catch(err:Error)
			{
				// Hope for the best that we are online.
				LogUtils.writeErrorToLog(err);
				LogUtils.writeToLog("LoadPkg failed. Cannot determine if we are online. ", LogUtils.WARN);
				
				_online = true;
				this.dispatchEvent(new Event(COMPLETE));
			}
		}
		
		private function pkgHandler(event:Event):void
		{
			_online = true;
			this.dispatchEvent(new Event(COMPLETE));
		}
		
		private function pkgErrorHandler(event:Event):void
		{
			_attemptsCount ++;
			
			if (_attemptsCount < _attemptsMax)
			{
				loadPkg();
			}
			else
			{
				_online = false;
				this.dispatchEvent(new Event(COMPLETE));
			}
		}
		
		private function removeListeners():void
		{
			if (_loader != null)
			{
				_loader.removeEventListener(Event.COMPLETE, pkgHandler);
				_loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, pkgErrorHandler);
				_loader.removeEventListener(IOErrorEvent.IO_ERROR, pkgErrorHandler);
			}
		}
	}
}