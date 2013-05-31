package com.stratoscreen.model
{
	import flash.geom.Rectangle;
	
	public class ResizeRectangle extends Rectangle
	{
		public var scaleX:Number;
		public var scaleY:Number;
		
		public function ResizeRectangle(x:Number=0, y:Number=0, width:Number=0, height:Number=0)
		{
			this.scaleX = 1;
			this.scaleY = 1;
			super(x, y, width, height);
		}
	}
}