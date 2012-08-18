package com.huafu.sql.orm
{
	import flash.utils.getDefinitionByName;

	/**
	 * Handle the "has one" kind of relation on a ORM preoperty
	 */
	public class ORMHasOneDescriptor extends ORMRelationDescriptorBase implements IORMRelationDescriptor
	{
		/**
		 * @var If true, the relation is 0,1 else it is a 1,1
		 */
		private var _nullable : Boolean;
		/**
		 * @var The name of the column in the table where the information is stored
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
		 * @var The related property descriptor object
		 */
		public function get relatedOrmPropertyDescriptor() : ORMPropertyDescriptor
		{
			return relatedOrmDescriptor.primaryKeyProperty;
		}
		
		
		/**
		 * @var Whether the relation is 0,1 or 1,1
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
		 * Setup the property of an ORM object looking at this realtion
		 * 
		 * @param ormObject The ORM object to setup property of
		 * @param resultRow The result row object containing data for this relation
		 */
		public function setupOrmObject( ormObject : ORM, resultRow : Object ) : void
		{
			var res : ORM, id : int = resultRow[columnName];
			if ( id )
			{
				res = new relatedOrmClass();
				if ( !res.find(id) )
				{
					res = null;
				}
			}
			else
			{
				res = null;
			}
			ormObject[propertyName] = res;
		}
	}
}