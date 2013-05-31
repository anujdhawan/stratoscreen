package com.stratoscreen.resources
{
	import flash.utils.ByteArray;
	
	[Embed(source="newUserEmail.htm",mimeType="application/octet-stream")]
	public class NewUserEmail extends ByteArray
	{
		public function NewUserEmail()
		{
			super();
		}
	}
}