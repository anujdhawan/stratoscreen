
package org.bytearray.video
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.StageVideoAvailabilityEvent;
	import flash.events.StageVideoEvent;
	import flash.events.VideoEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.media.StageVideo;
	import flash.media.StageVideoAvailability;
	import flash.media.Video;
	import flash.media.VideoStatus;
	import flash.net.NetStream;
	
	import org.bytearray.video.events.SimpleStageVideoEvent;
	import org.bytearray.video.events.SimpleStageVideoToggleEvent;
	
	/**
	 * The SimpleStageVideo class allows you to leverage StageVideo trough a few lines of ActionScript.
	 * SimpleStageVideo automatically handles any kind of fallback, from StageVideo to video and vice versa.
	 * 
	 * @example
	 * To use SimpleStageVideo, use the following lines :
	 * <div class="listing">
	 * <pre>
	 *
	 * // specifies the size to conform (will always preserve ratio)
	 * sv = new SimpleStageVideo(500, 500);
	 * // dispatched when the NetStream object can be played
	 * sv.addEventListener(Event.INIT, onInit);
	 * // informs the developer about the compositing, decoding and if full GPU states
	 * sv.addEventListener(SimpleStageVideoEvent.STATUS, onStatus);
	 * </pre>
	 * </div>
	 * 
	 * 
	 * @author Thibault Imbert (bytearray.org)
	 * @version 1.1
	 */
	public class SimpleStageVideo extends Sprite
	{		
		private var _available:Boolean;
		private var _stageVideoInUse:Boolean;
		private var _classicVideoInUse:Boolean;
		private var _played:Boolean;
		private var _rc:Rectangle;
		
		private var _videoRect:Rectangle = new Rectangle(0, 0, 0, 0);
		private var _reset:Rectangle = new Rectangle(0, 0, 0, 0);
		
		private var _initEvent:Event = new Event(Event.INIT);
		
		private var _ns:NetStream;
		private var _video:Video;
		private var _sv:StageVideo;
		
		private var _x:int;
		private var _y:int;
		private var _width:int;
		private var _height:int;
		
		public var useAccel:Boolean = true;
		
		/**
		 * 
		 * @param width The width of the screen, the video will fit this maximum width (while preserving ratio)
		 * @param height The height of the screen, the video will fit this maximum height (while preserving ratio)
		 * 
		 */		
		public function SimpleStageVideo(x:int, y:int,width:int, height:int)
		{
			_x = x;
			_y = y;
			_width = width;
			_height = height;
			init();
		}
		
		/**
		 * Forces the switch from Video to StageVideo and vice versa. 
		 * You should not have to use this API but can be useful for debugging purposes.
		 * @param on
		 * 
		 */		
		public function toggle(on:Boolean):void
		{			
			if (on && _available) 
			{
				_stageVideoInUse = true;
				if ( _sv == null && stage.stageVideos.length > 0 )
				{
					_sv = stage.stageVideos[0];
					_sv.addEventListener(StageVideoEvent.RENDER_STATE, onRenderState);
				}
				_sv.attachNetStream(_ns);
				dispatchEvent( new SimpleStageVideoToggleEvent ( SimpleStageVideoToggleEvent.TOGGLE, SimpleStageVideoToggleEvent.STAGEVIDEO ));
				if (_classicVideoInUse)
				{
					stage.removeChild ( _video );
					_classicVideoInUse = false;
				}
			} else 
			{
				if (_stageVideoInUse)
					_stageVideoInUse = false;
				_classicVideoInUse = true;
				_video.attachNetStream(_ns);
				dispatchEvent( new SimpleStageVideoToggleEvent ( SimpleStageVideoToggleEvent.TOGGLE, SimpleStageVideoToggleEvent.VIDEO ));
				stage.addChildAt(_video, 0);
			}
			
			if ( !_played ) 
			{
				_played = true;
				dispatchEvent(_initEvent);
			}
		}
		
		/**
		 * Resizes the video surfaces while always preserving the image ratio.
		 * 
		 */		
		public function resize (width:uint=0, height:uint=0):void
		{	
			// Ignore the resize and use the size determined by the player
			//
			//_width = width, _height = height;
			
			if ( _stageVideoInUse )	
				//_sv.viewPort = getVideoRect(_sv.videoWidth, _sv.videoHeight);
				_sv.viewPort = getVideoRect(_width, _height);
			else 
			{
				/*
				_rc = getVideoRect(_video.videoWidth, _video.videoHeight);
				_video.width = _rc.width;
				_video.height = _rc.height;
				_video.x = _rc.x, _video.y = _rc.y;
				*/
				_video.width = _width;
				_video.height = _height;
				_video.x = _x;
				_video.y = _y;			}
		}
		
		public function dispose():void
		{
			if (_classicVideoInUse)
			{
				if (_video != null) 
				{
					try
					{
						_video.clear();
						
						// Remove the video 
						for (var i:int = this.numChildren -1; i >=0; i--)
						{
							var item:Object = this.getChildAt(i);
							if (item == _video)
							{
								this.removeChild(_video);
								break;
							}
						}

						// Remove the video from stage if it is there 
						if (this.stage != null)
						{
							for (i = this.stage.numChildren -1; i >=0; i--)
							{
								item = this.stage.getChildAt(i);
								if (item == _video)
								{
									this.stage.removeChild(_video);
									break;
								}
							}
						}
					}
					catch (err:Error)
					{
						trace(err.message);
					}
				}
			}
			
			if (_sv != null)
			{
				try
				{
					_ns.close();
					_ns.dispose();
					_sv.viewPort = new Rectangle(0,0,0,0);
					_sv.attachNetStream(null);
					_sv.removeEventListener(StageVideoEvent.RENDER_STATE, onRenderState);
				}
				catch (err:Error)
				{
					trace(err.message);
				}	
			}

			try
			{
				if (stage != null)
				{
					stage.removeEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, onStageVideoAvailable);
				}
			}
			catch (err:Error)
			{
				trace(err.message);
			}	
			
			try
			{
				removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
				removeEventListener(Event.ADDED_TO_STAGE, onAddedToStageView);
				removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			}
			catch (err:Error)
			{
				trace(err.message);
			}
		}
		
		/**
		 * 
		 * @param stream The NetStream to use for the video.
		 * 
		 */		
		public function attachNetStream(stream:NetStream):void
		{
			_ns = stream;
		}
		
		/**
		 * 
		 * @return Returns the internal StageVideo object used if available.
		 * 
		 */		
		public function get stageVideo():StageVideo
		{
			return _sv;
		}
		
		/**
		 * 
		 * @return Returns the internal Video object used as a fallback.
		 * 
		 */		
		public function get video():Video
		{
			return _video;
		}
		
		/**
		 * 
		 * @return Returns the Stage Video availability.
		 * 
		 */		
		public function get available():Boolean
		{
			return _available;
		}
		
		/**
		 * 
		 * 
		 */		
		private function init():void
		{
			addChild(_video = new Video());
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStageView);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */		
		private function onAddedToStage(event:Event):void
		{	
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, onStageVideoAvailable);
			_video.addEventListener(VideoEvent.RENDER_STATE, onRenderState);
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */		
		private function onAddedToStageView(event:Event):void
		{	
			if (_classicVideoInUse)
				stage.addChildAt(_video, 0);
			else if ( _stageVideoInUse )
				_sv.viewPort = _videoRect;
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */		
		private function onRemovedFromStage(event:Event):void
		{
			if ( !contains ( _video ) )
				addChild(_video);
			if ( _sv != null )
				_sv.viewPort = _reset;
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */		
		private function onStageVideoAvailable(event:StageVideoAvailabilityEvent):void
		{
			toggle(_available = (event.availability == StageVideoAvailability.AVAILABLE && this.useAccel));
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */		
		private function onRenderState(event:Event):void
		{
			var hwDecoding:Boolean;
			var status:String = Object(event).status;			
			
			if ( event is VideoEvent )
			{
				hwDecoding = (event as VideoEvent).status == VideoStatus.ACCELERATED;
				dispatchEvent( new SimpleStageVideoEvent ( SimpleStageVideoEvent.STATUS, hwDecoding, false, false,  status ) );
			}else 
			{
				hwDecoding = (event as StageVideoEvent).status == VideoStatus.ACCELERATED;
				dispatchEvent( new SimpleStageVideoEvent ( SimpleStageVideoEvent.STATUS, hwDecoding, true, hwDecoding && true, status ));
			}
			
			resize(_width, _height);
		} 
		
		/**
		 * 
		 * @param width
		 * @param height
		 * @return 
		 * 
		 */		
		private function getVideoRect(width:int, height:int):Rectangle
		{	
			var videoWidth:int = width;
			var videoHeight:int = height;
			var scaling:Number = Math.min ( _width / videoWidth, _height / videoHeight );
			
			videoWidth *= scaling, videoHeight *= scaling;			
			
			//var posX:Number = stage.stageWidth - videoWidth >> 1;
			//var posY:Number = stage.stageHeight - videoHeight >> 1;
			
			_videoRect.x = _x;
			_videoRect.y = _y;
			_videoRect.width = videoWidth;
			_videoRect.height = videoHeight;
			
			return _videoRect;
		}
	}
}