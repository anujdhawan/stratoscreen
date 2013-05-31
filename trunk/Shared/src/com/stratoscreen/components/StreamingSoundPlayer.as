package com.stratoscreen.components
{
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class StreamingSoundPlayer extends EventDispatcher
	{
		public static const SOUND_CONNECT:String = "SOUND_CONNECT";
		public static const SOUND_START:String = "SOUND_START";
		public static const SOUND_END:String = "SOUND_END";
		
		private static var _netConnect:NetConnection_ = null; 
		private var _source:String;
		private var _server:String;
		private var _file:String;
		private var _loop:Boolean = false;
		private var _autoPlay:Boolean = true;
		private var _stream:NetStream_;
		private var _startTime:Number;
		private var _endTime:Number;
		
		public function StreamingSoundPlayer(source:String, loop:Boolean = false, startTime:Number = 0, endTime:Number = 0,
									autoPlay:Boolean = true )
		{			
			super(null);
			_loop = loop;
			_autoPlay = autoPlay;
			_source = source;		
			_startTime = startTime;
			_endTime = endTime;
			
			// Assume the client and the player has a NetConnection object
			// It will be reused
			
			// Convert the URL into two files so we can stream 
			// Assume the url looks like this rtmp://s68ld5hvjn4o7.cloudfront.net/cfx/st/file.mp3
			var sections:Array = _source.split("/");
			var file:String = sections[sections.length - 1];
			
			_server = "";
			for (var i:int = 0; i < sections.length - 1; i++)
			{
				_server += sections[i];
				
				// Do not include the trailing slash in the server address 
				if ( i < sections.length - 2) {_server += "/";}				
			}
			
			// Convert the File name from "file.mp3" to mp3:file"
			sections = file.split(".");	// Assume one and only one period
			_file = sections[1] + ":" + sections[0];
			
			// Do we need to connect to the server or do we have a connection to use
			var _connect:NetConnection_ = _netConnect;				
			var connected:Boolean = false;			
			if (_connect != null )
			{
				connected = _netConnect.connected;	
			}
			
			if (connected)
			{
				// Start playing the sound we have a connection
				if (_autoPlay) {play();}
				
				// Post the connect event with an timer. We do not have the callLater function
				var timerPost:Timer = new Timer(100, 1);
				timerPost.addEventListener(TimerEvent.TIMER, onPostTimer);
				timerPost.start();
			}
			else
			{
				_connect = new NetConnection_();
				_connect.connect(_server);
				_connect.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				_connect.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
				_connect.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncError);
			}
		}
		
		private function onPostTimer(event:TimerEvent):void
		{
			event.target.addEventListener(TimerEvent.TIMER, onPostTimer);
			this.dispatchEvent(new Event(SOUND_CONNECT));			
		}
		
		public function play():void
		{
			stop();
			
			_stream = new NetStream_(_netConnect);
			_stream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus, false, 0, true);
			_stream.addEventListener(NetStream_.PLAY_COMPLETE, onPlayComplete, false, 0, true);
			if (_startTime > 0) {_stream.seek(_startTime);}
			_stream.play(_file);
		}
		
		public function stop():void
		{
			if (_stream != null) 
			{
				_stream.close();
				_stream.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
				_stream.removeEventListener(NetStream_.PLAY_COMPLETE, onPlayComplete);
			}
		}
		
		private function onPlayComplete(event:Event):void
		{
			if (_loop)
			{
				play();	
			}
			else
			{
				this.dispatchEvent(new Event(SOUND_END));
			}
		}
		
		private function onAsyncError(event:Event):void
		{
			trace("ASYNC Error");
		}
		
		private function onIOError(event:Event):void
		{
			trace("IO Error");
		}		
		
		private function onNetStatus(event:NetStatusEvent):void
		{
			if (event.info != null)
			{
				if (event.info.code != null)
				{
					switch (event.info.code.toString())
					{
						case "NetConnection.Connect.Success":
							_netConnect = event.target as NetConnection_;
							this.dispatchEvent(new Event(SOUND_CONNECT));
							if (_autoPlay) {play();}
							break
						
						case "NetStream.Buffer.Flush":
							break;							
						
						case "NetStream.Buffer.Full":
							break;							
						
						case "NetStream.Buffer.Empty":
							this.dispatchEvent(new Event(SOUND_END));
							break;
						
						case "NetStream.Play.Reset":
							break;
						
						case "NetStream.Play.Start":
							this.dispatchEvent(new Event(SOUND_START));
							break;
						
						case "NetStream.Play.Stop":
							break;
						
						default:
							trace(event.info.code);
							break;
					}	
				}				
			}
		}
	}
}