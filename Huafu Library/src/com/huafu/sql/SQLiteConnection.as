package com.huafu.sql
{
	import com.huafu.utils.HashMap;
	
	import flash.data.SQLColumnSchema;
	import flash.data.SQLConnection;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLTableSchema;
	import flash.errors.IllegalOperationError;
	import flash.errors.SQLError;
	import flash.filesystem.File;
	import flash.net.Responder;
	import flash.utils.Dictionary;
	
	
	/**
	 * Extends the native SQLConnection to be able to have auto connect on require
	 * feature and other common stuffs like the createStatement and a statement cache
	 * @see flash.data.SQLConnection
	 */
	public class SQLiteConnection extends SQLConnection
	{
		/**
		 * All connections indexed by their name
		 */
		private static var _allByName : HashMap = new HashMap();
		/**
		 * Internally used to know if it's actually creating a connection or not
		 */
		private static var _creatingConnection : Boolean = false;
		
		/**
		 * Used to know the defails connection name
		 */
		public static var defaultConnectionName : String = "main";
		/**
		 * Used to save the name of the default database
		 */
		public static var defaultDatabaseName : String = "main";
		
		
		/**
		 * Used to cache all statments looking at their SQL
		 */
		private var _stmtCache : HashMap;
		/**
		 * Name of the connection
		 */
		private var _name : String;
		/**
		 * The cached version of the schema information
		 */
		private var _cachedSchema : SQLSchemaResult;
		/**
		 * The schemas of tables indexed by db_name.table_name
		 */
		private var _tableSchemas : HashMap;
		
		
		/**
		 * Constructor, don't call direcly, call SQLiteConnection.instance("name") instead
		 * 
		 * @param name The name of the connection
		 */
		public function SQLiteConnection( name : String )
		{
			super();
			if ( !_creatingConnection )
			{
				throw new IllegalOperationError("You must create/load a connection using the 'instance' method");
			}
			_stmtCache = new HashMap();
			_name = name;
		}
		
		
		/**
		 * Name of the connection
		 */
		public function get name() : String
		{
			return _name;
		}
		
		
		/**
		 * Auto open the connection
		 */
		public function autoOpen() : void
		{
			var file : File;
			if ( !connected )
			{
				file = File.applicationStorageDirectory.resolvePath(_name + ".sqlite");
				open(file);
			}
		}
		
		
		/**
		 * Creates or get from the cache a statement
		 * 
		 * @param sql The sql code of the statement
		 * @param noCache If true, the cache won't be used or set
		 * @return The cache or new statement
		 */
		public function createStatement( sql : String = null, noCache : Boolean = false ) : SQLiteStatement
		{
			var res : SQLiteStatement = (noCache || !sql) ? null : _stmtCache.get(sql);
			if ( res )
			{
				res.clearParameters();
				return res;
			}
			SQLiteStatement._creatingStatement = true;
			res = new SQLiteStatement(sql, !noCache);
			res.sqlConnection = this;
			if ( !(noCache || !sql) )
			{
				_stmtCache.set(sql, res);
			}
			return res;
		}
		
		
		/**
		 * @inheritDoc
		 */
		override public function begin( option : String = null, responder : Responder = null ) : void
		{
			autoOpen();
			super.begin(option, responder);
		}
		
		
		/**
		 * Loads the schema after opening connection if necessary, also caches the schema
		 * @inheritDoc
		 */
		override public function loadSchema( type : Class = null, name : String = null, database : String = "main", includeColumnSchema : Boolean = true, responder : Responder = null ) : void
		{
			var sTable : SQLTableSchema;
			autoOpen();
			_cachedSchema = null;
			_tableSchemas = new HashMap();
			try
			{
				super.loadSchema(type, name, database, includeColumnSchema, responder);
			}
			catch ( err : SQLError )
			{
				// forget the "No schema objects in database 'xxx' were found." error
				if ( err.errorID != 3115 || err.detailID != 1010 )
				{
					throw err;
				}
				return;
			}
			_cachedSchema = getSchemaResult();
			for each ( sTable in _cachedSchema.tables )
			{
				_tableSchemas.set(sTable.database + "." + sTable.name, sTable);
			}
		}
		
		
		/**
		 * Get the schema of a table
		 * 
		 * @param tableName name of the table
		 * @param databaseName The name of the database
		 * @return The schema of that table
		 */
		public function getTableSchema( tableName : String, databaseName : String = null ) : SQLTableSchema
		{
			var key : String = getTableName(tableName, databaseName);
			if ( !_cachedSchema || !(key in _tableSchemas) )
			{
				loadSchema();
			}
			return _tableSchemas.get(key);
		}
		
		
		/**
		 * Creates an insert statement related to a given table
		 * 
		 * @param tableName The name of the table
		 * @param databaseName The name of the database where is the table
		 * @return The create statement ready to be binded with parameters and executed
		 */
		public function createInsertStatement( tableName : String, databaseName : String = null ) : SQLiteStatement
		{
			var sTable : SQLTableSchema = getTableSchema(tableName, databaseName),
				sql : String,
				cols : Array = new Array(),
				col : SQLColumnSchema;
			sql = "INSERT INTO " + getTableName(tableName, databaseName) + "(";
			for each ( col in sTable.columns )
			{
				if ( !col.autoIncrement )
				{
					cols.push(col.name);
				}
			}
			sql += cols.join(", ") + " VALUES(:" + cols.join(", :") + ")";
			return createStatement(sql);
		}
		
		
		/**
		 * Get the full table name looking at the given or default database name
		 * 
		 * @param tableName The name of the table
		 * @param databaseName The name of the database, if not set it'll be the default one
		 * @return The full name of the table
		 */
		private function getTableName( tableName : String, databaseName : String = null) : String
		{
			return (databaseName ? databaseName : defaultDatabaseName) + "." + tableName;
		}
		
		
		/**
		 * Create or retreive an existing instance of a database connection looking at a
		 * given database name
		 * 
		 * @param name The name of the connection
		 * @return The connection object
		 */
		public static function instance( name : String = null ) : SQLiteConnection
		{
			if ( !name )
			{
				name = defaultConnectionName;
			}
			var res : SQLiteConnection = _allByName.get(name);
			if ( res )
			{
				return res;
			}
			_creatingConnection = true;
			res = new SQLiteConnection(name);
			_allByName.set(name, res);
			return res;
		}
	}
}