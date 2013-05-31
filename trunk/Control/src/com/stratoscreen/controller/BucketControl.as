package com.stratoscreen.controller
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.aws.S3Class;
	import com.stratoscreen.aws.S3Event;
	import com.stratoscreen.events.InstallEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.model.InstallStep;
	import com.stratoscreen.model.domains.Identities;
	import com.stratoscreen.resources.CrossDomainEmbed;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.SecurityUtils;
	import com.stratoscreen.utils.Utils;
	import com.stratoscreen.utils.XMLUtils;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.utils.StringUtil;	
	
	public class BucketControl extends EventDispatcher
	{
		private var _appManager:AppManager;
		private var _bucket:String;
		private var _buckets:Array;
		private var _contents:Array;
		private var _callback:Function;
		private var _crossDomain:File
		private var _marker:File;
		private var _signon:File;
		private var _success:Boolean = true;	// Hope for the best
		private var _lastErrMessage:String;
		private var _index:int;
		private var _contentIndex:int;
		private var _installEvent:InstallEvent;
		private var _identities:Array
		private var _policiesXml:XML = null;
		
		public function BucketControl(appManager:AppManager)
		{
			_appManager = appManager;
			
			// Set up the security encryption keys
			SecurityUtils.globalCode = Constants.KEY_PREFIX + _appManager.settings.accountId;
			SecurityUtils.regionalCode = _appManager.settings.regionId;		
			SecurityUtils.installCode = _appManager.settings.bucketWeb;			
			super(null);
		}
		
		public function success():Boolean
		{
			return _success;
		}
		
		/**
		 * Upload the base files for every bucket.  
		 *   
		 * @param bucket
		 * @param callback
		 * 
		 */
		public function configure(bucket:String, callback:Function):void
		{
			_bucket = bucket;
			_callback = callback;
			
			// Create temporary files for configuring the bucket
			_crossDomain = File.createTempFile();
			var stream:FileStream = new FileStream();
			stream.open(_crossDomain, FileMode.WRITE);
			stream.writeUTFBytes(new CrossDomainEmbed().toString());
			stream.close();
			
			// Upload the file
			_appManager.s3.uploadFile(bucket, _crossDomain, "crossdomain.xml", crossDomainUploadHandler, S3Class.ACL_PUBLIC_READ);
		}
		
		public function createSignonFile(regionId:int, accountBucket:String, webBucket:String, identity:Identities, accountId:String, callback:Function):void
		{
			_callback = callback;
			var DELIMETER:String = "\t";

			SecurityUtils.installCode = webBucket;
			SecurityUtils.accountCode = accountBucket;
			
			// Create the rows of the packages
			var pkg:String = regionId.toString() + DELIMETER;
			pkg += identity.accessKey + DELIMETER;
			pkg += identity.secretKey + DELIMETER;
			pkg += SecurityUtils.simpleEncrypt(accountId, SecurityUtils.ACCOUNT_KEY) + DELIMETER;
			pkg += SecurityUtils.simpleEncrypt(webBucket, SecurityUtils.ACCOUNT_KEY);
			pkg = SecurityUtils.simpleEncrypt(pkg, SecurityUtils.ACCOUNT_KEY); 
			
			// Re-encrypt with the common key. 
			// I hope this is all worth it!     
			_signon = File.createTempFile();
			var stream:FileStream = new FileStream();
			stream.open(_signon, FileMode.WRITE);
			stream.writeUTFBytes(pkg);
			stream.close();
			
			// Upload the file
			_appManager.s3.uploadFile(accountBucket, _signon, accountBucket, signonUploadHandler, S3Class.ACL_PUBLIC_READ);			
		}
		
		public function deleteBuckets(buckets:Array, callback:Function):void
		{
			_buckets = buckets;
			_callback = callback;
			_success = false;
			_index = -1;	// Start at Zero
			
			deleteNextBucket();
		}
		
		private function deleteNextBucket(event:Object = null):void
		{
			try
			{
				_index++;
				if (_index > _buckets.length) 
				{
					_success = true;
					_callback(new InstallEvent(InstallEvent.INFO, "Buckets deleted", _success));
					return;
				}

				// We are missing the bucket or there was a failed uninstall
				if (_buckets[_index] == "") 
				{
					LogUtils.writeToLog("Missing Media Bucket. Account may not delete properly", LogUtils.WARN);
					deleteNextBucket();
					return;
				}
					
				// Check for a marker in the file. If it is there delete the bucket
				{
					_appManager.s3.getFile(_buckets[_index], Constants.BUCKET_MARKER, getMarkerHandler);
				}
			}
			catch (err:Error)
			{
				_success = false;
				_lastErrMessage = err.message;
				LogUtils.writeErrorToLog(err);
				_callback(new InstallEvent(InstallEvent.ERROR, err.message, _success));
			}			
		}
		
		private function getMarkerHandler(event:S3Event):void
		{
			try
			{
							
				if (event.success)
				{
					_appManager.s3.getBucket(_buckets[_index], getBucketHandler);
				}
				else
				{
					// If we did not find the marker then skip this file
					deleteNextBucket();
				}
			}
			catch (err:Error)
			{
				_success = false;
				_lastErrMessage = err.message;
				LogUtils.writeErrorToLog(err);
				_callback(new InstallEvent(InstallEvent.ERROR, err.message, _success));
			}				
		}
		
		private function getBucketHandler(event:S3Event):void
		{
			try
			{
				var result:Object = XMLUtils.stringToObject(event.result.toString());
								
				// Save the list files so we can delete				
				if (result.ListBucketResult.Contents is Array)
				{
					_contents = result.ListBucketResult.Contents;
				}
				else
				{
					_contents = new Array();
					_contents.push(result.ListBucketResult.Contents);
				}
				
				_contentIndex = -1;
				deleteNextFile();
				
			}
			catch (err:Error)
			{
				// If we fail move to the next bucket and continue
				_success = false;
				_lastErrMessage = err.message;
				LogUtils.writeErrorToLog(err);
				deleteNextBucket();
			}
		}
		
		private function crossDomainUploadHandler(event:S3Event):void
		{
			// Make sure we uploaded correctly
			if (!event.success)
			{
				_callback(event);
				return;					
			}

			// Clean up old work files
			try
			{
				_crossDomain.deleteFile();
			}
			catch (err:Error)
			{
				_success = false;
				_lastErrMessage = err.message;
				LogUtils.writeErrorToLog(err);
			}

			// Create a marker in the bucket. This will help with identification
			// Add the Main Account web bucket so the sub accounts can find the web bucket
			_marker = File.createTempFile();
			var stream:FileStream = new FileStream();
			stream.open(_marker, FileMode.WRITE);
			stream.writeUTFBytes("");	
			stream.close();
			
			// Upload the marker
			_appManager.s3.uploadFile(_bucket, _marker, Constants.BUCKET_MARKER, markerUploadHandler);					
		}
		
		private function markerUploadHandler(event:S3Event):void
		{
			// Clean up old work files
			try
			{
				_marker.deleteFile();
			}
			catch (err:Error)
			{
				_success = false;
				_lastErrMessage = err.message;
				LogUtils.writeErrorToLog(err);
			}

			_callback(event);
		}
		
		private function signonUploadHandler(event:S3Event):void
		{
			// Clean up old work files
			try
			{
				_signon.deleteFile();
			}
			catch (err:Error)
			{
				_success = false;
				_lastErrMessage = err.message;
				LogUtils.writeErrorToLog(err);
			}
			
			_callback(event);
		}		
		
		private function deleteNextFile(event:S3Event = null):void
		{
			// Ignore the result. If oit fails move to the next content file
			_contentIndex ++;
			if (_contentIndex >= _contents.length) 
			{
				_appManager.s3.deleteBucket(_buckets[_index], deleteNextBucket);
				return;
			}
			
			_appManager.s3.deleteFile(_buckets[_index], _contents[_contentIndex].Key, deleteNextFile);
		}

	}
}