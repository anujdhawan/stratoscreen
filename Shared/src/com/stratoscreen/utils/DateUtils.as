package com.stratoscreen.utils
{
	import mx.formatters.DateFormatter;
	import mx.formatters.Formatter;

	public class DateUtils
	{
		
		public static function GMTTime(dateTime:Date = null):String
		{
			var now:Date = dateTime; 
			if (now == null) {now = new Date();}	// Use current date if not requested
			
			var month:String = padZeros((now.monthUTC + 1).toString());
			var date:String = padZeros(now.dateUTC.toString());
			var hours:String = padZeros(now.hoursUTC.toString());
			var minutes:String = padZeros(now.minutesUTC.toString());
			var seconds:String = padZeros(now.secondsUTC.toString());
			// Ignore the milliseconds. We can live without.
			
			return(now.fullYearUTC + "-" + month + "-" + date + "T" + hours + ":" + minutes + ":" + seconds + ".000Z");			
		}
		
		public static function RFCTime(dateTime:Date = null):String
		{
			
			var now:Date = dateTime; 
			if (now == null) {now = new Date();}	// Use current date if not requested 

			// I must be missing something. There has to be a better way
			var date:String = (new Date()).toUTCString();
			var rfcDate:String = date.substr(0, 3) + ", ";
			rfcDate += padZeros(now.dateUTC.toString()) + " " ;
			rfcDate += date.substr(4, 3) + " " ;
			rfcDate += now.fullYearUTC.toString() + " ";
			rfcDate += date.substr(10, 8);
			rfcDate += " +0000";
			
			return rfcDate;			
		}
		
		private static function padZeros(value:String):String 
		{
			if (value.length < 2)	{value = 0 + value;}
			return value;
		}		
		
		public static function isTime(value:String):Boolean
		{
			try
			{
				var now:Date = new Date();
				var prefixDate:String = now.toDateString();
				var testDate:Date = new Date(prefixDate + " " + value.toUpperCase());
				
				if(testDate.date.toString()=="NaN")
				{
					return false;
				}
				
				// Make sure we did not pass a 5:66 and it returned 6:06
				var format1:String = formattedDate(testDate,"L:NN A"); 
				var format2:String = formattedDate(testDate,"L:NN:SS A");
				var test3:String = formattedDate(testDate,"LL:NN A"); 
				var test4:String = formattedDate(testDate,"LL:NN:SS A");
				var test5:String = formattedDate(testDate,"H:NN");
				var test7:String = formattedDate(testDate,"H:NN:SS");		
				var test6:String = formattedDate(testDate,"HH:NN");
				var test8:String = formattedDate(testDate,"HH:NN:SS");
				
				var formatTime:String = formattedTime(value);
				if ((formatTime == format1) || (formatTime == format2) || (formatTime == test3) || (formatTime == test4) || (formatTime == test5) || (formatTime == test6) || (formatTime == test7) || (formatTime == test8))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			catch (err:Error)
			{
				return false;
			}
			
			return true;
		}
		
		private static function formattedDate(value:Date, formatString:String):String
		{
			var formatter:DateFormatter = new DateFormatter()
			formatter.formatString = formatString;
			return formatter.format(value);
		} 
		
		public static function formattedTime(value:String):String
		{
			var time:String = value.toUpperCase();
			time = time.replace(" ","");		// Remove double spaces
			time = time.replace("am"," am");	// Add spaces back
			time = time.replace("pm"," pm");
			time = time.replace("AM"," AM");	
			time = time.replace("PM"," PM");
			return time;
		}
		
		public static function getDateFromTimeString(value:String):Date
		{
			try
			{
				var now:Date = new Date();
				
				// Using the colons, we'll chop up the time
				var time:String = value.toLowerCase();
				time = time.replace(new RegExp(/\ /gi), "");			
				var pmFound:Boolean = time.indexOf("pm") > 0;
				var amFound:Boolean = time.indexOf("am") > 0;
				time = time.replace(new RegExp(/\am/gi), "");
				time = time.replace(new RegExp(/\pm/gi), "");
				
				var sections:Array = time.split(":");
				var hours:int = parseInt(sections[0]);
				var minutes:int = parseInt(sections[1]);
				var seconds:int = 0;
				if (sections.length > 2) {seconds = parseInt(sections[2]);}
				
				// Adjust for non military time
				if (amFound && hours == 12) {hours = hours - 12;}
				if (pmFound && hours < 12) {hours = hours + 12;}
				
				return new Date(now.fullYear, now.month, now.day, hours, minutes, seconds);
			}
			catch (err:Error)
			{
				trace(err.message);
			}
			
			return null;
		}
	}
}