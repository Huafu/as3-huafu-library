package com.huafu.sql.orm
{
	import com.huafu.sql.SQLiteStatement;

	public class ORMHasManyUsingDescriptor extends ORMHasOneDescriptor implements IORMRelationDescriptor
	{
		private var _usingOrmClass: Class;
		private var _usingOrmDescriptor : ORMDescriptor;
		private var _relationToMe : ORMHasOneDescriptor;
		private var _relationToRelated : ORMHasOneDescriptor;
		
		public function ORMHasManyUsingDescriptor( ormDescriptor : ORMDescriptor, propertyName : String, relatedOrmClass : Class, usingOrmClass : Class )
		{
			super(ormDescriptor, propertyName, relatedOrmClass, false, ormDescriptor.primaryKeyProperty.columnName);
			_usingOrmClass = usingOrmClass;
		}
		
		
		public function get usingOrmDescriptor() : ORMDescriptor
		{
			if ( !_usingOrmDescriptor )
			{
				_usingOrmDescriptor = ORMDescriptor.forClass(_usingOrmClass);
			}
			return _usingOrmDescriptor;
		}
		
		
		public function get relationToMe() : ORMHasOneDescriptor
		{
			if ( !_relationToMe )
			{
				_relationToMe = usingOrmDescriptor.getRelationTo(ormDescriptor, ORMHasOneDescriptor) as ORMHasOneDescriptor;
			}
			return _relationToMe;
		}
		
		
		public function get relationToRelated() : ORMHasOneDescriptor
		{
			if ( !_relationToRelated )
			{
				_relationToRelated = usingOrmDescriptor.getRelationTo(relatedOrmDescriptor, ORMHasOneDescriptor) as ORMHasOneDescriptor;
			}
			return _relationToRelated;
		}
		
		
		/**
		 * Setup an object's property that describe this relation object
		 * 
		 * @param ormObject The ORM object ot setup
		 * @param dataObject The dataObject that the ORM object holds
		 * @param resultRow The row comming from the db that might be used to setup the object looking at the relation
		 */
		override public function setupOrmObject( ormObject : ORM, dataObject : Object, resultRow : Object ) : void
		{
			var iterator : ORMIterator, stmt : SQLiteStatement, sql : String;
			if ( !dataObject[propertyName] )
			{
				sql = "SELECT r.*, u." + usingOrmDescriptor.primaryKeyProperty.columnName
					+ " AS __using_pk_value FROM " + relatedOrmDescriptor.tableName + " AS r, "
					+ usingOrmDescriptor.tableName + " AS u WHERE u." + relationToRelated.columnName + " = "
					+ relationToRelated.relatedColumnName + " AND u." + relationToMe.columnName + " = :"
					+ columnName;
				stmt = relatedOrmDescriptor.connection.createStatement(sql);
				stmt.bind(columnName, null);
				iterator = new ORMIterator(relatedOrmClass, stmt, dataObject);
				dataObject[propertyName] = iterator;
			}
		}
	}
}