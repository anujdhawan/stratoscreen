package com.stratoscreen.model
{
	import com.stratoscreen.utils.GUID;

	public class RenameId
	{
		public static const MEDIA_GROUP:String = "G";
		public static const MEDIA:String = "M";
		public static const OVERLAY:String = "O";
		public static const CHANNEL:String = "C";
		
		public var oldId:String;
		public var newId:String;
		public var type:String;
		public var displayName:String;	// For the UI only
		
		public function RenameId(oldId:String, type:String, displayName:String = "")
		{
			this.type = type;
			this.displayName = displayName;
			this.oldId = oldId;
			this.newId = GUID.create();
			this.newId = this.newId.replace(new RegExp(/\-/gi), "");
		}
	}
}