package com.stratoscreen.controller
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.aws.S3Class;
	import com.stratoscreen.aws.S3Event;
	import com.stratoscreen.events.UpdateMediaEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.model.domains.Medias;
	import com.stratoscreen.utils.LogUtils;
	
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import mx.graphics.codec.PNGEncoder;
	
	public class MediaControl extends EventDispatcher
	{
		private var _appManager:AppManager;
		private var _media:Medias;
		private var _callback:Function;
		private var _mediaEvent:UpdateMediaEvent;
		private var _stepIndex:int;
		private var _thumbFile:File = null;
		
		public function MediaControl(appManager:AppManager)
		{
			_appManager = appManager;
			super(null);
		}
		
		/**
		 * Assume files are uploaded/updated one at a time for per class 
		 * @param media
		 * @param callback
		 * 
		 */
		public function update(media:Medias, callback:Function):void
		{
			_media = media;
			_callback = callback;
			
			//Precreate the event tyo send back. Assume the worts
			_mediaEvent = new UpdateMediaEvent();
			_mediaEvent.success = false;

			_stepIndex = -1;
			processUpdate(null);
		}
		
		public function delete_(media:Medias, callback:Function):void
		{
			_media = media;
			_media.deleted = true;
			_callback = callback;
			
			//Precreate the event tyo send back. Assume the worts
			_mediaEvent = new UpdateMediaEvent();
			_mediaEvent.success = false;
			
			_stepIndex = -1;
			processDelete(null);
		}
		
		
		private function processUpdate(event:Object):void
		{
			if (event != null)
			{
				// The process failed. Return to the parent humilated. 
				if (!event.success)
				{
					_callback(_mediaEvent);
					return;
				}
			}
			
			_stepIndex ++;
			switch (_stepIndex)
			{
				case 0:
					createUploadThumb();
					break;
				
				case 1:
					uploadMedia();
					break;
				
				case 2:
					updateDatabase(processUpdate);
					break;
				
				default:
					
					// Delete any left over thumbnails
					try
					{
						if (_thumbFile != null) {_thumbFile.deleteFile();}	
					}
					catch (err:Error)
					{
						LogUtils.writeErrorToLog(err, 2, LogUtils.WARN);
					}					
					
					_mediaEvent.success = true;
					_callback(_mediaEvent);
			}
		}
		
		private function processDelete(event:Object):void
		{
			if (event != null)
			{
				// If the DB portion failed, return the failure
				// Otherwise, the media will appear deleted but will still exist				
				if (!event.success && _stepIndex == 0)
				{
					_callback(_mediaEvent);
					return;
				}
			}
			
			_stepIndex ++;
			switch (_stepIndex)
			{
				case 0:
					updateDatabase(processDelete);
					break;
				
				case 1:
					deleteMedia();
					break;

				case 2:
					deleteThumb();
					break;
				
				default:
					_mediaEvent.success = true;
					_callback(_mediaEvent);
			}
		}
		
		private function createUploadThumb():void
		{
			try
			{
				if (_media.thumbBmpData == null) 	{processUpdate(null);}
				
				// Just use the existing bitmap data. Assume it is loaded and resized
				loadThumbHandler(null);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				_mediaEvent.message = err.message;
				_callback(_mediaEvent);
			}
		}
		
		private function deleteThumb():void
		{
			try
			{
				var bucket:String = _appManager.currentAccount.bucket;
				var thumbFile:String =  Constants.THUMB_PREFIX + _media.itemName + Constants.THUMB_EXTENSION; 

				_appManager.s3.deleteFile(bucket, thumbFile, processDelete);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				_mediaEvent.message = err.message;
				_callback(_mediaEvent);
			}			
		}
		
		private function loadThumbHandler(event:Event):void
		{
			try
			{
				// If the event is null we are using the precreated thumbnail 
				if (event != null)
				{
					
				}
				
				// Create the thumbnail. We prefer a PNG. 
				// Also watch for a changed bitmaop
				var encoder:PNGEncoder = new PNGEncoder();
				var bytes:ByteArray = encoder.encode(_media.thumbBmpData);
				
				_thumbFile = File.createTempFile();
				var stream:FileStream = new FileStream();
				stream.open(_thumbFile, FileMode.WRITE);
				stream.writeBytes(bytes);
				stream.close();
				
				var bucket:String = _appManager.currentAccount.bucket;
				var thumbName:String = Constants.THUMB_PREFIX + _media.itemName + Constants.THUMB_EXTENSION;
				_appManager.s3.uploadFile(bucket, _thumbFile, thumbName, processUpdate, S3Class.ACL_PUBLIC_READ);				
				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				_mediaEvent.message = err.message;
				_callback(_mediaEvent);
			}			
		}
		
		private function uploadMedia():void
		{
			try
			{
				if (_media.file == null) 	
				{
					processUpdate(null);
					return;
				}
				
				var bucket:String = _appManager.currentAccount.bucket;
				_appManager.s3.uploadFile(bucket, _media.file, _media.itemName, processUpdate);
				_appManager.s3.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);				
				_mediaEvent.message = err.message;
				_callback(_mediaEvent);				
			}
		}
		
		private function deleteMedia():void
		{
			try
			{
				var bucket:String = _appManager.currentAccount.bucket;
				_appManager.s3.deleteFile(bucket, _media.itemName, processDelete);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);				
				_mediaEvent.message = err.message;
				_callback(_mediaEvent);				
			}			
		}

		private function updateDatabase(interalCallback:Function):void
		{
			try
			{
				if (_media.createdBy == "") {_media.createdBy = _appManager.currentUser.itemName;}					
				_media.modifiedDate = new Date();				
				_appManager.sdb.updateDomain([_media],interalCallback);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);				
				_mediaEvent.message = err.message;
				_callback(_mediaEvent);				
			}
		}

		private function progressHandler(event:ProgressEvent):void
		{
			this.dispatchEvent(event);
		}
		
	}
}