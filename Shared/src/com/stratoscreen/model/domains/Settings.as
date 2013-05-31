package com.stratoscreen.model.domains
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.SecurityUtils;

	
	public class Settings extends DomainBase
	{
		private const MAX_LENGTH:int = 1024;
		
		public var name:String = "";
		public var regionId:String = "";
		public var bucketWeb:String = "";
		public var email:String = "";
		public var contentAccountId:String = "";
		public var s3CanonicalUserId:String = "";
		public var originAccessIdentity:String = "";

		
		private var _keyPairId:String = "";
		private var _decryptedKeyPairId:String = "";
		private var _decryptedKeyPair:String = "";
		
		// The encrypted private key is not fitting into the AWS Limitations. 
		// Split this into two fields
		public var keyPairPart1:String = "";
		public var keyPairPart2:String = "";
		
		public function get keyPairId():String
		{
			return _keyPairId;
		}
		
		public function set keyPairId(value:String):void
		{
			_keyPairId = value;
			try
			{
				_decryptedKeyPairId = SecurityUtils.simpleDecrypt(value, SecurityUtils.INSTALL_KEY);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
		
		public function get decryptedKeyPairId():String
		{
			return _decryptedKeyPairId;
		}
		
		public function set decryptedKeyPairId(value:String):void
		{
			_decryptedKeyPairId = value;
			try
			{
				_keyPairId = SecurityUtils.simpleEncrypt(value, SecurityUtils.INSTALL_KEY);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
		
		public function get keyPair():String
		{
			return keyPairPart1 + keyPairPart2;
		}
				
		public function get decryptedKeyPair():String
		{
			if (_decryptedKeyPair == "")
			{
				_decryptedKeyPair = SecurityUtils.simpleDecrypt(keyPairPart1 + keyPairPart2, SecurityUtils.INSTALL_KEY);
			}
				
			return _decryptedKeyPair;
		}
		
		public function set decryptedKeyPair(value:String):void
		{
			_decryptedKeyPair = value;
			try
			{
				var keyPair:String = SecurityUtils.simpleEncrypt(value, SecurityUtils.INSTALL_KEY);
				
				if (keyPair.length <= MAX_LENGTH)
				{
					keyPairPart1 = keyPair;
				}
				else
				{
					// Assume it is under 2048
					keyPairPart1 = keyPair.substr(0, MAX_LENGTH);
					keyPairPart2 = keyPair.substr(MAX_LENGTH, MAX_LENGTH);
				}
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}

	}
}