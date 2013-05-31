package
{
	import mx.controls.Alert;
	public class DemoUtils
	{
		public static function isDemo():Boolean
		{
			CONFIG::isDemo
			{
				Alert.show("Featured disabled in DEMO mode", "Feature not Available");
				return true;
			}
			
			// Default will return false not in demo mode
			return false;
		}
	}
}