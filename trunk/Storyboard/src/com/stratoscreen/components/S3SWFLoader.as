package com.stratoscreen.components
{
	import com.stratoscreen.PlayerConstants;
	import com.stratoscreen.model.domains.Accounts;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLStream;
	import flash.net.URLVariables;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import mx.controls.SWFLoader;
	
	public class S3SWFLoader extends SWFLoader
	{
		private static var _account:Accounts;
		
		public static function set account(value:Accounts):void
		{
			_account = value;
		}
		
		public function S3SWFLoader()
		{
			this.smoothBitmapContent = true;
			this.scaleContent = true;
			this.maintainAspectRatio = false;
			
			var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
			context.allowCodeImport = true;
			context.parameters = new Object();
			context.parameters[PlayerConstants.QUERYSTRING_STATE] = escape(_account.state);
			context.parameters[PlayerConstants.QUERYSTRING_ZIP] = escape(_account.zip);
			context.parameters[PlayerConstants.QUERYSTRING_ID] = escape(_account.itemName);
			
			super.loaderContext = context;
		}
		
		public function set signedURLSource( value:String ):void
		{
			if ( content )	{content.visible = false;}
			
			// Build URLRequest:
			var urlRequest:URLRequest = new URLRequest( value );
			
			// Build URLStream:
			var stream:URLStream = new URLStream();
			stream.addEventListener(Event.COMPLETE, onStreamComplete);
			stream.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStreamStatus );
			stream.addEventListener(IOErrorEvent.IO_ERROR, onStreamIOError );
			stream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onStreamSecurityError);
			// Load stream:
			stream.load( urlRequest) ;
		}
				
		private function onStreamComplete(event:Event):void
		{
			// Get byte array and assign it to source:
			var stream:URLStream = event.target as URLStream;
			var bytes:ByteArray = new ByteArray();
			stream.readBytes(bytes);
			super.source = bytes;
			
			if ( content )
				content.visible = true;
		}
		private function onStreamIOError(event:IOErrorEvent):void
		{
			trace("");
		}
		
		private function onStreamSecurityError(event:SecurityErrorEvent):void
		{
			trace("");
		}

		private function onStreamStatus(event:HTTPStatusEvent):void
		{
		}				
	}
}