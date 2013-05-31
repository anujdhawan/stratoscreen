package com.stratoscreen.model.domains
{	
	import com.stratoscreen.Constants;
	
	import flash.display.BitmapData;
	import flash.net.FileReference;
	
	[RemoteClass()]
	[Bindable] public class Medias extends DomainBase
	{
		include "../includes/MediaType.as";

		public var name:String = "";
		public var height:String = "0";
		public var width:String = "0";
		public var size:String = "0";
		public var mimeType:String = "";
		public var duration:String = "0";
		public var calcDuration:String = "0";	// Not editable
		public var frames:String = "0";
		public var effectId:String = "";	// Not Associated with the Media, but the Media object will help proxy the property
		public var origId:String = "";		// Used for copying media into the library. It helps avoid uploading duplicates		
		public var canStream:String = "0";
		public var stream:String = "0";		// Only used at play time. Data is copied from the ChannelDetail
		public var accelerated:String = "0";
		
		public var uploaded:Boolean;
		public var file:FileReference;
		public var thumbBmpData:BitmapData;
		public var refresh:Boolean;	 // Used to override the data property in MediaItem
		
		private var _modifiedMediaDateUTC:String;

		public function Medias()
		{
			super();
			file = null;
			uploaded = true;
		}		
		
		public function get modifiedMediaDate():Date
		{
			return new Date(_modifiedMediaDateUTC);
		}
		
		public function set modifiedMediaDate(value:Date):void
		{
			_modifiedMediaDateUTC = value.toUTCString(); 
		}

		public function get modifiedMediaDateUTC():String
		{
			return _modifiedMediaDateUTC;
		}
		
		public function set modifiedMediaDateUTC(value:String):void
		{
			_modifiedMediaDateUTC = value;
		}
		
		public function get typeName():String
		{
			if (this.mimeType.indexOf("image") >= 0)
			{
				return "Image";
			} 
			else if (this.mimeType.indexOf("application/x-shockwave-flash") >= 0)
			{
				return "SWF";
			}
			else if (this.mimeType.indexOf("video") >= 0)
			{
				return "Video";			
			}
			else if (this.mimeType.indexOf("audio") >= 0)
			{
				return "Audio";			
			}
			
			// When in doubt return the actual mimetype
			return this.mimeType;
		}
		
		public function get widthNumber():Number
		{
			var value:Number = parseFloat(this.width);
			
			return value == 0 ? 1 : value; // Avoid division by zero
		}
		
		public function get heightNumber():Number
		{
			var value:Number = parseFloat(this.height);
			
			return value == 0 ? 1 : value; // Avoid division by zero
		}
			
		public function get acceleratedBool():Boolean
		{
			return this.accelerated == "1";
		}
		
	}
}