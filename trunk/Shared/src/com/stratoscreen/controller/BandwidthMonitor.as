package com.stratoscreen.controller
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.model.Bandwidth;
	import com.stratoscreen.utils.SharedUtils;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.Timer;
	
	public class BandwidthMonitor
	{
		public static const BANDWIDTH_KEY_NAME:String = "BANDWIDTH_KEY_NAME";
		public static const BANDWIDTH_UP:int = 1;
		public static const BANDWIDTH_DOWN:int = 2;
		
		private static var _timer:Timer;
		private static var _bandwidth:Bandwidth;
		private static var _timerCount:int;		
		private static var _reportFolder:File;
		private static var _reportFile:File;
		private static var _reportStream:FileStream;
		private static var _today:int;
		
		/**
		 * If this variable is set the Bandwidth monitor will write
		 * its results to a report
		 */
		public static function set reportFolder(value:File):void
		{
			_reportFolder = value;
			
			setTodaysFile();
		}
		
		public static function get totalBytes():Number
		{
			return _bandwidth.bytesDown + _bandwidth.bytesUp;
		}

		private static function initMonitor():void
		{
			_bandwidth = SharedUtils.getValue(BANDWIDTH_KEY_NAME, "") as Bandwidth;
			
			if (_bandwidth == null)
			{
				_bandwidth = new Bandwidth();
				_bandwidth.lastUpdate = new Date();
				_bandwidth.bytesUp = 0;
				_bandwidth.bytesDown = 0;
			}
			
			if (isNaN(_bandwidth.bytesDown)) {_bandwidth.bytesDown = 0;}
			if (isNaN(_bandwidth.bytesUp)) {_bandwidth.bytesUp = 0;}

			_timer = new Timer(60000);
			_timer.addEventListener(TimerEvent.TIMER, timerHandler);
			_timer.start();
		}
		
		public static function downloaded(bytes:Number, action:String = null):void
		{
			bytesTotal(bytes, BANDWIDTH_DOWN, action);
		}
		
		public static function uploaded(bytes:Number, action:String = null):void
		{
			bytesTotal(bytes, BANDWIDTH_UP, action);
		}
		
		public static function commit():void
		{
			// Save the bandwidth usage to the shared object
			timerHandler(null);
		}
		
		private static function bytesTotal(bytes:Number, direction:int, action:String = null):void
		{
			try
			{
				if (_timer == null) {initMonitor();}
				
				if (action == null) {action = "";}
				
				if (direction == BANDWIDTH_UP) {_bandwidth.bytesUp += bytes;}
				if (direction == BANDWIDTH_DOWN) {_bandwidth.bytesDown += bytes;}
				
				// Do we need to reset the this?
				var now:Date = new Date();
				if (_bandwidth.lastUpdate.month != now.month) 
				{
					_bandwidth.bytesDown = 0;
					_bandwidth.bytesUp;
				}
				
				// Save the a log too
				if (_reportFile != null)
				{
					if (_today != now.day) {setTodaysFile();}
					
					var record:String = (now.time / 1000).toFixed() + "\t";
					record += direction.toString() + "\t";
					record += bytes.toString() + "\t";
					record += _bandwidth.bytesUp.toString() + "\t";
					record += _bandwidth.bytesDown.toString() + "\t";
					record += action + "\r\n";
					
					_reportStream.writeUTFBytes(record);
				}
			}
			catch (err:Error)
			{
				trace(err);
			}
		}
		
		private static function timerHandler(event:TimerEvent):void
		{
			// Save the bandiwdth usage ever 5 minutes
			_timerCount ++;
			if (_timerCount > 5)
			{
				SharedUtils.setValue(BANDWIDTH_KEY_NAME, _bandwidth);
				_timerCount = 0;
			}
		}
		
		private static function setTodaysFile():void
		{
			if (_reportStream != null) {_reportStream.close();}
			
			_today = (new Date()).day;
			
			_reportFile = _reportFolder.resolvePath(Constants.REPORT_BANDWIDTH_PREFIX + _today.toString());
			_reportStream = new FileStream();
			_reportStream.open(_reportFile, FileMode.APPEND);
		}
		
		
	}
}