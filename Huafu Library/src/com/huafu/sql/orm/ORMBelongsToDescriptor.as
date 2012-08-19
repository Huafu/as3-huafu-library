package com.huafu.sql.orm
{
	/**
	 * Handles a "belongs to" ORM relation on an ORM property (which is basically the same as "has many")
	 * @see ORMHasManyDescriptor
	 */
	public class ORMBelongsToDescriptor extends ORMHasManyDescriptor implements IORMRelationDescriptor
	{
		/**
		 * Creates a new has many relation descriptor
		 * 
		 * @param ormDescriptor The ORM descriptor that holds the property corresponding to a relation
		 * @param propertyName The property name in the owner descriptor
		 * @param relatedClass The class of the related ORM
		 * @param realtedColumnName The name of the column in the related table
		 */
		public function ORMBelongsToDescriptor(ormDescriptor:ORMDescriptor, propertyName:String, relatedClass:Class, relatedColumnName:String)
		{
			super(ormDescriptor, propertyName, relatedClass, relatedColumnName);
		}
	}
}