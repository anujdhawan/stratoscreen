package com.stratoscreen.model
{
	import com.stratoscreen.utils.DateUtils;
	
	[RemoteClass()]
	[Bindable] public class PlayTimes
	{
		public function PlayTimes( startTime:String = "", endTime:String = "")
		{
			this.startTime = startTime;
			this.endTime = endTime;
			this.deleted = false;
			this.blankRow = true;
		}
		public var startTime:String;
		public var endTime:String;
		public var deleted:Boolean;
		public var blankRow:Boolean;
		
		public function datesInSequence():Boolean
		{
			if (this.startTime == "" || this.endTime == "") {return true;}
			
			var startDate:Date = DateUtils.getDateFromTimeString(this.startTime);
			var endDate:Date = DateUtils.getDateFromTimeString(this.endTime);
			
			return endDate > startDate;
		}
	}
}