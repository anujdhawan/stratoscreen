package com.stratoscreen.model.domains
{
	import com.stratoscreen.utils.GUID;
	
	[Bindable] public class DomainBase
	{
		private var _createdDateUTC:String;
		private var _modifiedDateUTC:String;

		// The values that will not be saved to AWS
		// The fields are filtered by the getClassInfo command
		public static const excludeAttributes:Array = ["itemName", "decryptedPassword", "decryptedAccessKey", "decryptedSecretKey", "decryptedKeyPair", "decryptedKeyPairId"];

		public var itemName:String;
		public var accountId:String = "";
		public var createdBy:String = "";
		public var modifiedBy:String = "";

		// Flag for SDB Update Domain function
		// NOTE. Any non-strings will not be saved to the DB
		// AWS only deals with strings
		public var deleted:Boolean = false;	
		public var updated:Boolean = false;	
		
		public function DomainBase()
		{
			// Use a guid for ALL ids. 
			// We will remove the 'dash' because the ID will be later used
			// to assemble Indentity Users, Policies, etc
			this.itemName = GUID.create();
			this.itemName = this.itemName.replace(new RegExp(/\-/gi), "");
			
			this.updated = true;			
			
			var now:Date = new Date();
			this.createdDateUTC = now.toUTCString();
			this.modifiedDateUTC = now.toUTCString();
		}

		public function get createdDate():Date
		{
			return new Date(_createdDateUTC);
		}

		public function set createdDate(value:Date):void
		{
			_createdDateUTC = value.toUTCString(); 
		}
		
		public function get modifiedDate():Date
		{
			return new Date(_modifiedDateUTC);
		}
		
		public function set modifiedDate(value:Date):void
		{
			_modifiedDateUTC = value.toUTCString(); 
		}
		
		public function get createdDateUTC():String
		{
			return _createdDateUTC;
		}
		
		public function set createdDateUTC(value:String):void
		{
			_createdDateUTC = value;
		}
		
		public function get modifiedDateUTC():String
		{
			return _modifiedDateUTC;
		}
		
		public function set modifiedDateUTC(value:String):void
		{
			_modifiedDateUTC = value;
		}

	}
}