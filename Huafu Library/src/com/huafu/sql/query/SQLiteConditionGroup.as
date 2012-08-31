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
	 * Handles groups of conditions joined with AND or OR keywords
	 */
	public class SQLiteConditionGroup
	{
		public static const AND : String     = "AND";
		public static const AND_NOT : String = "AND NOT";
		public static const OR : String      = "OR";
		public static const OR_NOT : String  = "OR NOT";


		/**
		 * Creates a new condition group
		 *
		 * @param owner The owner if this is a sub-block
		 */
		public function SQLiteConditionGroup( owner : SQLiteConditionGroup = null )
		{
			reset();
			_owner = owner;
		}

		/**
		 * Stores all conditions and logic operators
		 */
		internal var list : Array;

		/**
		 * The owner of this group if it's in another block (for parentheses)
		 */
		private var _owner : SQLiteConditionGroup;


		/**
		 * Add a condition to the group
		 *
		 * @param condition Either a string representing the condition or the condition object
		 * @param logicOperator The logic operator if this is not the first condition
		 * @return Returns this object to do chained calls
		 */
		public function add( condition : *, logicOperator : String = AND ) : SQLiteConditionGroup
		{
			if (list.length > 0)
			{
				list.push(logicOperator);
			}
			if (condition is SQLiteConditionGroup)
			{
				(condition as SQLiteConditionGroup)._owner = this;
			}
			list.push(SQLiteCondition.cast(condition));
			return this;
		}


		/**
		 * The count of conditions in this group and possible sub groups
		 */
		public function get length() : int
		{
			var i : int, res : int = 0;
			for (i = 0; i < list.length; i += 2)
			{
				if (list[i] is SQLiteConditionGroup)
				{
					res += (list[i] as SQLiteConditionGroup).length;
				}
				else
				{
					res += 1;
				}
			}
			return res;
		}


		/**
		 * The group owning this group if any
		 */
		public function get ownerGroup() : SQLiteConditionGroup
		{
			return _owner;
		}


		/**
		 * Resets the condition group
		 */
		public function reset() : void
		{
			list = new Array();
		}


		/**
		 * Get the SQL code of the condition group
		 *
		 * @param parametersDestination The SQLiteParameters object where to bind parameters to
		 * @return The SQL code
		 */
		public function sqlCode( parametersDestination : SQLiteParameters = null ) : String
		{
			var item : *, i : int, res : String = "";
			if (list.length < 1)
			{
				return null;
			}
			for (i = 0; i < list.length; i++)
			{
				if (i % 2 == 0)
				{
					res += (list[i] as SQLiteCondition).sqlCode(parametersDestination);
				}
				else
				{
					res += " " + (list[i] as String) + " ";
				}
			}
			if (_owner)
			{
				res = "(" + res + ")";
			}
			return res;
		}
	}
}
