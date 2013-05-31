package com.fusiox.ui
{
	import mx.controls.Image;
	import flash.utils.ByteArray;
	import flash.system.LoaderContext;
	import flash.display.Loader;
	import flash.display.DisplayObject;
	import flash.events.Event;

	public class Image extends mx.controls.Image
	{
		private var _loader:Loader = new Loader();
		
		public function Image():void {
		}
		
		override protected function createChildren():void {
			addChild(_loader);
		}
		
		public function loadBytes(bytes:ByteArray, context:LoaderContext = null):void {
			_loader.loadBytes(bytes, context);
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBytesLoaded);
		}
		
		private function onBytesLoaded( e:Event ):void {
			width = e.target.width;
			height = e.target.height;
		}
	}
}