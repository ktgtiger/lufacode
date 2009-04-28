package com.pixelboob.lufa.lib {	import com.pixelboob.lufa.Table;		import flash.utils.Dictionary;			/**	 * @author mikej	 */	public class MetaTable 	{		[LufaMethod(methodName="rawset")]		public static function lufa_rawset(args:Array):void		{			rawSet(args[0], args[1], args[2]);		}				[LufaMethod(methodName="rawget")]		public static function lufa_rawget(args:Array):Array		{			return [rawGet(args[0], args[1])];		}				[LufaMethod(methodName="setmetatable")]		public static function lufa_setmetatable(args:Array):void		{			setMetaTable(args[0], args[1]);		}				[LufaMethod(methodName="getmetatable")]		public static function lufa_getmetatable(args:Array):Array		{			return [getMetaTable(args[0])];		}				public static function rawGet(table : Table, index : Object) : Object		{			return table[index];		}				public static function rawSet(table : Table, index : Object, value : Object) : void		{			table[index] = value;		}				public static function setMetaTable(table:Table, metatable:Table) : void		{			table["__metatable"] = metatable;		}				public static function getMetaTable(object:Object) : Table		{			if(object is Table)			{				return (object as Table)["__metatable"];			}			else			{				return null;			}		}			}}