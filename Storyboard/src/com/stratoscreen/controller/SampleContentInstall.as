package com.stratoscreen.controller
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.aws.S3Class;
	import com.stratoscreen.aws.S3Event;
	import com.stratoscreen.aws.SDBEvent;
	import com.stratoscreen.events.InstallEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.model.InstallStep;
	import com.stratoscreen.model.RenameId;
	import com.stratoscreen.model.domains.*;	
	import com.stratoscreen.model.views.*;
	import com.stratoscreen.utils.LogUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class SampleContentInstall extends EventDispatcher
	{
		private var _appManager:AppManager;
		private var _steps:Array;
		private var _index:int;
		private var _mediaIndex:int;
		private var _settings:Settings;
		private var _copyAccount:Accounts;
		private var _medias:Array;
		private var _mediaGroups:Array;
		private var _mediaGroupDetail:Array;
		private var _overlays:Array;
		private var _overlayDetail:Array;
		private var _channels:Array;
		private var _channelDetail:Array;
		private var _acctId:String;
		private var _thisAcctId:String 
		private var _renameIds:Array;
		private var _mediaIds:Array
		
		public function SampleContentInstall(appManager:AppManager)
		{
			_appManager = appManager;
			_thisAcctId = _appManager.currentAccount.itemName;			
		}
		
		public function start():void
		{
			_steps = new Array();
			_steps.push(new InstallStep("Querying Settings", querySettings, querySettingsHandler));
			_steps.push(new InstallStep("Querying Account", queryAccount, queryAccountHandler));
			_steps.push(new InstallStep("Querying Medias", queryMedias, queryMediasHandler));
			_steps.push(new InstallStep("Querying Media Groups", queryMediaGroups, queryMediaGroupsHandler));
			_steps.push(new InstallStep("Querying Media Group Detail", queryMediaGroupDetail, queryMediaGroupDetailHandler));
			_steps.push(new InstallStep("Querying Overlays", queryOverlays, queryOverlaysHandler));
			_steps.push(new InstallStep("Querying Overlay Detail", queryOverlayDetail, queryOverlayDetailHandler));
			_steps.push(new InstallStep("Querying Channels", queryChannels, queryChannelsHandler));
			_steps.push(new InstallStep("Querying Channel Detail", queryChannelDetail, queryChannelDetailHandler));
			_steps.push(new InstallStep("Changing Ids", updateBaseDomain));
			_steps.push(new InstallStep("Changing child Ids", updateChildIds));
			_steps.push(new InstallStep("Configuring media to copy", configCopyMedia));
			_steps.push(new InstallStep("Copying thumbnails", copyThumbs));
			_steps.push(new InstallStep("Copying Media", copyMedia));
			_steps.push(new InstallStep("Updating Medias", updateMedias));
			_steps.push(new InstallStep("Updating Media Groups", updateMediaGroups));
			_steps.push(new InstallStep("Updating Media Group Detail", updateMediaGroupDetail));
			_steps.push(new InstallStep("Updating Overlays", updateOverlays));
			_steps.push(new InstallStep("Updating Overlay Detail", updateOverlayDetail));
			_steps.push(new InstallStep("Updating Channels", updateChannels));
			_steps.push(new InstallStep("Updating Channel Detail", updateChannelDetail));
			_steps.push(new InstallStep("Updating Account", updateAccount));
			
			_index = -1;
			runProcess();
		}
		
		private function runProcess(event:Object = null):void
		{
			var installStep:InstallStep;
			
			// If we have a timer event treat as null
			if (event is TimerEvent)
			{
				event.target.removeEventListener(TimerEvent.TIMER, runProcess);
				event = null;
			}
			
			if (event != null)
			{
				installStep = _steps[_index] as InstallStep;
				if (!event.success)
				{
					var errorType:int =  InstallEvent.ERROR;
					if (!installStep.stopOnFail) {errorType = InstallEvent.WARNING;}
					
					sendEvent(errorType,  event.message == ""? "Operation failed" : event.message, false);
					if (installStep.stopOnFail) 
					{
						return;
					}	
				}
				
				// Run any follow up functions
				if (installStep.completeHandler != null) 
				{					
					installStep.completeHandler(event);
				}
			}
			
			_index ++;			
			if (_index >= _steps.length)
			{
				sendEvent(InstallEvent.COMPLETE, "");
				return;
			}
			
			installStep = _steps[_index] as InstallStep;
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
		
		private function sendEvent(status:int, message:String, success:Boolean = true):void
		{
			var event:InstallEvent = new InstallEvent(status, message, success);
			this.dispatchEvent(event);
		}

		/**
		 * Since we do not have a callLater, use a timer to all the events to catch up 
		 */
		private function postRunProcess():void
		{
			var timer:Timer = new Timer(250, 1);
			timer.addEventListener(TimerEvent.TIMER, runProcess);
			timer.start();
		}

		private function querySettings():void
		{
			_appManager.sdb.select("Select * from Settings", runProcess, Settings);
		}

		private function querySettingsHandler(event:SDBEvent):void
		{
			try
			{
				_settings = event.result[0] as Settings;
				_acctId = _settings.contentAccountId;
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.ERROR,  err.message, false);				
			}
		}
		
		private function queryAccount():void
		{
			_appManager.sdb.select("Select * from Accounts where itemName()= '" + _acctId + "'", runProcess, Accounts);
		}
		
		private function queryAccountHandler(event:SDBEvent):void
		{
			try
			{
				_copyAccount = event.result[0] as Accounts;
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.ERROR,  err.message, false);				
			}
		}

		private function queryMedias():void
		{
			_appManager.sdb.select("Select * from Medias where accountId = '" + _acctId + "'", runProcess, Medias);
		}
		
		private function queryMediasHandler(event:SDBEvent):void
		{
			try
			{
				_medias = event.result as Array; 	
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.ERROR,  err.message, false);				
			}
		}

		private function queryMediaGroups():void
		{
			_appManager.sdb.select("Select * from MediaGroups where accountId = '" + _acctId + "'", runProcess, MediaGroups);
		}
		
		private function queryMediaGroupsHandler(event:SDBEvent):void
		{
			try
			{
				_mediaGroups = event.result as Array; 	
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.ERROR,  err.message, false);				
			}
		}

		private function queryMediaGroupDetail():void
		{
			_appManager.sdb.select("Select * from MediaGroupDetail where accountId = '" + _acctId + "'", runProcess, MediaGroupDetail);
		}
		
		private function queryMediaGroupDetailHandler(event:SDBEvent):void
		{
			try
			{
				_mediaGroupDetail = event.result as Array; 	
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.ERROR,  err.message, false);				
			}
		}

		private function queryOverlays():void
		{
			_appManager.sdb.select("Select * from Overlays where accountId = '" + _acctId + "'", runProcess, Overlays);
		}
		
		private function queryOverlaysHandler(event:SDBEvent):void
		{
			try
			{
				_overlays = event.result as Array; 	
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.ERROR,  err.message, false);				
			}
		}

		private function queryOverlayDetail():void
		{
			_appManager.sdb.select("Select * from OverlayDetail where accountId = '" + _acctId + "'", runProcess, OverlayDetail);
		}
		
		private function queryOverlayDetailHandler(event:SDBEvent):void
		{
			try
			{
				_overlayDetail = event.result as Array; 	
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.ERROR,  err.message, false);				
			}
		}

		private function queryChannels():void
		{
			_appManager.sdb.select("Select * from Channels where accountId = '" + _acctId + "'", runProcess, Channels);
		}
		
		private function queryChannelsHandler(event:SDBEvent):void
		{
			try
			{
				_channels = event.result as Array; 	
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.ERROR,  err.message, false);				
			}
		}
		
		private function queryChannelDetail():void
		{
			_appManager.sdb.select("Select * from ChannelDetail where accountId = '" + _acctId + "'", runProcess, ChannelDetail);
		}
		
		private function queryChannelDetailHandler(event:SDBEvent):void
		{
			try
			{
				_channelDetail = event.result as Array; 	
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.ERROR,  err.message, false);				
			}
		}

		private function updateBaseDomain():void
		{
			try
			{
				updateArray(_medias);
				updateArray(_mediaGroups);
				updateArray(_mediaGroupDetail);
				updateArray(_overlays);
				updateArray(_overlayDetail);
				updateArray(_channels);
				updateArray(_channelDetail);
				
				postRunProcess();
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.ERROR,  err.message, false);				
			}
		}
		
		private function updateArray(value:Array):void
		{
			for (var i:int = 0; i < value.length; i++)
			{
				value[i].accountId = _thisAcctId;
				value[i].createdBy = _appManager.currentUser.itemName;
				value[i].createdDate = new Date();
				value[i].modifiedBy = _appManager.currentUser.itemName;
				value[i].modifiedDate = new Date();
				value[i].updated = true;	// Make sure it updates when we save
			}			
		}
		
		private function updateChildIds():void
		{
			try
			{
				_renameIds = new Array();
					
				// Loop trough the most common elements first and start to change the IDs
				// i.e. Medias, MediaGroups, Overlays
				for each( var media:Medias in _medias)
				{
					var renameId:RenameId = new RenameId(media.itemName, RenameId.MEDIA, media.name);
					_renameIds[media.itemName] = renameId;
					media.itemName = renameId.newId;
				}
	
				for each(var group:MediaGroups in _mediaGroups)
				{
					renameId = new RenameId(group.itemName, RenameId.MEDIA_GROUP);	
					_renameIds[group.itemName] = renameId;
					group.itemName = renameId.newId;
					group.firstMediaId =  getNewId(group.firstMediaId);
				}
				
				// Update the Media Group Detail.
				// We'll need to match the references to the other IDs too
				for each (var groupDetail:MediaGroupDetail in _mediaGroupDetail)
				{
					renameId = new RenameId(groupDetail.itemName, "");	// No need to track this ID
					groupDetail.itemName = renameId.newId;
					groupDetail.mediaGroupId = _renameIds[groupDetail.mediaGroupId].newId;
					groupDetail.mediaId = getNewId(groupDetail.mediaId);
				}
	
				for each(var overlay:Overlays in _overlays)
				{
					renameId = new RenameId(media.itemName, RenameId.OVERLAY);	
					_renameIds[overlay.itemName] = renameId;
					overlay.itemName = renameId.newId;
					overlay.baseMediaId = getNewId(overlay.baseMediaId);
				}
				
				for each(var overlayDetail:OverlayDetail in _overlayDetail)
				{
					renameId = new RenameId(overlayDetail.itemName, "");	// No need to track this ID
					overlayDetail.itemName = renameId.newId;
					overlayDetail.overlayId = getNewId(overlayDetail.overlayId);
					overlayDetail.mediaId = getNewId(overlayDetail.mediaId);
				}
				
				for each (var channel:Channels in _channels)
				{
					renameId = new RenameId(channel.itemName, RenameId.CHANNEL);	
					_renameIds[channel.itemName] = renameId;
					channel.itemName = renameId.newId;		
					channel.firstMediaId = getNewId(channel.firstMediaId);
				}
	
				for each(var channelDetail:ChannelDetail in _channelDetail)
				{
					renameId = new RenameId(channelDetail.itemName, "");	
					channelDetail.itemName = renameId.newId;
					channelDetail. channelId = _renameIds[channelDetail. channelId].newId;
					channelDetail.mediaId = _renameIds[channelDetail.mediaId].newId;
					channelDetail.firstMediaId = getNewId(channelDetail.firstMediaId);
			}
				
				postRunProcess();
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.ERROR,  err.message, false);				
			}
		}
		
		private function getNewId(oldId:String):String
		{
			try
			{
				if (oldId == "") {return "";}
				return _renameIds[oldId].newId;
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
			
			return "";
		}
		
		private function configCopyMedia():void
		{
			// Dump the media ids only into an array.
			// That is what we need to copy
			_mediaIds = new Array();
			for each (var renameId:RenameId in _renameIds)
			{
				if (renameId.type == RenameId.MEDIA) {_mediaIds.push(renameId);}
			}
			
			postRunProcess();
		}
		
		private function copyThumbs():void
		{
			// Start the download process
			_mediaIndex = -1;			
			copyThumbProcess(null);
		}
		
		private function copyThumbProcess(event:S3Event):void
		{
			try
			{
				if (event != null)
				{
					if (!event.success)
					{
						// We'll skip failures for the thumbnails. We can survive without them
					}
				}
				
				_mediaIndex ++;
				if (_mediaIndex >= _mediaIds.length)
				{
					postRunProcess();
					return;
				}
				
				// Copy this thumbnail
				var renameId:RenameId = _mediaIds[_mediaIndex];
				var fromBucket:String = _copyAccount.bucket;
				var toBucket:String = _appManager.currentAccount.bucket;
				var fromThumb:String = Constants.THUMB_PREFIX + renameId.oldId + Constants.THUMB_EXTENSION;
				var toThumb:String = Constants.THUMB_PREFIX + renameId.newId + Constants.THUMB_EXTENSION;
				
				_appManager.s3.copyFile(fromBucket, fromThumb, toBucket, toThumb, copyThumbProcess, S3Class.ACL_PUBLIC_READ);
				sendEvent(InstallEvent.INFO, "Copying thumb for " + renameId.displayName);
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.ERROR,  err.message, false);						
			}
		}

		private function copyMedia():void
		{
			// Start the download process
			_mediaIndex = -1;			
			copyMediaProcess(null);
		}
		
		private function copyMediaProcess(event:S3Event):void
		{
			try
			{
				if (event != null)
				{
					if (!event.success)
					{
						sendEvent(InstallEvent.ERROR, event.message, false);
						return;
					}
				}
				
				_mediaIndex ++;
				if (_mediaIndex >= _mediaIds.length)
				{
					postRunProcess();
					return;
				}
				
				// Copy this thumbnail
				var renameId:RenameId = _mediaIds[_mediaIndex];
				var fromBucket:String = _copyAccount.bucket;
				var toBucket:String = _appManager.currentAccount.bucket;
				var fromFile:String = renameId.oldId;
				var toFile:String = renameId.newId;
				
				_appManager.s3.copyFile(fromBucket, fromFile, toBucket, toFile, copyMediaProcess);
				sendEvent(InstallEvent.INFO, "Copying " + renameId.displayName);
			}
			catch (err:Error)
			{
				sendEvent(InstallEvent.ERROR,  err.message, false);						
			}
		}
		
		private function updateMedias():void
		{
			_appManager.sdb.updateDomain(_medias, runProcess);
		}

		private function updateMediaGroups():void
		{
			_appManager.sdb.updateDomain(_mediaGroups, runProcess);
		}

		private function updateMediaGroupDetail():void
		{
			_appManager.sdb.updateDomain(_mediaGroupDetail, runProcess);
		}

		private function updateOverlays():void
		{
			_appManager.sdb.updateDomain(_overlays, runProcess);
		}

		private function updateOverlayDetail():void
		{
			_appManager.sdb.updateDomain(_overlayDetail, runProcess);
		}

		private function updateChannels():void
		{
			_appManager.sdb.updateDomain(_channels, runProcess);
		}

		private function updateChannelDetail():void
		{
			_appManager.sdb.updateDomain(_channelDetail, runProcess);
		}

		private function updateAccount():void
		{
			_appManager.currentAccount.sampleContent = "1";
			_appManager.currentAccount.updated = true;
			_appManager.currentAccount.modifiedBy = _appManager.currentUser.itemName;
			_appManager.currentAccount.modifiedDate = new Date();
			
			_appManager.sdb.updateDomain([_appManager.currentAccount], runProcess);
		}

	}
}