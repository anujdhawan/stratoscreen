package com.stratoscreen.managers
{
	import com.stratoscreen.PlayerConstants;
	import com.stratoscreen.model.*;
	import com.stratoscreen.model.domains.*;
	import com.stratoscreen.model.views.*;
	import com.stratoscreen.model.views.AccountHdr;
	import com.stratoscreen.model.views.SettingsHdr;
	import com.stratoscreen.utils.*;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.collections.ArrayCollection;
	import mx.collections.SortField;

	public class DataManager
	{
		private static const NO_CHANNEL_MESSAGE:int = 1;
		private static const SCHEDULE_GAP_MESSAGE:int = 2;
		
		private var _appManager:AppManager;
		private var _accountHdr:AccountHdr;
		private var _screenSettings:ScreenSettings;
		private var _screen:Screens;
		private var _screenDetail:ScreenDetail;
		private var _channels:Array;
		private var _channelDetail:Array;
		private var _medias:Array;
		private var _mediaGroups:Array;
		private var _mediaGroupDetail:Array;
		private var _overlays:Array;
		private var _overlayDetail:Array;
		private var _schedule:Array;
		private var _scheduleDetail:Array;
		private var _filesManager:FilesManager;
		private var _settingsHdr:SettingsHdr;
		private var _lastMessage:int = -1;	// Used internally to avoid excessive logs
		
		private var _channelXRef:Array;
		
		public function DataManager(appManager:AppManager)
		{
			_channels = null;
			_filesManager = new FilesManager(appManager,this);
			_appManager = appManager;
		}
		
		public function get filesManager():FilesManager
		{
			return _filesManager;
		}

		public function get screen_():Screens
		{
			try
			{
				if (_screen == null) 
				{
					_screen = _filesManager.readObjectFromFile(Screens) as Screens;
				}
				
				return _screen;
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
			
			return null;
		}
		
		public function set screenDetail(value:ScreenDetail):void
		{
			_screenDetail = value;
		}
		
		public function get screenDetail():ScreenDetail
		{
			try
			{
				if (_screenDetail == null) 
				{
					_screenDetail = _filesManager.readObjectFromFile(ScreenDetail) as ScreenDetail;
				}
				
				// Create the ScreenDetail if it is still null
				if (_screenDetail == null)
				{
					_screenDetail = new ScreenDetail();
					_screenDetail.accountId = _screenSettings.accountId;
					_screenDetail.itemName = _screenSettings.screenDetailId;
					_screenDetail.activated = "1";
					_screenDetail.viewMode = _screen.viewMode;
					_screenDetail.activatedDateUTC = _screen.activatedDateUTC;
				}				
				
				return _screenDetail;
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
			
			return null;
		}
		
		public function set accountHdr(value:AccountHdr):void
		{
			_accountHdr = value;
		}
		
		public function get accountHdr():AccountHdr
		{
			try
			{
				if (_accountHdr == null) 
				{
					_accountHdr = _filesManager.readObjectFromFile(AccountHdr) as AccountHdr;
				}
				
				return _accountHdr;
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
			
			return null;
		}

		public function set settingsHdr(value:SettingsHdr):void
		{
			_settingsHdr = value;
		}
		
		public function get settingsHdr():SettingsHdr
		{
			try
			{
				if (_settingsHdr == null) 
				{
					_settingsHdr = _filesManager.readObjectFromFile(SettingsHdr) as SettingsHdr;
				}
				
				return _settingsHdr;
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
			
			return null;
		}

		public function set screen_(value:Screens):void
		{
			_screen = value;
		}

		public function get screenSettings():ScreenSettings
		{
			try
			{
				if (_screenSettings == null) 
				{
					_screenSettings = _filesManager.readObjectFromFile(ScreenSettings) as ScreenSettings;
				}
				
				return _screenSettings;
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
			
			return null;
		}
		
		public function set screenSettings(value:ScreenSettings):void
		{
			_screenSettings = value;
		}
		
		public function get channels():Array
		{
			if (_channels == null)
			{
				_channels = getArrayFromFile(Channels);
				createChannelXRef()
			}
			
			return _channels;
		}
		
		public function set channels(value:Array):void
		{
			_channels = value;
			createChannelXRef()
		}
		
		private function createChannelXRef():void
		{
			_channelXRef = new Array();
			for (var i:int = 0; i < _channels.length; i++)
			{
				_channelXRef[_channels[i].itemName] = _channels[i];
			}
		}
		
		public function get channelDetail():Array
		{
			if (_channelDetail == null)
			{
				_channelDetail = getArrayFromFile(ChannelDetail);
			}
			
			return _channelDetail;
		}
		
		public function set channelDetail(value:Array):void
		{
			_channelDetail = value;
		}
		
		public function get medias():Array
		{
			if (_medias == null)
			{
				_medias = getArrayFromFile(Medias);
			}
			
			return _medias;
		}
		
		public function set medias(value:Array):void
		{
			_medias = value;
		}
		
		public function get mediaGroups():Array
		{
			if (_mediaGroups == null)
			{
				_mediaGroups = getArrayFromFile(MediaGroups);
			}
			
			return _mediaGroups;
		}
		
		public function set mediaGroups(value:Array):void
		{
			_mediaGroups = value;
		}
				
		public function get mediaGroupDetail():Array
		{
			if (_mediaGroupDetail == null)
			{
				_mediaGroupDetail = getArrayFromFile(MediaGroupDetail);
			}
			
			return _mediaGroupDetail;
		}
		
		public function set mediaGroupDetail(value:Array):void
		{
			_mediaGroupDetail = value;
		}		
		
		public function get overlays():Array
		{
			if (_overlays == null)
			{
				_overlays = getArrayFromFile(Overlays);
			}
			
			return _overlays;
		}
		
		public function set overlays(value:Array):void
		{
			_overlays = value;
		}		
		
		public function get overlayDetail():Array
		{
			if (_overlayDetail == null)
			{
				_overlayDetail = getArrayFromFile(OverlayDetail);
			}
			
			return _overlayDetail;
		}
		
		public function set overlayDetail(value:Array):void
		{
			_overlayDetail = value;
		}	
		
		public function get schedule():Array
		{
			if (_schedule == null)
			{
				_schedule = getArrayFromFile(Schedules);
			}
			
			return _schedule;
		}
		
		public function set schedule(value:Array):void
		{
			_schedule = value;
		}	
		
		public function get scheduleDetail():Array
		{
			if (_scheduleDetail == null)
			{
				_scheduleDetail = getArrayFromFile(ScheduleDetail);
			}
			
			return _scheduleDetail;
		}
		
		public function set scheduleDetail(value:Array):void
		{
			_scheduleDetail = value;
		}		
		
		public function commit(version:int):Boolean
		{
			try
			{
				// Make copies of the data files
				_filesManager.shiftVersions();
				
				_filesManager.writeObjectToFile(_accountHdr, version);
				_filesManager.writeObjectToFile(_screenSettings, version);
				_filesManager.writeObjectToFile(_screen, version);
				_filesManager.writeObjectToFile(_screenDetail, version);
				_filesManager.writeObjectToFile(_channels, version);
				_filesManager.writeObjectToFile(_channelDetail, version);
				_filesManager.writeObjectToFile(_medias, version);
				_filesManager.writeObjectToFile(_mediaGroups, version);
				_filesManager.writeObjectToFile(_mediaGroupDetail, version);
				_filesManager.writeObjectToFile(_overlays, version);
				_filesManager.writeObjectToFile(_overlayDetail, version);
				_filesManager.writeObjectToFile(_schedule, version);
				_filesManager.writeObjectToFile(_scheduleDetail, version);
				_filesManager.writeObjectToFile(_settingsHdr, version);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				return false;
			}
			
			return true;
		}
		
		public function commitTable(table:Object, version:int = 1):Boolean
		{
			try
			{
				_filesManager.writeObjectToFile(table, version);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				return false;
			}
			
			return true;			
		}
		
		private function getArrayFromFile(classObject:Class):Array
		{
			var stored:Array = _filesManager.readObjectFromFile(classObject) as Array;			
			
			return stored;
		}
		
		public function getMedia(id:String):Medias
		{
			// Double check that the medias object is loaded
			if (_medias == null) 
			{
				this.medias;	// Call the property to force the load
			}
			
			for each (var media:Medias in _medias)
			{
				if (media.itemName == id) {return media;}
			}
			
			// Nothing found
			return null;
		}
		
		public function getMediaMarker(mediaId:String):Medias
		{
			try
			{
				var marker:File = _appManager.mediaFolder(mediaId + "." + PlayerConstants.MEDIA_MARKER_EXTENSION);
				if (!marker.exists)	{return null;}
				
				// While here, also check to see if the actual file exists. 
				// In the unlikely event that the data file exists butr not the media file
				// we need to download the file
				if (!_appManager.mediaFolder(mediaId).exists) {return null;}				
				
				var stream:FileStream = new FileStream();
				stream.open(marker, FileMode.READ);
				var media:Medias = stream.readObject();
				stream.close();		
				
				return media;
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
			
			return null;
		}
		
		public function getUpdated(classObject:Class, compareField:String = "modifiedDateUTC" ):Array
		{
			// Compare the the two most versions of the stored classes and return the differences
			var updatedItems:Array = new Array;
			var versions:Array = _filesManager.getObjectFileVersions(classObject);
			
			// Return a blank array if there is nothing to copmpare
			if (versions.length <= 1) {return updatedItems;}
			
			// The list of versions should be sequential. i.e. 1,3,4,5
			var list1:Object =  _filesManager.readObjectFromFile(classObject, versions[0]);
			var list2:Object =  _filesManager.readObjectFromFile(classObject, versions[1]);
			
			// If we do not have arrays we have problems
			if (list1 is Array && list2 is Array)
			{
				// Loop through the object lists. Assume these are classes that inherit the DomainBase
				// We are looking for changes in the ModifiedDate
				for (var i:int = 0; i < list1.length; i++)
				{
					var matchFound:Boolean = false;
					for (var j:int = 0; j < list2.length; j++)
					{
						if (list1[i].itemName == list2[j].itemName)
						{
							matchFound = true;
							if (list1[i][compareField] != list2[j][compareField])
							{
								updatedItems[list1[i].itemName] = list1[i];
							}
							break;
						}
					}						
					
					// If we did not find the row in teh last version we must have a new row
					if (!matchFound) {updatedItems[list1[i].itemName] = list1[i];}
				}
			}
			
			return updatedItems;
		}

		/**
		 * Return the active Channel showing on this Display
		 *  
		 * @return String 
		 * 
		 */
		public function getActiveChannel(dateTime:Date):String
		{
			// Check to see if this channel was set by the user
			var userChannelId:String = SharedUtils.getValue(PlayerConstants.USER_CHANNEL_ID, "").toString();
			if (userChannelId != "") {return userChannelId;}
			
			var _showUtils:ShowUtils = new ShowUtils();
			var sortField:SortField = new SortField("priority");
			var details:Array = DataUtils.sortAndFilter(this.scheduleDetail, [sortField], null);

			// Check to see if this is totally blank
			if (details.length == 0)
			{
				if (_lastMessage != NO_CHANNEL_MESSAGE)
				{	
					LogUtils.writeToLog("There are no channels scheduled to this screen", LogUtils.WARN);
					_lastMessage = NO_CHANNEL_MESSAGE;
				}
				return "";
			}
			
			for each (var detail:ScheduleDetail in details)
			{
				var channelOk:Boolean = true;
				
				// Check for Start and End dates
				if (detail.startDateString != "" && detail.startDateString != "Invalid Date")
				{
					if (dateTime < detail.startDate) {channelOk = false;}					
				}
				
				if (detail.endDateString != "" && detail.endDateString != "Invalid Date")
				{
					if (dateTime > detail.endDate) {channelOk = false;}					
				}
				
				// Check on the day of the week
				if (channelOk)
				{
					var dayOfWeek:int = dateTime.day;
					if (detail.daysOfWeek.substr(dayOfWeek, 1) !=  "1") {channelOk = false;}
				}
				
				// Check Playtimes
				if (channelOk && detail.playTimesArray.length > 0)
				{
					var matchFound:Boolean = false;
					for each(var playtime:PlayTimes in detail.playTimesArray)
					{
						var nowTime:Date = new Date(0,0,0, dateTime.hours, dateTime.minutes, dateTime.seconds);
						var startTime:Date = _showUtils.getPlayTime(playtime.startTime, "00:00:00");
						var endTime:Date = _showUtils.getPlayTime(playtime.endTime, "23:59:59");

						if (nowTime >= startTime && nowTime < endTime)
						{
							matchFound = true;
							break
						}
						
					}
					
					if (!matchFound) {channelOk = false;}
				}
				
				if (channelOk) {return detail.itemId;}
			}
			
			// If we have nothing. We fell through the stack.  Just return something
			if (_lastMessage != SCHEDULE_GAP_MESSAGE)
			{		
				LogUtils.writeToLog("The schedule has a gap in channels for time " + dateTime.toTimeString() + ". " + 
	                                "Reverting to first channel in schedule without dates, weekdays, or playtimes.", LogUtils.WARN);
				_lastMessage = SCHEDULE_GAP_MESSAGE;
			}

			return details[0].itemId;
		}
	
	
		public function getChannelById(id:String):Channels
		{
			return _channelXRef[id];
		}
	}
}