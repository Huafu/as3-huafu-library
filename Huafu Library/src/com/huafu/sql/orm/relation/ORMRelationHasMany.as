package com.huafu.sql.orm.relation
{
	import com.huafu.sql.SQLiteStatement;
	import com.huafu.sql.orm.ORM;
	import com.huafu.sql.orm.ORMDescriptor;
	import com.huafu.sql.orm.ORMIterator;
	import com.huafu.sql.query.SQLiteCondition;
	import com.huafu.sql.query.SQLiteQuery;
	
	public class ORMRelationHasMany extends ORMRelation implements IORMRelation
	{
		public function ORMRelationHasMany(ownerDescriptor:ORMDescriptor, ownerPropertyName:String, foreignOrmClass:Class, foreignColumnName:String)
		{
			super(ownerDescriptor, ownerPropertyName, foreignOrmClass, foreignColumnName);
		}
		
		
		override public function get localColumnName() : String
		{
			return ownerDescriptor.primaryKeyProperty.columnName;
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