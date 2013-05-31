package com.stratoscreen.aws
{
	import com.stratoscreen.aws.AWS;
	import com.stratoscreen.model.OrderedPair;
	import com.stratoscreen.utils.DateUtils;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.Utils;
	import com.stratoscreen.utils.XMLUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
		
	/**
	 * Wrapper for the AWS Identity and Access Managment API. Class includes the methods commonly
	 * used by StratoScreen 
	 *  
	 * The class utilizes the REST api for IAM
	 * 
	 * @author P.J. Steele
	 * 
	 */
	public class IAMClass extends EventDispatcher
	{
		private static const SIGNATURE_METHOD:String = "HmacSHA256";
		private static const SIGNATURE_VERSION:String = "2";
		private static const VERSION:String = "2010-05-08";

		private var _aws:AWS;
		private var _regionEndpoint:String;
		private var _accessKey:String;
		private var _secretKey:String;	

		public function IAMClass(region:String, accessKey:String, secretKey:String)
		{
			_aws = new AWS();
			_regionEndpoint = region;
			_accessKey = accessKey;
			_secretKey = secretKey;

			super(null);
		}

		public function validateKeys(handler:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("MaxItems", "1"));
			this.execute("ListUsers", pairs, handler);			
		}
		
		public function listUsers(handler:Function):void
		{
			var pairs:Array = new Array();
			this.execute("ListUsers", pairs, handler);			
		}		

		public function createGroup(groupName:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("GroupName", groupName));
			this.execute("CreateGroup", pairs, callback);			
		}

		public function createUser(userName:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("UserName", userName));
			this.execute("CreateUser", pairs, callback);			
		}
		
		public function addUserToGroup(groupName:String, userName:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("GroupName", groupName));
			pairs.push(new OrderedPair("UserName", userName));
			this.execute("AddUserToGroup", pairs, callback);			
		}		

		public function removeUserFromGroup(groupName:String, userName:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("GroupName", groupName));
			pairs.push(new OrderedPair("UserName", userName));
			this.execute("RemoveUserFromGroup", pairs, callback);			
		}
		
		public function GetUser(userName:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("UserName", userName));
			this.execute("CreateUser", pairs, callback);			
		}

		public function deleteGroup(groupName:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("GroupName", groupName));
			this.execute("DeleteGroup", pairs, callback);			
		}

		public function deleteUser(userName:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("UserName", userName));
			this.execute("DeleteUser", pairs, callback);			
		}

		public function listGroupsForUser(userName:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("UserName", userName));
			this.execute("ListGroupsForUser", pairs, callback);			
		}

		public function createUserAccessKey(userName:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("UserName", userName));
			this.execute("CreateAccessKey", pairs, callback);						
		}

		public function listUserAccessKey(userName:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("UserName", userName));
			this.execute("ListAccessKeys", pairs, callback);						
		}

		public function deleteUserAccessKey(userName:String, accessKey:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("UserName", userName));
			pairs.push(new OrderedPair("AccessKeyId", accessKey));
			
			this.execute("DeleteAccessKey", pairs, callback);						
		}

		public function listUserPolicies(username:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("UserName", username));
			
			this.execute("ListUserPolicies", pairs, callback);					
		}
		
		public function putUserPolicy(policyName:String, document:String, username:String, callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("PolicyName", policyName));
			pairs.push(new OrderedPair("PolicyDocument", document));
			pairs.push(new OrderedPair("UserName", username));
			
			this.execute("PutUserPolicy", pairs, callback);									
		}

		public function deleteUserPolicy(username:String, policyName:String,  callback:Function):void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("PolicyName", policyName));
			pairs.push(new OrderedPair("UserName", username));
			
			this.execute("DeleteUserPolicy", pairs, callback);									
		}

		/**
		 * Run the actual IAM get query. 
		 * 
		 * The function will also add the common parameters too (Action, Signature, SignatureVersion, TimeStamp, etc). 
		 * Assume the values are not in the OrderedPairs array
		 *  
		 * @param action
		 * @param orderedPairs
		 * @param callback
		 * 
		 */
		private function execute(action:String, pairs:Array, callback:Function):void
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
			_aws.performRestApi(_regionEndpoint, action, pairs, resultHandler, errorHandler, callback);
		}
		
		private function resultHandler(event:Event):void
		{			
			var iamEvent:IAMEvent= new IAMEvent();
			iamEvent.result = event.target.data;
			iamEvent.success = true;
			
			event.target.callback(iamEvent);
		}
		
		
		private function errorHandler(event:Event):void
		{
			var iamEvent:IAMEvent= new IAMEvent();
			iamEvent.success = false;
			
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
					iamEvent.message = message;
				}						
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err, 2, LogUtils.WARN);
			}
			
			
			event.target.callback(iamEvent);
		}
	}
}