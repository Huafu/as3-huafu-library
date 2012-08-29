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
		internal var _fieldList : Array;
		/**
		 * List of tables
		 */
		internal var _tableList : Array;
		/**
		 * The conditions for the where part
		 */
		internal var _conditions : SQLiteConditionGroup;
		/**
		 * The list of group by
		 */
		internal var _groupByList : Array;
		/**
		 * THe list of order by
		 */
		internal var _orderByList : Array;
		/**
		 * The conditions of the having part
		 */
		internal var _havings : SQLiteConditionGroup;
		/**
		 * The limit part
		 */
		internal var _limitCount : int;
		/**
		 * The offset part
		 */
		internal var _limitOffset : int;
		/**
		 * Stores whether the last function call was related to having or to where
		 */
		internal var _inHaving : Boolean;
		/**
		 * The comment prepending any query
		 */
		internal var _prependingComment : String;
		/**
		 * Whether to use cached statements or not
		 */
		internal var _useCachedStatements : Boolean;
		/**
		 * The statement if compiled and nothing changed
		 */
		internal var _statement : SQLiteStatement;
		
		/**
		 * The connection used to execute the query
		 */
		public var connection : SQLiteConnection;
		
		
		/**
		 * Creates a new query object
		 * 
		 * @param connection The SQL connection to use when executing the query
		 * @param useCachedStatements Whether to use cached statements or not
		 * @param prependQueriesWithComment If given, the string will be put in a comment before each statemetns
		 */
		public function SQLiteQuery( connection : SQLiteConnection = null, useCachedStatements : Boolean = false, prependQueriesWithComment : String = null )
		{
			this.connection = connection;
			_conditions = new SQLiteConditionGroup();
			_havings = new SQLiteConditionGroup();
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
			_add(fields, _fieldList);
			_statement = null;
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
			_add(tables, _tableList);
			_statement = null;
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
			_inHaving = false;
			_where(this._conditions, SQLiteConditionGroup.AND, conditions);
			_statement = null;
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
			_inHaving = false;
			_where(this._conditions, SQLiteConditionGroup.AND, conditions);
			_statement = null;
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
			_inHaving = false;
			_where(this._conditions, SQLiteConditionGroup.OR, conditions);
			_statement = null;
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
			_inHaving = true;
			_where(_havings, SQLiteConditionGroup.AND, conditions);
			_statement = null;
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
			_inHaving = true;
			_where(_havings, SQLiteConditionGroup.AND, conditions);
			_statement = null;
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
			_inHaving = true;
			_where(_havings, SQLiteConditionGroup.OR, conditions);
			_statement = null;
			return this;
		}
		
		
		/**
		 * Open a parenthesis while in where or having parts
		 * 
		 * @param logicOperator If there is already one or more conditions, this logic operator
		 * will be used to aggregate the block
		 * @return Returns this object to do chained calls
		 */
		public function openBracket( logicOperator : String = SQLiteConditionGroup.AND ) : SQLiteQuery
		{
			var group : SQLiteConditionGroup = new SQLiteConditionGroup();
			if ( _inHaving )
			{
				_havings.add(group, logicOperator);
				_havings = group;
			}
			else
			{
				_conditions.add(group, logicOperator);
				_conditions = group;
			}
			_statement = null;
			return this;
		}
		
		
		/**
		 * Close a previously opened parenthesis withing a having or whre clause
		 * 
		 * @return Returns this object to do chained calls
		 */
		public function closeBracket() : SQLiteQuery
		{
			if ( _inHaving )
			{
				_havings = _havings.ownerGroup;
			}
			else
			{
				_conditions = _conditions.ownerGroup;
			}
			_statement = null;
			return this;
		}
		
		
		/**
		 * Add one or more order by instruction
		 * 
		 * @param fields Fields to order by, as many as needed, or an array of them.
		 * Each paraemter or element of the array must be a string corresponding to
		 * the SQL code of the order by, or an object with property names as field
		 * to order to and property values as the direction (asc/desc)
		 * @return Returns this object to do chained calls
		 */
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
							_orderByList.push(name + " DESC");
						}
						else
						{
							_orderByList.push(name + " ASC");
						}
					}
				}
				else
				{
					_orderByList.push(field);
				}
			}
			_statement = null;
			return this;
		}
		
		
		/**
		 * Add one or more group by instruction
		 * 
		 * @param fields Fields to group by, as many as needed, or an array of them.
		 * Each paraemter or element of the array must be a string corresponding to
		 * the SQL code of the group by
		 * @return Returns this object to do chained calls
		 */
		public function groupBy( ... fields : Array ) : SQLiteQuery
		{
			var field : *;
			if ( fields.length == 1 && fields[0] is Array )
			{
				fields = fields[0];
			}
			_groupByList.push.apply(_groupByList, fields);
			_statement = null;
			return this;
		}
		
		
		/**
		 * Set the limits of record and optional offset
		 * 
		 * @param count The maximum of records to get
		 * @param offset The first record to get in the results
		 * @return Returns this object to do chained calls
		 */
		public function limit( count : int, offset : int = 0 ) : SQLiteQuery
		{
			_limitCount = count;
			_limitOffset = offset;
			return this;
		}
		
		
		/**
		 * Creates the statement and bind parameeters that can be used to execute the query
		 * 
		 * @return The statement object, ready to be executed
		 */
		public function compile() : SQLiteStatement
		{
			var params : SQLiteParameters = new SQLiteParameters,
				sql : String = sqlCode(params);
			if ( !_statement )
			{
				_statement = connection.createStatement(sql, !_useCachedStatements);
			}
			_statement.clearParameters();
			if ( _limitCount )
			{
				params.bind(_limitCount);
				if ( _limitOffset )
				{
					params.bind(_limitOffset);
				}
			}
			params.bindTo(_statement);
			return _statement;
		}
		
		
		/**
		 * Get the SQL code of the query, optionally binding parameters to the
		 * given parameters object
		 * 
		 * @param parametersDestination Where to bind the parameters to if any
		 * @return The SQL code of the query
		 */
		public function sqlCode( parametersDestination : SQLiteParameters = null ) : String
		{
			var sql : String;
			sql = "SELECT " + (_fieldList.length == 0 ? "*" : _fieldList.join(", ")) + " FROM " + _tableList.join(", ");
			if ( _conditions.length > 0 )
			{
				sql += " WHERE " + _conditions.sqlCode(parametersDestination);
			}
			if ( _groupByList.length > 0 )
			{
				sql += " GROUP BY " + _groupByList.join(", ");
			}
			if ( _havings.length > 0 )
			{
				sql += " HAVING " + _havings.sqlCode(parametersDestination);
			}
			if ( _orderByList.length > 0 )
			{
				sql += " ORDER BY " + _orderByList.join(", ");
			}
			if ( _limitCount )
			{
				sql += " LIMIT ?";
				if ( _limitOffset )
				{
					sql += ", ?";
				}
			}
			if ( _prependingComment )
			{
				sql = "/* " + _prependingComment + " */ " + sql;
			}
			return sql;
		}
		
		
		/**
		 * Compile, execute and get the results of the query
		 * 
		 * @return The array of all results
		 */
		public function get() : Array
		{
			var stmt : SQLiteStatement = compile();
			stmt.safeExecute();
			return stmt.getResult().data;
		}
		
		
		/**
		 * Reset the query
		 * 
		 * @return Returns this object to do chained calls
		 */
		public function reset() : SQLiteQuery
		{
			_fieldList = new Array();
			_tableList = new Array();
			_conditions.reset();
			_groupByList = new Array();
			_orderByList = new Array();
			_limitCount = 0;
			_limitOffset = 0;
			_havings.reset();
			_statement = null;
			_inHaving = false;
			return this;
		}
		
		
		/**
		 * Add where conditions in a given condition group with the given logic operator
		 */
		private function _where( which : SQLiteConditionGroup, logicOp : String, conditions : Array ) : void
		{
			var condition : *, name : String, parts : Array;
			if ( conditions.length == 1 && conditions[0] is Array )
			{
				conditions = conditions[0];
			}
			for each ( condition in conditions )
			{
				// jump on empty conditions
				if ( !condition || condition == "" )
				{
					continue;
				}
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
		
		
		/**
		 * Add columns or tables to the given list
		 */
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