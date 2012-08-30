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
	
	public class ORMRelationHasMany extends ORMRelation implements IORMRelation
	{
		public function ORMRelationHasMany( ownerDescriptor : ORMDescriptor, property : ReflectionProperty, metadata : ReflectionMetadata )
		{
			super(ownerDescriptor, property, metadata);
			_foreignColumnName = metadata.argValueString("foreignColumn");
			_foreignOrmClassName = ORMRelation.readOrmClassFromMetadataArg(metadata);
			_localColumnName = metadata.argValueString("column");
		}
		
		
		override public function get foreignColumnName() : String
		{
			if ( !_foreignColumnName )
			{
				_foreignColumnName = ownerDescriptor.tableName + "_id";
			}
			return _foreignColumnName;
		}
		
		
		override public function get localColumnName() : String
		{
			if ( !_localColumnName )
			{
				_localColumnName = ownerDescriptor.primaryKeyProperty.columnName;
			}
			return _localColumnName;
		}
		
		
		public function setupOrmObject(ormObject:ORM, ormObjectData:Object, usingData:Object):void
		{
			var res : ORMIterator, foreignOrm : ORM = foreignDescriptor.globalOrmInstance,
				q : SQLiteQuery;
			
			foreignOrm.excludeSoftDeleted = ormObject.excludeSoftDeleted;
			q = foreignOrm.getPreparedQuery();
			q.where(new SQLiteCondition(foreignColumnName + " = ?", usingData[localColumnName]));
			ormObjectData[ownerPropertyName] = new ORMIterator(foreignOrmClass, q.compile(), {});
		}
	}
}