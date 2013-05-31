package com.stratoscreen.model.domains
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.model.PlayTimes;
	
	[RemoteClass()]
	[Bindable] public class ChannelDetail extends DomainBase
	{
		public static const TYPE_MEDIA:String = "M";
		public static const TYPE_GROUP:String = "G";
		public static const TYPE_OVERLAY:String = "O";
		public static const TYPE_GROUP_OVERLAY:String = "GO";
		
		
		public var channelId:String;
		public var type:String = "";
		public var name:String;
		public var mediaId:String;		// Media, Group, or Overlay ID
		public var mediaGroupId:String;
		public var firstMediaId:String;	// Used in client for create thumbs
		public var order:String;
		public var mediaType:String;
		public var playTimes:String = "";
		public var width:String;
		public var height:String;
		public var effectId:String = "";
		public var audioTrack:String = "0";
		public var channelOverlay:String = "0";

		// Media specific
		public var mimeType:String = "";
		public var duration:String = "";
		public var frames:String = "";
		public var canStream:String = "0";
		public var stream:String = "0";
		public var accelerated:String = "0";

		// Groups specific
		public var groupType:String = "";
		public var playCount:String = "";
		public var playAll:String = "";
		public var playOrder:String = "";		
		
		// Overlays specific
		// None for now. 
		
		
		// The Player and PreviewPlayer will store the Group Detail and Overlay Detail in the class
		public var subDetail:Array;
		
		// Media Group Overlays have two layers of sub detail
		public var subDetail2:Array;
		
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
		
		public function get orderInt():int
		{
			return parseInt(this.order);
		}
	}
}