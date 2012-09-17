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
	import com.huafu.sql.orm.iterator.IORMIterator;
	import com.huafu.sql.orm.iterator.ORMRelationIterator;
	import com.huafu.sql.query.SQLiteQuery;
	import com.huafu.utils.reflection.ReflectionClass;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;


	/**
	 * Handle relations that are using a bridge table
	 */
	public class ORMRelationBridge extends ORMRelation implements IORMRelation
	{
		public static const USING_PK_ALIAS : String = "__using_pk_value";


		/**
		 * @copy ORMRelation#ORMRelation()
		 */
		public function ORMRelationBridge(ownerDescriptor : ORMDescriptor, property : ReflectionProperty,
				metadata : ReflectionMetadata)
		{
			super(ownerDescriptor, property, metadata);
			_localToUsingPropertyName = metadata.argValueString("localToBridge");
			_usingToForeignPropertyName = metadata.argValueString("bridgeToForeign");
			_foreignIsUnique = !ReflectionClass.isClassInheriting(property.dataTypeClass, IORMIterator);
		}


		protected var _localToUsing : IORMRelation;


		protected var _localToUsingPropertyName : String;


		protected var _usingOrmClass : Class;


		protected var _usingOrmDescriptor : ORMDescriptor;


		protected var _usingToForeign : IORMRelation;


		protected var _usingToForeignPropertyName : String;


		/**
		 * @copy IORMRelation#addForeignItem()
		 */
		public function addForeignItem(ownerOrmObject : ORM, item : ORM, saveAdditionalRelatedDataIn : Object,
				throwError : Boolean = true) : Boolean
		{
			var using : ORM;
			if (!(checkForeignItemClass(item, throwError) && checkOwnerObjectClass(ownerOrmObject, throwError)
					&& checkIfFromDb(item, throwError) && checkIfFromDb(ownerOrmObject, throwError)))
			{
				return false;
			}
			using = new usingOrmClass();
			using.setColumnValue(ownerToUsingRelation.foreignColumnName, ownerOrmObject.getColumnValue(localColumnName));
			using.setColumnValue(usingToForeignRelation.localColumnName, item.getColumnValue(usingToForeignRelation.
					foreignColumnName));
			if (!using.save())
			{
				if (throwError)
				{
					throw new Error("Unable to save the table used as a bridge in the relation");
				}
				return false;
			}
			saveAdditionalRelatedDataIn[USING_PK_ALIAS] = using.primaryKeyValue;
			return true;
		}


		/**
		 * @copy IORMRelation#foreignColumnName
		 */
		override public function get foreignColumnName() : String
		{
			if (!_foreignColumnName)
			{
				_foreignColumnName = usingToForeignRelation.foreignColumnName;
			}
			return _foreignColumnName;
		}


		/**
		 * @copy IORMRelation#foreignOrmClass
		 */
		override public function get foreignOrmClass() : Class
		{
			if (!_foreignOrmClass)
			{
				_foreignOrmClass = usingToForeignRelation.foreignOrmClass;
			}
			return _foreignOrmClass;
		}


		/**
		 * @copy IORMRelation#foreignRelation
		 */
		override public function get foreignRelation() : IORMRelation
		{
			if (!_foreignRelation)
			{
				_foreignRelation = usingToForeignRelation.foreignRelation;
			}
			return _foreignRelation;
		}


		/**
		 * @copy IORMRelation#getSqlCondition()
		 */
		override public function getSqlCondition(localTableAlias : String = null, foreignTableAlias : String
				= null, usingTableAlias : String = null) : String
		{
			return ownerToUsingRelation.getSqlCondition(localTableAlias, usingTableAlias) + " AND " + usingToForeignRelation.
					getSqlCondition(usingTableAlias, foreignTableAlias);
		}


		/**
		 * @copy IORMRelation#localColumnName
		 */
		override public function get localColumnName() : String
		{
			if (!_localColumnName)
			{
				_localColumnName = ownerToUsingRelation.localColumnName;
			}
			return _localColumnName;
		}


		/**
		 * The relation object from the owner ORM to the bridge ORM
		 */
		public function get ownerToUsingRelation() : IORMRelation
		{
			if (!_localToUsing)
			{
				_localToUsing = ownerDescriptor.getRelatedTo(_localToUsingPropertyName);
			}
			return _localToUsing;
		}


		/**
		 * @copy IORMRelation#removeAllForeignItem()
		 */
		public function removeAllForeignItems(ownerOrmObject : ORM, throwError : Boolean = true) : Boolean
		{
			// TODO
			return false;
		}


		/**
		 * @copy IORMRelation#removeForeignItem()
		 */
		public function removeForeignItem(ownerOrmObject : ORM, item : ORM, additionalRelatedData : Object,
				throwError : Boolean = true) : Boolean
		{
			// TODO
			return false;
		}


		/**
		 * @copy IORMRelation#replaceForeignItem()
		 */
		public function replaceForeignItem(ownerOrmObject : ORM, oldItem : ORM, oldAdditionalRelatedData : Object,
				newItem : ORM, saveNewItemAdditionalRelatedDataIn : Object, throwError : Boolean
				= true) : Boolean
		{
			// TODO
			return false;
		}


		/**
		 * @copy IORMRelation#setupOrmObject()
		 */
		public function setupOrmObject(ormObject : ORM, ormObjectData : Object, usingData : Object) : void
		{
			var res : ORMRelationIterator, foreignOrm : ORM, usingOrm : ORM, q : SQLiteQuery, result : Array;
			if (!usingData || !usingData[localColumnName])
			{
				ormObjectData[ownerPropertyName] = null;
				return;
			}
			foreignOrm = foreignDescriptor.globalOrmInstance;
			usingOrm = usingDescriptor.globalOrmInstance;
			foreignOrm.excludeSoftDeletedRecords = usingOrm.excludeSoftDeletedRecords = ormObject.excludeSoftDeletedRecords;
			q = foreignOrm.getPreparedSelectQuery("f", false).select("f.*, u." + usingDescriptor.primaryKeyProperty.
					columnName + " AS " + USING_PK_ALIAS);
			// add the using table
			q.from(usingDescriptor.tableName + " AS u");
			setupQueryCondition(q, ormObject, usingData, "l", "f", "u");
			if (foreignIsUnique)
			{
				result = q.get();
				if (result.length == 0)
				{
					ormObjectData[ownerPropertyName] = null;
				}
				else
				{
					ormObjectData[ownerPropertyName] = new foreignOrmClass();
					(ormObjectData[ownerPropertyName] as ORM).loadWithResult(result[0]);
				}
			}
			else
			{
				ormObjectData[ownerPropertyName] = new ORMRelationIterator(foreignOrmClass, q.get(),
						ormObject, this);
			}
		}


		/**
		 * @copy IORMRelation#setupQueryCondition()
		 */
		override public function setupQueryCondition(query : SQLiteQuery, ormObject : ORM, usingData : Object,
				localTableAlias : String = null, foreignTableAlias : String
				= null, usingTableAlias : String = null) : void
		{
			ownerToUsingRelation.setupQueryCondition(query, ormObject, usingData, localTableAlias, usingTableAlias);
			query.where(usingToForeignRelation.getSqlCondition(usingTableAlias, foreignTableAlias));
		}


		/**
		 * The descriptor of the bridge ORM
		 */
		public function get usingDescriptor() : ORMDescriptor
		{
			if (!_usingOrmDescriptor)
			{
				_usingOrmDescriptor = ownerToUsingRelation.foreignDescriptor;
			}
			return _usingOrmDescriptor;
		}


		/**
		 * The class of the bridge ORM
		 */
		public function get usingOrmClass() : Class
		{
			if (!_usingOrmClass)
			{
				_usingOrmClass = ownerToUsingRelation.foreignOrmClass;
			}
			return _usingOrmClass;
		}


		/**
		 * The relation object from the bridge to the foreign ORM
		 */
		public function get usingToForeignRelation() : IORMRelation
		{
			if (!_usingToForeign)
			{
				_usingToForeign = usingDescriptor.getRelatedTo(_usingToForeignPropertyName);
			}
			return _usingToForeign;
		}
	}
}
