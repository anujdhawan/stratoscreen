package com.stratoscreen.model.domains
{
	import com.stratoscreen.model.filters.DropShadow;
	import com.stratoscreen.model.filters.Glow;

	[Bindable]
	[RemoteClass()]
	public class OverlayDetail extends DomainBase
	{
		public static const TYPE_BASE:String = "B";
		public static const TYPE_MEDIA:String = "M";
		public static const TYPE_TEXT:String = "T";
		public static const DEFAULT_TEXT_WIDTH:int = 300;
		public static const DEFAULT_TEXT_HEIGHT:int = 40;
		public static const DEFAULT_TEXT_TEXT:String = "Enter text here";;
		public static const DEFAULT_TEXT_COLOR:String = "404040";		
		public static const DEFAULT_TEXT_FONT:String = "arialEmbed";
		public static const DEFAULT_TEXT_SIZE:String = "24";
		public static const DEFAULT_TEXT_STYLE:String = "normal";
		public static const DEFAULT_TEXT_WEIGHT:String = "normal";
		public static const DEFAULT_TEXT_DECOR:String = "none";		

		private var _alpha:String = "1";
		private var _locked:String = "0"
		private var _media:Medias = null;
		private var _maintainAspect:String = "1";
		private var _dropShadow:String = "";
		private var _dropShadowFilter:DropShadow;
		private var _glow:String = "";
		private var _glowFilter:Glow;
		private var _filters:Array;
		private var _fontStyle:String = "normal";

		public var overlayId:String = "";
		public var mediaId:String = "";
		public var type:String;
		public var z:String = "0";
		public var x:String = "0";
		public var y:String = "0";
		public var width:String = "0";
		public var height:String = "0";
		public var rotate:String = "0";
		public var text:String ="";
		public var color:String = "";		
		public var fontFamily:String = "";
		public var fontSize:String = "";
		public var fontWeight:String = "";
		public var textDecoration:String = "";
		public var startTime:String = "0";
		public var endTime:String = "0";
		public var startFrame:String = "0";
		public var endFrame:String = "0";
		public var localUrl:String = "";		// To only be used preview and playback. 
		public var mimeType:String = "";
		public var effectId:String = "0";
		public var accelerated:String = "0";		
		public var showDropShadow:String = "0";
		public var showGlow:String = "0";
		
		[Deprecated] public var playAlways:Boolean = false;	// Use in the Edit pages only
		public var hasError:Boolean = false;
 				
		public function OverlayDetail(overlayId:String = "", type:String = TYPE_BASE)
		{
			super();
			
			this.overlayId = overlayId;
			this.type = type;
			this.maintainAspectBool = type == TYPE_MEDIA;	// Default new items to have aspect for Media Only
		}

		public function get fontStyle():String
		{
			// Watch for valid values
			if (_fontStyle != "normal" && _fontStyle != "italic") {_fontStyle = "normal";}
			return _fontStyle;
		}

		public function set fontStyle(value:String):void
		{
			_fontStyle = value;
		}

		[Deprecated] public function get media():Medias
		{
			return _media;
		}

		public function set media(value:Medias):void
		{
			_media = value;
			if (value != null) {mediaId = _media.itemName;}
		}
		
		public function get isAudio():Boolean
		{
			if (this.mimeType == null || this.mimeType == "") {return false;}
			
			return this.mimeType.indexOf("audio") >= 0;
		}

		public function get isVideo():Boolean
		{
			if (this.mimeType == null || this.mimeType == "") {return false;}
			
			return this.mimeType.indexOf("video") >= 0;
		}

		public function get isImage():Boolean
		{
			if (this.mimeType == null || this.mimeType == "") {return false;}
			
			return this.mimeType.indexOf("image") >= 0;
		}

		public function get isSWF():Boolean
		{
			if (this.mimeType == null || this.mimeType == "") {return false;}
			
			return this.mimeType.indexOf("shockwave") >= 0;
		}

		public function get xNum():Number
		{
			return parseFloat(this.x);
		}

		public function set xNum(value:Number):void
		{
			this.x = value.toString();
		}

		public function get yNum():Number
		{
			return parseFloat(this.y);
		}
		
		public function set yNum(value:Number):void
		{
			this.y = value.toString();
		}

		public function get zInt():int
		{
			return parseInt(this.z);
		}
		
		public function get alpha():String
		{
			return _alpha;
		}
		
		public function set alpha(value:String):void
		{
			_alpha = value;
		}

		public function get alphaNum():Number
		{
			return parseFloat(_alpha);
		}
		
		public function set alphaNum(value:Number):void
		{
			_alpha = value.toString();
		}

		public function get locked():String
		{
			return _locked;
		}
		
		public function set locked(value:String):void
		{
			_locked = value;
		}

		public function get lockedBool():Boolean
		{
			return _locked == "1";
		}
		
		public function set lockedBool(value:Boolean):void
		{
			_locked = value ? "1" : "0";
		}
		
		public function get maintainAspect():String
		{
			return _maintainAspect;
		}
		
		public function set maintainAspect(value:String):void
		{
			_maintainAspect = value;
		}

		public function get maintainAspectBool():Boolean
		{
			return _maintainAspect == "1";
		}
		
		public function set maintainAspectBool(value:Boolean):void
		{
			_maintainAspect = value ? "1" : "0";
		}

		public function get isBold():Boolean
		{
			return  this.fontWeight == "bold";
		}

		public function set isBold(value:Boolean):void
		{
			this.fontWeight = value ? "bold" : null;
		}

		public function get isItalic():Boolean
		{
			return this.fontStyle == "italic";
		}
		
		public function set isItalic(value:Boolean):void
		{
			this.fontStyle = value ? "italic" : null;
		}

		public function get isUnderline():Boolean
		{
			return  this.textDecoration == "underline";
		}
		
		public function set isUnderline(value:Boolean):void
		{
			this.textDecoration = value ? "underline" : null;
		}
		
		public function get colorNum():uint
		{
			return  uint("0x" + this.color); 
		}
		
		public function set colorNum(value:uint):void
		{
			var hex:String = value.toString(16);
			if (hex.length < 6)
			{
				hex = "000000".substr(0, 6 - hex.length) + hex; 
			}
			
			this.color = hex;
		}

		public function get fontSizeNum():Number
		{
			// Watch for NAN
			var sizeNum:Number = parseFloat(this.fontSize);
			if (isNaN(sizeNum)) {sizeNum = 0;}
			
			return sizeNum;
		}
		
		public function set fontSizeNum(value:Number):void
		{
			this.fontSize = value.toString();
		}
		
		public function get startTimeInt():int
		{
			return parseInt(this.startTime);
		}

		public function set startTimeInt(value:int):void
		{
			this.startTime = value.toString();
		}

		public function get endTimeInt():int
		{
			return parseInt(this.endTime);
		}
		
		public function set endTimeInt(value:int):void
		{
			this.endTime = value.toString();
		}

		public function get startFrameInt():int
		{
			return parseInt(this.startFrame);
		}
		
		public function set startFrameInt(value:int):void
		{
			this.startFrame = value.toString();
		}

		public function get endFrameInt():int
		{
			return parseInt(this.endFrame);
		}
		
		public function set endFrameInt(value:int):void
		{
			this.endFrame = value.toString();
		}

		public function get dropShadow():String
		{
			if (!this.showDropShadowBool || _dropShadowFilter == null) {return "{}";} 
			return JSON.stringify(_dropShadowFilter);
		}
		
		public function set dropShadow(value:String):void
		{
			_dropShadow = value;
			_dropShadowFilter = new DropShadow(value);
		}

		public function get showDropShadowBool():Boolean
		{
			return this.showDropShadow == "1";
		}
		
		public function set showDropShadowBool(value:Boolean):void
		{
			this.showDropShadow = value ? "1" : "0";
		}

		[Transient] public function get dropShadowFilter():DropShadow
		{
			if (_dropShadowFilter == null) {_dropShadowFilter = new DropShadow(this.dropShadow);}
			return _dropShadowFilter;
		}
		
		public function set dropShadowFilter(value:DropShadow):void
		{
			_dropShadowFilter = value;
		}
		
		public function get glow():String
		{
			if (!this.showGlowBool || _glowFilter == null) {return "{}";} 
			return JSON.stringify(_glowFilter);
		}
		
		public function set glow(value:String):void
		{
			_glow = value;
			_glowFilter = new Glow(value);
		}
		
		public function get showGlowBool():Boolean
		{
			return this.showGlow == "1";
		}
		
		public function set showGlowBool(value:Boolean):void
		{
			this.showGlow = value ? "1" : "0";
		}
		
		[Transient] public function get glowFilter():Glow
		{
			if (_glowFilter == null) {_glowFilter = new Glow(this.glow);}
			return _glowFilter;
		}
		
		public function set glowFilter(value:Glow):void
		{
			_glowFilter = value;
		}
		
		public function get filters():Array
		{
			_filters = new Array();
			if (this.showDropShadowBool) {_filters.push(this.dropShadowFilter.filter);}
			if (this.showGlowBool) {_filters.push(this.glowFilter.filter);}
				
			return _filters;	
		}

	}
	
}