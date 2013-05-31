package com.stratoscreen.utils
{
	import flash.xml.XMLDocument;
	
	import mx.rpc.xml.SimpleXMLDecoder;
	
	public class XMLUtils
	{
		private static var _xmlDecoder:SimpleXMLDecoder;
		
		public static function stringToObject(source:String):Object
		{
			if (_xmlDecoder == null) {_xmlDecoder = new SimpleXMLDecoder();}
			
			var xmlDoc:XMLDocument = new XMLDocument(source);
			return  _xmlDecoder.decodeXML(xmlDoc);			
		}
	}
}