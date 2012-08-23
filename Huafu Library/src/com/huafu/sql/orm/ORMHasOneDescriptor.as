package com.huafu.sql.orm
{
	import flash.utils.getDefinitionByName;

	/**
	 * Handle the "has one" kind of relation on a ORM preoperty
	 */
	public class ORMHasOneDescriptor extends ORMRelationDescriptorBase implements IORMRelationDescriptor
	{
		/**
		 * If true, the relation is 0,1 else it is a 1,1
		 */
		private var _nullable : Boolean;
		/**
		 * The name of the column in the table where the information is stored
		 */
		private var _columnName : String;
		

		/**
		 * Creates a new "has one" kind of relation for a model property
		 * 
		 * @param ormDescriptor The descriptor owning the relation
		 * @param propertyName The name of the property where the relation object is saved
		 * @param relatedOrmClass The related ORM class
		 * @param nullable If true the relation is 0,1 else it is a 1,1
		 * @param columnName The name in the atabase where the ID of the related element is saved
		 */
		public function ORMHasOneDescriptor( ormDescriptor : ORMDescriptor, propertyName : String, relatedOrmClass : Class, nullable : Boolean = false, columnName : String = null )
		{
			super(ormDescriptor, propertyName, relatedOrmClass);
			_nullable = nullable;
			_columnName = columnName;
		}
		
		
		/**
		 * The related property descriptor object
		 */
		public function get relatedOrmPropertyDescriptor() : ORMPropertyDescriptor
		{
			return relatedOrmDescriptor.primaryKeyProperty;
		}
		
		
		/**
		 * The column name in the related ORM model
		 */
		public function get relatedColumnName() : String
		{
			return relatedOrmPropertyDescriptor.columnName;
		}
		
		
		/**
		 * Whether the relation is 0,1 or 1,1
		 */
		public function get nullable() : Boolean
		{
			return _nullable;
		}
		
		
		/**
		 * The name of the column in the database where is stored the information
		 */
		public function get columnName() : String
		{
			if ( !_columnName )
			{
				_columnName = relatedOrmDescriptor.tableName + "_id";
			}
			return _columnName;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function get columnSqlCode() : String
		{
			var p : ORMPropertyDescriptor,
				res : String;
			if ( (p = relatedOrmDescriptor.propertyDescriptorByColumnName(columnName)) )
			{
				return p.sqlCode;
			}
			p = relatedOrmPropertyDescriptor;
			res = "\"" + columnName + "\" " + p.columnDataType;
			if ( p.columnDataLength > 0 )
			{
				res += "(" + p.columnDataLength + ")";
			}
			res += " " + (nullable ? "" : "NOT ") + "NULL";
			return res;
		}
		
		
		/**
		 * Setup the property of an ORM object looking at this realtion
		 * 
		 * @param ormObject The ORM object to setup property of
		 * @param dataObject The dataObject that the ORM object holds
		 * @param resultRow The result row object containing data for this relation
		 */
		public function setupOrmObject( ormObject : ORM, dataObject : Object, resultRow : Object ) : void
		{
			var res : ORM, id : int = resultRow[columnName];
			if ( id )
			{
				res = ORM.factory(relatedOrmClass);
				if ( !res.find(id) )
				{
					res = null;
				}
			}
			else
			{
				res = null;
			}
			dataObject[propertyName] = res;
		}
	}
}