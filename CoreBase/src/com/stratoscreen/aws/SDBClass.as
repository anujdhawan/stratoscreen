package com.stratoscreen.aws
{
	import com.stratoscreen.aws.AWS;
	import com.stratoscreen.controller.ResubmitTimer;
	import com.stratoscreen.model.OrderedPair;
	import com.stratoscreen.model.ResubmitSDBRequest;
	import com.stratoscreen.model.domains.DomainBase;
	import com.stratoscreen.utils.DateUtils;
	import com.stratoscreen.utils.GUID;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.Utils;
	import com.stratoscreen.utils.XMLUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
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
	 * The class utilizes the REST api for SDB
	 * 
	 * @author P.J. Steele
	 * 
	 */
	public class SDBClass extends EventDispatcher
	{
		private static const SIGNATURE_METHOD:String = "HmacSHA256";
		private static const SIGNATURE_VERSION:String = "2";
		private static const VERSION:String = "2009-04-15";
		
		private var _regionEndpoint:String;
		private var _accessKey:String;
		private var _secretKey:String;
		private var _requests:ArrayCollection;
		private var _aws:AWS;
		private var _startTime:Date;
		
		public function SDBClass(region:String, accessKey:String, secretKey:String)
		{
			super(null);
			
			_aws = new AWS();
			_regionEndpoint = region;
			_accessKey = accessKey;
			_secretKey = secretKey;
			
			_requests = new ArrayCollection();
		}

		public function listDomains(callback:Function):void
		{
			var pairs:Array = new Array();
			this.execute("ListDomains", pairs, callback);			
		}
		
		public function createDomain(domain:Object, callback:Function):void
		{
			var domainName:String = getDomainName(domain);
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("DomainName", domainName));
			this.execute("CreateDomain", pairs, callback);			
		}

		public function deleteDomain(domain:Object, callback:Function):void
		{
			var domainName:String = getDomainName(domain);
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("DomainName",  domainName));
			this.execute("DeleteDomain", pairs, callback);			
		}
		
		/**
		 * Using an arrray of objects found in  com.stratoscreen.model.domains
		 * add, update, or delete the rows in the table
		 *  
		 * @param values
		 * @param callback
		 * @param replace
		 * 
		 * @see com.stratoscreen.model.domains.DomainBase
		 */
		public function updateDomain(values:Array, callback:Function, replace:Boolean = true):void
		{
			_startTime = new Date();
			
			// Watch for empty arrays 
			if (values.length == 0) 
			{
				var sdbEvent:SDBEvent = new SDBEvent();
				sdbEvent.result = "";
				sdbEvent.success = true;
				
				callback(sdbEvent);
				return;
			}
			
			// Offload the Update and Delete calls to a new object
			var update:SDBUpdate = new SDBUpdate(this, values, callback, replace);
		}
		
		public function select(query:String, callback:Function, format:Class = null):void
		{
			_startTime = new Date();
			
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("ConsistentRead", "true"));
			pairs.push(new OrderedPair("SelectExpression", query));
			this.execute("Select", pairs, callback, format);						
		}

		/**
		 * Run the actual SimpleDB get query. 
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
			
			// The SDB occasional fails. Retry if the server is unavailable
			var request:ResubmitSDBRequest = new ResubmitSDBRequest();
			request.requestId = GUID.create();
			request.endpoint = _regionEndpoint;
			request.action = action;
			request.pairs = pairs;
			request.callback = callback;
			request.format = format;
			_requests.addItem(request);	 
			
			_aws.performRestApi(_regionEndpoint, action, pairs, resultHandler, errorHandler, callback, format, request.requestId);
		}
		
		private function resultHandler(event:Event):void
		{						
			var now:Date = new Date();
			try
			{
				var action:String = event.target.action;
				if (action == null) {action = "";}
				trace(action + " " + (now.time - _startTime.time));
			}
			catch (err:Error)
			{
				trace(err.message);
			}
			
			var sdbEvent:SDBEvent = new SDBEvent();
			sdbEvent.result = event.target.data;
			sdbEvent.success = true;
			
			// If this is a Select query the user may want the resulst formatted
			// into an array of a certain class
			try
			{
				if (event.target.format != null && event.target.format is Class)
				{
					sdbEvent.result = formatResult(sdbEvent.result.toString(), event.target.format as Class);
				}
				
				// Remove the saved request
				var requestId:String = event.target.requestId;
				for (var i:int = 0; i < _requests.length; i++)
				{
					if (requestId == _requests[i].requestId)
					{
						_requests.removeItemAt(i);
						break;
					}
				}
				
				// While we are here watch for lingering saved data
				now = new Date();
				for (i = 0; i < _requests.length; i++)
				{
					var dateDiff:Number = now.time - _requests[i].created.time;					
					if (dateDiff > 15000)	// 15 seconds
					{
						_requests.removeItemAt(i);
						break;
					}
				}
				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				sdbEvent.result = event.target.data; // Just pass back the XML
			}				
			
			if (event.target.callback != null) {event.target.callback(sdbEvent);}
		}

		
		private function errorHandler(event:Event):void
		{
			var sdbEvent:SDBEvent = new SDBEvent();
			sdbEvent.success = false;
			
			// Add the message if we can. Ignore the Signature Messages
			try
			{
				if (event is IOErrorEvent)
				{
					sdbEvent.message = IOErrorEvent(event).text;
					sdbEvent.errorId = Object(event).errorID;
				}

				// Try and extract the XML if possible
				try
				{
					var xml:XML = new XML(event.target.data.toString());
					sdbEvent.code = xml.Errors.Error.Code;
				}
				catch (err2:Error)
				{ /* Ignore error */}
				
				if (sdbEvent.code != "SignatureDoesNotMatch")
				{
					try
					{
						sdbEvent.message = xml.Errors.Error[0].Message;
					}
					finally 
					{ /* ignore error */}
				}
				
				if (sdbEvent.code == "ServiceUnavailable")
				{
					// Find the matching request 
					var requestId:String = event.target.requestId;
					var request:ResubmitSDBRequest;
					for (var i:int = 0; i < _requests.length; i++)
					{
						if (requestId == _requests[i].requestId)
						{
							request = _requests[i];
							break;
						}
					}
					
					// Recall this failed request. Call again in a 1/4 second
					var resubmit:ResubmitTimer = new ResubmitTimer(250, 1);
					resubmit.request = request;
					resubmit.addEventListener(TimerEvent.TIMER, postTimerHandler);
					resubmit.start();
										
					return; // DO NOT call the callback
				}
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err, 2, LogUtils.WARN);
			}
		
			if (event.target.callback != null) {event.target.callback(sdbEvent);}
		}
		
		/**
		 * Recall the execute command with the same parameters. This is required because 
		 * of a bug in AWS SDB
		 * 
		 * We are using a Timer because the callLater function is not available
		 * @param event
		 * 
		 */
		private function postTimerHandler(event:TimerEvent):void
		{
			var request:ResubmitSDBRequest = event.target.request;

			LogUtils.writeToLog("Recalling SDB request. Action='" + request.action + "' ID=" + request.requestId,
				                LogUtils.WARN);

			_aws.performRestApi(request.endpoint, request.action, request.pairs, resultHandler, errorHandler, 
				               request.callback, request.format, request.requestId); 
		}
		
		/**
		 * Convert the SelectResponse XML from Amazon into a simple array 
		 * with each item matching formatting class. 
		 *  
		 * @param xml
		 * @return Array
		 * 
		 */
		private function formatResult(response:String, format:Class):Array
		{
			var list:Array = new Array;
			try
			{
				var result:Object = XMLUtils.stringToObject(response);
				var items:Array;
				
				if (result.SelectResponse.SelectResult == null)
				{
					// No matching values were found. Return a blank array
					return list;
				}
				
				// Get the items from the response object
				if (result.SelectResponse.SelectResult.Item is Array)
				{
					items = result.SelectResponse.SelectResult.Item;
				}
				else
				{
					items = new Array();
					items.push(result.SelectResponse.SelectResult.Item);
				}
				
				// Loop through the items and create the array
				// We are running on the assumption that the Formatting Class
				// will have matching field names				
				for (var i:int = 0; i < items.length; i++)
				{
					var item:Object = new format();
					var fieldName:String;
					item.itemName = items[i].Name;  // Assume there is always an itemName()
					item.updated = false;			// Override the updated flag. This will have to be set to true for SDB to update 		
						
					if (items[i].Attribute is Array) 
					{
						for (var j:int = 0; j < items[i].Attribute.length; j++)
						{
							try
							{
								fieldName = items[i].Attribute[j].Name;
								item[fieldName] = items[i].Attribute[j].Value; 
								if (item[fieldName] == null) {item[fieldName] = "";}
							}
							catch (err:Error)
							{
								// Watch for properties that are in the SDB but not on the class
								// This means someone was monkeying with the attributes
								LogUtils.writeErrorToLog(err, 2, LogUtils.WARN);
							}
						}
						list.push(item);
					}
					else	// This table has one field
					{
						fieldName = items[i].Attribute.Name;
						item[fieldName] = items[i].Attribute.Value;
						if (item[fieldName] == null) {item[fieldName] = "";}
						list.push(item);
					}
				}
			} 
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);				
				list =  null;
			}
			
			return list;
		}
		

		public function getDomainName(domain:Object):String
		{
			// Assume the class name will look like this com.stratoscreen.model.domains::Table
			var classInfo:Object = ObjectUtil.getClassInfo(domain);

			var sections:Array = classInfo.name.toString().split(":");
			
			return sections[sections.length -1];			
		}
		
		public function getProperties(value:Object):Array
		{
			var options:Object = new Object();
			options.includeReadOnly = false;
			
			var properties:Array = new Array();			
			var classInfo:Object = ObjectUtil.getClassInfo(value, DomainBase.excludeAttributes, options);
			for each (var item:Object in classInfo.properties)
			{
				// Only save Strings because that is what AWS stores
				if (value[item.localName] is String) {properties.push(item.localName);}
			}
			
			return properties;
		}
	}
}