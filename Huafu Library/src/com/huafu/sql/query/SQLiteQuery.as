package com.huafu.sql.query
{
	import com.huafu.sql.SQLiteConnection;
	import com.huafu.sql.SQLiteStatement;
	import com.huafu.utils.reflection.ReflectionClass;
	
	import flash.data.SQLResult;
	
	public class SQLiteQuery
	{
		internal var fieldList : Array;
		internal var tableList : Array;
		internal var conditions : SQLiteConditionGroup;
		internal var groupByList : Array;
		internal var orderByList : Array;
		internal var havings : SQLiteConditionGroup;
		internal var limitCount : int;
		internal var limitOffset : int;
		
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
			_add(fields, fieldList);
			return this;
		}
		
		
		public function from( ... tables : Array ) : SQLiteQuery
		{
			_add(tables, tableList);
			return this;
		}
		
		
		public function where( ... conditions : Array ) : SQLiteQuery
		{
			_where(this.conditions, SQLiteConditionGroup.AND, conditions);
			return this;
		}
		
		
		public function andWhere( ... conditions : Array ) : SQLiteQuery
		{
			_where(this.conditions, SQLiteConditionGroup.AND, conditions);
			return this;
		}
		
		
		public function orWhere( ... conditions : Array ) : SQLiteQuery
		{
			_where(this.conditions, SQLiteConditionGroup.OR, conditions);
			return this;
		}
		
		
		public function having( ... conditions : Array ) : SQLiteQuery
		{
			_where(havings, SQLiteConditionGroup.AND, conditions);
			return this;
		}
		
		
		public function andHaving( ... conditions : Array ) : SQLiteQuery
		{
			_where(havings, SQLiteConditionGroup.AND, conditions);
			return this;
		}
		
		
		public function orHaving( ... conditions : Array ) : SQLiteQuery
		{
			_where(havings, SQLiteConditionGroup.OR, conditions);
			return this;
		}
		
		
		public function orderBy( ... fields : Array ) : SQLiteQuery
		{
			var field : *, name : String;
			if ( fields.length == 1 && fields[0] is Array )
			{
				fields = fields[0];
			}
			for each ( field in fields )
			{
				if ( ReflectionClass.isStrictly(field, Object) )
				{
					for ( name in field )
					{
						if ( field[name].match(/^\s*desc\s*$/i) )
						{
							orderByList.push(name + " DESC");
						}
						else
						{
							orderByList.push(name + " ASC");
						}
					}
				}
				else
				{
					orderByList.push(field);
				}
			}
			return this;
		}
		
		
		public function groupBy( ... fields : Array ) : SQLiteQuery
		{
			var field : *;
			if ( fields.length == 1 && fields[0] is Array )
			{
				fields = fields[0];
			}
			groupByList.push.apply(groupByList, fields);
			return this;
		}
		
		
		public function limit( count : int, offset : int = 0 ) : SQLiteQuery
		{
			limitCount = count;
			limitOffset = offset;
			return this;
		}
		
		
		public function compile() : SQLiteStatement
		{
			var params : SQLiteParameters = new SQLiteParameters,
				res : SQLiteStatement = connection.createStatement();
			res.text = sqlCode(params);
			params.bindTo(res);
			return res;
		}
		
		
		public function sqlCode( parametersDestination : SQLiteParameters = null ) : String
		{
			var sql : String;
			sql = "SELECT " + (fieldList.length == 0 ? "*" : fieldList.join(", ")) + " FROM " + tableList.join(", ");
			if ( conditions.length > 0 )
			{
				sql += " WHERE " + conditions.sqlCode(parametersDestination);
			}
			if ( groupByList.length > 0 )
			{
				sql += " GROUP BY " + groupByList.join(", ");
			}
			if ( havings.length > 0 )
			{
				sql += " HAVING " + havings.sqlCode(parametersDestination);
			}
			if ( orderByList.length > 0 )
			{
				sql += " ORDER BY " + orderByList.join(", ");
			}
			if ( limitCount )
			{
				sql += " LIMIT " + limitCount;
				if ( limitOffset )
				{
					sql += ", " + limitOffset;
				}
			}
			return sql;
		}
		
		
		public function get() : Array
		{
			var stmt : SQLiteStatement = compile();
			stmt.safeExecute();
			return stmt.getResult().data;
		}
		
		
		private function _where( which : SQLiteConditionGroup, logicOp : String, conditions : Array ) : void
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
					for ( name in condition )
					{
						parts = name.match(/^\s*([a-z0-9_]+)\s*([=\!\<\>]{1,2})?$/i);
						if ( parts[2] == undefined )
						{
							parts[2] = "=";
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
			fieldList = new Array();
			tableList = new Array();
			conditions.reset();
			groupByList = new Array();
			orderByList = new Array();
			limitCount = 0;
			limitOffset = 0;
			havings.reset();
			return this;
		}
	}
}