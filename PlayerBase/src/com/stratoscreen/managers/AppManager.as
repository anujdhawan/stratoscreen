package com.stratoscreen.managers
{
	import com.stratoscreen.PlayerConstants;
	import com.stratoscreen.aws.AWSEndpoint;
	import com.stratoscreen.aws.AWSRegions;
	import com.stratoscreen.aws.IAMClass;
	import com.stratoscreen.aws.S3Class;
	import com.stratoscreen.aws.SDBClass;
	import com.stratoscreen.aws.SDBEvent;
	import com.stratoscreen.aws.SESClass;
	import com.stratoscreen.model.domains.*;
	import com.stratoscreen.model.views.*;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.SharedUtils;
	import com.stratoscreen.utils.XMLUtils;
	
	import flash.desktop.NativeApplication;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.Capabilities;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	public class AppManager extends EventDispatcher
	{		
		private var _dataManager:DataManager;
		private var _iam:IAMClass;
		private var _sdb:SDBClass;
		private var _s3:S3Class;	
		private var _ses:SESClass;	
		private var _regionId:int = 1;	// US-East
		private var _accessKey:String = "";
		private var _secretKey:String = "";		
		private var _bucket:String;
		private var _startTime:Date;
		private var _rootPath:String = null;
		private var _fileAppRoot:File;
		private var _fileDocsRoot:File;
		private var _fileData:File = null;
		private var _fileMedia:File = null;
		private var _fileMediaDownload:File = null;
		private var _fileLogs:File = null;
		private var _fileReports:File = null;
		private var _fileTemp:File = null;
		private var _parentApplication:DisplayObject;
		private var _isDesktop:Boolean = true;
		private var _appVersion:String = "";
 		private var _offline:Boolean = false;
		
		// Not used but needed to allow reuse of some of the componenents
		public var currentUser:Users;
		public var currentAccount:Accounts;
		
		[Bindable(event="offlineChange")]
		public function get offline():Boolean
		{
			return _offline;
		}

		public function set offline(value:Boolean):void
		{
			if( _offline !== value)
			{
				_offline = value;
				dispatchEvent(new Event("offlineChange"));
			}
		}

		public function get isAccelerated():Boolean
		{
			// Are we hardware accelerated?
			var xml:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = xml.namespace();
			
			var initialWindow:XML = xml.ns::initialWindow[0];
			var ns2:Namespace = initialWindow.namespace();
			
			var renderMode:String = initialWindow.ns2::renderMode[0].toString();
			renderMode = renderMode.toLowerCase();
			
			return renderMode == "direct";
		}
		
		public function get regionId():int
		{
			return _regionId;
		}
		
		public function set regionId(value:int):void
		{
			if (value != _regionId) 
			{ 
				_regionId = value;
				setAWSClasses();
			}			
		}		
		
		public function get startTime():Date
		{
			return _startTime;
		}

		public function get accountBucket():String
		{
			return _bucket.toLowerCase();
		}
		
		public function set accountBucket(value:String):void
		{
			_bucket = value;
		}
		
		public function get secretKey():String
		{
			return _secretKey;
		}

		public function set secretKey(value:String):void
		{
			if (value != _secretKey) 
			{ 
				_secretKey = value;
				setAWSClasses();
			}			
		}

		public function get accessKey():String
		{
			return _accessKey;
		}

		public function set accessKey(value:String):void
		{
			if (value != _secretKey) 
			{ 
				_accessKey = value;
				setAWSClasses();
			}				
		}
		
		public function get fileDocsRoot():File
		{
			return _fileDocsRoot;
		}
		
		public function get appversion():String
		{
			if (_appVersion == "")
			{
				// Get the version of this Player
				var xmlDoc:XMLDocument = new XMLDocument(NativeApplication.nativeApplication.applicationDescriptor);
				for each(var xmlNode:XMLNode in xmlDoc.childNodes[0].childNodes)
				{
					if (xmlNode.nodeName == "versionNumber")
					{
						if (xmlNode.childNodes.length > 0) {_appVersion = xmlNode.childNodes[0].nodeValue;}
					}					
				}												
			}
			
			return _appVersion;
		}

		public function AppManager(parentApplication:DisplayObject)
		{
			super(null);
			
			_isDesktop = Object(parentApplication).deviceType == Screens.DEVICE_PC;
			_startTime = new Date();
			_parentApplication = parentApplication;
			
			// Set the root folders. They will differ
			if (_isDesktop)
			{
				_fileAppRoot = File.applicationDirectory.resolvePath("c:/stratoscreen/");
				_fileDocsRoot = _fileAppRoot;
			}
			else
			{
				// If running as an App, use the defaults
				_fileAppRoot = File.applicationStorageDirectory;
				_fileDocsRoot = File.documentsDirectory.resolvePath(PlayerConstants.DIRECTORY_PREFIX);
				if (!_fileDocsRoot.exists) {_fileDocsRoot.createDirectory();}
			}
		}		
		
		public function get parentApplication():DisplayObject
		{
			return _parentApplication;
		}
		
		public function get iam():IAMClass
		{
			return _iam;
		}

		public function get sdb():SDBClass
		{
			return _sdb;
		}

		public function get s3():S3Class
		{
			return _s3;
		}

		public function get ses():SESClass
		{
			return _ses;	
		}
		
		private function setAWSClasses():void
		{
			var awsEndpoint:AWSEndpoint = AWSRegions.getAWSEndpoint(_regionId);
			_iam = new IAMClass(awsEndpoint.iam, _accessKey, _secretKey);
			_sdb = new SDBClass(awsEndpoint.sdb, _accessKey, _secretKey);
			_s3 = new S3Class(awsEndpoint.s3, _accessKey, _secretKey);
			_ses = new SESClass(awsEndpoint.ses, _accessKey, _secretKey);
		}
		
		public function logsFolder(value:String = ""):File
		{
			if (_fileLogs == null)
			{
				_fileLogs = _fileDocsRoot.resolvePath(PlayerConstants.DIRECTORY_LOGS);
				if (!_fileLogs.exists) {_fileLogs.createDirectory();}
			}
			
			var file:File = _fileLogs.resolvePath(value);
			return file;
		}
		
		public function dataFolder(value:String = ""):File
		{
			if (_fileData == null)
			{
				_fileData = _fileDocsRoot.resolvePath(PlayerConstants.DIRECTORY_DATA);
				if (!_fileData.exists) {_fileData.createDirectory();}
			}
			
			var file:File = _fileData.resolvePath( value);
			return file;
		}
		
		public function mediaFolder(value:String = ""):File
		{
			if (_fileMedia == null)
			{
				_fileMedia = _fileDocsRoot.resolvePath(PlayerConstants.DIRECTORY_MEDIA);
				if (!_fileMedia.exists) {_fileMedia.createDirectory();}
			}
			
			var file:File = _fileMedia.resolvePath(value);
			return file;
		}

		public function downloadMediaFolder(value:String = ""):File
		{
			if (_fileMediaDownload == null)
			{
				_fileMediaDownload = _fileDocsRoot.resolvePath(PlayerConstants.DIRECTORY_MEDIA_DOWNLOAD);
				if (!_fileMediaDownload.exists) {_fileMediaDownload.createDirectory();}
			}
			
			var file:File = _fileMediaDownload.resolvePath(value);
			return file;
		}

		
		public function reportsFolder(value:String = ""):File
		{
			if (_fileReports == null)
			{
				_fileReports = _fileDocsRoot.resolvePath(PlayerConstants.DIRECTORY_REPORTS);
				if (!_fileReports.exists) {_fileReports.createDirectory();}
			}
			
			var file:File = _fileReports.resolvePath(value);
			return file;
		}
		
		public function tempFolder(value:String = ""):File
		{
			if (_fileTemp == null)
			{
				//_fileTemp = _fileDocsRoot.resolvePath(PlayerConstants.DIRECTORY_TEMP);
				//if (!_fileTemp.exists) {_fileTemp.createDirectory();}
				
				_fileTemp = File.createTempDirectory();
			}
			
			var file:File = _fileTemp.resolvePath(value);
			return file;
		}
		
		public function get rootAppPath():String
		{
			return _fileAppRoot.nativePath + "/";
		}
		
		public function get rootDocsPath():String
		{
			return _fileDocsRoot.nativePath + "/";
		}
		
	}
}