package com.huafu.sql.orm
{
	import avmplus.getQualifiedClassName;
	
	import com.huafu.sql.SQLiteConnection;
	import com.huafu.sql.SQLiteStatement;
	import com.huafu.utils.HashMap;
	import com.huafu.utils.StringUtil;
	import com.huafu.utils.reflection.ReflectionClass;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;
	
	import flash.data.SQLResult;
	import flash.data.SQLTableSchema;
	import flash.errors.IllegalOperationError;
	import flash.errors.SQLError;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayList;

	/**
	 * Class used to describe a model
	 */
	public class ORMDescriptor
	{
		/**
		 * The qname of the package where reside all your models
		 */
		public static var ormModelsPackageFullName : String = "models";
		
		/**
		 * Stores all ORM descriptor indexed by their class qname
		 */
		private static var _allByClassQName : HashMap = new HashMap();
		
		// basic stuff
		/**
		 * Pointer to the ORM class that describes this object
		 */
		private var _ormClass : Class;
		/**
		 * The qname of the ORM class taht describes this object
		 */
		private var _ormClassQName : String;
		/**
		 * The name of the table in the database
		 */
		private var _tableName : String;
		/**
		 * The name of the database where the table is
		 */
		private var _databaseName : String;
		/**
		 * The SQL connection used for the related table
		 */
		private var _connection : SQLiteConnection;
		/**
		 * The name of the SQL connection used for the related table
		 */
		private var _connectionName : String;
				
		// properties indexed
		/**
		 * All properties of the ORM indexed by their name
		 */
		private var _propertiesByName : HashMap;
		/**
		 * All properties of the ORM indexed by their column name
		 */
		private var _propertiesByColumnName : HashMap;
		
		// special columns
		/**
		 * A pointer to the primary key property
		 */
		private var _primaryKeyProperty : ORMPropertyDescriptor;
		/**
		 * A pointer to the createdAt property of the ORM if any
		 */
		private var _createdAtProperty : ORMPropertyDescriptor;
		/**
		 * A pointer to the updatedAt property of the ORM if any
		 */
		private var _updatedAtProperty : ORMPropertyDescriptor;
		/**
		 * A pointer to the deletedAt property of the ORM if any
		 */
		private var _deletedAtProperty : ORMPropertyDescriptor;
		
		// relations
		/**
		 * Stores all relations (has one, has many, belongs to) indexed by property names
		 */
		private var _relatedTo : HashMap;
		
		
		/**
		 * Constructor
		 * 
		 * @param ormClass A pointer to the ORM class that this object will describe
		 */
		public function ORMDescriptor( ormClass : Class )
		{
			var reflection : ReflectionClass = ReflectionClass.forClass(ormClass),
				meta : ReflectionMetadata, prop : ReflectionProperty,
				ormProp : ORMPropertyDescriptor,
				pk : String = "id", upd : String = "updatedAt", cre : String = "createdAt",
				del : String = "deletedAt", relatedToProps : Array = new Array();
			
			// basic stuff
			_ormClassQName = getQualifiedClassName(ormClass);
			_ormClass = ormClass;
			_relatedTo = new HashMap();
			
			// testing if the descriptor is already in the register
			if ( _allByClassQName.exists(ormClassQName) )
			{
				throw new IllegalOperationError("You have to call ORMDescription.forClass() method and not directly the constructor of ORMDescriptor");
			}
			
			// table and database
			meta = reflection.uniqueMetadata("Table");
			_tableName = meta.argValue("name") ? meta.argValueString("name") : StringUtil.unCamelize(reflection.className);
			_databaseName = meta.argValue("database") ? meta.argValueString("database") : ORM.defaultDatabaseName;
			_connectionName = meta.argValueString("connection", null);
			
			// special columns
			pk = meta.argValueString("primaryKey", pk);
			upd = meta.argValueString("updatedDate", upd);
			cre = meta.argValueString("createdDate", cre);
			del = meta.argValueString("deletedDate", del);
			
			// properties
			_propertiesByName = new HashMap();
			_propertiesByColumnName = new HashMap();
			for each ( prop in reflection.properties(true, false) )
			{
				if ( prop.hasMetadata("HasOne") || prop.hasMetadata("HasMany") || prop.hasMetadata("BelongsTo") )
				{
					// handle relations
					relatedToProps.push(prop);
					continue;
				}
				else if ( !prop.hasMetadata("Column") )
				{
					continue;
				}
				
				ormProp = ORMPropertyDescriptor.fromReflectionProperty(this, prop);
				_propertiesByColumnName.set(ormProp.columnName, ormProp);
				_propertiesByName.set(ormProp.name, ormProp);
				if ( pk == ormProp.name )
				{
					ormProp.isReadOnly = true;
					_primaryKeyProperty = ormProp;
				}
				else if ( cre == ormProp.name )
				{
					ormProp.isReadOnly = true;
					_createdAtProperty = ormProp;
				}
				else if ( upd == ormProp.name )
				{
					ormProp.isReadOnly = true;
					_updatedAtProperty = ormProp;
				}
				else if ( del == ormProp.name )
				{
					ormProp.isReadOnly = true;
					_deletedAtProperty = ormProp;
				}
			}
			
			// before setting up the related objects, we need to register this class
			_allByClassQName.set(ormClassQName, this);
			
			for each ( prop in relatedToProps )
			{
				_relatedTo.set(prop.name, ORMRelationDescriptorBase.fromReflectionProperty(this, prop));
			}
			
			// update the DB schema if necessary
			updateDatabase();
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
				_connection = SQLiteConnection.instance(_connectionName);
			}
			return _connection;
		}
		
		
		/**
		 * Update the database to reflect the descriptor if necessary
		 */
		public function updateDatabase() : void
		{
			var stmt : SQLiteStatement, schema : SQLTableSchema;
			if ( (schema = connection.getTableSchema(tableName)) )
			{
				// the table exists, check if the schema is the same
				//TODO: check th table's columns and alter if needed
			}
			else
			{
				// the table doesn't exist, let's create it
				stmt = connection.createStatement(sqlCreationCode, true);
				stmt.safeExecute();
			}
		}
		
		
		/**
		 * Get the ORM relation descriptor that the given property name is holding
		 * 
		 * @param propertyName The name of the property holding a relaiton
		 * @return The ORM relation descriptor
		 */
		public function getRelatedTo( propertyName : String ) : IORMRelationDescriptor
		{
			return _relatedTo.get(propertyName) as IORMRelationDescriptor;
		}
		
		
		/**
		 * The updatedAt property if any
		 */
		public function get updatedAtProperty() : ORMPropertyDescriptor
		{
			return _updatedAtProperty;
		}
		
		
		/**
		 * The createdAt property if any
		 */
		public function get createdAtProperty() : ORMPropertyDescriptor
		{
			return _createdAtProperty;
		}
		
		
		/**
		 * The deletedAt property if any
		 */
		public function get deletedAtProperty() : ORMPropertyDescriptor
		{
			return _deletedAtProperty;
		}
		
		
		/**
		 * Load the data from a sql result to an ORM object that this object describe and also
		 * prepare/load any property corresponding to a realtion
		 * 
		 * @param result The row as an object to load in the ORM object
		 * @param object The ORM object to load results in
		 */
		public function sqlResultRowToOrmObject( result : Object, object : ORM ) : void
		{
			var prop : ORMPropertyDescriptor, relation : IORMRelationDescriptor;
			// load normal properties
			for each ( prop in _propertiesByName )
			{
				if ( result.hasOwnProperty(prop.columnName) )
				{
					object[prop.name] = result[prop.columnName];
				}
				else
				{
					object[prop.name] = undefined;
				}
			}
			// prepare for relation properties
			for each ( relation in _relatedTo )
			{
				relation.setupOrmObject(object, result);
			}
		}
		
		
		/**
		 * The qname of the ORM class that describes this object
		 */
		public function get ormClassQName() : String
		{
			return _ormClassQName;
		}
		
		
		/**
		 * A pointer to the primary key property
		 */
		public function get primaryKeyProperty() : ORMPropertyDescriptor
		{
			return _primaryKeyProperty;
		}
		
		
		/**
		 * Get the descriptor of a property looking at its name
		 * 
		 * @param name The name of the property we want the descriptor of
		 * @return The appropriate property descriptor
		 */
		public function propertyDescriptor( name : String ) : ORMPropertyDescriptor
		{
			return _propertiesByName.get(name) as ORMPropertyDescriptor;
		}
		
		
		/**
		 * Get the descriptor of a property looking at its column name
		 * 
		 * @param name The name of the column corresponding to the property we want the decriptor of
		 * @return The descriptor of the proerty
		 */
		public function propertyDescriptorByColumnName( name : String ) : ORMPropertyDescriptor
		{
			return _propertiesByColumnName.get(name) as ORMPropertyDescriptor;
		}
		
		
		/**
		 * The name of the table corresponding to this descriptor in the database
		 */
		public function get tableName() : String
		{
			return _tableName;
		}
		
		
		/**
		 * A pointer to the ORM class that this descriptor describes
		 */
		public function get ormClass() : Class
		{
			return _ormClass;
		}
		
		
		/**
		 * The SQL creation code of the table related to this model
		 */
		public function get sqlCreationCode() : String
		{
			var cols : Array = new Array(),
				prop : ORMPropertyDescriptor,
				rel : IORMRelationDescriptor,
				res : String = "CREATE TABLE \"" + tableName + "\"(";
			if ( !primaryKeyProperty )
			{
				throw new IllegalOperationError("You must define a primary key column to the table '" + tableName + "' (model '" + ormClassQName + "')");
			}
			cols.push(primaryKeyProperty.sqlCode);
			for each ( prop in _propertiesByName )
			{
				if ( prop.isPrimaryKey )
				{
					continue;
				}
				cols.push(prop.sqlCode);
			}
			for each ( rel in _relatedTo )
			{
				if ( !_propertiesByColumnName.exists(rel.columnName) && rel.columnSqlCode )
				{
					cols.push(rel.columnSqlCode);
				}
			}
			res += cols.join(", ") + ")";
			return res;
		}
		
		
		/**
		 * Get the appropriate descriptor for a given ORM object, creating it if necessary
		 * 
		 * @param ormObject The ORM object we want the descriptor of
		 * @return The desired descriptor
		 */
		public static function forObject( ormObject : ORM ) : ORMDescriptor
		{
			var descriptor : ORMDescriptor = _allByClassQName.get(ormObject.classQName);
			if ( !descriptor )
			{
				descriptor = new ORMDescriptor(ormObject.classRef);
			}
			return descriptor;
		}
		
		
		/**
		 * Get a ORM descriptor describing the given ORM class, creating it if necessary
		 * 
		 * @param ormClass The ORM class we want the descriptor of
		 * @return The desired ORM descriptor
		 */
		public static function forClass( ormClass : Class ) : ORMDescriptor
		{
			var classQName : String = getQualifiedClassName(ormClass),
				desc : ORMDescriptor = _allByClassQName.get(classQName);
			if ( !desc )
			{
				desc = new ORMDescriptor(ormClass);
			}
			return desc;
		}
		
		
		/**
		 * An array of all ORM class qnames already known
		 */
		public static function get allModelClassQNamesKnown() : Array
		{
			return _allByClassQName.keys();
		}
		
		
		/**
		 * An array containing all known ORM descriptors
		 */
		public static function get allKnownOrmDescriptors() : Array
		{
			return _allByClassQName.toArray();
		}
	}
}