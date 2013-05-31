package com.stratoscreen.controller
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.model.ResizeRectangle;
	import com.stratoscreen.model.domains.Medias;
	import com.stratoscreen.utils.ImageUtils;
	import com.stratoscreen.utils.LogUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.*;
	import flash.geom.Matrix;
	import flash.media.ID3Info;
	import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.controls.SWFLoader;
	import mx.controls.VideoDisplay;
	import mx.core.IVisualElement;
	import mx.events.FlexEvent;
	import mx.events.MetadataEvent;
	import mx.events.VideoEvent;
	
	import org.osmf.events.TimeEvent;
	
	import spark.components.Group;
	import spark.core.SpriteVisualElement;
		
	public class MediaInfo extends EventDispatcher
	{
		public static const MEDIA_INFO_COMPLETE:String = "MEDIA_INFO_COMPLETE";
		public static const MEDIA_INFO_ERROR:String = "MEDIA_INFO_ERROR";
		
		[Bindable][Embed(source="assets/images/audio_128.png")]
		private var imageAudio:Class;
		[Bindable][Embed(source="assets/images/video.png")]
		private var imageVideo:Class;
		
		private var _workGroup:Group;	// Make sure this is a blank Group. This function will remove everything
		private var _workSprite:SpriteVisualElement;
		private var _media:Medias = null;		
		private var _success:Boolean = false;
		private var _video:VideoDisplay;
		private var _sound:Sound;
		private var _timeOut:Timer;
		
		public function MediaInfo(workGroup:Group)
		{
			_workGroup = workGroup;
			
			// Look or a SpriteVisualElement if it is not found create one
			for (var i:int = 0; i < _workGroup.numElements; i++)
			{
				var element:IVisualElement = _workGroup.getElementAt(i);
				if (element is SpriteVisualElement)
				{
					_workSprite = element as SpriteVisualElement;
					break;
				}
			}
			
			if (_workSprite == null)
			{
				_workSprite = new SpriteVisualElement();
				_workGroup.addElement(_workSprite);
			}
			
			_workSprite.addEventListener(Event.ADDED, swfCompleteHandler);
			
			super(null);
		}
		
		public function get media():Medias
		{
			return _media;
		}
		
		public function get success():Boolean
		{
			return _success;
		}
		
		public function updateMedia(media:Medias):void
		{
			_media = media;
		
			// Use a simple SwfLoader to load the image 
			// so we can get the size and create the thumnbail
			switch (_media.mediaType)
			{
				case Constants.MEDIA_TYPE_IMAGE:
					var swfLoader:SWFLoader = new SWFLoader();
					swfLoader.addEventListener(Event.COMPLETE, swfCompleteHandler);
					swfLoader.addEventListener(IOErrorEvent.IO_ERROR, swfIOErrorHandler);
					swfLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, swfSecurityError);
					swfLoader.source = File(media.file).url;
					_workGroup.addElement(swfLoader);
					break;

				case Constants.MEDIA_TYPE_SWF:
					// Avoid Stage issues and load the swf as a byte array
					var bytes:ByteArray = new ByteArray();
					var file:File = new File( File(media.file).nativePath);
					var stream:FileStream = new FileStream();
					stream.open(file, FileMode.READ);					
					stream.readBytes(bytes, 0, stream.bytesAvailable);
					stream.close();

					var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
					context.allowCodeImport = true;
					
					var loader:Loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, contentCompleteHandler);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, contentIOErrorHandler);
					loader.loadBytes(bytes, context);					

					
				case Constants.MEDIA_TYPE_VIDEO:
					_video = new VideoDisplay();
					_video.addEventListener(VideoEvent.STATE_CHANGE, videoStateChangeHandler);
					_video.addEventListener(VideoEvent.READY, videoCompleteHandler);	
					_video.addEventListener(MetadataEvent.METADATA_RECEIVED, videoMetaDataHandler);
					_video.source = File(media.file).url;
					_workGroup.addElement(_video);
					break;
				
				case Constants.MEDIA_TYPE_AUDIO:
					_sound = new Sound();
					_sound.addEventListener(Event.COMPLETE, audioCompleteHandler);
					_sound.load( new URLRequest(File(media.file).url));
			}
			
			// Watch for files that never complete
			_timeOut = new Timer(2000);
			_timeOut.addEventListener(TimerEvent.TIMER, timeOutHandler);
			_timeOut.start();
		}
		
		public function stopTimeout():void
		{
			if (_timeOut != null) {_timeOut.stop();}
		}
				
		protected function swfCompleteHandler(event:Event):void
		{
			try
			{
				try
				{
					_media.width = event.target.content.loaderInfo.width;
					_media.height = event.target.content.loaderInfo.height;
				}
				catch (err:Error)
				{
					// Just default to height and width 
					_media.width = event.target.content.width;
					_media.height = event.target.content.height;					
				}
				
				// Try and get the frames
				try
				{
					_media.frames = event.target.content.totalFrames;
					_media.duration = "0";
					
					// If this is very short use the default. i.e. Less than on second
					if (parseInt(_media.frames) < 24)
					{
						_media.frames = "0";
						_media.duration = Constants.DEFAULT_DURATION;
					}
				}
				catch (err:Error)
				{
					// If we cannot frames defaulf the default time 
					_media.frames = "0";
					_media.duration = Constants.DEFAULT_DURATION;
				}				
	
				// Create the thumbnail for bitmaps
				var rect:ResizeRectangle;
				var matrix:Matrix = new Matrix();
				if (event.target.content is Bitmap)
				{
					// Scale the image to a better thumbnail
					var bitmap:Bitmap = event.target.content;
					rect = ImageUtils.reSizetoMax( bitmap.bitmapData.width, bitmap.bitmapData.height);
					
					matrix.scale(rect.scaleX, rect.scaleY);
					_media.thumbBmpData = new BitmapData(rect.width, rect.height, true);
					_media.thumbBmpData.draw(bitmap, matrix, null, null, null, true);
				}
				else
				{
					// Assume this is a SWF
					var swfWidth:Number = event.target.content.loaderInfo.width;
					var swfHeight:Number = event.target.content.loaderInfo.height;
					rect = ImageUtils.reSizetoMax(swfWidth, swfHeight);

					matrix.scale(rect.scaleX, rect.scaleY);
					_media.thumbBmpData = new BitmapData(rect.width, rect.height, true);
					_media.thumbBmpData.draw(event.target.content, matrix, null, null, null, true);     
				}
				
				_media.refresh = true;	// Force the MediaItem to redraw
				_success = true;
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err, 2, LogUtils.WARN);
			}
			finally
			{
				this.dispatchEvent(new Event(MEDIA_INFO_COMPLETE));
				removeSwfLoader(event.target);
			}
		}
		
		protected function swfIOErrorHandler(event:IOErrorEvent):void
		{
			LogUtils.writeToLog(event.text, LogUtils.WARN);
			this.dispatchEvent(new Event(MEDIA_INFO_COMPLETE));
			removeSwfLoader(event.target);
		}

		protected function swfSecurityError(event:SecurityErrorEvent):void
		{
			LogUtils.writeToLog(event.text, LogUtils.WARN);
			this.dispatchEvent(new Event(MEDIA_INFO_COMPLETE));
			removeSwfLoader(event.target);			
		}

		
		private function removeSwfLoader(target:Object):void
		{
			try
			{
				target.removeEventListener(Event.COMPLETE, swfCompleteHandler);
				target.removeEventListener(IOErrorEvent.IO_ERROR, swfIOErrorHandler);
				target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, swfSecurityError);
				
				_workGroup.removeAllElements();
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err, 2, LogUtils.WARN);
			}
		}

		private function contentCompleteHandler(event:Event):void
		{
			try
			{
				event.target.removeEventListener(Event.COMPLETE, contentCompleteHandler);
				event.target.removeEventListener(IOErrorEvent.IO_ERROR, contentIOErrorHandler);
				
				_workSprite.addChild(event.target.loader as DisplayObject);
								
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err, 2, LogUtils.WARN);
			}
		}
		
		private function contentIOErrorHandler(event:Event):void
		{
			event.target.removeEventListener(Event.COMPLETE, contentCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, contentIOErrorHandler);
			
			this.dispatchEvent(new Event(MEDIA_INFO_COMPLETE));
			_workGroup.removeAllElements();
		}
		
		protected function videoCompleteHandler(event:Event):void
		{
			try
			{
				_media.width = _video.videoWidth.toString();
				_media.height = _video.videoHeight.toString();
				_video.stop();
				
				// If we did not get a height or width we may have a video in the wrong format
				if (_video.videoWidth <= 0 || _video.videoHeight <= 0)
				{
					_media.refresh = false
					_success = false;
					return;					
				}
				
				// Use an embedded video bitmap
				var thumb:Bitmap = new imageVideo();
				_media.thumbBmpData = thumb.bitmapData;
				
				_media.refresh = true;	// Force the MediaItem to redraw
				_success = true;
			}			
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err,2, LogUtils.WARN);
			}
			finally
			{
				this.dispatchEvent(new Event(MEDIA_INFO_COMPLETE));
				removeVideoDisplay();
			}
		}
		
		private function videoMetaDataHandler(event:MetadataEvent):void
		{
			_media.calcDuration = parseInt(event.info.duration).toString();
		}
		
		protected function audioCompleteHandler(event:Event):void
		{
			try
			{
				_media.width = "50";	// Just add something so the thumbnails will draw
				_media.height = "50";
				_media.duration = "0"	// Make the default to play to enbd
				_media.calcDuration = (_sound.length/ 1000).toFixed(0).toString();
				
				// Use an embedded video bitmap
				var thumb:Bitmap = new imageAudio();
				_media.thumbBmpData = thumb.bitmapData;
				_media.refresh = true;	// Force the MediaItem to redraw
			
				// Add a better name if possible
				var id3:ID3Info = event.target.id3 as ID3Info;
				if (id3 != null)
				{
					var songName:String = id3.songName;
					var artist:String = id3.artist;				
					if (songName != null && artist != null) {_media.name = 	songName + " - " + artist;}
				}

				_success = true;				
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err,2, LogUtils.WARN);
				_success = false;				
			}
			finally
			{
				_sound.removeEventListener(Event.COMPLETE, audioCompleteHandler);
				this.dispatchEvent(new Event(MEDIA_INFO_COMPLETE));
			}
		}
		
		private function videoStateChangeHandler(event:Event):void
		{
		}
		
		protected function videoErrorHandler(event:Event):void
		{
			this.dispatchEvent(new Event(MEDIA_INFO_COMPLETE));
			removeSwfLoader(event.target);
		}


		private function removeVideoDisplay():void
		{
			try
			{
				_video.removeEventListener(VideoEvent.READY, videoCompleteHandler);
				
				_workGroup.removeAllElements();
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err, 2, LogUtils.WARN);
			}
		}
		
		private function timeOutHandler(event:TimerEvent):void
		{
			_success = false
			_timeOut.stop();
			this.dispatchEvent(new Event(MEDIA_INFO_ERROR));	
		}

	}
}