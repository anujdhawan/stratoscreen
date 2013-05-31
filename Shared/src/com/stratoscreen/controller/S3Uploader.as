package com.stratoscreen.controller
{
	import com.hurlant.crypto.hash.HMAC;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.util.Base64;
	import com.stratoscreen.aws.AWSEndpoint;
	import com.stratoscreen.aws.AWSRegions;
	import com.stratoscreen.aws.S3Event;
	
	import flash.events.*;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import s3.flash.S3PostOptions;
	import s3.flash.S3PostRequest;
	
	import spark.formatters.DateTimeFormatter;

	public class S3Uploader
	{
		private const ACL_AUTHENTICATED_READ:String = "authenticated-read";
		private const ACL_BUCKET_OWNER_FULL_CONTROL:String = "bucket-owner-full-control";
		private const ACL_BUCKET_OWNER_READ:String = "bucket-owner-read";
		private const ACL_PRIVATE:String = "private";
		private const ACL_PUBLIC_READ:String = "public-read";
		private const ACL_PUBLIC_WRITE:String = "public-write";
		private const MIME_TYPE:String = "application/octet-stream";

		private var _regionEndpoint:String;
		private var _accessKey:String;
		private var _secretKey:String;
		private var _s3Request:S3PostRequest;	
		private var _callback:Function;
		
		public function S3Uploader(regionId:int, accessKey:String, secretKey:String)
		{
			_accessKey = accessKey;
			_secretKey = secretKey;
			
			var awsEndpoint:AWSEndpoint = AWSRegions.getAWSEndpoint(regionId);
			_regionEndpoint = awsEndpoint.s3;
		}
		
		public function upload(file:FileReference, bucket:String, key:String, callback:Function, acl:String = ACL_PRIVATE):void
		{
			_callback = callback;
			
			var policy:String =  generatePolicy( bucket, key);
			var base64Policy:String = Base64.encode(policy);
			var signature:String = generateSignature(base64Policy, _secretKey);
			
			var options:S3PostOptions = new S3PostOptions();
			options.secure = true;	
			options.acl = ACL_PRIVATE;	// The server will adjust authority for Streaming content
			options.contentType = MIME_TYPE;				
			options.policy = base64Policy;
			options.signature = signature;

			_s3Request = new S3PostRequest(_accessKey,  bucket, key, options, _regionEndpoint);
			_s3Request.addEventListener(ProgressEvent.PROGRESS, uploadProgressHandler);
			_s3Request.addEventListener(IOErrorEvent.IO_ERROR, uploadErrorHandler);
			_s3Request.addEventListener(SecurityErrorEvent.SECURITY_ERROR, uploadErrorHandler);
			_s3Request.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, uploadCompleteHandler);		
			
			_s3Request.upload(file);
		}
		
		private function uploadCompleteHandler(event:DataEvent):void
		{
			removeListeners();
			
			// Use the same callback method as the S3Class
			var s3Event:S3Event = new S3Event();
			s3Event.result = "";
			s3Event.success = true;
		
			_callback(s3Event);	
		}

		private function uploadErrorHandler(event:Event):void
		{
			removeListeners();
			
			// Use the same callback method as the S3Class
			var s3Event:S3Event = new S3Event();
			s3Event.result = null;
			s3Event.success = false;
			
			if (event is IOErrorEvent) {s3Event.message = IOErrorEvent(event).text;	}
			if (event is SecurityErrorEvent) {s3Event.message = SecurityErrorEvent(event).text;}
			
			_callback(s3Event);	
		}
		
		private function uploadProgressHandler(event:ProgressEvent):void
		{
			var percent:Number = event.bytesLoaded  /  event.bytesTotal * 100; 
		}
		
		private function removeListeners():void
		{
			_s3Request.removeEventListener(ProgressEvent.PROGRESS, uploadProgressHandler);
			_s3Request.removeEventListener(IOErrorEvent.IO_ERROR, uploadErrorHandler);
			_s3Request.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, uploadErrorHandler);
			_s3Request.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA, uploadCompleteHandler);	
		}

		private function generatePolicy(bucket:String, fileName:String):String
		{
			var buffer:Array = new Array();
			buffer.indents = 0;
			
			write(buffer, "{\n");
			indent(buffer);
			
			// expiration
			// Default to two days out
			var expireDate:Date = new Date();
			expireDate = new Date(expireDate.getTime() + (2 * 24 *60 * 60 * 1000)); //86400 seconds in a day	
			var formatter:DateTimeFormatter = new DateTimeFormatter();
			formatter.dateTimePattern= "yyyy-MM-dd";
			
			write(buffer, "'expiration': '");
			write(buffer, formatter.format(expireDate));
			write(buffer, "T12:00:00.000Z'");
			write(buffer, ",\n");                
			
			// conditions
			write(buffer, "'conditions': [\n");
			indent(buffer);
			
			// bucket
			writeSimpleCondition(buffer, "bucket", bucket, true);
			
			// key
			writeSimpleCondition(buffer, "key", fileName, true);
			
			// acl
			// Default to private
			writeSimpleCondition(buffer, "acl", ACL_PRIVATE, true);
			
			// Content-Type
			writeSimpleCondition(buffer, "Content-Type", MIME_TYPE, true);
			
			// Filename
			/**
			 * FileReference.Upload sends along the "Filename" form field.
			 * The "Filename" form field contains the name of the local file being
			 * uploaded.
			 * 
			 * See http://livedocs.adobe.com/flex/2/langref/flash/net/FileReference.html for more imformation
			 * about the FileReference API.
			 * 
			 * Since there is no provided way to exclude this form field, and since
			 * Amazon S3 POST interface requires that all form fields are handled by
			 * the policy document, we must always add this 'starts-with' condition that 
			 * allows ANY 'Filename' to be specified.  Removing this condition from your
			 * policy will result in Adobe Flash clients not being able to POST to Amazon S3.
			 */
			writeCondition(buffer, "starts-with", "$Filename", "", true);
			
			// success_action_status
			/**
			 * Certain combinations of Flash player version and platform don't handle
			 * HTTP responses with the header 'Content-Length: 0'.  These clients do not
			 * dispatch completion or error events when such a response is received.
			 * Therefore it is impossible to tell when the upload has completed or failed.
			 * 
			 * Flash clients should always set the success_action_status parameter to 201
			 * so that Amazon S3 returns a response with Content-Length being non-zero.
			 * The policy sent along with the POST MUST therefore contain a condition
			 * enabling use of the success_action_status parameter with a value of 201.
			 * 
			 * There are many possible conditions satisfying the above requirements.
			 * This policy generator adds one for you below.
			 */
			writeCondition(buffer, "eq", "$success_action_status", "201", false);
			
			write(buffer, "\n");
			outdent(buffer);
			write(buffer, "]");
			
			write(buffer, "\n");
			outdent(buffer);
			write(buffer, "}");
			
			return  buffer.join("");
		}
		
		private function generateSignature(data:String, secretKey:String):String 
		{            
			var secretKeyByteArray:ByteArray = new ByteArray();
			secretKeyByteArray.writeUTFBytes(secretKey);
			secretKeyByteArray.position = 0;
			
			var dataByteArray:ByteArray = new ByteArray();
			dataByteArray.writeUTFBytes(data);
			dataByteArray.position = 0;
			
			var hmac:HMAC = new HMAC(new SHA1());            
			var signatureByteArray:ByteArray = hmac.compute(secretKeyByteArray, dataByteArray);
			return Base64.encodeByteArray(signatureByteArray);
		}

		private function write(buffer:Array, value:String):void 
		{
			if(buffer.length > 0) {
				var lastPush:String =  String(buffer[buffer.length-1]);
				if(lastPush.length && lastPush.charAt(lastPush.length - 1) == "\n") {
					writeIndents(buffer);
				}
			}
			buffer.push(value);
		}
		
		private function indent(buffer:Array):void 
		{
			buffer.indents++;
		}
		
		private function outdent(buffer:Array):void 
		{
			buffer.indents = Math.max(0, buffer.indents-1);
		}
		
		private function writeIndents(buffer:Array):void 
		{
			for(var i:int=0;i<buffer.indents;i++) {
				buffer.push("    ");
			}
		}

		private function writeCondition(buffer:Array, type:String, name:String, value:String, commaNewLine:Boolean):void 
		{
			write(buffer, "['");
			write(buffer, type);
			write(buffer, "', '");
			write(buffer, name);
			write(buffer, "', '");
			write(buffer, value);
			write(buffer, "'");
			write(buffer, "]");
			if(commaNewLine) 
			{
				write(buffer, ",\n");
			}			
		}
		
		private function writeSimpleCondition(buffer:Array, name:String, value:String, commaNewLine:Boolean):void 
		{
			write(buffer, "{'");
			write(buffer, name);
			write(buffer, "': ");
			write(buffer, "'");
			write(buffer, value);
			write(buffer, "'");
			write(buffer, "}");
			if(commaNewLine) 
			{
				write(buffer, ",\n");
			}
		}
	}
}