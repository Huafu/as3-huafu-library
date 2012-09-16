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
	import flash.errors.IllegalOperationError;


	/**
	 * Helper to manipulate RegExp
	 */
	public final class RegExpUtil
	{
		private static var _escape : RegExp;


		/**
		 * Escape regex special caracters in the given string
		 *
		 * @param source The string containing the possible regex special chars to escape
		 * @return The string with escaped regex special chars
		 */
		public static function escape(source : String) : String
		{
			if (!_escape)
			{
				_escape = new RegExp("([{}\(\)\^$&.\*\?\/\+\|\[\\\\]|\]|\-)", "g");
			}
			return source.replace(_escape, "\\$1");
		}


		public function RegExpUtil()
		{
			throw new IllegalOperationError("The RegExpUtil is an abstract class");
		}
	}
}
