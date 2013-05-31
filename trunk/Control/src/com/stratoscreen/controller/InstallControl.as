package com.stratoscreen.controller
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.aws.AWSEndpoint;
	import com.stratoscreen.aws.AWSRegions;
	import com.stratoscreen.aws.IAMClass;
	import com.stratoscreen.aws.IAMEvent;
	import com.stratoscreen.aws.S3Class;
	import com.stratoscreen.aws.S3Event;
	import com.stratoscreen.aws.SDBClass;
	import com.stratoscreen.aws.SDBEvent;
	import com.stratoscreen.events.InstallEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.model.InstallStep;
	import com.stratoscreen.model.OrderedPair;
	import com.stratoscreen.model.domains.*;
	import com.stratoscreen.resources.PoliciesEmbed;
	import com.stratoscreen.utils.GUID;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.SecurityUtils;
	import com.stratoscreen.utils.Utils;
	import com.stratoscreen.utils.XMLUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.utils.StringUtil;
	
	
	/**
	 * Class will handled the step by step setup the AWS products.
	 * 
	 * The Setup will follow these steps
	 * 1. Validate Keys.
	 * 2. Create database
	 * 3. Create Buckets
	 * 4. Create Notifications
	 * 5. Create Users
	 * 6. Assign policies to the users.
	 * 
	 * @author pjsteele
	 * 
	 */
	public class InstallControl extends EventDispatcher
	{
		private const IAM_SIGNON:String = "IAM_SIGNON";
		private const IAM_MANAGER:String = "IAM_MANAGER";
		private const IAM_USER:String = "IAM_USER";
		private const IAM_PLAYER:String = "IAM_PLAYER";
		
		private var _patternAwsAccount:RegExp = /\@@AWSACCOUNT@@/gi;
		
		private var _appManager:AppManager;
		private var _steps:Array;
		private var _stepIndex:int;
		private var _bucketWeb:String;
		private var _identitySignon:Identities;
		private var _identityMgr:Identities;
		private var _identityUser:Identities;
		private var _identityPlayer:Identities;
		private var _buckets:Array;
		
		public function InstallControl(appManager:AppManager)
		{
			super(null);
		
			_appManager = appManager;
			
			// Set up the security encryption keys
			SecurityUtils.globalCode = Constants.KEY_PREFIX + _appManager.settings.accountId;
			SecurityUtils.regionalCode = _appManager.settings.regionId;		
			
			// Create the signon identity. This will be secure the user sign on process only
			_identitySignon = new Identities();
			_identitySignon.name = IAM_SIGNON;
			_identitySignon.type = Constants.USER_TYPE_SIGNON;
			
			_identityMgr = new Identities();
			_identityMgr.name = IAM_MANAGER;
			_identityMgr.type = Constants.USER_TYPE_MANAGER;
			
			_identityUser = new Identities();
			_identityUser.name = IAM_USER;
			_identityUser.type = Constants.USER_TYPE_USER;
			
			_identityPlayer = new Identities();
			_identityPlayer.name = IAM_PLAYER;
			_identityPlayer.type = Constants.USER_TYPE_PLAYER;
			
			
			// Create an array of steps to complete the process. 
			_steps = new Array();
			_steps.push(new InstallStep("Validating keys", validateKeys));
			_steps.push(new InstallStep("Listing buckets", listBuckets, listBucketsHandler));
			_steps.push(new InstallStep("Creating accounts table", createAccountsTable));
			_steps.push(new InstallStep("Creating channels table", createChannelsTable));
			_steps.push(new InstallStep("Creating channel detail table", createChannelDetailTable));
			_steps.push(new InstallStep("Creating identities table", createIdentitiesTable));
			_steps.push(new InstallStep("Creating medias table", createMediaTable));
			_steps.push(new InstallStep("Creating media detail table", createMediaGroupDetailTable));
			_steps.push(new InstallStep("Creating media groups table", createMediaGroupsTable));
			_steps.push(new InstallStep("Creating overlays table", createOverlaysTable));
			_steps.push(new InstallStep("Creating overlay detail table", createOverlayDetailTable));
			_steps.push(new InstallStep("Creating settings table", createSettingsTable));
			_steps.push(new InstallStep("Creating screens table", createScreensTable));
			_steps.push(new InstallStep("Creating screen detail table", createScreenDetailTable));
			_steps.push(new InstallStep("Creating schedule table", createScheduleTable));
			_steps.push(new InstallStep("Creating schedule detail table", createScheduleDetailTable));
			_steps.push(new InstallStep("Creating users table", createUsersTable));
			_steps.push(new InstallStep("Creating web bucket", createWebBucket, createWebBucketHandler));
			_steps.push(new InstallStep("Configuring web bucket", configureWebBucket));
			_steps.push(new InstallStep("Creating web identity", createWebIdentity, createWebIdentityHandler));
			_steps.push(new InstallStep("Creating web keys", createWebAccessKey, createWebAccessKeyHandler));
			_steps.push(new InstallStep("Creating manager identity", createMgrIdentity, createMgrIdentityHandler ));
			_steps.push(new InstallStep("Creating manager keys", createMgrAccessKey, createMgrAccessKeyHandler));
			_steps.push(new InstallStep("Setting manager policy", setMgrPolicy));
			_steps.push(new InstallStep("Creating user identity", createUserIdentity, createUserIdentityHandler));
			_steps.push(new InstallStep("Creating user keys", createUserAccessKey, createUserAccessKeyHandler));
			_steps.push(new InstallStep("Setting user policy", setUserPolicy));
			_steps.push(new InstallStep("Creating player identity", createPlayerIdentity, createPlayerIdentityHandler));
			_steps.push(new InstallStep("Creating player keys", createPlayerAccessKey, createPlayerAccessKeyHandler));
			_steps.push(new InstallStep("Setting player policy", setPlayerPolicy));
			_steps.push(new InstallStep("Updating identities table", updateIndentiesTable));
			_steps.push(new InstallStep("Configuring web signon", configureWebSignon));
			_steps.push(new InstallStep("Applying web signon policies", setSignonPolicy));
			_steps.push(new InstallStep("Updating settings table", updateSettingsTable));
		}

		public function start():void
		{
			_stepIndex = -1;	// We want to start at Zero
			runProcess();
		}
		
		public function get percentComplete():Number
		{
			var percent:Number = _stepIndex / _steps.length;
			if (percent < 0 ) {percent = 0;}
			
			return percent;
		}
		
		public function get webBucket():String
		{
			return _bucketWeb;
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
			installStep.func();	// Call the next function
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

		private function listBuckets():void
		{
			_appManager.s3.listAllBuckets(runProcess);	
		}
		
		private function listBucketsHandler(event:Object):void
		{
			try
			{
				var result:Object = XMLUtils.stringToObject(event.result.toString());
				var bucketList:Array = new Array();
				_buckets = new Array();
				
				if (result.ListAllMyBucketsResult.Buckets != null)
				{
					if (result.ListAllMyBucketsResult.Buckets.Bucket is Array)
					{
						bucketList = result.ListAllMyBucketsResult.Buckets.Bucket;
					}
					else
					{
						bucketList.push(result.ListAllMyBucketsResult.Buckets.Bucket);
					}
				}
				
				// Save all the possible StratoScreen buckets into a work array
				for each (var bucket:Object in bucketList)
				{
					_buckets.push(bucket.Name);
				}
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.WARNING, err.message);
				LogUtils.writeErrorToLog(err);
			}
		}
		
		private function createAccountsTable():void
		{
			_appManager.sdb.createDomain(Accounts, runProcess);
		}

		private function createChannelsTable():void
		{
			_appManager.sdb.createDomain(Channels, runProcess);
		}

		private function createChannelDetailTable():void
		{
			_appManager.sdb.createDomain(ChannelDetail, runProcess);
		}

		private function createIdentitiesTable():void
		{
			_appManager.sdb.createDomain(Identities, runProcess);
		}

		private function createMediaTable():void
		{
			_appManager.sdb.createDomain(Medias, runProcess);
		}

		private function createMediaGroupDetailTable():void
		{
			_appManager.sdb.createDomain(MediaGroupDetail, runProcess);
		}

		private function createMediaGroupsTable():void
		{
			_appManager.sdb.createDomain(MediaGroups, runProcess);
		}

		private function createOverlaysTable():void
		{
			_appManager.sdb.createDomain(Overlays, runProcess);
		}

		private function createOverlayDetailTable():void
		{
			_appManager.sdb.createDomain(OverlayDetail, runProcess);
		}

		private function createSettingsTable():void
		{
			_appManager.sdb.createDomain(Settings, runProcess);
		}

		private function createScreensTable():void
		{
			_appManager.sdb.createDomain(Screens, runProcess);
		}
		
		private function createScreenDetailTable():void
		{
			_appManager.sdb.createDomain(ScreenDetail, runProcess);
		}
		
		private function createScheduleTable():void
		{
			_appManager.sdb.createDomain(Schedules, runProcess);
		}		
		
		private function createScheduleDetailTable():void
		{
			_appManager.sdb.createDomain(ScheduleDetail, runProcess);
		}		
		
		private function createUsersTable():void
		{
			_appManager.sdb.createDomain(Users, runProcess);
		}


		private function createWebBucket():void
		{
			// Start the bucket name with the region ID. i.e 
			// 1 = A, 2= B, etc
			var prefix:String = String.fromCharCode(_appManager.regionId + 64);
			
			// Assume no buckets have been created when this process started
			var ok:Boolean = false;
			do 
			{
				_bucketWeb = prefix + Utils.randomEasyReadString(Constants.BUCKET_NAME_LENGTH);
				_bucketWeb = _bucketWeb.toLowerCase();
				
				ok = true;
				for (var i:int = 0; i < _buckets.length; i++)
				{
					if (_bucketWeb.toLowerCase() == _buckets[i].toLowerCase())
					{
						ok = false;
						break
					}
				}					
				
			} while (!ok)
			
			SecurityUtils.installCode = _bucketWeb;			
			_appManager.s3.putBucket(_bucketWeb, runProcess, S3Class.ACL_PUBLIC_READ);	
		}
		
		private function createWebBucketHandler(event:Object):void
		{
			_appManager.settings.bucketWeb = _bucketWeb;
		}
		
		private function configureWebBucket():void
		{
			var control:BucketControl = new BucketControl(_appManager);
			control.configure(_bucketWeb, runProcess);
		}
		
		private function createWebIdentity():void
		{
			_appManager.iam.createUser(_identitySignon.name , runProcess);
		}
		
		private function createWebIdentityHandler(event:IAMEvent):void
		{
			try
			{
				var result:Object = XMLUtils.stringToObject(event.result.toString());
				
				_identitySignon.arn = result.CreateUserResponse.CreateUserResult.User.Arn;
				setAWSAccount(_identitySignon.arn);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}			
		}
		
		private function createMgrIdentity():void
		{			
			_appManager.iam.createUser(_identityMgr.name , runProcess);
		}		
		
		private function createMgrIdentityHandler(event:IAMEvent):void
		{
			try
			{
				var result:Object = XMLUtils.stringToObject(event.result.toString());
				
				_identityMgr.arn = result.CreateUserResponse.CreateUserResult.User.Arn;
				setAWSAccount(_identityMgr.arn);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}			
		}
		
		private function createUserIdentity():void
		{			
			_appManager.iam.createUser(_identityUser.name, runProcess);
		}		
		
		private function createUserIdentityHandler(event:IAMEvent):void
		{
			try
			{
				var result:Object = XMLUtils.stringToObject(event.result.toString());
				
				_identityUser.arn = result.CreateUserResponse.CreateUserResult.User.Arn;
				setAWSAccount(_identityUser.arn);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
		
		private function createPlayerIdentity():void
		{			
			_appManager.iam.createUser(_identityPlayer.name, runProcess);
		}		
		
		private function createPlayerIdentityHandler(event:IAMEvent):void
		{
			try
			{
				var result:Object = XMLUtils.stringToObject(event.result.toString());
				
				_identityPlayer.arn = result.CreateUserResponse.CreateUserResult.User.Arn;
				setAWSAccount(_identityPlayer.arn);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}		
		
		private function createWebAccessKey():void
		{
			_appManager.iam.createUserAccessKey( _identitySignon.name, runProcess);
		}
		
		private function createWebAccessKeyHandler(event:Object):void
		{
			var result:Object = XMLUtils.stringToObject(event.result.toString());
			
			_identitySignon.decryptedAccessKey = result.CreateAccessKeyResponse.CreateAccessKeyResult.AccessKey.AccessKeyId;
			_identitySignon.decryptedSecretKey = result.CreateAccessKeyResponse.CreateAccessKeyResult.AccessKey.SecretAccessKey;
		}		
		
		private function createMgrAccessKey():void
		{
			_appManager.iam.createUserAccessKey( _identityMgr.name, runProcess);
		}
		
		private function createMgrAccessKeyHandler(event:Object):void
		{
			var result:Object = XMLUtils.stringToObject(event.result.toString());
			
			_identityMgr.decryptedAccessKey = result.CreateAccessKeyResponse.CreateAccessKeyResult.AccessKey.AccessKeyId;
			_identityMgr.decryptedSecretKey = result.CreateAccessKeyResponse.CreateAccessKeyResult.AccessKey.SecretAccessKey;
		}
		
		private function setMgrPolicy():void
		{
			var policyXML:XML = new XML(new PoliciesEmbed().toString());
			var policy:String = policyXML.IAM.IAM_MANAGER;
			policy = StringUtil.trim(policy);
			policy = policy.replace(_patternAwsAccount, _appManager.awsAccount);
			
			_appManager.iam.putUserPolicy("mgrPolicy", policy, IAM_MANAGER, runProcess);
		}
		
		private function createUserAccessKey():void
		{
			_appManager.iam.createUserAccessKey(_identityUser.name, runProcess);
		}
		
		private function createUserAccessKeyHandler(event:Object):void
		{
			var result:Object = XMLUtils.stringToObject(event.result.toString());
			
			_identityUser.decryptedAccessKey = result.CreateAccessKeyResponse.CreateAccessKeyResult.AccessKey.AccessKeyId;
			_identityUser.decryptedSecretKey = result.CreateAccessKeyResponse.CreateAccessKeyResult.AccessKey.SecretAccessKey;
		}		
		
		private function setUserPolicy():void
		{
			var policyXML:XML = new XML(new PoliciesEmbed().toString());
			var policy:String = policyXML.IAM.IAM_USER;
			policy = StringUtil.trim(policy);
			policy = policy.replace(_patternAwsAccount, _appManager.awsAccount);
			
			_appManager.iam.putUserPolicy("userPolicy", policy, IAM_USER, runProcess);
		}
		
		private function createPlayerAccessKey():void
		{
			_appManager.iam.createUserAccessKey(_identityPlayer.name, runProcess);
		}
		
		private function createPlayerAccessKeyHandler(event:Object):void
		{
			var result:Object = XMLUtils.stringToObject(event.result.toString());
			
			_identityPlayer.decryptedAccessKey = result.CreateAccessKeyResponse.CreateAccessKeyResult.AccessKey.AccessKeyId;
			_identityPlayer.decryptedSecretKey = result.CreateAccessKeyResponse.CreateAccessKeyResult.AccessKey.SecretAccessKey;
		}		
		
		private function setPlayerPolicy():void
		{
			var policyXML:XML = new XML(new PoliciesEmbed().toString());
			var policy:String = policyXML.IAM.IAM_PLAYER;
			policy = StringUtil.trim(policy);
			policy = policy.replace(_patternAwsAccount, _appManager.awsAccount);
			
			_appManager.iam.putUserPolicy("playerPolicy", policy, IAM_PLAYER, runProcess);
		}
		
		private function updateIndentiesTable():void
		{
			var identies:Array = new Array(_identitySignon, _identityMgr, _identityUser, _identityPlayer);
			_appManager.sdb.updateDomain(identies, runProcess);
		}
		
		
		private function configureWebSignon():void
		{
			var control:BucketControl = new BucketControl(_appManager);
			control.createSignonFile(_appManager.regionId, _bucketWeb, _bucketWeb, _identitySignon, "account id not added", runProcess);	
		}
		
		private function setSignonPolicy():void
		{
			try
			{
				var policiesXml:XML = new XML(new PoliciesEmbed().toString());		
				var policy:String = policiesXml.IAM.IAM_SIGNON;				
				
				// Perform the substitution on the generice policy
				policy = policy.replace(_patternAwsAccount, _appManager.awsAccount);
				policy = StringUtil.trim(policy);
				policy = policy.replace(new RegExp(/\t/gi), " ");

				_appManager.iam.putUserPolicy("policySDB_IAM_SIGNON", policy, IAM_SIGNON, runProcess);
				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);

				// Return to the runprocess but mark as fail
				runProcess(new InstallEvent(InstallEvent.ERROR, err.message, false));
			}
		}
		
		private function updateSettingsTable():void
		{			
			_appManager.sdb.updateDomain([_appManager.settings], runProcess);
		}
		
		private function setAWSAccount(arn:String):void
		{
			if (_appManager.awsAccount != null && _appManager.awsAccount != "") {return;}
			
			// Extract the account number from one of the identites
			// it should loook like this arn:aws:iam::123456789012:user/im_AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE
			try
			{
				var sections:Array = arn.split(":");
				_appManager.awsAccount = sections[4];		
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
				_appManager.awsAccount = "";
			}
		}
	}
}