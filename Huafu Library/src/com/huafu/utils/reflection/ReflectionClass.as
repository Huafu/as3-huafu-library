package com.huafu.utils.reflection
{
	import avmplus.getQualifiedClassName;
	
	import com.huafu.utils.HashMap;
	
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;

	public class ReflectionClass extends ReflectionBase
	{
		private static var _allByClassQName : HashMap = new HashMap();
		
		
		private var _class : Class;
		private var _classQName : String;
		private var _className : String;
		private var _propertyXmls : HashMap;
		private var _properties : HashMap;
		private var _allProperties : Array;
		private var _allPropertiesLoaded : Boolean;
		
		
		public function ReflectionClass( theClass : Class )
		{
			var s : Boolean = XML.ignoreWhitespace;
			XML.ignoreWhitespace = true;
			super(describeType(theClass).factory[0]);
			XML.ignoreWhitespace = s;
			_class = theClass;
			_propertyXmls = new HashMap();
			_properties = new HashMap();
			_allProperties = new Array();
			_allPropertiesLoaded = false;
		}

		
		public function get classQName() : String
		{
			if ( !_classQName )
			{
				_classQName = xmlDescription.localName() == "factory" ? xmlDescription.@type.toString() : xmlDescription.@name.toString();
			}
			return _classQName;
		}
		
		
		public function get className() : String
		{
			if ( !_className )
			{
				_className = classQName.split("::").pop().toString();
			}
			return _className;
		}
		
		
		public function property( name : String ) : ReflectionProperty
		{
			var res : ReflectionProperty = _properties.get(name), x : XML;
			if ( !res && !_properties.exists(name) )
			{
				res = null;
				x = propertyXml(name);
				if ( x )
				{
					res = new ReflectionProperty(this, x);
					_allProperties.push(res);
				}
				_properties.set(name, res);
			}
			return res;
		}
		
		
		public function properties( includeVariables : Boolean = true, includeAccessors : Boolean = true ) : Array
		{
			var x : XML, p : ReflectionProperty, name : String, res : Array;
			if ( !_allPropertiesLoaded )
			{
				for each ( x in (xmlDescription.variable + xmlDescription.accessor) )
				{
					name = x.@name.toString();
					if ( !_propertyXmls.exists(name) )
					{
						_propertyXmls.set(name, x);
					}
					if ( !_properties.exists(name) )
					{
						p = new ReflectionProperty(this, x);
						_properties.set(name, p);
						_allProperties.push(p);
					}
				}
				_allPropertiesLoaded = true;
			}
			res = new Array();
			for each ( p in _allProperties )
			{
				if ( (p.varType == "accessor" && includeAccessors) || (p.varType == "variable" && includeVariables) )
				{
					res.push(p);
				}
			}
			return res;
		}
		
		
		public function propertyXml( name : String ) : XML
		{
			var prop : XML = _propertyXmls.get(name), n : String = name;
			if ( !prop && !_propertyXmls.exists(name) )
			{
				prop = xmlDescription.variable.(@name == n)[0];
				if ( !prop )
				{
					prop = xmlDescription.accessor.(@name == n)[0];
				}
				_propertyXmls.set(name, prop);
			}
			return prop;
		}
		
		
		public function propertyMetadataXmlByName( propertyName : String, metadataName : String ) : XMLList
		{
			var m : String = metadataName;
			return propertyXml(propertyName).metadata.(@name == m);
		}
		
		
		public function propertyMetadataXmlByNameAndKeyValue( propertyName : String, metadataName : String, metadataKey : String, metadataValue : String ) : XML
		{
			var m : String = metadataName, k : String = metadataKey, v : String = metadataValue;
			var x : XML = propertyXml(propertyName).metadata.(@name == m).arg.(@key == k && @value == v)[0];
			if ( x )
			{
				return x.parent();
			}
			return null;
		}
		
		
		public function get classRef() : Class
		{
			return _class;
		}
		
		
		public static function forClassOfObject( object : Object ) : ReflectionClass
		{
			var className : String = getQualifiedClassName(object),
				res : ReflectionClass = _allByClassQName.get(className);
			if ( !res )
			{
				res = new ReflectionClass(getDefinitionByName(className) as Class);
				_allByClassQName.set(className, res);
			}
			return res;
		}
		
		
		public static function forClass( theClass : Class ) : ReflectionClass
		{
			var className : String = getClassQName(theClass),
				res : ReflectionClass = _allByClassQName.get(className);
			if ( !res )
			{
				res = new ReflectionClass(getDefinitionByName(className) as Class);
				_allByClassQName.set(className, res);
			}
			return res;
		}
		
		
		public static function getClassQName( theClass : Class ) : String
		{
			return getQualifiedClassName(theClass);
		}
	}
}