/*============================================================================*/
/*                                                                            */
/*    Huafu Gandon, hereby disclaims all copyright interest in the            */
/*    library “Huafu Library” (which makes passes at compilers)               */
/*    written by Huafu Gandon.                                                */
/*                                                                            */
/*    Huafu Gandon <huafu.gandon@gmail.com>, 15 August 2012                   */
/*                                                                            */
/*                                                                            */
/*    This file is part of Huafu Library.                                     */
/*                                                                            */
/*    Huafu Library is free software: you can redistribute it and/or modify   */
/*    it under the terms of the GNU General Public License as published by    */
/*    the Free Software Foundation, either version 3 of the License, or       */
/*    (at your option) any later version.                                     */
/*                                                                            */
/*    Huafu Library is distributed in the hope that it will be useful,        */
/*    but WITHOUT ANY WARRANTY; without even the implied warranty of          */
/*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           */
/*    GNU General Public License for more details.                            */
/*                                                                            */
/*    You should have received a copy of the GNU General Public License       */
/*    along with Huafu Library.  If not, see <http://www.gnu.org/licenses/>.  */
/*                                                                            */
/*============================================================================*/


package com.huafu.sql.orm
{
	import com.huafu.common.Huafu;
	import com.huafu.sql.SQLiteConnection;
	import com.huafu.sql.SQLiteStatement;
	import com.huafu.sql.orm.relation.IORMRelation;
	import com.huafu.sql.orm.relation.ORMRelation;
	import com.huafu.sql.query.SQLiteParameters;
	import com.huafu.utils.HashMap;
	import com.huafu.utils.StringUtil;
	import com.huafu.utils.reflection.ReflectionClass;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;
	import flash.data.SQLColumnSchema;
	import flash.data.SQLTableSchema;
	import flash.errors.IllegalOperationError;
	import flash.utils.getDefinitionByName;
	import mx.logging.ILogger;
	import avmplus.getQualifiedClassName;


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


		/**
		 * An array containing all known ORM descriptors
		 */
		public static function get allKnownOrmDescriptors() : Array
		{
			return _allByClassQName.toArray();
		}


		/**
		 * An array of all ORM class qnames already known
		 */
		public static function get allModelClassQNamesKnown() : Array
		{
			return _allByClassQName.keys();
		}


		/**
		 * Get a ORM descriptor describing the given ORM class, creating it if necessary
		 *
		 * @param ormClass The ORM class we want the descriptor of
		 * @return The desired ORM descriptor
		 */
		public static function forClass(ormClass : Class) : ORMDescriptor
		{
			var classQName : String = getQualifiedClassName(ormClass), desc : ORMDescriptor = _allByClassQName.
					get(classQName);
			if (!desc)
			{
				desc = new ORMDescriptor(ormClass);
			}
			return desc;
		}


		/**
		 * Get the appropriate descriptor for a given ORM object, creating it if necessary
		 *
		 * @param ormObject The ORM object we want the descriptor of
		 * @return The desired descriptor
		 */
		public static function forObject(ormObject : ORM) : ORMDescriptor
		{
			var descriptor : ORMDescriptor = _allByClassQName.get(ormObject.ormClassQName);
			if (!descriptor)
			{
				descriptor = new ORMDescriptor(ormObject.ormClass);
			}
			return descriptor;
		}


		/**
		 * Resolve a model name to the class object corresponding
		 *
		 * @param className The name of the model's class
		 * @param fromOrm The ORM descriptor from which trying to resolve from
		 * @return The pointer to the ORM class
		 */
		public static function resolveOrmClass(className : String, fromOrm : ORMDescriptor) : Class
		{
			var fullCN : String = ORMDescriptor.ormModelsPackageFullName + "::" + className, ormClass : Class;
			try
			{
				ormClass = getDefinitionByName(fullCN) as Class;
			}
			catch (err : ReferenceError)
			{
				if (err.errorID == 1065)
				{
					err.message = err.message + " This is usually thrown because as3 cannot find your related ORM model's class. Try adding the line '"
							+ className + ";' in the constructor of '" + getQualifiedClassName(fromOrm.
							ormClass)
							+ "', it should solve the problem.";
				}
				throw err;
			}
			return ormClass;
		}


		/**
		 * Constructor
		 *
		 * @param ormClass A pointer to the ORM class that this object will describe
		 */
		public function ORMDescriptor(ormClass : Class)
		{
			var reflection : ReflectionClass = ReflectionClass.forClass(ormClass), meta : ReflectionMetadata,
					prop : ReflectionProperty, ormProp : ORMPropertyDescriptor, pk : String = "id", upd : String
					= "updatedAt", cre : String = "createdAt", del : String = "deletedAt", relatedToProps : Array
					= new Array(), rel : IORMRelation;

			// basic stuff
			_ormClass = ormClass;
			_ormClassQName = reflection.classQName;
			_ormClassName = reflection.className;
			_relatedTo = new HashMap();

			// testing if the descriptor is already in the register
			if (_allByClassQName.exists(ormClassQName))
			{
				throw new IllegalOperationError("You have to call ORMDescription.forClass() method and not directly the constructor of ORMDescriptor");
			}

			// table and database
			meta = reflection.uniqueMetadata("Table");
			_tableName = meta.argValue("name") ? meta.argValueString("name") : StringUtil.unCamelize(reflection.
					className);
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
			for each (prop in reflection.properties(true, false))
			{
				if (prop.hasMetadata("HasOne") || prop.hasMetadata("HasMany") || prop.hasMetadata("BelongsTo"))
				{
					// handle relations
					relatedToProps.push(prop);
					continue;
				}
				else if (!prop.hasMetadata("Column"))
				{
					continue;
				}

				ormProp = ORMPropertyDescriptor.fromReflectionProperty(this, prop);
				_propertiesByColumnName.set(ormProp.columnName, ormProp);
				_propertiesByName.set(ormProp.name, ormProp);
				if (pk == ormProp.name)
				{
					ormProp.isReadOnly = true;
					_primaryKeyProperty = ormProp;
				}
				else if (cre == ormProp.name)
				{
					ormProp.isReadOnly = true;
					_createdAtProperty = ormProp;
				}
				else if (upd == ormProp.name)
				{
					ormProp.isReadOnly = true;
					_updatedAtProperty = ormProp;
				}
				else if (del == ormProp.name)
				{
					ormProp.isReadOnly = true;
					_deletedAtProperty = ormProp;
				}
			}

			// before setting up the related objects, we need to register this class
			_allByClassQName.set(ormClassQName, this);

			_relationsPerColumn = {};
			for each (prop in relatedToProps)
			{
				rel = ORMRelation.fromReflectionProperty(this, prop);
				if (!_relationsPerColumn[rel.localColumnName])
				{
					_relationsPerColumn[rel.localColumnName] = new Vector.<IORMRelation>();
				}
				_relationsPerColumn[rel.localColumnName].push(rel);
				_relatedTo.set(prop.name, rel);
			}

			logger.debug("Created a new ORM descriptor for table '" + tableName + "' represented by ORM class '"
					+ ormClassQName + "'");

			// update the DB schema if necessary
			updateSchema();
		}


		/**
		 * Stores all column names that are in the table
		 */
		private var _allColumnNames : Array;


		/**
		 * The SQL connection used for the related table
		 */
		private var _connection : SQLiteConnection;


		/**
		 * The name of the SQL connection used for the related table
		 */
		private var _connectionName : String;


		/**
		 * A pointer to the createdAt property of the ORM if any
		 */
		private var _createdAtProperty : ORMPropertyDescriptor;


		/**
		 * The name of the database where the table is
		 */
		private var _databaseName : String;


		/**
		 * A pointer to the deletedAt property of the ORM if any
		 */
		private var _deletedAtProperty : ORMPropertyDescriptor;


		/**
		 * A global instance needed for relations and other stuffs
		 */
		private var _globalOrmInstance : ORM;


		/**
		 * The logger
		 */
		private var _logger : ILogger;


		// basic stuff
		/**
		 * Pointer to the ORM class that describes this object
		 */
		private var _ormClass : Class;


		/**
		 * Stores the name of the class withut package info
		 */
		private var _ormClassName : String;


		/**
		 * The qname of the ORM class taht describes this object
		 */
		private var _ormClassQName : String;


		// special columns
		/**
		 * A pointer to the primary key property
		 */
		private var _primaryKeyProperty : ORMPropertyDescriptor;


		/**
		 * All properties of the ORM indexed by their column name
		 */
		private var _propertiesByColumnName : HashMap;


		// properties indexed
		/**
		 * All properties of the ORM indexed by their name
		 */
		private var _propertiesByName : HashMap;


		// relations
		/**
		 * Stores all relations (has one, has many, belongs to) indexed by property names
		 */
		private var _relatedTo : HashMap;


		/**
		 * All relations per column name
		 */
		private var _relationsPerColumn : Object;


		/**
		 * Names of the properties which are magic properties depending on a relation
		 */
		private var _relationsPropertyNames : Array;


		/**
		 * The name of the table in the database
		 */
		private var _tableName : String;


		/**
		 * A pointer to the updatedAt property of the ORM if any
		 */
		private var _updatedAtProperty : ORMPropertyDescriptor;


		/**
		 * All column names in an array
		 */
		public function get allColumnNames() : Array
		{
			return _allColumnNames;
		}


		/**
		 * Gets the default value of a column
		 *
		 * @param columnName The name of the column to get the default value of
		 * @return The default value for this column
		 */
		public function columnDefaultValue(columnName : String) : *
		{
			var prop : ORMPropertyDescriptor = propertyDescriptorByColumnName(columnName);
			if (prop)
			{
				return prop.defaultValue();
			}
			// TODO: when loading the descriptor, get the default value of undefined columns
			// somewhere and return it here
			return null;
		}


		/**
		 * Get the connection object used to manipulate the table in the db
		 *
		 * @return The connection object
		 */
		public function get connection() : SQLiteConnection
		{
			if (!_connection)
			{
				_connection = SQLiteConnection.instance(_connectionName);
			}
			return _connection;
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
		 * Get the ORM relation descriptor that the given property name is holding
		 *
		 * @param propertyName The name of the property holding a relaiton
		 * @return The ORM relation descriptor
		 */
		public function getRelatedTo(propertyName : String) : IORMRelation
		{
			return _relatedTo.get(propertyName) as IORMRelation;
		}


		/**
		 * Get the relation object that correspond to the link with a given ORM
		 *
		 * @param toWhat The ORM descriptor we want the relation object of
		 * @param relationClass If specified, it'll look for a relation having strictly the given class
		 * @return Returns the desired relation or null if no such defined
		 */
		public function getRelationTo(toWhat : ORMDescriptor, toWhatColumnName : String = null, relationClass : Class
				= null) : IORMRelation
		{
			var rel : IORMRelation;
			for each (rel in _relatedTo)
			{
				if (rel.foreignDescriptor === toWhat && (!relationClass || ReflectionClass.isStrictly(rel,
						relationClass))
						&& (!toWhatColumnName || toWhatColumnName == rel.foreignColumnName))
				{
					return rel;
				}
			}
			return null;
		}


		/**
		 * Get all the relation descriptors that are based on a local column which name is given
		 *
		 * @param localColumnName The name of the local column
		 * @return The vector containing all relation descriptors for this column
		 */
		public function getRelationsBasedOnColumn(localColumnName : String) : Vector.<IORMRelation>
		{
			var res : Vector.<IORMRelation>;
			if (_relationsPerColumn.hasOwnProperty(localColumnName))
			{
				res = _relationsPerColumn[localColumnName];
			}
			else
			{
				res = new Vector.<IORMRelation>();
			}
			return res;
		}


		/**
		 * Get the SQL creation code of the table related to this model
		 *
		 * @param parametersDestination Used to bind the possible default values of the columns
		 * @return The SQL code to create the table
		 */
		public function getSqlCreationCode(parametersDestination : SQLiteParameters = null) : String
		{
			var cols : Array = new Array(), prop : ORMPropertyDescriptor, rel : IORMRelation, res : String
					= "CREATE TABLE \"" + tableName + "\"(", sql : String;
			if (!primaryKeyProperty)
			{
				throw new IllegalOperationError("You must define a primary key column to the table '"
						+ tableName + "' (model '" + ormClassQName + "')");
			}
			cols.push(primaryKeyProperty.getSqlCode(parametersDestination));
			for each (prop in _propertiesByName)
			{
				if (prop.isPrimaryKey)
				{
					continue;
				}
				cols.push(prop.getSqlCode(parametersDestination));
			}
			for each (rel in _relatedTo)
			{
				if (!_propertiesByColumnName.exists(rel.localColumnName) && (sql = rel.getLocalColumnSqlCode(parametersDestination)))
				{
					cols.push(sql);
				}
			}
			res += cols.join(", ") + ")";
			return res;
		}


		/**
		 * A global instance needed for relations and other stuffs
		 */
		public function get globalOrmInstance() : ORM
		{
			if (!_globalOrmInstance)
			{
				_globalOrmInstance = new _ormClass();
			}
			return _globalOrmInstance;
		}


		/**
		 * A pointer to the ORM class that this descriptor describes
		 */
		public function get ormClass() : Class
		{
			return _ormClass;
		}


		/**
		 * The name of the class only, without the package information
		 */
		public function get ormClassName() : String
		{
			return _ormClassName;
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
		public function propertyDescriptor(name : String) : ORMPropertyDescriptor
		{
			return _propertiesByName.get(name) as ORMPropertyDescriptor;
		}


		/**
		 * Get the descriptor of a property looking at its column name
		 *
		 * @param name The name of the column corresponding to the property we want the decriptor of
		 * @return The descriptor of the proerty
		 */
		public function propertyDescriptorByColumnName(name : String) : ORMPropertyDescriptor
		{
			return _propertiesByColumnName.get(name) as ORMPropertyDescriptor;
		}


		/**
		 * Get all properties defined in an array
		 *
		 * @return All properties in an array
		 */
		public function get propertyDescriptors() : Array
		{
			return _propertiesByName.toArray();
		}


		/**
		 * Get all relations defined in an array
		 *
		 * @return All relations in an array
		 */
		public function get relationDescriptors() : Array
		{
			return _relatedTo.toArray();
		}


		/**
		 * The names of the properties that are in fact foreign objects
		 */
		public function get relationsPropertyNames() : Array
		{
			if (!_relationsPropertyNames)
			{
				_relationsPropertyNames = _relatedTo.keys();
			}
			return _relationsPropertyNames;
		}


		/**
		 * Load the data from a sql result to an ORM object that this object describe and also
		 * prepare/load any property corresponding to a realtion
		 *
		 * @param result The row as an object to load in the ORM object
		 * @param object The ORM object to load results in
		 * @param dataObject The data object of the ORM object
		 */
		public function sqlResultRowToOrmObject(result : Object, object : ORM, dataObject : Object) : void
		{
			var prop : ORMPropertyDescriptor, relation : IORMRelation;
			// load normal properties
			for each (prop in _propertiesByName)
			{
				if (result && result.hasOwnProperty(prop.columnName))
				{
					dataObject[prop.name] = result[prop.columnName];
				}
				else
				{
					dataObject[prop.name] = result ? undefined : prop.defaultValue();
				}
			}
			// prepare for relation properties
			for each (relation in _relatedTo)
			{
				//relation.setupOrmObject(object, dataObject, result);
				dataObject[relation.ownerPropertyName] = null;
			}
		}


		/**
		 * The name of the table corresponding to this descriptor in the database
		 */
		public function get tableName() : String
		{
			return _tableName;
		}


		/**
		 * Update the database to reflect the descriptor if necessary
		 */
		public function updateSchema() : void
		{
			var stmt : SQLiteStatement, schema : SQLTableSchema, params : SQLiteParameters, col : SQLColumnSchema;
			if ((schema = connection.getTableSchema(tableName)))
			{
				// the table exists, check if the schema is the same
				//TODO: check the table's columns and alter if needed
				//enterDebugger();
			}
			else
			{
				// the table doesn't exist, let's create it
				params = new SQLiteParameters();
				stmt = connection.createStatement(getSqlCreationCode(params), true);
				params.softBindTo(stmt);
				stmt.safeExecute();
				schema = connection.getTableSchema(tableName);
			}

			// grab the name of all columns
			_allColumnNames = new Array();
			for each (col in schema.columns)
			{
				_allColumnNames.push(col.name);
			}
		}


		/**
		 * The updatedAt property if any
		 */
		public function get updatedAtProperty() : ORMPropertyDescriptor
		{
			return _updatedAtProperty;
		}


		/**
		 * The logger for this class
		 */
		private function get logger() : ILogger
		{
			if (!_logger)
			{
				_logger = Huafu.getLoggerFor(ORMDescriptor);
			}
			return _logger;
		}
	}
}
