package com.huafu.sql.query
{
	import com.huafu.sql.SQLiteConnection;
	import com.huafu.sql.SQLiteStatement;
	import com.huafu.utils.reflection.ReflectionClass;
	
	import flash.data.SQLResult;
	
	
	/**
	 * Helper to build SQL queries
	 * @example
	 * <listing version="3.0">
	 * 	var query :SQLiteQuery = new SQLiteQuery(theConnection);
	 * 	var results : Array;
	 * results = query.select("name", {firstName: "first_name", lastName: "UPPER(last_name)"})
	 * 		.from("user", {AnotherTable: "the_name"})
	 * 		.where("id = 2")
	 * 		.openBracket(SQLiteConditionGroup.OR)
	 * 			.where({id: 5})
	 * 			.orWhere({"age >=": 10})
	 * 		.closeBracket()
	 * 		.orderBy("name ASC", {age: "DESC"})
	 * 		.limit(10)
	 * 		.get();
	 * </listing>
	 */
	public class SQLiteQuery
	{
		/**
		 * List of fields
		 */
		internal var fieldList : Array;
		/**
		 * List of tables
		 */
		internal var tableList : Array;
		/**
		 * The conditions for the where part
		 */
		internal var conditions : SQLiteConditionGroup;
		/**
		 * The list of group by
		 */
		internal var groupByList : Array;
		/**
		 * THe list of order by
		 */
		internal var orderByList : Array;
		/**
		 * The conditions of the having part
		 */
		internal var havings : SQLiteConditionGroup;
		/**
		 * The limit part
		 */
		internal var limitCount : int;
		/**
		 * The offset part
		 */
		internal var limitOffset : int;
		/**
		 * Stores whether the last function call was related to having or to where
		 */
		internal var inHaving : Boolean;
		
		/**
		 * The connection used to execute the query
		 */
		public var connection : SQLiteConnection;
		
		
		/**
		 * Creates a new query object
		 * 
		 * @param connection The SQL connection to use when executing the query
		 */
		public function SQLiteQuery( connection : SQLiteConnection = null )
		{
			this.connection = connection;
			conditions = new SQLiteConditionGroup();
			havings = new SQLiteConditionGroup();
			reset();
		}
		
		
		/**
		 * Add field(s) to the select part
		 * 
		 * @param fields Any amount of fields or an array containing the fields. Each parameter (or item in the array)
		 * can be a string with the SQL code of the field or an object with each property name as the alias and the value as
		 * the SQL code for that alias
		 * @return Returns this object to do chained calls
		 */
		public function select( ... fields : Array ) : SQLiteQuery
		{
			_add(fields, fieldList);
			return this;
		}
		
		
		/**
		 * Add table(s) to the list of tables to select from
		 * 
		 * @param tables The table(s) to add (see #select() method to see what parameters can be sent)
		 * @return Returns this object to do chained calls
		 */
		public function from( ... tables : Array ) : SQLiteQuery
		{
			_add(tables, tableList);
			return this;
		}
		
		/**
		 * Add conditions to the where clause
		 * 
		 * @param conditions The conditions
		 * @return Returns this object to do chained calls
		 * @see #andWhere
		 */
		public function where( ... conditions : Array ) : SQLiteQuery
		{
			inHaving = false;
			_where(this.conditions, SQLiteConditionGroup.AND, conditions);
			return this;
		}
		
		
		/**
		 * Add conditions to the where clause with the AND logic operator
		 * 
		 * @param conditions Any amount of conditions or an array with all conditions to add
		 * each parameter or item in the array should be a SQLiteCondition object
		 * or a SQLiteConditionGroup object, or the string of the condition,
		 * or an object where each property name is the name of the column and
		 * the value is the value it has to be equal (for other operators, add them at the end
		 * of the name of the property
		 * @return Returns this object to do chained calls
		 */
		public function andWhere( ... conditions : Array ) : SQLiteQuery
		{
			inHaving = false;
			_where(this.conditions, SQLiteConditionGroup.AND, conditions);
			return this;
		}
		
		
		/**
		 * Add conditions to the where clause with the OR logic operator
		 * 
		 * @param conditions The conditions to add
		 * @return Returns this object to do chained calls
		 * @see #andWhere
		 */
		public function orWhere( ... conditions : Array ) : SQLiteQuery
		{
			inHaving = false;
			_where(this.conditions, SQLiteConditionGroup.OR, conditions);
			return this;
		}
		
		
		/**
		 * Add conditions to the having clause with the AND logic operator
		 * 
		 * @param conditions the conditions
		 * @return Returns this object to do chained calls
		 * @see #andWhere
		 */
		public function having( ... conditions : Array ) : SQLiteQuery
		{
			inHaving = true;
			_where(havings, SQLiteConditionGroup.AND, conditions);
			return this;
		}
		
		
		/**
		 * Add conditions to the having clause with the AND logic operator
		 * 
		 * @param conditions the conditions
		 * @return Returns this object to do chained calls
		 * @see #andWhere
		 */
		public function andHaving( ... conditions : Array ) : SQLiteQuery
		{
			inHaving = true;
			_where(havings, SQLiteConditionGroup.AND, conditions);
			return this;
		}
		
		
		/**
		 * Add conditions to the having clause with the OR logic operator
		 * 
		 * @param conditions the conditions
		 * @return Returns this object to do chained calls
		 * @see #andWhere
		 */
		public function orHaving( ... conditions : Array ) : SQLiteQuery
		{
			inHaving = true;
			_where(havings, SQLiteConditionGroup.OR, conditions);
			return this;
		}
		
		
		public function openBraket( logicOperator : String = SQLiteConditionGroup.AND ) : SQLiteQuery
		{
			var group : SQLiteConditionGroup = new SQLiteConditionGroup();
			if ( inHaving )
			{
				havings.add(group, logicOperator);
				havings = group;
			}
			else
			{
				conditions.add(group, logicOperator);
				conditions = group;
			}
			return this;
		}
		
		
		public function closeBracket() : SQLiteQuery
		{
			if ( inHaving )
			{
				havings = havings.ownerGroup;
			}
			else
			{
				conditions = conditions.ownerGroup;
			}
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
			inHaving = false;
			return this;
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
	}
}