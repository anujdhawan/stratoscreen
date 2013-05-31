package com.stratoscreen.model
{
	import flash.system.Capabilities;
	import flash.system.System;

	[RemoteClass()]
	public class ScreenSummary
	{
		public var uptimeSeconds:Number;
		public var freeMemory:Number;
		public var totalMemory:Number;
		public var capabilities:Array;
		public var volumes:Array;
	}
}