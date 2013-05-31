package com.stratoscreen.aws
{
	import mx.collections.ArrayCollection;

	public class AWSRegions
	{
		[Bindable] private static var _endpoints:ArrayCollection = null;
		
		/**
		 * Return the available endpoints for AWS. The array will contain fields
		 * for each possible product.  
		 *  
		 * @return 
		 * 
		 */
		public static function get endpoints():ArrayCollection
		{
			// Manually build the array on the first call
			if (_endpoints == null)
			{
				_endpoints = new ArrayCollection();
				
				var row:AWSEndpoint = new AWSEndpoint();
				row.id = 1;
				row.name = "US-East (Northern Virginia)";
				row.s3 = "s3.amazonaws.com";
				row.sdb = "sdb.amazonaws.com";
				row.iam = "iam.amazonaws.com";
				row.ses = "email.us-east-1.amazonaws.com"
				row.sns = "sns.us-east-1.amazonaws.com";
				_endpoints.addItem(row);
				
				row = new AWSEndpoint();
				row.id = 2;
				row.name = "US-West (Northern California)";
				row.s3 = "s3-us-west-1.amazonaws.com";
				row.sdb = "sdb.us-west-1.amazonaws.com";
				row.iam = "iam.amazonaws.com";
				row.ses = "email.us-east-1.amazonaws.com"
				row.sns = "sns.us-west-1.amazonaws.com";
				_endpoints.addItem(row);
				
				row = new AWSEndpoint();
				row.id = 3;				
				row.name = "EU (Ireland)";
				row.s3 = "s3-eu-west-1.amazonaws.com";
				row.sdb = "sdb.eu-west-1.amazonaws.com";
				row.iam = "iam.amazonaws.com";
				row.ses = "email.us-east-1.amazonaws.com";
				row.sns = "sns.eu-west-1.amazonaws.com";
				_endpoints.addItem(row);				

				row = new AWSEndpoint();
				row.id = 4;				
				row.name = "Asia Pacific (Singapore)";
				row.s3 = "s3-ap-southeast-1.amazonaws.com";
				row.sdb = "sdb.ap-southeast-1.amazonaws.com";
				row.iam = "iam.amazonaws.com";
				row.ses = "email.us-east-1.amazonaws.com";
				row.sns = "sns.ap-southeast-1.amazonaws.com";
				_endpoints.addItem(row);								
			}
			
			return _endpoints;
		}
		
		/**
		 * Find the matching AWS endpoint and return. 
		 * The endpoint should have addresses for AWS product per region
		 *  
		 * @param id
		 * @return AWSEndpoint
		 * @see com.stratoscreen.aws.AWSEndpoint
		 * 
		 */
		public static function getAWSEndpoint(id:int):AWSEndpoint
		{
			for each(var endpoint:AWSEndpoint in AWSRegions.endpoints)
			{
				if (endpoint.id == id) {return endpoint;}
			}
			
			// They value may not be set. Return the first
			return _endpoints[3];
		}
	}
}