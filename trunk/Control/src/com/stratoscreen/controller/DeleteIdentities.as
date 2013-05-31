package com.stratoscreen.controller
{
	import com.stratoscreen.aws.IAMEvent;
	import com.stratoscreen.events.InstallEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.XMLUtils;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class DeleteIdentities extends EventDispatcher
	{
		private var _appManager:AppManager;		
		private var _users:Array;	
		private var _members:Array;
		private var _policies:Array;
		private var _callback:Function;
		private var _installEvent:InstallEvent;
		private var _userIndex:int;
		private var _memberIndex:int;
		private var _policyIndex:int;
		private var _accountId:String;
		
		public function DeleteIdentities(appManager:AppManager, callback:Function, accountId:String = "")
		{
			super(null);
			_appManager = appManager;
			_callback = callback;
			_accountId = accountId;
			_users = new Array();
			_members = new Array();
			_policies = new Array();
			
			// Assume the worst. Set up the return event for a failure
			_installEvent = new InstallEvent(InstallEvent.WARNING, "", false);
		}
		
		public function start():void
		{
			_appManager.iam.listUsers(listUsersHandler);
		}
		
		private function listUsersHandler(event:IAMEvent):void
		{
			try
			{
				// Save all the user names to an array
				// The Identities have the account ItemName in them
				var result:Object = XMLUtils.stringToObject(event.result.toString());
				
				if (result.ListUsersResponse.ListUsersResult.Users != null)
				{
					var member:Object = result.ListUsersResponse.ListUsersResult.Users.member;
					var userName:String;
					if ( member is Array)
					{
						for (var i:int = 0; i < member.length; i++)
						{
							userName = member[i].UserName;
							
							if (userName.indexOf(_accountId)>= 0)	{_users.push(userName);	}
						}
					}
					else
					{
						userName = member.UserName;
						if (userName.indexOf(_accountId) >=0 )	{_users.push(userName);	}
					}
				}
				
				// Get the list of all the Policies for these users
				_userIndex = -1;
				listUsersPolicies();
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				_installEvent.message = err.message
				_callback(_installEvent);
			}
		}
		
		private function listUsersPolicies():void
		{
			try
			{
				_userIndex ++;
				
				// Start the delete of all the keys
				if (_userIndex >= _users.length)
				{
					_userIndex = -1;
					listUsersKeys();
					return;
				}
				
				_appManager.iam.listUserPolicies(_users[_userIndex], listUsersPoliciesHandler);
				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				_installEvent.message = err.message
				_callback(_installEvent);
			}			
		}
		
		private function listUsersPoliciesHandler(event:IAMEvent):void
		{
			try
			{
				var result:Object = XMLUtils.stringToObject(event.result.toString());		
				
				// Assume this is not an array
				if (result.ListUserPoliciesResponse.ListUserPoliciesResult.PolicyNames != null)
				{
					var policyName:String = result.ListUserPoliciesResponse.ListUserPoliciesResult.PolicyNames.member;
					
					// Add the results to a new Object
					var item:Object = new Object();
					item.UserName = _users[_userIndex];
					item.PolicyName = policyName;
					
					_policies.push(item);
				}
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}	
			
			// Return to the parent 
			listUsersPolicies();			
		}		
		
		private function listUsersKeys():void
		{
			try
			{
				_userIndex ++;

				// Start the delete of all the keys
				if (_userIndex >= _users.length)
				{
					_policyIndex = -1;
					deleteUserPolicies();
					return;
				}
				
				_appManager.iam.listUserAccessKey(_users[_userIndex], listUsersKeysHandler);
					
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				_installEvent.message = err.message
				_callback(_installEvent);
			}			
		}
		
		private function listUsersKeysHandler(event:IAMEvent):void
		{
			try
			{
				var result:Object = XMLUtils.stringToObject(event.result.toString());		
				
				if (result.ListAccessKeysResponse.ListAccessKeysResult.AccessKeyMetadata != null)
				{
					var member:Object = result.ListAccessKeysResponse.ListAccessKeysResult.AccessKeyMetadata.member;
					if ( member is Array)
					{
						for (var i:int = 0; i < member.length; i++)
						{
							_members.push(member[i]);
						}
					}
					else
					{
						if (member != null) {_members.push(member);}
					}
				}
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}	
			
			// Return to the parent 
			listUsersKeys();			
		}

		private function deleteUserPolicies(event:IAMEvent = null):void
		{
			try
			{
				_policyIndex ++;
				
				// Start the delete of all the keys
				if (_policyIndex >= _policies.length)
				{
					_memberIndex = -1;
					deleteUserKeys();
					return;
				}				
				
				var policy:Object = _policies[_policyIndex];				
				_appManager.iam.deleteUserPolicy(policy.UserName, policy.PolicyName, deleteUserPolicies );
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				_installEvent.message = err.message
				_callback(_installEvent);
			}				
		}

		private function deleteUserKeys(event:IAMEvent = null):void
		{
			try
			{
				_memberIndex ++;
				
				// Start the delete of all the keys
				if (_memberIndex >= _members.length)
				{
					_userIndex = -1;
					deleteUsers();
					return;
				}				
				
				_appManager.iam.deleteUserAccessKey(_members[_memberIndex].UserName, _members[_memberIndex].AccessKeyId, deleteUserKeys );
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				_installEvent.message = err.message
				_callback(_installEvent);
			}				
		}
		
		
		private function deleteUsers(event:IAMEvent = null):void
		{
			try
			{
				_userIndex ++;
				
				// Start the delete of all the keys
				if (_userIndex >= _users.length)
				{
					_installEvent.message = "";
					_installEvent.status = InstallEvent.SUCCESS;
					_installEvent.success = true;
					_callback(_installEvent);
					return;
				}			
				
				_appManager.iam.deleteUser(_users[_userIndex], deleteUsers);
				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				_installEvent.message = err.message
				_callback(_installEvent);
			}				
		}
	}
}