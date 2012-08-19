package com.huafu.utils.reflection
{
	import com.huafu.utils.HashMap;

	
	/**
	 * This is the base class for any Reflection class which has metadata
	 * @abstract
	 */
	public class ReflectionBase
	{
		/**
		 * Stores the XML node relted to this reflection object
		 */
		private var _xml : XML;
		/**
		 * Stores all metadata which are unique by name
		 */
		private var _uniqueMetadatas : HashMap;
		/**
		 * Stores all metadata of this object
		 */
		private var _allMetadatas : Array;
		
		
		/**
		 * Constructor
		 * 
		 * @param xmlNode The node describing this reflection object
		 */
		public function ReflectionBase( xmlNode : XML )
		{
			_xml = xmlNode;
			_uniqueMetadatas = new HashMap();
		}
		
		
		/**
		 * Finds whether this object has a given metadata
		 * 
		 * @param name The name of the metadata
		 * @return Returns true if the metadata with given name exists, else false
		 */
		public function hasMetadata( name : String ) : Boolean
		{
			return (metadataByName(name)..length() > 0);
		}
		
		
		/**
		 * List of all metadatas that has this object
		 */
		public function get metadatas() : Array
		{
			var x : XML;
			if ( !_allMetadatas )
			{
				_allMetadatas = new Array();
				for each ( x in _xml.metadata )
				{
					_allMetadatas.push(new ReflectionMetadata(this, x));
				}
			}
			return _allMetadatas;
		}
		
		
		/**
		 * The XML description node of this object
		 */
		public function get xmlDescription() : XML
		{
			return _xml;
		}
		
		
		/**
		 * Get a metadata by its name (this metadata has to be unique)
		 * 
		 * @param name The name of the unique metadata to get
		 * @return The reflection metadata object or null if no such metadata
		 */
		public function uniqueMetadata( name : String ) : ReflectionMetadata
		{
			var res : ReflectionMetadata = _uniqueMetadatas.get(name), x : XML, s : String = name;
			if ( !res && !_uniqueMetadatas.exists(name) )
			{
				res = null;
				if ( (x = xmlDescription.metadata.(@name == s)[0]) )
				{
					res = new ReflectionMetadata(this, x);
				}
				_uniqueMetadatas.set(name, res);
			}
			return res;
		}
		
		
		/**
		 * Get a XMLList of all metadata with the given name
		 * 
		 * @param name The name of the metadatas to get
		 * @return The XMLList of all metadatas with the given name
		 */
		public function metadataByName( name : String ) : XMLList
		{
			var s : String = name;
			return xmlDescription.metadata.(@name == s);
		}
		
		
		/**
		 * Get a metadata by name and argument's name and value as a XML object
		 * 
		 * @param name The name of the metadata
		 * @param key The key of the argument which value has to be the one in the value parameter
		 * @param value The value of the argument which key is the one given in key parameter
		 * @return The XML node of the metadata or null
		 */
		public function metadataByNameAndKeyValue( name : String, key : String, value : String ) : XML
		{
			var n : String = name, k : String = key, v : String = value,
				x : XML = xmlDescription.metadata.(@name == n).arg.(@key == k && @value == v)[0];
			if ( x )
			{
				return x.parent();
			}
			return null;
		}
	}
}