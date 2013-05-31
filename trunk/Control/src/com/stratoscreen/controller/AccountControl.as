package com.stratoscreen.controller
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.aws.AWSEndpoint;
	import com.stratoscreen.aws.AWSRegions;
	import com.stratoscreen.aws.CFEvent;
	import com.stratoscreen.aws.IAMClass;
	import com.stratoscreen.aws.IAMEvent;
	import com.stratoscreen.aws.S3Class;
	import com.stratoscreen.aws.S3Event;
	import com.stratoscreen.aws.SDBClass;
	import com.stratoscreen.aws.SDBEvent;
	import com.stratoscreen.aws.SNSEvent;
	import com.stratoscreen.events.InstallEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.model.InstallStep;
	import com.stratoscreen.model.OrderedPair;
	import com.stratoscreen.model.domains.*;
	import com.stratoscreen.utils.GUID;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.XMLUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class AccountControl extends EventDispatcher
	{
		private var _appManager:AppManager;
		private var _account:Accounts;
		private var _accounts:Array;
		private var _steps:Array;
		private var _stepIndex:int;
		private var _users:Array;
		private var _playerIdentity:Identities;
		private var _streamControl:StreamControl;
		
		public function get accounts():Array
		{
			return _accounts;
		}

		public function AccountControl(appManager:AppManager)
		{
			_appManager = appManager;
			super(null);
		}
		
		public function addAccount(account:Accounts, users:Array):void
		{
			_account = account;
			_users = users;
			
			// Create an array of steps to complete the process. 
			_steps = new Array();
			_steps.push(new InstallStep("Validating keys", validateKeys));
			_steps.push(new InstallStep("Updating users table", updateUsersTable));
			_steps.push(new InstallStep("Configuring bucket", configBucket));
			_steps.push(new InstallStep("Querying player identity", queryPlayerIdentity, queryPlayerIdentityHandler ));
			_steps.push(new InstallStep("Creating player signon package", configurePlayerSignon));
			_steps.push(new InstallStep("Configuring streaming", configCloudFront));
			_steps.push(new InstallStep("Updating accounts table", updateAccountsTable));
			_steps.push(new InstallStep("Setting sample content flag", updateSampleContentTable));
			
			// Reload the accounts so we can update the list
			_steps.push(new InstallStep("Querying accounts table", queryAccounts, queryAccountsHandler, false));
			
			_stepIndex = -1;	// We want to start at Zero
			runProcess();
		}

		public function updateAccount(account:Accounts, users:Array):void
		{
			_account = account;
			_users = users;
			
			// Create an array of steps to complete the process. 
			_steps = new Array();
			_steps.push(new InstallStep("Validating keys", validateKeys));
			_steps.push(new InstallStep("Configuring streaming", configCloudFront));
			_steps.push(new InstallStep("Updating accounts table", updateAccountsTable));
			_steps.push(new InstallStep("Updating users table", updateUsersTable));				
			_steps.push(new InstallStep("Setting sample content flag", updateSampleContentTable));	

			// Reload the accounts so we can update the list
			_steps.push(new InstallStep("Querying accounts table", queryAccounts, queryAccountsHandler, false));

			_stepIndex = -1;	// We want to start at Zero
			runProcess();
		}
		
		public function deleteAccount(account:Accounts):void
		{
			_account = account;

			// Create an array of steps to complete the process. 
			_steps = new Array();
			_steps.push(new InstallStep("Validating keys", validateKeys, null, false));
			_steps.push(new InstallStep("Deleting bucket", deleteBucket, null, false));	
			_steps.push(new InstallStep("Deleting from accounts ", deleteAccountsRow, null, false));
			_steps.push(new InstallStep("Deleting account users", queryAccountUsers, queryAccountUsersHandler, false));

			// Reload the accounts so we can update the list
			_steps.push(new InstallStep("Querying accounts table", queryAccounts, queryAccountsHandler, false));

			_stepIndex = -1;	// We want to start at Zero
			runProcess();
		}

		public function get percentComplete():Number
		{
			var percent:Number = _stepIndex / _steps.length;
			if (percent < 0 ) {percent = 0;}
			
			return percent;
		}		

		private function runProcess(event:Object = null):void
		{
			var installStep:InstallStep;
			if (event != null)
			{
				installStep = _steps[_stepIndex] as InstallStep;
				if (!event.success)
				{
					var errorType:int =  InstallEvent.ERROR;
					if (!installStep.stopOnFail) {errorType = InstallEvent.WARNING;}
					
					sendEvent(errorType,  event.message == ""? "Operation failed" : event.message);
					if (installStep.stopOnFail) {return;}	
				}
				
				// Run any follow up functions
				if (installStep.completeHandler != null) 
				{
					installStep.completeHandler(event);
				}
			}
			
			_stepIndex ++;			
			if (_stepIndex >= _steps.length)
			{
				sendEvent(InstallEvent.COMPLETE, "");
				return;
			}
			
			installStep = _steps[_stepIndex] as InstallStep;
			sendEvent(InstallEvent.INFO, installStep.startMessage);
			
			// Call the next function. We may have to pass an argument to the function
			if (installStep.argument == null)
			{
				installStep.func();		
			}
			else
			{
				installStep.func(installStep.argument)
			}
			
		}
		
		private function sendEvent(status:int, message:String):void
		{
			var event:InstallEvent = new InstallEvent(status, message);
			this.dispatchEvent(event);
		}
		
		private function validateKeys():void
		{
			_appManager.iam.validateKeys(runProcess);
		}
		
		private function updateAccountsTable():void
		{			
			_appManager.sdb.updateDomain([_account], runProcess);
		}
		
		private function updateSampleContentTable():void
		{
			if (_account.useForSampleContent)
			{
				_appManager.settings.contentAccountId = _account.itemName;
				_appManager.settings.updated = true;
				_appManager.sdb.updateDomain([_appManager.settings], runProcess);
			}
			else
			{
				// pass back a sucess flag even though we did not run
				var event:SDBEvent = new SDBEvent();
				event.success = true;
				event.message = "Skipped step";
				runProcess(event);
			}
		}

		private function configCloudFront():void
		{
			// We may already be set up for Streaming
			var enableStreaming:Boolean = _account.streaming == "1" && _account.cloudFrontId == "";
			
			// We do not allow disabling at this time
			//var disableStreaming:Boolean = _account.streaming != "1" && _account.cloudFrontId != "";
			
			if (enableStreaming)
			{
				_streamControl = new StreamControl(_appManager);
				_streamControl.createStreamingDistribution(_account, configCloudFrontHandler);
				
				// Do not let the runprocess handle the next step. We will
			}
			else
			{
				// pass back a sucess flag even though we did not run
				var event:SDBEvent = new SDBEvent();
				event.success = true;
				event.message = "Skipped step";
				runProcess(event);
			}			
		}
		
		private function configCloudFrontHandler():void
		{
			try
			{
				if (_streamControl.success)
				{
					_account.cloudFrontId = _streamControl.cfId;
					_account.streamDomain = _streamControl.cfDomain;
				}
				else
				{
					// Reset the account so we can set up again
					_account.streaming = "0";
				}					
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);				
			}
			finally
			{
				// Manually move the next step in the run process
				runProcess(new InstallEvent(InstallEvent.SUCCESS, "", true));
			}
		}
		

		private function updateUsersTable():void
		{			
			_appManager.sdb.updateDomain(_users, runProcess);
		}		
		
		private function queryAccounts():void
		{
			_appManager.sdb.select("Select * from Accounts where name is not null order by name", runProcess, Accounts);
		}

		private function queryAccountsHandler(event:SDBEvent):void
		{
			if (event.success) {_accounts = event.result as Array;}
		}
		
		private function deleteAccountsRow():void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("DomainName", "Accounts"));
			pairs.push(new OrderedPair("ItemName", _account.itemName));
			
			_appManager.sdb.execute("DeleteAttributes", pairs, runProcess);
		}
		
		private function queryAccountUsers():void
		{
			var sql:String = "Select * from Users where accountId = '" + _account.itemName + "'"
			_appManager.sdb.select(sql, runProcess, Users) ;			
		}
		
		private function queryAccountUsersHandler(event:SDBEvent):void
		{
			try
			{
				// Convert the results into an array
				var users:Array = event.result as Array;
				if (users.length > 0)
				{
					// Create a very lathe delete statement
					var pairs:Array = new Array();
					pairs.push(new OrderedPair("DomainName", "Users"));
					
					for (var i:int = 0; i < users.length; i++)
					{
						pairs.push(new OrderedPair("Item." + i + ".ItemName", users[i].itemName ));
					}					
					_appManager.sdb.execute("BatchDeleteAttributes", pairs, null);	// Ignore the call back. If the delete fails we cannot clean up
				}				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err, 2, LogUtils.WARN);
			}
		}

		private function configBucket():void
		{
			var bucketControl:BucketControl = new BucketControl(_appManager);
			bucketControl.configure(_account.bucket, runProcess);
		}
		
		private function queryPlayerIdentity():void
		{
			var sql:String = "Select * from Identities where type = '" + Constants.USER_TYPE_PLAYER + "'"
			_appManager.sdb.select(sql, runProcess,Identities) ;			

		}
		
		private function  queryPlayerIdentityHandler(event:SDBEvent):void
		{
			try
			{
				if (!event.success) {throw new Error(event.message);}
				
				_playerIdentity = event.result[0] as Identities;
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err)
			}
		}

		private function configurePlayerSignon():void
		{
			var control:BucketControl = new BucketControl(_appManager);
			control.createSignonFile(_appManager.regionId, _account.bucket, _appManager.settings.bucketWeb, _playerIdentity, _account.itemName, runProcess);
		}

		private function deleteBucket():void
		{
			var bucketControl:BucketControl = new BucketControl(_appManager);
			bucketControl.deleteBuckets([_account.bucket], runProcess);			
		}
		
	}
}