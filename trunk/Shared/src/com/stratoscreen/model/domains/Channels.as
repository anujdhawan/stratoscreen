package com.stratoscreen.model.domains
{
	[RemoteClass()]
	[Bindable] public class Channels extends DomainBase
	{
		public var name:String;
		public var height:String = "0";
		public var width:String = "0";
		public var firstMediaId:String;
		public var sizeLo:String = "";
		public var sizeHi:String = "";
	}
}