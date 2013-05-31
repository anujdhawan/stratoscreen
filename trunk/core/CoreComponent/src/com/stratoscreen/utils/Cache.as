package com.stratoscreen.utils
{
	public class Cache
	{
		private static const ENCRYPT_KEY:String = "462eda00708345179a1f2aedcf692d76";
		private static const CACHE_URL:String = "https://www.stratoscreen.com/cache/index.php";

		import se.cambiata.utils.crypt.Simplecrypt;
		
		public function Cache()
		{
		}
		
		public static function getCacheUrl(url:String, expire:int = 15):String
		{
			var encrpytedUrl:String = urlEncode(Simplecrypt.encrypt(url));
			
			var cacheUrl:String = CACHE_URL;
			cacheUrl += "?url=" + encrpytedUrl;
			cacheUrl += "&expire=" + expire.toString();
			
			return cacheUrl;
		}
		
		public static function urlEncode(phrase:String):String
		{
			var encoded:String = escape(phrase);
			
			var pattern:RegExp = /\//gi;
			encoded = encoded.replace(pattern, "%2F");
			
			pattern = /\*/gi;;
			encoded = encoded.replace(pattern, "%2A");
			
			pattern = /\+/gi;;
			encoded = encoded.replace(pattern, "%2B");
			
			pattern = /\@/gi;;
			encoded = encoded.replace(pattern, "%40");
			
			return encoded
		}

	}
}