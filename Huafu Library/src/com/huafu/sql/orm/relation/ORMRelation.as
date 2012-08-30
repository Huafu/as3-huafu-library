package com.huafu.sql.orm.relation
{
	import com.huafu.sql.orm.ORM;
	import com.huafu.sql.orm.ORMDescriptor;
	import com.huafu.sql.orm.ORMPropertyDescriptor;
	import com.huafu.sql.query.SQLiteCondition;
	import com.huafu.sql.query.SQLiteQuery;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;
	
	import flash.errors.IllegalOperationError;

	public class ORMRelation
	{
		protected var _destinationOrmDescriptor : ORMDescriptor;
		protected var _destinationOrmPropertyName : String;
		protected var _localColumnName : String;
		
		protected var _foreignColumnName : String;
		protected var _foreignOrmClassName : String;
		protected var _foreignOrmClass : Class;
		protected var _foreignOrmDescriptor : ORMDescriptor;
		protected var _foreignRelation : IORMRelation;
		protected var _foreignIsUnique : Boolean;
		
		public function ORMRelation( ownerDescriptor : ORMDescriptor, property : ReflectionProperty, metadata : ReflectionMetadata )
		{
			_destinationOrmDescriptor = ownerDescriptor;
			_destinationOrmPropertyName = property.name;
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
			if ( !_foreignOrmClass )
			{
				_foreignOrmClass = ORMDescriptor.resolveOrmClass(_foreignOrmClassName, ownerDescriptor);
			}
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
		
		
		internal static function readOrmClassFromMetadataArg( metadata : ReflectionMetadata, argName : String = "className" ) : String
		{
			var className : String;
			className = metadata.argValueString("className");
			if ( !className )
			{
				throw new IllegalOperationError("You must define a '" + argName + "' argument on the '" + metadata.name
					+ "' metadata of the property '" + (metadata.owner as ReflectionProperty).name + "' defined in model '"
					+ (metadata.owner as ReflectionProperty).owner.className + "'");
			}
			return className;
		}
	}
}