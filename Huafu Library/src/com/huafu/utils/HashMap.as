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


package com.huafu.utils
{
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import mx.collections.ArrayList;
	import mx.utils.ArrayUtil;


	/**
	 * Allows to access properties with set/get/unset and also the ability to
	 * iterate over them
	 */
	public class HashMap extends Proxy
	{


		/**
		 * Constructs a new hash map object
		 *
		 * @param initialData An optional object to get value(s) from
		 */
		public function HashMap( initialData : Object = null )
		{
			var key : String;

			_keys = new ArrayList();
			_data = {};
			if (initialData)
			{
				if (initialData is HashMap)
				{
					initialData = (initialData as HashMap).toObject();
				}
				for (key in initialData)
				{
					_set(key, initialData[key]);
				}
			}
		}

		/**
		 * All data of this object
		 */
		private var _data : Object;
		/**
		 * All keys of this object
		 */
		private var _keys : ArrayList;


		/**
		 * Finds wheteher a property exists or not
		 *
		 * @param name The name of the property to test existence
		 * @return Returns true if the proeprty exists, else false
		 */
		public function exists( name : String ) : Boolean
		{
			return (_keyIndex(name) != -1);
		}


		/**
		 * Get the value associated with a property
		 *
		 * @param name The name of the property to get
		 * @param ifUndefined The value returned if the proeprty isn't defined
		 * @return The value of the property
		 */
		public function get( name : String, ifUndefined : * = null ) : *
		{
			if (_keyIndex(name) == -1)
			{
				return ifUndefined;
			}
			return _data[name];
		}


		/**
		 * Returns all keys of the map in an array
		 *
		 * @return The array of all keys
		 */
		public function keys() : Array
		{
			return _keys.toArray();
		}


		/**
		 * Set or update a property's value
		 *
		 * @param name The name of the property to set
		 * @param value The value of the property
		 * @return Returns this object to do chained calls
		 */
		public function set( name : String, value : * ) : HashMap
		{
			_set(name, value, (_keyIndex(name) == -1));
			return this;
		}


		/**
		 * Return all values in an array
		 *
		 * @return An array with all values that have been set so far
		 */
		public function toArray() : Array
		{
			var o : *, res : Array = new Array();
			for each (o in _data)
			{
				res.push(o);
			}
			return res;
		}


		/**
		 * Returns all the key/value pairs in an object
		 *
		 * @return The object with all properties set with the key/value pairs of this object
		 */
		public function toObject() : Object
		{
			var name : String, res : Object = {};
			for each (name in this)
			{
				res[name] = _data[name];
			}
			return res;
		}


		/**
		 * Unset a property
		 *
		 * @param name The name of the property to unset
		 * @return Returns true if this proeprty existed and has been removed
		 * else returns false
		 */
		public function unset( name : String ) : Boolean
		{
			var index : int;
			if ((index = _keyIndex(name)) != -1)
			{
				_keys.removeItemAt(index);
				delete _data[name];
				return true;
			}
			return false;
		}


		/**
		 * @copy #unset
		 */
		flash_proxy override function deleteProperty( name : * ) : Boolean
		{
			return unset(name);
		}


		/**
		 * @copy #get
		 */
		flash_proxy override function getProperty( name : * ) : *
		{
			return get(name);
		}


		/**
		 * @copy #exists
		 */
		flash_proxy override function hasProperty( name : * ) : Boolean
		{
			return exists(name);
		}


		flash_proxy override function nextName( index : int ) : String
		{
			return _keys.getItemAt(index - 1) as String;
		}


		flash_proxy override function nextNameIndex( index : int ) : int
		{
			if (index >= _keys.length)
			{
				return 0;
			}
			return index + 1;
		}


		flash_proxy override function nextValue( index : int ) : *
		{
			return _data[_keys.getItemAt(index - 1)];
		}


		/**
		 * @copy #set
		 */
		flash_proxy override function setProperty( name : *, value : * ) : void
		{
			set(name, value);
		}


		/**
		 * Finds the index of a key in the keys array
		 *
		 * @param name The name of the key to get the index of
		 * @return The index of that key or -1 if no such index
		 */
		private function _keyIndex( name : String ) : int
		{
			return _keys.getItemIndex(name);
		}


		/**
		 * Set a property adding or not the key to they list of keys
		 *
		 * @param name The name of the property
		 * @param value The value of the property
		 * @param addNameToKeys If true, will add the name of the property to the list of keys
		 */
		private function _set( name : String, value : *, addNameToKeys : Boolean = true ) : void
		{
			_data[name] = value;
			if (addNameToKeys)
			{
				_keys.addItem(name);
			}
		}
	}
}
