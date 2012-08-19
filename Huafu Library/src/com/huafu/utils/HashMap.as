package com.huafu.utils
{
	
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import mx.collections.ArrayList;
	import mx.utils.ArrayUtil;

	public class HashMap extends Proxy
	{
		private var _keys : ArrayList;
		private var _data : Object;
		
		
		public function HashMap( initialData : Object = null )
		{
			var key : String;
			
			_keys = new ArrayList();
			_data = {};
			if ( initialData )
			{
				if ( initialData is HashMap )
				{
					initialData = (initialData as HashMap).toObject();
				}
				for ( key in initialData )
				{
					_set(key, initialData[key]);
				}
			}
		}
		
		
		public function unset( name : String ) : Boolean
		{
			var index : int;
			if ( (index = _keyIndex(name)) != -1 )
			{
				_keys.removeItemAt(index);
				delete _data[name];
				return true;
			}
			return false;
		}
		
		
		public function set( name : String, value : * ) : HashMap
		{
			_set(name, value, (_keyIndex(name) == -1));
			return this;
		}
		
		
		public function get( name : String ) : *
		{
			if ( _keyIndex(name) == -1 )
			{
				return undefined;
			}
			return _data[name];
		}
		
		
		public function exists( name : String ) : Boolean
		{
			return (_keyIndex(name) != -1);
		}
		
		
		public function toObject() : Object
		{
			var name : String, res : Object = {};
			for each ( name in this )
			{
				res[name] = _data[name];
			}
			return res;
		}
		
		
		public function keys() : Array
		{
			return _keys.toArray();
		}
		
		
		flash_proxy override function deleteProperty( name : * ) : Boolean
		{
			return unset(name);
		}
		
		
		flash_proxy override function getProperty( name : * ) : *
		{
			return get(name);
		}
		
		
		flash_proxy override function hasProperty( name : * ) : Boolean
		{
			return exists(name);
		}
		
		
		flash_proxy override function setProperty( name : *, value : * ) : void
		{
			set(name, value);
		}
		
		
		flash_proxy override function nextNameIndex( index : int ) : int
		{
			if ( index > _keys.length )
			{
				return 0;
			}
			return index + 1;
		}
		
		
		flash_proxy override function nextName( index : int ) : String
		{
			return _keys[index - 1];
		}
		
		
		flash_proxy override function nextValue( index : int ) : *
		{
			return _data[_keys[index - 1]];
		}
		
		
		private function _set( name : String, value : *, addNameToKeys : Boolean = true ) : void
		{
			_data[name] = value;
			if ( addNameToKeys )
			{
				_keys.addItem(name);
			}
		}
		
		private function _keyIndex( name : String ) : int
		{
			return _keys.getItemIndex(name);
		}
	}
}