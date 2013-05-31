package com.stratoscreen.aws
{
	import com.hurlant.crypto.hash.HMAC;
	import com.hurlant.crypto.hash.MD5;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.crypto.hash.SHA256;
	import com.hurlant.crypto.rsa.RSAKey;
	import com.hurlant.util.Base64;
	import com.hurlant.util.Hex;
	import com.hurlant.util.der.PEM;
	import com.stratoscreen.aws.AWS;
	import com.stratoscreen.model.OrderedPair;
	import com.stratoscreen.utils.*;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	CONFIG::isAir {import flash.filesystem.File;}
	import flash.net.FileReference;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.formatters.DateFormatter;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	public class CFClass extends EventDispatcher
	{
		private static const SIGNATURE_METHOD:String = "HmacSHA256";
		private static const SIGNATURE_VERSION:String = "2";
		private static const VERSION:String = "2010-11-01";

		private var _aws:AWS;
		private var _regionEndpoint:String;
		private var _accessKey:String;
		private var _secretKey:String;	
		private var _formatter:DateFormatter;
		private var _hmac:HMAC;
		private var _md5:MD5;
		private var _bytesSecretKey:ByteArray;
		private var _uploadCallback:Function;
		
		public function CFClass(region:String, accessKey:String, secretKey:String)
		{
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
			
			super(null);
		}
		
		public function listDistributionsList(callback:Function):void
		{
			this.execute("GET", "/" + VERSION + "/distribution", callback);			
		} 

		public function listStreamingDistributionsList(callback:Function):void
		{
			this.execute("GET", "/" + VERSION + "/streaming-distribution", callback);			
		}
		
		public function getStreamingDistribution(id:String, callback:Function):void
		{
			this.execute("GET", "/" + VERSION + "/streaming-distribution/" + id, callback);
		}
		
		CONFIG::isAir 
		public function createStreamingDistributions(config:FileReference, callback:Function):void
		{		
			postConfigFile(config, "/streaming-distribution", callback);
		}
		
		CONFIG::isAir 
		public function createOrginAccessIdentity(config:FileReference, callback:Function):void
		{
			postConfigFile(config, "/origin-access-identity/cloudfront", callback);
		}
		
		CONFIG::isAir 
		private function postConfigFile(config:FileReference, context:String, callback:Function):void
		{
			_uploadCallback = callback;
			
			var timeStamp:String = getDateString(new Date());			
			var bytesPolicy:ByteArray = new ByteArray();
			bytesPolicy.writeUTFBytes(timeStamp);
			var bytesKey:ByteArray = _hmac.compute(_bytesSecretKey, bytesPolicy);			
			var signature:String = Base64.encodeByteArray(bytesKey);			
			var authorization:String = "AWS " + _accessKey + ":" + signature;
			
			var request:URLRequest = new URLRequest();
			request.url =  "https://" + _regionEndpoint + "/" + VERSION + context;
			request.method = "POST";
			request.contentType = "text/plain";
			request.requestHeaders.push(new URLRequestHeader("Date", timeStamp));
			request.requestHeaders.push(new URLRequestHeader("Authorization", authorization));
			request.requestHeaders.push(new URLRequestHeader("Content-Length", config.size.toString()));
			
			config.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, uploadCompleHandler);
			config.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			config.uploadUnencoded(request);	
		}
		
		public function createPrivateUrl(domain:String, filename:String, mimeType:String, keyPair:String, keyPairId:String):String
		{
			//	Give a plus two day window to play the streeam
			var startDate:String = getExpireString(-24*60);
			var expireDate:String = getExpireString(24*60);
			var baseUrl:String = "rtmp://" + domain + "/" + filename;
			var policy:String = createPolicy(baseUrl, startDate, expireDate);
			
			var bytesSigned:ByteArray = new ByteArray();
			var bytesPolicy:ByteArray = Hex.toArray(Hex.fromString(policy));
							
			var rsaKey:RSAKey = PEM.readRSAPrivateKey(keyPair);
			rsaKey.sign(bytesPolicy, bytesSigned, bytesPolicy.length);
		
			// clean up the signature so it is safe for URLs
			var signature:String = Base64.encodeByteArray(bytesSigned);
			signature = signature.replace("+", "-");
			signature = signature.replace(new RegExp(/\+/gi), "-");
			signature = signature.replace(new RegExp(/\=/gi), "_");
			signature = signature.replace(new RegExp(/\//gi), "~");		
			
			// depending on the video type we want to change the URL
			var prefix:String = "";
			switch (mimeType)
			{
				case "video/quicktime":
				case "video/mp4":
					prefix = "mp4:";
					break;
				case "video/x-flv":
					prefix = "flv:";
					break;					
			}
				
			
			var url:String = "rtmp://" + domain + "/cfx/st/" + prefix + filename;
			url += "?Expires=" + escape(expireDate) + "&Signature=" + signature + 
				   "&Key-Pair-Id=" + escape(keyPairId);
			
			return url;
		}

		private function execute(verb:String, resource:String, callback:Function, pairs:Array = null):void
		{
			// Watch for addition x-amz headers
			var sortedPairs:ArrayCollection = null;
			if (pairs != null) { sortedPairs = _aws.getSortedPairs(pairs)}

			var timeStamp:String = getDateString(new Date());			
			var bytesPolicy:ByteArray = new ByteArray();
			bytesPolicy.writeUTFBytes(timeStamp);
			var bytesKey:ByteArray = _hmac.compute(_bytesSecretKey, bytesPolicy);			
			var signature:String = Base64.encodeByteArray(bytesKey);			
			var authorization:String = "AWS " + _accessKey + ":" + signature;
			
			// Create the request to AWS
			var request:URLRequest = new URLRequest();
			request.url = "https://" + _regionEndpoint + resource;
			//request.contentType = contentType;
			request.method = verb;
			
			if (sortedPairs != null)
			{
				for each (var orderedPair:OrderedPair in sortedPairs)
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
			var cfEvent:CFEvent= new CFEvent();
			cfEvent.result = event.target.data;
			cfEvent.success = true;
			
			event.target.removeEventListener(Event.COMPLETE, resultHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			event.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);

			// Assume the targets are overridden classes with the callback property
			if (event.target is AWSURLLoader)
			{
				event.target.callback(cfEvent);				
			}
			else
			{				
				_uploadCallback(cfEvent);	// Assume this is set
			}
		}		
		
		private function uploadCompleHandler(event:DataEvent):void
		{
			var cfEvent:CFEvent= new CFEvent();
			cfEvent.result = event.data;
			cfEvent.success = true;
			
			event.target.removeEventListener(Event.COMPLETE, resultHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			event.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
						
			// Assume the targets are overridden classes with the callback property
			if (event.target is AWSURLLoader)
			{
				event.target.callback(cfEvent);				
			}
			else
			{				
				_uploadCallback(cfEvent);	// Assume this is set
			}	
		}
		
		private function errorHandler(event:Event):void
		{
			var cfEvent:CFEvent = new CFEvent();
			cfEvent.success = false;
			
			event.target.removeEventListener(Event.COMPLETE, resultHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			event.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			
			// Add the message if we can. Ignore the Signature Messages
			try
			{
				var result:Object = XMLUtils.stringToObject(event.target.data.toString());

				var code:String;
				var message:String;
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
				
				if (code != "SignatureDoesNotMatch")
				{
					cfEvent.message = message;
				}						
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err, 2, LogUtils.WARN);
			}
			
			
			event.target.callback(cfEvent);
		}		

		private function getDateString(dateTime:Date):String
		{
			var date:Date = new Date(dateTime.getUTCFullYear(), dateTime.getUTCMonth(), dateTime.getUTCDate(), 
				dateTime.getUTCHours(), dateTime.getUTCMinutes(), dateTime.getUTCSeconds(), 
				dateTime.getUTCMilliseconds());
			var dateString:String =_formatter.format(date);
			return dateString + " GMT";
		}
		
		private function generateSignature(date:String):String
		{
			// Create the bytes array from the strings to encrypt
			var bytesPolicy:ByteArray = new ByteArray();
			bytesPolicy.writeUTFBytes(date);
			
			var bytesSecret:ByteArray = new ByteArray();
			bytesSecret.writeUTFBytes(_secretKey);
			
			var hmac:HMAC = new HMAC(new SHA256());
			
			return Base64.encodeByteArray(hmac.compute(bytesSecret, bytesPolicy));;
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

		private function createPolicy(resource:String, startDate:String, endDate:String):String
		{
			//http://docs.amazonwebservices.com/AmazonCloudFront/latest/DeveloperGuide/
			
			var policy:String = "";
			policy += "{\n"; 
			policy += "	\"Statement\": [{\n";
			//policy += "      \"Resource\":\"" + resource + "\", \n";
			policy += "      \"Condition\":{\n" ;
			policy += "         \"DateLessThan\":{\"AWS:EpochTime\":" + endDate + "}\n" ;
			//policy += "         \"DateGreaterThan\":{\"AWS:EpochTime\":" + startDate + "}," ;
			//policy += "         \"DateLessThan\":{\"AWS:EpochTime\":" + endDate + "}" ;
			policy += "      }\n"; 
			policy += "   }]\n"; 
			policy += "}"; 
			
			return policy;
		}
		
	}
}