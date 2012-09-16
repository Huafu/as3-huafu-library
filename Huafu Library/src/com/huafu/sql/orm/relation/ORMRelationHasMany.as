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
	import com.huafu.sql.SQLiteConnection;
	import com.huafu.sql.orm.ORM;
	import com.huafu.sql.orm.ORMDescriptor;
	import com.huafu.sql.orm.iterator.ORMRelationIterator;
	import com.huafu.sql.query.SQLiteQuery;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;
	import flash.data.SQLResult;


	/**
	 * Handle ORM relation "one to many"
	 */
	public class ORMRelationHasMany extends ORMRelation implements IORMRelation
	{
		/**
		 * @copy ORMRelation#ORMRelation()
		 */
		public function ORMRelationHasMany(ownerDescriptor : ORMDescriptor, property : ReflectionProperty,
				metadata : ReflectionMetadata)
		{
			super(ownerDescriptor, property, metadata);
			_foreignColumnName = metadata.argValueString("foreignColumn");
			_foreignOrmClassName = ORMRelation.readOrmClassFromMetadataArg(metadata);
			_localColumnName = metadata.argValueString("column");
		}


		/**
		 * @copy IORMRelation#addForeignItem()
		 */
		public function addForeignItem(ownerOrmObject : ORM, item : ORM, saveAdditionalRelatedDataIn : Object,
				throwError : Boolean = true) : Boolean
		{
			if (!checkForeignItemClass(item, throwError))
			{
				return false;
			}
			if (!checkIfFromDb(ownerOrmObject, throwError))
			{
				return false;
			}
			item.setColumnValue(foreignColumnName, ownerOrmObject.getColumnValue(localColumnName));
			return item.save();
		}


		/**
		 * @copy IORMRelation#foreignColumnName
		 */
		override public function get foreignColumnName() : String
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
		override public function get localColumnName() : String
		{
			if (!_localColumnName)
			{
				_localColumnName = ownerDescriptor.primaryKeyProperty.columnName;
			}
			return _localColumnName;
		}


		/**
		 * @copy IORMRelation#removeAllForeignItem()
		 */
		public function removeAllForeignItems(ownerOrmObject : ORM, throwError : Boolean = true) : Boolean
		{
			var foreignOrm : ORM = foreignDescriptor.globalOrmInstance, q : SQLiteQuery = foreignOrm.
					getQuery(true,
					false), r : SQLResult;
			foreignOrm.excludeSoftDeletedRecords = true;
			if (foreignDescriptor.deletedAtProperty)
			{
				// soft delete
				q.update(foreignDescriptor.tableName).set(foreignDescriptor.deletedAtProperty.columnName,
						new Date());
			}
			else
			{
				// really delete
				q.deleteFrom(foreignDescriptor.tableName);
			}
			q.where(foreignOrm.getDeletedCondition(), foreignColumnName + " = " + q.bind(foreignColumnName,
					ownerOrmObject.getColumnValue(localColumnName)));
			r = q.execute();
			return true;
		}


		/**
		 * @copy IORMRelation#removeForeignItem()
		 */
		public function removeForeignItem(ownerOrmObject : ORM, item : ORM, additionalRelatedData : Object,
				throwError : Boolean = true) : Boolean
		{
			if (!checkForeignItemClass(item, throwError))
			{
				return false;
			}
			if (!checkIfFromDb(ownerOrmObject, throwError))
			{
				return false;
			}
			return item.remove();
		}


		/**
		 * @copy IORMRelation#replaceForeignItem()
		 */
		public function replaceForeignItem(ownerOrmObject : ORM, oldItem : ORM, oldAdditionalRelatedData : Object,
				newItem : ORM, saveNewItemAdditionalRelatedDataIn : Object, throwError : Boolean
				= true) : Boolean
		{
			var oldConn : SQLiteConnection = oldItem.connection, conn : SQLiteConnection = newItem.connection,
					res : Boolean = false;
			oldItem.connection = conn;
			conn.begin();
			try
			{
				res = removeForeignItem(ownerOrmObject, oldItem, oldAdditionalRelatedData, throwError)
						&& addForeignItem(ownerOrmObject, newItem, saveNewItemAdditionalRelatedDataIn,
						throwError);
			}
			catch (err : Error)
			{
				conn.rollback();
				if (throwError)
				{
					throw err;
				}
				return false;
			}
			conn[res ? 'commit' : 'rollback']();
			oldItem.connection = oldConn;
			return res;
		}


		/**
		 * @copy IORMRelation#setupOrmObject()
		 */
		public function setupOrmObject(ormObject : ORM, ormObjectData : Object, usingData : Object) : void
		{
			var res : ORMRelationIterator, foreignOrm : ORM, q : SQLiteQuery;
			if (!usingData || !usingData[localColumnName])
			{
				ormObjectData[ownerPropertyName] = null;
				return;
			}
			foreignOrm = foreignDescriptor.globalOrmInstance;
			foreignOrm.excludeSoftDeletedRecords = ormObject.excludeSoftDeletedRecords;
			q = foreignOrm.getPreparedSelectQuery();
			q.where(foreignColumnName + " = " + q.bind(foreignDescriptor.tableName + "_" + foreignColumnName,
					usingData[localColumnName]));
			ormObjectData[ownerPropertyName] = new ORMRelationIterator(foreignOrmClass, q.get(), ormObject,
					this);
		}
	}
}
