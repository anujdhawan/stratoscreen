package com.stratoscreen.managers
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.PlayerConstants;
	import com.stratoscreen.controller.MediaControl;
	import com.stratoscreen.controls.AlertWindow;
	import com.stratoscreen.events.StepEvent;
	import com.stratoscreen.model.domains.Medias;
	import com.stratoscreen.utils.LogUtils;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	
	public class FilesManager
	{
		private var _appManager:AppManager;
		private var _dataManager:DataManager;

		public function FilesManager(appManager:AppManager, dataManager:DataManager)
		{			
			_appManager = appManager;
			_dataManager = dataManager;
		}
		
		public function writeObjectToFile(object:Object, version:int):void
		{
			if (object == null) {return;}
						
			// We do not have th ability to save a blank array
			if (object is Array || object is ArrayCollection)
			{
				if (object.length == 0) {return;} 
			}

			// If the object is an array. Use the first item the object to name
			// the file. We will assume that all the rows in the array are the same object
			var fileName:String;
			if (object is Array || object is ArrayCollection)
			{
				fileName = getClassName(object[0]);
			}
			else
			{
				fileName = getClassName(object);	
			}
			
			// Append the version on the name. We'll use versiosn 0,1,etc 
			// for looking for changes
			fileName += "." + version

			var file:File = _appManager.dataFolder(fileName);
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeObject(object);
			fileStream.close();
		}
		
		public function shiftVersions():void
		{
			// Loop through all the data and rename to the latest version
			var files:Array = _appManager.dataFolder().getDirectoryListing();
			
			// Shift everything up. Preparing for the new "1"
			for (var i:int = PlayerConstants.MAX_DATA_VERSION; i >= 1; i--)
			{
				for each(var file:File in files)
				{
					if (file.extension == i.toString())
					{
						try
						{
							var sections:Array = file.name.split(".");
							var newName:String = sections[0] + "." + (i+1).toString();
							var renamedFile:File = _appManager.dataFolder(newName);
							file.moveTo(renamedFile, true);
						}
						catch (err:Error)
						{
							LogUtils.writeErrorToLog(err);
						}
					}
				}
			}
		}

		public function clean():Boolean
		{
			try
			{
				var files:Array = _appManager.dataFolder().getDirectoryListing();				
				for each(var file:File in files)
				{
					file.deleteFile();
				}			

				files = _appManager.mediaFolder().getDirectoryListing();
				for each(file in files)
				{
					file.deleteFile();
				}			

				return true;
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
			
			return false;
		}
		
		public function deleteUnusedMedia():int
		{			
			// Delete any unused media before we download the latest
			var count:int = 0;
			var mediaControl:MediaControl = new MediaControl(_appManager, _dataManager, mediaDownloadEventHandler);
			var usedMedia:Array = mediaControl.listUsedMedia();
			
			var files:Array = _appManager.mediaFolder().getDirectoryListing();				
			for each(var file:File in files)
			{
				var sections:Array = file.name.split(".");
				var mediaId:String = sections[0];
				mediaId = mediaId.replace(Constants.THUMB_PREFIX, "");;
				var matchFound:Boolean = false;				
				for (var i:int = 0; i < usedMedia.length; i++)
				{
					if (usedMedia[i] == mediaId)
					{
						matchFound = true;
						break;
					}					
				}
				
				if (!matchFound) 
				{
					file.deleteFile();
					count ++;
				}
			}	
			
			return count;
		}
		
		private function mediaDownloadEventHandler(event:StepEvent):void
		{
			
		}
			
		public function getObjectFileVersions(classObject:Class):Array
		{
			var versions:Array = new Array();
			var fileName:String = getClassName(classObject);
			var file:File;
			
			for (var i:int = 1; i <= PlayerConstants.MAX_DATA_VERSION; i++)
			{
				file = _appManager.dataFolder(fileName + "." + i);	
				if(file.exists) {versions.push(i);}
			}
			
			return versions;
		}
		
		public function readObjectFromFile(classObject:Class, version:int = 0):Object
		{
			var fileName:String = getClassName(classObject);
			var file:File;
			
			// If not version is passed looked for the most recent file
			// In therory, we should only have to use one version
			if (version > 0 )
			{
				file = _appManager.dataFolder(fileName + "." + version);
			}
			else
			{
				for (var i:int = 1; i <= PlayerConstants.MAX_DATA_VERSION; i++)
				{
					file = _appManager.dataFolder(fileName + "." + i);	
					if(file.exists) {break;}
				}
			}
			
			
			if(file.exists) 
			{
				var obj:Object;
				var fileStream:FileStream = new FileStream();
				fileStream.open(file, FileMode.READ);
				obj = fileStream.readObject();
				fileStream.close();
				return obj;
			}
			return null;
		}
		
		private static function getClassName(classObject:Object):String
		{
			var fileName:String = getQualifiedClassName(classObject);
			var sections:Array = fileName.split(":");
			
			return sections[sections.length - 1];
		}
		
		public function moveDownloadedMedia():void
		{
			// The Web Player will tell us when it is safe to move files
			// // For consistency this should be handled by the FilesManager, but I am in a rush
			var files:Array = _appManager.downloadMediaFolder().getDirectoryListing();
			for each(var file:File in files)
			{
				try
				{
					var moveFile:File = _appManager.mediaFolder(file.name);
					file.moveTo(moveFile, true);
				}
				catch (err:Error)
				{
					LogUtils.writeErrorToLog(err);
					new AlertWindow("Could not move file. Applicaton may not play properly", "File Error", false, null, null, true);
				}
			}
		}
	}
}