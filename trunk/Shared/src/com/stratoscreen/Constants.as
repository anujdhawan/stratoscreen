package com.stratoscreen
{
	public class Constants
	{
		public static const KEY_PREFIX:String = "STRATO";
		public static const PRIVATE_CODE:String = "PRIVATE_CODE";
		
		public static const USER_TYPE_MANAGER:String = "M";
		public static const USER_TYPE_USER:String = "U";
		public static const USER_TYPE_PLAYER:String = "P";	
		public static const USER_TYPE_SIGNON:String = "S";	// Only used for signing on the user
		
		public static const MEDIA_TYPE_IMAGE:String = "I";
		public static const MEDIA_TYPE_SWF:String = "S";
		public static const MEDIA_TYPE_VIDEO:String = "V";
		public static const MEDIA_TYPE_AUDIO:String = "A";
		
		public static const VIEW_STRETCH:String = "S";
		public static const VIEW_LETTERBOX:String = "L";
		public static const VIEW_FULL:String = "F";
		
		public static const GROUP_TYPE_SEQUENCE:String = "S";
		public static const GROUP_TYPE_RANDOM:String = "R";
		public static const GROUP_SORT_NONE:String = "N";
		public static const GROUP_SORT_LIFO:String = "L";
		public static const GROUP_SORT_FIFO:String = "F";
		public static const GROUP_SORT_ALPHA:String = "A";
		public static const GROUP_SORT_ALPHA_DESC:String = "D";
		
		public static const THUMB_PREFIX:String = "T_";
		public static const THUMB_EXTENSION:String = ".png";
		
		public static const MINIMUM_PASSWORD_LENGTH:int = 8;
		
		public static const EDIT_WINDOW_SIZE:Number = 0.9;	// 90% of entire size size
		public static const EDIT_WINDOW_SIZE_SUB:Number = 0.85;	
		
		public static const BUCKET_MARKER:String = ".63b6aedd125142359b83f90d0ef44d9f";
		public static const BUCKET_NAME_LENGTH:int = 4;	
		public static const BUCKET_STREAM_PREFIX:String = "_s";
		
		public static const FILTER_IMAGE:String = "*.jpg; *.gif; *.png";
		public static const FILTER_SWF:String = "*.swf";
		public static const FILTER_VIDEO:String = "*.flv; *.mp4; *.mov";
		public static const FILTER_AUDIO:String = "*.mp3";
		
		public static const DEFAULT_DURATION:String = "15";
				
		public static const PREVIEW_MEDIA:String = "M";
		public static const PREVIEW_GROUP:String = "G";
		public static const PREVIEW_OVERLAY:String = "O";
		public static const PREVIEW_CHANNEL:String = "C";		
		public static const PREVIEW_GROUP_OVERLAY:String = "GO";
		public static const PREVIEW_CHANNEL_OVERLAY:String = "CO";		
		
		public static const QUERYSTRING_STATE:String = "state";
		public static const QUERYSTRING_ZIP:String = "zip";
		public static const QUERYSTRING_MINI_SEVER:String = "ms";
		
		public static const REPORT_REMOTE_FOLDER:String = "reports";
		public static const REPORT_TRACKING_PREFIX:String = "track";
		public static const REPORT_SCREEN_SUMMARY:String = "summary";
		public static const REPORT_BANDWIDTH_PREFIX:String = "bandwidth";
	}
}