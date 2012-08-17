package com.huafu.sql.orm
{
	import com.huafu.utils.StringUtil;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;
	
	import flash.utils.getDefinitionByName;

	public class ORMPropertyDescriptor
	{
		
		private var _name : String;
		private var _columnName : String;
		private var _type : String;
		private var _typeClass : Class;
		private var _columnType : String;
		private var _ormDescriptor : ORMDescriptor;
		private var _readOnly : Boolean;
		private var _nullable : Boolean;
		
		public function ORMPropertyDescriptor( ormDescriptor : ORMDescriptor, name : String, type : String, columnName : String = null, columnType : String = null, nullable : Boolean = false )
		{
			_ormDescriptor = ormDescriptor;
			_name = name;
			_type = type;
			_nullable = nullable;
			_typeClass = getDefinitionByName(type) as Class;
			_columnName = columnName || StringUtil.unCamelize(name);
			_columnType = columnType || type.split("::").pop().toString();
			if ( _columnType == "ByteArray")
			{
				_columnType = "BLOB";
			}
			else if ( _columnType in ["uint", "int"] )
			{
				_columnType = "INTEGER";
			}
			else if ( _columnType == "Date" )
			{
				_columnType = "DATETIME";
			}
			else if ( _columnType in ["Number", "Float"] )
			{
				_columnType = "FLOAT";
			}
			_readOnly = false;
		}
		
		
		public function get name() : String
		{
			return _name;
		}
		
		
		public function get columnName() : String
		{
			return _columnName;
		}
		
		
		public function get isNullable() : Boolean
		{
			return _nullable;
		}
		
		
		public function get ormDescriptor() : ORMDescriptor
		{
			return _ormDescriptor;
		}
		
		
		public function get isReadOnly() : Boolean
		{
			return _readOnly;
		}
		
		
		public function set isReadOnly( value : Boolean ) : void
		{
			_readOnly = value;
		}
		
		
		public static function fromReflectionProperty( ownerOrm : ORMDescriptor, property : ReflectionProperty ) : ORMPropertyDescriptor
		{
			var name : String = property.name,
				type : String = property.dataType,
				meta : ReflectionMetadata = property.uniqueMetadata("Column"),
				columnName : String = meta.argValueString("name"),
				columnType : String = meta.argValueString("type"),
				nullable : Boolean = meta.argValueBoolean("nullable", false);
			return new ORMPropertyDescriptor(ownerOrm, name, type, columnName, columnType, nullable);
		}
	}
}