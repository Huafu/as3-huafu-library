package com.huafu.sql.orm.relation
{
	import com.huafu.sql.orm.ORM;
	import com.huafu.sql.orm.ORMDescriptor;
	import com.huafu.sql.orm.ORMPropertyDescriptor;
	import com.huafu.sql.query.SQLiteCondition;
	import com.huafu.sql.query.SQLiteQuery;

	public class ORMRelation
	{
		protected var _destinationOrmDescriptor : ORMDescriptor;
		protected var _destinationOrmPropertyName : String;
		protected var _localColumnName : String;
		
		protected var _foreignColumnName : String;
		protected var _foreignOrmClass : Class;
		protected var _foreignOrmDescriptor : ORMDescriptor;
		protected var _foreignRelation : IORMRelation;
		protected var _foreignIsUnique : Boolean;
		
		public function ORMRelation( ownerDescriptor : ORMDescriptor, ownerPropertyName : String, foreignOrmClass : Class, foreignColumnName : String )
		{
			_destinationOrmDescriptor = ownerDescriptor;
			_destinationOrmPropertyName = ownerPropertyName;
			_foreignOrmClass = foreignOrmClass;
			_foreignColumnName = foreignColumnName;
			_foreignIsUnique = false;
		}
		
		public function get foreignIsUnique() : Boolean
		{
			return _foreignIsUnique;
		}
		
		public function get foreignColumnName() : String
		{
			return _foreignColumnName;
		}
		
		public function get foreignRelation() : IORMRelation
		{
			if ( !_foreignRelation )
			{
				_foreignRelation = foreignDescriptor.getRelationTo(ownerDescriptor, localColumnName);
			}
			return _foreignRelation;
		}
		
		public function get ownerDescriptor() : ORMDescriptor
		{
			return _destinationOrmDescriptor;
		}
		
		public function get ownerPropertyName() : String
		{
			return _destinationOrmPropertyName;
		}
		
		public function get localColumnName() : String
		{
			return _localColumnName;
		}
		
		
		public function get foreignOrmClass() : Class
		{
			return _foreignOrmClass;
		}
		
		public function get foreignDescriptor() : ORMDescriptor
		{
			if ( !_foreignOrmDescriptor )
			{
				_foreignOrmDescriptor = ORMDescriptor.forClass(_foreignOrmClass);
			}
			return _foreignOrmDescriptor;
		}
		
		
		public function setupQueryCondition( query : SQLiteQuery, ormObject : ORM, usingData : Object, localTableAlias : String = null, foreignTableAlias : String = null, usingTableAlias : String = null ) : void
		{
			var foreignOrm : ORM = foreignDescriptor.globalOrmInstance;
			foreignOrm.excludeSoftDeleted = ormObject.excludeSoftDeleted;
			if ( !localTableAlias )
			{
				localTableAlias = ownerDescriptor.tableName;
			}
			if ( !foreignTableAlias )
			{
				foreignTableAlias = foreignDescriptor.tableName;
			}
			query.where(
				new SQLiteCondition(foreignTableAlias + "." + foreignColumnName + " = ?", usingData[localColumnName]),
				foreignOrm.getDeletedCondition(foreignTableAlias));
		}
		
		
		public function getSqlCondition( localTableAlias : String = null, foreignTableAlias : String = null, usingTableAlias : String = null ) : String
		{
			if ( !localTableAlias )
			{
				localTableAlias = ownerDescriptor.tableName;
			}
			if ( !foreignTableAlias )
			{
				foreignTableAlias = foreignDescriptor.tableName;
			}
			return foreignTableAlias + "." + foreignColumnName + " = " + localTableAlias + "." + localColumnName;
		}
	}
}