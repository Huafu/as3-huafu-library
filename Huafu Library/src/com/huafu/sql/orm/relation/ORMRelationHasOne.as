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


package com.huafu.sql.orm.relation
{
	import com.huafu.sql.orm.ORM;
	import com.huafu.sql.orm.ORMDescriptor;
	import com.huafu.sql.orm.ORMPropertyDescriptor;
	import com.huafu.sql.query.SQLiteParameters;
	import com.huafu.sql.query.SQLiteQuery;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;
	import flash.errors.IllegalOperationError;


	/**
	 * Handle an ORM relation "one to one"
	 */
	public class ORMRelationHasOne extends ORMRelation implements IORMRelation
	{

		/**
		 * @copy ORMRelation#ORMRelation()
		 */
		public function ORMRelationHasOne(ownerDescriptor : ORMDescriptor, property : ReflectionProperty,
				metadata : ReflectionMetadata)
		{
			super(ownerDescriptor, property, metadata);
			_foreignIsUnique = true;
			_foreignColumnName = metadata.argValueString("foreignColumn");
			_nullable = metadata.argValueBoolean("nullable", false);
			_localColumnName = metadata.argValueString("column");
			_foreignOrmClass = property.dataTypeClass;
		}


		protected var _nullable : Boolean;


		/**
		 * @copy IORMRelation#addForeignItem()
		 */
		public function addForeignItem(ownerOrmObject : ORM, item : ORM, saveAdditionalRelatedDataIn : Object,
				throwError : Boolean = true) : Boolean
		{
			if (replaceForeignItem(ownerOrmObject, null, null, item, {}, throwError))
			{
				ownerOrmObject[ownerPropertyName] = item;
				return true;
			}
			return false;
		}


		/**
		 * @copy IORMRelation#foreignColumnName
		 */
		override public function get foreignColumnName() : String
		{
			if (!_foreignColumnName)
			{
				_foreignColumnName = foreignDescriptor.primaryKeyProperty.columnName
			}
			return _foreignColumnName;
		}


		/**
		 * @copy IORMRelation#getLocalColumnSqlCode()
		 */
		override public function getLocalColumnSqlCode(parametersDestination : SQLiteParameters = null) : String
		{
			var p : ORMPropertyDescriptor;
			if (!_localColumnSqlCode)
			{
				if ((p = ownerDescriptor.propertyDescriptorByColumnName(localColumnName)))
				{
					return p.getSqlCode(parametersDestination);
				}
				p = foreignDescriptor.propertyDescriptorByColumnName(foreignColumnName);
				_localColumnSqlCode = "\"" + localColumnName + "\" " + p.columnDataType;
				if (p.columnDataLength > 0)
				{
					_localColumnSqlCode += "(" + p.columnDataLength + ")";
				}
				_localColumnSqlCode += " " + (isNullable ? "" : "NOT ") + "NULL";
			}
			return _localColumnSqlCode;
		}


		/**
		 * Whether there can be no linked object or not
		 */
		public function get isNullable() : Boolean
		{
			return _nullable;
		}


		/**
		 * @copy IORMRelation#localColumnName
		 */
		override public function get localColumnName() : String
		{
			if (!_localColumnName)
			{
				_localColumnName = foreignDescriptor.tableName + "_id";
			}
			return _localColumnName;
		}


		/**
		 * @copy IORMRelation#removeAllForeignItem()
		 */
		public function removeAllForeignItems(ownerOrmObject : ORM, throwError : Boolean = true) : Boolean
		{
			ownerOrmObject[ownerPropertyName] = null;
			return true;
		}


		/**
		 * @copy IORMRelation#removeForeignItem()
		 */
		public function removeForeignItem(ownerOrmObject : ORM, item : ORM, additionalRelatedData : Object,
				throwError : Boolean = true) : Boolean
		{
			throw new IllegalOperationError("Trying to remove a foreign item when the relation is unique and not multiple");
			return false;
		}


		/**
		 * @copy IORMRelation#replaceForeignItem()
		 */
		public function replaceForeignItem(ownerOrmObject : ORM, oldItem : ORM, oldAdditionalRelatedData : Object,
				newItem : ORM, saveNewItemAdditionalRelatedDataIn : Object, throwError : Boolean
				= true) : Boolean
		{
			var q : SQLiteQuery, pkName : String;
			if (!(checkForeignItemClass(newItem, throwError) && checkOwnerObjectClass(ownerOrmObject,
					throwError) && checkIfFromDb(newItem, throwError)))
			{
				return false;
			}
			pkName = ownerDescriptor.primaryKeyProperty.columnName;
			q = ownerOrmObject.getQuery(true, false)
					.update(ownerDescriptor.tableName)
					.set(localColumnName, newItem.getColumnValue(foreignColumnName))
					.where(pkName + " = " + q.bind(pkName, ownerOrmObject.primaryKeyValue));
			if (!q.execute().rowsAffected > 0)
			{
				return false;
			}
			ownerOrmObject[ownerPropertyName] = newItem;
			return true;
		}


		/**
		 * @copy IORMRelation#setupOrmObject()
		 */
		public function setupOrmObject(ormObject : ORM, ormObjectData : Object, usingData : Object) : void
		{
			var res : ORM = null;
			if (!usingData || !usingData[localColumnName])
			{
				ormObjectData[ownerPropertyName] = null;
				return;
			}
			res = new foreignOrmClass();
			res.excludeSoftDeletedRecords = ormObject.excludeSoftDeletedRecords;
			if (res.load(usingData[localColumnName]))
			{
				ormObjectData[ownerPropertyName] = res;
			}
			else
			{
				ormObjectData[ownerPropertyName] = null;
			}
		}
	}
}
