package com.huafu.sql
{
	import flash.data.SQLStatement;
	import flash.net.Responder;
	
	
	/**
	 * Handle statments as the native SQLStatement but auto openning the connection on demand
	 * @see flash.data.SQLStatement
	 */
	public class SQLiteStatement extends SQLStatement
	{
		
		/**
		 * Constructor
		 */
		public function SQLiteStatement()
		{
			super();
		}
		
		
		/**
		 * Execute the statement, opening the connection if this one isn't opened yet
		 * @inheritDoc
		 */
		override public function execute( prefetch : int = -1, responder : Responder = null ) : void
		{
			(sqlConnection as SQLiteConnection).autoOpen();
			super.execute(prefetch, responder);
		}
		
		
		/**
		 * Bind one or more parameters to the parameters property of this object
		 * 
		 * @param nameOrObject The name of the parameter if the second parameter is the
		 * vaue of the parameter. If this parameter is an object, all properties of this
		 * object will be binded to the parameter proeprty
		 * @param value Value of the parameter to bind
		 * @return Returns this object to do chained calls
		 */
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