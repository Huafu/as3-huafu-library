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
	import com.huafu.sql.SQLiteStatement;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.errors.IllegalOperationError;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;


	/**
	 * Used to browse a result with rows that each contains an ORM object
	 */
	public class ORMIterator extends Proxy
	{


		/**
		 * Creates a new ierator for the given ORM class and data/statement
		 *
		 * @param ormClass The ORM class of the models that this iterator will iterate
		 * @param statementOrData Either a SQLStatement or anything thta can cast to an array.
		 * If a SQLStatement is given, it'll be executed and used to get the ORM objects to iterate.
		 * If it's an Array or anything that can cast to an Array, it'll be used as the list of
		 * ORM objects to iterate through
		 * @param objectUsedToBindParameters The object used to (re)bind parameters to
		 * the statement given as second parameter when a new iteration occurs. You MUST provide it
		 * when the second parameter is a statement and you want the iterator to (re)load the
		 * data on the first iteration (and each other new iteration if the last parameter is true)
		 * @param loadOnEveryNewIteration If true, the statement will be binded with parameters
		 * and executed not only for the first iteraton, but for every new iteration
		 */
		public function ORMIterator( ormClass : Class, statementOrData : *, objectUsedToBindParameters : Object
									 = null, loadOnEveryNewIteration : Boolean = false )
		{
			_objectUsedToReaload = objectUsedToBindParameters;
			_statement = statementOrData is SQLStatement ? statementOrData : null;
			_loadOnEveryNewIteration = loadOnEveryNewIteration;
			if (_objectUsedToReaload)
			{
				_data = null;
			}
			else
			{
				_data = ((_statement ? _statement.getResult().data : statementOrData) as Array).slice();
			}
			_ormClass = ormClass;
		}

		/**
		 * The data which is browsed is stored here
		 */
		internal var _data : Array;
		/**
		 * Stores whether to executre the statement on each new iteration or not
		 */
		internal var _loadOnEveryNewIteration : Boolean;
		/**
		 * If given, when the iteration will be initiated, the data wil be binded to
		 * the statement using this object
		 */
		internal var _objectUsedToReaload : Object;
		/**
		 * A pointer to the ORM class that this iterator delivers
		 */
		internal var _ormClass : Class;
		/**
		 * The statement object
		 */
		internal var _statement : SQLiteStatement;


		/**
		 * The number of items in the collection
		 */
		public function get count() : int
		{
			if (!_data)
			{
				_load();
			}
			return _data.length;
		}


		/**
		 * The object used to bind parameters
		 */
		public function set sourceUsedToReload( object : Object ) : void
		{
			_objectUsedToReaload = object;
			// invalidate the data
			_data = null;
		}


		/**
		 * Get all the items in an array
		 *
		 * @return The array containing all ORM instances that this iterator would have ran through
		 */
		public function toArray() : Array
		{
			var res : Array = new Array(), item : ORM;
			for each (item in this)
			{
				res.push(item);
			}
			return res;
		}


		/**
		 * Used to (re)load the data
		 */
		internal function _load() : void
		{
			var name : String, cleanName : String;
			// (re)bind the parameters
			for (name in _statement.parameters)
			{
				cleanName = name.substr(1);
				if (_objectUsedToReaload.hasOwnProperty(cleanName))
				{
					_statement.parameters[name] = _objectUsedToReaload[cleanName];
				}
			}
			// re-execute only if the parameters are new, or no data yet, or force reload on
			// every new iteration
			if (_loadOnEveryNewIteration || !_data)
			{
				_statement.safeExecute();
				_data = _statement.getResult().data.slice();
			}
		}


		flash_proxy override function getProperty( name : * ) : *
		{
			if (name is String)
			{
				throw new IllegalOperationError("You cannot access property '" + name + "' on an ORMIterator");
			}
			if (!_data)
			{
				_load();
			}
			return _get(name);
		}


		/**
		 * Get the next item's index looking at the given index
		 *
		 * @param index The current index
		 * @return The index of the next item
		 */
		internal function nextItemIndex( index : int ) : int
		{
			if (index == 0 && _objectUsedToReaload && (_loadOnEveryNewIteration || !_data))
			{
				_load();
			}
			if (index >= _data.length)
			{
				return 0;
			}
			return index + 1;
		}


		flash_proxy override function nextName( index : int ) : String
		{
			return String(index - 1);
		}


		flash_proxy override function nextNameIndex( index : int ) : int
		{
			return nextItemIndex(index);
		}


		flash_proxy override function nextValue( index : int ) : *
		{
			return _get(index - 1);
		}


		/**
		 * Get an item looking at its index, creating the ORM instance for it if not created yet
		 *
		 * @param index The index of the item to get
		 * @return ORM The ORM instance for thi item
		 */
		private function _get( index : int ) : ORM
		{
			var res : ORM, v : *;
			if (!((v = _data[index]) is ORM))
			{
				res = ORM.factory(_ormClass);
				res.loadDataFromSqlResult(v);
				_data[index] = res;
				return res;
			}
			return v;
		}
	}
}
