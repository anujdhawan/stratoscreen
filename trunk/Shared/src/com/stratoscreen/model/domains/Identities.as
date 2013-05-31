package com.stratoscreen.model.domains
{
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.SecurityUtils;

	public class Identities extends DomainBase
	{
		private var _accessKey:String = "";
		private var _secretKey:String = "";
		private var _decryptedAccessKey:String = "";		
		private var _decryptedSecreyKey:String = "";		

		public var name:String = "";
		public var arn:String = ""		
		public var type:String = ""; 
		
		public function Identities()
		{
		}
				
		public function get accessKey():String
		{
			return _accessKey;
		}
		
		public function set accessKey(value:String):void
		{
			_accessKey = value;
			try
			{
				_decryptedAccessKey = SecurityUtils.simpleDecrypt(value, SecurityUtils.INSTALL_KEY);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
		
		public function get secretKey():String
		{
			return _secretKey;
		}
		
		public function set secretKey(value:String):void
		{
			_secretKey = value;
			try
			{
				_decryptedSecreyKey = SecurityUtils.simpleDecrypt(value, SecurityUtils.INSTALL_KEY);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}		
		
		public function get decryptedAccessKey():String
		{
			return _decryptedAccessKey;
		}
		
		public function set decryptedAccessKey(value:String):void
		{
			_decryptedAccessKey = value;
			try
			{
				_accessKey = SecurityUtils.simpleEncrypt(value, SecurityUtils.INSTALL_KEY);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}		
		
		public function get decryptedSecretKey():String
		{
			return _decryptedSecreyKey;
		}
		
		public function set decryptedSecretKey(value:String):void
		{
			_decryptedSecreyKey = value;
			try
			{
				_secretKey = SecurityUtils.simpleEncrypt(value, SecurityUtils.INSTALL_KEY);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}		
	}
}