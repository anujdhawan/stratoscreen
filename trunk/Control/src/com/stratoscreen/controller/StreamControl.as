package com.stratoscreen.controller
{
	import com.stratoscreen.aws.AWSEndpoint;
	import com.stratoscreen.aws.AWSRegions;
	import com.stratoscreen.aws.CFEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.model.domains.Accounts;
	import com.stratoscreen.resources.CloudFrontOriginAccessIdentityConfig;
	import com.stratoscreen.resources.StreamingDistributionConfig;
	import com.stratoscreen.utils.GUID;
	import com.stratoscreen.utils.XMLUtils;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	public class StreamControl
	{
		private var _appManager:AppManager;
		private var _callback:Function
		private var _success:Boolean;
		private var _lastMessage:String;
		private var _xmlFile:File;
		private var _cfId:String;
		private var _cfStatus:String;
		private var _cfDomain:String;
		private var _cfEnabled:Boolean;
		private var _cfOriginId:String;
		private var _cfS3Id:String;

		public function get success():Boolean
		{
			return _success;
		}
		
		public function get lastMesage():String
		{
			return _lastMessage;
		}
		
		public function get cfId():String
		{
			return _cfId;
		}
		
		public function get cfStatus():String
		{
			return _cfStatus;
		}
		
		public function get cfDomain():String
		{
			return _cfDomain;
		}
		
		public function get cfEnabled():Boolean
		{
			return _cfEnabled;
		}

		public function get cfOriginId():String
		{
			return _cfOriginId;
		}

		public function get cfS3Id():String
		{
			return _cfS3Id;
		}

		public function StreamControl(appManager:AppManager)
		{
			_appManager = appManager;
		}
				
		public function createStreamingDistribution(account:Accounts, callback:Function):void
		{
			_callback = callback;
			
			// Assemble the values to be used
			var endpoint:AWSEndpoint = AWSRegions.getAWSEndpoint(_appManager.regionId);
			var dnsName:String = account.bucket;
			dnsName += "." + endpoint.s3;
			
			// Create an XML file for the configuration
			var patternDns:RegExp = /\@@DNSNAME@@/gi;	
			var patternRef:RegExp = /\@@REF@@/gi;
			var patternComment:RegExp = /\@@COMMENT@@/gi;
			var patternOrgin:RegExp = /\@@ORGINID@@/gi;
			
			var xml:String = (new StreamingDistributionConfig()).toString();
			xml = xml.replace(patternDns, dnsName);
			xml = xml.replace(patternRef, GUID.create());
			xml = xml.replace(patternComment, account.name);
			xml = xml.replace(patternOrgin, _appManager.settings.originAccessIdentity);
			createTempXML(xml);
			
			// Start the config
			_appManager.cf.createStreamingDistributions(_xmlFile, createDistributionHandler);
		}
		
		private function createTempXML(xml:String):void
		{
			_xmlFile = File.createTempFile();
			var stream:FileStream = new FileStream();
			stream.open(_xmlFile, FileMode.WRITE);
			stream.writeUTFBytes(xml);
			stream.close();			
		}
		
		private function createDistributionHandler(event:CFEvent):void
		{
			try
			{
				_success = event.success;
				_lastMessage = event.message;
				_xmlFile.deleteFile();
				
				if (event.success)
				{
					var result:Object = XMLUtils.stringToObject(event.result.toString());
					_cfId = result.StreamingDistribution.Id;
					_cfStatus = result.StreamingDistribution.Status;
					_cfDomain = result.StreamingDistribution.DomainName;
					_cfEnabled = result.StreamingDistribution.StreamingDistributionConfig.Enabled == "true";
				}
			}
			finally
			{			
				_callback();
			}
		}
		
		public function configure(callback:Function):void
		{
			_callback = callback;
			
			// We have several steps to perform before we are ready to stream privately
			//
			// First create the Origin Access Key
			var patternRef:RegExp = /\@@REF@@/gi;
			var patternComment:RegExp = /\@@COMMENT@@/gi;
			
			var xml:String = (new CloudFrontOriginAccessIdentityConfig()).toString();
			xml = xml.replace(patternRef, GUID.create());
			xml = xml.replace(patternComment, "StratoScreen config " + (new Date()).toUTCString());
			createTempXML(xml);
			
			_appManager.cf.createOrginAccessIdentity(_xmlFile, configureHandler);
		}

		private function configureHandler(event:CFEvent):void
		{
			try
			{
				_success = event.success;
				_lastMessage = event.message;
				_xmlFile.deleteFile();
				
				if (event.success)
				{
					var result:Object = XMLUtils.stringToObject(event.result.toString());
					_cfOriginId = result.CloudFrontOriginAccessIdentity.Id;	
					_cfS3Id = result.CloudFrontOriginAccessIdentity.S3CanonicalUserId;
				}
			}
			catch (err:Error)
			{
				_success = false;
				_lastMessage = err.message
			}
			finally
			{			
				_callback();
			}
		}

		
		public function getDistributionStatus(id:String, callback:Function):void
		{
			_callback = callback;
			
			_appManager.cf.getStreamingDistribution(id, getDistributionStatusHandler);			
		}
		
		private function getDistributionStatusHandler(event:CFEvent):void
		{
			try
			{
				_success = event.success;
				_lastMessage = event.message;
				
				if (event.success)
				{
					var result:Object = XMLUtils.stringToObject(event.result.toString());
					_cfId = result.StreamingDistribution.Id;
					_cfStatus = result.StreamingDistribution.Status;
					_cfDomain = result.StreamingDistribution.DomainName;
					_cfEnabled = result.StreamingDistribution.StreamingDistributionConfig.Enabled.toString() == "true";
				}
			}
			finally
			{			
				_callback();
			}			
				
		}
	}
}