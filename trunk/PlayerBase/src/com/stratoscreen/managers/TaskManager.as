package com.stratoscreen.managers
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.PlayerConstants;
	import com.stratoscreen.aws.SDBEvent;
	import com.stratoscreen.aws.SESEvent;
	import com.stratoscreen.controller.BandwidthMonitor;
	import com.stratoscreen.controller.InitializeAndSynchronize;
	import com.stratoscreen.controller.OnlineTest;
	import com.stratoscreen.events.RestartEvent;
	import com.stratoscreen.events.StepEvent;
	import com.stratoscreen.model.ChannelLineUp;
	import com.stratoscreen.model.domains.Channels;
	import com.stratoscreen.model.domains.ScreenDetail;
	import com.stratoscreen.model.domains.Screens;
	import com.stratoscreen.model.requests.PlayDetailReport;
	import com.stratoscreen.model.requests.RequestBase;
	import com.stratoscreen.model.requests.UpdateNow;
	import com.stratoscreen.model.views.ScreenRequests;
	import com.stratoscreen.utils.DateUtils;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.Utils;
	
	import flash.display.Screen;
	import flash.events.*;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.utils.Timer;
	
	import mx.events.CloseEvent;
	import mx.formatters.DateFormatter;
	import mx.managers.PopUpManager;
	import mx.messaging.Channel;
	import mx.utils.ObjectUtil;
	
	[Event(name="RESTART_PLAYER", type="com.stratoscreen.events.RestartEvent")]
	public class TaskManager extends EventDispatcher
	{				
		private const MILLISECONDS_IN_A_MINUTE:int = 60000;
		private const MILLISECONDS_IN_A_HOUR:int = 3600000;
		private const MILLISECONDS_IN_A_DAY:int = 86400000;
		
		private var _appManager:AppManager;
		private var _dataManager:DataManager;
		private var _timer:Timer;
		private var _nextUpdate:Date;
		private var _nextPing:Date;
		private var _currentDay:int = -1;
		private var _reportFile:File;
		private var _lastRequestId:String = null;	
		private var _onlineTest:OnlineTest;
		
		public function TaskManager(appManager:AppManager, dataManager:DataManager)
		{
			super(null);
			
			_appManager = appManager;
			_dataManager = dataManager;
		}
		
		/**
		 * Start the timed tasks for the plauer 
		 */
		public function start():void
		{	
			
			// We are getting multiple starts from the PlayerStart module
			// add a patch
			if (_timer != null && _timer.running) {return;}
			
			setNextUpdateTime();
			
			// Set up the next ping frequency
			var pingFrequency:int = parseInt(_dataManager.screen_.pingFrequency);
			if (pingFrequency == 0) {pingFrequency = 1;}
			_nextPing = new Date();
			_nextPing.time += pingFrequency * MILLISECONDS_IN_A_MINUTE;
			
			_timer = new Timer(MILLISECONDS_IN_A_MINUTE);	
			_timer.addEventListener(TimerEvent.TIMER, timerHandler);
			_timer.start();
			
			// Run the timer immediately
			timerHandler(null);
		}
		
		private function timerHandler(event:TimerEvent):void
		{
			if (_appManager.offline)
			{
				checkForOnline();
			}
			else
			{
				checkForScheduledUpdate();

				checkForPing();
			
				// Query the screen and see if there is any requests
				// i.e. An 'Update now' or specialized task
				checkForRequestedTask();
			}
		}
				
		/**
		 * Tell the Player to restart itself, so we can download the latest data and media
		 *   
		 */
		private function checkForScheduledUpdate(updateNow:Boolean = false):void
		{
			var now:Date = new Date();
			if (now > _nextUpdate)
			{
				setNextUpdateTime();

				var event:RestartEvent = new RestartEvent(RestartEvent.RESTART_PLAYER, updateNow);
				this.dispatchEvent(event);
			}
		}
		
		/**
		 * Check out the screen record and see if if has changed  
		 */
		private function checkForRequestedTask():void
		{
			// This is the first loop. Ingore the request
			if (_lastRequestId == null) 
			{
				_lastRequestId = _dataManager.screen_.requestTaskId;
				return;
			}
			
			var sql:String = "Select requestTaskId, requestTask from Screens where itemName()='" + _dataManager.screen_.itemName + "'";
			_appManager.sdb.select(sql, checkForRequestsHandler, ScreenRequests);
		}
		
		private function checkForRequestsHandler(event:SDBEvent):void
		{
			try
			{
				if (!event.success)
				{
					LogUtils.writeToLog(event.message, LogUtils.WARN);
					return;
				}
				
				// Expect back one record
				if (event.result.length == 0) {throw new Error("Matching screen record not found");}
				
				var screenRequest:ScreenRequests = event.result[0];
				
				// There are no requests at this time
				// The Storyboard will reset these back to blanks later
				if (screenRequest.requestTaskId == "")
				{
					_lastRequestId = "";
					return;
				}
								
				// Check to see if this is a new request since the last loop 
				if (screenRequest.requestTaskId != _lastRequestId)
				{
					performRequest(screenRequest);
				}

			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
		
		
		/**
		 * The screen can ping the server with the current media and last update time
		 * or it can be done as it happens 
		 * 
		 */
		private function checkForPing():void
		{
			try
			{
				var now:Date = new Date()
				if (now > _nextPing)
				{
					_dataManager.screenDetail.screenType = _dataManager.screen_.type;
					_dataManager.screenDetail.lastUpdateUTC = (new Date()).toString();
					// Watch for a weird #2014 error
					try
					{
						_dataManager.screenDetail.spaceAvailable = File.documentsDirectory.spaceAvailable.toString();
					}
					catch (errSize:Error)
					{
						LogUtils.writeErrorToLog(errSize);
					}
					_dataManager.screenDetail.bandwidth = BandwidthMonitor.totalBytes.toString();
					_dataManager.screenDetail.updated = true;
					
					// Transfer along any changes as the Player level
					// generally a blank mean nothing has changed. 
					_dataManager.screenDetail.viewMode = _dataManager.screenDetail.viewMode == _dataManager.screen_.viewMode ? "" : _dataManager.screen_.viewMode;
					
					// Watch for disappearing data. This is probably a bug in the SToryBoard ScreenControl
					if (_dataManager.screen_.os == "")	
					{
						_dataManager.screen_.os = Capabilities.os;
						_dataManager.screenDetail.os = Capabilities.os;
					}
					if (_dataManager.screen_.screenWidth == "")	
					{
						_dataManager.screen_.screenWidth = Capabilities.screenResolutionX.toString();
						_dataManager.screenDetail.screenWidth = Capabilities.screenResolutionX.toString();
					}
					if (_dataManager.screen_.screenHeight == "") 
					{
						_dataManager.screen_.screenHeight = Capabilities.screenResolutionY.toString();
						_dataManager.screenDetail.screenHeight = Capabilities.screenResolutionY.toString();
					}
					
					_appManager.sdb.updateDomain([_dataManager.screenDetail], pingCompleteHandler);
					
					// Reset the ping frequency
					// double check for a change in data too
					var pingFrequency:int = parseInt(_dataManager.screen_.pingFrequency);
					if (pingFrequency == 0) {pingFrequency = 1;}
					_nextPing = new Date();
					_nextPing.time += pingFrequency * MILLISECONDS_IN_A_MINUTE;
				}
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
		
		private function checkForOnline():void
		{
			if (_onlineTest == null) 
			{
				_onlineTest = new OnlineTest(_dataManager);
				_onlineTest.addEventListener(OnlineTest.COMPLETE, onlineTestHandler, false, 0, true); 
			}
			
			_onlineTest.start()
		}
		
		private function onlineTestHandler(event:Event):void
		{
			_appManager.offline = !_onlineTest.online;
		}
		
		public function updateScreenStatus(channelId:String, channelDetailId:String, mediaId:String):void
		{
			var screenDetail:ScreenDetail = _dataManager.screenDetail;
			if (screenDetail == null) {return;}
			
			screenDetail.currentChannelId = channelId;
			screenDetail.currentMediaId = mediaId;
			screenDetail.lastUpdateUTC = (new Date()).toString();
			screenDetail.status = ScreenDetail.STATUS_PLAYING;

			// Write a tracking record too
			writeCurrentRecord(channelId, channelDetailId, mediaId);
		}
		
		private function writeCurrentRecord(channelId:String, channelDetailId:String, mediaId:String):void
		{
			var now:Date = new Date();
			if (now.day != _currentDay)
			{
				var fileName:String = Constants.REPORT_TRACKING_PREFIX + now.day.toString();
				_reportFile = _appManager.reportsFolder(fileName);
			}
			
			var record:String = (now.time / 1000) + "\t";
			record += channelId + "\t";
			record += channelDetailId + "\t";
			record += mediaId + "\r\n"
			
			var stream:FileStream = new FileStream();
			stream.open(_reportFile, FileMode.APPEND);
			stream.writeUTFBytes(record);
			stream.close();
		}
		
		private function pingCompleteHandler(event:SDBEvent):void
		{
			// Log the message and move on if we could not send to server
			if (!event.success)
			{
				LogUtils.writeToLog(event.message, LogUtils.WARN);
			}
		}
		
		private function setNextUpdateTime():void
		{
			// Set up the next update time. If hourly do it on the hour
			var now:Date = new Date();
			switch (_dataManager.screen_.updateFrequency)
			{
				// Immediate updates not fully updates, skip it for now
				// Add logic just in case				
				case Screens.UPDATE_DAILY:
					var time:Date = DateUtils.getDateFromTimeString(_dataManager.screen_.updateTime); 
					_nextUpdate = new Date(now.fullYear, now.month, now.date, time.hours, time.minutes, 0);
					if (_nextUpdate < now) {_nextUpdate.time += MILLISECONDS_IN_A_DAY;}
					break;
					
				case Screens.UPDATE_HOURLY:
					_nextUpdate = new Date(now.fullYear, now.month, now.date, now.hours, 0, 0);
					if (_nextUpdate < now) {_nextUpdate.time += MILLISECONDS_IN_A_HOUR;}
					break;				
			}
		}
		
		/**
		 * Run a specialized request from ther server. The request will be in JSON
		 * format and should be created from a RequestBase class  
		 * 
		 * @param request
		 * 
		 */
		private function performRequest(screenRequest:ScreenRequests):void
		{
			try
			{				
				var requestBase:RequestBase = Utils.copyClassObject(RequestBase, JSON.parse(screenRequest.requestTask));
				
				switch (requestBase.name)
				{
					case "UpdateNow":
						// Reset the next update time to now. It will run on the next timer start. 
						_nextUpdate = new Date(0);
						checkForScheduledUpdate(true);	// Pass true to erase any user settings
						break;
					
					default:
						LogUtils.writeToLog("Unexpected task " + requestBase.name, LogUtils.WARN);					
				}
				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
			finally
			{
				_lastRequestId = screenRequest.requestTaskId;
			}
		}
		

	}
}