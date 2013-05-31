package com.stratoscreen.controller
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.PlayerConstants;
	import com.stratoscreen.controller.BandwidthMonitor;
	import com.stratoscreen.events.StepEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.managers.DataManager;
	import com.stratoscreen.model.domains.*;
	import com.stratoscreen.model.views.*;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.SharedUtils;
	
	import flash.events.*;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;

	public class MediaControl extends EventDispatcher
	{
		private var _appManager:AppManager;
		private var _dataManager:DataManager;		
		private var _urlStream:URLStream;
		private var _fileStream:FileStream;
		private var _file:File;
		private var _tempDir:File;
		private var _mediaId:String = "";
		private var _callback:Function;
		private var _eventCallback:Function;
		private var _lastBytesLoaded:Number;
		private var _downloading:Boolean = false;
		
		public function MediaControl(appManager:AppManager, dataManager:DataManager, eventCallback:Function)
		{
			_appManager = appManager;
			_dataManager = dataManager;
			_tempDir = File.createTempDirectory();
			_eventCallback = eventCallback;
		}
		
		public function get downloading():Boolean
		{
			return _downloading;
		}
		
		/**
		 * Get all the media that is used in the Channel. 
		 * 
		 * This includes the Media in a MediaGroup in the Channel. The Media in an Overlay in the Channel, etc
		 *  
		 * @return Array
		 * 
		 */
		public function listUsedMedia():Array
		{
			var list:Array = new Array();
			var userChannelId:String =  SharedUtils.getValue(PlayerConstants.USER_CHANNEL_ID, "").toString();
			
			// Get the items for one channel if the user has selected it
			if (userChannelId != "")
			{
				list = listUsedMediaHandler(userChannelId);		
			}
			else
			{
				for each(var scheduleDetail:ScheduleDetail in _dataManager.scheduleDetail)
				{
					var items:Array = listUsedMediaHandler(scheduleDetail.itemId);
					list = list.concat(items);
				}
			}
			
			
			// After the main list is created. Remove the duplicates
			list.sort();
			
			var uniqueList:Array = new Array();
			var lastItemName:String = "";
			for (var i:int = 0; i < list.length; i++)
			{
				if (lastItemName != list[i])
				{
					uniqueList.push(list[i]);
					lastItemName = list[i];	
				}
			}
			
			return uniqueList;
		}
	
		private function listUsedMediaHandler(channelId:String):Array
		{
			var list:Array = new Array();
			
			for each (var channel:Channels in _dataManager.channels)
			{
				// Load the channel if it is in teh schedule 
				// or the user selected it
				if (channel.itemName == channelId)
				{
					for each(var channelDetail:ChannelDetail in _dataManager.channelDetail)
					{
						if (channel.itemName == channelDetail.channelId)
						{
							switch (channelDetail.type)
							{
								case ChannelDetail.TYPE_MEDIA:
									if (channelDetail.stream != "1") {list.push(channelDetail.mediaId);}
									break;
								
								case ChannelDetail.TYPE_GROUP:
									for each(var groupDetail:MediaGroupDetail in _dataManager.mediaGroupDetail)
								{
									if (groupDetail.mediaGroupId == channelDetail.mediaId)
									{
										if (groupDetail.stream != "1") {list.push(groupDetail.mediaId);}
									}
								}
									break;
								
								case ChannelDetail.TYPE_GROUP_OVERLAY:
									for each(groupDetail in _dataManager.mediaGroupDetail)
								{
									if (groupDetail.mediaGroupId == channelDetail.mediaGroupId)
									{
										if (groupDetail.stream != "1") {list.push(groupDetail.mediaId);}
									}
								}
									for each (var overlayDetail:OverlayDetail in _dataManager.overlayDetail)
								{
									if (overlayDetail.overlayId == channelDetail.mediaId)
									{
										if (overlayDetail.type != OverlayDetail.TYPE_TEXT)
										{
											list.push(overlayDetail.mediaId);	
										}								
									}
								}
									break;
								
								case ChannelDetail.TYPE_OVERLAY:										
									for each (overlayDetail in _dataManager.overlayDetail)
								{
									if (overlayDetail.overlayId == channelDetail.mediaId)
									{
										if (overlayDetail.type != OverlayDetail.TYPE_TEXT)
										{
											list.push(overlayDetail.mediaId);	
										}								
									}
								}
									break;
							}
						}
					}
				}
			}
			
			return list;
		}
	
		public function downloadMedia(mediaId:String, callback:Function):void
		{
			try
			{
				_callback = callback;
				_mediaId = mediaId;
				_lastBytesLoaded = 0;
				_downloading = true;
				
				// Create the new file. Delete if needed
				_file = _appManager.tempFolder(mediaId);
				if (_file.exists) {_file.deleteFile();}
	
				// Create the reference to the tempoary local file
				_fileStream = new FileStream();
				_fileStream.openAsync(_file, FileMode.WRITE);
			
				// Assemble the URL for the media
				var url:String = _appManager.s3.getSelectURL(_appManager.accountBucket, mediaId);
				
				// Create a reference and stream to the remote file
				var request:URLRequest = new URLRequest(url);
				
				_urlStream = new URLStream();
				_urlStream.addEventListener(Event.COMPLETE, downloadCompleteHandler);
				_urlStream.addEventListener(ProgressEvent.PROGRESS, downloadProgressHandler);
				_urlStream.addEventListener(IOErrorEvent.IO_ERROR, downloadIOErrorHandler);
				_urlStream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, downloadSecurityErrorHandler);
				_urlStream.load(request);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
		
		public function abortDownload():void
		{
			if (_urlStream != null)
			{
				_urlStream.close();
			}
		}

		private function downloadProgressHandler(event:ProgressEvent):void
		{
			if (_fileStream == null) {return;}
			
			try
			{
				// Download in 50 K chunks
				if (_urlStream.bytesAvailable > 51200)
				{
					var buffer:ByteArray = new ByteArray();
					_urlStream.readBytes(buffer, 0, _urlStream.bytesAvailable);
					_fileStream.writeBytes(buffer, 0, buffer.length);
					
					// Forward the event on
					var progressEvent:ProgressEvent = new ProgressEvent(ProgressEvent.PROGRESS);
					progressEvent.bytesLoaded = event.bytesLoaded;
					progressEvent.bytesTotal = event.bytesTotal;
					
					this.dispatchEvent(progressEvent);
				}
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
			
			try
			{
				var bytesLength:Number = _lastBytesLoaded == 0 ? event.bytesLoaded : event.bytesLoaded - _lastBytesLoaded;
				_lastBytesLoaded = event.bytesLoaded;
				BandwidthMonitor.downloaded(bytesLength, _mediaId);
			}
			catch (err:Error)
			{
				trace(err.message);				
			}
		}

		private function downloadCompleteHandler(event:Event):void
		{
			try
			{
				_downloading = false;

				// Finish the remain bytes of the file
				var buffer:ByteArray = new ByteArray();
				_urlStream.readBytes(buffer, 0, _urlStream.bytesAvailable);
				_fileStream.writeBytes(buffer, 0, buffer.length);
				_fileStream.close();
				
			}
			catch (err:Error)
			{
				// Crud. We have a problem. Try to skip file and recover
				LogUtils.writeErrorToLog(err);
				removeListeners();
				_callback(new StepEvent(StepEvent.WARNING, "", true));
			}
			finally
			{
				// Allow the PC a second to release the stream
				var _timer:Timer = new Timer(333,1);
				_timer.addEventListener(TimerEvent.TIMER, moveFilesHandler);
				_timer.start();				
			}
		}
		
		private function moveFilesHandler(event:TimerEvent):void
		{
			try
			{
				var eventStatus:int = StepEvent.COMPLETE;

				event.target.removeEventListener(TimerEvent.TIMER, moveFilesHandler);
				
				// Copy the file from the temp file to the main directory
				var moveFile:File = _appManager.downloadMediaFolder(_file.name);
				_file.moveTo(moveFile, true);
				
				// Write a companion file so we can check its status later
				if (_file.name.indexOf(Constants.THUMB_PREFIX) != 0)
				{
					var media:Medias = _dataManager.getMedia(_file.name);
					
					var marker:File = _appManager.downloadMediaFolder(_file.name + "." + PlayerConstants.MEDIA_MARKER_EXTENSION);
					var stream:FileStream = new FileStream();
					stream.open(marker, FileMode.WRITE);
					stream.writeObject(media);
					stream.close();
				}
			}
			catch (err:Error)
			{
				eventStatus = StepEvent.WARNING;
				LogUtils.writeErrorToLog(err);
			}
			finally
			{
				removeListeners();
				_callback(new StepEvent(eventStatus, "", true));
			}
		}
		
		private function downloadIOErrorHandler(event:IOErrorEvent):void
		{
			try
			{
				LogUtils.writeToLog(event.text, LogUtils.ERROR);
				
				removeListeners();
				_fileStream.close();
				_file.deleteFile();
			}
			finally
			{
				_callback(new StepEvent(StepEvent.WARNING, event.text, false));
			}
		}
		
		private function downloadSecurityErrorHandler(event:SecurityErrorEvent):void
		{
			try
			{
				removeListeners();
				_fileStream.close();
				_file.deleteFile();
			}
			finally
			{
				_callback(new StepEvent(StepEvent.WARNING, event.text, false));
			}
		}
		
		private function removeListeners():void
		{
			_downloading = false;

			_urlStream.removeEventListener(Event.COMPLETE, downloadCompleteHandler);
			_urlStream.removeEventListener(ProgressEvent.PROGRESS, downloadProgressHandler);
			_urlStream.removeEventListener(IOErrorEvent.IO_ERROR, downloadIOErrorHandler);
			_urlStream.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, downloadSecurityErrorHandler);			
		}

		private function sendEvent(errorType:int, message:String):void
		{
			var event:StepEvent = new StepEvent(errorType, message);
			_eventCallback(event);
		}


	}
}