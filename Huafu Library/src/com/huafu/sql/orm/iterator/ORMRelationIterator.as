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
	import com.huafu.sql.orm.relation.IORMRelation;


	/**
	 * Handles iterator of relations to reflect changes in the database
	 */
	public class ORMRelationIterator extends ORMIterator implements IORMIterator
	{

		/**
		 * Builds a new iterator for a relation of a given orm object
		 */
		public function ORMRelationIterator(ormClass : Class = null, source : Array = null, ownerOrmObject : ORM
				= null, relation : IORMRelation = null)
		{
			super(ormClass, source);
			_otherLoadedData = new Array();
			_ownerOrmObject = ownerOrmObject;
			_relation = relation;
		}


		private var _otherLoadedData : Array;


		private var _ownerOrmObject : ORM;


		private var _relation : IORMRelation;


		/**
		 * @inheritDoc
		 */
		override public function addItemAt(item : Object, index : int) : void
		{
			var data : Object = {};
			_checkIndex(index);
			if (_relation.addForeignItem(_ownerOrmObject, item as ORM, data))
			{
				super.addItemAt(item, index);
				_otherLoadedData[index] = data;
			}
		}


		/**
		 * @inheritDoc
		 */
		override public function get isPersistent() : Boolean
		{
			return true;
		}


		/**
		 * @inheritDoc
		 */
		override public function get ormClass() : Class
		{
			return _relation.foreignOrmClass;
		}


		/**
		 * The ORM object owning this iterator
		 */
		public function get owner() : ORM
		{
			return _ownerOrmObject;
		}


		/**
		 * Used internally to set the owner ORM object after instanciation
		 */
		public function set ownerOrmObject(value : ORM) : void
		{
			_ownerOrmObject = value;
		}


		/**
		 * Used internally to setup the relation after instanciating
		 */
		public function set relation(value : IORMRelation) : void
		{
			_relation = value;
		}


		/**
		 * @inheritDoc
		 */
		override public function removeAll() : void
		{
			if (_relation.removeAllForeignItems(_ownerOrmObject))
			{
				super.removeAll();
			}
		}


		/**
		 * @inheritDoc
		 */
		override public function removeItemAt(index : int) : Object
		{
			_checkIndex(index, true);
			if (_relation.removeForeignItem(_ownerOrmObject, _transformOne(index), _otherLoadedData[index]))
			{
				_otherLoadedData.splice(index, 1);
				return super.removeItemAt(index);
			}
			return null;
		}


		/**
		 * @inheritDoc
		 */
		override public function setItemAt(item : Object, index : int) : Object
		{
			var oldItem : ORM = _transformOne(index, true), data : Object = {};
			if (_relation.replaceForeignItem(_ownerOrmObject, oldItem, _otherLoadedData[index], item
					as ORM, data))
			{
				_otherLoadedData[index] = data;
				return super.setItemAt(item, index);
			}
			return null;
		}


		/**
		 * @inheritDoc
		 */
		override public function toArrayOfResultObjects() : Array
		{
			var i : int, len : int = _source.length, res : Array = new Array(), o : Object, n : String;
			for (i = 0; i < len; i++)
			{
				o = _source.source[i];
				if (o is ORM)
				{
					o = (o as ORM).toResultObject();
					for (n in _otherLoadedData[i])
					{
						o[n] = _otherLoadedData[i][n];
					}
				}
				res.push(o);
			}
			return res;
		}


		/**
		 * @inheritDoc
		 */
		override protected function _transformOne(index : int, checkIndex : Boolean = true) : ORM
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
			_otherLoadedData[index] = res.loadWithResult(o);
			_source.source[index] = res;
			return res;
		}
	}
}
