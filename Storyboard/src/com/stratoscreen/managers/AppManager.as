package com.stratoscreen.managers
{
	import com.hurlant.util.der.Set;
	import com.stratoscreen.aws.AWSEndpoint;
	import com.stratoscreen.aws.AWSRegions;
	import com.stratoscreen.aws.CFClass;
	import com.stratoscreen.aws.IAMClass;
	import com.stratoscreen.aws.S3Class;
	import com.stratoscreen.aws.SDBClass;
	import com.stratoscreen.aws.SESClass;
	import com.stratoscreen.components.S3SWFLoader;
	import com.stratoscreen.model.domains.Accounts;
	import com.stratoscreen.model.domains.Medias;
	import com.stratoscreen.model.domains.Settings;
	import com.stratoscreen.model.domains.Users;
	import com.stratoscreen.model.views.*;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	import flash.system.Capabilities;

	[Event(name="APP_RESIZE", type="com.stratoscreen.managers.AppManager")]
	[Event(name="OVERLAY_EDIT_SCALE_CHANGE", type="com.stratoscreen.managers.AppManager")]
	public class AppManager extends EventDispatcher
	{		
		public static const APP_RESIZE:String = "APP_RESIZE";
		public static const OVERLAY_EDIT_SCALE_CHANGE:String = "OVERLAY_EDIT_SCALE_CHANGE";
		
		private static const NEWS_URL:String = "http://apps.stratoscreen.com/storyboard/news/index.htm";
		private static const PROVIDERS_URL:String = "http://apps.stratoscreen.com/storyboard/config/providers.xml";
		private static const VERSION_URL:String = "http://apps.stratoscreen.com/install/version.txt";

		//private static const PROVIDERS_URL:String = "http://stratoapps.s3.amazonaws.com/storyboard/config/providers.xml";

		private var _storyboard:Object;	// Keep a reference to the main application
		private var _iam:IAMClass;
		private var _cf:CFClass;
		private var _sdb:SDBClass;
		private var _s3:S3Class;	
		private var _ses:SESClass;	
		private var _regionId:int = 1;	// US-East
		private var _accessKey:String = "";
		private var _secretKey:String = "";		
		private var _webBucket:String;
		private var _appName:String;
		private var _appVersion:String;
		private var _localKey:String;
		private var _currentAccount:Accounts;
		private var _overlayEditScale:Number = 1;

		public var usersHdrs:Array;
		public var currentUser:Users;
		public var medias:Array;
		public var currentEditWindow:DisplayObject;
		public var currentScreenCount:int;
		public var currentMediasCount:int;
		public var currentMediasSize:Number;
		public var settings:Settings;
		
		public function get newsUrl():String
		{
			return NEWS_URL;
		}
		
		public function get providersUrl():String
		{
			return PROVIDERS_URL;
		}

		public function get versionUrl():String
		{
			return VERSION_URL;
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
		
		public function get appName():String
		{
			return _appName;
		}
		
		public function get appVersion():String
		{
			return _appVersion;
		}
		
		public function get accountBucket():String
		{
			return _webBucket;
		}
		
		public function setWebBucket(value:String):void
		{
			_webBucket = value;
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
		
		public function get localKey():String
		{
			// Create a key for storing data locally
			// Try and keey it unique per machone
			if (_localKey == null)
			{
				_localKey = File.userDirectory.name;
				_localKey += Capabilities.screenResolutionX.toString();
				
				_localKey = _localKey.toLowerCase();
				_localKey = _localKey.replace(new RegExp(/\s/gi), "");	
				_localKey = _localKey.replace(new RegExp(/\\/gi), "");		
			}
			
			return _localKey;
		}

		public function get currentAccount():Accounts
		{
			return _currentAccount;
		}
		
		public function set currentAccount(value:Accounts):void
		{
			// Update the SWF loadeer too
			// It needs to no what parms to display
			S3SWFLoader.account = value;
			
			_currentAccount = value;
		}

		public function AppManager(parentApp:Object, appName:String, appVersion:String,  bucket:String)
		{
			_storyboard = parentApp;	
			_appName = appName;
			_appVersion = appVersion;
			_webBucket = bucket;			
			
			usersHdrs = new Array();
			super(null);
		}
		
		public function get storyboard():Object
		{
			return _storyboard;
		}
		
		public function get cf():CFClass
		{
			return _cf;
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
						
		/**
		 * Not used, but added to allow reuse of components between the player and storyboard
		 *  
		 * @param value
		 * @return null 
		 * 
		 */
		public function mediaFolder(value:String = ""):Object
		{
			return null;
		}
		
		public function sendResizeEvent():void
		{
			this.dispatchEvent(new Event(APP_RESIZE));
		}
		
		public function get overlayEditScale():Number
		{
			return _overlayEditScale;
		}
		
		public function set overlayEditScale(value:Number):void
		{
			_overlayEditScale = value;
			this.dispatchEvent(new Event(OVERLAY_EDIT_SCALE_CHANGE));
		}
		
		public function getMedia(id:String):Medias
		{
			for each(var media:Medias in this.medias)
			{
				if (media.itemName == id) {return media;}
			}
			
			return null;
		}
		
		private function setAWSClasses():void
		{
			var awsEndpoint:AWSEndpoint = AWSRegions.getAWSEndpoint(_regionId);
			_cf = new CFClass(awsEndpoint.cf, _accessKey, _secretKey);
			_iam = new IAMClass(awsEndpoint.iam, _accessKey, _secretKey);
			_sdb = new SDBClass(awsEndpoint.sdb, _accessKey, _secretKey);
			_s3 = new S3Class(awsEndpoint.s3, _accessKey, _secretKey);
			_ses = new SESClass(awsEndpoint.ses, _accessKey, _secretKey);
		}
	}
}