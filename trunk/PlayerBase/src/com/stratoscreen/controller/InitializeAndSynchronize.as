package com.stratoscreen.controller
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.PlayerConstants;
	import com.stratoscreen.aws.SDBEvent;
	import com.stratoscreen.controller.BandwidthMonitor;
	import com.stratoscreen.events.StepEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.managers.DataManager;
	import com.stratoscreen.managers.FilesManager;
	import com.stratoscreen.model.domains.Medias;
	import com.stratoscreen.model.domains.ScreenDetail;
	import com.stratoscreen.model.domains.Screens;
	import com.stratoscreen.model.views.CountRows;
	import com.stratoscreen.utils.LogUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.Capabilities;
	
	public class InitializeAndSynchronize extends EventDispatcher
	{
		private var _index:int;
		private var _appManager:AppManager;
		private var _dataManager:DataManager;
		private var _filesManager:FilesManager;
		private var _dataControl:DataControl;
		private var _mediaControl:MediaControl;
		private var _reportsControl:ReportsUploadControl;
		private var _success:Boolean = false;
		private var _downloadMedia:Array;
		private var _screenDetails:Array;
		private var _screen:Screens;
		private var _screenRegistered:Boolean = true;		
		private var _firstTimeInstall:Boolean = false; 
		private var _deviceType:String;
		private var _running:Boolean;
		private var _userStop:Boolean = false;
		private var _onlineTest:OnlineTest;
		
		public var restartImmediately:Boolean;	// Not sure if this is still needed
		public var manuallyStarted:Boolean = false;

		public function InitializeAndSynchronize(appManager:AppManager, dataManager:DataManager, 
												 firstInstall:Boolean = false, deviceType:String = "")
		{
			_firstTimeInstall = firstInstall;
			_deviceType = deviceType;
			_appManager = appManager;
			_dataManager = dataManager;
			_filesManager = new FilesManager(_appManager, _dataManager);
			
			super(null);
		}
		
		public function get success():Boolean
		{
			return _success;
		}
				
		public function get screenRegistered():Boolean
		{
			return _screenRegistered;
		}
		
		public function get isRunning():Boolean
		{
			return _running;
		}
		
		public function start():void
		{
			_running = true;
			_userStop = false;
			
			// Check to see if we are on line first
			sendMessage(StepEvent.INFO, "Checking internet connection");
			
			_onlineTest = new OnlineTest(_dataManager);
			_onlineTest.addEventListener(OnlineTest.COMPLETE, onlineTestHandler, false, 0, true); 
			_onlineTest.start();
		}
		
		private function onlineTestHandler(event:Event):void
		{
			_onlineTest.removeEventListener(Event.COMPLETE, onlineTestHandler); 
			_onlineTest.dispose();
			
			_appManager.offline = !_onlineTest.online;
			
			if (_onlineTest.online)
			{
				startData();
			}
			else
			{
				sendMessage(StepEvent.OFFLINE, "Could not establish connection to the internet", false);
			}
		}
		
		private function startData():void
		{
			// Get the info of this Screen first
			if (_firstTimeInstall)
			{
				// Find the Screen 
				var sql:String = "Select * from Screens where accountId = '" + _dataManager.screenSettings.accountId + "' ";
				sql += "and code='" + _dataManager.screenSettings.code + "'";
				_appManager.sdb.select(sql, queryScreensHandler, Screens);
			}
			else
			{
				// Get the latest data from the server
				downloadData();
			}
		}
		
		public function stop():void
		{
			_userStop = true;
			if (_dataControl != null) {_dataControl.stop();}			
		}
		
		private function queryScreensHandler(event:SDBEvent):void
		{
			try
			{
				if (!event.success)
				{
					_success = false;
					if (_firstTimeInstall)
					{
						sendMessage(StepEvent.ERROR, "Could connect to cloud. Please try again later.", false);
					}
					else
					{
						sendMessage(StepEvent.WARNING, "Could connect to cloud. Continuing with local data.");
					}
				}
				
				// If we have nothing back we have an issue. but allow the show to go on
				if (event.result.length == 0)
				{
					if (_firstTimeInstall)
					{
						_screenRegistered = false;
						_success = false;
						sendMessage(StepEvent.INVALID_CODE, "Invalid code.", false);
					}
					else
					{
						_success = false;
						sendMessage(StepEvent.WARNING, "Could connect to cloud. Continuing with local data.");
					}
					
					return;						
				}
				
				_screen = event.result[0] as Screens;
				if (_screen == null) {throw new Error("Could not convert result to Screens object");} 
				
				// Only one screen per code
				if (_screen.type == Screens.TYPE_SCREEN &&  _screen.activatedBool)
				{
					_success = false
					sendMessage(StepEvent.USED_CODE, "This code is already associated with another screen", false);
					return;
				}
				
				// Set the ScreenId. We will need it later
				_dataManager.screenSettings.screenId = _screen.itemName;
				
				// Count the number of screens registered againist this code
				var sql:String = "Select count(*) from ScreenDetail where screenId='" + _screen.itemName + "'";
				_appManager.sdb.select(sql, queryDetailCountHandler, CountRows);
				
			}
			catch (err:Error)
			{
				sendMessage(StepEvent.WARNING, err.message, false, err.errorID);
			}
		}
		
		private function queryDetailCountHandler(event:SDBEvent):void
		{
			try
			{
				var stepEvent:StepEvent;
				if (!event.success)
				{
					_success = false;
					sendMessage(StepEvent.WARNING, "Could verify code. Please try again later", false);
					return;
				}
				
				// If we have too many records we have an issue
				var countRows:CountRows = event.result[0];					
				
				// Create the detail record and send to the server
				var detail:ScreenDetail = new ScreenDetail();
				detail.accountId = _screen.accountId;
				detail.screenId = _screen.itemName;
				detail.screenType = _screen.type;
				detail.activated = "1";
				detail.status = ScreenDetail.STATUS_DOWNLOADING;
				detail.activatedDateUTC = (new Date()).toString();
				detail.lastUpdateUTC = (new Date()).toString();
				
				// Save the item name locally we will need it
				_dataManager.screenSettings.screenDetailId = detail.itemName;
				_dataManager.screenDetail = detail;
				_dataManager.commit(1);
				
				_appManager.sdb.updateDomain([detail], updateDetailHandler);
				
			}
			catch (err:Error)
			{
				sendMessage(StepEvent.WARNING, err.message, false, err.errorID);
			}
		}
		
		
		private function updateDetailHandler(event:SDBEvent):void
		{
			if (!event.success)
			{
				_success = false;
				sendMessage(StepEvent.WARNING, "Could update registration status");
			}
			
			downloadData();
		}
		
		private function downloadData():void
		{
			_dataControl = new DataControl(_appManager, _dataManager);
			_dataControl.addEventListener(StepEvent.STEP_EVENT, dataControlEventHandler);
			_dataControl.start();
		}		
				
		private function downloadMedia(event:StepEvent):void
		{
			if (_userStop)	 // Break the loop 
			{
				if (_mediaControl != null && _mediaControl.downloading) {_mediaControl.abortDownload()}
				return;
			}	
			
			// Treat a null being passed as the first loop of the application
			if (event == null)
			{
				// Clear the download directories before start 
				var files:Array = _appManager.downloadMediaFolder().getDirectoryListing();				
				for each(var file:File in files)
				{
					file.deleteFile();
				}
				
				// Get a list of media to download. 
				// If this is a first time install we will download everything
				_mediaControl = new MediaControl(_appManager, _dataManager, mediaControlEventHandler);
				_mediaControl.addEventListener(ProgressEvent.PROGRESS, mediaProgressHandler);
				
				if (_firstTimeInstall)
				{
					_downloadMedia = _mediaControl.listUsedMedia();
				}
				else
				{
					// Get a list of media used, plus look for media that has been updated
					// We will compare the downloaded files and see what needs to be downloaded 
					var usedMedia:Array = _mediaControl.listUsedMedia();
					_downloadMedia = new Array();
					
					// Loop through and find out if the media has changed
					for (var i:int = 0; i < usedMedia.length; i++)
					{
						var mediaData:Medias = _dataManager.getMedia(usedMedia[i]);
						var mediaMarker:Medias = _dataManager.getMediaMarker(usedMedia[i]);
						
						// Download if we do not have the file and/or marker
						// or their is a difference in modified dates 
						if (mediaMarker == null || mediaData.modifiedDateUTC != mediaMarker.modifiedDateUTC)
						{
							_downloadMedia.push(usedMedia[i]);
							
							// Get the Thumbnail too 
							_downloadMedia.push(Constants.THUMB_PREFIX + usedMedia[i] + Constants.THUMB_EXTENSION);
						}
					}
				}
				
				_index = -1;
			}
			
			_index ++;
			
			
			// After all the media is downloaded 
			if (_index >= _downloadMedia.length)
			{
				uploadReports();
								
				BandwidthMonitor.commit(); // Force a bandwidth calc to save to disk
				
				// We have downloaded a file while the plater is player
				// Tell player to Start the Channel
				_success = true;
				_running = false;
				sendMessage(StepEvent.CHANNEL_READY);
				return;
			}
			
			// Update the status
			var media:Medias;
			var message:String
			
			if (_downloadMedia[_index].indexOf(Constants.THUMB_PREFIX) == 0)
			{
				message = "Downloading thumbnail";
			}
			else
			{
				media = _dataManager.getMedia(_downloadMedia[_index]);
				message = media == null ? "Unknown Media" : "Downloading " + media.name; 
			}			
			
			sendMessage(StepEvent.INFO, message);
			
			_mediaControl.downloadMedia(_downloadMedia[_index], downloadMedia);
		}
		
		/** 
		 * Final step before the Channel starts. When the reports are uploaded the
		 * window will close
		 **/
		private function uploadReports():void
		{
			_reportsControl = new ReportsUploadControl(_appManager, _dataManager, reportUploadEventHandler);
			_reportsControl.uploadReports();
		}
				
				
		private function dataControlEventHandler(event:StepEvent):void
		{
			switch (event.status)
			{				
				case StepEvent.NOT_REGISTERED:					
					_success = false;
					_screenRegistered = false;
					break;
				
				case StepEvent.COMPLETE:
					// Get the media next 
					downloadMedia(null);	
					break;
				
				case StepEvent.ERROR:
					// If this is an not connect error. Just go with what we have
					break;
			}
		
			// Forward the event on
			var stepEvent:StepEvent = new StepEvent(event.status, event.message, event.success, event.percent);;
			this.dispatchEvent(stepEvent);
		}
		
		private function mediaControlEventHandler(event:StepEvent):void
		{
			// Forward the event on
			var stepEvent:StepEvent = new StepEvent(event.status, event.message, event.success, event.percent);;
			this.dispatchEvent(stepEvent);
		}
		
		private function reportUploadEventHandler(event:StepEvent):void
		{
			switch (event.status)
			{				
				case StepEvent.ERROR:
					LogUtils.writeToLog("Could not upload the reports to the cloud", LogUtils.WARN);
					break;
					
				case StepEvent.COMPLETE:
					break;
			}		
		}
		
		private function initComplete():void
		{			
			// Save the settings about this device 
			if (_deviceType != null && _deviceType != "") 
			{_dataManager.screenDetail.device = _deviceType;}	// Assume this will be set on the intial setup
			_dataManager.screenDetail.os = Capabilities.os;
			_dataManager.screenDetail.screenWidth = Capabilities.screenResolutionX.toString();
			_dataManager.screenDetail.screenHeight = Capabilities.screenResolutionY.toString();
			_dataManager.screenDetail.viewMode = _dataManager.screen_.viewMode;
			_dataManager.screenDetail.version = Capabilities.version;
			_dataManager.screenDetail.spaceAvailable = File.documentsDirectory.spaceAvailable.toString();
			
			_dataManager.screenSettings.lastSync = new Date();
		}

		private function sendMessage(status:int, message:String = "", success:Boolean = true, errorId:int = 0):void
		{
			var steps:Number = _downloadMedia == null ? 1 :_downloadMedia.length
			var stepEvent:StepEvent = new StepEvent(status, message, success, _index / steps);
			stepEvent.errorId = errorId;			

			this.dispatchEvent( stepEvent);
		}
		
		private function mediaProgressHandler(event:ProgressEvent):void
		{
			// Forward the event on
			var progressEvent:ProgressEvent = new ProgressEvent(ProgressEvent.PROGRESS);
			progressEvent.bytesLoaded = event.bytesLoaded;
			progressEvent.bytesTotal = event.bytesTotal;
			
			this.dispatchEvent(progressEvent);
		}
	}
}