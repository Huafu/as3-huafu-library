package com.huafu.sql.orm
{
	import com.huafu.sql.SQLiteStatement;

	/**
	 * Describe and handle a "has many using" relation property in a model
	 */
	public class ORMHasManyUsingDescriptor extends ORMHasOneDescriptor implements IORMRelationDescriptor
	{
		/**
		 * The ORM class that describe the table used to make the relations
		 */
		private var _usingOrmClass: Class;
		/**
		 * The ORM descriptor of the "using" table
		 */
		private var _usingOrmDescriptor : ORMDescriptor;
		/**
		 * The relation in the "using" table to the ORM descriptor holding this relation
		 */
		private var _relationToMe : ORMHasOneDescriptor;
		/**
		 * The relation in the "using" table to the related ORM descriptor
		 */
		private var _relationToRelated : ORMHasOneDescriptor;
		
		
		/**
		 * Creates a "has many using" relation
		 * 
		 * @param ormDescriptor The ORM descriptor holding the relation
		 * @param propertyName The name of the proeprty holding the relation
		 * @param relatedOrmClass The ORM class that will give this relation
		 * @param usingOrmClass The class of the ORM object that holds relation informations
		 */
		public function ORMHasManyUsingDescriptor( ormDescriptor : ORMDescriptor, propertyName : String, relatedOrmClass : Class, usingOrmClass : Class )
		{
			super(ormDescriptor, propertyName, relatedOrmClass, false, ormDescriptor.primaryKeyProperty.columnName);
			_usingOrmClass = usingOrmClass;
		}
		
		
		/**
		 * The ORM descriptor of the "using" table
		 */
		public function get usingOrmDescriptor() : ORMDescriptor
		{
			if ( !_usingOrmDescriptor )
			{
				_usingOrmDescriptor = ORMDescriptor.forClass(_usingOrmClass);
			}
			return _usingOrmDescriptor;
		}
		
		
		/**
		 * The relation in the "using" table to the ORM descriptor holding this relation
		 */
		public function get relationToMe() : ORMHasOneDescriptor
		{
			if ( !_relationToMe )
			{
				_relationToMe = usingOrmDescriptor.getRelationTo(ormDescriptor, ORMHasOneDescriptor) as ORMHasOneDescriptor;
			}
			return _relationToMe;
		}
		
		
		/**
		 * The relation in the "using" table to the related ORM descriptor
		 */
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
				relatedOrmDescriptor.globalOrmInstance.excludeSoftDeleted = usingOrmDescriptor.globalOrmInstance.excludeSoftDeleted = ormObject.excludeSoftDeleted;
				sql = "SELECT r.*, u." + usingOrmDescriptor.primaryKeyProperty.columnName
					+ " AS __using_pk_value FROM " + relatedOrmDescriptor.tableName + " AS r, "
					+ usingOrmDescriptor.tableName + " AS u WHERE u." + relationToRelated.columnName + " = "
					+ relationToRelated.relatedColumnName + " AND u." + relationToMe.columnName + " = :"
					+ columnName
					+ relatedOrmDescriptor.globalOrmInstance.getDeletedCondition(" AND ")
					+ usingOrmDescriptor.globalOrmInstance.getDeletedCondition(" AND ");
				stmt = relatedOrmDescriptor.connection.createStatement(ORM.PREPEND_SQL_COMMENT + sql);
				stmt.bind(columnName, null);
				iterator = new ORMIterator(relatedOrmClass, stmt, dataObject);
				dataObject[propertyName] = iterator;
			}
		}
	}
}