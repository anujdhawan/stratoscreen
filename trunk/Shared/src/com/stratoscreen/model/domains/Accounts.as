package com.stratoscreen.model.domains
{	
	import com.stratoscreen.Constants;
	import com.stratoscreen.managers.EffectsManager;
	import com.stratoscreen.model.BillingRow;
	
	[Bindable] public class Accounts extends DomainBase
	{
		// Billing is set by the Site Adminstrator
		public static const BILLING_NONE:String = "1";

		// User will purchase licenses from AWS 
		public static const BILLING_FPS:String = "2";
		
		public var name:String = "";
		public var companyName:String = "";
		public var address1:String = "";
		public var address2:String = "";
		public var city:String = "";
		public var state:String = "";
		public var zip:String = "";
		public var contactName:String = "";
		public var phone:String = "";
		public var email:String = "";
		public var bucket:String = "";
		public var topicArn:String = "";
		public var sampleContent:String = "";
		public var licenseCount:String = "0";
		public var mediasCount:String = "1000";
		public var mediasSize:String = "1073741824";	// One gigabyte
		public var bandwidth:String = "1073741824";	// One gigabyte
		public var standAloneCount:String = "1";
		public var streaming:String = "0";
		public var streamDomain:String = "";
		public var cloudFrontId:String = "";
		public var partial:String = "";	// Partial Setup. Needs to be completed on first signin
		public var billingType:String = BILLING_NONE;
		public var billing:String = "";
		
		public var defaultDuration:String;
		public var defaultScreenView:String;
		public var defaultEffectId:String;
		
		public var useForSampleContent:Boolean;	// only used at update and create

		public function Accounts()
		{
			this.defaultDuration = Constants.DEFAULT_DURATION;
			this.defaultScreenView = Constants.VIEW_STRETCH;
			this.defaultEffectId = EffectsManager.EFFECT_FADE;
		}
		
		public function get sampleContentBool():Boolean
		{
			return this.sampleContent == "1";
		}
		
		public function get licenseCountInt():int
		{
			return parseInt(this.licenseCount);
		}

		
		public function get paidLicenseCount():int
		{
			if (this.billingArray == null || this.billingArray.length == 0) {return 0;}
			
			var count:int = 0;
			for each (var row:BillingRow in this.billingArray)
			{
				count += row.screenCount;
			}
			
			return count;
		}
		
		public function get billingArray():Array
		{
			// We should have a string that looks like thos
			//   aaa-bbb-ccc-dd|99, fff-ggg-hhh-ii|100,
			//   The ffirst number is the subscripition id. The second is the number of screens
			
			var array:Array = new Array();
			var sections:Array = billing.split(",");
			
			for (var i:int = 0; i < sections.length; i++)
			{
				if (sections[i] != "")
				{
					var subSections:Array = sections[i].split("|");
					if (subSections.length == BillingRow.FIELD_COUNT)
					{
						var row:BillingRow = new BillingRow;
						row.subscriptionId = subSections[0];
						row.screenCount = parseInt(subSections[1]);
						
						array.push(row);
					}
				}
			}
			
			return array;
		}
		
		public function set billingArray(array:Array):void
		{
			this.billing = "";
			
			for (var i:int = 0; i < array.length; i++)
			{
				var row:BillingRow = array[i] as BillingRow;
				if (row != null)
				{
					this.billing += row.subscriptionId + "|" + row.screenCount;
					if (i < array.length - 1) { this.billing += ",";}
				}
			}
		}
	
	}
}