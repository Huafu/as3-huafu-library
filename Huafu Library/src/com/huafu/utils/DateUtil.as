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
	 * Helper class to manipulate dates
	 */
	public final class DateUtil
	{
		private static var _allParts : Array = [ "year", "month", "day", "hour", "minute", "second" ];
		private static var _parsers : Object = { '([0-9]{4})-([0-9]{2})-([0-9]{2})(?: ([0-9]{2})\\:([0-9]{2})(?:\\:([0-9]{2})))\\s*': { year: 1,
					month: 2, day: 3, hour: 4, minute: 5, second: 6 }};


		/**
		 * Better parser than the AS native one which can understand formats such as YYYY-MM-DD HH:MM:SS
		 *
		 * @param date The date to parse as a string
		 * @return The parsed date
		 */
		public static function parse( date : String ) : Date
		{
			var match : Array, re : RegExp, name : String, parser : Object, num : Number = Date.parse(date),
				parts : Object = {}, part : String, v : String;
			if (!date)
			{
				return new Date(NaN);
			}
			if (!isNaN(num))
			{
				return new Date(num);
			}
			for (name in _parsers)
			{
				parser = _parsers[name];
				if (!(re = parser.regexp))
				{
					re = new RegExp(name);
					parser.regexp = re;
				}
				if ((match = date.match(re)) && match.length > 0)
				{
					// got a match, use this parser to create the date
					for each (part in _allParts)
					{
						if (parser.hasOwnProperty(part) && parser[part] <= match.length && (v = match[parser[part]]))
						{
							parts[part] = parseInt(v, 10);
						}
						else
						{
							part[part] = null;
						}
					}
					return new Date(parts.year, parts.month, parts.day, parts.hour, parts.minute, parts.
									second);
				}
			}
			return new Date(NaN);
		}


		/**
		 * Abstract class - avoid instanciation
		 */
		public function DateUtil()
		{
			throw new IllegalOperationError("The DateUtil is an abstract class");
		}
	}
}
