package com.stratoscreen.utils
{
	import com.stratoscreen.utils.LogUtils;
	import flash.net.SharedObject;
	
	public class SharedUtils
	{
		public function SharedUtils()
		{
		}
		
		private static const SHARED_NAME:String = "aea5ebcd221e436baeb0413758206e44";
		
		private static var _sharedObject:SharedObject = null;
		
		public static function getValue(key:String, defaultValue:Object):Object
		{
			var savedValue:Object = null;
			try
			{
				savedValue = getSharedObject().data[key];
				if (savedValue == null) {savedValue = defaultValue;}
			}
			catch (err:Error)
			{
				return defaultValue;
			}
			
			return savedValue;						
		}
		
		public static function setValue(key:String, value:Object):Boolean
		{
			try
			{
				getSharedObject().data[key] = value;
				_sharedObject.flush();
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				return false;
			}
			
			return true;						
		}
		
		private static function getSharedObject():SharedObject
		{
			if (_sharedObject == null) {_sharedObject = SharedObject.getLocal(SHARED_NAME, "/");}
			return _sharedObject;
		}			
		
	}
}