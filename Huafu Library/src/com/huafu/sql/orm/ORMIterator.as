package com.huafu.sql.orm
{
	import com.huafu.sql.SQLiteStatement;
	
	import flash.data.SQLResult;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import mx.collections.ArrayList;

	public class ORMIterator extends Proxy
	{
		private var _data : ArrayList;
		private var _statement : SQLiteStatement;
		private var _objectUsedToReaload : Object;
		private var _ormClass : Class;
		private var _cursorPosition : int;
		private var _ormInstance : ORM;
		
		public function ORMIterator( ormClass : Class, statement : SQLiteStatement, objectUsedToReloadOnNewIteration : Object = null )
		{
			_objectUsedToReaload = objectUsedToReloadOnNewIteration;
			_statement = statement;
			if ( !_objectUsedToReaload )
			{
				_data = new ArrayList(_statement.getResult().data);
			}
			_ormClass = ormClass;
			_cursorPosition = -1;
		}
		
		
		private function ormInstance() : ORM
		{
			if ( !_ormInstance )
			{
				_ormInstance = new _ormClass();
			}
			return _ormInstance;
		}
		
		
		flash_proxy override function nextNameIndex( index : int ) : int
		{
			var name : String;
			if ( index == 0 && _objectUsedToReaload )
			{
				for ( name in _statement.parameters )
				{
					if ( _objectUsedToReaload.hasOwnProperty(name) )
					{
						_statement.parameters[name] = _objectUsedToReaload[name];
					}
				}
				_statement.execute();
				_data = new ArrayList(_statement.getResult().data);
			}
			if ( index > _data.length )
			{
				return 0;
			}
			return index + 1;
		}
		
		
		flash_proxy override function nextName( index : int ) : String
		{
			return String(index - 1);
		}
		
		
		flash_proxy override function nextValue( index : int ) : *
		{
			return _get(index - 1);
		}
		
		
		private function _get( index : int ) : ORM
		{
			var res : ORM;
			if ( !(_data[index] is ORM) )
			{
				res = new _ormClass();
				res.loadDataFromSqlResult(_data[index]);
				_data[index] = res;
			}
			return _data[index];
		}
	}
}