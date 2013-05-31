package com.stratoscreen.controller
{
	import com.stratoscreen.Constants;
	import com.stratoscreen.aws.SDBEvent;
	import com.stratoscreen.managers.AppManager;
	import com.stratoscreen.model.domains.Medias;
	import com.stratoscreen.model.domains.OverlayDetail;
	import com.stratoscreen.model.domains.Overlays;
	import com.stratoscreen.view.WinOverlayEdit;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	
	[Event(name="OVERLAY_UPDATE", type="com.stratoscreen.controller.OverlayEditControl")]
	[Event(name="OVERLAY_CLOSE", type="com.stratoscreen.controller.OverlayEditControl")]
	public class OverlayEditControl extends EventDispatcher
	{		
		public static const OVERLAY_UPDATE:String = "OVERLAY_UPDATE";
		public static const OVERLAY_CLOSE:String = "OVERLAY_CLOSE";
		
		private var _parentApplication:DisplayObject;
		private var _appManager:AppManager;
		private var _overlay:Overlays;
		private var _overlayDetail:ArrayCollection;
		private var _overlayType:String;
		private var _overlayEdit:WinOverlayEdit;
		private var _lastEditWindow:DisplayObject;
		
		public function OverlayEditControl(parentApplication:DisplayObject)
		{							
			_parentApplication = parentApplication
			_appManager = Object(_parentApplication).appManager;

			super(null);
		}
		
		public function editOverlay(overlay:Overlays, type:String = ""):void
		{
			_overlay = overlay;
			_overlayType = type;
			
			if (overlay != null) {_overlayType = overlay.type;}  // Override if an Edit			
			if (_overlayType == null || _overlayType == "") {throw new Error("Overlay type not passed");}			
			
			if (_overlay == null)
			{
				_overlay = new Overlays();			
				_overlay.type = type;
				_overlay.accountId = _appManager.currentAccount.itemName;
				_overlay.createdBy = _appManager.currentUser.itemName;
				_overlay.createdDate = new Date();
				
				_overlayDetail = new ArrayCollection();
				openWindow(true);				
			}
			else
			{
				var sql:String = "Select * from OverlayDetail where overlayId = '" + _overlay.itemName + "' ";
				sql += "and z is not null order by z";
				_appManager.sdb.select(sql, loadOverlayDetailHandler, OverlayDetail);
			}			
		}
		
		private function loadOverlayDetailHandler(event:SDBEvent):void
		{
			if (!event.success)
			{
				Alert.show("Could not load overlay detail. Please try again later", "Load Error");
				return;
			}
			
			_overlayDetail = new ArrayCollection(event.result as Array);
			openWindow(false);
		}
		
		private function openWindow(isNew:Boolean):void
		{
			_overlayEdit = new WinOverlayEdit();
			_overlayEdit.overlay = _overlay;
			_overlayEdit.isNew = isNew;
			_overlayEdit.overlayDetail = _overlayDetail ;
			_overlayEdit.addEventListener(CloseEvent.CLOSE, overlayEdit_closeHandler);
			_overlayEdit.width = _parentApplication.width * Constants.EDIT_WINDOW_SIZE;
			_overlayEdit.height = _parentApplication.height * Constants.EDIT_WINDOW_SIZE;
			
			switch (_overlayType)
			{
				case Overlays.TYPE_CHANNEL:
					_overlayEdit.title = "Edit Channel Overlay";
					break;
				case Overlays.TYPE_MEDIA:
					_overlayEdit.title = "Edit Media Overlay";
					break;
				case Overlays.TYPE_MEDIA_GROUP:
					_overlayEdit.title = "Edit Media Group Overlay";
					break;
			}
			
			_lastEditWindow = _appManager.currentEditWindow
			_appManager.currentEditWindow = _overlayEdit;
			PopUpManager.addPopUp(_overlayEdit, _parentApplication, true);				
		}
		
		private function overlayEdit_closeHandler(event:Event):void
		{
			_appManager.currentEditWindow = _lastEditWindow; 
			if (_overlayEdit.canceled) {return;}
			
			// Save the detail first. Just in case this fails
			_appManager.sdb.updateDomain(_overlayEdit.overlayDetail.source, updateOverlayDetailHandler);
		}
		
		private function updateOverlayDetailHandler(event:SDBEvent):void
		{
			if (!event.success)
			{
				Alert.show("Could not save Overlay Detail. Please try again later.", "Update Error");
				return;
			}
			
			// Save the headers next
			_overlay.updated = true;
			_overlay.modifiedBy = _appManager.currentUser.itemName;
			_overlay.modifiedDate = new Date();
			_appManager.sdb.updateDomain([_overlay], updateOverlayHandler);
		}
		
		private function updateOverlayHandler(event:SDBEvent):void
		{
			if (!event.success)
			{
				Alert.show("Could not save Overlay. Please try again later.", "Update Error");
				return;
			}
			
			this.dispatchEvent(new Event(OVERLAY_UPDATE));
		}

	}
}