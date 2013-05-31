package com.stratoscreen.aws
{
	import com.stratoscreen.model.OrderedPair;
	import com.stratoscreen.utils.*;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;
	
	[Deprecated]
	public class FPSClass extends EventDispatcher
	{
		private static const SIGNATURE_METHOD:String = "HmacSHA256";
		private static const SIGNATURE_VERSION:String = "2";
		private static const VERSION:String = "2009-01-09";
		
		private static var _endpoint:String = "https://authorize.payments.amazon.com/cobranded-ui/actions/start";

		public static function set useSandbox(value:Boolean):void
		{
			if (value) 
			{
				trace("Using FPS Sandbox");
				_endpoint = "https://authorize.payments-sandbox.amazon.com/cobranded-ui/actions/start";
			}
		}

		private var _aws:AWS;
		private var _accessKey:String;
		private var _secretKey:String;

		public function FPSClass(accessKey:String, secretKey:String)
		{
			super(null);
			
			_aws = new AWS();
			_accessKey = accessKey;
			_secretKey = secretKey;
		}
		

		public function getRecurringURL(reference:String, amount:Number, reason:String, period:String, returnUrl:String):String
		{
			var pairs:Array = baseOrderedPairs();
			pairs.push(new OrderedPair("callerReference", reference));
			pairs.push(new OrderedPair("transactionAmount", amount.toString()));
			pairs.push(new OrderedPair("recurringPeriod", period));
			pairs.push(new OrderedPair("returnUrl", returnUrl));
			pairs.push(new OrderedPair("paymentMethod", "CC"));
			pairs.push(new OrderedPair("paymentReason", reason));
			
			// Create the signature and add it to the parms
			var signature:String = _aws.generateRESTSignature(_endpoint, _accessKey, _secretKey, pairs);
			pairs.push( new OrderedPair("signature", signature));

			return createURL(pairs);
		}
		
		private function baseOrderedPairs():Array
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("callerKey", _accessKey));
			pairs.push(new OrderedPair("signatureMethod", SIGNATURE_METHOD));
			pairs.push(new OrderedPair("signatureVersion", SIGNATURE_VERSION));
			pairs.push(new OrderedPair("version", VERSION));
			
			return pairs;
		}

		private function createURL(pairs:Array):String
		{
			var url:String = _endpoint;			
			var sortedPairs:ArrayCollection = _aws.getSortedPairs(pairs);
			
			for (var i:int = 0; i < sortedPairs.length; i++)
			{
				url += i == 0 ? "?" : "&";
				url += sortedPairs[i].name + "=" + Utils.urlEncode(sortedPairs[i].value);
			}

			return url;
		}
	}
}