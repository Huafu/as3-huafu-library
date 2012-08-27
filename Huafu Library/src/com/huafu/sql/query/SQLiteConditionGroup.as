package com.huafu.sql.query
{
	import mx.collections.ArrayList;

	public class SQLiteConditionGroup
	{
		public static const AND : String = "AND";
		public static const OR : String = "OR";
		public static const AND_NOT : String = "AND NOT";
		public static const OR_NOT : String = "OR NOT";
		
		private var _owner : SQLiteConditionGroup;
		internal var list : Array;
		
		public function SQLiteConditionGroup( owner : SQLiteConditionGroup = null )
		{
			reset();
			_owner = owner;
			
		}
		
		
		public function reset() : void
		{
			list = new Array();
		}
		
		
		public function get length() : int
		{
			var i : int, res : int = 0;
			for ( i = 0; i < list.length; i += 2 )
			{
				if ( list[i] is SQLiteConditionGroup )
				{
					res += (list[i] as SQLiteConditionGroup).length;
				}
				else
				{
					res += 1;
				}
			}
			return res;
		}
		
		public function add( condition : *, logicOperator : String = AND ) : SQLiteConditionGroup
		{
			if ( list.length > 0 )
			{
				list.push(logicOperator);
			}
			if ( condition is SQLiteConditionGroup )
			{
				(condition as SQLiteConditionGroup)._owner = this;
			}
			list.push(SQLiteCondition.cast(condition));
			return this;
		}
		
		
		public function sqlCode( parametersDestination : SQLiteParameters = null ) : String
		{
			var item : *, i : int, res : String = "";
			if ( list.length < 1 )
			{
				return null;
			}
			for ( i = 0; i < list.length; i++ )
			{
				if ( i % 2 == 0 )
				{
					res += (list[i] as SQLiteCondition).sqlCode(parametersDestination);
				}
				else
				{
					res += " " + (list[i] as String) + " ";
				}
			}
			if ( _owner )
			{
				res = "(" + res + ")";
			}
			return res;
		}
	}
}