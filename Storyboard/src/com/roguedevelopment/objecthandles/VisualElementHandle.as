package com.roguedevelopment.objecthandles
{
	import com.stratoscreen.managers.AppManager;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import spark.core.SpriteVisualElement;
	
	/**
	 * A handle class based on SpriteVisualElement which is suitable for adding to
	 * a Flex 4 Group based container.
	 **/
	public class VisualElementHandle extends SpriteVisualElement implements IHandle
	{
		private var _descriptor:HandleDescription;		
		private var _targetModel:Object;
		protected var isOver:Boolean = false;
		
		private static var _appManager:AppManager;
		
		public function get handleDescriptor():HandleDescription
		{
			return _descriptor;
		}
		public function set handleDescriptor(value:HandleDescription):void
		{
			_descriptor = value;
		}
		public function get targetModel():Object
		{
			return _targetModel;
		}
		public function set targetModel(value:Object):void
		{
			_targetModel = value;
		}
		
		public static function set appManager(value:AppManager):void
		{
			_appManager = value;
		}
		
		public function VisualElementHandle()
		{
			super();
			
			addEventListener( MouseEvent.ROLL_OUT, onRollOut );
			addEventListener( MouseEvent.ROLL_OVER, onRollOver );

			//redraw();
		}
		
		protected function onRollOut( event : MouseEvent ) : void
		{
			isOver = false;
			redraw();
		}
		protected function onRollOver( event:MouseEvent):void
		{
			isOver = true;
			redraw();
		}
		
		public function redraw() : void
		{
			graphics.clear();
			if( isOver )
			{
				graphics.lineStyle(1,0x00F000);
				graphics.beginFill(0x80FF80,1);
			}
			else
			{
				graphics.lineStyle(1,0x00C000);
				graphics.beginFill(0x00FF00,1);
			}
			
			// Adjust for scaling
			var boxSize:Number = 10 / _appManager.overlayEditScale;
			var boxOffset:Number = boxSize / -2;
			var boxCorner:Number = _descriptor.role == HandleRoles.ROTATE ? 10 : 2;
			boxCorner = boxCorner / _appManager.overlayEditScale;
			
			graphics.drawRoundRect(boxOffset, boxOffset, boxSize, boxSize, boxCorner, boxCorner);
			graphics.endFill();			
		}
	}
}