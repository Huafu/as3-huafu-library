package com.huafu.sql.orm
{
	import com.huafu.utils.reflection.ReflectionProperty;

	/**
	 * Defines a ORM realtion descriptor which is used with ORM object which has relation to other ORM objects
	 */
	public interface IORMRelationDescriptor
	{
		/**
		 * Called to setup an ORM object which has a relation described by a IORMRelationDescriptor
		 * 
		 * @param ormObject The ORM object ot setup
		 * @param resultRow The row comming from the db that might be used to setup the object looking at the relation
		 */
		function setupOrmObject( ormObject : ORM, resultRow : Object ) : void;
		
		/**
		 * The SQL code used to create the column in the ORM if any
		 */
		function get columnSqlCode() : String;
		
		/**
		 * The name of the column, if any, in the related ORM
		 */
		function get columnName() : String;
	}
}