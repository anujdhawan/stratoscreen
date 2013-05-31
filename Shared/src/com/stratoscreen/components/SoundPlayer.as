package com.stratoscreen.components
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.ProgressEvent;
	import flash.events.SampleDataEvent;
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundLoaderContext;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	
	public class SoundPlayer extends EventDispatcher
	{
		public static const SOUND_START:String = "SOUND_START";
		public static const SOUND_END:String = "SOUND_END";
		public static const SOUND_PROGRESS:String = "SOUND_PROGRESS";
		
		private var _source:String;
		private var _sound:Sound;
		private var _soundChannel:SoundChannel;
		private var _percentLoaded:Number;
		private var _playing:Boolean = false;
		private var _firstProgress:Boolean = false;
		private var _stopTimer:Timer;
		
		public function SoundPlayer(source:String)
		{			
			super(null);
			_source = source;
			
			_sound = new Sound();			
			_sound.addEventListener(Event.COMPLETE, loadCompleteHandler, false, 0, true);
			_sound.addEventListener(IOErrorEvent.IO_ERROR, loadCompleteHandler, false, 0, true);
			_sound.addEventListener(ProgressEvent.PROGRESS, loadProgressHandler, false, 0, true);
			_sound.addEventListener(SampleDataEvent.SAMPLE_DATA, sampleDataHandler, false, 0, true);
		}
		
		public function get percentLoaded():Number
		{
			return _percentLoaded;
		}
		
		public function play():void
		{
			if (!_playing)
			{
				var context:SoundLoaderContext = new SoundLoaderContext(3000, false);
				_sound.load(new URLRequest(_source), context);			
	
				_soundChannel = _sound.play();
				_soundChannel.addEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
				_playing = true;
				_firstProgress = false;
			}
		}
		
		public function stop(fadeOut:Boolean = true):void
		{
			_playing = false;

			if (_soundChannel == null || !fadeOut)
			{
				dispose();
			}
			else				
			{
				_stopTimer = new Timer(100);
				_stopTimer.addEventListener(TimerEvent.TIMER, fadeoutHandler);
				_stopTimer.start();
			}
		}
		
		private function fadeoutHandler(event:TimerEvent):void
		{
			try
			{
				var volume:Number = _soundChannel.soundTransform.volume;
				volume -= 0.1;
				
				if (volume <=0) 
				{
					dispose();
				}
				else
				{
					_soundChannel.soundTransform = new SoundTransform(volume);
				}
			}
			catch (err:Error)
			{
				trace(err.message);				
				SoundMixer.stopAll();
				dispose();
			}
		}
		
		private function dispose():void
		{
			if (_stopTimer != null)
			{
				_stopTimer.stop();
				_stopTimer.removeEventListener(TimerEvent.TIMER, fadeoutHandler);
				_stopTimer = null;
			}

			if (_soundChannel != null)
			{
				_soundChannel.stop();
				_soundChannel.removeEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
			}
			

			if (_sound != null)
			{
				_sound.removeEventListener(Event.COMPLETE, loadCompleteHandler);
				_sound.removeEventListener(IOErrorEvent.IO_ERROR, loadCompleteHandler);
				_sound.removeEventListener(ProgressEvent.PROGRESS, loadProgressHandler);
				_sound.removeEventListener(SampleDataEvent.SAMPLE_DATA, sampleDataHandler);
				try
				{
					_sound.close();
				}
				catch (err:Error) {/* ignore errors */}
			}
		}
		
		private function loadCompleteHandler(event:Event):void
		{
		}
			
		private function sampleDataHandler(event:Event):void
		{
			this.dispatchEvent(new Event(SOUND_START));
		}
		
		private function soundCompleteHandler(event:Event):void
		{
			this.dispatchEvent(new Event(SOUND_END));
		}	
		
		private function loadProgressHandler(event:ProgressEvent):void
		{
			_percentLoaded = event.bytesLoaded / event.bytesTotal;
			this.dispatchEvent(new Event(SOUND_PROGRESS));
			
			// I am having trouble determining the actual start of the media. 
			if (!_firstProgress)
			{
				_firstProgress = true;
				this.dispatchEvent(new Event(SOUND_START));
			}
		}
		
	}
}