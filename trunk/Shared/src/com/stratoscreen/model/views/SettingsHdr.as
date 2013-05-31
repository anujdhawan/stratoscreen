package com.stratoscreen.model.views
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.SecurityUtils;

	[RemoteClass()]
	public class SettingsHdr extends ViewBase
	{
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
		
		public function get decryptedKeyPair():String
		{
			if (_decryptedKeyPair == "")
			{
				_decryptedKeyPair = SecurityUtils.simpleDecrypt(keyPairPart1 + keyPairPart2, SecurityUtils.INSTALL_KEY);
			}
			
			return _decryptedKeyPair;
		}
		
	}
}