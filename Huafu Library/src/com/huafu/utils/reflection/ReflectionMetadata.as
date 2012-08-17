package com.huafu.utils.reflection
{
	import com.huafu.utils.HashMap;
	
	import flashx.textLayout.formats.Float;

	public class ReflectionMetadata
	{
		private var _xml : XML;
		private var _args : HashMap;
		private var _name : String;
		private var _owner : *;
		
		public function ReflectionMetadata( owner : *, node : XML )
		{
			_xml = node;
			_name = node.@name.toString();
			_owner = owner;
		}
		
		
		public function get name() : String
		{
			return _name;
		}
		
		
		public function get owner() : *
		{
			return _owner;
		}
		
		
		public function argValue( argKey : String, ifNotDefined : * = null ) : *
		{
			var x : XML;
			if ( !_args )
			{
				_args = new HashMap();
				for each ( x in _xml.arg )
				{
					_args.set(x.@key.toString(), x.@value);
				}
			}
			if ( !_args.exists(argKey) )
			{
				return ifNotDefined;
			}
			return _args.get(argKey);
		}
		
		
		public function argValueString( argKey : String, ifNotDefined : String = null ) : String
		{
			var res : * = argValue(argKey);
			if ( res )
			{
				return res.toString();
			}
			return ifNotDefined;
		}
		
		
		public function argValueBoolean( argKey : String, ifNotDefined : Boolean = false ) : Boolean
		{
			var res : String = argValueString(argKey);
			if ( res === null )
			{
				return ifNotDefined;
			}
			return (res.toLowerCase() in ["1", "true", "on", "yes", "y", "o"]);
		}
		
		
		public function argValueInteger( argKey : String, ifNotDefined : int = undefined ) : int
		{
			var res : String = argValueString(argKey);
			if ( res === null )
			{
				return ifNotDefined;
			}
			return parseInt(res);
		}
		
		
		public function argValueNumber( argKey : String, ifNotDefined : Number = undefined ) : Number
		{
			var res : String = argValueString(argKey);
			if ( res === null )
			{
				return ifNotDefined;
			}
			return parseFloat(res);
		}
	}
}