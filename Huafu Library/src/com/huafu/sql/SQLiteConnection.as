package com.huafu.sql
{
	import flash.data.SQLColumnSchema;
	import flash.data.SQLConnection;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLTableSchema;
	import flash.errors.IllegalOperationError;
	import flash.filesystem.File;
	import flash.net.Responder;
	import flash.utils.Dictionary;
	
	public class SQLiteConnection extends SQLConnection
	{
		private static var _allByName : Dictionary = new Dictionary();
		private static var _creatingConnection : Boolean = false;
		
		
		public static var defaultConnectionName : String = "main";
		public static var defaultDatabaseName : String = "main";
		
		private var _stmtCache : Dictionary;
		private var _name : String;
		private var _cachedSchema : SQLSchemaResult;
		private var _tableSchemas : Dictionary;
		
		
		public function SQLiteConnection( name : String )
		{
			super();
			if ( !_creatingConnection )
			{
				throw new IllegalOperationError("You must create/load a connection using the 'instance' method");
			}
			_stmtCache = new Dictionary();
			_name = name;
		}
		
		
		public function get name() : String
		{
			return _name;
		}
		
		
		public function autoOpen() : SQLConnection
		{
			var file : File;
			if ( !connected )
			{
				file = File.applicationStorageDirectory.resolvePath(_name + ".sqlite");
				open(file);
			}
			return super;
		}
		
		
		public function createStatement( sql : String, noCache : Boolean = false ) : SQLiteStatement
		{
			var res : SQLiteStatement = noCache ? null : _stmtCache[sql];
			if ( res )
			{
				res.clearParameters();
				return res;
			}
			res = new SQLiteStatement();
			res.sqlConnection = this;
			res.text = sql;
			if ( !noCache )
			{
				_stmtCache[sql] = res;
			}
			return res;
		}
		
		
		override public function begin( option : String = null, responder : Responder = null ) : void
		{
			autoOpen().begin(option, responder);
		}
		
		
		override public function loadSchema( type : Class = null, name : String = null, database : String = "main", includeColumnSchema : Boolean = true, responder : Responder = null ) : void
		{
			var sTable : SQLTableSchema;
			autoOpen().loadSchema(type, name, database, includeColumnSchema, responder);
			_cachedSchema = getSchemaResult();
			_tableSchemas = new Dictionary();
			for each ( sTable in _cachedSchema.tables )
			{
				_tableSchemas[sTable.database + "." + sTable.name] = sTable;
			}
		}
		
		
		public function getTableSchema( tableName : String, databaseName : String = null ) : SQLTableSchema
		{
			var key : String = getTableName(tableName, databaseName);
			if ( !_cachedSchema || !(key in _tableSchemas) )
			{
				loadSchema();
			}
			return _tableSchemas[key];
		}
		
		
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
		
		
		private function getTableName( tableName : String, databaseName : String = null) : String
		{
			return (databaseName ? databaseName : defaultDatabaseName) + "." + tableName;
		}
		
		
		public static function instance( name : String = null ) : SQLiteConnection
		{
			if ( arguments.length < 1 )
			{
				name = defaultConnectionName;
			}
			var res : SQLiteConnection = _allByName[name];
			if ( res )
			{
				return res;
			}
			_creatingConnection = true;
			res = new SQLiteConnection(name);
			_allByName[name] = res;
			return res;
		}
	}
}