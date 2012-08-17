package com.huafu.utils
{
	import mx.utils.StringUtil;
	
	public class StringUtil extends mx.utils.StringUtil
	{
		
		/**
		 * Camelize a string
		 * 
		 * @param string The string to camelize
		 * @param upperFirstLetter If true, the first letter will be uppercased
		 * @return The camelized string
		 */ 
		public static function camelize( string : String, upperFirstLetter : Boolean = false ) : String
		{
			var res : String= string;
			if ( upperFirstLetter )
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
		public static function unCamelize( string : String ) : String
		{
			var res : String = string.replace(/([A-Z])/g, function( dummy : String, firstLetter : String, ... rest : Array ) : String
			{
				return '_' + firstLetter.toLowerCase();
			});
			if ( res.charAt(0) == "_" )
			{
				res = res.substr(1);
			}
			return res;
		}
	}
}