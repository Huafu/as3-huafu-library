package com.huafu.sql.orm
{
	import com.huafu.sql.SQLiteStatement;
	import com.huafu.utils.reflection.ReflectionProperty;

	/**
	 * Describe and handle a "has many" relation property in a model
	 */
	public class ORMHasManyDescriptor extends ORMRelationDescriptorBase implements IORMRelationDescriptor
	{
		/**
		 * @var The name of the column in the related table
		 */
		private var _relatedColumnName : String;
		
		
		/**
		 * Creates a new has many relation descriptor
		 * 
		 * @param ormDescriptor The ORM descriptor that holds the property corresponding to a relation
		 * @param propertyName The property name in the owner descriptor
		 * @param relatedClass The class of the related ORM
		 * @param realtedColumnName The name of the column in the related table
		 */
		public function ORMHasManyDescriptor( ormDescriptor : ORMDescriptor, propertyName : String, relatedClass : Class, relatedColumnName : String )
		{
			super(ormDescriptor, propertyName, relatedClass);
			_relatedColumnName = relatedColumnName;
		}
		
		
		/**
		 * @var Name of the column in the owner descriptor responsible to make the realtion
		 */
		public function get columnName() : String
		{
			return ormDescriptor.primaryKeyProperty.columnName;
		}
		
		
		/**
		 * @var The name of the column in the related descriptor
		 */
		public function get relatedColumnName() : String
		{
			return _relatedColumnName;
		}
		
		
		/**
		 * Setup the property of an ORM object looking at this realtion
		 * 
		 * @param ormObject The ORM object to setup property of
		 * @param resultRow The result row object containing data for this relation
		 */
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