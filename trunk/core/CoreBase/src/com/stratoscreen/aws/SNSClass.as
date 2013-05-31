package com.stratoscreen.aws
{
	import com.stratoscreen.aws.AWS;
	import com.stratoscreen.model.OrderedPair;
	import com.stratoscreen.model.domains.DomainBase;
	import com.stratoscreen.utils.DateUtils;
	import com.stratoscreen.utils.GUID;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.Utils;
	import com.stratoscreen.utils.XMLUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	import mx.utils.StringUtil;
	
	/**
	 * Wrapper for the AWS SimpleDB API. Class includes the methods commonly
	 * used by StratoScreen 
	 *  
	 * The class utilizes the REST api for SNS
	 * 
	 * @author P.J. Steele
	 * 
	 */
	public class SNSClass extends EventDispatcher
	{
		private static const SIGNATURE_METHOD:String = "HmacSHA256";
		private static const SIGNATURE_VERSION:String = "2";
		private static const VERSION:String = "2010-03-31";
		
		private var _aws:AWS;
		private var _regionEndpoint:String;
		private var _accessKey:String;
		private var _secretKey:String;
		
		public function SNSClass(region:String, accessKey:String, secretKey:String)
		{
			super(null);
			
			_aws = new AWS();
			_regionEndpoint = region;
			_accessKey = accessKey;
			_secretKey = secretKey;
		}

		public function listTopics(callback:Function):void
		{
			var pairs:Array = new Array();
			this.execute("ListTopics", pairs, callback);			
		}
		
		public function createTopic(name:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("Name", name));
			this.execute("CreateTopic", pairs, callback);			
		}			
		
		public function deleteTopic(arn:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("TopicArn", arn));
			this.execute("DeleteTopic", pairs, callback);			
		}		

		/**
		 * Run the actual Simple Notification get query. 
		 * 
		 * The function will also add the common parameters too (Action, Signature, SignatureVersion, TimeStamp, etc). 
		 * Assume the values are not in the OrderedPairs array
		 * 
		 * This function is only to be called by the SDBClass and SDBUpdate
		 *  
		 * @param action
		 * @param orderedPairs
		 * @param callback
		 * 
		 */
		public function execute(action:String, pairs:Array, callback:Function, format:Class = null):void
		{
			// Add the common values to the ordered pairs
			pairs.push(new OrderedPair("Action", action));
			pairs.push(new OrderedPair("AWSAccessKeyId", _accessKey));
			pairs.push(new OrderedPair("SignatureMethod", SIGNATURE_METHOD));
			pairs.push(new OrderedPair("SignatureVersion", SIGNATURE_VERSION));
			pairs.push(new OrderedPair("Timestamp", DateUtils.GMTTime()));
			pairs.push(new OrderedPair("Version", VERSION));
			
			// Create the signature and add it to the parms
			var signature:String = _aws.generateRESTSignature(_regionEndpoint, _accessKey, _secretKey, pairs);
			pairs.push( new OrderedPair("Signature", signature));
			
			_aws.performRestApi(_regionEndpoint, action, pairs, resultHandler, errorHandler, callback, format);
		}
		
		private function resultHandler(event:Event):void
		{			
			var snsEvent:SNSEvent = new SNSEvent();
			snsEvent.result = event.target.data;
			snsEvent.success = true;
			
			// If this is a Select query the user may want the resulst formatted
			// into an array of a certain class
			try
			{
								
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				snsEvent.result = event.target.data; // Just pass back the XML
			}				
			
			if (event.target.callback != null) {event.target.callback(snsEvent);}
		}

		
		private function errorHandler(event:Event):void
		{
			var snsEvent:SNSEvent = new SNSEvent();
			snsEvent.success = false;
			
			// Add the message if we can. Ignore the Signature Messages
			try
			{
				var xml:XML = new XML(event.target.data.toString());
				snsEvent.code = xml.Errors.Error.Code;
				if (snsEvent.code != "SignatureDoesNotMatch")
				{
					snsEvent.message = xml.Errors.Error[0].Message;
				}				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err, 2, LogUtils.WARN);
			}
			
		
			if (event.target.callback != null) {event.target.callback(snsEvent);}
		}
					}
}