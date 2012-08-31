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


package com.huafu.sql.query
{
	import com.huafu.sql.SQLiteStatement;
	import com.huafu.utils.reflection.ReflectionClass;
	import flash.data.SQLStatement;
	import flash.errors.IllegalOperationError;
	import flash.utils.Proxy;


	/**
	 * Handle the binding and storage of name indexed and/or 0 indexed parameters
	 */
	public class SQLiteParameters extends Proxy
	{

		/**
		 * Creates a new parameter object
		 * @see #bind
		 */
		public function SQLiteParameters( ... parameters : Array )
		{
			super();
			namedParams = {};
			zeroBasedParams = new Array();
			bind.apply(this, parameters);
		}

		/**
		 * The name indexed parameters
		 */
		internal var namedParams : Object;
		/**
		 * The 0 based indexed parameters
		 */
		internal var zeroBasedParams : Array;


		/**
		 * Binds many parameters given one by one as each argument of this method
		 * Each parameter can be anything that calling bindOne method with only
		 * one argument will accept as first argument
		 *
		 * @return Returns this object to do chained calls
		 * @se #bindOne
		 */
		public function bind( ... parameters : Array ) : SQLiteParameters
		{
			var param : *;
			for each (param in parameters)
			{
				bindOne(param);
			}
			return this;
		}


		/**
		 * Binds only one parameter
		 *
		 * @param objectOrNameOrValue Can be the name of the parameter if the second attribute is given,
		 * or an object with the keys as names and values as values, or the value of a zero
		 * based parameter which means it'll be pushed after the other 0 based paramters
		 * @param value The value of the parameter if the first argument is a string and so its name
		 * @return Returns this object to do chained calls
		 */
		public function bindOne( objectOrNameOrValue : *, value : * = null ) : SQLiteParameters
		{
			var name : String;
			if (arguments.length == 2)
			{
				if (!(objectOrNameOrValue is String))
				{
					throw new IllegalOperationError("The first argument of bindOne method must be a String if the second argument is given");
				}
				namedParams[objectOrNameOrValue as String] = value;
			}
			else
			{
				if (ReflectionClass.isStrictly(objectOrNameOrValue, Object))
				{
					for (name in objectOrNameOrValue)
					{
						namedParams[name] = objectOrNameOrValue[name];
					}
				}
				else
				{
					zeroBasedParams.push(objectOrNameOrValue);
				}
			}
			return this;
		}


		/**
		 * Bind all parameters to a SQL statement
		 *
		 * @param statement The statement on which to bin all parameters
		 */
		public function bindTo( statement : SQLStatement ) : void
		{
			var name : String, i : int;
			for (name in namedParams)
			{
				statement.parameters[name] = namedParams[name];
			}
			for (i = 0; i < zeroBasedParams.length; i++)
			{
				statement.parameters[i] = zeroBasedParams[i];
			}
		}
	}
}
