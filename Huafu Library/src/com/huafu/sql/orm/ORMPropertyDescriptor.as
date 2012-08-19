package com.huafu.sql.orm
{
	import com.huafu.utils.StringUtil;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;
	
	import flash.utils.getDefinitionByName;

	/**
	 * Holds the description of an ORM property
	 */
	public class ORMPropertyDescriptor
	{
		/**
		 * Name of the property
		 */
		private var _name : String;
		/**
		 * Name of the column for that property in the database
		 */
		private var _columnName : String;
		/**
		 * The type of the property as a string
		 */
		private var _type : String;
		/**
		 * A pointer to the class of the property
		 */
		private var _typeClass : Class;
		/**
		 * The type of the column in the database
		 */
		private var _columnType : String;
		/**
		 * The ORM descriptor owning this property
		 */
		private var _ormDescriptor : ORMDescriptor;
		/**
		 * Stores whether this proeprty is read-only or not
		 */
		private var _readOnly : Boolean;
		/**
		 * Stores whether this property is nullable or not
		 */
		private var _nullable : Boolean;
		
		
		/**
		 * Creates a new ORM property descriptor
		 * 
		 * @param ormDescriptor The ORM descriptor owning this property
		 * @param name The name of the property
		 * @param type The type of the property
		 * @param columnName The name of the column in the database
		 * @param columnType The type of the column
		 * @param nullable If the property can be null or not
		 */
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
		
		
		/**
		 * Name of the property
		 */
		public function get name() : String
		{
			return _name;
		}
		
		
		/**
		 * Name of the column in the table
		 */
		public function get columnName() : String
		{
			return _columnName;
		}
		
		
		/**
		 * Whether it is nullable or not
		 */
		public function get isNullable() : Boolean
		{
			return _nullable;
		}
		
		
		/**
		 * The ORM descriptor owning this property
		 */
		public function get ormDescriptor() : ORMDescriptor
		{
			return _ormDescriptor;
		}
		
		
		/**
		 * Whether the property is read-only or not
		 */
		public function get isReadOnly() : Boolean
		{
			return _readOnly;
		}
		public function set isReadOnly( value : Boolean ) : void
		{
			_readOnly = value;
		}
		
		
		/**
		 * Creates a new ORM property descriptor looking at a given ReflectionProperty
		 *
		 * @param ownerOrm The ORMDescriptor which is owning the property
		 * @param property The ReflectionProperty that the new descriptor will describe
		 * @return The newly created ORMPropertyDescriptor
		 */
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