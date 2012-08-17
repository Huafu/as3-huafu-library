package com.huafu.utils.reflection
{
	import com.huafu.utils.HashMap;

	public class ReflectionBase
	{
		private var _xml : XML;
		private var _uniqueMetadatas : HashMap;
		private var _allMetadatas : Array;
		
		
		public function ReflectionBase( xmlNode : XML )
		{
			_xml = xmlNode;
			_uniqueMetadatas = new HashMap();
		}
		
		
		public function hasMetadata( name : String ) : Boolean
		{
			return (metadataByName(name)..length() > 0);
		}
		
		
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
		
		
		public function get xmlDescription() : XML
		{
			return _xml;
		}
		
		
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
		
		
		public function metadataByName( name : String ) : XMLList
		{
			var s : String = name;
			return xmlDescription.metadata.(@name == s);
		}
		
		
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