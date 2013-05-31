package com.stratoscreen.utils
{
	import com.stratoscreen.model.FilterPair;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;


	public class DataUtils
	{
		/**
		 * Using an ArrayCollection, take an existing array and apply sorting and filtering. 
		 * 
		 * The sort fields will be a an array of SortPair. 
		 * 
		 * The filter fields will be an array of FilterPair
		 *  
		 * @param source
		 * @param sortFields
		 * @param filterFields
		 * 
		 * @return Array
		 * 
		 */
		public static function sortAndFilter(source:Array, sortFields:Array, filterFields:Array):Array
		{
			// In the off chance we are passed a null Source. Just return a blank array
			if (source == null)
			{
				LogUtils.writeToLog("A null source was passed. Return blank array", LogUtils.WARN);
				return new Array();
			}
			
			
			var array:ArrayCollection = new ArrayCollection(source);
			
			var sort:Sort = new Sort();
			
			if (sortFields != null)
			{
				sort.fields = sortFields;				
				array.sort = sort;
				array.refresh();
			}			
			// Create the array to return
			var newArray:Array = new Array();			
			
			for (var i:int = 0; i < array.length; i++)
			{
				var includeRow:Boolean = false;			
				if (filterFields == null)
				{
					includeRow = true;
				}
				else
				{
					for each (var pair:FilterPair in filterFields)
					{
						if (array[i][pair.field] == pair.value) 
						{
							includeRow = true;
							break;
						}	
					}
				}
				
				if (includeRow) {newArray.push(array[i]);}
			}
				
			return newArray; 
		}
	}
}