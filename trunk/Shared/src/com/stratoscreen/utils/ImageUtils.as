package com.stratoscreen.utils
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.model.ResizeRectangle;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.geom.Rectangle;
	
	public class ImageUtils extends EventDispatcher
	{
		public static const THUMB_SIZE:int = 256;
		
		private var _screenView:String

		public function ImageUtils(screenView:String = "L")
		{
			_screenView = screenView;

			super(null);
		}
		
		public static function reSizetoMax(width:Number, height:Number, maxSize:Number = THUMB_SIZE, keepSmallerSize:Boolean = true):ResizeRectangle
		{
			if (keepSmallerSize)
			{
			 	if (width <= maxSize && height <= maxSize)
				{
					return new ResizeRectangle(0,0, width, height);
				}
			}
			
			var rect:ResizeRectangle = new ResizeRectangle();
			var ratio:Number
			if (height > width)
			{
				ratio = maxSize / height;
				rect.height = maxSize;
				rect.width = width * ratio;
			}
			else
			{
				ratio = maxSize / width;
				rect.width = maxSize;
				rect.height = height * ratio;					
			}
			
			rect.scaleX = ratio;
			rect.scaleY = ratio;
			
			return rect;
		}
		
		
		/**
		 * Since we are working with squares, it is slighty more difficult finding
		 * best fit. It may take a few steps
		 * 
		 * This also takes in consideration the prefered view of the Account
		 */ 
		public function getBestFit( width:Number, height:Number, boxWidth:Number, boxHeight:Number, expandImage:Boolean = true ):ResizeRectangle
		{			
			var rect:ResizeRectangle;
			switch (_screenView)
			{
				// If we are stretching that is easy. 
				// Just return the maxiumums
				case Constants.VIEW_STRETCH:
					rect = new ResizeRectangle();
					rect.x = 0;
					rect.y = 0;
					rect.width = boxWidth;
					rect.height = boxHeight;
					rect.scaleX = boxWidth / width;
					rect.scaleY = boxHeight / height;					
					break;

				case Constants.VIEW_LETTERBOX:
					rect = calcLetterBox(width, height, boxWidth, boxHeight, expandImage);
					break;

				case Constants.VIEW_FULL:
					rect = calcFull(width, height, boxWidth, boxHeight);
					break;
				
				default:
					trace("???");
			
			}

			
			return rect;
		}
		
		private function calcLetterBox(width:Number, height:Number, boxWidth:Number, boxHeight:Number, expandImage:Boolean ):ResizeRectangle
		{
			var newWidth:Number;
			var newHeight:Number;
			var ratio:Number = 1;				
			var skipResize:Boolean = false;
			var rect:ResizeRectangle;

			if (!expandImage)
			{
				if ( width <= boxWidth && height <= boxHeight)
				{
					newWidth = width;
					newHeight = height;
					skipResize = true;
				}				
			}					
			
			if (!skipResize)
			{
				if (height > width)
				{
					ratio = boxHeight / height;
					newHeight = boxHeight;
					newWidth = width * ratio;
				}
				else
				{
					ratio = boxWidth / width;
					newWidth = boxWidth;
					newHeight = height * ratio;					
				}
				
				// Perform a second calc to make sure it will fit
				if (newHeight > boxHeight)
				{
					var resizeRatio:Number = boxHeight / newHeight;
					newHeight = newHeight * resizeRatio;
					newWidth = newWidth * resizeRatio;
					ratio = ratio * resizeRatio;
				}
				
				if (newWidth > boxWidth)
				{
					resizeRatio = boxWidth / newWidth;
					newHeight = newHeight * resizeRatio;
					newWidth = newWidth * resizeRatio;
					ratio = ratio * resizeRatio;
				}
			}
			
			rect = new ResizeRectangle();
			rect.x = (boxWidth - newWidth) / 2;
			rect.y = (boxHeight - newHeight) / 2;
			rect.width = newWidth;
			rect.height = newHeight;
			rect.scaleX = ratio;
			rect.scaleY = ratio;

			return rect;
		}

		private function calcFull(width:Number, height:Number, boxWidth:Number, boxHeight:Number ):ResizeRectangle
		{
			var newWidth:Number;
			var newHeight:Number;
			var ratio:Number = 1;				
			var rect:ResizeRectangle;
						
			if (height < width)
			{
				ratio = boxHeight / height;
				newHeight = boxHeight;
				newWidth = width * ratio;
			}
			else
			{
				ratio = boxWidth / width;
				newWidth = boxWidth;
				newHeight = height * ratio;					
			}
			
			// Perform a second calc to make sure it will fit
			// Note. One will probably be bigger. We need to truncate 
			if (newHeight < boxHeight || newWidth < boxWidth)
			{
				if (newHeight < boxHeight)
				{
					var resizeRatio:Number = boxHeight / newHeight;
					newHeight = newHeight * resizeRatio;
					newWidth = newWidth * resizeRatio;
					ratio = ratio * resizeRatio;
				}
				
				if (newWidth < boxWidth)
				{
					resizeRatio = boxWidth / newWidth;
					newHeight = newHeight * resizeRatio;
					newWidth = newWidth * resizeRatio;
					ratio = ratio * resizeRatio;
				}
			}			
			
			rect = new ResizeRectangle();
			rect.x = (boxWidth - newWidth) / 2;
			rect.y = (boxHeight - newHeight) / 2;
			rect.width = newWidth;
			rect.height = newHeight;
			rect.scaleX = ratio;
			rect.scaleY = ratio;
			
			return rect;
		}
	
	}
}