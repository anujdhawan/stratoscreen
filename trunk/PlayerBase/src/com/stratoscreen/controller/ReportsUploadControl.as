package com.stratoscreen.controller
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.aws.S3Event;
	import com.stratoscreen.events.StepEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.managers.DataManager;
	import com.stratoscreen.model.ScreenSummary;
	import com.stratoscreen.model.Step;
	import com.stratoscreen.model.VolumeSummary;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.Utils;
	import com.stratoscreen.utils.zip.GZIPEncoder;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.filesystem.StorageVolume;
	import flash.filesystem.StorageVolumeInfo;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.utils.Timer;
	
	import mx.utils.ObjectUtil;
	
	/**
	 * Upload to the cloud the information of this screen
	 *  
	 * @author pjsteele
	 * 
	 */
	public class ReportsUploadControl
	{
		private var _appManager:AppManager;
		private var _dataManager:DataManager;
		private var _eventCallback:Function;
		private var _index:int;
		private var _steps:Array;
		private var _summaryFile:File;
		private var _zipFile:File;
		//private var _remoteFolder:String;

		public function ReportsUploadControl(appManager:AppManager, dataManager:DataManager, eventCallback:Function)
		{
			_appManager = appManager;
			_dataManager = dataManager;
			_eventCallback = eventCallback;
			
			_steps = new Array();
			_steps.push(new Step("Uploading Screen Summary", uploadScreenSummary, uploadScreenSummaryHandler));
			_steps.push(new Step("Uploading Usage Report for Today", uploadUsageReport1, uploadUsageReportHandler));
			_steps.push(new Step("Uploading Usage Report for Yesterday", uploadUsageReport2, uploadUsageReportHandler));
		}
		
		public function uploadReports():void
		{
			_index = -1;
			runProcess(null);
		}
		
		private function runProcess(event:Object = null):void
		{
			var step:Step;
			
			// If we have a timer event treat as null
			if (event is TimerEvent)
			{
				event.target.removeEventListener(TimerEvent.TIMER, runProcess);
				event = null;
			}
			
			if (event != null)
			{
				step = _steps[_index] as Step;
				if (!event.success)
				{
					var errorType:int = StepEvent.ERROR;
					if (!step.stopOnFail) {errorType = StepEvent.WARNING;}
					
					sendEvent(errorType,  event.message == ""? "Operation failed" : event.message);
					if (step.stopOnFail) {return;}	
				}
				
				// Run any follow up functions
				if (step.completeHandler != null) 
				{					
					step.completeHandler(event);
				}
			}
			
			_index ++;			
			if (_index >= _steps.length)
			{
				sendEvent(StepEvent.COMPLETE, "");
				return;
			}
			
			step = _steps[_index] as Step;
			sendEvent(StepEvent.INFO, step.startMessage);
			
			// Call the next function. We may have to pass an argument to the function
			step.func();		
		}
		
		/**
		 * Since we do not have a callLater, use a timer to all the events to catch up 
		 */
		private function postRunProcess():void
		{
			var timer:Timer = new Timer(250, 1);
			timer.addEventListener(TimerEvent.TIMER, runProcess);
			timer.start();
		}

		private function sendEvent(errorType:int, message:String):void
		{
			var event:StepEvent = new StepEvent(errorType, message);
			_eventCallback(event);
		}
		
		private function sendProgressEvent(percent:Number):void
		{
			var event:StepEvent = new StepEvent(StepEvent.PROGRESS, "");
			event.percent = percent;
			_eventCallback(event);
		}
		
		private function uploadScreenSummary():void
		{
			try
			{
				// Get the summarized info about this screen
				var summary:ScreenSummary = new ScreenSummary();
				summary.freeMemory = System.freeMemory;
				summary.totalMemory = System.totalMemory;
							
				var properties:Array = new Array();			
				var classInfo:Object = ObjectUtil.getClassInfo(Capabilities, ["_internal","prototype","serverString"] );
				
				for each (var item:Object in classInfo.properties)
				{
					properties.push(item.localName);
				}
	
				summary.capabilities = new Array();
				for (var i:int = 0; i < properties.length; i++)
				{
					summary.capabilities[properties[i]] = Capabilities[properties[i]].toString();
				}
				
				// Add info on all hard drives
				summary.volumes = new Array();
				if (StorageVolumeInfo.isSupported)
				{
					var volumes:Vector.<StorageVolume> = StorageVolumeInfo.storageVolumeInfo.getStorageVolumes();
					for each (var volume:StorageVolume in volumes)
					{
						var vol:VolumeSummary = new VolumeSummary();
						vol.drive = volume.drive;
						vol.name = volume.name;
						vol.removable = volume.isRemovable;
						vol.writeable = volume.isWritable;
						vol.freeSpace = volume.rootDirectory.spaceAvailable;
						
						summary.volumes.push(vol);
					}
				}
				
				_summaryFile = _appManager.tempFolder(Constants.REPORT_SCREEN_SUMMARY);
				var fileStream:FileStream = new FileStream();
				fileStream.open(_summaryFile, FileMode.WRITE);
				fileStream.writeObject(summary);
				fileStream.close();
				
				// Upload the file
				var s3Upload:S3Uploader = new S3Uploader(_appManager.regionId, _appManager.accessKey, _appManager.secretKey);
				var fileName:String = Constants.REPORT_REMOTE_FOLDER + "/" + _dataManager.screen_.itemName + "/" + 
					                  Constants.REPORT_SCREEN_SUMMARY;
				s3Upload.upload(_summaryFile, _appManager.accountBucket, fileName , runProcess);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				postRunProcess();	// Return to the main process to perform the next item
			}
		}
		
		private function uploadScreenSummaryHandler(event:S3Event):void
		{
			try
			{
				_summaryFile.deleteFile();
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				// DO not call the run process. We need this step to fall through
			}
		}
		
		private function uploadUsageReport1():void
		{
			var now:Date = new Date();
			var day:int = now.day;
			
			uploadUsageReportByDay(now.day);
		}	
		
		private function uploadUsageReport2():void
		{
			var now:Date = new Date();
			var day:int = now.day;
			day --;
			
			// update to Saturday if the day is Sunday
			if (day < 0) {day = 6;}
			
			uploadUsageReportByDay(day);
		}	


		
		private function uploadUsageReportByDay(day:int):void
		{
			try
			{
				// Check to see if the report exists
				var report:File = _appManager.reportsFolder(Constants.REPORT_TRACKING_PREFIX + day.toString());
				if (!report.exists)
				{
					postRunProcess();
					return;
				}
					
				// Create a zip file
				var fileName:String = Constants.REPORT_TRACKING_PREFIX + day.toString() + ".gz"
				_zipFile = _appManager.tempFolder(fileName);
				var encoder:GZIPEncoder = new GZIPEncoder();
				encoder.compressToFile(report, _zipFile);
								
				// Upload the file
				// Keep evetything segregated by screen id
				//_appManager.s3.uploadFile(_remoteFolder, _zipFile, fileName, runProcess);
				
				var s3Upload:S3Uploader = new S3Uploader(_appManager.regionId,_appManager.accessKey, _appManager.secretKey);
				var key:String = Constants.REPORT_REMOTE_FOLDER + "/" + _dataManager.screen_.itemName + "/" +  fileName;				
				s3Upload.upload(_zipFile, _appManager.accountBucket, key , runProcess);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				postRunProcess();	// Return to the main process to perform the next item
			}
		}
		
		private function uploadUsageReportHandler(event:S3Event):void
		{
			try
			{
				_zipFile.deleteFile();
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				// DO not call the run process. We need this step to fall through
			}
		}
	}
}