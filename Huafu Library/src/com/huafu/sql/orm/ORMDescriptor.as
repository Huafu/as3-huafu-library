package com.huafu.sql.orm
{
	import avmplus.getQualifiedClassName;
	
	import com.huafu.utils.HashMap;
	import com.huafu.utils.StringUtil;
	import com.huafu.utils.reflection.ReflectionClass;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;
	
	import flash.data.SQLResult;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayList;

	public class ORMDescriptor
	{
		public static var ormModelsPackageFullName : String = "models";
		
		private static var _allByClassQName : HashMap = new HashMap();
		
		// basic stuff
		private var _ormClass : Class;
		private var _ormClassQName : String;
		private var _tableName : String;
		private var _databaseName : String;
		// properties indexed
		private var _propertiesByName : HashMap;
		private var _propertiesByColumnName : HashMap;
		// special columns
		private var _primaryKeyProperty : ORMPropertyDescriptor;
		private var _createdAtProperty : ORMPropertyDescriptor;
		private var _updatedAtProperty : ORMPropertyDescriptor;
		private var _deletedAtProperty : ORMPropertyDescriptor;
		// relations
		private var _relatedTo : HashMap;
		
		
		public function ORMDescriptor( ormClass : Class )
		{
			var reflection : ReflectionClass = ReflectionClass.forClass(ormClass),
				meta : ReflectionMetadata, prop : ReflectionProperty,
				ormProp : ORMPropertyDescriptor,
				pk : String = "id", upd : String = "updatedAt", cre : String = "createdAt",
				del : String = "deletedAt";
			
			// basic stuff
			_ormClassQName = getQualifiedClassName(ormClass);
			_ormClass = ormClass;
			_relatedTo = new HashMap();
			
			// table and database
			meta = reflection.uniqueMetadata("Table");
			_tableName = meta.argValue("tableName") ? meta.argValueString("tableName") : StringUtil.unCamelize(reflection.className);
			_databaseName = meta.argValue("database") ? meta.argValueString("database") : ORM.defaultDatabaseName;
			
			// special columns
			pk = meta.argValueString("primaryKey", pk);
			upd = meta.argValueString("modifiedDate", upd);
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
					_relatedTo.set(prop.name, ORMRelationDescriptorBase.fromReflectionProperty(this, prop));
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
					_primaryKeyProperty = ormProp;
				}
				else if ( cre == ormProp.name )
				{
					_createdAtProperty = ormProp;
				}
				else if ( upd == ormProp.name )
				{
					_updatedAtProperty = ormProp;
				}
				else if ( del == ormProp.name )
				{
					_deletedAtProperty = ormProp;
				}
			}
		}
		
		
		public function getRelatedTo( propertyName : String ) : IORMRelationDescriptor
		{
			return _relatedTo.get(propertyName) as IORMRelationDescriptor;
		}
		
		
		public function get updatedAtProperty() : ORMPropertyDescriptor
		{
			return _updatedAtProperty;
		}
		
		
		public function get createdAtProperty() : ORMPropertyDescriptor
		{
			return _createdAtProperty;
		}
		
		
		public function get deletedAtProperty() : ORMPropertyDescriptor
		{
			return _deletedAtProperty;
		}
		
		
		public function sqlResultRowToOrmObject( result : Object, object : ORM ) : void
		{
			// load normal properties
			_propertiesByName.forEach(function( name : String, prop : ORMPropertyDescriptor, index : int ) : void
			{
				if ( result.hasOwnProperty(prop.columnName) )
				{
					object[name] = result[prop.columnName];
				}
				else
				{
					object[name] = undefined;
				}
			});
			// prepare for relation properties
			_relatedTo.forEach(function( name : String, relation : IORMRelationDescriptor, index : int ) : void
			{
				relation.setupOrmObject(object, result);
			});
		}
		
		
		public function get ormClassQName() : String
		{
			return _ormClassQName;
		}
		
		
		public function get primaryKeyProperty() : ORMPropertyDescriptor
		{
			return _primaryKeyProperty;
		}
		
		
		public function propertyDescriptor( name : String ) : ORMPropertyDescriptor
		{
			return _propertiesByName.get(name) as ORMPropertyDescriptor;
		}
		
		
		public function propertyDescriptorByColumnName( name : String ) : ORMPropertyDescriptor
		{
			return _propertiesByColumnName.get(name) as ORMPropertyDescriptor;
		}
		
		
		public function get tableName() : String
		{
			return _tableName;
		}
		
		
		public function get ormClass() : Class
		{
			return _ormClass;
		}
		
		
		public static function forObject( ormObject : ORM ) : ORMDescriptor
		{
			var descriptor : ORMDescriptor = _allByClassQName.get(ormObject.classQName);
			if ( !descriptor )
			{
				descriptor = new ORMDescriptor(ormObject.classRef);
				_allByClassQName.set(ormObject.classQName, descriptor);
			}
			return descriptor;
		}
		
		
		public static function forClass( ormClass : Class ) : ORMDescriptor
		{
			var classQName : String = getQualifiedClassName(ormClass),
				desc : ORMDescriptor = _allByClassQName.get(classQName);
			if ( !desc )
			{
				desc = new ORMDescriptor(ormClass);
				_allByClassQName.set(classQName, desc);
			}
			return desc;
		}
		
		
		public static function get allModelClassQNamesKnown() : Array
		{
			return _allByClassQName.keys();
		}
	}
}