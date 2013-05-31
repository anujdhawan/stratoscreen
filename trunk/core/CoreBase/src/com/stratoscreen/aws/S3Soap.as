package com.stratoscreen.aws
{
	import com.hurlant.crypto.hash.HMAC;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.util.Base64;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import mx.rpc.AbstractOperation;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.soap.WebService;
	
	public class S3Soap extends EventDispatcher
	{
		private static const WSDL_SUFFIX:String = "/doc/2006-03-01/AmazonS3.wsdl";
		private var _region:String;
		private var _accessKey:String;
		private var _secretKey:String;
		private var _serv:WebService;
		private var _callback:Function;
		
		public function S3Soap(region:String, accessKey:String, secretKey:String)
		{
			_accessKey = accessKey;
			_secretKey = secretKey;
			
			var wsdl:String = "http://" + region + WSDL_SUFFIX;
			_serv = new WebService(wsdl);
			_serv.addEventListener(ResultEvent.RESULT, resultHandler);
			_serv.addEventListener(FaultEvent.FAULT, faultHandler);
			_serv.loadWSDL(wsdl);
			
			super(null);
		}
		
		public function listAllBuckets(callback:Function):void
		{			
			_callback = callback;
			
			var now:Date = new Date();
			var timeStamp:String = getDateTime(now);
			
			var vars:URLVariables = new URLVariables();
			vars.Service = "AmazonS3";
			vars.Action = "ListAllMyBuckets";
			vars.Timestamp = timeStamp;		
			
			var signature:String = generateSignature(vars);
			_serv.ListAllMyBuckets(_accessKey, timeStamp, signature);
		}
		
		public function createBucket(bucket:String, callback:Function):void
		{			
			_callback = callback;
			
			var now:Date = new Date();
			var timeStamp:String = getDateTime(now);
			
			var vars:URLVariables = new URLVariables();
			vars.Service = "AmazonS3";
			vars.Action = "CreateBucket";
			vars.Timestamp = timeStamp;		
			
			var signature:String = generateSignature(vars);
			var operation:AbstractOperation = _serv.getOperation("CreateBucket");
			operation.arguments.Bucket = bucket;
			operation.arguments.AWSAccessKeyId = _accessKey;
			operation.arguments.Timestamp = timeStamp;
			operation.arguments.Signature = signature;
			operation.send();
		}
		
		
		private function resultHandler(event:ResultEvent):void
		{
			var s3Event:S3Event = new S3Event();
			s3Event.result = event.result;
			s3Event.success = true;

			_callback(s3Event);
		}
		
		private function faultHandler(event:FaultEvent):void
		{
			var s3Event:S3Event= new S3Event();
			s3Event.success = false;

			try
			{
				s3Event.message = event.fault.faultString;
			}
			catch (err:Error)
			{
				trace(err.message);
			}
			
			_callback(s3Event);
		}
		
		private function getDateTime(dt:Date):String {
			var dateTime:String;
			
			var now:Date = dt;
			var month:String = addLeadingZero(String(now.monthUTC + 1));
			var date:String  = addLeadingZero(String(now.dateUTC));
			var hours:String  = addLeadingZero(String(now.hoursUTC));
			var minutes:String  = addLeadingZero(String(now.minutesUTC));
			var seconds:String  = addLeadingZero(String(now.secondsUTC));
			
			return(now.fullYearUTC + "-" + month + "-" + date + "T" + hours + ":" + minutes + ":" + seconds + ".000Z");
		}
		
		private function addLeadingZero(num:String):String {
			if (num.length < 2)
				num = 0 + num;
			return num;
		}
		
		private function generateSignature(urlVariables:URLVariables):String
		{
			var bytesSignature:ByteArray = new ByteArray();
			var bytesSecret:ByteArray = new ByteArray();			
			var stringToSign:String = urlVariables.Service + urlVariables.Action + urlVariables.Timestamp;			
			bytesSignature.writeUTFBytes(stringToSign);			
			bytesSecret.writeUTFBytes(_secretKey);
			var hmac:HMAC = new HMAC(new SHA1());
			return Base64.encodeByteArray(hmac.compute(bytesSecret, bytesSignature));
		}
	}
}