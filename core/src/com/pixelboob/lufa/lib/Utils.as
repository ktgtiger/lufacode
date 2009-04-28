package com.pixelboob.lufa.lib {	import com.pixelboob.lufa.LuaFunction;	import com.pixelboob.lufa.Table;				/**	 * @author mikej	 */	public class Utils 	{				[LufaMethod(methodName="print")]		public static function lufa_print(args:Array):void		{			print(args);		}				[LufaMethod(methodName="type")]		public static function lufa_type(args:Array):Array		{			return [type(args[0])];		}						public static function print(args:Array):void		{			var out : Array = [];			for each(var arg : Object in args)			{				if(arg is Table)				{					// TODO : Typically this would print the address of the dictionary, which we don't have ;)					out.push("table: "+(arg as Table));				}				else if(arg is String || arg is Boolean || arg is Number)				{					out.push(arg);				}				else				{					out.push(arg);				}			}						trace(out.join("\t"));		}						public static function type(object:Object):String		{			if(object == null)			{				return "nil";			}			else if(object is Number)			{				return "number";			}			else if(object is String)			{				return "string";			}			else if(object is Table)			{				return "table";			}			else if(object is Boolean)			{				return "boolean";			}			else if(object is LuaFunction || object is Function)			{				return "function";			}						return "unknown";		}	}}