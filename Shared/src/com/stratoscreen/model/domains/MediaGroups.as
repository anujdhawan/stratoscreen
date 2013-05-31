package com.stratoscreen.model.domains
{
	import com.stratoscreen.Constants;
	
	[RemoteClass()]
	[Bindable] public class MediaGroups extends DomainBase
	{
	 	public var name:String = "";
		public var type:String = Constants.GROUP_TYPE_SEQUENCE;
		public var playCount:String = "0";
		public var playAll:String = "1";
		public var playOrder:String = Constants.GROUP_SORT_NONE;
		public var audioOnly:String = "0";
		
		public var firstMediaId:String = "";

		public function get playAllBool():Boolean
		{
			return this.playAll == "1";
		}
		
		public function get audioOnlyBool():Boolean
		{
			return this.audioOnly == "1";
		}

	}
}