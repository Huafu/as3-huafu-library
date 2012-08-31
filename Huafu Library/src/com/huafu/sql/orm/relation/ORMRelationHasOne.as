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
	import com.huafu.sql.query.SQLiteCondition;
	import com.huafu.sql.query.SQLiteQuery;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;


	/**
	 * Handle an ORM relation "one to one"
	 */
	public class ORMRelationHasOne extends ORMRelation implements IORMRelation
	{

		/**
		 * @copy ORMRelation#ORMRelation()
		 */
		public function ORMRelationHasOne( ownerDescriptor : ORMDescriptor, property : ReflectionProperty,
										   metadata : ReflectionMetadata )
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
		 * @copy IORMRelation#foreignColumnName
		 */
		public override function get foreignColumnName() : String
		{
			if (!_foreignColumnName)
			{
				_foreignColumnName = foreignDescriptor.primaryKeyProperty.columnName
			}
			return _foreignColumnName;
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
		public override function get localColumnName() : String
		{
			if (!_localColumnName)
			{
				_localColumnName = foreignDescriptor.tableName + "_id";
			}
			return _localColumnName;
		}


		/**
		 * @copy IORMRelation#localColumnSqlCode
		 */
		public override function get localColumnSqlCode() : String
		{
			var p : ORMPropertyDescriptor;
			if (!_localColumnSqlCode)
			{
				if ((p = ownerDescriptor.propertyDescriptorByColumnName(localColumnName)))
				{
					return p.sqlCode;
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
		 * @copy IORMRelation#setupOrmObject()
		 */
		public function setupOrmObject( ormObject : ORM, ormObjectData : Object, usingData : Object ) : void
		{
			var res : ORM = ormObjectData[ownerPropertyName] || null;
			if (!usingData || !usingData[localColumnName])
			{
				ormObjectData[ownerPropertyName] = null;
				return;
			}
			if (!res)
			{
				res = new foreignOrmClass();
				ormObjectData[ownerPropertyName] = res;
			}
			res.excludeSoftDeleted = ormObject.excludeSoftDeleted;
			res.find(usingData[localColumnName]);
			if (!res.isLoaded)
			{
				ormObjectData[ownerPropertyName] = null;
			}
		}
	}
}
