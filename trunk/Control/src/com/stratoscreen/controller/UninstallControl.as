package com.stratoscreen.controller
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.aws.IAMEvent;
	import com.stratoscreen.aws.S3Event;
	import com.stratoscreen.aws.SDBEvent;
	import com.stratoscreen.events.InstallEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.model.InstallStep;
	import com.stratoscreen.model.OrderedPair;
	import com.stratoscreen.model.domains.*;
	import com.stratoscreen.model.views.*;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.XMLUtils;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;

	
	public class UninstallControl extends EventDispatcher
	{		
		private var _appManager:AppManager;
		private var _steps:Array;
		private var _stepIndex:int;
		private var _buckets:Array;
		private var _members:Array;
		
		public function UninstallControl(appManager:AppManager)
		{
			super(null);
			_appManager = appManager;		
			
			// Create an array of steps to complete the process. 
			_steps = new Array();
			_steps.push(new InstallStep("Validating keys", validateKeys));
			_steps.push(new InstallStep("Deleting accounts table", deleteAccountsTable, null, false));
			_steps.push(new InstallStep("Deleting channels table", deleteChannelsTable, null, false));
			_steps.push(new InstallStep("Deleting channel detail table", deleteChannelDetailTable, null, false));
			_steps.push(new InstallStep("Deleting identities", deleteIdentities, null, false));
			_steps.push(new InstallStep("Deleting medias table", deleteMediasTable, null, false));
			_steps.push(new InstallStep("Deleting media detail table", deleteMediaGroupDetailTable, null, false));
			_steps.push(new InstallStep("Deleting media groups table", deleteMediaGroupsTable, null, false));
			_steps.push(new InstallStep("Deleting overlays table", deleteOverlaysTable, null, false));
			_steps.push(new InstallStep("Deleting overlay detail table", deleteOverlayDetailTable, null, false));
			_steps.push(new InstallStep("Deleting settings table", deleteSettingsTable, null, false));
			_steps.push(new InstallStep("Deleting screens table", deleteScreensTable, null, false));
			_steps.push(new InstallStep("Deleting screen detail table", deleteScreenDetailTable, null, false));
			_steps.push(new InstallStep("Deleting schedules table", deleteSchedulesTable, null, false));
			_steps.push(new InstallStep("Deleting schedule detail table", deleteScheduleDetailTable, null, false));
			_steps.push(new InstallStep("Deleting users table", deleteUsersTable, null, false));
			_steps.push(new InstallStep("Deleting identities table", deleteIdentitiesTable, null, false));
			_steps.push(new InstallStep("Listings buckets", listBuckets, listBucketsHandler, false));
			_steps.push(new InstallStep("Deleting buckets", deleteBuckets, null, false));
			
		}
		
		public function get percentComplete():Number
		{
			var percent:Number = _stepIndex / _steps.length;
			if (percent < 0 ) {percent = 0;}
			
			return percent;
		}
		
		public function start():void
		{
			_stepIndex = -1;	// We want to start at Zero
			runProcess();
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
			
			// Call the next function
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
		
		private function deleteIdentities():void
		{
			// Passing a blank string will delete all identities
			var control:DeleteIdentities = new DeleteIdentities(_appManager, runProcess, "");
			control.start();
		}
		
		private function deleteSettingsTable():void
		{
			_appManager.sdb.deleteDomain(Settings, runProcess);
		}
		
		private function deleteAccountsTable():void
		{
			_appManager.sdb.deleteDomain(Accounts, runProcess);
		}
		
		private function deleteUsersTable():void
		{
			_appManager.sdb.deleteDomain(Users, runProcess);
		}

		private function deleteIdentitiesTable():void
		{
			_appManager.sdb.deleteDomain(Identities, runProcess);
		}

		private function deleteMediasTable():void
		{
			_appManager.sdb.deleteDomain(Medias, runProcess);
		}

		private function deleteChannelsTable():void
		{
			_appManager.sdb.deleteDomain(Channels, runProcess);
		}

		private function deleteChannelDetailTable():void
		{
			_appManager.sdb.deleteDomain(ChannelDetail, runProcess);
		}
		
		private function deleteMediaGroupDetailTable():void
		{
			_appManager.sdb.deleteDomain(MediaGroupDetail, runProcess);
		}
		
		private function deleteMediaGroupsTable():void
		{
			_appManager.sdb.deleteDomain(MediaGroups, runProcess);
		}
		
		private function deleteOverlaysTable():void
		{
			_appManager.sdb.deleteDomain(Overlays, runProcess);
		}
		
		private function deleteOverlayDetailTable():void
		{
			_appManager.sdb.deleteDomain(OverlayDetail, runProcess);
		}
		
		private function deleteScreensTable():void
		{
			_appManager.sdb.deleteDomain(Screens, runProcess);
		}
		
		private function deleteScreenDetailTable():void
		{
			_appManager.sdb.deleteDomain(ScreenDetail, runProcess);
		}
		
		
		private function deleteSchedulesTable():void
		{
			_appManager.sdb.deleteDomain(Schedules, runProcess);
		}		

		private function deleteScheduleDetailTable():void
		{
			_appManager.sdb.deleteDomain(ScheduleDetail, runProcess);
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
				
				if (result.ListAllMyBucketsResult.Buckets.Bucket is Array)
				{
					bucketList = result.ListAllMyBucketsResult.Buckets.Bucket;
				}
				else
				{
					bucketList.push(result.ListAllMyBucketsResult.Buckets.Bucket);
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

		private function deleteBuckets():void
		{
			var control:BucketControl =  new BucketControl(_appManager);
			control.deleteBuckets(_buckets, runProcess);
		}

	}
}