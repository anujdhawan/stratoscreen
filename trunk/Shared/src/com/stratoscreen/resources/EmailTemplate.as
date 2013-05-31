package com.stratoscreen.resources
{
	import flash.utils.ByteArray;
	
	[Embed(source="emailTemplate.htm",mimeType="application/octet-stream")]
	public class EmailTemplate extends ByteArray
	{
		public function EmailTemplate()
		{
			super();
		}
	}
}