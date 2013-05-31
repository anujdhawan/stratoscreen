package com.stratoscreen.resources
{
	import flash.utils.ByteArray;
	
	[Embed(source="StreamingDistributionConfig.xml",mimeType="application/octet-stream")]
	public class StreamingDistributionConfig extends ByteArray
	{
		public function StreamingDistributionConfig()
		{
			super();
		}
	}
}