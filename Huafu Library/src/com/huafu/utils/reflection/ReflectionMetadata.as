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


package com.huafu.utils.reflection
{
	import com.huafu.utils.HashMap;


	/**
	 * Reflects a metadata of a class, method or property
	 */
	public class ReflectionMetadata
	{


		/**
		 * Creates a new reflection metadata
		 *
		 * @param owner The owner of this metadata
		 * @param node The XML node of the metadata
		 */
		public function ReflectionMetadata(owner : ReflectionBase, node : XML)
		{
			_xml = node;
			_name = node.@name.toString();
			_owner = owner;
		}


		/**
		 * Cached arguments of this metadata
		 */
		private var _args : HashMap;


		/**
		 * The name of the metadaa
		 */
		private var _name : String;


		/**
		 * The owner of this metadata
		 */
		private var _owner : ReflectionBase;


		/**
		 * The xml node of the metadata
		 */
		private var _xml : XML;


		/**
		 * Get the value of a metadata's argument looking at its name
		 *
		 * @param argKey The key of the argument
		 * @param ifNotDefined The value returned if no such argument present
		 * @return The value of the argument with given name
		 */
		public function argValue(argKey : String, ifNotDefined : * = null) : *
		{
			_loadArgs();
			if (!_args.exists(argKey))
			{
				return ifNotDefined;
			}
			return _args.get(argKey);
		}


		/**
		 * Get the value of a metadata's argument as a boolean looking at its name
		 *
		 * @param argKey The key of the argument
		 * @param ifNotDefined The value returned if no such argument present
		 * @return The value of the argument with given name
		 * @see #argValue()
		 */
		public function argValueBoolean(argKey : String, ifNotDefined : Boolean = false) : Boolean
		{
			var res : String = argValueString(argKey);
			if (res === null)
			{
				return ifNotDefined;
			}
			return (res.toLowerCase() in ["1", "true", "on", "yes", "y", "o"]);
		}


		/**
		 * Get the value of a metadata's argument as an integer looking at its name
		 *
		 * @param argKey The key of the argument
		 * @param ifNotDefined The value returned if no such argument present
		 * @return The value of the argument with given name
		 * @see #argValue()
		 */
		public function argValueInteger(argKey : String, ifNotDefined : int = undefined) : int
		{
			var res : String = argValueString(argKey);
			if (res === null)
			{
				return ifNotDefined;
			}
			return parseInt(res);
		}


		/**
		 * Get the value of a metadata's argument as a number looking at its name
		 *
		 * @param argKey The key of the argument
		 * @param ifNotDefined The value returned if no such argument present
		 * @return The value of the argument with given name
		 * @see #argValue()
		 */
		public function argValueNumber(argKey : String, ifNotDefined : Number = undefined) : Number
		{
			var res : String = argValueString(argKey);
			if (res === null)
			{
				return ifNotDefined;
			}
			return parseFloat(res);
		}


		/**
		 * Get the value of a metadata's argument as a string looking at its name
		 *
		 * @param argKey The key of the argument
		 * @param ifNotDefined The value returned if no such argument present
		 * @return The value of the argument with given name
		 * @see #argValue()
		 */
		public function argValueString(argKey : String, ifNotDefined : String = null) : String
		{
			var res : * = argValue(argKey);
			if (res)
			{
				return res.toString();
			}
			return ifNotDefined;
		}


		/**
		 * Finds wether an argument is present or not
		 *
		 * @param name The name of the argument to test existence
		 * @return Returns true if the argument is defined, else false
		 */
		public function hasArgument(name : String) : Boolean
		{
			_loadArgs();
			return _args.exists(name);
		}


		/**
		 * The name of the metadata
		 */
		public function get name() : String
		{
			return _name;
		}


		/**
		 * The owner of the metadata
		 */
		public function get owner() : ReflectionBase
		{
			return _owner;
		}


		/**
		 * Load all the arguments if not loaded already
		 */
		private function _loadArgs() : void
		{
			var x : XML, k : String, v : *;
			if (!_args)
			{
				_args = new HashMap();
				for each (x in _xml.arg)
				{
					k = x.@key.toString();
					v = x.@value;
					if (!k)
					{
						k = v.toString();
						v = true;
					}
					_args.set(k, v);
				}
			}
		}
	}
}
