package com.fusiox.media {
	
	import flash.events.*;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	[Event(Event.ID3)]
	public class ID3Reader extends EventDispatcher {
		
		public var version:Number; // ID3 version (major.minor)
		public var length:Number; // ID3 tag size in bytes
		public var frames:Array; // holds all our ID3 frames
		public var bytes:ByteArray;
		public var img:ByteArray;
		public var unsynchronisation:Boolean,extendedHeader:Boolean,experimental:Boolean;
		private var frameIdSize:uint = 3;
		private var frameHeadSize:uint = 10;
		
		public function ID3Reader(data:ByteArray = null) {
			frames = new Array();
			//frames["APIC"] = new Array();
			img = new ByteArray();
			data ? load(data):0 ;
		}
		
		public function load(data:ByteArray):void {
			bytes = data;
			bytes.position = 0;
			if( bytes.readUTFBytes(3).toUpperCase()=="ID3") {
				version = bytes.readByte() + bytes.readByte()/100; // storing tag version
				trace("valid ID3 [version " + version + "]");
				if (version >= 3) { frameIdSize = 4; }
				var flags:uint = bytes.readByte();
				var unsynchronisation:uint = flags>>7;
				var extendedHeader:uint = flags>>6&&01;
				var experimental:uint = flags>>5&&001;
				//trace(unsynchronisation + ":" + extendedHeader + ":" + experimental);
				length = readSynchsafeIntA(bytes.readInt()); // storing tag length
				trace("ID3 size: " + length);
				readFrames();
			} else {
				trace("error");
			}
		}
		
		private function readFrames():void {
			var id:String = "";
			var size:uint = 0;
			while(bytes.position < length + 10){
				trace("position[" + bytes.position + "]");
				id = bytes.readUTFBytes(frameIdSize);
				size = bytes.readInt();
				if (version >= 3) { 
					bytes.readByte();
					bytes.readByte();
				} // add two to skip flags in frame header
				trace("frameSize[" + size + " (+10)]");
				trace("Frame:" + id);
				if(id=="APIC" || id=="PIC"){
					frames[id] = readAPIC(size);
					traceObject(frames[id]);
				} else if(id=="GEOB") {
					frames[id] = readGEOB(size);
					traceObject(frames[id]);
				} else if(id=="COMM" || id=="USLT"){
					//frames[id] = readCOMM(size);
					//traceObject(frames[id]);
					readUnknown(size);
				} else if(id == "PRIV"){
					frames[id] = readPRIV(size);
					traceObject(frames[id]);
				} else if(id.charAt(0)=="T"){
					frames[id] = readTextFrame(size);
					traceObject(frames[id]);
				} else if(id.charAt(0)=="W"){
					//frames[id] = readWebFrame(size);
					//trace("text: " + frames[frameId].text);
					readUnknown(size);
				} else if(id==""){
					trace("error");
					break;
				} else {readUnknown(size)};
			}
			trace("position[" + bytes.position + "]");
			dispatchEvent(new Event(Event.ID3));
		}
		
		private function readSynchsafeIntA(synch:int):int {
			return (synch & 127) + 128 * ((synch >> 8) & 127) + 16384 * ((synch >>16) & 127) + 2097152 * ((synch >> 24) & 127)
		}
		
		private function readSynchsafeIntB(synch:int):int {
			return (synch & 127) + 128 * ((synch >> 7) & 127) + 16384 * ((synch >>14) & 127) + 2097152 * ((synch >> 21) & 127)
		}
		
		/*
		private function readIntX(x:uint):uint {
			var temp:ByteArray = new ByteArray();
			temp.writeByte(0x00);
			bytes.readBytes(temp, 4-x, x);
			temp.position = 0;
			return temp.readInt();
		}
		*/
		
		private function readWebFrame(size:uint):Object {
			var obj:Object = new Object();
			obj.text = bytes.readUTFBytes(size);
			return obj;
		}
		
		private function readCOMM(size:uint):Object {
			var start:uint = bytes.position;
			var obj:Object = new Object();
			obj.encoding = bytes.readByte();
			obj.language = bytes.readUTFBytes(3);
			obj.description = readString();//readString();
			obj.text = bytes.readUTFBytes(size-(bytes.position-start));
			return obj;
		}
		
		private function readPRIV(size:uint):Object {
			var start:uint = bytes.position;
			var obj:Object = new Object();
			obj.data = new ByteArray();
			obj.owner = readString();
			if (size-(bytes.position-start)>0) bytes.readBytes(obj.data,0,size-(bytes.position-start));
			return obj;
		}
		
		private function readGEOB(size:uint):Object {
			var start:uint = bytes.position;
			var obj:Object = new Object();
			obj.data = new ByteArray();
			obj.encoding = bytes.readByte();
			obj.mime = readString();
			obj.type = bytes.readByte();
			obj.filename = readString();
			obj.description = readString();
			bytes.readBytes(obj.data,0,size-(bytes.position-start));
			obj.data.position = 0;
			return obj;
		}
		
		private function readUnknown(size:uint):void {
			skipLength(size);
		}
		
		private function skipLength(x:uint):void {
			try
			{
				for(var i:uint=0;i<x;i++) 
				{
					bytes.readByte();
				}
			}
			catch (err:Error)
			{
				trace(err.message);
			}
		}
		
		private function readTXXXFrame():Object {
			var obj:Object = new Object();
			obj.encoding = bytes.readByte();
			obj.description = readString();
			obj.text = "";
			return obj;
		}
		
		private function readTextFrame(size:uint):Object {
			var obj:Object = new Object();
			obj.encoding = bytes.readByte();
			obj.text = bytes.readUTFBytes(size-1);
			return obj;
		}
		
		private function readAPIC(size:uint):Object {
			var start:uint = bytes.position;
			var obj:Object = new Object();
			obj.data = new ByteArray();
			obj.encoding = bytes.readByte();
			obj.mime = readString();
			obj.type = bytes.readByte();
			obj.description = readString();
			bytes.readBytes(img,0,size-(bytes.position-start));//48259//48251
			img.position = 0;
			return obj;
		}
		
		private function readString():String {
			var ba:ByteArray = new ByteArray();
			var b:int = bytes.readByte();
			while( b!=0 ) {
				ba.writeByte(b)
				b = bytes.readByte();
			}
			ba.position = 0;
			return ba.readUTFBytes(ba.length);
		}
		
		private function traceObject(obj:Object):void {
			for (var s:String in obj) {
				trace("     " + s + " : " + obj[s]);
			}
		}
	}
}