package com.stratoscreen.model.filters
{
	[Bindable]
	public class DropShadow
	{
		import flash.filters.DropShadowFilter;

		private var _distance:int = 4;
		private var _angle:int = 45;
		private var _color:uint = 0x000000;
		private var _alpha:Number = .5;
		private var _blur:Number = 5;
		private var _strength:int = 1;
		private var _quality:int = 2;
		private var _filter:DropShadowFilter;
		
		public function DropShadow(json:String = null)
		{
			if (json != null && json != "" && json != "{}")
			{
				var item:Object = JSON.parse(json);
				if (item.hasOwnProperty("distance")) {_distance = item.distance;}
				if (item.hasOwnProperty("angle")) {_angle = item.angle;}
				if (item.hasOwnProperty("color")) {_color = item.color;}
				if (item.hasOwnProperty("alpha")) {_alpha = item.alpha;}
				if (item.hasOwnProperty("blur")) {_blur = item.blur;}
				if (item.hasOwnProperty("strength")) {_strength = item.strength;}
				if (item.hasOwnProperty("quality")) {_quality = item.quality;}
			}
			
			_filter = new DropShadowFilter(_distance, _angle, _color, _alpha, _blur, _blur, _strength, _quality);
		}
		
		[Transient] public function get filter():DropShadowFilter
		{
			return _filter;
		}
		
		public function get distance():int
		{
			return _distance;
		}

		public function set distance(value:int):void
		{
			_filter.distance = value;
			_distance = value;
		}
		
		public function get angle():int
		{
			return _angle;
		}
		
		public function set angle(value:int):void
		{
			_filter.angle = value;
			_angle = value;
		}

		public function get color():uint
		{
			return _color;
		}

		public function set color(value:uint):void
		{
			_filter.color = value;
			_color = value;
		}

		public function get alpha():Number
		{
			return _alpha;
		}

		public function set alpha(value:Number):void
		{
			_filter.alpha = value;
			_alpha = value;
		}

		public function get blur():Number
		{
			return _blur;
		}

		public function set blur(value:Number):void
		{
			_filter.blurX = value;
			_filter.blurY = value;
			_blur = value;
		}

		public function get strength():int
		{
			return _strength;
		}

		public function set strength(value:int):void
		{
			_filter.strength = value;
			_strength = value;
		}

		public function get quality():int
		{
			return _quality;
		}

		public function set quality(value:int):void
		{
			_filter.quality = value;
			_quality = value;
		}

	}
}