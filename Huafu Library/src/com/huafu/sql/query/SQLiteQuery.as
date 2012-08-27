package com.huafu.sql.query
{
	import com.huafu.sql.SQLiteConnection;
	import com.huafu.utils.reflection.ReflectionClass;
	
	public class SQLiteQuery
	{
		internal var fields : Array;
		internal var tables : Array;
		internal var conditions : SQLiteConditionGroup;
		internal var groupBy : Array;
		internal var orderBy : Array;
		internal var havings : SQLiteConditionGroup;
		
		public var connection : SQLiteConnection;
		
		public function SQLiteQuery( connection : SQLiteConnection )
		{
			this.connection = connection;
			conditions = new SQLiteConditionGroup();
			havings = new SQLiteConditionGroup();
			reset();
		}
		
		
		public function select( ... fields : Array ) : SQLiteQuery
		{
			_add(fields, this.fields);
			return this;
		}
		
		
		public function from( ... tables : Array ) : SQLiteQuery
		{
			_add(tables, this.tables);
			return this;
		}
		
		
		public function where( ... conditions : Array ) : SQLiteQuery
		{
			_where(this.conditions, SQLiteConditionGroup.AND);
			return this;
		}
		
		
		public function andWhere( ... conditions : Array ) : SQLiteQuery
		{
			_where(this.conditions, SQLiteConditionGroup.AND);
			return this;
		}
		
		
		public function orWhere( ... conditions : Array ) : SQLiteQuery
		{
			_where(this.conditions, SQLiteConditionGroup.OR);
			return this;
		}
		
		
		public function having( ... conditions : Array ) : SQLiteQuery
		{
			_where(havings, SQLiteConditionGroup.AND);
			return this;
		}
		
		
		public function andHaving( ... conditions : Array ) : SQLiteQuery
		{
			_where(havings, SQLiteConditionGroup.AND);
			return this;
		}
		
		
		public function orHaving( ... conditions : Array ) : SQLiteQuery
		{
			_where(havings, SQLiteConditionGroup.OR);
			return this;
		}
		
		
		private function _where( which : SQLiteConditionGroup, logicOp : String, ... conditions : Array ) : void
		{
			var condition : *, name : String, parts : Array;
			if ( conditions.length == 1 && conditions[0] is Array )
			{
				conditions = conditions[0];
			}
			for each ( condition in conditions )
			{
				if ( ReflectionClass.isStrictly(condition, Object) )
				{
					for each ( name in condition )
					{
						parts = name.match(/^\s*([a-z0-9_]+)\s*([=\!\<\>]{1,2})?$/i);
						if ( parts.length == 2 )
						{
							parts.push("=");
						}
						condition = new SQLiteCondition(parts[1] + " " + parts[2] + " ?", condition[name]);
						which.add(condition, logicOp);
					}
				}
				else
				{
					which.add(condition, logicOp);
				}
			}
		}
		
		
		private function _add( data : Array, destination : Array ) : void
		{
			var thing : *, name : String;
			if ( data.length == 1 && data[0] is Array )
			{
				data = data[0];
			}
			for each ( thing in data )
			{
				if ( thing is String )
				{
					destination.push(thing);
				}
				else if ( thing is Object )
				{
					for ( name in thing )
					{
						destination.push(thing[name] + " AS " + name);
					}
				}
			}
		}
		
		
		public function reset() : SQLiteQuery
		{
			fields = new Array();
			tables = new Array();
			conditions.reset();
			groupBy = new Array();
			orderBy = new Array();
			havings.reset();
			return this;
		}
	}
}