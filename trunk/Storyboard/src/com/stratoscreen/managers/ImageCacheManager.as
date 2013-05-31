package com.stratoscreen.managers
{	
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.hash.IHash;
	import com.hurlant.util.Base64;
	import com.hurlant.util.Hex;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	public class ImageCacheManager
	{
		private static const imageDir:File = File.applicationStorageDirectory.resolvePath("cachedimages/");
		private static var instance:ImageCacheManager;
		private var pendingDictionaryByLoader:Dictionary = new Dictionary();
		private var pendingDictionaryByURL:Dictionary = new Dictionary();
		public function ImageCacheManager()
		{
		}
		public static function getInstance():ImageCacheManager
		{
			if (instance == null)
			{
				instance = new ImageCacheManager();
			}
			
			return instance;
		}
		
		public function getImageByURL(url:String):String
		{
			try
			{
				var cacheFile:File = new File(imageDir.nativePath +File.separator+ cleanURLString(url));
				if(cacheFile.exists){
					return cacheFile.url;
				} else {
					addImageToCache(url);
					return url;
				}
			}
			catch (err:Error)
			{
				trace(err.message);				
			}
			
			return null;
		}
		
		public function deleteImageByURL(url:String):void
		{
			var cacheFile:File = new File(imageDir.nativePath +File.separator+ cleanURLString(url));
			if(cacheFile.exists) {cacheFile.deleteFile();}			
		}
		
		private  function addImageToCache(url:String):void
		{
			try
			{
				if(!pendingDictionaryByURL[url]){
					var req:URLRequest = new URLRequest(url);
					var loader:URLLoader = new URLLoader();
					loader.addEventListener(Event.COMPLETE,imageLoadComplete);
					loader.addEventListener(IOErrorEvent.IO_ERROR, imageLoadError);
					loader.dataFormat = URLLoaderDataFormat.BINARY;
					loader.load(req);
					pendingDictionaryByLoader[loader] = url;
					pendingDictionaryByURL[url] = true;
				} 
			}
			catch (err:Error)
			{
				trace(err.message);
			}
		}
		private function imageLoadComplete(event:Event):void{
			var loader:URLLoader = event.target as URLLoader;
			var url:String = pendingDictionaryByLoader[loader];
			var cacheFile:File = new File(imageDir.nativePath +File.separator+ cleanURLString(url));
			var stream:FileStream = new FileStream();
			stream.open(cacheFile,FileMode.WRITE);
			stream.writeBytes(loader.data);
			stream.close();
			delete pendingDictionaryByLoader[loader]
			delete pendingDictionaryByURL[url];
		}
		
		private function imageLoadError(event:IOErrorEvent):void
		{
			trace("");
		}
		
		private function cleanURLString(url:String):String{
			var hash:IHash = Crypto.getHash("md5");
			var bytesUrl:ByteArray = Hex.toArray(url);
			var bytesHash:ByteArray = hash.hash(bytesUrl);
			var hashText:String = Hex.fromArray(bytesHash);
			
			return hashText;
		}
		
	}
}