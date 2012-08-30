package com.huafu.sql.orm.relation
{
	import com.huafu.sql.orm.ORM;
	import com.huafu.sql.orm.ORMDescriptor;
	import com.huafu.sql.orm.ORMPropertyDescriptor;
	import com.huafu.sql.query.SQLiteCondition;
	import com.huafu.sql.query.SQLiteQuery;
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;
	
	import flash.errors.IllegalOperationError;

	/**
	 * Base class for any other ORM relation class
	 */
	public class ORMRelation
	{
		protected var _destinationOrmDescriptor : ORMDescriptor;
		protected var _destinationOrmPropertyName : String;
		protected var _localColumnName : String;
		
		protected var _foreignColumnName : String;
		protected var _foreignColumnProperty : ORMPropertyDescriptor;
		protected var _foreignOrmClassName : String;
		protected var _foreignOrmClass : Class;
		protected var _foreignOrmDescriptor : ORMDescriptor;
		protected var _foreignRelation : IORMRelation;
		protected var _foreignIsUnique : Boolean;
		protected var _localColumnSqlCode : String;
		
		/**
		 * Constructor
		 * 
		 * @param ownerDescriptor The ORM descriptor owning the relation
		 * @param property The reflection property owning the relation
		 * @param metadata The medtadata reflection of the property concerning the relation
		 */
		public function ORMRelation( ownerDescriptor : ORMDescriptor, property : ReflectionProperty, metadata : ReflectionMetadata )
		{
			_destinationOrmDescriptor = ownerDescriptor;
			_destinationOrmPropertyName = property.name;
			_foreignIsUnique = false;
		}
		
		
		/**
		 * @copy IORMRelation#foreignColumnProperty
		 */
		public function get foreignColumnProperty() : ORMPropertyDescriptor
		{
			if ( !_foreignColumnProperty )
			{
				_foreignColumnProperty = foreignDescriptor.propertyDescriptorByColumnName(foreignColumnName);
			}
			return _foreignColumnProperty;
		}
		
		
		/**
		 * @copy IORMRelation#foreignIsUnique
		 */
		public function get foreignIsUnique() : Boolean
		{
			return _foreignIsUnique;
		}
		
		
		/**
		 * @copy IORMRelation#foreignColumnName
		 */
		public function get foreignColumnName() : String
		{
			return _foreignColumnName;
		}
		
		
		/**
		 * @copy IORMRelation#foreignRelation
		 */
		public function get foreignRelation() : IORMRelation
		{
			if ( !_foreignRelation )
			{
				_foreignRelation = foreignDescriptor.getRelationTo(ownerDescriptor, localColumnName);
			}
			return _foreignRelation;
		}
		
		
		/**
		 * @copy IORMRelation#ownerDescriptor
		 */
		public function get ownerDescriptor() : ORMDescriptor
		{
			return _destinationOrmDescriptor;
		}
		
		
		/**
		 * @copy IORMRelation#ownerPropertyName
		 */
		public function get ownerPropertyName() : String
		{
			return _destinationOrmPropertyName;
		}
		
		
		/**
		 * @copy IORMRelation#localColumnName
		 */
		public function get localColumnName() : String
		{
			return _localColumnName;
		}
		
		
		/**
		 * @copy IORMRelation#localColumnSqlCode
		 */
		public function get localColumnSqlCode() : String
		{
			return _localColumnSqlCode;
		}
		
		
		/**
		 * @copy IORMRelation#foreignOrmClass
		 */
		public function get foreignOrmClass() : Class
		{
			if ( !_foreignOrmClass )
			{
				_foreignOrmClass = ORMDescriptor.resolveOrmClass(_foreignOrmClassName, ownerDescriptor);
			}
			return _foreignOrmClass;
		}
		
		
		/**
		 * @copy IORMRelation#foreignDescriptor
		 */
		public function get foreignDescriptor() : ORMDescriptor
		{
			if ( !_foreignOrmDescriptor )
			{
				_foreignOrmDescriptor = ORMDescriptor.forClass(_foreignOrmClass);
			}
			return _foreignOrmDescriptor;
		}
		
		
		/**
		 * @copy IORMRelation#setupQueryCondition()
		 */
		public function setupQueryCondition( query : SQLiteQuery, ormObject : ORM, usingData : Object, localTableAlias : String = null, foreignTableAlias : String = null, usingTableAlias : String = null ) : void
		{
			var foreignOrm : ORM = foreignDescriptor.globalOrmInstance;
			foreignOrm.excludeSoftDeleted = ormObject.excludeSoftDeleted;
			if ( !localTableAlias )
			{
				localTableAlias = ownerDescriptor.tableName;
			}
			if ( !foreignTableAlias )
			{
				foreignTableAlias = foreignDescriptor.tableName;
			}
			query.where(
				new SQLiteCondition(foreignTableAlias + "." + foreignColumnName + " = ?", usingData[localColumnName]),
				foreignOrm.getDeletedCondition(foreignTableAlias));
		}
		
		
		/**
		 * @copy IORMRelation#getSqlCondition()
		 */
		public function getSqlCondition( localTableAlias : String = null, foreignTableAlias : String = null, usingTableAlias : String = null ) : String
		{
			if ( !localTableAlias )
			{
				localTableAlias = ownerDescriptor.tableName;
			}
			if ( !foreignTableAlias )
			{
				foreignTableAlias = foreignDescriptor.tableName;
			}
			return foreignTableAlias + "." + foreignColumnName + " = " + localTableAlias + "." + localColumnName;
		}
		
		
		/**
		 * Creates a new relation object of the appropriate class looking at the given ReflectionProperty
		 * 
		 * @param ownerDescriptor The descriptor of the ORM owning the realtion
		 * @param property The ReflectionProperty to use to setup the ORM relation
		 * @return The newly created ORM relation object
		 */
		public static function fromReflectionProperty( ownerDescriptor : ORMDescriptor, property : ReflectionProperty ) : IORMRelation
		{
			var res : IORMRelation, relationType : String, metadata : ReflectionMetadata, relClass : Class;
			relationType = property.xmlDescription.metadata.(@name == "HasOne" || @name == "HasMany" || @name == "BelongsTo")[0].@name.toString();
			metadata = property.uniqueMetadata(relationType);
			if ( metadata.hasArgument("usingClass") )
			{
				relClass = ORMRelationBridge;
			}
			else if ( relationType == "HasOne" )
			{
				relClass = ORMRelationHasOne;
			}
			else
			{
				relClass = ORMRelationHasMany;
			}
			res = new relClass(ownerDescriptor, property, metadata);
			return res;
		}
		
		
		/**
		 * Read a class name from a metadata argument, 
		 * 
		 * @param metadata The metadata containing the argument to read
		 * @param argName The name of the argument which value is the name of the class
		 * @return The name of the class read
		 * @throws IllegalOperationError If no class name defined in the given argument
		 */
		internal static function readOrmClassFromMetadataArg( metadata : ReflectionMetadata, argName : String = "foreignClass" ) : String
		{
			var className : String;
			className = metadata.argValueString(argName);
			if ( !className )
			{
				throw new IllegalOperationError("You must define a '" + argName + "' argument on the '" + metadata.name
					+ "' metadata of the property '" + (metadata.owner as ReflectionProperty).name + "' defined in model '"
					+ (metadata.owner as ReflectionProperty).owner.className + "'");
			}
			return className;
		}
	}
}