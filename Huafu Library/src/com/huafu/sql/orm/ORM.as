package com.huafu.sql.orm
{
	import avmplus.getQualifiedClassName;
	
	import com.huafu.sql.SQLiteConnection;
	import com.huafu.sql.SQLiteStatement;
	
	import flash.data.SQLResult;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getDefinitionByName;
	
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	import mx.utils.ObjectProxy;

	[Event(name="propertyUpdate", type="com.huafu.sql.orm.ORMEvent")]
	[Event(name="loaded", type="com.huafu.sql.orm.ORMEvent")]
	[Event(name="saving", type="com.huafu.sql.orm.ORMEvent")]
	[Event(name="saved", type="com.huafu.sql.orm.ORMEvent")]
	[Event(name="deleted", type="com.huafu.sql.orm.ORMEvent")]
	public class ORM extends EventDispatcher
	{
		public static var defaultDatabaseName : String = "main";
		
		private var _connection : SQLiteConnection;
		private var _descriptor : ORMDescriptor;
		private var _objectProxy : ObjectProxy;
		private var _isLoaded : Boolean;
		private var _hasChanged : Array;
		private var _isSaved : Boolean;
		private var _class : Class;
		private var _classQName : String;
		private var _updateHandlerEnabled : int;
		
		
		public function ORM()
		{	
			_objectProxy = new ObjectProxy(this);
			_descriptor = ORMDescriptor.forObject(this);
			_updateHandlerEnabled = 1;
			_reset();
			
			// listen to changes on the properties
			_objectProxy.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, _propertyChangeHandler);
		}
		
		
		public function find( id : int ) : Boolean
		{
			var res : SQLResult, ev : ORMEvent,
				stmt : SQLiteStatement = connection.createStatement(
				"SELECT * FROM " + ormDescriptor.tableName
				+ " WHERE " + primaryKeyColumnName + " = :" + primaryKeyPropertyName);
			_reset();
			stmt.bind(primaryKeyPropertyName, id);
			stmt.execute();
			res = stmt.getResult();
			if ( res.data.length == 0 )
			{
				return false;
			}
			loadDataFromSqlResult(stmt.getResult().data[0]);
			
			ev = new ORMEvent(ORMEvent.LOADED);
			dispatchEvent(ev);
			
			return true;
		}
		
		
		public function loadDataFromSqlResult( result : Object, flagAsLoaded : Boolean = true ) : void
		{
			updateHandlerEnabled = false;
			ormDescriptor.sqlResultRowToOrmObject(result, this);
			_isLoaded = flagAsLoaded;
			_isSaved = flagAsLoaded;
			_hasChanged = new Array();
			updateHandlerEnabled = true;
		}
		
		
		public function findAll( params : Object = null, orderBy : Object = null, limit : int = -1, offset : int = 1 ) : ORMIterator
		{
			var sql : String = "SELECT * FROM " + ormDescriptor.tableName, value : *,
				_params : Array = new Array(), name : String, prop : ORMPropertyDescriptor,
				nameParts : Array, op : String, stmt : SQLiteStatement, binds : Object = {};
			
			for ( name in (params || {}) )
			{
				value = params[name];
				nameParts = name.split(/\s+/g);
				if ( nameParts.length > 1 )
				{
					op = nameParts[1];
				}
				else
				{
					op = "=";
				}
				name = nameParts[0];
				prop = ormDescriptor.propertyDescriptor(name);
				_params.push(prop.columnName + " " + op + " :" + name);
				binds[name] = value;
			}
			if ( _params.length > 0 )
			{
				sql += " WHERE " + _params.join(" AND ");
			}
			if ( orderBy )
			{
				_params = new Array();
				for ( name in orderBy )
				{
					prop = ormDescriptor.propertyDescriptor(name);
					_params.push(prop.columnName + " " + (!orderBy[name] || orderBy[name] == "DESC" ? "DESC" : "ASC"));
				}
				if ( _params.length > 0 )
				{
					sql += " ORDER BY " + _params.join(", ");
				}
			}
			if ( limit > 0 )
			{
				sql += " LIMIT " + limit + ", " + offset;
			}
			stmt = connection.createStatement(sql);
			stmt.bind(binds);
			stmt.execute();
			return new ORMIterator(classRef, stmt);
		}
		
		
		public function findAllBySql( whereSql : String, params : Object = null, orderBySql : String = null, groupBySql : String = null, limit : int = -1, offset : int = 1 ) : ORMIterator
		{
			var sql : String = "SELECT * FROM " + ormDescriptor.tableName, stmt : SQLiteStatement;
			if ( whereSql )
			{
				sql += " WHERE " + whereSql;
			}
			if ( groupBySql )
			{
				sql += " GROUP BY " + groupBySql;
			}
			if ( orderBySql )
			{
				sql += " ORDER BY " + orderBySql;
			}
			if ( limit > 0 )
			{
				sql += " LIMIT " + limit + ", " + offset;
			}
			stmt = connection.createStatement(sql, true);
			stmt.bind(params || {});
			stmt.execute();
			return new ORMIterator(classRef, stmt);
		}
		
		
		public function save() : Boolean
		{
			var ev : ORMEvent = new ORMEvent(ORMEvent.SAVING), sql : String, res : SQLResult,
				parts : Array, params : Object = {}, name : String, stmt : SQLiteStatement;
			
			dispatchEvent(ev);
			if ( ev.preventDefault() )
			{
				return false;
			}
			if ( primaryKeyValue )
			{
				// update
				if ( !hasChanged )
				{
					return true;
				}
				updateHandlerEnabled = true;
				if ( ormDescriptor.updatedAtProperty )
				{
					this[ormDescriptor.updatedAtProperty.name] = new Date();
					_hasChanged.push(ormDescriptor.updatedAtProperty.name);
				}
				updateHandlerEnabled = false;
				// create the sql statement
				sql = "UPDATE " + ormDescriptor.tableName + " SET ";
				parts = new Array();
				for each ( name in _hasChanged )
				{
					parts.push(ormDescriptor.propertyDescriptor(name).columnName + " = :" + name);
					params[name] = this[name];
				}
				sql += parts.join(", ") + " WHERE " + primaryKeyColumnName
					+ " = :" + primaryKeyPropertyName;
				params[primaryKeyPropertyName] = primaryKeyValue;
				
				// execute the sql
				stmt = connection.createStatement(sql, true);
				stmt.bind(params);
				stmt.execute();
				if ( stmt.getResult().rowsAffected > 0 )
				{
					_isSaved = true;
					_hasChanged = new Array();
					ev = new ORMEvent(ORMEvent.SAVED);
					dispatchEvent(ev);
					return true;
				}
			}
			else
			{
				// insert
				updateHandlerEnabled = false
				if ( ormDescriptor.createdAtProperty )
				{
					this[ormDescriptor.createdAtProperty.name] = new Date();
				}
				if ( ormDescriptor.updatedAtProperty )
				{
					this[ormDescriptor.updatedAtProperty.name] = new Date();
				}
				_hasChanged.push(ormDescriptor.createdAtProperty.name, ormDescriptor.updatedAtProperty.name);
				updateHandlerEnabled = true;
				
				// creates the SQL
				sql = " INSERT INTO " + ormDescriptor.tableName + "(";
				parts = new Array();
				for each ( name in _hasChanged )
				{
					parts.push(ormDescriptor.propertyDescriptor(name).columnName);
					params[name] = this[name];
				}
				sql += parts.join(", ") + ") VALUES(:" + _hasChanged.join(", :") + ")";
				
				// execute sql
				stmt = connection.createStatement(sql, true);
				stmt.bind(params);
				stmt.execute();
				res = stmt.getResult();
				if ( res.rowsAffected == 1 )
				{
					updateHandlerEnabled = false;
					this[primaryKeyPropertyName] = res.lastInsertRowID;
					updateHandlerEnabled = true;
					_isSaved = true;
					_hasChanged = new Array();
					ev = new ORMEvent(ORMEvent.SAVED);
					dispatchEvent(ev);
					return true;
				}
			}
			return false;
		}
		
		
		public function get connection() : SQLiteConnection
		{
			if ( !_connection )
			{
				_connection = SQLiteConnection.instance();
			}
			return _connection;
		}
		
		
		public function set connectionName( connectionName : String ) : void
		{
			_connection = SQLiteConnection.instance( connectionName );
		}
		
		
		public function get primaryKeyValue() : int
		{
			return this[primaryKeyPropertyName];
		}
		
		
		public function get primaryKeyPropertyName() : String
		{
			return _descriptor.primaryKeyProperty.name;
		}
		
		
		public function get primaryKeyColumnName() : String
		{
			return _descriptor.primaryKeyProperty.columnName;
		}
		
		
		public function get classQName() : String
		{
			if ( !_classQName )
			{
				_classQName = getQualifiedClassName(this);
			}
			return _classQName;
		}
		
		
		public function get classRef() : Class
		{
			if ( !_class )
			{
				_class = getDefinitionByName(classQName) as Class;
			}
			return _class;
		}
		
		
		public function get ormDescriptor() : ORMDescriptor
		{
			return _descriptor;
		}
		
		
		public function get isSaved() : Boolean
		{
			return _isSaved;
		}
		
		
		public function get isLoaded() : Boolean
		{
			return _isLoaded;
		}
		
		
		public function get hasChanged() : Boolean
		{
			return (_hasChanged.length > 0);
		}
		
		
		private function set updateHandlerEnabled( value : Boolean ) : void
		{
			_updateHandlerEnabled += value ? 1 : -1;
		}
		
		
		private function _propertyChangeHandler( event : PropertyChangeEvent ) : void
		{
			if ( _updateHandlerEnabled < 1 || event.kind != PropertyChangeEventKind.UPDATE )
			{
				return;
			}
			var prop : ORMPropertyDescriptor = _descriptor.propertyDescriptor(event.property.toString());
			if ( !prop )
			{
				return;
			}
			// here it's a property of the ORM that has changed
			if ( prop.isReadOnly )
			{
				throw new IllegalOperationError("The property '" + prop.name + "'  of model '" + _descriptor.ormClassQName + "' is read-only");
			}
			var ev : ORMEvent = new ORMEvent(ORMEvent.PROPERTY_UPDATE, prop);
			dispatchEvent(ev);
			// if the event has been cancelled, don't do the update
			if ( ev.isDefaultPrevented() )
			{
				updateHandlerEnabled = false;
				this[prop.name] = event.oldValue;
				updateHandlerEnabled = true;
			}
			else
			{
				_isSaved = false;
				_isLoaded = false;
				if ( _hasChanged.indexOf(prop.name) == -1 )
				{
					_hasChanged.push(prop.name, true);
				}
			}
		}
		
		private function _reset() : void
		{
			updateHandlerEnabled = false;
			_isLoaded = false;
			_isSaved = false;
			_hasChanged = new Array();
			loadDataFromSqlResult({}, false);
			updateHandlerEnabled = true;
		}
	}
}