////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   Copyright Huafu 2012 
//   All rights reserved. 
//
////////////////////////////////////////////////////////////////////////////////////////////////////

package com.huafu.common
{
	import com.huafu.utils.HashMap;
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
		protected static var _loggingToConsole : Boolean     = false;


		/**
		 * Get the logger for a given class
		 *
		 * @param theClass The class to get the logger of
		 */
		public static function getLoggerFor( theClass : Class ) : ILogger
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
		public static function set traceEnabled( value : Boolean ) : void
		{
			if (value == _loggingToConsole)
			{
				return;
			}
			if (!_consoleLogTarget)
			{
				_consoleLogTarget = new TraceTarget();
				_consoleLogTarget.filters = [ "mx.rpc.*", "mx.messaging.*", "com.huafu.*" ];
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
