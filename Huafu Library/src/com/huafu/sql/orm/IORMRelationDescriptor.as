package com.huafu.sql.orm
{
	import com.huafu.utils.reflection.ReflectionProperty;

	public interface IORMRelationDescriptor
	{
		function setupOrmObject( ormObject : ORM, resultRow : Object ) : void;
	}
}