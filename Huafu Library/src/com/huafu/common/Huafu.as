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


package com.huafu.common
{
	import flash.errors.IllegalOperationError;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.logging.LogEventLevel;
	import mx.logging.targets.TraceTarget;
	import avmplus.getQualifiedClassName;


	/**
	 * Global class handling common operations
	 */
	public final class Huafu
	{
		protected static var _consoleLogTarget : TraceTarget = null;


		protected static var _loggingToConsole : Boolean = false;


		/**
		 * Get the logger for a given class
		 *
		 * @param theClass The class to get the logger of
		 */
		public static function getLoggerFor(theClass : Class) : ILogger
		{
			var name : String = getQualifiedClassName(theClass).replace("::", ".");
			return Log.getLogger(name);
		}


		public static function get traceEnabled() : Boolean
		{
			return _loggingToConsole;
		}


		/**
		 * Whether the trace is enabled or not
		 */
		public static function set traceEnabled(value : Boolean) : void
		{
			if (value == _loggingToConsole)
			{
				return;
			}
			if (!_consoleLogTarget)
			{
				_consoleLogTarget = new TraceTarget();
				_consoleLogTarget.filters = ["mx.rpc.*", "mx.messaging.*", "com.huafu.*"];
				_consoleLogTarget.level = LogEventLevel.ALL;
				_consoleLogTarget.includeCategory = true;
				_consoleLogTarget.includeDate = true;
				_consoleLogTarget.includeLevel = true;
				_consoleLogTarget.includeTime = true;
			}
			Log[value ? "addTarget" : "removeTarget"](_consoleLogTarget);
			_loggingToConsole = value;
		}


		public function Huafu()
		{
			throw new IllegalOperationError("Huafu is an abstract class");
		}
	}
}
