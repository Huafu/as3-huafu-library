package com.huafu.sql.orm
{
	import avmplus.getQualifiedClassName;
	
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;
	
	import flash.debugger.enterDebugger;
	import flash.utils.getDefinitionByName;

	
	/**
	 * The base class for any ORM relation object
	 * 
	 * @abstract
	 */
	public class ORMRelationDescriptorBase
	{
		/**
		 * Name of the property holding the relation
		 */
		private var _propertyName : String;
		/**
		 * The ORMDescriptor owning the realtion
		 */
		private var _ormDescriptor : ORMDescriptor;
		/**
		 * The ORMDescriptor of the related model
		 */
		private var _relatedOrmDescriptor : ORMDescriptor;
		/**
		 * A pointer to the class of the related ORM
		 */
		private var _relatedOrmClass : Class;
		
		
		/**
		 * Constructor
		 * 
		 * @param ormDescriptor The owning ORM descriptor
		 * @param propertyName The name of hte property holding the relation
		 * @param relatedClass The class of the related ORM
		 */
		public function ORMRelationDescriptorBase( ormDescriptor : ORMDescriptor, propertyName : String, relatedClass : Class )
		{
			_propertyName = propertyName;
			_ormDescriptor = ormDescriptor;
			_relatedOrmClass = relatedClass;
		}
		
		
		/**
		 * The class of the related ORM
		 */
		public function get relatedOrmClass() : Class
		{
			return _relatedOrmClass;
		}
		
		
		/**
		 * The descriptor of the related ORM
		 */
		public function get relatedOrmDescriptor() : ORMDescriptor
		{
			if ( !_relatedOrmDescriptor )
			{
				_relatedOrmDescriptor = ORMDescriptor.forClass(_relatedOrmClass);
			}
			return _relatedOrmDescriptor;
		}
		
		
		/**
		 * The name of the property holding the relation
		 */
		public function get propertyName() : String
		{
			return _propertyName;
		}
		
		
		/**
		 * The descriptor of theORM holing the relation
		 */
		public function get ormDescriptor() : ORMDescriptor
		{
			return _ormDescriptor;
		}
		
		
		/**
		 * Creates a new relation object of the appropriate class looking at the given ReflectionProperty
		 * 
		 * @param ownerDescriptor The descriptor of the ORM owning the realtion
		 * @param property The ReflectionProperty to use to setup the ORM relation
		 * @return The newly created ORM relation object
		 */
		public static function fromReflectionProperty( ownerDescriptor : ORMDescriptor, property : ReflectionProperty ) : IORMRelationDescriptor
		{
			var res : IORMRelationDescriptor, relationType : String;
			relationType = property.xmlDescription.metadata.(@name == "HasOne" || @name == "HasMany" || @name == "BelongsTo")[0].@name.toString();
			res = ORMRelationDescriptorBase["_create" + relationType + "FromReflectionProperty"](ownerDescriptor, property, property.uniqueMetadata(relationType));
			return res;
		}
		
		
		/**
		 * Creates a "has one" relation object looking at the given property and meta reflections
		 * 
		 * @param ownerDescriptor The descriptor of the ORM holding the relation
		 * @param property The reflection of the property hoding the relation
		 * @param meta The reflection metadata describing the realtion
		 * @return The new relation object
		 */
		private static function _createHasOneFromReflectionProperty( ownerDescriptor : ORMDescriptor, property : ReflectionProperty, meta : ReflectionMetadata ) : IORMRelationDescriptor
		{
			var res : ORMHasOneDescriptor;
			res = new ORMHasOneDescriptor(
				ownerDescriptor,
				property.name,
				property.dataTypeClass,
				meta.hasArgument("nullable"),
				meta.argValueString("columnName")
			);
			return res;
		}
		
		
		/**
		 * Creates a "has many" relation object looking at the given property and meta reflections
		 * 
		 * @param ownerDescriptor The descriptor of the ORM holding the relation
		 * @param property The reflection of the property hoding the relation
		 * @param meta The reflection metadata describing the realtion
		 * @return The new relation object
		 */
		private static function _createHasManyFromReflectionProperty( ownerDescriptor : ORMDescriptor, property : ReflectionProperty, meta : ReflectionMetadata ) : IORMRelationDescriptor
		{
			var res : IORMRelationDescriptor,
				ormClass : Class,
				usingOrmClassName : String,
				usingOrmClass : Class;
			ormClass = ORMDescriptor.resolveOrmClass(meta.argValueString("className"), ownerDescriptor);
			// the case depends if we're in front of a direct relation or not
			if ( (usingOrmClassName = meta.argValueString("using")) )
			{
				usingOrmClass = ORMDescriptor.resolveOrmClass(usingOrmClassName, ownerDescriptor);
				res = new ORMHasManyUsingDescriptor(
					ownerDescriptor,
					property.name,
					ormClass,
					usingOrmClass
				);
			}
			else
			{
				res = new ORMHasManyDescriptor(
					ownerDescriptor,
					property.name,
					ormClass,
					meta.argValueString("relatedColumnName")
				);
			}
			return res;
		}
		
		
		/**
		 * Creates a "belongs to" relation object looking at the given property and meta reflections
		 * 
		 * @param ownerDescriptor The descriptor of the ORM holding the relation
		 * @param property The reflection of the property hoding the relation
		 * @param meta The reflection metadata describing the realtion
		 * @return The new relation object
		 */
		private static function _createBelongsToFromReflectionProperty( ownerDescriptor : ORMDescriptor, property : ReflectionProperty, meta : ReflectionMetadata ) : IORMRelationDescriptor
		{
			var res : ORMBelongsToDescriptor,
				ormClass : Class = ORMDescriptor.resolveOrmClass(meta.argValueString("className"), ownerDescriptor);
			res = new ORMBelongsToDescriptor(
				ownerDescriptor,
				property.name,
				ormClass,
				meta.argValueString("relatedColumnName")
			);
			return res;
		}
		
		
		
	}
}