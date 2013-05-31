package com.stratoscreen.resources
{
	import flash.utils.ByteArray;
	
	[Embed(source="terms.htm",mimeType="application/octet-stream")]
	public class TermsEmbed extends ByteArray
	{
		public function TermsEmbed()
		{
			super();
		}
	}
}