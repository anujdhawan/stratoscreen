package com.stratoscreen.model.domains
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.model.PlayTimes;
	
	[RemoteClass()]
	public class Overlays extends DomainBase
	{
		public static const TYPE_MEDIA:String = "M";
		public static const TYPE_MEDIA_GROUP:String = "G";
		public static const TYPE_CHANNEL:String = "C";

		[Bindable] public var name:String = "";
		public var baseMediaId:String = "";
		public var baseMediaGroupId:String = "";	// Used for MediaGroup Overlays
		[Bindable] public var baseName:String = "";
		public var type:String = "";
		[Bindable] public var height:String = "";
		[Bindable] public var width:String = "";
		public var playTimes:String = "";
		public var duration:String = "0";
		[Bindable] public var frames:String = "0";
		
		// Used for MediaGroup Overlays
		public var playCount:String = "0";
		public var playAll:String = "1";
		public var playOrder:String = Constants.GROUP_SORT_NONE;
		public var audioOnly:String = "0";
		public var groupType:String = "";

		[Transient] public function get playTimesArray():Array
		{
			var times:Array = new Array();
			try
			{
				var rows:Array =  this.playTimes.split(";");
				for (var i:int = 0; i < rows.length; i++)
				{
					if ( rows[i] != "")
					{
						var sections:Array = rows[i].split(",");
						var item:PlayTimes = new PlayTimes(sections[0], sections[1]);
						times.push(item);
					}
				}
			}
			finally 
			{
				return times;
			}
		}
		
		public function set playTimesArray(value:Array):void
		{
			var times:String = "";
			for each (var playTime:PlayTimes in value)
			{
				if (!playTime.deleted && !playTime.blankRow)
				{
					if (times != "") {times += ";";}	
					times += playTime.startTime + "," + playTime.endTime;
				}
			}
			
			this.playTimes = times;
		}
	}
}