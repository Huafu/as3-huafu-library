package com.huafu.utils.reflection
{
	import avmplus.getQualifiedClassName;
	
	import com.huafu.utils.HashMap;
	
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;

	
	/**
	 * Reflection of a Class
	 */
	public class ReflectionClass extends ReflectionBase
	{
		/**
		 * Cache for all classes by thei QName
		 */
		private static var _allByClassQName : HashMap = new HashMap();
		
		/**
		 * Pointer to the class
		 */
		private var _class : Class;
		/**
		 * The qname of the class
		 */
		private var _classQName : String;
		/**
		 * The name of the class
		 */
		private var _className : String;
		/**
		 * The cached XML nodes for each property
		 */
		private var _propertyXmls : HashMap;
		/**
		 * The properties indexed by their name
		 */
		private var _properties : HashMap;
		/**
		 * All properties
		 */
		private var _allProperties : Array;
		/**
		 * Whether all properties have been loaded already or not
		 */
		private var _allPropertiesLoaded : Boolean;
		
		
		/**
		 * Creates a new reflection of the given class
		 * 
		 * @param theClass The class to get reflection of
		 */
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

		
		/**
		 * The QName of the class
		 */
		public function get classQName() : String
		{
			if ( !_classQName )
			{
				_classQName = xmlDescription.localName() == "factory" ? xmlDescription.@type.toString() : xmlDescription.@name.toString();
			}
			return _classQName;
		}
		
		
		/**
		 * Name of the class
		 */
		public function get className() : String
		{
			if ( !_className )
			{
				_className = classQName.split("::").pop().toString();
			}
			return _className;
		}
		
		
		/**
		 * Get a property by it's name
		 * 
		 * @param name The name of the property to get
		 * @return The reflection of the given property
		 */
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
		
		
		/**
		 * Get all properties of the reflected class
		 * 
		 * @param includeVariables If true, the variables are included in the resulting array
		 * @param includeAccessors If true, all accessors are incuded in the resulting array
		 * @return An array containing all accessors and/or variables
		 */
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
				if ( (p.propertyType == ReflectionProperty.TYPE_ACCESSOR && includeAccessors) || (p.propertyType == ReflectionProperty.TYPE_VARIABLE && includeVariables) )
				{
					res.push(p);
				}
			}
			return res;
		}
		
		
		/**
		 * Get the XML node of a property looking at the given property's name
		 * 
		 * @param name The name of the property to get
		 * @return The XML node corresponding to the property
		 */
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
		
		
		/**
		 * Pointer to the class that this reflection refers to
		 */
		public function get classRef() : Class
		{
			return _class;
		}
		
		
		/**
		 * Returns the reflection class object of the class of the given object
		 * 
		 * @param The object ot get the reflection class object of it's class
		 * @return The reflection class object for the class of the given object
		 */
		public static function forClassOfObject( object : * ) : ReflectionClass
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
		
		
		/**
		 * Get the reflection class of the given class
		 * 
		 * @param theClass The class to get reflection of
		 * @return The relfection class object
		 */
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
		
		
		/**
		 * Get the QName of the given class
		 * 
		 * @param theClass The class to get the QName of
		 * @return The QName of the given class
		 */
		public static function getClassQName( theClass : Class ) : String
		{
			return getQualifiedClassName(theClass);
		}
		
		
		/**
		 * Finds whether a given object is an instance of the given class
		 * and only of the given class, not an extended version of the class
		 * 
		 * @param objectToTest The object to test
		 * @param classToTest The class the object has to be of
		 * @return Returns true if the object is an instance of the given class, else false
		 */
		public static function isStrictly( objectToTest : *, classToTest : Class ) : Boolean
		{
			return (objectToTest is classToTest) && (getQualifiedClassName(objectToTest) == getQualifiedClassName(classToTest));
		}
	}
}