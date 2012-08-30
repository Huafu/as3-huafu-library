package com.huafu.sql.orm.relation
{
	import com.huafu.sql.orm.ORM;
	import com.huafu.sql.orm.ORMDescriptor;
	import com.huafu.sql.orm.ORMIterator;
	import com.huafu.sql.query.SQLiteCondition;
	import com.huafu.sql.query.SQLiteQuery;
	
	public class ORMRelationBridge implements IORMRelation
	{
		internal var _localToUsing : IORMRelation;
		internal var _usingToForeign : IORMRelation;
		
		internal var _localOrmClass : Class;
		internal var _foreginOrmClass : Class;
		internal var _usingOrmClass : Class;
		internal var _usingOrmDescriptor : ORMDescriptor;
		internal var _ownerPropertyName : String;
		
		public function ORMRelationBridge( fromOrmClass : Class, ownerPropertyName : String, toOrmClass : Class, usingOrmClass : Class )
		{
			_localOrmClass = fromOrmClass;
			_foreginOrmClass = toOrmClass;
			_usingOrmClass = usingOrmClass;
			_ownerPropertyName = ownerPropertyName;
		}
		
		
		public function get usingDescriptor() : ORMDescriptor
		{
			if ( !_usingOrmDescriptor )
			{
				_usingOrmDescriptor = ORMDescriptor.forClass(usingOrmClass);
			}
			return _usingOrmDescriptor;
		}
		
		public function get usingOrmClass() : Class
		{
			return _usingOrmClass;
		}
		
		public function get usingToForeignRelation() : IORMRelation
		{
			if ( !_usingToForeign )
			{
				_usingToForeign = usingDescriptor.getRelationTo(foreignDescriptor);
			}
			return _usingToForeign;
		}
		
		public function get ownerToUsingRelation() : IORMRelation
		{
			if ( !_localToUsing )
			{
				_localToUsing = ownerDescriptor.getRelationTo(usingDescriptor);
			}
			return _localToUsing;
		}
		
		public function get foreignColumnName() : String
		{
			return usingToForeignRelation.foreignColumnName;
		}
		
		public function get foreignRelation():IORMRelation
		{
			return usingToForeignRelation.foreignRelation;
		}
		
		public function get ownerDescriptor():ORMDescriptor
		{
			return ORMDescriptor.forClass(_localOrmClass);
		}
		
		public function get ownerPropertyName():String
		{
			return _ownerPropertyName;
		}
		
		public function get localColumnName():String
		{
			return ownerToUsingRelation.localColumnName;
		}
		
		public function get foreignDescriptor():ORMDescriptor
		{
			return ORMDescriptor.forClass(_foreginOrmClass);
		}
		
		public function get foreignOrmClass():Class
		{
			return _foreginOrmClass;
		}
		
		public function get foreignIsUnique():Boolean
		{
			return ownerToUsingRelation.foreignIsUnique && usingToForeignRelation.foreignIsUnique;
		}
		
		public function getSqlCondition( localTableAlias : String = null, foreignTableAlias : String = null, usingTableAlias : String = null ) : String
		{
			return ownerToUsingRelation.getSqlCondition( localTableAlias, usingTableAlias )
				+ " AND " + usingToForeignRelation.getSqlCondition( usingTableAlias, foreignTableAlias );
		}
		
		
		public function setupQueryCondition( query : SQLiteQuery, ormObject : ORM, usingData : Object, localTableAlias : String = null, foreignTableAlias : String = null, usingTableAlias : String = null ) : void
		{
			ownerToUsingRelation.setupQueryCondition(query, ormObject, usingData, localTableAlias, usingTableAlias);
			query.where(usingToForeignRelation.getSqlCondition(usingTableAlias, foreignTableAlias));
		}
		
		public function setupOrmObject(ormObject:ORM, ormObjectData:Object, usingData:Object):void
		{
			var res : ORMIterator,
				foreignOrm : ORM = foreignDescriptor.globalOrmInstance,
				usingOrm : ORM = usingDescriptor.globalOrmInstance,
				q : SQLiteQuery;
				
			foreignOrm.excludeSoftDeleted = usingOrm.excludeSoftDeleted = ormObject.excludeSoftDeleted;
			q = foreignOrm.getPreparedQuery("f", false)
				.select("f.*, u." + usingDescriptor.primaryKeyProperty.columnName + " AS __using_pk");
			// add the using table
			q.from(usingDescriptor.tableName + " AS u");
			setupQueryCondition(q, ormObject, usingData, "l", "f", "u");
			ormObjectData[ownerPropertyName] = new ORMIterator(foreignOrmClass, q.compile(), {});
		}
	}
}