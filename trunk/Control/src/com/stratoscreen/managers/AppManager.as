package com.stratoscreen.managers
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.aws.*;
	import com.stratoscreen.model.domains.Settings;
	import com.stratoscreen.utils.SecurityUtils;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class AppManager extends EventDispatcher
	{		
		private var _settings:Settings = null;
		
		private var _controlPanel:ControlPanel;	// Keep a reference to the main application
		private var _cf:CFClass;
		private var _iam:IAMClass;
		private var _sdb:SDBClass;
		private var _s3:S3Class;	
		private var _ses:SESClass;
		//private var _sns:SNSClass;
		private var _accessKey:String = "";
		private var _secretKey:String = "";
		
		public function get settings():Settings
		{
			return _settings;
		}

		public function set settings(value:Settings):void
		{
			_settings = value;
			SecurityUtils.installCode = _settings.bucketWeb;
		}

		public function get accountBucket():String
		{
			if (settings == null) {return "";}
			return settings.bucketWeb;
		}

		public function set accountBucket(value:String):void
		{
			SecurityUtils.installCode = value;
			if (settings == null) {this.settings = new Settings();}
			settings.bucketWeb = value;
		}

		public function get awsAccount():String
		{
			if (settings == null) {return "";}
			
			return settings.accountId;
		}

		public function set awsAccount(value:String):void
		{
			SecurityUtils.globalCode = Constants.KEY_PREFIX + value;
			if (settings == null) {this.settings = new Settings();}
			settings.accountId = value;
		}
		
		public function get regionId():int
		{
			if (settings == null) {return 1;}			
			return parseInt(settings.regionId);
		}
		

		public function set regionId(value:int):void
		{
			SecurityUtils.regionalCode = value.toString();
				
			if (settings == null) {this.settings = new Settings();}
			
			if (value != parseInt(settings.regionId)) 
			{
				settings.regionId = value.toString();
				setAWSClasses();
			}			
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

		public function AppManager(parentApp:ControlPanel)
		{
			_controlPanel = parentApp;						
			super(null);
		}
		
		public function get controlPanel():ControlPanel
		{
			return _controlPanel;
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
		
		/*
		public function get sns():SNSClass
		{
			return _sns;
		}		
		*/
		
		private function setAWSClasses():void
		{
			if (settings == null) {this.settings = new Settings();}			
			var regionId:int = parseInt(this.settings.regionId)
			var awsEndpoint:AWSEndpoint = AWSRegions.getAWSEndpoint(regionId);
			_cf = new CFClass(awsEndpoint.cf, _accessKey, _secretKey);
			_iam = new IAMClass(awsEndpoint.iam, _accessKey, _secretKey);
			_sdb = new SDBClass(awsEndpoint.sdb, _accessKey, _secretKey);
			_s3 = new S3Class(awsEndpoint.s3, _accessKey, _secretKey);
			_ses = new SESClass(awsEndpoint.ses, _accessKey, _secretKey);
			//_sns = new SNSClass(awsEndpoint.sns, _accessKey, _secretKey);
		}
	}
}