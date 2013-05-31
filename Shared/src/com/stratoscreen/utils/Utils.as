package com.stratoscreen.utils
{
	import flash.utils.ByteArray;
	
	import mx.utils.ObjectUtil;
	import mx.utils.StringUtil;
		
	public class Utils
	{
		private static var _hardToReadChars:Array = ["L", "1", "I", "0", "O","Q", "2", "3", "4", "5", "6", "7", "8", "9"];

		/**
		 * A simple escape call will not suffice. Replace forward slashes, astericks, etc 
		 * @param phrase
		 * @return String
		 * 
		 */
		public static function urlEncode(phrase:String):String
		{
			var encoded:String = escape(phrase);
			
			var pattern:RegExp = /\//gi;
			encoded = encoded.replace(pattern, "%2F");
			
			pattern = /\*/gi;;
			encoded = encoded.replace(pattern, "%2A");
			
			pattern = /\+/gi;;
			encoded = encoded.replace(pattern, "%2B");
			
			pattern = /\@/gi;;
			encoded = encoded.replace(pattern, "%40");
			
			return encoded
		}
		
		public static function zeroPad(value:int, length:int):String
		{
			var formatted:String = value.toString();
			
			while( formatted.length < length )
			{
				formatted = "0" + formatted;
			}
			
			return formatted;			
		}
		
		public static function isNumeric(value:String):Boolean
		{
			if (StringUtil.trim(value) == "") {return false;}
			if (!isNaN(Number(value))) {return true;}
			
			return false;
		}
		
		public static function randomString(base:int = 0, length:int = 0 ):String
		{
			// This should be about 5-6 characters
			if (length <= 0) {return randomSubString(base);}
			
			var randString:String = "";
			do 
			{
				randString += randomSubString(base);
			} while (randString.length < length);
			
			
			return randString.substr(0, length);			
		}
		
		
		/**
		 * Create a string without the characters that can be confused i.e. 1, I, 1, L, 0, O
		 * This will create an uppercase string too.
		 *   
		 * @param length
		 * @return 
		 * 
		 */
		public static function randomEasyReadString(length:int = 0 ):String
		{
			var clean:Boolean = false;
			var value:String;
			do
			{
				value = randomString(36, length).toLocaleUpperCase();
				
				for (var i:int = 0; i < _hardToReadChars.length; i++)
				{
					clean = true;	// Hope for the best
					if (value.indexOf(_hardToReadChars[i]) >= 0)
					{
						clean = false;
						break;
					}
				}				
			} while (!clean)
				
			return value;
		}
		
		
		private static function randomSubString(base:int = 0):String
		{
			// This shoudl be about 5-6 charc
			var randNum:int = Math.random() * int.MAX_VALUE;
			var randString:String;
			
			if (base < 2)
			{	
				var base62:Base62 = new Base62();
				randString = base62.toString(randNum);
			}
			else
			{
				randString = randNum.toString(base);
			}
			
			return randString;			
		}
		
		public static function copyClassObject(cls:Class, obj:Object, exclude:Array = null):*
		{
			// Get all the writable fields from the class
			var options:Object = new Object();
			options.includeReadOnly = false;
			
			var properties:Array = new Array();			
			var classInfo:Object = ObjectUtil.getClassInfo(obj, exclude, options);
			for each (var item:Object in classInfo.properties)
			{
				properties.push(item.localName);
			}
			
			
			// Create the class object
			var copied:Object = new cls();
			
			// Assign the existing values
			for (var i:int = 0; i < properties.length; i++)
			{
				try
				{
					copied[properties[i]] = obj[properties[i]];
				}
				catch (err:Error)
				{
					try
					{
						copied[properties[i]] = null;
						trace(err.message);
					}
					catch (err:Error)
					{
						/* Ignore error. This will throw of the object properties do not match */
					}
				}
			}
			
			return copied;
		}
		
		public static function formatBytes(bytes:Number):String 
		{
			if (bytes == 0) {return "";}
			
			var units:Array = ['bytes', 'kb', 'MB', 'GB', 'TB', 'PB'];
			var decimals:Array = [0, 1, 2, 2, 2, 2];
			var e:Number = Math.floor(Math.log(bytes)/Math.log(1024));
			return (bytes/Math.pow(1024, Math.floor(e))).toFixed(decimals[e])+" "+units[e];
		}
		
		public static function formatDuration(seconds:int):String
		{
			var time:Date = new Date(seconds * 1000);
			
			var formatted:String = "";
			if (time.hours > 0) {formatted = time.hours.toString() + ":";}
			formatted = zeroPad(time.minutes, 2) + ":" + zeroPad(time.seconds, 2);
			
			return formatted;
		}
		
		
		public static function clone(source:Object):*
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeObject(source);
			bytes.position = 0;
			return(bytes.readObject());
		}
	}
}