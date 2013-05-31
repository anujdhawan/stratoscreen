package com.stratoscreen.model
{
	/**
	 * Use this class to pass data from the Mini Server to the player
	 * The local connection appears to be losing the Class type
	 *  
	 * @author pjsteele
	 * 
	 */
	public class PlayerResponse
	{		
		public static const DOMAIN_OK:String = "DOMAIN_OK";
		public static const START_OK:String = "START_OK";
		public static const PLAY:String = "PLAY";
		public static const SKIP:String = "SKIP";
		public static const RESTART:String = "RESTART";

		public var response:String;
		public var channelId:String;
				
		public function PlayerResponse(response:String = "")
		{
			this.response = response;
			this.channelId = "";
		}
	}
}