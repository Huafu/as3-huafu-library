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


package com.huafu.sql.orm.iterator
{
	import mx.collections.IList;


	public interface IORMIterator extends IList
	{
		/**
		 * Whether the iterator is persistent or not
		 */
		function get isPersistent() : Boolean;
		/**
		 * The ORM class of bojects delivered by the iterator
		 */
		function get ormClass() : Class;
		/**
		 * Creates an array of objects as if it was the result of a query returning all those ORM objects (ie: simple objects
		 * with property names as the column names
		 *
		 * @return The array of all result objects of the ORM objects conatined in the collection
		 */
		function toArrayOfResultObjects() : Array;
	}
}
