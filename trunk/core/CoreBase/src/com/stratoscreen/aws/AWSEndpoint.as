package com.stratoscreen.aws
{
	public class AWSEndpoint
	{
		public var id:int;
		public var name:String;
		public var s3:String;
		public var sdb:String;	
		public var iam:String;
		public var ses:String;
		public var sns:String;
		public var cf:String = "cloudfront.amazonaws.com";	// The same for all regions
	}
}