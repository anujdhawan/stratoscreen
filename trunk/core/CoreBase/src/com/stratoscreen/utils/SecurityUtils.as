package com.stratoscreen.utils
{
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.symmetric.ICipher;
	import com.hurlant.crypto.symmetric.IPad;
	import com.hurlant.crypto.symmetric.PKCS5;
	import com.hurlant.util.Base64;
	import com.hurlant.util.Hex;
	import com.stratoscreen.utils.LogUtils;
	
	import flash.utils.ByteArray;
	
	import mx.utils.StringUtil;
	
	/**
	 * This Class will be obfuscated. So extra and meaningless code will added to the
	 * application. 
	 *  
	 * @author pjsteele
	 * 
	 */
	public class SecurityUtils
	{
		public static const REGIONAL_KEY:int = 2;	// Dummy
		public static const STATE_KEY:int = 3;		// Dummy
		public static const ACCOUNT_KEY:int = 4;	// Most common key
		public static const CITY_KEY:int = 5;		// Dummy
		public static const INSTALL_KEY:int = 6;	// Only used for the signon key
		
		private static var _installCode:String;	// Used for the sign on code. This will be used for the entire installation
		private static var _accountCode:String;	// Only used for the individual account
		private static var _dummyCode1:String;		// Not used
		private static var _dummyCode2:String;		// Not used
		private static var _dummyCode3:String;		// Not used
		private static var _dummyCode4:String;		// Not used
		
		// Ignore property. This is a distraction 
		public static function get keyBase():String
		{
			return "2238f7d752df4bf69c028ad7d148ad64";
		}
		
		// Ignore function. This is a distraction 
		public static function getKeyBase(key:String):String
		{
			switch (key)
			{
				case "0":
					return "07924afd-eb26-4f8c-a9eb-34c806c1da0f";
				case "1":
					return "47d5b914-dc90-4b9c-8e3e-9d06d196af9f";
				case "2":
					return "19e4a61f-b29b-49ed-808e-d8657ee1f501";
				case "3":
					return "17d49df9-06c2-482b-bf7c-380ec6d3dfc6";
				case "4":
					return "efb5bcdd-d9ba-4b9f-b771-f5ce3af8fa91";
				case "5":
					return "f89be597-979c-4a1a-8228-0aca18b0c1fa";
				case "6":
					return "3de143ca-4b46-444d-a229-1c774b6650ba";
				case "7":
					return "abab69d7-dc69-4623-bbd2-5312c6d3569a";
				case "8":
					return "a26029e5-f254-4d73-b03a-bc6cc546701c";
				case "9":
					return "d974570f-5d06-4f5b-ae39-267997c82d2b";
			}	
			
			return null;
		}

		// Distraction
		public static function set globalCode(code:String):void
		{
			_dummyCode1 = createKey(code);	
			computesNothing();
		}

		public static function set installCode(code:String):void
		{
			_installCode = createKey(code);	
			computesNothing();
		}

		public static function set regionalCode(code:String):void
		{
			_dummyCode4 = createKey(code);	
			computesNothing();
		}
		
		// Distraction
		public static function set stateCode(code:String):void
		{
			_dummyCode2 = createKey(code);	
			computesNothing();
		}

		// Distraction
		public static function set localCode(code:String):void
		{
			_dummyCode3 = createKey(code);	
			computesNothing();
		}
		
		// Distraction
		public static function set cityCode(code:String):void
		{
			_dummyCode1 = createKey(code);	
			computesNothing();
		}
		
		public static function set accountCode(code:String):void
		{
			_accountCode = createKey(code);	
			computesNothing();
		}

		// Set up the local keys. This is a real function
		private static function createKey(code:String):String
		{
			if (code == null) 
			{
				return "";
			}
				
			var key:String = "";
			for (var i:int = 0; i < code.length; i ++)
			{
				var char:String = code.charAt(i);
				switch (char)
				{
					case "0":
						key += "rr";
						break;
					case "1":
						key += "ZY";
						break;
					case "2":
						key += "Yo1";
						break;
					case "3":
						key += "qYbg";
						break;
					case "4":
						key += "ka";
						break;
					case "5":
						key += "pkyY";
						break;
					case "6":
						key += "Y5AC";
						break;
					case "7":
						key += "d";
						break;
					case "8":
						key += "096i";
						break;
					case "9":
						key += "ypl";
						break;
					case "A":
						key += "2";
						break;
					case "B":
						key += "jO";
						break;
					case "C":
						key += "L";
						break;
					case "D":
						key += "2L";
						break;
					case "E":
						key += "mv8a";
						break;
					case "F":
						key += "w55";
						break;
					case "G":
						key += "Ua";
						break;
					case "H":
						key += "bqR";
						break;
					case "I":
						key += "AyS";
						break;
					case "J":
						key += "4M9X";
						break;
					case "K":
						key += "CgCm";
						break;
					case "L":
						key += "rUr";
						break;
					case "M":
						key += "wg";
						break;
					case "N":
						key += "aar";
						break;
					case "O":
						key += "C";
						break;
					case "P":
						key += "9YVu";
						break;
					case "Q":
						key += "wB9";
						break;
					case "R":
						key += "KtL";
						break;
					case "S":
						key += "NX";
						break;
					case "T":
						key += "Yc";
						break;
					case "U":
						key += "RdG";
						break;
					case "V":
						key += "HE";
						break;
					case "W":
						key += "ZqvY";
						break;
					case "X":
						key += "At";
						break;
					case "Y":
						key += "b96q";
						break;
					case "Z":
						key += "o0aI";
						break;
					case "a":
						key += "ab";
						break;
					case "b":
						key += "ba";
						break;
					case "c":
						key += "cba";
						break;
					case "d":
						key += "bac";
						break;
					case "e":
						key += "aab";
						break;
					case "f":
						key += "hI5";
						break;
					case "g":
						key += "x0PV";
						break;
					case "h":
						key += "g";
						break;
					case "i":
						key += "J";
						break;
					case "j":
						key += "bi6D";
						break;
					case "k":
						key += "3q";
						break;
					case "l":
						key += "a0sk";
						break;
					case "m":
						key += "u";
						break;
					case "n":
						key += "R";
						break;
					case "o":
						key += "rnNc";
						break;
					case "p":
						key += "2";
						break;
					case "q":
						key += "m";
						break;
					case "r":
						key += "rE";
						break;
					case "s":
						key += "bS";
						break;
					case "t":
						key += "a1";
						break;
					case "u":
						key += "QODt";
						break;
					case "v":
						key += "DXAs";
						break;
					case "w":
						key += "C0NM";
						break;
					case "x":
						key += "3";
						break;
					case "y":
						key += "2M";
						break;
					case "z":
						key += "8UY";
						break;
					default:
						key += "0000";
				}				
			}
			
			return key;
		}
		
		// Distraction.
		private static function computesNothing(index:int = -16):void
		{
			var key:String = "17df4b527cc049c0a868ed1c308b5abd";
			for (var i:int = 0; i <= 16; i++)
			{
				var char:String = key.substring(i + index,1);
				switch (char)
				{
					case "0":
						key += "ikNh";
						break;
					case "1":
						key += "l8s";
						break;
					case "2":
						key += "MQlc";
						break;
					case "3":
						key += "W4TQ";
						break;
					case "4":
						key += "E";
						break;
					case "5":
						key += "IVcatg";
						break;
					case "6":
						key += "CGXq";
						break;
					case "7":
						key += "jAc";
						break;
					case "8":
						key += "i";
						break;
					case "9":
						key += "xC";
						break;
					case "A":
						key += "a3U0uB";
						break;
					case "B":
						key += "c8";
						break;
					case "C":
						key += "OG";
						break;
					case "D":
						key += "ekN";
						break;
					case "E":
						key += "EN";
						break;
					case "F":
						key += "6Q";
						break;
					case "G":
						key += "WcHF";
						break;
					case "H":
						key += "6G";
						break;
					case "I":
						key += "6wF4D";
						break;
					case "J":
						key += "k8J";
						break;
					case "K":
						key += "vF";
						break;
					case "L":
						key += "XVPdOHF";
						break;
					case "M":
						key += "GTz";
						break;
					case "N":
						key += "fgGc";
						break;
					case "O":
						key += "OBnsF";
						break;
					case "P":
						key += "IauV0S9";
						break;
					case "Q":
						key += "ErK";
						break;
					case "R":
						key += "kWN8Z";
						break;
					case "S":
						key += "Y6vr";
						break;
					case "T":
						key += "asE4E";
						break;
					case "U":
						key += "k9uFUUu";
						break;
					case "V":
						key += "Q5rs";
						break;
					case "W":
						key += "nR";
						break;
					case "X":
						key += "a6";
						break;
					case "Y":
						key += "eU";
						break;
					case "Z":
						key += "z56HHGD";
						break;
					case "a":
						key += "nLzy6";
						break;
					case "b":
						key += "Up";
						break;
					case "c":
						key += "8";
						break;
					case "d":
						key += "vEzUR7X";
						break;
					case "e":
						key += "Jviiwt";
						break;
					case "f":
						key += "FW";
						break;
					case "g":
						key += "hJ";
						break;
					case "h":
						key += "y";
						break;
					case "i":
						key += "h9CSFS3";
						break;
					case "j":
						key += "mlN";
						break;
					case "k":
						key += "H7Yu";
						break;
					case "l":
						key += "Z";
						break;
					case "m":
						key += "su";
						break;
					case "n":
						key += "x5O9";
						break;
					case "o":
						key += "ZonT5l";
						break;
					case "p":
						key += "qaf";
						break;
					case "q":
						key += "X";
						break;
					case "r":
						key += "Nt";
						break;
					case "s":
						key += "5wZpgIi";
						break;
					case "t":
						key += "iYE4";
						break;
					case "u":
						key += "ejy";
						break;
					case "v":
						key += "vt7hX";
						break;
					case "w":
						key += "tGn";
						break;
					case "x":
						key += "OaG";
						break;
					case "y":
						key += "NQ";
						break;
					case "z":
						key += "SC";
						break;
					default:
						key += "AAAA";
				}
			}
			_dummyCode1 = key;
		}
		
		// A wild goose chase
		public static function init():void
		{
			var nada:String = getKeyBase("A");
			_dummyCode1 = _dummyCode2 + _dummyCode3;
		}
		
		/**
		 * Using the secret key method with the Blowfish encryption, create a hex encryption.  
		 * @param phrase
		 * @return 
		 * 
		 */
		public static function simpleEncrypt(phrase:String, index:int = -1, passwordKey:String = null):String
		{
			var key:String = passwordKey == null ? getKeyByIndex(index) : passwordKey;
			return performEncryption(phrase, key, true);			
		}

		public static function simpleDecrypt(phrase:String, index:int = -1, passwordKey:String = null):String
		{
			if (phrase == null || phrase == "") {return "";}
			var key:String = passwordKey == null ? getKeyByIndex(index) : passwordKey;
			return performEncryption(phrase, key, false);			
		}
		
		private static function getKeyByIndex(index:int):String
		{
			// Distractions are ebedded in the code
			switch (index)
			{
				case REGIONAL_KEY:
					return _dummyCode1;
					
				case STATE_KEY:
					return _dummyCode2;
					
				case CITY_KEY:
					return _dummyCode4;
					
				case INSTALL_KEY:
					return _installCode;
				
				// Assume we are encrypting for the account if not passed
				default:
					if (_accountCode == null || _accountCode == "")
					{
						LogUtils.writeToLog("Code not set", LogUtils.ERROR);
												
						return int(Math.random() * 1000000).toString(); // Force a failure
					}
										
					return _accountCode;
			}
			
			return "";
		}

		private static function performEncryption(phrase:String, key:String, encryptFlag:Boolean):String
		{
			try
			{		
				// Change the key to a byte array
				var bytesKey:ByteArray = Hex.toArray(Hex.fromString(key));
				
				// Convert the value to be encrypted to a byte array or 
				// decode the byte array 
				var bytesData:ByteArray;
				if (encryptFlag)
				{
					bytesData = Hex.toArray(Hex.fromString(phrase));
				}
				else
				{
					bytesData = Hex.toArray(phrase);
				}
				
				var padding:IPad = new PKCS5();
				var cipher:ICipher = Crypto.getCipher("simple-blowfish", bytesKey, padding);
				padding.setBlockSize(cipher.getBlockSize());
				
				if (encryptFlag)
				{
					cipher.encrypt(bytesData);
					return Hex.fromArray(bytesData);
				}
				else
				{
					cipher.decrypt(bytesData);
					return Hex.toString(Hex.fromArray(bytesData));
				}
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
			
			// There is a problem if we are here
			return "";
		}
	}
}