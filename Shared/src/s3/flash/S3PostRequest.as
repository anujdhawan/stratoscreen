//  This software code is made available "AS IS" without warranties of any
//  kind.  You may copy, display, modify and redistribute the software
//  code either by itself or as incorporated into your code; provided that
//  you do not remove any proprietary notices.  Your use of this software
//  code is at your own risk and you waive any claim against Amazon
//  Digital Services, Inc. or its affiliates with respect to your use of
//  this software code. (c) 2006-2007 Amazon Digital Services, Inc. or its
//  affiliates.

package s3.flash {

    import flash.errors.IOError;
    import flash.events.*;
    import flash.net.*;
    import flash.system.Security;
    import flash.utils.ByteArray;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import flash.xml.XMLDocument;
    import flash.xml.XMLNode;
    

    /**
     * This class encapsulates a POST request to S3.
     * 
     * After you create an S3PostRequest, invoke S3PostRequest::upload(fileReference:FileReference).
     * 
     */
    public class S3PostRequest extends EventDispatcher {
        
        [Event(name="open", type="flash.events.Event.OPEN")]
        [Event(name="uploadCompleteData", type="flash.events.DataEvent.UPLOAD_COMPLETE_DATA")]        
        [Event(name="ioError", type="flash.events.IOErrorEvent.IO_ERROR")]
        [Event(name="securityError", type="flash.events.SecurityErrorEvent.SECURITY_ERROR")]
        [Event(name="progress", type="flash.events.ProgressEvent.PROGRESS")]
        
        private var _accessKeyId:String;
        private var _bucket:String;
        private var _key:String;
        private var _options:S3PostOptions;
        private var _httpStatusErrorReceived:Boolean;
        private var _uploadStarted:Boolean;
        private var _fileReference:FileReference;
		private var _endPoint:String;
        
        private const MIN_BUCKET_LENGTH:int = 3;
        private const MAX_BUCKET_LENGTH:int = 63;
        
        /**
         * Creates and initializes a new S3PostRequest object.
         * @param    accessKeyId The AWS access key id to authenticate the request
         * @param    bucket The bucket to POST into
         * @param    key The key to create
         * @param    options Options for this request
         */
        public function S3PostRequest(accessKeyId:String, bucket:String, key:String, options:S3PostOptions, endPoint:String) 
		{
            if(!accessKeyId) {
                throw new ArgumentError("Invalid access key id: " + accessKeyId);
            }
            _accessKeyId = accessKeyId;
            if(!bucket) {
                throw new ArgumentError("Invalid bucket: " + bucket);
            }
            _bucket = bucket;
            if(!key) {
                throw new ArgumentError("Invalid key: " + key);
            }
            _key = key;
            
            if(options == null) {
                // if no options were set, use the default options
                options = new S3PostOptions();
            }
            
			_options = options;
			_endPoint = endPoint;
        }
        
        private function buildUrl():String {

            var canUseVanityStyle:Boolean = canUseVanityStyle(_bucket);
            if(_options.secure && canUseVanityStyle && _bucket.match(/\./)) {
                // We cannot use SSL for bucket names containing "."
                // The certificate won't match "my.bucket.s3.amazonaws.com"
                throw new SecurityError("Cannot use SSL with bucket name containing '.': " + _bucket);
            }
            var postUrl:String = "http" + (_options.secure ? "s" : "") + "://";
            
            if(canUseVanityStyle) {
                postUrl += _bucket + "." + _endPoint;                
            } else {
                postUrl += _endPoint + "/" + _bucket;
            }
            
            return postUrl;
        }
        
        private function loadPolicyFile(postUrl:String):void {
            /*
             * Due to the restrictions imposed by the Adobe Flash security sandbox,
             * the bucket being uploaded to must contain a public-readable crossdomain.xml
             * file that allows access from the domain that served the SWF hosting this code.
             * 
             * Read Adobe's documentation on the Flash security sandbox for more information.
             * 
             */
            Security.loadPolicyFile(postUrl + "/crossdomain.xml");
        }
        
        private function buildPostVariables():URLVariables {
            var postVariables:URLVariables = new URLVariables();
            postVariables.key = _key;
            if(_options.acl != null) {
                postVariables.acl = _options.acl;
            }
            if(_options.policy != null) {
                addPolicyAndSignature(postVariables);
            }
            if(_options.contentType != null) {
                postVariables["Content-Type"] = _options.contentType;
            }
            
            /**
             * Certain combinations of Flash player version and platform don't handle
             * HTTP responses with the header 'Content-Length: 0'.  These clients do not
             * dispatch completion or error events when such a response is received.
             * Therefore it is impossible to tell when the upload has completed or failed.
             * 
             * Flash clients should always set the success_action_status parameter to 201
             * so that Amazon S3 returns a response with Content-Length being non-zero.
             * 
             */
            postVariables.success_action_status = "201";
            
            return postVariables;
        }
        
        /**
         * Initiates a POST upload request to S3
         * @param    fileReference A FileReference object referencing the file to upload to S3.
         */
        public function upload(fileReference:FileReference):void {
            
            if(_uploadStarted) 
			{
                throw new Error("S3PostRequest object cannot be reused.  Create another S3PostRequest object to send another request to Amazon S3.");
            }
            _uploadStarted = true;
            
            // Save the FileReference object so that it doesn't get GCed.
            // If this happens, we can lose events that should be dispatched.
            _fileReference = fileReference;
            
            var postUrl:String = buildUrl();
            loadPolicyFile(postUrl);
            var urlRequest:URLRequest = new URLRequest(postUrl);
            urlRequest.method = URLRequestMethod.POST;
            urlRequest.data = buildPostVariables();            
            
            // set up event handlers *****************************************************
            fileReference.addEventListener(Event.OPEN, onOpen);
            fileReference.addEventListener(ProgressEvent.PROGRESS, onProgress);
            fileReference.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
            fileReference.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
            fileReference.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, onUploadCompleteData);
            fileReference.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
            // *****************************************************************************
            
            // send the request
            fileReference.upload(urlRequest, "file", false);
        }
        
        private function onOpen(event:Event):void {
            this.dispatchEvent(event);
        }
        private function onIOError(event:IOErrorEvent):void {
            /*
             * FileReference.upload likes to send cryptic IOErrors when it doesn't get a status code that it likes.
             * If we already got an error HTTP status code, don't propagate this event since the HTTPStatusEvent
             * event handler dispatches an IOErrorEvent.
             */
            if(!_httpStatusErrorReceived) {
                this.dispatchEvent(event);
            }
        }
        private function onSecurityError(event:SecurityErrorEvent):void {
            this.dispatchEvent(event);
        }
        private function onProgress(event:ProgressEvent):void {
            this.dispatchEvent(event);
        }
        private function onUploadCompleteData(event:DataEvent):void {
            var data:String = event.data;
            if(isError(data)) {
                this.dispatchEvent(
                    new IOErrorEvent(IOErrorEvent.IO_ERROR, event.bubbles, event.cancelable, "Amazon S3 returned an error: " + data + ".")
                );
            } else {
                this.dispatchEvent(new DataEvent(DataEvent.UPLOAD_COMPLETE_DATA, event.bubbles, event.cancelable, data));
            }
        }
        
        private function isError(responseText:String):Boolean {
            var xml:XMLDocument = new XMLDocument();
            xml.ignoreWhite = true;
            xml.parseXML(responseText);
            var root:XMLNode = xml.firstChild;
            if( root == null || root.nodeName != "Error" )
            {
                return false;
            }
            return true;
        }
        
        private function onHttpStatus(event:HTTPStatusEvent):void {
            _httpStatusErrorReceived = true;
            if(Math.floor(event.status/100) == 2) {
                this.dispatchEvent(new DataEvent(DataEvent.UPLOAD_COMPLETE_DATA, event.bubbles, event.cancelable, "Amazon S3 returned HTTP status " + event.status.toString() + "."));
            } else {
                this.dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, event.bubbles, event.cancelable, "Amazon S3 returned an error: HTTP status " + event.status.toString() + "."));
            }
        }
        
        private function canUseVanityStyle(bucket:String):Boolean {
            if( bucket.length < MIN_BUCKET_LENGTH ||
                bucket.length > MAX_BUCKET_LENGTH ||
                bucket.match(/^\./) ||
                bucket.match(/\.$/) ) {
                return false;
            }
            
            // must be lower case
            if(bucket.toLowerCase() != bucket) {
                return false;
            }
            
            // Check not IPv4-like
            if (bucket.match(/^[0-9]|+\.[0-9]|+\.[0-9]|+\.[0-9]|+$/)) {
                return false;
            }
            
                // Check each label
            if(bucket.match(/\./)) {
                var labels:Array = bucket.split(/\./);
                for (var i:int = 0;i < labels.length; i++) {
                    if(!labels[i].match(/^[a-z0-9]([a-z0-9\-]*[a-z0-9])?$/)) {
                        return false;
                    }
                }
            }
            
            return true;
        }
        
        private function addPolicyAndSignature(postVariables:URLVariables):void {
            if(_accessKeyId == null) {
                throw new Error("An accessKeyId must be specified in order to do an authenticated POST request.");
            }
            postVariables.AWSAccessKeyId = _accessKeyId;
            
            postVariables.policy = _options.policy;
            postVariables.signature = _options.signature;
        }
        
    }
    
}
