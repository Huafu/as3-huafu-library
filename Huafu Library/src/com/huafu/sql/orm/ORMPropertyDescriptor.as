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
		 * The size of the column data type in the database
		 */
		private var _columnTypeSize : Number;
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
		 * Stores whether this property is unique or not
		 */
		private var _unique : Boolean;
		
		
		/**
		 * Creates a new ORM property descriptor
		 * 
		 * @param ormDescriptor The ORM descriptor owning this property
		 * @param name The name of the property
		 * @param type The type of the property
		 * @param columnName The name of the column in the database
		 * @param columnType The type of the column
		 * @param nullable If the property can be null or not
		 * @param columnDataLength The column's data length
		 * @param unique If the column is unique
		 */
		public function ORMPropertyDescriptor( ormDescriptor : ORMDescriptor, name : String, type : String, columnName : String = null, columnType : String = null, nullable : Boolean = false, columnDataLength : Number = 0, unique : Boolean = false )
		{
			_ormDescriptor = ormDescriptor;
			_name = name;
			_type = type;
			_nullable = nullable;
			_typeClass = getDefinitionByName(type) as Class;
			_columnName = columnName || StringUtil.unCamelize(name);
			_columnType = columnType || type.split("::").pop().toString();
			_columnTypeSize = columnDataLength;
			_unique = unique;
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
			else if ( _columnType == "String" )
			{
				_columnType = (_columnTypeSize == 0) ? "TEXT" : "VARCHAR";
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
		 * The type of data of the column
		 */
		public function get columnDataType() : String
		{
			return _columnType;
		}
		
		
		/**
		 * The data length of the column
		 */
		public function get columnDataLength() : Number
		{
			return _columnTypeSize;
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
		 * Whether this column is unique or not
		 */
		public function get isUnique() : Boolean
		{
			return _unique;
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
			var meta : ReflectionMetadata = property.uniqueMetadata("Column");
			return new ORMPropertyDescriptor(ownerOrm,
				property.name,
				property.dataType,
				meta.argValueString("name"),
				meta.argValueString("type"),
				meta.hasArgument("nullable"),
				meta.argValueNumber("size", 0),
				meta.hasArgument("unique")
			);
		}
	}
}