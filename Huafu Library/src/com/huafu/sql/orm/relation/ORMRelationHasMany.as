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
	import com.huafu.sql.SQLiteStatement;
	import com.huafu.sql.orm.ORM;
	import com.huafu.sql.orm.ORMDescriptor;
	import com.huafu.sql.orm.ORMIterator;
	import com.huafu.sql.query.SQLiteCondition;
	import com.huafu.sql.query.SQLiteQuery;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;
	import flash.errors.IllegalOperationError;


	/**
	 * Handle ORM relation "one to many"
	 */
	public class ORMRelationHasMany extends ORMRelation implements IORMRelation
	{
		/**
		 * @copy ORMRelation#ORMRelation()
		 */
		public function ORMRelationHasMany( ownerDescriptor : ORMDescriptor, property : ReflectionProperty,
											metadata : ReflectionMetadata )
		{
			super(ownerDescriptor, property, metadata);
			_foreignColumnName = metadata.argValueString("foreignColumn");
			_foreignOrmClassName = ORMRelation.readOrmClassFromMetadataArg(metadata);
			_localColumnName = metadata.argValueString("column");
		}


		/**
		 * @copy IORMRelation#foreignColumnName
		 */
		public override function get foreignColumnName() : String
		{
			if (!_foreignColumnName)
			{
				_foreignColumnName = ownerDescriptor.tableName + "_id";
			}
			return _foreignColumnName;
		}


		/**
		 * @copy IORMRelation#localColumnName
		 */
		public override function get localColumnName() : String
		{
			if (!_localColumnName)
			{
				_localColumnName = ownerDescriptor.primaryKeyProperty.columnName;
			}
			return _localColumnName;
		}


		/**
		 * @copy IORMRelation#setupOrmObject()
		 */
		public function setupOrmObject( ormObject : ORM, ormObjectData : Object, usingData : Object ) : void
		{
			var res : ORMIterator, foreignOrm : ORM, q : SQLiteQuery;
			if (!usingData || !usingData[localColumnName])
			{
				ormObjectData[ownerPropertyName] = null;
				return;
			}
			foreignOrm = foreignDescriptor.globalOrmInstance;
			foreignOrm.excludeSoftDeleted = ormObject.excludeSoftDeleted;
			q = foreignOrm.getPreparedQuery();
			q.where(new SQLiteCondition(foreignColumnName + " = ?", usingData[localColumnName]));
			ormObjectData[ownerPropertyName] = new ORMIterator(foreignOrmClass, q.compile(), {});
		}
	}
}
