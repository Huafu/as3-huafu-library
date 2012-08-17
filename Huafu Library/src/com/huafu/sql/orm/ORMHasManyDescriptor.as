package com.huafu.sql.orm
{
	import com.huafu.sql.SQLiteStatement;
	import com.huafu.utils.reflection.ReflectionProperty;

	public class ORMHasManyDescriptor extends ORMRelationDescriptorBase implements IORMRelationDescriptor
	{
		private var _relatedColumnName : String;
		
		public function ORMHasManyDescriptor( ormDescriptor : ORMDescriptor, propertyName : String, relatedClass : Class, relatedColumnName : String )
		{
			super(ormDescriptor, propertyName, relatedClass);
			_relatedColumnName = relatedColumnName;
		}
		
		
		public function get columnName() : String
		{
			return ormDescriptor.primaryKeyProperty.columnName;
		}
		
		
		public function get relatedColumnName() : String
		{
			return _relatedColumnName;
		}
		
		
		public function setupOrmObject( ormObject : ORM, resultRow : Object ) : void
		{
			var res : ORMIterator, stmt : SQLiteStatement, sql : String;
			if ( ormObject[propertyName] )
			{
				return;
			}
			sql = "SELECT * FROM " + relatedOrmDescriptor.tableName + " WHERE " + relatedColumnName + " = :" + propertyName;
			stmt = ormObject.connection.createStatement(sql, true);
			res = new ORMIterator(ormDescriptor.ormClass, stmt, ormObject);
			ormObject[propertyName] = res;
		}
	}
}