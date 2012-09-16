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
	import mx.utils.StringUtil;


	/**
	 * Utility functions to manipulate strings
	 * @abstract
	 */
	public class StringUtil extends mx.utils.StringUtil
	{

		/**
		 * Camelize a string
		 *
		 * @param string The string to camelize
		 * @param upperFirstLetter If true, the first letter will be uppercased
		 * @return The camelized string
		 */
		public static function camelize(string : String, upperFirstLetter : Boolean = false) : String
		{
			var res : String = string;
			if (upperFirstLetter)
			{
				res = "_" + res;
			}
			res = res.replace(/_([a-z])/gi, function(dummy : String, firstLetter : String, ... rest : Array) : String
			{
				return firstLetter.toUpperCase();
			});
			return res;
		}


		/**
		 * Uncamelize a string
		 *
		 * @param string The string to uncamelize
		 * @return The uncamelized string
		 */
		public static function unCamelize(string : String) : String
		{
			var res : String = string.replace(/([A-Z])/g, function(dummy : String, firstLetter : String,
						... rest : Array) : String
						{
							return '_' + firstLetter.toLowerCase();
						});
			if (res.charAt(0) == "_")
			{
				res = res.substr(1);
			}
			return res;
		}
	}
}
