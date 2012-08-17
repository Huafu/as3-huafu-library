package com.huafu.utils.reflection
{
	import flash.utils.getDefinitionByName;

	public class ReflectionProperty extends ReflectionBase
	{
		private var _owner : ReflectionClass;
		private var _name : String;
		private var _type : String;
		private var _dataType : String;
		
		public function ReflectionProperty( owner : ReflectionClass, xmlNode : XML )
		{
			super(xmlNode);
			_name = xmlNode.@name.toString();
			_type = xmlNode.localName();
			_dataType = xmlNode.@type.toString();
			_owner = owner;
		}
		
		
		public function get owner() : ReflectionClass
		{
			return _owner;
		}
		
		
		public function get dataType() : String
		{
			return _dataType;
		}
		
		
		public function get dataTypeClass() : Class
		{
			return getDefinitionByName(_dataType) as Class;
		}
		
		
		public function get varType() : String
		{
			return _type;
		}
		
		
		public function get name() : String
		{
			return _name;
		}
	}
}