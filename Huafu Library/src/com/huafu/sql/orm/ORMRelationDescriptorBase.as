package com.huafu.sql.orm
{
	import avmplus.getQualifiedClassName;
	
	import com.huafu.utils.reflection.ReflectionMetadata;
	import com.huafu.utils.reflection.ReflectionProperty;
	
	import flash.utils.getDefinitionByName;

	public class ORMRelationDescriptorBase
	{
		private var _propertyName : String;
		private var _ormDescriptor : ORMDescriptor;
		private var _relatedOrmDescriptor : ORMDescriptor;
		private var _relatedOrmClass : Class;
		
		public function ORMRelationDescriptorBase( ormDescriptor : ORMDescriptor, propertyName : String, relatedClass : Class )
		{
			_propertyName = propertyName;
			_ormDescriptor = ormDescriptor;
			_relatedOrmClass = relatedClass;
		}
		
		
		public function get relatedOrmClass() : Class
		{
			return _relatedOrmClass;
		}
		
		
		public function get relatedOrmDescriptor() : ORMDescriptor
		{
			if ( !_relatedOrmDescriptor )
			{
				_relatedOrmDescriptor = ORMDescriptor.forClass(_relatedOrmClass);
			}
			return _relatedOrmDescriptor;
		}
		
		
		public function get propertyName() : String
		{
			return _propertyName;
		}
		
		
		public function get ormDescriptor() : ORMDescriptor
		{
			return _ormDescriptor;
		}
		
		
		public static function fromReflectionProperty( ownerDescriptor : ORMDescriptor, property : ReflectionProperty ) : IORMRelationDescriptor
		{
			var res : IORMRelationDescriptor, relationType : String;
			relationType = property.xmlDescription.metadata.(@name == "HasOne" || @name == "HasMany" || @name == "BelongsTo")[0].@name.toString();
			res = ORMRelationDescriptorBase["_create" + relationType + "FromReflectionProperty"](ownerDescriptor, property, property.uniqueMetadata(relationType));
			return res;
		}
		
		
		private static function _createHasOneFromReflectionProperty( ownerDescriptor : ORMDescriptor, property : ReflectionProperty, meta : ReflectionMetadata ) : ORMHasOneDescriptor
		{
			var res : ORMHasOneDescriptor;
			res = new ORMHasOneDescriptor(
				ownerDescriptor,
				property.name,
				property.dataTypeClass,
				meta.argValueBoolean("nullable", false),
				meta.argValueString("columnName")
			);
			return res;
		}
		
		
		private static function _createHasManyFromReflectionProperty( ownerDescriptor : ORMDescriptor, property : ReflectionProperty, meta : ReflectionMetadata ) : ORMHasManyDescriptor
		{
			var res : ORMHasManyDescriptor, ormClass : Class, ormClassName : String = ORMDescriptor.ormModelsPackageFullName + "::" + meta.argValueString("className");
			try
			{
				ormClass = getDefinitionByName(ormClassName) as Class;
			}
			catch ( err : ReferenceError )
			{
				if ( err.errorID == 1065 )
				{
					err.message = err.message + " This is usually thrown because as3 cannot find your related ORM model's class. Try adding the line '" + meta.argValueString("className") + ";' in the constructor of '" + getQualifiedClassName(ownerDescriptor.ormClass) + "' before 'super();', it should solve the problem.";
				}
				throw err;
			}
			res = new ORMHasManyDescriptor(
				ownerDescriptor,
				property.name,
				ormClass,
				meta.argValueString("relatedColumnName")
			);
			return res;
		}
		
		
		
	}
}