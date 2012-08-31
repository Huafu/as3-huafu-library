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
		 * Creates a new ORM property descriptor looking at a given ReflectionProperty
		 *
		 * @param ownerOrm The ORMDescriptor which is owning the property
		 * @param property The ReflectionProperty that the new descriptor will describe
		 * @return The newly created ORMPropertyDescriptor
		 */
		public static function fromReflectionProperty( ownerOrm : ORMDescriptor, property : ReflectionProperty ) : ORMPropertyDescriptor
		{
			var meta : ReflectionMetadata = property.uniqueMetadata("Column");
			return new ORMPropertyDescriptor(ownerOrm, property.name, property.dataType, meta.argValueString("name"),
											 meta.argValueString("type"), meta.hasArgument("nullable"),
											 meta.argValueNumber("size", 0), meta.hasArgument("unique"));
		}


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
		public function ORMPropertyDescriptor( ormDescriptor : ORMDescriptor, name : String, type : String,
											   columnName : String = null, columnType : String = null,
											   nullable : Boolean = false, columnDataLength : Number
											   = 0, unique : Boolean = false )
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
			if (_columnType == "ByteArray")
			{
				_columnType = "BLOB";
			}
			else if (_columnType in [ "uint", "int" ])
			{
				_columnType = "INTEGER";
			}
			else if (_columnType == "Date")
			{
				_columnType = "DATETIME";
			}
			else if (_columnType in [ "Number", "Float" ])
			{
				_columnType = "FLOAT";
			}
			else if (_columnType == "String")
			{
				_columnType = (_columnTypeSize == 0) ? "TEXT" : "VARCHAR";
			}
			_readOnly = false;
		}

		/**
		 * Name of the column for that property in the database
		 */
		private var _columnName : String;
		/**
		 * The type of the column in the database
		 */
		private var _columnType : String;
		/**
		 * The size of the column data type in the database
		 */
		private var _columnTypeSize : Number;
		/**
		 * Name of the property
		 */
		private var _name : String;
		/**
		 * Stores whether this property is nullable or not
		 */
		private var _nullable : Boolean;
		/**
		 * The ORM descriptor owning this property
		 */
		private var _ormDescriptor : ORMDescriptor;
		/**
		 * Stores whether this proeprty is read-only or not
		 */
		private var _readOnly : Boolean;
		/**
		 * The type of the property as a string
		 */
		private var _type : String;
		/**
		 * A pointer to the class of the property
		 */
		private var _typeClass : Class;
		/**
		 * Stores whether this property is unique or not
		 */
		private var _unique : Boolean;


		/**
		 * The data length of the column
		 */
		public function get columnDataLength() : Number
		{
			return _columnTypeSize;
		}


		/**
		 * The type of data of the column
		 */
		public function get columnDataType() : String
		{
			return _columnType;
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
		 * Whether this property correspond to the PK of the table
		 */
		public function get isPrimaryKey() : Boolean
		{
			return (ormDescriptor.primaryKeyProperty === this);
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
		 * Name of the property
		 */
		public function get name() : String
		{
			return _name;
		}


		/**
		 * The ORM descriptor owning this property
		 */
		public function get ormDescriptor() : ORMDescriptor
		{
			return _ormDescriptor;
		}


		/**
		 * The SQL code that creates the columns
		 */
		public function get sqlCode() : String
		{
			var res : String = "\"" + columnName + "\" " + columnDataType;
			if (columnDataLength > 0)
			{
				res += "(" + columnDataLength + ")";
			}
			res += " " + (isNullable ? "" : "NOT ") + "NULL";
			if (isPrimaryKey)
			{
				res += " PRIMARY KEY AUTOINCREMENT";
			}
			if (isUnique)
			{
				res += " UNIQUE";
			}
			return res;
		}
	}
}
