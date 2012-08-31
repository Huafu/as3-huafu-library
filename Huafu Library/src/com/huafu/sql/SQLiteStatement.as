package com.huafu.sql
{
	import com.huafu.common.Huafu;
	
	import flash.data.SQLStatement;
	import flash.errors.IllegalOperationError;
	import flash.errors.SQLError;
	import flash.events.SQLErrorEvent;
	import flash.net.Responder;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.logging.LogLogger;
	
	
	/**
	 * Handle statments as the native SQLStatement but auto openning the connection on demand
	 * @see flash.data.SQLStatement
	 */
	public class SQLiteStatement extends SQLStatement
	{
		/**
		 * To avoid user to create a cached statement without calling the SQLiteConnection.createStatement method
		 */
		internal static var _creatingStatement : Boolean = false;
		
		/**
		 * Stores the last error that occurres or null if the last execute call doesn't throw any error
		 */
		private var _lastError : SQLError;
		/**
		 * Stores whether the statement is cached or not
		 */
		private var _cached : Boolean;
		
		
		/**
		 * Constructor
		 * 
		 * @param cached Used internally
		 */
		public function SQLiteStatement( text : String = null, cached : Boolean = false )
		{
			super();
			if ( cached && !_creatingStatement )
			{
				throw new IllegalOperationError("Trying to create a cached statement without using the createStatement() helper from the SQLiteConnection class");
			}
			_creatingStatement = false;
			_lastError = null;
			if ( text )
			{
				super.text = text;
			}
			_cached = cached;
			addEventListener(SQLErrorEvent.ERROR, _sqlErrorHandler);
		}
		
		
		/**
		 * Execute the statement, opening the connection if this one isn't opened yet
		 * @inheritDoc
		 */
		override public function execute( prefetch : int = -1, responder : Responder = null ) : void
		{
			_lastError = null;
			(sqlConnection as SQLiteConnection).autoOpen();
			logger.debug("Executing a SQL query", text);
			super.execute(prefetch, responder);
		}
		
		
		/**
		 * The logger for this class
		 */		
		private function get logger() : ILogger
		{
			if ( !_logger )
			{
				_logger = Huafu.getLoggerFor(SQLiteStatement);
			}
			return _logger;
		}
		private var _logger : ILogger;
		
		
		/**
		 * Execute the statement, but return false or throw an exception if there was a SQL error
		 * 
		 * @inheritDoc
		 * @param throwError If true, the error will be thrown if any, else only false returned in case of error
		 * @return If no error, returns true, else returns false
		 * @see #execute
		 */
		public function safeExecute( throwError : Boolean = true, prefetch : int = -1, responder : Responder = null ) : Boolean
		{
			execute(prefetch, responder);
			if ( throwError && _lastError )
			{
				throw _lastError;
			}
			return !_lastError;
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
				parameters[":" + nameOrObject as String] = value;
			}
			else
			{
				for ( name in nameOrObject )
				{
					parameters[":" + name] = nameOrObject[name];
				}
			}
			return this;
		}
		
		
		/**
		 * SQL code of the query
		 * @inheritDoc
		 */
		override public function set text( value : String ) : void
		{
			if ( _cached )
			{
				throw new IllegalOperationError("Trying to change the text property of a cached statement");
			}
			super.text = value;
		}
		
		
		/**
		 * The error (if any) that occures during last operation ran by exectue() method
		 */
		public function get lastError() : SQLError
		{
			return _lastError;
		}
		
		
		/**
		 * Handle the SQL error event
		 * 
		 * @param event The event triggered
		 */
		private function _sqlErrorHandler( event : SQLErrorEvent ) : void
		{
			_lastError = event.error;
		}
	}
}