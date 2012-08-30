package com.huafu.sql.orm.relation
{
	import com.huafu.sql.orm.ORM;
	import com.huafu.sql.orm.ORMDescriptor;
	import com.huafu.sql.orm.ORMIterator;
	import com.huafu.sql.query.SQLiteCondition;
	import com.huafu.sql.query.SQLiteQuery;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;
	
	public class ORMRelationBridge extends ORMRelation implements IORMRelation
	{
		protected var _localToUsing : IORMRelation;
		protected var _usingToForeign : IORMRelation;
		
		protected var _usingOrmClass : Class;
		protected var _usingOrmClassName : String;
		protected var _usingOrmDescriptor : ORMDescriptor;
		
		public function ORMRelationBridge( ownerDescriptor : ORMDescriptor, property : ReflectionProperty, metadata : ReflectionMetadata )
		{
			super(ownerDescriptor, property, metadata);
			_usingOrmClassName = ORMRelation.readOrmClassFromMetadataArg(metadata, "usingClassName");
			_foreignOrmClassName = ORMRelation.readOrmClassFromMetadataArg(metadata);
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
			if ( !_usingOrmClass )
			{
				_usingOrmClass = ORMDescriptor.resolveOrmClass(_usingOrmClassName, ownerDescriptor);
			}
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
		
		override public function get foreignColumnName() : String
		{
			if ( !_foreignColumnName )
			{
				_foreignColumnName = usingToForeignRelation.foreignColumnName;
			}
			return _foreignColumnName;
		}
		
		override public function get foreignRelation() : IORMRelation
		{
			if ( !_foreignRelation )
			{
				_foreignRelation = usingToForeignRelation.foreignRelation;
			}
			return _foreignRelation;
		}
		
		override public function get localColumnName() : String
		{
			if ( !_localColumnName )
			{
				_localColumnName = ownerToUsingRelation.localColumnName;
			}
			return _localColumnName;
		}
		
		override public function get foreignIsUnique() : Boolean
		{
			if ( !_foreignIsUnique )
			{
				_foreignIsUnique = ownerToUsingRelation.foreignIsUnique && usingToForeignRelation.foreignIsUnique;
			}
			return _foreignIsUnique;
		}
		
		override public function getSqlCondition( localTableAlias : String = null, foreignTableAlias : String = null, usingTableAlias : String = null ) : String
		{
			return ownerToUsingRelation.getSqlCondition( localTableAlias, usingTableAlias )
				+ " AND " + usingToForeignRelation.getSqlCondition( usingTableAlias, foreignTableAlias );
		}
		
		
		override public function setupQueryCondition( query : SQLiteQuery, ormObject : ORM, usingData : Object, localTableAlias : String = null, foreignTableAlias : String = null, usingTableAlias : String = null ) : void
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