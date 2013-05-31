package com.stratoscreen.model
{
	public class Step
	{
		public var startMessage:String;
		public var func:Function;
		public var completeHandler:Function;
		public var stopOnFail:Boolean;
		public var argument:Object;

		public function Step(startMessage:String, func:Function, completeHandler:Function = null, 
									stopOnFail:Boolean = true, argument:Object = null)
		{
			this.startMessage = startMessage;
			this.func = func;
			this.completeHandler = completeHandler;
			this.stopOnFail = stopOnFail;
			this.argument = argument;
		}		
	}
}