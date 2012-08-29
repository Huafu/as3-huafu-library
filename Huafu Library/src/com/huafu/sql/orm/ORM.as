package com.huafu.sql.orm
{
	import avmplus.getQualifiedClassName;
	
	import com.huafu.sql.SQLiteConnection;
	import com.huafu.sql.SQLiteStatement;
	import com.huafu.sql.query.SQLiteCondition;
	import com.huafu.sql.query.SQLiteQuery;
	
	import flash.data.SQLResult;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.getDefinitionByName;
	
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	import mx.utils.ObjectProxy;

	
	/**
	 * @eventType com.huafu.sql.orm.ORMEvent.PROPERTY_UPDATE
	 */
	[Event(name="propertyUpdate", type="com.huafu.sql.orm.ORMEvent")]
	/**
	 * @eventType com.huafu.sql.orm.ORMEvent.LOADED
	 */
	[Event(name="loaded", type="com.huafu.sql.orm.ORMEvent")]
	/**
	 * @eventType com.huafu.sql.orm.ORMEvent.SAVING
	 */
	[Event(name="saving", type="com.huafu.sql.orm.ORMEvent")]
	/**
	 * @eventType com.huafu.sql.orm.ORMEvent.SAVED
	 */
	[Event(name="saved", type="com.huafu.sql.orm.ORMEvent")]
	/**
	 * @eventType com.huafu.sql.orm.ORMEvent.DELETING
	 */
	[Event(name="deleting", type="com.huafu.sql.orm.ORMEvent")]
	/**
	 * @eventType com.huafu.sql.orm.ORMEvent.DELETED
	 */
	[Event(name="deleted", type="com.huafu.sql.orm.ORMEvent")]
	
	/**
	 * Base class of any ORM model the user may define
	 * @example
	 * <listing version="3.0">
	 * 	// The Table metadata has to be present, but any of the arguments here are the default values so
	 * 	// no need to put them if you inten to use the same values
	 * 	[Table(name="user", database="main", primaryKey="id", connection="main", createdDate="cretaedAt", updatedDate="updatedAt", deletedDate="deletedAt")]
	 * 	public class User
	 * 	{
	 * 		// Also here the Column metadatas have to be present but hte arguments are the default values
	 * 		// so if you intend to use the same values you don't need to put them (the type, if not set,
	 * 		// is defined looking at the property's type)
	 * 		[Column(name="id", type="INTEGER")]
	 * 		public var id : int;
	 * 
	 * 		[Column(size="30", unique)]
	 * 		public var name : String;
	 * 
	 * 		// Here is how to define a "has one" relation type. By default the column name is the table name of the related
	 * 		// table on which "_id" is appended. The model of the related model is defined looking at the type of the variable.
	 * 		// When loading this object, if the associated column isn't null, it'll load the associated model object in this
	 * 		// property automatically, and changing this property will automatically save the good ID in the table when calling
	 * 		// the save() method
	 * 		[HasOne(columnName="avatar_id", nullable)]
	 * 		public var avatar : Avatar;
	 * 
	 * 		// Here is how to define a one to many relation. In this exact example you don't have to define this
	 * 		// property and metadata if you use only the next defined property (because it's a many to many relation
	 * 		// to the Tag model, but we also want to show how to define the one to many relation to the relation
	 * 		// table which is in this case defined by the model UserTag.
	 * 		// The ORM iterators of relations are prepared and setup at ORM object load, The first time you
	 * 		// gonna iterate through them it'll run the query and load the associated data transparently
	 * 		[HasMany(relatedColumnName="user_id", className="UserTag")]
	 * 		public var userTags : ORMIterator;
	 * 
	 * 		// Here is how to define a many to many relation, where a relation table is needed.
	 * 		// The "using" argument is the table to use as the realtion table, the "className" argument
	 * 		// contains the ORM model that the ORM iteartor will deliver
	 * 		[HasMany(className="Tag", using="UserTag")]
	 * 		public var tags : ORMIterator;
	 * 
	 * 		public function User()
	 * 		{
	 * 			// Since as3 isn't able to retreive the class from its name if it's not used before
	 * 			// you need to add any used ORM model class which is used in a realtion other than HasOne.
	 * 			// But here the Tag one is optional since normally the UserTag will contain a HasOne with the
	 * 			// model Tag so as3 will know about it already
	 * 			UserTag;
	 * 			Tag;
	 * 		}
	 * 	}
	 * 
	 * // then to use it, you have to use the factory method:
	 * var myUser : ORM = ORM.factory(User);
	 * // or to load one user with his id:
	 * var myUser : ORM = ORM.factory(User, 12);
	 * </listing>
	 */
	public dynamic class ORM extends ObjectProxy
	{
		/**
		 * The SQL comment prepended to each statement to be sure to have independant SQL staetment cache
		 */
		public static const PREPEND_SQL_COMMENT : String = "HORM";

		/**
		 * Used to avoid the coder to instanciate directly the class without using the factory static method
		 */
		private static var _dummyChecker : Object = {uid: "xxxx"};
		
		
		/**
		 * Stores the default database name of any table without database name defined
		 */
		public static var defaultDatabaseName : String = "main";
		
		/**
		 * The ORMDescriptor of this model
		 */
		private var _descriptor : ORMDescriptor;
		/**
		 * Stores the real data
		 */
		private var _data : *;
		/**
		 * Finds whether the object has been loaded or not
		 */
		private var _isLoaded : Boolean;
		/**
		 * Stores any property related to the model that may have changed
		 */
		private var _hasChanged : Array;
		/**
		 * Whether the object has been saved or not
		 */
		private var _isSaved : Boolean;
		/**
		 * Stores a pointer to the ORM class of this object
		 */
		private var _class : Class;
		/**
		 * The QName of the class of this object
		 */
		private var _classQName : String;
		/**
		 * Used to saved the last loaded data
		 */
		private var _lastLoadedData : Object;
		/**
		 * The SQL connection used for the related table
		 */
		private var _connection : SQLiteConnection;
		/**
		 * The query object used, using cached statements
		 */
		private var _query : SQLiteQuery;
		/**
		 * The query object used, using not cached statements
		 */
		private var _notCachedQuery : SQLiteQuery;
		/**
		 * Whether to exclude soft deleted rows or not in all commands
		 */
		public var excludeSoftDeleted : Boolean;
		
		
		/**
		 * Instanciate a new ORM object. DON'T CALL DIRECTLY, use ORM.factory instead
		 * 
		 * @param ormClass The class of the ORM object to create
		 * @param _dummy Used internally
		 */
		public function ORM( ormClass : Class, _dummy : Object )
		{
			excludeSoftDeleted = true;
			_data = new ormClass();
			super(_data);
			if ( _dummy !== _dummyChecker )
			{
				throw new IllegalOperationError("You MUST use the ORM.factory() method to instanciate an ORM object");
			}
			_class = ormClass;
			_descriptor = ORMDescriptor.forClass(ormClass);
			_reset();
			
			// listen to changes on the properties
			addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, _propertyChangeHandler);
		}
		
		
		/**
		 * Finds and load a row of the associated table into this model
		 * 
		 * @param id The primary key value of the row to load
		 * @return Returns true on success, else false
		 */
		public function find( id : int ) : Boolean
		{
			var res : Array, ev : ORMEvent,
				sql : String, params : Object = {},
				q : SQLiteQuery = getQuery();
			
			params[primaryKeyColumnName] = id;
			_reset();
			res = q.from(ormDescriptor.tableName).where(params).andWhere(getDeletedCondition()).get();
			if ( res.length == 0 )
			{
				return false;
			}
			loadDataFromSqlResult(res[0]);
			
			ev = new ORMEvent(ORMEvent.LOADED);
			dispatchEvent(ev);
			
			return true;
		}
		
		/**
		 * Loa the data from a SQL result into this ORM object, and prepare any related property
		 *
		 * @param result The result row object to load
		 * @param flagAsLoaded If true, the object will b flagged as loaded
		 */
		public function loadDataFromSqlResult( result : Object, flagAsLoaded : Boolean = true ) : void
		{
			var name : String;
			// copy the data from the given result row to the last loaded data
			_lastLoadedData = new Object();
			for ( name in result )
			{
				_lastLoadedData[name] = result[name];
			}
			ormDescriptor.sqlResultRowToOrmObject(result, this, _data);
			_isLoaded = flagAsLoaded;
			_isSaved = flagAsLoaded;
			_hasChanged = new Array();
		}
		
		
		/**
		 * Returns an ORMIterator prepared to iterate other all the ORM object corresponding to the filters
		 * 
		 * @param params An object containing the filters
		 * @param orderBy The optional order by settings
		 * @param limit The number of rows maximum to retreive
		 * @param offset The offset of the result row to jump to
		 * @return ORMIterator The iterator to browse results
		 * 
		 * @example
		 * <listing version="3.0">
		 * 	var user : User = ORM.factory(User);
		 * 	var iterator : ORMIterator = user.findAll({"age >": 18, "deleted": false}, {name: "desc"});
		 * 	for each ( user in iterator )
		 * 	{
		 * 		// do something with each result
		 * 	}
		 * </listing>
		 */
		public function findAll( params : Object = null, orderBy : Object = null, limit : int = -1, offset : int = 1 ) : ORMIterator
		{
			var q : SQLiteQuery = getQuery().from(ormDescriptor.tableName), value : *,
				name : String, prop : ORMPropertyDescriptor,
				nameParts : Array, op : String;
			
			q.where(getDeletedCondition());
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
				if ( value === null )
				{
					q.andWhere(prop.columnName + " IS" + (op == "!=" ? " NOT" : "") + " NULL");
				}
				else
				{
					q.andWhere(new SQLiteCondition(prop.columnName + " " + op + " ?", value));
				}
			}
			if ( orderBy )
			{
				for ( name in orderBy )
				{
					prop = ormDescriptor.propertyDescriptor(name);
					q.orderBy(prop.columnName + " " + (!orderBy[name] || String(orderBy[name]).toUpperCase() == "DESC" ? "DESC" : "ASC"));
				}
			}
			if ( limit > 0 )
			{
				q.limit(limit, offset);
			}
			return q.getAsOrmIterator(ormClass);
		}
		
		
		/**
		 * Same as the findAll method, except that the sql where, order by and group by are specified as SQL string
		 * 
		 * @param whreSql The conditions, as a string
		 * @param params The parameters to bind, if any
		 * @param orderBySql The order by, as a SQL string
		 * @param groupBySql The group by, as a SQL string
		 * @param limit The maximum of results to get
		 * @param offset The offset of the result row to jump to
		 * @result The iterator to use to browse results
		 */
		public function findAllBySql( whereSql : String, params : Object = null, orderBySql : String = null, groupBySql : String = null, limit : int = -1, offset : int = 1 ) : ORMIterator
		{
			var q : SQLiteQuery = getQuery().from(ormDescriptor.tableName);
			
			q.where(getDeletedCondition()).andWhere(new SQLiteCondition(whereSql, params || {}));
			if ( groupBySql )
			{
				q.groupBy(groupBySql);
			}
			if ( orderBySql )
			{
				q.orderBy(orderBySql);
			}
			if ( limit > 0 )
			{
				q.limit(limit, offset);
			}
			return q.getAsOrmIterator(ormClass);
		}
		
		
		/**
		 * Save the changes into the database
		 * 
		 * @return Returns true on success, flase if error
		 */
		public function save() : Boolean
		{
			var ev : ORMEvent = new ORMEvent(ORMEvent.SAVING), sql : String, res : SQLResult,
				parts : Array, params : Object = {}, name : String, stmt : SQLiteStatement,
				prop : ORMPropertyDescriptor, rel : ORMHasOneDescriptor;
			
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
				if ( ormDescriptor.updatedAtProperty )
				{
					_data[ormDescriptor.updatedAtProperty.name] = new Date();
					_hasChanged.push(ormDescriptor.updatedAtProperty.name);
				}
				// create the sql statement
				sql = "UPDATE " + ormDescriptor.tableName + " SET ";
				parts = new Array();
				for each ( name in _hasChanged )
				{
					prop = ormDescriptor.propertyDescriptor(name);
					if ( prop )
					{
						parts.push(prop.columnName + " = :" + name);
						params[name] = _data[name];
					}
					else
					{
						// it's a "has one" relation, save the id or null if no ID
						rel = ormDescriptor.getRelatedTo(name) as ORMHasOneDescriptor;
						parts.push(rel.columnName + " = :" + name);
						params[name] = _data[name] ? _data[name][rel.relatedOrmPropertyDescriptor.name] : null;
					}
				}
				sql += parts.join(", ") + " WHERE " + primaryKeyColumnName
					+ " = :" + primaryKeyPropertyName;
				params[primaryKeyPropertyName] = primaryKeyValue;
				
				// execute the sql
				stmt = connection.createStatement(PREPEND_SQL_COMMENT + sql, true);
				stmt.bind(params);
				stmt.safeExecute();
				if ( stmt.getResult().rowsAffected == 1 )
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
				if ( ormDescriptor.createdAtProperty )
				{
					_data[ormDescriptor.createdAtProperty.name] = new Date();
				}
				if ( ormDescriptor.updatedAtProperty )
				{
					_data[ormDescriptor.updatedAtProperty.name] = new Date();
				}
				_hasChanged.push(ormDescriptor.createdAtProperty.name, ormDescriptor.updatedAtProperty.name);
				
				// creates the SQL
				sql = " INSERT INTO " + ormDescriptor.tableName + "(";
				parts = new Array();
				for each ( name in _hasChanged )
				{
					prop = ormDescriptor.propertyDescriptor(name);
					if ( prop )
					{
						parts.push(prop.columnName);
						params[name] = _data[name];
					}
					else
					{
						// it's a "has one" relation, save the id or null if no ID
						rel = ormDescriptor.getRelatedTo(name) as ORMHasOneDescriptor;
						parts.push(rel.columnName);
						params[name] = _data[name] ? _data[name][rel.relatedOrmPropertyDescriptor.name] : null;
					}
				}
				sql += parts.join(", ") + ") VALUES(:" + _hasChanged.join(", :") + ")";
				
				// execute sql
				stmt = connection.createStatement(PREPEND_SQL_COMMENT + sql, true);
				stmt.bind(params);
				stmt.safeExecute();
				res = stmt.getResult();
				if ( res.rowsAffected == 1 )
				{
					_data[primaryKeyPropertyName] = res.lastInsertRowID;
					_isSaved = true;
					_hasChanged = new Array();
					ev = new ORMEvent(ORMEvent.SAVED);
					dispatchEvent(ev);
					return true;
				}
			}
			return false;
		}
		
		
		/**
		 * The last data that has been loaded to this ORM object, including
		 * unused data if any
		 */
		public function get lastLoadedData() : Object
		{
			return _lastLoadedData;
		}
		
		
		/**
		 * Get the connection object used to manipulate the table in the db
		 * 
		 * @return The connection object
		 */
		public function get connection() : SQLiteConnection
		{
			if ( !_connection )
			{
				_connection = ormDescriptor.connection;
			}
			return _connection;
		}
		
		
		/**
		 * The name of the connection to use with this object
		 */
		public function set connectionName( connectionName : String ) : void
		{
			_connection = SQLiteConnection.instance( connectionName );
		}
		
		
		/**
		 * The value of the primary key
		 */
		public function get primaryKeyValue() : int
		{
			return _data[primaryKeyPropertyName];
		}
		
		
		/**
		 * The name of the property containing the primary key value
		 */
		public function get primaryKeyPropertyName() : String
		{
			return _descriptor.primaryKeyProperty.name;
		}
		
		
		/**
		 * THe name of the primary key column
		 */
		public function get primaryKeyColumnName() : String
		{
			return _descriptor.primaryKeyProperty.columnName;
		}
		
		
		/**
		 * The qname of the class of this object
		 */
		public function get classQName() : String
		{
			if ( !_classQName )
			{
				_classQName = getQualifiedClassName(_data);
			}
			return _classQName;
		}
		
		
		/**
		 * A pointer to the class of this object
		 */
		public function get ormClass() : Class
		{
			return _class;
		}
		
		
		/**
		 * The ORM descriptor of this objet
		 */
		public function get ormDescriptor() : ORMDescriptor
		{
			return _descriptor;
		}
		
		
		/**
		 * Whether the object has been saved in the db or not
		 */
		public function get isSaved() : Boolean
		{
			return _isSaved;
		}
		
		
		/**
		 * Whether the object has been loaded from the database or not
		 */
		public function get isLoaded() : Boolean
		{
			return _isLoaded;
		}
		
		
		/**
		 * Whether the object has been changed
		 */
		public function get hasChanged() : Boolean
		{
			return (_hasChanged.length > 0);
		}
		
		
		/**
		 * Whether a record is soft deleted or not
		 */
		public function get isDeleted() : Boolean
		{
			if ( !ormDescriptor.deletedAtProperty )
			{
				throw new IllegalOperationError("You cannot test if a record is deleted if the model doesn't include a 'deletedDate' column (has to be defined in the [Table] metadata)");
			}
			return (_data[ormDescriptor.deletedAtProperty.name] != null);
		}
		
		
		/**
		 * Delete the record from the DB and reset this object or flag the record as soft
		 * deleted and save the flag in the db
		 * 
		 * @return Returns true if the record has been deleted, else false
		 */
		public function remove() : Boolean
		{
			var stmt : SQLiteStatement, res : Boolean;
			if ( ormDescriptor.deletedAtProperty )
			{
				if ( isDeleted )
				{
					throw new IllegalOperationError("The record is already flagged as deleted");
				}
				_data[ormDescriptor.deletedAtProperty.name] = new Date();
				_hasChanged.push(ormDescriptor.deletedAtProperty.name);
				return save();
			}
			if ( !primaryKeyValue )
			{
				throw new IllegalOperationError("The record has no PK value, it cannot be deleted");
			}
			stmt = connection.createStatement(PREPEND_SQL_COMMENT + "DELETE FROM " + ormDescriptor.tableName + " WHERE "
				+ primaryKeyColumnName + " = :" + primaryKeyPropertyName);
			stmt.bind(primaryKeyPropertyName, primaryKeyValue);
			res = stmt.safeExecute() && (stmt.getResult().rowsAffected == 1);
			if ( res )
			{
				_reset();
			}
			return res;
		}
		
		
		/**
		 * Handle a change on a property of this object
		 * 
		 * @param event The change event
		 */
		private function _propertyChangeHandler( event : PropertyChangeEvent ) : void
		{
			if ( event.kind != PropertyChangeEventKind.UPDATE )
			{
				throw new IllegalOperationError("You cannot " + event.kind + " a property on an ORM model");
			}
			var pName : String = event.property.toString(),
				rel : IORMRelationDescriptor,
				prop : ORMPropertyDescriptor = _descriptor.propertyDescriptor(pName);
			if ( !prop )
			{
				if ( !(rel = _descriptor.getRelatedTo(pName)) )
				{
					throw new IllegalOperationError("Trying to access a unknown property '"
						+ pName + "'. Define it first in the model if you wish to use it in your code if that is a column of the related table.");
				}
			}
			// here it's a property of the ORM that has changed
			if ( prop && prop.isReadOnly )
			{
				throw new IllegalOperationError("The property '" + prop.name + "'  of model '" + _descriptor.ormClassQName + "' is read-only");
			}
			var ev : ORMEvent = new ORMEvent(ORMEvent.PROPERTY_UPDATE, pName);
			dispatchEvent(ev);
			// if the event has been cancelled, don't do the update
			if ( ev.isDefaultPrevented() )
			{
				_data[pName] = event.oldValue;
			}
			else if ( (!rel || rel is ORMHasOneDescriptor) && _hasChanged.indexOf(pName) == -1 )
			{
				_hasChanged.push(pName);
				_isSaved = false;
				_isLoaded = false;
			}
		}
		
		
		/**
		 * Used to reset the object
		 */
		private function _reset() : void
		{
			_isLoaded = false;
			_isSaved = false;
			_lastLoadedData = null;
			_hasChanged = new Array();
			loadDataFromSqlResult({}, false);
		}
		
		
		/**
		 * Get the query object to use and reset it
		 * 
		 * @return The query object already instancied or newly created
		 */
		private function getQuery( cachedStatements : Boolean = true ) : SQLiteQuery
		{
			var res : SQLiteQuery = cachedStatements ? _query : _notCachedQuery;
			if ( !res )
			{
				res = new SQLiteQuery(connection, cachedStatements, PREPEND_SQL_COMMENT);
				if ( cachedStatements )
				{
					_query = res;;
				}
				else
				{
					_notCachedQuery = res;
				}
			}
			res.reset();
			return res;
		}
		
		
		/**
		 * Get the condition SQL string to handle soft deleted records
		 * 
		 * @param prepend The string to prepend to the condition
		 * @param append The string to append to the condition
		 * @return The condition SQL code if any else an empty string
		 */
		public function getDeletedCondition( prepend : String = null, append : String = null ) : String
		{
			var res : String;
			if ( !excludeSoftDeleted || !ormDescriptor.deletedAtProperty )
			{
				return "";
			}
			return (prepend ? prepend : "") + ormDescriptor.deletedAtProperty.columnName + " IS NULL"
				+ (append ? append : "");
		}
		
		
		/**
		 * Add the condition for the possible deleted columns if needed
		 * 
		 * @param query The query to add condition to
		 */
		public function addDeletedCondition( query : SQLiteQuery ) : void
		{
			if ( !excludeSoftDeleted || !ormDescriptor.deletedAtProperty )
			{
				return;
			}
			query.andWhere(ormDescriptor.deletedAtProperty.columnName + " IS NULL");
		}
		
		
		/**
		 * Create a new instance of the given ORM model
		 * 
		 * @param ormClass The class of the ORM instance to create
		 * @param id The unique ID, if given it'll load from the db the row with that ID
		 * @return The ORM object to be sued
		 */
		public static function factory( ormClass : Class, id : int = 0 ) : *
		{
			var orm : ORM = new ORM(ormClass, _dummyChecker);
			if ( id > 0 )
			{
				orm.find(id);
			}
			return orm;
		}
	}
}