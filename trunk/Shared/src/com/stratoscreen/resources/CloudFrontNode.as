package com.stratoscreen.resources
{
	import flash.utils.ByteArray;
	
	[Embed(source="cloudFrontNode.xml",mimeType="application/octet-stream")]
	public class CloudFrontNode extends ByteArray
	{
		public function CloudFrontNode()
		{
			super();
		}
	}
}