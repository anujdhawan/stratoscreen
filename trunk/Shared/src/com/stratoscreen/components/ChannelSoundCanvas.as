package com.stratoscreen.components
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.model.ScreenSubset;
	import com.stratoscreen.model.domains.ChannelDetail;
	import com.stratoscreen.model.domains.Medias;
	import com.stratoscreen.utils.Utils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	
	public class ChannelSoundCanvas extends EventDispatcher
	{
		private var _index:int;
		private var _subIndex:int;
		private var _details:ArrayCollection;
		private var _soundPlayer:SoundPlayer;
		private var _appManager:AppManager;
		private var _timer:Timer;
		private var _startTime:Date;
		private var _useTimerForSound:Boolean;
		private var _useSchedule:Boolean;
		private var _isPlayer:Boolean;
		private var _screenSubset:ScreenSubset;
		
		public function ChannelSoundCanvas(appManager:AppManager, subset:ScreenSubset = null)
		{			
			_appManager = appManager;
			_screenSubset = subset;
			
			_timer = new Timer(250);
			_timer.addEventListener(TimerEvent.TIMER, timerHandler);

			super(null);
		}
		
		public function play(details:ArrayCollection, isPlayer:Boolean):void
		{
			_useSchedule = isPlayer;	// Do not filter by days or times when previewing
			_isPlayer = isPlayer;		// Select files differently when in the Player
			
			_index = -1;	// We want to at zero
			_subIndex = 0;	// SubIndexs are treated differently from Index
			_details = details;
			playNextSound();
		}
		
		public function stop():void
		{
			_timer.stop()
			if (_soundPlayer != null) {_soundPlayer.stop();}
		}
		
		/**
		 * Since we do not have a callLater, use a timer to all the events to catch up 
		 */
		private function postPlayNextSound():void
		{
			var timer:Timer = new Timer(250, 1);
			timer.addEventListener(TimerEvent.TIMER, playNextSound);
			timer.start();
		}
		
		private function playNextSound(event:Event = null):void
		{
			// If we have a timer event treat as null
			if (event is TimerEvent)
			{
				event.target.removeEventListener(TimerEvent.TIMER, playNextSound);
				event = null;
			}
			
			// Stop the playing sound
			if (_index >= 0)
			{
				if (_soundPlayer != null) {_soundPlayer.stop(false);}
				
				// Increment based on the type
				switch (_details[_index].type)
				{
					case ChannelDetail.TYPE_MEDIA:
						_index ++;
						break;
					
					case ChannelDetail.TYPE_GROUP:
						_subIndex ++;
						if (_subIndex >= _details[_index].subDetail.length)
						{
							_subIndex = 0;
							_index ++;
						}
						break;
				}
			}
			else
			{
				_index ++;	// start at the first item.
			}
			
			// Restart if we have plyed too much
			// Stop the process if we played too many
			if (_index >= _details.length)
			{
				_index = -1;	
				_subIndex = 0;	
				postPlayNextSound();
				return;
			}
			
			// Get the Media Object from the array
			var media:Medias;
			switch (_details[_index].type)
			{
				case ChannelDetail.TYPE_MEDIA:
					media = convertToMediasObject(_index);
					break;
				
				case ChannelDetail.TYPE_GROUP:
					media = convertToMediasObject(_index, _subIndex);
					break;
			}
		
			// If this is the plater
			var url:String;
			if (_isPlayer)
			{
				url = getLocalUrl(media.itemName);
			}
			else
			{
				var bucket:String = _appManager.currentAccount.bucket
				url = _appManager.s3.getSelectURL(bucket, media.itemName);
			}

			if (_soundPlayer != null)
			{
				_soundPlayer.removeEventListener(SoundPlayer.SOUND_START, soundStartHandler);
				_soundPlayer.removeEventListener(SoundPlayer.SOUND_END, soundEndHandler);
				_soundPlayer = null;
			}
			
			_soundPlayer = new SoundPlayer(url);
			_soundPlayer.addEventListener(SoundPlayer.SOUND_START, soundStartHandler, false, 0, true);
			_soundPlayer.addEventListener(SoundPlayer.SOUND_END, soundEndHandler, false, 0, true);
			_soundPlayer.play();
			
			_useTimerForSound = parseInt(media.duration) > 0;
		}
		
		private function convertToMediasObject(index:int, subIndex:int = 0):Medias
		{
			var media:Medias = null;
			
			switch (_details[index].type)
			{
				case ChannelDetail.TYPE_MEDIA:
					media = Utils.copyClassObject(Medias, _details[index]);
					media.itemName = _details[index].mediaId;
					break;
				
				case ChannelDetail.TYPE_GROUP:
					media = Utils.copyClassObject(Medias, _details[index]);
					media.itemName = _details[index].subDetail[subIndex].mediaId;
					media.duration = _details[index].subDetail[subIndex].duration;
					media.mimeType = _details[index].subDetail[subIndex].mimeType;
					break;
			}
			
			return media;
		}
		
		private function timerHandler(event:TimerEvent):void
		{
			var media:Medias;
			switch (_details[_index].type)
			{
				case ChannelDetail.TYPE_MEDIA:
					media = convertToMediasObject(_index);
					break;
				
				case ChannelDetail.TYPE_GROUP:
					media = convertToMediasObject(_index, _subIndex);
					break;
			}			
			
			
			// Keep track of how long the media has played
			var duration:int = parseInt(media.duration);
			if (duration == 0)	{return;} 	// We are waiting for the media to stop by itself
			
			var now:Date = new Date();
			var milliElapsed:Number = now.time - _startTime.time;
			
			if (milliElapsed > (duration * 1000))
			{
				_timer.stop();
				playNextSound();
			}
		}
		
		private function soundStartHandler(event:Event):void
		{
			if (_useTimerForSound) 
			{
				_startTime = new Date();
				_timer.start();
			}
		}
		
		private function soundEndHandler(event:Event):void
		{
			// Ignore the end if the user asks for the sound to play past the actual duration
			if (!_useTimerForSound) {playNextSound();}
		}	
		
		private function getLocalUrl(mediaId:String):String
		{
			var url:String =  _appManager.mediaFolder().url + "/" +  mediaId;
			return url;
		}
	}
}