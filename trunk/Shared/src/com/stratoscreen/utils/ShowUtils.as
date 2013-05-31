package com.stratoscreen.utils
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.model.domains.MediaGroups;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.Utils;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;

	public class ShowUtils
	{
		public function arrangeGroup(mediaGroup:MediaGroups, source:Array):Array
		{			
			// Is this a randomized group?
			if (mediaGroup.type == Constants.GROUP_TYPE_RANDOM)
			{
				var shuffled:Array = shuffle(source);
				source = shuffled;
			}
			else if (mediaGroup.type == Constants.GROUP_TYPE_SEQUENCE)
			{
				// Sequential groups may need sorted
				var sorted:Array;
				if (mediaGroup.playOrder == Constants.GROUP_SORT_NONE)
				{
					sorted = sortArray(source, "playOrder");
				}
				else if (mediaGroup.playOrder == Constants.GROUP_SORT_ALPHA)
				{
					sorted = sortArray(source, "name");
				}
				else if (mediaGroup.playOrder == Constants.GROUP_SORT_ALPHA_DESC)
				{
					sorted = sortArray(source, "name", true);
				}
				else if (mediaGroup.playOrder == Constants.GROUP_SORT_FIFO)
				{
					sorted = sortArray(source, "modifiedDate");
				}
				else if (mediaGroup.playOrder == Constants.GROUP_SORT_LIFO)
				{
					sorted = sortArray(source, "modifiedDate", true);
				}
				
				source = sorted;
			}
			else
			{
				LogUtils.writeToLog("Unknown Media Group type " + mediaGroup.type);
			}
			
			// The list may need to be truncated
			var playCount:int = parseInt(mediaGroup.playCount);
			if (!mediaGroup.playAllBool)
			{
				if (playCount < source.length)
				{
					var spliced:Array = source.slice(0, playCount);
					source = spliced;	
				}
			}
			
			return source;
		}
		
		private function shuffle(source:Array):Array
		{
			var shuffled:Array = new Array();
			
			while (source.length > 0) 
			{
				shuffled.push(source.splice(Math.round(Math.random() * (source.length - 1)), 1)[0]);
			}
			
			return shuffled;
		}
		
		private function sortArray(source:Array, fieldName:String, descending:Boolean = false):Array
		{
			var arySource:ArrayCollection = new ArrayCollection(source);
			var sort:Sort = new Sort();
			sort.fields = [new SortField(fieldName, true, descending)];
			
			arySource.sort = sort;
			arySource.refresh();
			
			// Recreate the array. Resturning the source will not return the sorted list
			var sorted:Array = new Array();
			for (var i:int = 0; i < arySource.length; i++)
			{
				sorted.push(arySource[i]);
			}
			
			return sorted;
		}
		
		public function getPlayTime(time:String, defaultTime:String):Date
		{
			if (time == null || time == "" || time.toLowerCase() == "null")
			{
				time = defaultTime;
			}
			
			var sections:Array = time.split(":");
			var hours:int = parseInt(sections[0]);
			var minutes:int = 0;
			if (sections.length > 1) {minutes = parseInt(sections[1]);}
			var seconds:int = 0;
			if (sections.length > 2) {seconds = parseInt(sections[2]);}
			
			// Adjust for AM/PM
			if (time.toLowerCase().indexOf("am") > 0)
			{
				if (hours == 12) {hours = 0;}
			}
			
			if (time.toLowerCase().indexOf("pm") > 0)
			{
				if (hours != 12) {hours += 12;}
			}
			
			
			
			return new Date(0,0,0,hours, minutes, seconds);
		}

	}
}