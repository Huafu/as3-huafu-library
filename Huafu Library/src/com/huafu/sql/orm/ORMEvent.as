package com.huafu.sql.orm
{
	import flash.events.Event;
	
	/**
	 * Events that can be fired by an ORM object
	 */
	public class ORMEvent extends Event
	{
		/**
		 * Fired when a proeprty is updated
		 */
		public static const PROPERTY_UPDATE : String = "propertyUpdate";
		/**
		 * Fired when the ORM object has been loaded successfully
		 */
		public static const LOADED : String = "loaded";
		/**
		 * Fired before the ORM object begin to be saved
		 */
		public static const SAVING : String = "saving";
		/**
		 * Fired when an ORM object has been saved correctly
		 */
		public static const SAVED : String = "saved";
		/**
		 * Fired before deleting an ORM object
		 */
		public static const DELETING : String = "deleting";
		/**
		 * Fired when an ORM object has been deleted successfully
		 */
		public static const DELETED : String = "deleted";
		
		
		/**
		 * Stores the name of the property that has been updated
		 */
		private var _propertyName : String = null;
		/**
		 * Stores the ID of the ORM object that has been deleted
		 */
		private var _deletedId : int;
		
		
		/**
		 * Creates an ORMEvent
		 * 
		 * @param type The type of event
		 * @param property The description of the ORM property that has been updated
		 * @param deletedId The ID of the ORM object that has been deleted
		 */
		public function ORMEvent( type : String, propertyName : String = null, deletedId : int = undefined )
		{
			super(type, false, (type in [PROPERTY_UPDATE, SAVING, DELETING]));
			if ( type == PROPERTY_UPDATE )
			{
				_propertyName = propertyName;
			}
			else if ( type == DELETED )
			{
				_deletedId = deletedId;
			}
		}
		
		
		/**
		 * The name of the property that has been updated
		 */
		public function get propertyName() : String
		{
			return _propertyName;
		}
		
		
		/**
		 * The ID of the ORM object that has been deleted
		 */
		public function get deletedIndex() : int
		{
			return _deletedId;
		}
	}
}