/*============================================================================*/
/*                                                                            */
/*    Huafu Gandon, hereby disclaims all copyright interest in the            */
/*    library “Huafu Library” (which makes passes at compilers)               */
/*    written by Huafu Gandon.                                                */
/*                                                                            */
/*    Huafu Gandon <huafu.gandon@gmail.com>, 15 August 2012                   */
/*                                                                            */
/*                                                                            */
/*    This file is part of Huafu Library.                                     */
/*                                                                            */
/*    Huafu Library is free software: you can redistribute it and/or modify   */
/*    it under the terms of the GNU General Public License as published by    */
/*    the Free Software Foundation, either version 3 of the License, or       */
/*    (at your option) any later version.                                     */
/*                                                                            */
/*    Huafu Library is distributed in the hope that it will be useful,        */
/*    but WITHOUT ANY WARRANTY; without even the implied warranty of          */
/*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           */
/*    GNU General Public License for more details.                            */
/*                                                                            */
/*    You should have received a copy of the GNU General Public License       */
/*    along with Huafu Library.  If not, see <http://www.gnu.org/licenses/>.  */
/*                                                                            */
/*============================================================================*/


package com.huafu.sql.orm
{
	import flash.events.Event;


	/**
	 * Events that can be fired by an ORM object
	 */
	public class ORMEvent extends Event
	{
		/**
		 * Fired when an ORM object has been deleted successfully
		 */
		public static const DELETED : String = "deleted";


		/**
		 * Fired before deleting an ORM object
		 */
		public static const DELETING : String = "deleting";


		/**
		 * Fired when the ORM object has been loaded successfully
		 */
		public static const LOADED : String = "loaded";


		/**
		 * Fired when a proeprty is updated
		 */
		public static const PROPERTY_UPDATE : String = "propertyUpdate";


		/**
		 * Fired when an ORM object has been saved correctly
		 */
		public static const SAVED : String = "saved";


		/**
		 * Fired before the ORM object begin to be saved
		 */
		public static const SAVING : String = "saving";


		/**
		 * Creates an ORMEvent
		 *
		 * @param type The type of event
		 * @param property The description of the ORM property that has been updated
		 * @param deletedId The ID of the ORM object that has been deleted
		 */
		public function ORMEvent(type : String, propertyName : String = null, deletedId : int = undefined)
		{
			super(type, false, (type in [PROPERTY_UPDATE, SAVING, DELETING]));
			if (type == PROPERTY_UPDATE)
			{
				_propertyName = propertyName;
			}
			else if (type == DELETED)
			{
				_deletedId = deletedId;
			}
		}


		/**
		 * Stores the ID of the ORM object that has been deleted
		 */
		private var _deletedId : int;


		/**
		 * Stores the name of the property that has been updated
		 */
		private var _propertyName : String = null;


		/**
		 * The ID of the ORM object that has been deleted
		 */
		public function get deletedIndex() : int
		{
			return _deletedId;
		}


		/**
		 * The name of the property that has been updated
		 */
		public function get propertyName() : String
		{
			return _propertyName;
		}
	}
}
