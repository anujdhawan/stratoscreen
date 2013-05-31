package com.stratoscreen.controller
{
	import com.stratoscreen.aws.SDBEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.model.domains.ScreenDetail;
	import com.stratoscreen.model.domains.Screens;
	import com.stratoscreen.utils.LogUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;

	/**
	 * Offload the screen query into a control. We will use the opprotunity 
	 * to update the screens at the same time. 
	 * 
	 *  
	 * @author P.J. Steele
	 * 
	 */
	public class ScreenControl extends EventDispatcher
	{
		public static const QUERY_COMPLETE:String = "QUERY_COMPLETE";
		public static const QUERY_ERROR:String = "QUERY_ERROR";
		
		private const MILLISECONDS_IN_A_DAY:int = 86400000;
		
		private var _appManager:AppManager;
		private var _screens:ArrayCollection;
		private var _screenDetail:Array;
		private var _screensLoaded:Boolean = false;
		private var _screenDetailLoaded:Boolean = false;
		private var _success:Boolean;
				
		public function ScreenControl(appManager:AppManager)
		{
			_appManager = appManager;
		}
		
		public function get success():Boolean
		{
			return _success;
		}
		
		public function get screens():ArrayCollection
		{
			return _screens;
		}
		
		public function queryAndUpdateScreens():void
		{		
			var sql:String = "Select * from Screens where accountId='";
			sql += _appManager.currentUser.accountId + "'";
			_appManager.sdb.select(sql, loadScreensHandler, Screens);
			
			sql = "Select * from ScreenDetail where accountId='";
			sql += _appManager.currentUser.accountId + "' ";
			sql += "and screenType='" + Screens.TYPE_SCREEN + "'"; 
			_appManager.sdb.select(sql, loadScreenDetailHandler, ScreenDetail);
		}
		
		private function loadScreensHandler(event:SDBEvent):void
		{			
			try
			{
				if (!event.success) {throw new Error(event.message);}
				
				_screens = new ArrayCollection();
				_screens.source = event.result as Array;				
						
				// Default to a sort by name
				var sort:Sort = new Sort();
				sort.fields = [new SortField("name", true)];				
				_screens.sort = sort;
				_screens.refresh();		
				
				_screensLoaded = true;
				updateScreenStatuses()
				return;
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				this.dispatchEvent(new Event(QUERY_ERROR));
			}			
		}
		
		
		private function loadScreenDetailHandler(event:SDBEvent):void
		{			
			try
			{
				if (!event.success) {throw new Error(event.message);}

				var details:Array = event.result as Array;
				_screenDetail = new Array();
				for (var i:int = 0; i < details.length; i++)
				{
					_screenDetail[details[i].screenId] = details[i];
				}

				_screenDetailLoaded = true;
				updateScreenStatuses()
				return;
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				this.dispatchEvent(new Event(QUERY_ERROR));
			}			
		}

		private function updateScreenStatuses():void
		{
			if (!_screensLoaded || !_screenDetailLoaded) {return;}
			
			// Loop through the Screens and copy some of the data to the Screen
			for each (var scrn:Screens in _screens)
			{				
				var detail:ScreenDetail = _screenDetail[scrn.itemName];
				if (detail != null)
				{
					// Only update if the Screen Detail is newer
					var updatedScreen:Date = new Date(scrn.detailLastUpdateUTC);
					var updatedScreenDetail:Date = new Date(detail.lastUpdateUTC);
					
					// Skip if the date has not change and the Screen is activated
					if (updatedScreenDetail > updatedScreen || 
					   (scrn.activated == "0" && detail.activated == "1"))
					{
						scrn.detailStatus = detail.status;
						scrn.detailLastUpdateUTC = detail.lastUpdateUTC;
						scrn.currentMediaId = detail.currentMediaId;
						scrn.currentChannelId = detail.currentChannelId;
						scrn.currentChannelName = "Fix this";
						scrn.userChannelId = detail.userChannelId;
						
						// Watch for a change from Pending
						if (scrn.activated != "1")
						{
							scrn.status = Screens.STATUS_ACTIVE;
							scrn.activated = "1";
							scrn.activatedDateUTC = detail.activatedDateUTC;
						}
						
						// Some items may have been partially sent
						scrn.device = detail.device == "" ? scrn.device : detail.device;
						scrn.viewMode = detail.viewMode == "" ? scrn.viewMode : detail.viewMode;
						scrn.os = detail.os == "" ? scrn.os : detail.os;
						scrn.screenWidth = detail.screenWidth == "" ? scrn.screenWidth : detail.screenWidth;
						scrn.screenHeight = detail.screenHeight == "" ? scrn.screenHeight : detail.screenHeight;
						scrn.spaceAvailable = detail.spaceAvailable == "" ? scrn.spaceAvailable : detail.spaceAvailable;
						scrn.bandwidth = detail.bandwidth == "" ? scrn.bandwidth : detail.bandwidth; 
						
						// Remove any stale requests
						var now:Date = new Date();
						var requestDate:Date = new Date(scrn.requestTaskDate);
						if (Math.abs(now.time - requestDate.time) > MILLISECONDS_IN_A_DAY)
						{
							scrn.requestTask = "";
							scrn.requestTaskDate = "";
							scrn.requestTaskId = "";
						}
						
						scrn.updated = true;
						scrn.modifiedDate = new Date();
						scrn.modifiedBy = _appManager.currentUser.itemName;
						_appManager.sdb.updateDomain([scrn],updateScreenHandler);
					}
				}				
			}
			
			_success = true
			this.dispatchEvent(new Event(QUERY_COMPLETE));
		}
		
		private function updateScreenHandler(event:SDBEvent):void
		{
			// Ignore the errors for now. We can update the next time
			if (!event.success) {LogUtils.writeToLog(event.message);}
		}

	}
}