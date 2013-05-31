package com.stratoscreen.controller
{
	import com.stratoscreen.aws.SDBEvent;
	import com.stratoscreen.events.ForeignKeyEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.model.views.CountRows;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class ForeignKeyControl extends EventDispatcher
	{
		private const QUERIES_MEDIA:Array =	[
			{name: "Media Group", sql: "Select count(*) from MediaGroupDetail where mediaId='@@ITEMNAME@@'"},
			{name: "Overlay Detail", sql: "Select count(*) from OverlayDetail where mediaId='@@ITEMNAME@@'"},
			{name: "Channel Detail", sql: "Select count(*) from ChannelDetail where mediaId='@@ITEMNAME@@'"}
			];
		
		private const QUERIES_GROUP:Array =	[
			{name: "Channel Detail", sql: "Select count(*) from ChannelDetail where mediaId='@@ITEMNAME@@'"},
			{name: "Media Group Overlay", sql: "Select count(*) from Overlays where baseMediaGroupId='@@ITEMNAME@@'"}
		];
		
		private const QUERIES_OVERLAY:Array =	[
			{name: "Channel Detail", sql: "Select count(*) from ChannelDetail where mediaId='@@ITEMNAME@@'"}
		];		

		private const QUERIES_CHANNELS:Array =	[
			{name: "Schedule Detail", sql: "Select count(*) from ScheduleDetail  where itemId='@@ITEMNAME@@'"}
		];		

		private const QUERIES_USERS:Array =	[
			{name: "Accounts", sql: "Select count(*) from Accounts where createdBy='@@ITEMNAME@@' or  modifiedBy='@@ITEMNAME@@'"},
			{name: "Channel Detail", sql: "Select count(*) from ChannelDetail where createdBy='@@ITEMNAME@@' or  modifiedBy='@@ITEMNAME@@'"},
			{name: "Channel", sql: "Select count(*) from Channels where createdBy='@@ITEMNAME@@' or  modifiedBy='@@ITEMNAME@@'"},
			{name: "Media Group Detail", sql: "Select count(*) from MediaGroupDetail where createdBy='@@ITEMNAME@@' or  modifiedBy='@@ITEMNAME@@'"},
			{name: "Media Groups", sql: "Select count(*) from MediaGroups where createdBy='@@ITEMNAME@@' or  modifiedBy='@@ITEMNAME@@'"},
			{name: "Medias", sql: "Select count(*) from Medias where createdBy='@@ITEMNAME@@' or  modifiedBy='@@ITEMNAME@@'"},
			{name: "Overlay Detail", sql: "Select count(*) from OverlayDetail where createdBy='@@ITEMNAME@@' or  modifiedBy='@@ITEMNAME@@'"},
			{name: "Overlays", sql: "Select count(*) from Overlays where createdBy='@@ITEMNAME@@' or  modifiedBy='@@ITEMNAME@@'"},
			{name: "Schedule Detail", sql: "Select count(*) from ScheduleDetail where createdBy='@@ITEMNAME@@' or  modifiedBy='@@ITEMNAME@@'"},
			{name: "Schedule", sql: "Select count(*) from Schedules where createdBy='@@ITEMNAME@@' or  modifiedBy='@@ITEMNAME@@'"},
			{name: "Screens", sql: "Select count(*) from Screens where createdBy='@@ITEMNAME@@' or  modifiedBy='@@ITEMNAME@@'"},
		];		

		private var _appManager:AppManager;
		private var _itemName:String;
		private var _callback:Function;
		private var _index:int;
		private var _queries:Array;
		private var _patternItemName:RegExp = /\@@ITEMNAME@@/gi;
		private var _event:ForeignKeyEvent;
		
		public function ForeignKeyControl(appManager:AppManager)
		{
			_appManager = appManager;
			super(null);
		}
		
		public function checkMedia(itemName:String, callback:Function):void		
		{
			runProcess(QUERIES_MEDIA, itemName, callback);
		}
		
		public function checkGroups(itemName:String, callback:Function):void		
		{
			runProcess(QUERIES_GROUP, itemName, callback);
		}
		
		public function checkOverlays(itemName:String, callback:Function):void		
		{
			runProcess(QUERIES_OVERLAY, itemName, callback);
		}

		public function checkChannels(itemName:String, callback:Function):void		
		{
			runProcess(QUERIES_CHANNELS, itemName, callback);
		}

		public function checkUsers(itemName:String, callback:Function):void		
		{
			runProcess(QUERIES_USERS, itemName, callback);
		}
		
		private function runProcess(queries:Array, itemName:String, callback:Function):void	
		{
			_itemName = itemName;
			_callback = callback;			
			_index = -1;
			_queries = new Array();
			
			// Precreate the event to pass back
			_event = new ForeignKeyEvent();
			
			// Create the test array
			for (var i:int = 0; i < queries.length; i++)
			{
				var item:Object = queries[i];
				item.sql = item.sql.replace(_patternItemName, itemName);
				
				_queries.push(item);
			}
			
			runQueries(null);			
		}
		
		private function runQueries(event:SDBEvent):void
		{
			try
			{
				if (event != null)
				{
					if (!event.success)	{throw new Error(event.message);}

					// Check for conficts
					var rowCount:String = event.result[0].Count;
					if (rowCount != "0")
					{
						_event.conflictFound = true;
						_event.success = true;
						_event.displayName = _queries[_index].name;
						_callback(_event);	
						return;					
					}
				}				
				
				// Check for a positive return;				
				_index++;
				if (_index >= _queries.length)
				{
					_event.conflictFound = false;
					_event.success = true;
					_callback(_event);	
					return;
				}
				
				// Run the query to check for conflics
				var sql:String = _queries[_index].sql;
				_appManager.sdb.select(sql, runQueries, CountRows);				
			}
			catch (err:Error)
			{
				_event.message = err.message;
				_callback(_event);
			}
		}
	}
}