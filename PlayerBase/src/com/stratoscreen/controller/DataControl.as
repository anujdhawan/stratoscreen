package com.stratoscreen.controller
{
	import com.stratoscreen.PlayerConstants;
	import com.stratoscreen.aws.SDBEvent;
	import com.stratoscreen.events.StepEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.managers.DataManager;
	import com.stratoscreen.managers.FilesManager;
	import com.stratoscreen.model.Step;
	import com.stratoscreen.model.domains.*;
	import com.stratoscreen.model.views.*;
	import com.stratoscreen.model.views.AccountHdr;
	import com.stratoscreen.model.views.SettingsHdr;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.SharedUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.utils.StringUtil;
	
	public class DataControl  extends EventDispatcher
	{
		
		private var _appManager:AppManager;
		private var _dataManager:DataManager;
		private var _filesManager:FilesManager;
		private var _steps:Array;
		private var _stepIndex:int;
		private var _version:int;
		private var _stopProcess:Boolean = false;
		private var _maxRetries:int;
		private var _retryCount:int;

		public function DataControl(appManager:AppManager, dataManager:DataManager, retryCount:int = 2 )
		{
			_appManager = appManager;
			_dataManager = dataManager;
			_maxRetries = retryCount;
		}
		
		public function start(clean:Boolean = false, version:int = 1):void
		{			
			_version = version;
			_stopProcess = false;
			
			_steps = new Array();
			if (clean) {_steps.push(new Step("Preparing", cleanInstall));}
			_steps.push(new Step("Synchronizing settings header", querySettingsTable, querySettingsHandler ));
			_steps.push(new Step("Synchronizing account header", queryAccountTable, queryAccountHandler ));
			_steps.push(new Step("Synchronizing screen table", queryScreenTable, queryScreenHandler ));
			_steps.push(new Step("Synchronizing channels table", queryChannelsTable, queryChannelsTableHandler ));
			_steps.push(new Step("Synchronizing channel details table", queryChannelDetailTable, queryChannelDetailTableHandler ));
			_steps.push(new Step("Synchronizing medias table", queryMediasTable, queryMediasHandler ));
			_steps.push(new Step("Synchronizing media groups table", queryMediaGroupsTable, queryMediaGroupsHandler ));
			_steps.push(new Step("Synchronizing media group detail table", queryMediaGroupDetailTable, queryMediaGroupDetailHandler ));
			_steps.push(new Step("Synchronizing overlays table", queryOverlaysTable, queryOverlaysHandler ));
			_steps.push(new Step("Synchronizing overlay detail table", queryOverlayDetailTable, queryOverlayDetailHandler ));
			_steps.push(new Step("Synchronizing schedule table", queryScheduleTable, queryScheduleHandler ));
			_steps.push(new Step("Synchronizing schedule detail table", queryScheduleDetailTable, queryScheduleDetailHandler ));
			_steps.push(new Step("Committing", commit));

			_stepIndex = -1;
			runProcess();
		}
		
		public function stop():void
		{
			_stopProcess = true;
		}
		
		private function runProcess(event:Object = null):void
		{
			// If we have a timer event treat as null
			if (event is TimerEvent)
			{
				event.target.removeEventListener(TimerEvent.TIMER, runProcess);
				event = null;
			}
			
			// We encountered an error or a non registered event
			if (_stopProcess) {	return;	}

			var step:Step;
			if (event != null)
			{				
				step = _steps[_stepIndex] as Step;
				if (!event.success)
				{
					var errorType:int =  StepEvent.ERROR;
					var errorId:int = event is SDBEvent ? event.errorId : 0;
					
					// Rerun the step if it failed
					if (_retryCount < _maxRetries)
					{
						runStepProcess();
						_retryCount ++;
						return;
					}
					
					if (!step.stopOnFail) {errorType = StepEvent.WARNING;}
					
					sendEvent(errorType, event.message == ""? "Operation failed" : event.message, _stepIndex, _steps.length, errorId );
					if (step.stopOnFail) {return;}	
				}
				
				// Run any follow up functions
				if (step.completeHandler != null) 
				{
					step.completeHandler(event);
				}
			}
			
			_stepIndex ++;		
			_retryCount = 0;
			if (_stepIndex >= _steps.length)
			{
				sendEvent(StepEvent.COMPLETE, "",  _steps.length, _steps.length);
				return;
			}
			
			runStepProcess();
		}
		
		private function runStepProcess():void
		{
			var step:Step = _steps[_stepIndex] as Step;
			sendEvent(StepEvent.INFO, step.startMessage, _stepIndex, _steps.length);
			
			// Call the next function. We may have to pass an argument to the function
			if (step.argument == null)
			{
				step.func();		
			}
			else
			{
				step.func(step.argument)
			}		
		}
		
		private function sendEvent(errorType:int, message:String, step:int = 0, totalSteps:int = 1, errorId:int = 0):void
		{
			var event:StepEvent = new StepEvent(errorType, message);
			event.percent = step/totalSteps;
			event.isMedia = false;
			event.errorId = errorId;
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
		
		private function commit():void
		{
			_dataManager.commit(_version);
			
			
			postRunProcess();
		}
		
		private function cleanInstall():void
		{
			_filesManager.clean();
			
			postRunProcess();
		}

		private function querySettingsTable():void
		{
			var sql:String = "Select keyPairId, keyPairPart1, keyPairPart2  from Settings";
			_appManager.sdb.select(sql, runProcess, SettingsHdr);
		}
		
		private function querySettingsHandler(event:SDBEvent):void
		{
			try
			{
				// Assume we only get one row				
				_dataManager.settingsHdr = event.result[0];				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}

		private function queryAccountTable():void
		{
			var sql:String = "Select name, streaming, streamDomain, bucket from Accounts where itemName()='" +  _dataManager.screenSettings.accountId + "'";
			_appManager.sdb.select(sql, runProcess, AccountHdr);
		}
		
		private function queryAccountHandler(event:SDBEvent):void
		{
			try
			{
				// If we receive a zero length, the screen was probably deleted
				if (event.result.length == 0)
				{
					sendEvent(StepEvent.NOT_REGISTERED, "Account ID " + _dataManager.screenSettings.accountId + " not found");
					_stopProcess = true;
					return;
				}
				
				_dataManager.accountHdr = event.result[0];				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
		
		private function queryScreenTable():void
		{
			// We will not have the screen ID if this is a first time install
			var firstTime:Boolean = false;
			if (_dataManager.screenSettings.screenId == null || 
			    StringUtil.trim(_dataManager.screenSettings.screenId) == "")
			{
				firstTime = true;
			}
			
			var sql:String = "Select * from Screens where ";
			if (firstTime)
			{
				sql += "code = '" + _dataManager.screenSettings.code + "'";
				sql += "and accountId = '" + _dataManager.screenSettings.accountId + "'";				 
			}
			else
			{
				sql += "itemName()='" + _dataManager.screenSettings.screenId + "' "	
			}
				
			_appManager.sdb.select(sql, runProcess, Screens);
		}
		
		private function queryScreenHandler(event:SDBEvent):void
		{
			try
			{
				// If we receive a zero length, the screen was probably deleted
				if (event.result.length == 0)
				{
					sendEvent(StepEvent.NOT_REGISTERED, "Screen ID " + _dataManager.screenSettings.screenId + " not found");
					_stopProcess = true;
					return;
				}

				_dataManager.screen_ = event.result[0];			
				
				// Save to the screen settings too. This will be blank on first install
				if (_dataManager.screenSettings.screenId == null || 
					StringUtil.trim(_dataManager.screenSettings.screenId) == "")
				{
					_dataManager.screenSettings.screenId = _dataManager.screen_.itemName;
				}
				
				// Update the user control too
				if (_dataManager.screen_.userControl != "1")
				{
					SharedUtils.setValue(PlayerConstants.USER_CHANNEL_ID, "");
				}

			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
		
		
		private function queryChannelsTable():void
		{
			var sql:String = "Select * from Channels where accountId = '" + _dataManager.screenSettings.accountId + "'";
			_appManager.sdb.select(sql, runProcess, Channels );
		}
		
		private function queryChannelsTableHandler(event:SDBEvent):void
		{
			try
			{
				_dataManager.channels = event.result as Array;				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
		
		private function queryChannelDetailTable():void
		{
			var sql:String = "Select * from ChannelDetail where accountId = '" + _dataManager.screenSettings.accountId + "'";
			_appManager.sdb.select(sql, runProcess, ChannelDetail );
		}
		
		private function queryChannelDetailTableHandler(event:SDBEvent):void
		{
			try
			{
				_dataManager.channelDetail = event.result as Array;				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}

		private function queryMediasTable():void
		{
			var sql:String = "Select * from Medias where accountId = '" + _dataManager.screenSettings.accountId + "'";
			_appManager.sdb.select(sql, runProcess, Medias );
		}
		
		private function queryMediasHandler(event:SDBEvent):void
		{
			try
			{
				_dataManager.medias = event.result as Array;				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
		
		private function queryMediaGroupsTable():void
		{
			var sql:String = "Select * from MediaGroups where accountId = '" + _dataManager.screenSettings.accountId + "'";
			_appManager.sdb.select(sql, runProcess, MediaGroups );
		}
		
		private function queryMediaGroupsHandler(event:SDBEvent):void
		{
			try
			{
				_dataManager.mediaGroups = event.result as Array;				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}		
		
		private function queryMediaGroupDetailTable():void
		{
			var sql:String = "Select * from MediaGroupDetail where accountId = '" + _dataManager.screenSettings.accountId + "'";
			_appManager.sdb.select(sql, runProcess, MediaGroupDetail );
		}
		
		private function queryMediaGroupDetailHandler(event:SDBEvent):void
		{
			try
			{
				_dataManager.mediaGroupDetail = event.result as Array;				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}		
		
		private function queryOverlaysTable():void
		{
			var sql:String = "Select * from Overlays where accountId = '" + _dataManager.screenSettings.accountId + "'";
			_appManager.sdb.select(sql, runProcess, Overlays);
		}
		
		private function queryOverlaysHandler(event:SDBEvent):void
		{
			try
			{
				_dataManager.overlays = event.result as Array;				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}

		private function queryOverlayDetailTable():void
		{
			var sql:String = "Select * from OverlayDetail where accountId = '" + _dataManager.screenSettings.accountId + "'";
			_appManager.sdb.select(sql, runProcess, OverlayDetail);
		}
		
		private function queryOverlayDetailHandler(event:SDBEvent):void
		{
			try
			{
				_dataManager.overlayDetail = event.result as Array;				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}

		private function queryScheduleTable():void
		{
			var sql:String = "Select * from Schedules where itemName()='" + _dataManager.screenSettings.screenId + "' "
			sql += "and accountId = '" + _dataManager.screenSettings.accountId + "'";
			_appManager.sdb.select(sql, runProcess, Schedules);
		}
		
		private function queryScheduleHandler(event:SDBEvent):void
		{
			try
			{
				_dataManager.schedule = event.result as Array;				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
	
		private function queryScheduleDetailTable():void
		{
			var sql:String = "Select * from ScheduleDetail where accountId = '" + _dataManager.screenSettings.accountId + "' ";
			sql += "and scheduleId = '" + _dataManager.screenSettings.screenId + "' ";
			_appManager.sdb.select(sql, runProcess, ScheduleDetail);
		}
		
		private function queryScheduleDetailHandler(event:SDBEvent):void
		{
			try
			{
				_dataManager.scheduleDetail = event.result as Array;				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
	}
}