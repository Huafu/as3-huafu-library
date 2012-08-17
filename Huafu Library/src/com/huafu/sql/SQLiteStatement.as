package com.huafu.sql
{
	import flash.data.SQLStatement;
	import flash.errors.IllegalOperationError;
	import flash.net.Responder;
	
	public class SQLiteStatement extends SQLStatement
	{
		public function SQLiteStatement()
		{
			super();
		}
		
		
		override public function execute( prefetch : int = -1, responder : Responder = null ) : void
		{
			(sqlConnection as SQLiteConnection).autoOpen();
			super.execute(prefetch, responder);
		}
		
		
		public function bind( nameOrObject : *, value : * = null ) : SQLiteStatement
		{
			var name : String;
			if ( arguments.length == 2 )
			{
				parameters[nameOrObject as String] = value;
			}
			else
			{
				for ( name in nameOrObject )
				{
					parameters[name] = nameOrObject[name];
				}
			}
			return this;
		}
	}
}