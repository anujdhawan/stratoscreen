// To be included with domains that implement the mimeType

public function get mediaType():String
{
	if (this.mimeType.indexOf("image") >= 0)
	{
		return Constants.MEDIA_TYPE_IMAGE;
	} 
	else if (this.mimeType.indexOf("application/x-shockwave-flash") >= 0)
	{
		return Constants.MEDIA_TYPE_SWF;
	}
	else if (this.mimeType.indexOf("video") >= 0)
	{
		return Constants.MEDIA_TYPE_VIDEO;			
	}
	else if (this.mimeType.indexOf("audio") >= 0)
	{
		return Constants.MEDIA_TYPE_AUDIO;			
	}
	
	// Hmmmm. Mystery Media...
	return "";			
}
// ActionScript file