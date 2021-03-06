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
	import com.huafu.sql.orm.ORMIterator;
	import com.huafu.sql.query.SQLiteQuery;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;


	/**
	 * Handle relations that are using a bridge table
	 */
	public class ORMRelationBridge extends ORMRelation implements IORMRelation
	{

		/**
		 * @copy ORMRelation#ORMRelation()
		 */
		public function ORMRelationBridge( ownerDescriptor : ORMDescriptor, property : ReflectionProperty,
										   metadata : ReflectionMetadata )
		{
			super(ownerDescriptor, property, metadata);
			_usingOrmClassName = ORMRelation.readOrmClassFromMetadataArg(metadata, "usingClass");
			_foreignOrmClassName = ORMRelation.readOrmClassFromMetadataArg(metadata);
			_foreignIsUnique = !(property.dataTypeClass === ORMIterator);
		}

		protected var _localToUsing : IORMRelation;

		protected var _usingOrmClass : Class;
		protected var _usingOrmClassName : String;
		protected var _usingOrmDescriptor : ORMDescriptor;
		protected var _usingToForeign : IORMRelation;


		/**
		 * @copy IORMRelation#foreignColumnName
		 */
		public override function get foreignColumnName() : String
		{
			if (!_foreignColumnName)
			{
				_foreignColumnName = usingToForeignRelation.foreignColumnName;
			}
			return _foreignColumnName;
		}


		/**
		 * @copy IORMRelation#foreignRelation
		 */
		public override function get foreignRelation() : IORMRelation
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
		public override function getSqlCondition( localTableAlias : String = null, foreignTableAlias : String
												  = null, usingTableAlias : String = null ) : String
		{
			return ownerToUsingRelation.getSqlCondition(localTableAlias, usingTableAlias) + " AND " + usingToForeignRelation.
				getSqlCondition(usingTableAlias, foreignTableAlias);
		}


		/**
		 * @copy IORMRelation#localColumnName
		 */
		public override function get localColumnName() : String
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
				_localToUsing = ownerDescriptor.getRelationTo(usingDescriptor);
			}
			return _localToUsing;
		}


		/**
		 * @copy IORMRelation#setupOrmObject()
		 */
		public function setupOrmObject( ormObject : ORM, ormObjectData : Object, usingData : Object ) : void
		{
			var res : ORMIterator, foreignOrm : ORM, usingOrm : ORM, q : SQLiteQuery, result : Array;
			if (!usingData || !usingData[localColumnName])
			{
				ormObjectData[ownerPropertyName] = null;
				return;
			}
			foreignOrm = foreignDescriptor.globalOrmInstance;
			usingOrm = usingDescriptor.globalOrmInstance;
			foreignOrm.excludeSoftDeleted = usingOrm.excludeSoftDeleted = ormObject.excludeSoftDeleted;
			q = foreignOrm.getPreparedQuery("f", false).select("f.*, u." + usingDescriptor.primaryKeyProperty.
															   columnName + " AS __using_pk");
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
					(ormObjectData[ownerPropertyName] as ORM).loadDataFromSqlResult(result[0]);
				}
			}
			else
			{
				ormObjectData[ownerPropertyName] = new ORMIterator(foreignOrmClass, q.compile(), {});
			}
		}


		/**
		 * @copy IORMRelation#setupQueryCondition()
		 */
		public override function setupQueryCondition( query : SQLiteQuery, ormObject : ORM, usingData : Object,
													  localTableAlias : String = null, foreignTableAlias : String
													  = null, usingTableAlias : String = null ) : void
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
				_usingOrmDescriptor = ORMDescriptor.forClass(usingOrmClass);
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
				_usingOrmClass = ORMDescriptor.resolveOrmClass(_usingOrmClassName, ownerDescriptor);
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
				_usingToForeign = usingDescriptor.getRelationTo(foreignDescriptor);
			}
			return _usingToForeign;
		}
	}
}
