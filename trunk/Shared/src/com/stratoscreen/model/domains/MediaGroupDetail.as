package com.stratoscreen.model.domains
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.model.PlayTimes;
		
	[RemoteClass()]
	public class MediaGroupDetail extends DomainBase
	{
		include "../includes/MediaType.as";

		public var mediaGroupId:String; 		
		public var mediaId:String;
		public var mimeType:String = "";
		[Bindable] public var name:String;
		public var playOrder:String; 
		[Bindable] public var duration:String = "0";	
		[Bindable] public var frames:String = "0";
		public var playTimes:String = "";
		public var height:String = "0";
		public var width:String = "0";
		public var effectId:String = "0";
		public var stream:String = "0";
		public var accelerated:String = "0";
		
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