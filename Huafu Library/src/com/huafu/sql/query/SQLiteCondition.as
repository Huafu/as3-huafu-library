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


	/**
	 * Represents a SQL condition
	 */
	public class SQLiteCondition
	{


		/**
		 * Cast anything that can resolve to a SQLiteCondition to an object of this type
		 *
		 * @param arrayOrCondition Can be a String with the condition, or an array with
		 * the first and second parameter of this class, or even a SQLiteCondition object
		 * in which case this object is just returned
		 * @return The SQLiteCondition object
		 */
		public static function cast( arrayOrCondition : * ) : SQLiteCondition
		{
			if (arrayOrCondition is SQLiteCondition)
			{
				return arrayOrCondition as SQLiteCondition;
			}
			if (arrayOrCondition is Array)
			{
				return new SQLiteCondition(arrayOrCondition[0], arrayOrCondition[1]);
			}
			return SQLiteCondition(arrayOrCondition);
		}


		/**
		 * Creates a new SQL condition
		 *
		 * @param conditionString The SQL code of the condition
		 * @param parameters Each more parameter given to the constructor will be
		 * treated as a bind parameter required for this condition
		 */
		public function SQLiteCondition( conditionString : String, ... parameters : Array )
		{
			this.conditionString = conditionString;
			this.parameters = parameters;
		}

		/**
		 * Stores the condition string
		 */
		internal var conditionString : String;
		/**
		 * Stores all parameters
		 */
		internal var parameters : Array;


		/**
		 * Get the SQL code of the condition, automatically binding the parameters to the
		 * given sql parameters object
		 *
		 * @param parametersDestination Where to bind the parameters if any
		 * @return The SQL code of the condition
		 */
		public function sqlCode( parametersDestination : SQLiteParameters = null ) : String
		{
			if (parametersDestination)
			{
				parametersDestination.bind.apply(parametersDestination, parameters);
			}
			return conditionString;
		}
	}
}
