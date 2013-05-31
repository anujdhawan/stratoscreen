package com.stratoscreen.model.domains
{
	import com.stratoscreen.model.PlayTimes;

	[RemoteClass()]
	public class ScheduleDetail extends DomainBase
	{
		public static const DEFAULT_DAYS_OF_WEEK:String = "1111111";	// 7 characters for each day of week
		
		private var _daysOfWeek:String = DEFAULT_DAYS_OF_WEEK;
		private var _startDateString:String = "";
		private var _endDateString:String = "";		

		[Bindable] public var name:String;
		public var type:String;
		public var scheduleId:String;
		public var priority:String;
		public var itemId:String;
		public var playTimes:String = "";
		public var firstMediaId:String = "";
		
		public function ScheduleDetail()
		{
			super();
		}
		
		public function get daysOfWeek():String
		{
			if (_daysOfWeek == null) {_daysOfWeek  = DEFAULT_DAYS_OF_WEEK;}
			
			if (_daysOfWeek.length < 7)
			{
				trace("Incorrect Days of Week format. Using Default");
				_daysOfWeek  = DEFAULT_DAYS_OF_WEEK
			}				
				
			return _daysOfWeek;
		}

		public function set daysOfWeek(value:String):void
		{
			_daysOfWeek = value;
			
			// check the property for bugs
			var temp:String = this.daysOfWeek;
		}
		
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
		
		
		public function get startDate():Date
		{
			return new Date(_startDateString);
		}
		
		public function set startDate(value:Date):void
		{
			_startDateString = value.toDateString(); 
		}
		
		public function get endDate():Date
		{
			return new Date(_endDateString);
		}
		
		public function set endDate(value:Date):void
		{
			_endDateString = value.toDateString(); 
		}
		
		public function get startDateString():String
		{
			return _startDateString;
		}
		
		public function set startDateString(value:String):void
		{
			_startDateString = value;
		}
		
		public function get endDateString():String
		{
			return _endDateString;
		}
		
		public function set endDateString(value:String):void
		{
			_endDateString = value;
		}		
	}
}