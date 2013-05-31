package com.stratoscreen.model.views
{
	import com.stratoscreen.model.domains.DomainBase;

	public class CountRows extends DomainBase
	{
		public var Count:String;
		
		public function get countInt():int
		{
			return parseInt(this.Count);
		}
	}
}