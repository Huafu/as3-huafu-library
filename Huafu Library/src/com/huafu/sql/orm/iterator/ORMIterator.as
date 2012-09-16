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


package com.huafu.sql.orm.iterator
{
	import com.huafu.sql.orm.ORM;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import flash.utils.getDefinitionByName;
	import mx.collections.ArrayList;
	import mx.collections.IList;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	import avmplus.getQualifiedClassName;


	public class ORMIterator extends Proxy implements IORMIterator
	{

		private static var _propertyRegexp : RegExp = /^[0-9]+$/g;


		public function ORMIterator(ormClass : Class, source : Array = null)
		{
			_source = new ArrayList(source);
			_ormClass = ormClass;
		}


		protected var _ormClass : Class;


		protected var _source : ArrayList;


		/**
		 *  Used for accessing localized Error messages.
		 */
		protected var resourceManager : IResourceManager =
				ResourceManager.getInstance();


		/**
		 * @copy mx.collections.ArrayList#addAll()
		 */
		public function addAll(addList : IList) : void
		{
			if (isPersistent)
			{
				_source.addAll(addList);
				return;
			}
			_throw("addAll");
		}


		/**
		 * @copy mx.collections.ArrayList#addAllAt()
		 */
		public function addAllAt(addList : IList, index : int) : void
		{
			if (isPersistent)
			{
				_source.addAllAt(addList, index);
				return;
			}
			_throw("addAllAt");
		}


		/**
		 * @inheritDoc
		 */
		public function addEventListener(type : String, listener : Function, useCapture : Boolean = false,
				priority : int = 0, useWeakReference : Boolean = false) : void
		{
			_source.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}


		/**
		 * @copy mx.collections.ArrayList#addItem()
		 */
		public function addItem(item : Object) : void
		{
			if (isPersistent)
			{
				_source.addItem(item);
				return;
			}
			_throw("addItem");
		}


		/**
		 * @copy mx.collections.ArrayList#addItemAt()
		 */
		public function addItemAt(item : Object, index : int) : void
		{
			if (isPersistent)
			{
				_source.addItemAt(item, index);
				return;
			}
			_throw("addItemAt");
		}


		/**
		 * @inheritDoc
		 */
		public function dispatchEvent(event : Event) : Boolean
		{
			return _source.dispatchEvent(event);
		}


		/**
		 * @inheritDoc
		 */
		public function getItemAt(index : int, prefetch : int = 0) : Object
		{
			_transformOne(index, true);
			return _source.getItemAt(index, prefetch);
		}


		/**
		 * @inheritDoc
		 */
		public function getItemIndex(item : Object) : int
		{
			var orm : ORM, i : int, len : int = length, other : ORM = item as ORM;
			if (!other.primaryKeyValue)
			{
				return -1;
			}
			for (i = 0; i < len; i++)
			{
				orm = _transformOne(i, false);
				if (orm.isSameAs(other))
				{
					return i;
				}
			}
			return -1;
		}


		/**
		 * @inheritDoc
		 */
		public function hasEventListener(type : String) : Boolean
		{
			return _source.hasEventListener(type);
		}


		/**
		 * @copy IORMIterator#isPersistent
		 */
		public function get isPersistent() : Boolean
		{
			return false;
		}


		/**
		 * @copy mx.collections.ArrayList#itemUpdated
		 */
		public function itemUpdated(item : Object, property : Object = null,
				oldValue : Object = null,
				newValue : Object = null) : void
		{
			_source.itemUpdated(item, property, oldValue, newValue);
		}


		/**
		 *  @copy mx.collections.ArrayList#length
		 */
		public function get length() : int
		{
			return _source.length;
		}


		/**
		 * @inheritDoc
		 */
		public function get ormClass() : Class
		{
			return _ormClass;
		}


		/**
		 * @copy mx.collections.ArrayList#readExternal()
		 */
		public function readExternal(input : IDataInput) : void
		{
			_source.source = (input.readObject() as Array);
			_ormClass = (getDefinitionByName(input.readObject() as String) as Class);
		}


		/**
		 * @copy mx.collections.ArrayList#removeAll()
		 */
		public function removeAll() : void
		{
			if (isPersistent)
			{
				_source.removeAll();
				return;
			}
			_throw("removeAll");
		}


		/**
		 * @inheritDoc
		 */
		public function removeEventListener(type : String, listener : Function, useCapture : Boolean
				= false) : void
		{
			_source.removeEventListener(type, listener, useCapture);
		}


		/**
		 * @copy mx.collections.ArrayList#removeItem()
		 */
		public function removeItem(item : Object) : Boolean
		{
			if (isPersistent)
			{
				return _source.removeItem(item);
			}
			return _throw("removeItem");
		}


		/**
		 * @copy mx.collections.ArrayList#removeItemAt()
		 */
		public function removeItemAt(index : int) : Object
		{
			if (isPersistent)
			{
				return _source.removeItemAt(index);
			}
			return _throw("removeItemAt");
		}


		/**
		 * @copy mx.collections.ArrayList#setItemAt()
		 */
		public function setItemAt(item : Object, index : int) : Object
		{
			if (isPersistent)
			{
				return _source.setItemAt(item, index);
			}
			return _throw("setItemAt");
		}


		/**
		 * @inheritDoc
		 */
		public function toArray() : Array
		{
			_transformAll();
			return _source.toArray();
		}


		/**
		 * @inheritDoc
		 */
		public function toArrayOfResultObjects() : Array
		{
			var i : int, len : int = _source.length, res : Array = new Array(), o : Object;
			for (i = 0; i < len; i++)
			{
				o = _source.source[i];
				if (o is ORM)
				{
					o = (o as ORM).toResultObject();
				}
				res.push(o);
			}
			return res;
		}


		/**
		 * @copy mx.collections.ArrayList#toString()
		 */
		public function toString() : String
		{
			return _source.toString();
		}


		/**
		 * @copy mx.collections.ArrayList#uid
		 */
		public function get uid() : String
		{
			return _source.uid;
		}


		public function set uid(value : String) : void
		{
			_source.uid = value;
		}


		/**
		 * @inheritDoc
		 */
		public function willTrigger(type : String) : Boolean
		{
			return _source.willTrigger(type);
		}


		/**
		 * @copy mx.collections.ArrayList#writeExternal()
		 */
		public function writeExternal(output : IDataOutput) : void
		{
			output.writeObject(toArrayOfResultObjects());
			output.writeObject(getQualifiedClassName(_ormClass));
		}


		/**
		 * Checks the validity of a given index
		 *
		 * @param index The index to check if in the bounds of the source array
		 * @param validIndexIncludeLength If true, the length is accepted as a valid index even if
		 * a valid index stops normally at length-1
		 */
		protected function _checkIndex(index : int, validIndexIncludeLength : Boolean = false) : void
		{
			if (index < 0 || index >= length - (validIndexIncludeLength ? 1 : 0))
			{
				var message : String = resourceManager.getString(
						"collections", "outOfBounds", [index]);
				throw new RangeError(message);
			}
		}


		/**
		 * Transform all items to ORM instances
		 */
		protected function _transformAll() : void
		{
			var i : int, len : int = _source.length;
			for (i = 0; i < len; i++)
			{
				_transformOne(i, false);
			}
		}


		/**
		 * Transforms one item to an ORM object if not done already
		 *
		 * @param index The index of the item to transform
		 * @return The ORM object corresponding
		 */
		protected function _transformOne(index : int, checkIndex : Boolean = true) : ORM
		{
			var res : ORM, o : Object;
			if (checkIndex)
			{
				_checkIndex(index);
			}
			if ((o = _source.source[index]) is ORM)
			{
				return o as ORM;
			}
			res = new ormClass();
			res.loadWithResult(o);
			_source.source[index] = res;
			return res;
		}


		flash_proxy override function callProperty(name : *, ... parameters) : *
		{
			_throw(name);
		}


		flash_proxy override function deleteProperty(name : *) : Boolean
		{
			removeItemAt(_checkProperty(name));
			return true;
		}


		flash_proxy override function getProperty(name : *) : *
		{
			return getItemAt(_checkProperty(name));
		}


		flash_proxy override function hasProperty(name : *) : Boolean
		{
			var i : int = _checkProperty(name);
			return (i >= 0 && i < length);
		}


		flash_proxy override function nextName(index : int) : String
		{
			return String(index - 1);
		}


		flash_proxy override function nextNameIndex(index : int) : int
		{
			if (index <= length)
			{
				return index;
			}
			return 0;
		}


		flash_proxy override function nextValue(index : int) : *
		{
			return getItemAt(index - 1);
		}


		flash_proxy override function setProperty(name : *, value : *) : void
		{
			setItemAt(value, _checkProperty(name));
		}


		private function _checkProperty(name : *) : int
		{
			if (!(name as String).match(_propertyRegexp))
			{
				throw new IllegalOperationError("Trying to access unknown property '" + name + "' on a '"
						+ getQualifiedClassName(this) + "'");
			}
			return parseInt(name, 10);
		}


		/**
		 * Internal method to throw an exception when trying to use a not supported method
		 */
		private function _throw(method : String) : Object
		{
			throw new IllegalOperationError("The '" + getQualifiedClassName(this) + "' class doesn't support the method '"
					+ method
					+ "'");
			return null;
		}
	}
}
