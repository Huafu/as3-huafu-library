package com.huafu.sql.orm
{
	import flash.utils.getDefinitionByName;

	public class ORMHasOneDescriptor extends ORMRelationDescriptorBase implements IORMRelationDescriptor
	{
		private var _nullable : Boolean;
		private var _columnName : String;
		

		public function ORMHasOneDescriptor( ormDescriptor : ORMDescriptor, propertyName : String, relatedOrmClass : Class, nullable : Boolean = false, columnName : String = null )
		{
			super(ormDescriptor, propertyName, relatedOrmClass);
			_nullable = nullable;
			_columnName = columnName;
		}
		
		
		public function get relatedOrmPropertyDescriptor() : ORMPropertyDescriptor
		{
			return relatedOrmDescriptor.primaryKeyProperty;
		}
		
		
		public function get nullable() : Boolean
		{
			return _nullable;
		}
		
		
		public function get columnName() : String
		{
			if ( !_columnName )
			{
				_columnName = relatedOrmDescriptor.tableName + "_id";
			}
			return _columnName;
		}
		
		
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