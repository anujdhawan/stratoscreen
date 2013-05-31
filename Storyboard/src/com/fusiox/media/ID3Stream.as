package com.fusiox.media
{
	import flash.net.URLStream;
	import flash.net.URLRequest;
	import flash.events.ProgressEvent;
	import com.fusiox.media.ID3Reader;
	import flash.utils.ByteArray;
	import flash.events.Event;

	[Event(Event.ID3)]
	public class ID3Stream extends URLStream
	{
		public var id3length:uint = 0;
		public var reader:ID3Reader = new ID3Reader();
		private var _close:Boolean = true;
		private var _bytes:ByteArray = new ByteArray();
		
		
		public function ID3Stream(request:URLRequest=null, close:Boolean=true):void {
			_close = close;
			if (request) { load(request); }
			addEventListener(ProgressEvent.PROGRESS, onID3Progress);
		}
		
		private function onID3Progress( e:ProgressEvent ):void {
			if (length == 0) 
			{ 
				getID3Length(); 
			}
			
			if (bytesAvailable >= length) 
			{
				readBytes(_bytes,10,bytesAvailable);
				if (_close) { close(); }
				reader.addEventListener(Event.ID3, onID3Loaded);
				removeEventListener(ProgressEvent.PROGRESS, onID3Progress);
				reader.load(_bytes);
			}
			else
			{
				trace("");
			}
		}
		
		private function onID3Loaded( e:Event ):void {
			dispatchEvent(new Event(Event.ID3));
		}
		
		private function getID3Length():void {
			if( length == 0 && bytesAvailable >= 10) {
				readBytes(_bytes,0,10);
				if (_bytes.readUTFBytes(3).toUpperCase()=="ID3") {
					_bytes.readByte();
					_bytes.readByte(); // storing tag version
					_bytes.readByte(); // storing flags byte
					id3length = _bytes.readInt();
				} else { trace("error"); }
			}
		}
		
	}
}