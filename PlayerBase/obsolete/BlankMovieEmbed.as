package com.stratoscreen.resources
{
	import flash.utils.ByteArray;
	
	[Embed(source="black.mp4",mimeType="application/octet-stream")]
	public class BlankMovieEmbed extends ByteArray
	{
		public function BlankMovieEmbed()
		{
			super();
		}
	}
}