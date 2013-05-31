package com.stratoscreen.aws
{
	/**
	 * Offload the calls for a domain update to a new process. 
	 * 
	 * When a domain is updated we will run a second process to also handle deletes.
	 *  
	 * @author pjsteele
	 * 
	 */
	
	import com.stratoscreen.model.OrderedPair;
	import com.stratoscreen.utils.GUID;
	import com.stratoscreen.utils.LogUtils;
	
	import mx.utils.StringUtil;
	
	public class SDBUpdate
	{
		private static const MAX_ROWS:int = 20; 
		
		private var _sdb:SDBClass;
		private var _callback:Function;
		private var _replace:Boolean;
		private var _updateRows:Array;
		private var _deletedRows:Array;
		private var _updateIndex:int = 0;
		private var _deleteIndex:int = 0;
		private var _partialUpdate:Boolean = false;
		private var _partialDelete:Boolean = false;
		
		public function SDBUpdate(sdb:SDBClass, values:Array, callback:Function, replace:Boolean)
		{
			_sdb = sdb;	// Reuse the parent class for the AWS calls
			_callback = callback;
			_replace = replace;
			
			// Seperate the deletes from the updates
			_updateRows = new Array();
			_deletedRows = new Array();
			
			// Every array should be an object derrived from the
			// com.stratoscreen.model.domains.DomainBas class
			for (var i:int = 0; i < values.length; i++)
			{
				if (values[i].deleted)
				{
					_deletedRows.push(values[i]);	
				}
				else
				{
					if (values[i].updated)
					{
						_updateRows.push(values[i]);
					}
				}
			}
			
			// Call the delete process first. If there are rows
			if (_deletedRows.length > 0)
			{
				deleteDomainRows()
			}
			else
			{
				updateDomainRows();
			}
		}
		
		private function deleteDomainRows():void
		{
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("DomainName", _sdb.getDomainName(_deletedRows[0])));
			
			var count:int = 0;
			for (var i:int = _deleteIndex; i < _deletedRows.length; i++)			
			{
				pairs.push(new OrderedPair("Item." + i + ".ItemName", _deletedRows[i].itemName ));
				
				count ++;
				if (count > MAX_ROWS)
				{
					_partialDelete = true;
					_deleteIndex = i + 1;
					break;
				}
			}
			
			_sdb.execute("BatchDeleteAttributes", pairs, deleteDomainRows_handler);				
		}
		
		private function deleteDomainRows_handler(event:SDBEvent):void
		{
			// Check for a successful delete
			var success:Boolean = true;
			var msg:String = ""
			if (event != null)
			{
				if (!event.success)
				{
					// Continue on we may have to clean up later
					msg = "Error deleting items from domain " + _sdb.getDomainName(_deletedRows[0]);
					LogUtils.writeToLog(msg, LogUtils.WARN);
				}
			}
			
			// If we have nothing to delete return to the orginating call
			if (_updateRows.length <= 0)
			{
				var sdbEvent:SDBEvent = new SDBEvent();
				sdbEvent.result = msg;
				sdbEvent.success = success;
				
				_callback(sdbEvent);
				return;
			}
			
			// We may need to do another 20 deletes
			if (_partialDelete)
			{
				_partialDelete = false;
				deleteDomainRows();
			}
			else
			{
				updateDomainRows();
			}
		}
		
		private function updateDomainRows():void
		{
			// If we have nothing to delete return to the orginating call
			if (_updateRows.length <= 0)
			{
				var sdbEvent:SDBEvent = new SDBEvent();
				sdbEvent.result = "";
				sdbEvent.success = true;
				
				_callback(sdbEvent);
				return;
			}
			
			var pairs:Array = new Array();
			pairs.push(new OrderedPair("DomainName", _sdb.getDomainName(_updateRows[0])));
			
			var count:int = 0;
			for (var i:int = _updateIndex; i < _updateRows.length; i++)
			{
				// Start the ordered pairs off with th item name
				pairs.push(new OrderedPair("Item." + i + ".ItemName", _updateRows[i].itemName ));
				
				// Add an ordered pair for every property in the row 				
				var properties:Array = _sdb.getProperties(_updateRows[i]);
				for (var j:int = 0; j < properties.length; j++)
				{
					var property:String = properties[j] 
					var value:String = _updateRows[i][property];
					if (value == null) {value = "";}
					pairs.push(new OrderedPair("Item." + i + ".Attribute." + j + ".Name", property ));
					pairs.push(new OrderedPair("Item." + i + ".Attribute." + j + ".Replace", _replace.toString()));
					pairs.push(new OrderedPair("Item." + i + ".Attribute." + j + ".Value", value));
				}
				
				count ++;
				if (count > MAX_ROWS)
				{
					_partialUpdate = true;
					_updateIndex = i + 1;
					break;
				}					
			}
			
			_sdb.execute("BatchPutAttributes", pairs, updateDomainRows_handler);	
		}
		
		private function updateDomainRows_handler(event:SDBEvent):void
		{
			if (!event.success) {_callback(event);}
			
			// We may need to do another 20 deletes
			if (_partialUpdate)
			{
				_partialUpdate = false;
				updateDomainRows();
			}
			else
			{
				_callback(event);
			}			
		}
		
	}
}