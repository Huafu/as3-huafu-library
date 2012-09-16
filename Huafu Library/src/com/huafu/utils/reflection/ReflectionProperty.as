/*============================================================================*/
/*                                                                            */
/*    Huafu Gandon, hereby disclaims all copyright interest in the            */
/*    library “Huafu Library” (which makes passes at compilers)               */
/*    written by Huafu Gandon.                                                */
/*                                                                            */
/*    Huafu Gandon <huafu.gandon@gmail.com>, 15 August 2012                   */
/*                                                                            */
/*                                                                            */
/*    This file is part of Huafu Library.                                     */
/*                                                                            */
/*    Huafu Library is free software: you can redistribute it and/or modify   */
/*    it under the terms of the GNU General Public License as published by    */
/*    the Free Software Foundation, either version 3 of the License, or       */
/*    (at your option) any later version.                                     */
/*                                                                            */
/*    Huafu Library is distributed in the hope that it will be useful,        */
/*    but WITHOUT ANY WARRANTY; without even the implied warranty of          */
/*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           */
/*    GNU General Public License for more details.                            */
/*                                                                            */
/*    You should have received a copy of the GNU General Public License       */
/*    along with Huafu Library.  If not, see <http://www.gnu.org/licenses/>.  */
/*                                                                            */
/*============================================================================*/


package com.huafu.utils.reflection
{
	import flash.utils.getDefinitionByName;


	/**
	 * Reflects a class' property
	 */
	public class ReflectionProperty extends ReflectionBase
	{
		/**
		 * Type of property : accessor
		 */
		public static const TYPE_ACCESSOR : String = "accessor";


		/**
		 * Type of property : variable
		 */
		public static const TYPE_VARIABLE : String = "variable";


		/**
		 * Creates a reflection of a preoperty
		 *
		 * @param owner The relfection class owning the property
		 * @param xmlNode The XML node describing the proeprty
		 */
		public function ReflectionProperty(owner : ReflectionClass, xmlNode : XML)
		{
			super(xmlNode);
			_name = xmlNode.@name.toString();
			_type = xmlNode.localName();
			_dataType = xmlNode.@type.toString();
			_owner = owner;
		}


		/**
		 * The data type QName of the property
		 */
		private var _dataType : String;


		/**
		 * The name of the property
		 */
		private var _name : String;


		/**
		 * The class owning the property
		 */
		private var _owner : ReflectionClass;


		/**
		 * The type of the property (accessor or variable)
		 * @see #TYPE_ACCESSOR
		 * @see #TYPE_VARIABLE
		 */
		private var _type : String;


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
		 * The name of this property
		 */
		public function get name() : String
		{
			return _name;
		}


		/**
		 * The owner reflection class of this property
		 */
		public function get owner() : ReflectionClass
		{
			return _owner;
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
	}
}
