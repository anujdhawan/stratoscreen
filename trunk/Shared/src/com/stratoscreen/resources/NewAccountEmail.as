package com.stratoscreen.resources
{
	import flash.utils.ByteArray;
	
	[Embed(source="newAccountEmail.htm",mimeType="application/octet-stream")]
	public class NewAccountEmail extends ByteArray
	{
		public function NewAccountEmail()
		{
			super();
		}
	}
}