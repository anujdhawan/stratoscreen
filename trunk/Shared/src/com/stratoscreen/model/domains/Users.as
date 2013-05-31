package com.stratoscreen.model.domains
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.utils.LogUtils;
	import com.stratoscreen.utils.SecurityUtils;
	
	[Bindable] public class Users extends DomainBase
	{		
		public static const STATUS_ACTIVE:String = "A";
		public static const STATUS_DISABLED:String = "D";
		
		private var _password:String = "";
		private var _decryptedPassword:String = "";
		private var _termsDateUTC:String;
		
		public var type:String = ""; 
		public var status:String = "";
		public var email:String = "";		
		public var firstName:String = "";
		public var lastName:String = "";		
		public var changePassword:String = "";
		public var agreedToTerms:String = "";
		public var emailVerfied:Boolean = false; 
		public var newUser:Boolean = false;

		public function Users()
		{
			this.status = STATUS_ACTIVE;
		}
		
		public function get password():String
		{
			return _password;
		}
		
		public function set password(value:String):void
		{
			_password = value;
			try
			{
				_decryptedPassword = SecurityUtils.simpleDecrypt(value, SecurityUtils.INSTALL_KEY);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}
		
		public function get decryptedPassword():String
		{
			return _decryptedPassword;
		}

		public function set decryptedPassword(value:String):void
		{
			_decryptedPassword = value;
			try
			{
				_password = SecurityUtils.simpleEncrypt(value, SecurityUtils.INSTALL_KEY);
			}
			catch (err:Error)
			{
				LogUtils.writeErrorToLog(err);
			}
		}

		public function get typeName():String
		{
			switch (this.type)
			{
				case Constants.USER_TYPE_MANAGER:
					return "Manager";
					
				case Constants.USER_TYPE_USER:
					return "User";
			}
			
			return "";
		}
		
		public function get termsDate():Date
		{
			return new Date(_termsDateUTC);
		}
		
		public function set termsDate(value:Date):void
		{
			_termsDateUTC = value.toUTCString(); 
		}
		
		public function get termsDateUTC():String
		{
			return _termsDateUTC;
		}
		
		public function set termsDateUTC(value:String):void
		{
			_termsDateUTC = value;
		}
	}
	
}