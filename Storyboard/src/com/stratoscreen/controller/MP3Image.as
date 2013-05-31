package com.stratoscreen.controller
{
	import com.fusiox.media.ID3Stream;
	import com.stratoscreen.model.ResizeRectangle;
	import com.stratoscreen.utils.ImageUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	
	/**
	 * 
	 * @author pjsteele
	 * 
	 * @see http://blog.benstucki.net/?p=3
	 */
	public class MP3Image extends EventDispatcher
	{	
		public static const MAX_THUMB_SIZE:int = 64;
		public static const MP3_INFO_COMPLETE:String = "MP3_INFO_COMPLETE";
		public static const MP3_INFO_ERROR:String = "MP3_INFO_ERROR";

		private var _timeOut:Timer;
		private var _success:Boolean = false;
		private var _bitmapData:BitmapData = null;
		private var _loader:Loader;
		private var _stream:ID3Stream;

		public function get success():Boolean
		{
			return _success;
		}
		
		public function MP3Image(target:IEventDispatcher=null)
		{
			super(target);
		}

		public function get bitmapData():BitmapData
		{
			return _bitmapData;
		}
		
		public function load(url:String):void 
		{
			_stream = new ID3Stream( new URLRequest(url) );
			_stream.addEventListener(Event.ID3, id3LoadHandler);
			_stream.addEventListener(ProgressEvent.PROGRESS, id3ProgressHandler);	
			
			// Watch for files that never complete
			_timeOut = new Timer(2000);
			_timeOut.addEventListener(TimerEvent.TIMER, timeOutHandler);
			_timeOut.start();
		}
		
		private function id3ProgressHandler( event:ProgressEvent ):void 
		{
			
		}
		private function id3LoadHandler( event:Event ):void 
		{
			// Abort if we do not have an MP3
			if (event.target.reader.img.length == 0)
			{
				_timeOut.stop();
				_success = false;
				_bitmapData = null;
				this.dispatchEvent(new Event(MP3_INFO_ERROR));
				return;
			}
			
			// Load the image into another loader so it will convert
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderCompleteHandler);
			_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
			_loader.loadBytes(event.target.reader.img);
		}
		
		private function loaderCompleteHandler(event:Event):void
		{
			try
			{
				_bitmapData = (event.target.content.bitmapData as BitmapData);
				if (_bitmapData.width > MAX_THUMB_SIZE || _bitmapData.height > MAX_THUMB_SIZE)
				{
					var rect:ResizeRectangle = ImageUtils.reSizetoMax(_bitmapData.width, _bitmapData.height, MAX_THUMB_SIZE);
					
					var matrix:Matrix = new Matrix();
					matrix.scale(rect.scaleX, rect.scaleY);
					
					var resized:BitmapData = new BitmapData(rect.width, rect.height);
					resized.draw(_bitmapData, matrix);
					
					_bitmapData = resized;					
				}
				
				_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loaderCompleteHandler);
				_loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);		

				_success = true;
				this.dispatchEvent(new Event(MP3_INFO_COMPLETE));
			}
			catch (err:Error)
			{
				_success = false;
				this.dispatchEvent(new Event(MP3_INFO_ERROR));
			}
			finally
			{
				if (_timeOut != null) {_timeOut.stop();}

			}
		}
		
		private function loaderErrorHandler(event:Event):void
		{
			try
			{
				_bitmapData = null;
				_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loaderCompleteHandler);
				_loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);		
					
				_success = false;
				this.dispatchEvent(new Event(MP3_INFO_ERROR));
			}
			finally
			{
				if (_timeOut != null) {_timeOut.stop();}
				
			}
		}	
		
		private function timeOutHandler(event:TimerEvent):void
		{
			_success = false
			_timeOut.stop();
			this.dispatchEvent(new Event(MP3_INFO_ERROR));	
		}
	}
}