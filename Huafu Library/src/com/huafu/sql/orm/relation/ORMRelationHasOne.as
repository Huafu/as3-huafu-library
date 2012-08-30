package com.huafu.sql.orm.relation
{
	import com.huafu.sql.orm.ORM;
	import com.huafu.sql.orm.ORMDescriptor;
	import com.huafu.sql.query.SQLiteCondition;
	import com.huafu.sql.query.SQLiteQuery;
	
	public class ORMRelationHasOne extends ORMRelation implements IORMRelation
	{
		public var _nullable : Boolean;
		
		public function ORMRelationHasOne(ownerDescriptor:ORMDescriptor, ownerPropertyName:String, localColumnName : String, foreignOrmClass:Class, nullable : Boolean = false)
		{
			super(ownerDescriptor, ownerPropertyName, foreignOrmClass, null);
			_foreignIsUnique = true;
			_nullable = nullable;
			_localColumnName = localColumnName;
		}
		
		
		override public function get foreignColumnName() : String
		{
			return foreignDescriptor.primaryKeyProperty.columnName;
		}
		
		
		public function setupOrmObject( ormObject : ORM, ormObjectData : Object, usingData : Object ) : void
		{
			var res : ORM = ormObjectData[ownerPropertyName] || null;
			if ( !usingData || !usingData[localColumnName] )
			{
				ormObjectData[ownerPropertyName] = null;
				return;
			}
			if ( !res )
			{
				res = new foreignOrmClass();
				ormObjectData[ownerPropertyName] = res;
			}
			res.excludeSoftDeleted = ormObject.excludeSoftDeleted;
			res.find(usingData[localColumnName]);
			if ( !res.isLoaded )
			{
				ormObjectData[ownerPropertyName] = null;
			}
		}
	}
}