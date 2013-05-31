package com.stratoscreen.aws
{
	import com.adobe.net.MimeTypeMap;
	import com.hurlant.crypto.hash.HMAC;
	import com.hurlant.crypto.hash.MD5;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.util.Base64;
	import com.stratoscreen.aws.AWS;
	import com.stratoscreen.aws.S3Event;
	CONFIG::isAir {import com.stratoscreen.controller.BandwidthMonitor;}
	import com.stratoscreen.model.OrderedPair;
	import com.stratoscreen.utils.DateUtils;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.Utils;
	import com.stratoscreen.utils.XMLUtils;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.formatters.DateFormatter;
	
	/**
	 * Wrapper for the AWS Simple Storage Service API. Class includes the methods commonly
	 * used by StratoScreen. 
	 * 
	 * The class utilizes the SOAP api for S3
	 *  
	 * @author P.J. Steele
	 * 
	 */
	public class S3Class extends EventDispatcher
	{	
		public static const ACL_AUTHENTICATED_READ:String = "authenticated-read";
		public static const ACL_BUCKET_OWNER_FULL_CONTROL:String = "bucket-owner-full-control";
		public static const ACL_BUCKET_OWNER_READ:String = "bucket-owner-read";
		public static const ACL_PRIVATE:String = "private";
		public static const ACL_PUBLIC_READ:String = "public-read";
		public static const ACL_PUBLIC_WRITE:String = "public-write";
		
		private static var _regionEndpoint:String;
		private static var _accessKey:String;
		private static var _secretKey:String;
		private static var _lastBytesLoaded:Number;

		private var _aws:AWS;
		private var _formatter:DateFormatter;
		private var _hmac:HMAC;
		private var _md5:MD5;
		private var _bytesSecretKey:ByteArray;
		private var _mimeMap:MimeTypeMap;
		private var _uploadCallback:Function;
		
		public function S3Class(region:String, accessKey:String, secretKey:String)
		{
			super(null);
			
			_aws = new AWS();
			_regionEndpoint = region;
			_accessKey = accessKey;
			_secretKey = secretKey;
			
			// Create the objects for the REST api
			_formatter = new DateFormatter();
			_formatter.formatString = "EEE, D MMM YYYY J:NN:SS";
			_md5 = new MD5();
			_hmac = new HMAC(new SHA1());			
			
			_bytesSecretKey = new ByteArray();
			_bytesSecretKey.writeUTFBytes(_secretKey);
		}	

		public function listAllBuckets( handler:Function):void
		{
			this.execute("GET", "/" , handler);				
		}

		public function getBucket(bucket:String, handler:Function):void
		{
			var resource:String = "/" + bucket + "/";
			this.execute("GET", resource , handler);				
		}

		public function getBucketACL(bucket:String, handler:Function):void
		{
			var resource:String = "/" + bucket + "/?acl";
			this.execute("GET", resource , handler);				
		}

		public function getFile(bucket:String, fileName:String, handler:Function):void
		{
			var resource:String = "/" + bucket + "/" + fileName;
			this.execute("GET", resource , handler);				
		}

		public function putBucket(bucket:String, handler:Function, acl:String = ACL_PRIVATE):void
		{
			var resource:String = "/" + bucket + "/";
			
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("x-amz-acl", acl));
			
			this.execute("PUT", resource , handler, pairs);				
		}

		public function deleteBucket(bucket:String, handler:Function):void
		{
			var resource:String = "/" + bucket + "/";
			this.execute("DELETE", resource , handler);				
		}
		
		public function deleteFile(bucket:String, fileName:String, handler:Function):void
		{
			var resource:String = "/" + bucket + "/" + fileName;
			this.execute("DELETE", resource , handler);				
		}		
		
		public function getFileACL(bucket:String, fileName:String, handler:Function):void
		{
			var resource:String = "/" + bucket + "/" + fileName + "?acl";
			this.execute("GET", resource , handler);							
		}

		CONFIG::isAir 
		public function putPolicy(bucket:String, file:FileReference, handler:Function):void
		{						
			_uploadCallback = handler;
			var timeStamp:String = getDateString(new Date());
			_lastBytesLoaded = 0;
			
			// Create the signature
			var hash:String = null;
			var contentType:String = "text/plain"; 
			var toSign:String = "PUT\n";
			toSign += (hash != null) ? hash + "\n" : "\n";
			toSign += (contentType != null) ? contentType + "\n" : "\n";
			toSign += timeStamp + "\n";	
			toSign +=  "/" + bucket + "/?policy";
			
			var bytesPolicy:ByteArray = new ByteArray();
			bytesPolicy.writeUTFBytes(toSign);			
			var bytesKey:ByteArray = _hmac.compute(_bytesSecretKey, bytesPolicy);			
			var signature:String = Base64.encodeByteArray(bytesKey);			
			var authorization:String = "AWS " + _accessKey + ":" + signature;
			
			var request:URLRequest = new URLRequest();
			request.url =  "https://" + _regionEndpoint + "/" + bucket + "/?policy";
			request.method = "PUT";
			request.contentType = "text/plain";
			request.requestHeaders.push(new URLRequestHeader("Date", timeStamp));
			request.requestHeaders.push(new URLRequestHeader("Authorization", authorization));
			request.requestHeaders.push(new URLRequestHeader("Content-Length", file.size.toString()));
			
			file.addEventListener(Event.COMPLETE, resultHandler);
			file.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			file.addEventListener(ProgressEvent.PROGRESS, progressUpHandler);
			file.uploadUnencoded(request);			
		}

		CONFIG::isAir 
		public function putObjectACL(bucket:String, filename:String, file:FileReference, handler:Function):void
		{						
			_uploadCallback = handler;
			var timeStamp:String = getDateString(new Date());
			_lastBytesLoaded = 0;
			
			// Create the signature
			var hash:String = null;
			var contentType:String = "text/plain"; 
			var toSign:String = "PUT\n";
			toSign += (hash != null) ? hash + "\n" : "\n";
			toSign += (contentType != null) ? contentType + "\n" : "\n";
			toSign += timeStamp + "\n";	
			toSign +=  "/" + bucket + "/" + filename + "?acl";
			
			var bytesPolicy:ByteArray = new ByteArray();
			bytesPolicy.writeUTFBytes(toSign);			
			var bytesKey:ByteArray = _hmac.compute(_bytesSecretKey, bytesPolicy);			
			var signature:String = Base64.encodeByteArray(bytesKey);			
			var authorization:String = "AWS " + _accessKey + ":" + signature;
			
			var request:URLRequest = new URLRequest();
			request.url =  "https://" + _regionEndpoint + "/" + bucket + "/" + filename + "?acl";
			request.method = "PUT";
			request.contentType = "text/plain";
			request.requestHeaders.push(new URLRequestHeader("Date", timeStamp));
			request.requestHeaders.push(new URLRequestHeader("Authorization", authorization));
			request.requestHeaders.push(new URLRequestHeader("Content-Length", file.size.toString()));
			
			file.addEventListener(Event.COMPLETE, resultHandler);
			file.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			file.addEventListener(ProgressEvent.PROGRESS, progressUpHandler);
			file.uploadUnencoded(request);			
		}

		CONFIG::isAir 
		public function uploadFile(bucket:String, file:FileReference, fileName:String, handler:Function, acl:String = ACL_PRIVATE):void
		{
			// Save the callback to an holder instead of the class. 
			// This will limit to upload one file at a time per class
			_uploadCallback = handler;
			_lastBytesLoaded = 0;

			// Determine the mime type from what we will name it on the server
			if (_mimeMap == null) { _mimeMap = new MimeTypeMap();}						
			var sections:Array = fileName.split(".");
			var contentType:String = _mimeMap.getMimeType( sections[sections.length - 1]); 
			
			var timeStamp:String = getDateString(new Date());
			
			// Create the signature
			var hash:String = null;
			var toSign:String = "PUT\n";
			toSign += (hash != null) ? hash + "\n" : "\n";
			toSign += (contentType != null) ? contentType + "\n" : "\n";
			toSign += timeStamp + "\n";	
			toSign += "x-amz-acl:" + acl + "\n";
			toSign += "/" + bucket + "/" + fileName;
						
			var bytesPolicy:ByteArray = new ByteArray();
			bytesPolicy.writeUTFBytes(toSign);			
			var bytesKey:ByteArray = _hmac.compute(_bytesSecretKey, bytesPolicy);			
			var signature:String = Base64.encodeByteArray(bytesKey);			
			var authorization:String = "AWS " + _accessKey + ":" + signature;
			
			var request:URLRequest = new URLRequest();
			request.url =  "https://" + _regionEndpoint + "/" + bucket + "/" + fileName;
			request.method = "PUT";
			request.contentType = contentType;
			request.requestHeaders.push(new URLRequestHeader("x-amz-acl",acl));
			request.requestHeaders.push(new URLRequestHeader("Date", timeStamp));
			request.requestHeaders.push(new URLRequestHeader("Authorization", authorization));
			request.requestHeaders.push(new URLRequestHeader("Content-Length", file.size.toString()));

			file.addEventListener(Event.COMPLETE, resultHandler);
			file.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			file.addEventListener(ProgressEvent.PROGRESS, progressUpHandler);
			file.uploadUnencoded(request);
		}
		
		public function copyFile(fromBucket:String, fromFile:String, toBucket:String, toFile:String, handler:Function, acl:String = ACL_PRIVATE):void
		{
			var resource:String = "/" + toBucket + "/" + toFile;
			_lastBytesLoaded = 0;
			
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("x-amz-acl", acl));
			pairs.push(new OrderedPair("x-amz-copy-source",  "/" + fromBucket + "/" + fromFile));
			
			this.execute("PUT", resource , handler, pairs);				
		}
		
		public function getSelectURL(bucket:String, key:String ):String
		{
			// Get the time that keeps this URL active. 5 Minutes is plenty
			var expire:String = getExpireString();
			
			// Create the signature for the request
			var resource:String = "/" + bucket + "/" + key;			
			var signature:String = getGetSignature(expire, resource);
			
			// Assemble the URL
			var url:String = "https://" + _regionEndpoint + resource;
			var startToken:String = resource.indexOf("?") >=0 ? "&" : "?";	// Watch for resources with a "?"
			url += startToken + "AWSAccessKeyId=" + _accessKey;
			url += "&Expires=" + expire;
			url += "&Signature=" +  Utils.urlEncode(signature);

			return url;
		}
				
		private function execute(verb:String, resource:String, callback:Function, pairs:Array = null, hash:String = null, contentType:String = null):void
		{
			var timeStamp:String = getDateString(new Date());
		
			// Watch for addition x-amz headers
			var sortedPairs:ArrayCollection = null;
			if (pairs != null) { sortedPairs = _aws.getSortedPairs(pairs)}
			
			// Create the signature
			var toSign:String = verb + "\n";
			toSign += (hash != null) ? hash + "\n" : "\n";
			toSign += (contentType != null) ? contentType + "\n" : "\n";
			toSign += timeStamp + "\n";
			
			// Watch for additional AWS Headers. Assume this is sorted
			if (sortedPairs != null)
			{
				for each (var orderedPair:OrderedPair in sortedPairs)
				{
					toSign += orderedPair.name + ":" + orderedPair.value + "\n";		
				}				
			}
			toSign += resource;
			
			var bytesPolicy:ByteArray = new ByteArray();
			bytesPolicy.writeUTFBytes(toSign);			
			var bytesKey:ByteArray = _hmac.compute(_bytesSecretKey, bytesPolicy);			
			var signature:String = Base64.encodeByteArray(bytesKey);			
			var authorization:String = "AWS " + _accessKey + ":" + signature;
			
			// Create the request to AWS
			var request:URLRequest = new URLRequest();
			request.url = "https://" + _regionEndpoint + resource;
			request.method = verb;

			if (sortedPairs != null)
			{
				for each (orderedPair in sortedPairs)
				{
					request.requestHeaders.push(new URLRequestHeader(orderedPair.name, orderedPair.value));		
				}				
			}
			
			request.requestHeaders.push(new URLRequestHeader("Date", timeStamp));
			request.requestHeaders.push(new URLRequestHeader("Authorization", authorization));
						
			// Use the AWSLoader so we can return to the parent handler
			var loader:AWSURLLoader = new AWSURLLoader();
			loader.action = resource;
			loader.callback = callback;
			loader.addEventListener(Event.COMPLETE, resultHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			loader.load(request);											
		}
		
		private function resultHandler(event:Event):void
		{			
			event.target.removeEventListener(Event.COMPLETE, resultHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			event.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			event.target.removeEventListener(ProgressEvent.PROGRESS, progressUpHandler);

			var s3Event:S3Event = new S3Event();
			s3Event.result = event.target.data;
			s3Event.success = true;
			
			// Assume the targets are overridden classes with the callback property
			if (event.target is AWSURLLoader)
			{
				event.target.callback(s3Event);				
			}
			else
			{				
				_uploadCallback(s3Event);	// Assume this is set
			}
		}
				
		private function errorHandler(event:Event):void
		{
			event.target.removeEventListener(Event.COMPLETE, resultHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			event.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			event.target.removeEventListener(ProgressEvent.PROGRESS, progressUpHandler);
			
			var s3Event:S3Event= new S3Event();
			s3Event.success = false;
			
			// Add the message if we can. Ignore the Signature Messages
			try
			{
				var result:Object = XMLUtils.stringToObject(event.target.data.toString());
				
				var code:String;
				var message:String;
				
				// Parse the error the best we can
				if (result.ErrorResponse != null)
				{
					if (result.ErrorResponse.Error is Array)
					{
						code = result.ErrorResponse.Error[0].Code;
						message = result.ErrorResponse.Error[0].Message;
					}
					else
					{
						code = result.ErrorResponse.Error.Code;
						message = result.ErrorResponse.Error.Message;
					}
				}
				else if (result.Error != null) 
				{
					code = result.Error.Code;
					message = result.Error.Message;
				}
				else
				{
					trace("Unexpected Error response.....");
				}
								
				
				if (code != "SignatureDoesNotMatch")
				{
					s3Event.message = message;
				}						
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err, 2, LogUtils.WARN);
			}
						
			// Assume the targets are overridden classes with the callback property
			if (event.target is AWSURLLoader)
			{
				event.target.callback(s3Event);				
			}
			else
			{
				_uploadCallback(s3Event);	// Assume this is set
			}
		}

		private function progressUpHandler(event:ProgressEvent):void
		{
			try
			{
				CONFIG::isAir 
				{
					var bytesLength:Number = _lastBytesLoaded == 0 ? event.bytesLoaded : event.bytesLoaded - _lastBytesLoaded;
					_lastBytesLoaded = event.bytesLoaded;

					
					BandwidthMonitor.uploaded(bytesLength, event.target.action);
				}
			}
			catch (err:Error)
			{
				trace(err.message);
			}
			
			this.dispatchEvent(event);
		}
		
		private function getDateString(dateTime:Date):String
		{
			var date:Date = new Date(dateTime.getUTCFullYear(), dateTime.getUTCMonth(), dateTime.getUTCDate(), 
				                   dateTime.getUTCHours(), dateTime.getUTCMinutes(), dateTime.getUTCSeconds(), 
								   dateTime.getUTCMilliseconds());
			var dateString:String =_formatter.format(date);
			return dateString + " GMT";
		}
		
		private function getGetSignature(expire:String, resource:String, contentType:String = null, hash:String = null):String
		{
			var toSign:String = "GET\n";
			toSign += (hash != null) ? hash + "\n" : "\n";
			toSign += (contentType != null) ? contentType + "\n" : "\n";
			toSign += expire + "\n";	
			toSign += resource;
			
			var bytesPolicy:ByteArray = new ByteArray();
			bytesPolicy.writeUTFBytes(toSign);			
			var bytesKey:ByteArray = _hmac.compute(_bytesSecretKey, bytesPolicy);
			
			return Base64.encodeByteArray(bytesKey);			
		}
		
		private function getExpireString(minutes:int = 5):String
		{
			var expire:Date = new Date();
			expire.milliseconds = 0;	// We are going to chopp these off any
			expire.time += 60000 * minutes;
			
			var expireGMT:Date = new Date(expire.getUTCFullYear(), expire.getUTCMonth(), expire.getUTCDate(), 
				expire.getUTCHours(), expire.getUTCMinutes(), 
				expire.getUTCSeconds(), expire.getUTCMilliseconds());
			
			var expireNum:Number = expireGMT.time / 1000;	// Remove the milliseconds
			
			return int(expireNum).toString();			
		}	
	}
}