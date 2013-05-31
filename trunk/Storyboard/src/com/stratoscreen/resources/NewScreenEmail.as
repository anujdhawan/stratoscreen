package com.stratoscreen.resources
{
	import flash.utils.ByteArray;
	
	[Embed(source="newScreenEmail.htm",mimeType="application/octet-stream")]
	public class NewScreenEmail extends ByteArray
	{
		public function NewScreenEmail()
		{
			super();
		}
	}
}