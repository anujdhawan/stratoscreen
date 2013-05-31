package com.stratoscreen.aws
{
	import com.hurlant.crypto.hash.HMAC;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.crypto.hash.SHA256;
	import com.hurlant.util.Base64;
	CONFIG::isAir {import com.stratoscreen.controller.BandwidthMonitor;}
	import com.stratoscreen.model.OrderedPair;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.Utils;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;


	public class AWS
	{
		public static const USER_AGENT:String = "com.stratoscreen.agent"; 

		private var _lastBytesLoaded:Number = 0;
		
		/**
		 * Create the signature for the REST API using the GET function.
		 * 
		 * http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/index.html?REST_RESTAuth.html
		 *   
		 * @param orderPairs
		 * @return 
		 * 
		 */
		public function generateRESTSignature(endpoint:String, accessKey:String, secretKey:String, pairs:Array):String
		{
			// Sort the array before we start
			var sortedPairs:ArrayCollection = getSortedPairs(pairs);
			
			// Create the string to sign
			var policy:String = "POST\n";
			policy += endpoint+ "\n";
			policy += "/\n";
			policy += "AWSAccessKeyId=" + accessKey;
			
			for each (var orderedPair:OrderedPair in sortedPairs)
			{
				// Ignore the version and the access ket when listing the arguments
				if (orderedPair.name != "AWSAccessKeyId" && orderedPair.name != "Signature")	
				{
					policy += "&" + orderedPair.name + "=" + Utils.urlEncode(orderedPair.value);		
				}
			}
			
			// Create the bytes array from the strings to encrypt
			var bytesPolicy:ByteArray = new ByteArray();
			bytesPolicy.writeUTFBytes(policy);
			
			var bytesSecret:ByteArray = new ByteArray();
			bytesSecret.writeUTFBytes(secretKey);
			
			var hmac:HMAC = new HMAC(new SHA256());
			
			return Base64.encodeByteArray(hmac.compute(bytesSecret, bytesPolicy));;
		}
		
		/**
		 * AWS expects the URlVariables to be sorted alphabectically, with some excptions.
		 * i.e. AWSAccessKeyId, Signature
		 * 
		 * Assume we are sorting an array of OrderedPair classes
		 *  
		 * @param orderedPairs
		 * @return ArrayCollection
		 * @see com.stratoscreen.model.OrderedPair
		 * 
		 */
		public function getSortedPairs(pairs:Array):ArrayCollection
		{
			var sortedPairs:ArrayCollection = new ArrayCollection(pairs);
			
			var sort:Sort = new Sort();
			sort.fields = [new SortField("name")];
			
			sortedPairs.sort = sort;
			sortedPairs.refresh();
			
			return sortedPairs;
		}
		
		/**
		 * Call the common AWS API. 
		 * 
		 * The function expects additional call backs. 
		 *  - result handler. Called from another aws class. i.e. SDBClass
		 *  - fault handler. Same as above
		 *  - callback. The originating class. 
		 *  
		 * @param endpoint
		 * @param action
		 * @param pairs
		 * @param method
		 * @param callback
		 * @param resultHandler
		 * @param faultHandler
		 * 
		 * @see com.stratoscreen.aws.AWSURLLoader
		 * 
		 */
		public function performRestApi(endpoint:String, action:String, pairs:Array,  
										      resultHandler:Function, faultHandler:Function, 
											  callback:Function, format:Class = null, requestId:String = null):void
		{
			// Create the URL to call
			var url:String = "https://" + endpoint + "/"
			
			// Add the remaining parameters alphabetized. Not 100% sure if it should be that way
			// but do not take a chance
			var postData:String = "";
			var sortedPairs:ArrayCollection = this.getSortedPairs(pairs);
			for each (var orderedPair:OrderedPair in sortedPairs)
			{
				if (postData != "") {postData += "&";}
				postData += orderedPair.name + "=" + Utils.urlEncode(orderedPair.value);
			}
			
			var request:URLRequest = new URLRequest(url);
			request.method = "POST";
			CONFIG::isAir {request.userAgent = USER_AGENT;}
			request.data = postData;
			
			var loader:AWSURLLoader = new AWSURLLoader();
			loader.action = action;
			loader.resultHandler = resultHandler;
			loader.faultHandler = faultHandler;
			loader.callback = callback;
			loader.format = format;
			loader.addEventListener(Event.COMPLETE, loaderResultHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, loaderResultHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderResultHandler);
			loader.addEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
			loader.requestId = requestId;
			loader.load(request);		
			
			_lastBytesLoaded = 0;
			
			CONFIG::isAir
			{
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTFBytes(postData);
				BandwidthMonitor.uploaded(bytes.length, action);
				bytes.clear();
			}
		}
		
		private function loaderResultHandler(event:Event):void
		{
			// Assume the event.Target is a AWSUrlLoader
			var awsLoader:AWSURLLoader = event.target as AWSURLLoader;
			awsLoader.removeEventListener(Event.COMPLETE, loaderResultHandler);
			awsLoader.removeEventListener(IOErrorEvent.IO_ERROR, loaderResultHandler);
			awsLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderResultHandler);
			awsLoader.removeEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);

			// Re-call the main event listener.
			if (event.type == Event.COMPLETE)
			{
				awsLoader.resultHandler(event);
			}
			else
			{
				awsLoader.faultHandler(event);
			}
		}
		
		private function loaderProgressHandler(event:ProgressEvent):void
		{
			try
			{
				CONFIG::isAir
				{
					var bytesLength:Number = _lastBytesLoaded == 0 ? event.bytesLoaded : event.bytesLoaded - _lastBytesLoaded;
					_lastBytesLoaded = event.bytesLoaded;
					BandwidthMonitor.downloaded(bytesLength, event.target.action);
				}
			}
			catch (err:Error)
			{
				trace(err.message);
			}
		}
	}
}