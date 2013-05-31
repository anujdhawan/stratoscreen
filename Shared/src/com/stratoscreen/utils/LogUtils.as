package com.stratoscreen.utils
{
	CONFIG::isAir 
	{
		import flash.filesystem.File;
		import flash.filesystem.FileMode;
		import flash.filesystem.FileStream;
	}
	
	import mx.formatters.DateFormatter;
	import mx.logging.LogEventLevel;
	import mx.rpc.events.FaultEvent;
	
	public class LogUtils
	{
		public static const DEBUG:int = LogEventLevel.DEBUG;
		public static const ERROR:int = LogEventLevel.ERROR;
		public static const FATAL:int = LogEventLevel.FATAL;
		public static const INFO:int = LogEventLevel.INFO;
		public static const WARN:int = LogEventLevel.WARN;

		private static var _formatter:DateFormatter = null;
		private static var _logFolder:Object = null;

		public function LogUtils()
		{
		}
		
		
		CONFIG::isAir 
		public static function set logsFolder(value:File):void
		{
			_logFolder = value;
		}
		
		private static function dateTimeStamp():String
		{
			if (_formatter == null)
			{
				_formatter = new DateFormatter();
				_formatter.formatString = "JJ:NN:SS ";		
			}
			
			return _formatter.format(new Date());
		}
		
		public static function writeToLog(message:String, level:int = 4):void // 4 = INFO
		{
			writeLine(dateTimeStamp() + "\t" +  level.toString() + "\t" + message);
		}
		
		public static function writeErrorToLog(err:Error, stackLines:int=2, level:int = 8):void //8 = Error 
		{
			try
			{
				var errMessage:String = err.message;
				
				var lines:Array = err.getStackTrace().split("\n");
				
				if (stackLines > lines.length) {stackLines = lines.length;}
				for (var i:int = 0; i < stackLines; i++)
				{
					errMessage += lines[i] + "\r\n";
				}		
				
				writeLine(errMessage);
			}
			catch (err:Error) 
			{
				trace(dateTimeStamp() + "\t" +  level.toString() + "\t" + err.message + "\r\n" + err.getStackTrace()  );				
			}
		}
		
		public static function writeFaultToLog(event:FaultEvent, level:int = 8):void // 8 = Error 
		{
			try
			{
				writeLine(dateTimeStamp() + "\t" +  level.toString() + "\t" + event.fault.message);
			}
			catch (err:Error) 
			{
				trace(dateTimeStamp() + "\t" +  level.toString() + "\t" + err.message + "\r\n" + err.getStackTrace());				
			}			
		}	
		
		CONFIG::isAir 
		public static function writeLine(message:String):void
		{
			if (_logFolder == null) {return;}
			
			var now:Date = new Date();
			var file:File = _logFolder.resolvePath("log" + now.day + ".txt");
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.APPEND);
			stream.writeUTFBytes(message + "\r\n");
			stream.close();

		}
		
		CONFIG::isFlex 
		public static function writeLine(message:String):void
		{
			trace(message);			
		}
	}
}