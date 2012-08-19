package com.huafu.utils.reflection
{
	import flash.utils.getDefinitionByName;

	
	/**
	 * Reflects a class' property
	 */
	public class ReflectionProperty extends ReflectionBase
	{
		/**
		 * Type of property : variable
		 */
		public static const TYPE_VARIABLE : String = "variable";
		/**
		 * Type of property : accessor
		 */
		public static const TYPE_ACCESSOR : String = "accessor";
		
		
		/**
		 * The class owning the property
		 */
		private var _owner : ReflectionClass;
		/**
		 * The name of the property
		 */
		private var _name : String;
		/**
		 * The type of the property (accessor or variable)
		 * @see #TYPE_ACCESSOR
		 * @see #TYPE_VARIABLE
		 */
		private var _type : String;
		/**
		 * The data type QName of the property
		 */
		private var _dataType : String;
		
		
		/**
		 * Creates a reflection of a preoperty
		 * 
		 * @param owner The relfection class owning the property
		 * @param xmlNode The XML node describing the proeprty
		 */
		public function ReflectionProperty( owner : ReflectionClass, xmlNode : XML )
		{
			super(xmlNode);
			_name = xmlNode.@name.toString();
			_type = xmlNode.localName();
			_dataType = xmlNode.@type.toString();
			_owner = owner;
		}
		
		
		/**
		 * The owner reflection class of this property
		 */
		public function get owner() : ReflectionClass
		{
			return _owner;
		}
		
		
		/**
		 * The data type of the property
		 */
		public function get dataType() : String
		{
			return _dataType;
		}
		
		
		/**
		 * Pointer to the class of the data type
		 */
		public function get dataTypeClass() : Class
		{
			return getDefinitionByName(_dataType) as Class;
		}
		
		
		/**
		 * The proeprty type of this proeprty
		 * @see #TYPE_ACCESSOR
		 * @see #TYPE_VARIABLE
		 */
		public function get propertyType() : String
		{
			return _type;
		}
		
		/**
		 * The name of this property
		 */
		public function get name() : String
		{
			return _name;
		}
	}
}