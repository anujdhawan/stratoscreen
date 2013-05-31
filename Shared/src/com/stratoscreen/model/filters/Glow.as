package com.stratoscreen.model.filters
{
	import flash.filters.GlowFilter;

	[Bindable]
	public class Glow
	{

		private var _color:uint = 0x000000;
		private var _alpha:Number = .5;
		private var _blur:Number = 5;
		private var _strength:int = 1;
		private var _quality:int = 2;
		private var _inner:Boolean = false;
		private var _filter:GlowFilter;
		
		public function Glow(json:String = null)
		{
			if (json != null && json != "" && json != "{}")
			{
				var item:Object = JSON.parse(json);
				if (item.hasOwnProperty("color")) {_color = item.color;}
				if (item.hasOwnProperty("alpha")) {_alpha = item.alpha;}
				if (item.hasOwnProperty("blur")) {_blur = item.blur;}
				if (item.hasOwnProperty("strength")) {_strength = item.strength;}
				if (item.hasOwnProperty("quality")) {_quality = item.quality;}
				if (item.hasOwnProperty("inner")) {_inner = item.inner;}
			}

			_filter = new GlowFilter(_color, _alpha, _blur,_blur, _strength, _quality, _inner);
		}
		
		[Transient] public function get filter():GlowFilter
		{
			return _filter;
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

		public function get inner():Boolean
		{
			return _inner;
		}
		
		public function set inner(value:Boolean):void
		{
			_filter.inner = value;
			_inner = value;
		}

	}
}