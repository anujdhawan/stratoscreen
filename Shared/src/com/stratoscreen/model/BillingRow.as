package com.stratoscreen.model
{
	[Bindable]
	public class BillingRow
	{
		public static const FIELD_COUNT:int = 2;
		public var subscriptionId:String;
		public var screenCount:int;
		public var deleted:Boolean = false;
	}
}