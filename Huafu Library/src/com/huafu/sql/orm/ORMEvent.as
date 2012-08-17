package com.huafu.sql.orm
{
	import flash.events.Event;
	
	public class ORMEvent extends Event
	{
		public static const PROPERTY_UPDATE : String = "propertyUpdate";
		public static const LOADED : String = "loaded";
		public static const SAVING : String = "saving";
		public static const SAVED : String = "saved";
		public static const DELETING : String = "deleting";
		public static const DELETED : String = "deleted";
		
		
		private var _property : ORMPropertyDescriptor = null;
		private var _deletedId : int;
		
		
		public function ORMEvent( type : String, property : ORMPropertyDescriptor = null, deletedId : int = undefined )
		{
			super(type, false, (type in [PROPERTY_UPDATE, SAVING, DELETING]));
			if ( type == PROPERTY_UPDATE )
			{
				_property = property;
			}
			else if ( type == DELETED )
			{
				_deletedId = deletedId;
			}
		}
		
		
		public function get property() : ORMPropertyDescriptor
		{
			return _property;
		}
		
		
		public function get deletedIndex() : int
		{
			return _deletedId;
		}
	}
}