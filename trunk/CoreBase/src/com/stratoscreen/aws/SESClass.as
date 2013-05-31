package com.stratoscreen.aws
{
	import com.hurlant.crypto.hash.HMAC;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.crypto.hash.SHA256;
	import com.hurlant.util.Base64;
	import com.stratoscreen.aws.AWS;
	import com.stratoscreen.model.OrderedPair;
	import com.stratoscreen.utils.DateUtils;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.Utils;
	import com.stratoscreen.utils.XMLUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;

	public class SESClass extends EventDispatcher
	{
		private static const SIGNATURE_METHOD:String = "HmacSHA256";
		private static const SIGNATURE_VERSION:String = "2";
		private static const VERSION:String = "2010-12-01";
		
		private var _aws:AWS;
		private var _regionEndpoint:String;
		private var _accessKey:String;
		private var _secretKey:String;	

		public static function verifiedListToArray(result:Object):Array
		{
			var emails:Array = new Array();
			try
			{
				var result:Object = XMLUtils.stringToObject(result.toString());
				var list:Object = result.ListVerifiedEmailAddressesResponse.ListVerifiedEmailAddressesResult.VerifiedEmailAddresses; 
				if (list != null && list.member != null)
				{
					if (list.member is Array)
					{
						for (var i:int = 0; i < list.member.length; i++)
						{
							emails.push(list.member[i]);	
						}						
					}
					else
					{
						emails.push(list.member);
					}
				}				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err, LogUtils.WARN);
				return new Array();	
			}
			
			return emails;
		}
		
		public function SESClass(region:String, accessKey:String, secretKey:String)
		{
			_aws = new AWS();
			_regionEndpoint = region;
			_accessKey = accessKey;
			_secretKey = secretKey;

			super(null);
		}
		
		public function getQuota(callback:Function):void
		{
			var pairs:Array = new Array();
			this.execute("GetSendQuota", pairs, callback);				
		}			
		
		public function listVerfied(callback:Function):void
		{
			var pairs:Array = new Array();
			this.execute("ListVerifiedEmailAddresses", pairs, callback);					
		}
		
		public function sendEmail(toEmail:String, fromEmail:String, subject:String, body:String, isHtml:Boolean, callback:Function):void
		{
			// Assemble the parameters for the second call
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("Source", fromEmail));
			pairs.push(new OrderedPair("Destination.ToAddresses.member.1", toEmail));
			pairs.push(new OrderedPair("Message.Subject.Data", subject));
			if (isHtml)
			{
				pairs.push(new OrderedPair("&Message.Body.Html.Data", body));
			}
			else
			{
				pairs.push(new OrderedPair("&Message.Body.Text.Data", body));
			}

			this.execute("SendEmail", pairs, callback);							
		}
		
		public function verifyEmailAddress(email:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("EmailAddress", email));			
			this.execute("VerifyEmailAddress", pairs, callback);				
		}		


		private function execute(action:String, pairs:Array, callback:Function):void
		{			
			var date:String = DateUtils.RFCTime();
			var auth:String = "AWS3-HTTPS ";
			auth += "AWSAccessKeyId=" + _accessKey + ", ";
			auth += "Algorithm=" + SIGNATURE_METHOD + ", ";
			auth += "Signature=" + generateSignature(date) + ", ";
		
			// Create the data to send
			var postData:String = "";
			pairs.push(new OrderedPair("Action", action));	
			
			var sortedPairs:ArrayCollection = _aws.getSortedPairs(pairs);			
			for each (var orderedPair:OrderedPair in sortedPairs)
			{
				if (postData != "") {postData += "&";}
				postData += orderedPair.name + "=" + Utils.urlEncode(orderedPair.value);
			}

			var url:String = "https://" + _regionEndpoint + "/" + action;
			var request:URLRequest = new URLRequest(url);			
			request.method = "POST";			
			//request.requestHeaders.push(new URLRequestHeader("Host", _regionEndpoint));
			request.requestHeaders.push(new URLRequestHeader("x-amz-host", _regionEndpoint));
			request.requestHeaders.push(new URLRequestHeader("Content-Type", "application/x-www-form-urlencoded"));
			//request.requestHeaders.push(new URLRequestHeader("Date", date));
			request.requestHeaders.push(new URLRequestHeader("x-amz-date", date));
			request.requestHeaders.push(new URLRequestHeader("X-Amzn-Authorization", auth));
			request.data = postData;
			
			var loader:AWSURLLoader = new AWSURLLoader();
			loader.action = action;
			loader.callback = callback;
			loader.addEventListener(Event.COMPLETE, resultHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			loader.load(request);			
		}
		
		private function resultHandler(event:Event):void
		{			
			
			var sesEvent:SESEvent= new SESEvent();
			sesEvent.result = event.target.data;
			sesEvent.success = true;
			
			event.target.removeEventListener(Event.COMPLETE, resultHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			event.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			event.target.callback(sesEvent);
		}		
		
		private function errorHandler(event:Event):void
		{
			var sesEvent:SESEvent = new SESEvent();
			sesEvent.success = false;
			
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
					sesEvent.message = message;
				}						
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err, 2, LogUtils.WARN);
			}
			
			
			event.target.callback(sesEvent);
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
		
	}
}