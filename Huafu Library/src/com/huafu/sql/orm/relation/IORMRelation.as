package com.huafu.sql.orm.relation
{
	import com.huafu.sql.orm.ORM;
	import com.huafu.sql.orm.ORMDescriptor;
	import com.huafu.sql.orm.ORMPropertyDescriptor;
	import com.huafu.sql.query.SQLiteQuery;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;

	
	/**
	 * Any relation has to implement this interface to work correctly
	 */
	public interface IORMRelation
	{
		/**
		 * The name of the column in the foreign table to link on
		 */
		function get foreignColumnName() : String;
		/**
		 * The opposite relation if any defined
		 */
		function get foreignRelation() : IORMRelation;
		/**
		 * The ORM descriptor owning the relation
		 */
		function get ownerDescriptor() : ORMDescriptor;
		/**
		 * Nam of the property in the ORM owner of the relation
		 */
		function get ownerPropertyName() : String;
		/**
		 * Name of the column used to make the relation in the table of the ORM owner of this relation
		 */
		function get localColumnName() : String;
		/**
		 * The ORM descriptor of theforeign table
		 */
		function get foreignDescriptor() : ORMDescriptor;
		/**
		 * The class of the foreign ORM
		 */
		function get foreignOrmClass() : Class;
		/**
		 * If there can be only ONE foreign and no more, this value is true
		 */
		function get foreignIsUnique() : Boolean;
		/**
		 * The SQL code of the column in the table owning the relation, if any
		 */
		function get localColumnSqlCode() : String;
		/**
		 * The property descriptor corresponding of the foreign column
		 */
		function get foreignColumnProperty() : ORMPropertyDescriptor;
		/**
		 * Get the SQL condition to make the link between the 2 or 3 tables involved in the relation
		 * 
		 * @param localTableAlias The alias of the local table (owning the relation)
		 * @param foreignTableAlias The alias of the foreign table
		 * @param usingTableAlias Only used if a third party table is used in the relation, is the alias of this third party table
		 * @return The SQL code to make the relation between the 2 or 3 tables
		 */
		function getSqlCondition( localTableAlias : String = null, foreignTableAlias : String = null, usingTableAlias : String = null ) : String;
		/**
		 * Setup the conditions to make the query bring related (foreign) object looking at a given ORM object and data used to load this ORM
		 * 
		 * @param query The query object to setup
		 * @param ormObject The ORM object corresponding to the entity owning the relation
		 * @param usingData The data to use as source to bind possible values from this ORM object
		 * @param localTableAlias The alias of the local table (owning the relation)
		 * @param foreignTableAlias The alias of the foreign table
		 * @param usingTableAlias Only used if a third party table is used in the relation, is the alias of this third party table
		 */
		function setupQueryCondition( query : SQLiteQuery, ormObject : ORM, usingData : Object, localTableAlias : String = null, foreignTableAlias : String = null, usingTableAlias : String = null ) : void;
		/**
		 * Setup the property holding the relation of the given ORM object to receive the related (foreign) object(s)
		 * 
		 * @param ormObject The ORM object to setup
		 * @param ormObjectData The data object of this ORM object
		 * @param usingData The data to use to find related objects
		 */
		function setupOrmObject( ormObject : ORM, ormObjectData : Object, usingData : Object ) : void;
	}
}