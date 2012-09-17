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
	import com.huafu.sql.SQLiteConnection;
	import com.huafu.sql.orm.iterator.IORMIterator;
	import com.huafu.sql.orm.iterator.ORMIterator;
	import com.huafu.sql.orm.relation.IORMRelation;
	import com.huafu.sql.query.SQLiteCondition;
	import com.huafu.sql.query.SQLiteQuery;
	import flash.data.SQLResult;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import flash.utils.getDefinitionByName;
	import mx.events.PropertyChangeEvent;
	import mx.utils.ObjectProxy;
	import avmplus.getQualifiedClassName;


	/**
	 * The base of any ORM
	 *
	 * @author Huafu Gandon <huafu.gandon@gmail.com>
	 * @since 1.0
	 */
	[Bindable]
	[Event(name = "deleted", type = "com.huafu.sql.orm.ORMEvent")]
	[Event(name = "deleting", type = "com.huafu.sql.orm.ORMEvent")]
	[Event(name = "loaded", type = "com.huafu.sql.orm.ORMEvent")]
	[Event(name = "saved", type = "com.huafu.sql.orm.ORMEvent")]
	[Event(name = "saving", type = "com.huafu.sql.orm.ORMEvent")]
	public class ORM extends Proxy implements IEventDispatcher
	{

		/**
		 * The default database name
		 */
		public static var defaultDatabaseName : String = "main";


		/**
		 * String used to prepend in a comment any query executed throw the ORM interface
		 */
		private static const PREPEND_SQL_COMMENT : String = "HORM";


		public function ORM(id : int = 0)
		{
			super();
			_eventDispatcher = new EventDispatcher(this);
			_descriptor = ORMDescriptor.forObject(this);
			_columnValues = {};
			_foreignObjects = {};
			_columnNames = _descriptor.allColumnNames;
			_foreignObjectsPropertyNames = _descriptor.relationsPropertyNames;
			_columnValuesProxy = new ObjectProxy(_columnValues);
			_foreignObjectsProxy = new ObjectProxy(_foreignObjects);
			
			reset();

			_columnValuesProxy.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, _handleColumnValueChange);
			_foreignObjectsProxy.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, _handleForeignObjectChange);

			if (id)
			{
				load(id);
			}
		}


		public var excludeSoftDeletedRecords : Boolean;


		private var _changedColumnNames : Array;


		private var _columnNames : Array;


		private var _columnValues : Object;


		private var _columnValuesProxy : ObjectProxy;


		private var _connection : SQLiteConnection;


		private var _descriptor : ORMDescriptor;


		private var _eventDispatcher : EventDispatcher;


		private var _foreignObjects : Object;


		private var _foreignObjectsPropertyNames : Array;


		private var _foreignObjectsProxy : ObjectProxy;


		private var _isDeleted : Boolean;


		private var _isLoaded : Boolean;


		private var _isSaved : Boolean;


		private var _notCachedQuery : SQLiteQuery;


		private var _ormClass : Class;


		private var _ormClassQName : String;


		private var _query : SQLiteQuery;


		/**
		 * @copy IEventDispatcher#addEventListener()
		 */
		public function addEventListener(type : String, listener : Function, useCapture : Boolean = false,
				priority : int = 0, useWeakReference : Boolean = false) : void
		{
			_eventDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}


		/**
		 * The connection object used to manipulate the table in the db
		 */
		public function get connection() : SQLiteConnection
		{
			if (!_connection)
			{
				_connection = _descriptor.connection;
			}
			return _connection;
		}


		public function set connection(value : SQLiteConnection) : void
		{
			_connection = value;
		}


		/**
		 * @copy IEventDispatcher#dispatchEvent()
		 */
		public function dispatchEvent(event : Event) : Boolean
		{
			return _eventDispatcher.dispatchEvent(event);
		}


		/**
		 * Find a record looking at given parameters
		 *
		 * @param parameters The paremeters, as they would be given in the where method of a SQLiteQuery
		 * @return Return true on success, lese false
		 * @see SQLiteQuery#where()
		 */
		public function find(... parameters : Array) : Boolean
		{
			var q : SQLiteQuery = getQuery(), res : Object;
			res = q.where(parameters).getOne();
			if (res)
			{
				loadWithResult(res);
				return true;
			}
			reset(false);
			return false;
		}


		/**
		 * Return an ierator over the objects corresponding to the given paremeters
		 *
		 * @param parameters The parameters to use in the where clause
		 * @param orderBy The order by fields if any
		 * @param limit The limit or -1 if not used
		 * @param offset The offset or -1 if not used
		 * @param iteratorClass The class of the iterator, if null, the base iterator class will be used
		 */
		public function findAll(parameters : Object = null, orderBy : Object = null, limit : int = -1,
				offset : int = -1, iteratorClass : Class = null) : IORMIterator
		{
			var q : SQLiteQuery = getQuery(), res : Array, itClass : Class = iteratorClass ? iteratorClass
					: ORMIterator;
			res = q.where(parameters).orderBy(orderBy).limit(limit, offset).get();
			return new iteratorClass(_descriptor.ormClass, res);
		}


		/**
		 * Get the value of a column looking at the name of this column like in the DB
		 *
		 * @param columnName The name of the column
		 * @return The value of that column
		 */
		public function getColumnValue(columnName : String) : *
		{
			return _columnValues[columnName];
		}


		/**
		 * Getthe soft deleted records condition looking at the exclude flag
		 *
		 * @param tableAlias The alias of the table if any
		 * @return The string of the sql condition
		 */
		public function getDeletedCondition(tableAlias : String = null) : String
		{
			var p : ORMPropertyDescriptor;
			if (excludeSoftDeletedRecords && (p = _descriptor.deletedAtProperty))
			{
				return (tableAlias ? tableAlias + "." : "") + p.columnName + " IS NULL";
			}
			return null;
		}


		/**
		 * Get a prepared select query for the related table of this ORM object
		 *
		 * @param tableAlias The alias of the table if any needed
		 * @param addSoftRecordsConddition If true, will add the soft deleted records condition
		 * @return The query object already instancied or newly created
		 */
		public function getPreparedSelectQuery(tableAlias : String = null, addSoftRecordsConddition : Boolean
				= true) : SQLiteQuery
		{
			var res : SQLiteQuery = getQuery(true, addSoftRecordsConddition);
			res.from(_descriptor.tableName + (tableAlias ? " AS " + tableAlias : ""));
			return res;
		}


		/**
		 * Get the query object to use and reset it
		 *
		 * @param cachedStatements If true, will use a query with cached statements, else non cached statements
		 * @param addSoftRecordsConddition If true, will add the soft deleted records condition
		 * @return The query object already instancied or newly created
		 */
		public function getQuery(cachedStatements : Boolean = true, addSoftRecordsConddition : Boolean
				= true) : SQLiteQuery
		{
			var res : SQLiteQuery = cachedStatements ? _query : _notCachedQuery;
			if (!res)
			{
				res = new SQLiteQuery(connection, cachedStatements, PREPEND_SQL_COMMENT);
				if (cachedStatements)
				{
					_query = res;
				}
				else
				{
					_notCachedQuery = res;
				}
			}
			res.reset();
			if (addSoftRecordsConddition)
			{
				res.where(getDeletedCondition());
			}
			return res;
		}


		/**
		 * Whether the record has changed or not since its load/creation
		 */
		public function get hasChanged() : Boolean
		{
			return (_changedColumnNames.length > 0);
		}


		/**
		 * @copy IEventDispatcher#hasEventListener()
		 */
		public function hasEventListener(type : String) : Boolean
		{
			return _eventDispatcher.hasEventListener(type);
		}


		/**
		 * Whether the record has been deleted sucessfuly (softly or hardly)
		 */
		public function get isDeleted() : Boolean
		{
			return _isDeleted || (excludeSoftDeletedRecords && _descriptor.deletedAtProperty && _columnValues[_descriptor.
					deletedAtProperty.columnName]);
		}


		/**
		 * Whether the record is hard delted or not
		 */
		public function get isHardDeleted() : Boolean
		{
			return _isDeleted;
		}


		/**
		 * Whether the record has been succesfully loaded from the database
		 */
		public function get isLoaded() : Boolean
		{
			return _isLoaded;
		}


		/**
		 * Finds whether the given object is pointing to the same record as the one represented by this object
		 *
		 * @param otherObject The other ORM object to compare with
		 * @return Returns true if both objects are pointing to the same record, else false
		 */
		public function isSameAs(otherObject : ORM) : Boolean
		{
			return (primaryKeyValue && primaryKeyValue == otherObject.primaryKeyValue);
		}


		/**
		 * Whether the record has been saved
		 */
		public function get isSaved() : Boolean
		{
			return _isSaved;
		}


		/**
		 * Whether the record is soft deleted or not
		 */
		public function get isSoftDeleted() : Boolean
		{
			return (_descriptor.deletedAtProperty && _columnValues[_descriptor.deletedAtProperty.columnName]);
		}


		/**
		 * Load a record using its ID
		 *
		 * @param id The record PK value
		 * @return Returns true on success, else false
		 */
		public function load(id : int) : Boolean
		{
			return this.find(new SQLiteCondition(_descriptor.primaryKeyProperty.columnName + " = ?",
					id));
		}


		/**
		 * Load data comming from the database into this object
		 *
		 * @param resultObject The result object to load into this ORM object
		 * @param flagAsLoaded If true, the object will be flagged as loaded (and so saved too), else all columns
		 * present into the given result object will be marked as changed
		 * @return An object will all properties from given resultObject which have not been used
		 */
		public function loadWithResult(resultObject : Object, flagAsLoaded : Boolean = true) : Object
		{
			var name : String, res : Object = {};
			reset(false);
			for each (name in resultObject)
			{
				if (_columnNames.indexOf(name) == -1)
				{
					res[name] = resultObject[name];
				}
				else
				{
					_columnValuesProxy[name] = resultObject[name];
					if (!flagAsLoaded)
					{
						_changedColumnNames.push(name);
					}
				}
			}
			if (flagAsLoaded)
			{
				_isLoaded = true;
				_isSaved = true;
				dispatchEvent(new ORMEvent(ORMEvent.LOADED));
			}
			return res;
		}


		/**
		 * The class for this ORM object
		 */
		public function get ormClass() : Class
		{
			if (!_ormClass)
			{
				_ormClass = getDefinitionByName(ormClassQName) as Class;
			}
			return _ormClass;
		}


		/**
		 * The ORM class qualified name
		 */
		public function get ormClassQName() : String
		{
			if (!_ormClassQName)
			{
				_ormClassQName = getQualifiedClassName(this);
			}
			return _ormClassQName;
		}


		/**
		 * The primary key value of the ORM object
		 */
		public function get primaryKeyValue() : int
		{
			return _columnValues[_descriptor.primaryKeyProperty.columnName];
		}


		/**
		 * Delete the record from the database
		 *
		 * @param forceHardDelete If true and the model has a "deletedAt" column, this will force a hard delete (not flag, but real delete)
		 * @return Returns true if deleted, else false
		 */
		public function remove(forceHardDelete : Boolean = false) : Boolean
		{
			var prop : ORMPropertyDescriptor = forceHardDelete ? null : _descriptor.deletedAtProperty,
					q : SQLiteQuery, r : SQLResult, id : int = primaryKeyValue,
					pkName : String = _descriptor.primaryKeyProperty.columnName;
			if (!isSaved || !id)
			{
				throw new IllegalOperationError("You must save any modification made in an ORM object before deleting it");
			}
			if (_isDeleted || (isSoftDeleted && !forceHardDelete))
			{
				// already deleted
				return true;
			}
			if (!dispatchEvent(new ORMEvent(ORMEvent.DELETING)))
			{
				return false;
			}
			q = new SQLiteQuery(connection, true, PREPEND_SQL_COMMENT);
			if (prop)
			{
				setColumnValue(prop.columnName, new Date(), false);
				q.update(_descriptor.tableName).set(prop.columnName, _columnValues[prop.columnName]);
			}
			else
			{
				q.deleteFrom(_descriptor.tableName);
			}
			r = q.where(pkName + " = " + q.bind(pkName, id)).execute();
			if (r.rowsAffected == 1)
			{
				if (prop)
				{
					_isSaved = true;
					_isLoaded = true;
				}
				else
				{
					reset();
					_isDeleted = true;
				}
				dispatchEvent(new ORMEvent(ORMEvent.DELETED, id));
				return true;
			}
			if (prop)
			{
				setColumnValue(prop.columnName, null, false);
			}
			return false;
		}


		/**
		 * @copy IEventDispatcher#removeEventListener()
		 */
		public function removeEventListener(type : String, listener : Function, useCapture : Boolean
				= false) : void
		{
			_eventDispatcher.removeEventListener(type, listener, useCapture);
		}


		/**
		 * Reset the record as if just instanciated without any parameter
		 *
		 * @param resetExcludeSoftDeletedRecordsFlag If false, the excludeSoftDeletedRecords will not be rested to true
		 * @return Returns this object to do chained calls
		 */
		public function reset(resetExcludeSoftDeletedRecordsFlag : Boolean = true) : ORM
		{
			var i : int;
			if (resetExcludeSoftDeletedRecordsFlag)
			{
				excludeSoftDeletedRecords = true;
			}
			// we use the proxy to dispatch the events
			for (i = 0; i < _columnNames.length; i++)
			{
				_columnValuesProxy[_columnNames[i]] = _descriptor.columnDefaultValue(_columnNames[i]);
			}
			for (i = 0; i < _foreignObjectsPropertyNames.length; i++)
			{
				_foreignObjectsProxy[_foreignObjectsPropertyNames[i]] = null;
			}
			_isSaved = false;
			_isLoaded = false;
			_isDeleted = false;
			_changedColumnNames = new Array();
			return this;
		}


		/**
		 * Save the object (persists it) in the database
		 *
		 * @return Returns true if it has been saved, else false (it also return true if nothing has to be save)
		 */
		public function save() : Boolean
		{
			var q : SQLiteQuery = new SQLiteQuery(connection, true, PREPEND_SQL_COMMENT), pkName : String
					= _descriptor.primaryKeyProperty.columnName,
					isUpdate : Boolean = _columnValues[pkName], name : String, r : SQLResult, lastUpdatedAt : Date;
			if (!hasChanged)
			{
				// nothing to save
				return true;
			}
			if (!dispatchEvent(new ORMEvent(ORMEvent.SAVING)))
			{
				return false;
			}
			if (isUpdate)
			{
				q.update(_descriptor.tableName).where(pkName + " = " + q.bind(pkName, _columnValues[pkName]));
			}
			else
			{
				q.insertInto(_descriptor.tableName);
				if (_descriptor.createdAtProperty)
				{
					setColumnValue(_descriptor.createdAtProperty.columnName, new Date());
				}
			}
			if (_descriptor.updatedAtProperty)
			{
				lastUpdatedAt = _columnValues[_descriptor.updatedAtProperty.columnName];
				setColumnValue(_descriptor.updatedAtProperty.columnName, new Date());
			}
			for each (name in _changedColumnNames)
			{
				q.set(name, _columnValues[name]);
			}
			r = q.execute();
			if (!r.rowsAffected < 1)
			{
				if (!isUpdate && _descriptor.createdAtProperty)
				{
					setColumnValue(_descriptor.createdAtProperty.columnName, null);
				}
				if (_descriptor.updatedAtProperty)
				{
					setColumnValue(_descriptor.updatedAtProperty.columnName, lastUpdatedAt);
				}
				return false;
			}
			if (!isUpdate)
			{
				setColumnValue(pkName, r.lastInsertRowID, false);
			}
			_isSaved = true;
			_isDeleted = false;
			_isLoaded = true;
			_changedColumnNames = new Array();
			dispatchEvent(new ORMEvent(ORMEvent.SAVED));
			return true;
		}


		/**
		 * Set a column value and optionally flag the column as modified
		 * DO NOT USE THIS METHOD UNLESS YOU KNOW WHAT YOU DO, use the properties defined in the model with the prepending "_"
		 *
		 * @param name The name of the column
		 * @param value The value of the column
		 * @param flagAsChanged If false the column will not be flagged as changed
		 * @resetRelationObjects If true all relation properties related to the changed column will be cleared
		 */
		public function setColumnValue(name : String, value : *, flagAsChanged : Boolean = true, resetRelationObjects : Boolean
				= true) : void
		{
			var diff : Boolean = (_columnValuesProxy[name] != value);
			_columnValuesProxy[name] = value;
			if (flagAsChanged && _changedColumnNames.indexOf(name) == -1)
			{
				_changedColumnNames.push(name);
			}
			if (resetRelationObjects && diff)
			{
				clearForeignObjectsRelatedToColumn(name);
			}
		}


		/**
		 * Returns an object representing this ORM object but with only the column values indexed by their column name like in the database
		 *
		 * @return The record object
		 */
		public function toResultObject() : Object
		{
			var res : Object = {}, name : String;
			for each (name in _columnNames)
			{
				res[name] = _columnValues[name];
			}
			return res;
		}


		/**
		 * @copy IEventDispatcher#willTrigger()
		 */
		public function willTrigger(type : String) : Boolean
		{
			return _eventDispatcher.willTrigger(type);
		}


		flash_proxy override function callProperty(name : *, ... parameters) : *
		{
			var rel : IORMRelation = _descriptor.getRelatedTo(name.toString());
			if (!rel)
			{
				throw new IllegalOperationError("Unknown property '" + name.toString() + "' or it is not a foreign entity");
			}
			if (rel.foreignIsUnique)
			{
				throw new IllegalOperationError("The filter on foreign property type cannot be used when the foreign object is unique");
			}
			return rel.getPreparedQuery(this, _columnValues, "local", "foreign", "using").where(parameters);
		}


		/**
		 * Clear all foreign objects/iterator related to the given column name
		 *
		 * @param columnName The name of the column to clear properties which are foreign item(s) attached to the given column
		 * @param excludeRelation If given, it'll not clear the property related to the given relation object
		 */
		internal function clearForeignObjectsRelatedToColumn(columnName : String, excludeRelation : IORMRelation
				= null) : void
		{
			var i : int, rels : Vector.<IORMRelation> = _descriptor.getRelationsBasedOnColumn(columnName);
			for (i = 0; i < rels.length; i++)
			{
				if (!excludeRelation || excludeRelation !== rels[i])
				{
					_foreignObjectsProxy[rels[i].ownerPropertyName] = null;
				}
			}
		}


		flash_proxy override function deleteProperty(name : *) : Boolean
		{
			return false;
		}


		/**
		 * Flag a column as changed looking at its name
		 *
		 * @param columnName The name of the column to flag
		 * @return Returns this object to do chained calls
		 */
		internal function flagColumnAsChanged(columnName : String) : ORM
		{
			if (_changedColumnNames.indexOf(columnName) == -1)
			{
				_changedColumnNames.push(columnName);
				_isSaved = false;
				_isLoaded = false;
			}
			return this;
		}


		flash_proxy override function getProperty(name : *) : *
		{
			var prop : ORMPropertyDescriptor = _descriptor.propertyDescriptor(name), rel : IORMRelation,
					data : *;
			if (!prop)
			{
				rel = _descriptor.getRelatedTo(name);
				if (!rel)
				{
					throw new IllegalOperationError("You must define the property '_" + name + "' on the model '"
							+ _descriptor.ormClassName
							+ "' with a 'Column', 'HasOne', 'HasMany' or 'BelongsTo' metadata");
				}
				if (!_foreignObjects[name])
				{
					rel.setupOrmObject(this, _foreignObjects, _columnValues);
					if (rel.localColumnName != _descriptor.primaryKeyProperty.columnName && rel.foreignIsUnique)
					{
						// using the proxy, we need to dispatch the change of the column
						data = _foreignObjects[name] ? _foreignObjects[name][rel.foreignColumnName] : null;
						if (_columnValues[rel.localColumnName] != data)
						{
							flagColumnAsChanged(rel.localColumnName);
							_columnValuesProxy[rel.localColumnName] = data;
							clearForeignObjectsRelatedToColumn(rel.localColumnName, rel);
						}

					}
				}
				return _foreignObjects[name];
			}
			return _columnValues[prop.columnName];
		}


		flash_proxy override function hasProperty(name : *) : Boolean
		{
			return (_descriptor.propertyDescriptor(name) || _descriptor.getRelatedTo(name));
		}


		flash_proxy override function setProperty(name : *, value : *) : void
		{
			var prop : ORMPropertyDescriptor = _descriptor.propertyDescriptor(name), rel : IORMRelation,
					data : *;
			if (!prop)
			{
				rel = _descriptor.getRelatedTo(name);
				if (!rel)
				{
					throw new IllegalOperationError("You must define the property '_" + name + "' on the model '"
							+ _descriptor.ormClassName
							+ "' with a 'Column', 'HasOne', 'HasMany' or 'BelongsTo' metadata");
				}
				if (!rel.foreignIsUnique)
				{
					throw new IllegalOperationError("You cannot override a non unique foreign object in an ORM object");
				}
				if (rel.replaceForeignItem(this, _foreignObjects[rel.ownerPropertyName], null, value,
						null))
				{
					_foreignObjectsProxy[rel.ownerPropertyName] = value;
					if (rel.localColumnName != _descriptor.primaryKeyProperty.columnName)
					{
						// using the proxy, we need to dispatch the change of the column
						data = _foreignObjects[name] ? _foreignObjects[name][rel.foreignColumnName] : null;
						if (_columnValues[rel.localColumnName] != data)
						{
							flagColumnAsChanged(rel.localColumnName);
							_columnValuesProxy[rel.localColumnName] = data;
							clearForeignObjectsRelatedToColumn(rel.localColumnName, rel);
						}
					}
				}
			}
			else
			{
				// TODO: check the type?
				_columnValuesProxy[prop.columnName] = value;
				clearForeignObjectsRelatedToColumn(prop.columnName);
				flagColumnAsChanged(prop.columnName);
			}
		}


		private function _handleColumnValueChange(event : PropertyChangeEvent) : void
		{
			var prop : ORMPropertyDescriptor = _descriptor.propertyDescriptorByColumnName(event.property.
					toString());
			if (prop)
			{
				event.source = this;
				event.property = prop.name;
				// TODO: make it possible to cancel the change of a column???
				//event.cancelable = false;
				dispatchEvent(event);
			}
		}


		private function _handleForeignObjectChange(event : PropertyChangeEvent) : void
		{
			/*var rel :IORMRelation = _descriptor.getRelatedTo(event.property);
			if ( rel.foreignIsUnique )*/
			event.source = this;
			//event.cancelable = false;
			dispatchEvent(event);
		}
	}
}
