package com.huafu.sql.orm.relation
{
	import com.huafu.sql.orm.ORM;
	import com.huafu.sql.orm.ORMDescriptor;
	import com.huafu.sql.orm.ORMPropertyDescriptor;
	import com.huafu.sql.query.SQLiteQuery;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;

	public interface IORMRelation
	{
		function get foreignColumnName() : String;
		
		function get foreignRelation() : IORMRelation;
		
		function get ownerDescriptor() : ORMDescriptor;
		
		function get ownerPropertyName() : String;
		
		function get localColumnName() : String;
		
		function get foreignDescriptor() : ORMDescriptor;
		
		function get foreignOrmClass() : Class;
		
		function get foreignIsUnique() : Boolean;
		
		function get localColumnSqlCode() : String;
		
		function get foreignColumnProperty() : ORMPropertyDescriptor;
		
		function getSqlCondition( localTableAlias : String = null, foreignTableAlias : String = null, usingTableAlias : String = null ) : String;
		
		function setupQueryCondition( query : SQLiteQuery, ormObject : ORM, usingData : Object, localTableAlias : String = null, foreignTableAlias : String = null, usingTableAlias : String = null ) : void;
		
		function setupOrmObject( ormObject : ORM, ormObjectData : Object, usingData : Object ) : void;
	}
}