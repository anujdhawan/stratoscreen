package com.stratoscreen.utils
{
	import com.stratoscreen.model.requests.RequestBase;
	import com.stratoscreen.utils.GUID;
	
	import mx.utils.ObjectUtil;
	
	public class RequestUtils
	{
		public static function generateId():String
		{
			var id:String = GUID.create();
			id = id.replace(new RegExp(/\-/gi), "");
			
			return id;
		}
		public static function generateDate():String
		{
			var now:Date = new Date();
			return now.toUTCString();
		}
		
		public static function createJSON(classObject:Object, emailFrom:String = "", emailTo:String = ""):String
		{
			var base:RequestBase = new RequestBase();
			base.emailFrom = emailFrom;
			base.emailTo = emailTo;
			
			// Get the class name
			// Assume the class name will look like this com.stratoscreen.model.domains::Table
			var classInfo:Object = ObjectUtil.getClassInfo(classObject);
			var sections:Array = classInfo.name.toString().split(":");
			base.name =  sections[sections.length -1];			
			base.object = classObject;
			
			var json:String = JSON.stringify(base);
			return json;
		}
	}		
}