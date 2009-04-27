package com.pixelboob.lufa {	/**	 * @author moj	 */	public class Instruction 	{				public static var MOVE : uint = 0;		public static var LOADK : uint = 1;		public static var LOADBOOL : uint = 2;		public static var LOADNIL : uint = 3;		public static var GETUPVAL : uint = 4;		public static var GETGLOBAL : uint = 5;		public static var GETTABLE : uint = 6;		public static var SETGLOBAL : uint = 7;		public static var SETUPVAL : uint = 8;		public static var SETTABLE : uint = 9;		public static var NEWTABLE : uint = 10;		public static var SELF : uint = 11;		public static var ADD : uint = 12;		public static var SUB : uint = 13;		public static var MUL : uint = 14;		public static var DIV : uint = 15;		public static var MOD : uint = 16;		public static var POW : uint = 17;		public static var UNM : uint = 18;		public static var NOT : uint = 19;		public static var LEN : uint = 20;		public static var CONCAT : uint = 21;		public static var JMP : uint = 22;		public static var EQ : uint = 23;		public static var LT : uint = 24;		public static var LE : uint = 25;		public static var TEST : uint = 26;		public static var TESTSET : uint = 27;		public static var CALL : uint = 28;		public static var TAILCALL : uint = 29;		public static var RETURN : uint = 30;		public static var FORLOOP : uint = 31;		public static var FORPREP : uint = 32;		public static var TFORLOOP : uint = 33;		public static var SETLIST : uint = 34;		public static var CLOSE : uint = 35;		public static var CLOSURE : uint = 36;		public static var VARARG : uint = 37;				private var _a:int;		private var _b:int;		private var _c:int;		private var _opcode : uint;		public static function fromBytes(bytes : LuaByteArray) : Object		{			var result : Instruction = new Instruction();						var instruction : int = bytes.readInteger();					/*	var instruction : int;			for(var i : uint = 0;i < 4; i++)			{				instruction = instruction | (bytes.readByte() << (i * 8)); 			}		*/				var opcode : uint = instruction & 0x3F;			instruction = instruction >> 6;						var a : uint = instruction & 0xFF; 			instruction = instruction >> 8;					result.opcode = opcode;			result.a = a;					switch(opcode)			{								case LOADK:				case GETGLOBAL:				case SETGLOBAL:				case CLOSURE:					result.b = instruction & 0x3FFFF;//					trace("Inst: "+instruction+" a="+result.a+" b="+result.b);					break;									case MOVE: // A B C				case LEN:				case SETUPVAL:				case GETUPVAL:				case VARARG:				case CLOSE:				case LOADBOOL:				case LOADNIL:				case GETTABLE:				case SETTABLE:				case RETURN:				case UNM:				case NOT:				case ADD:				case SUB:				case MUL:				case DIV:				case MOD:				case POW:				case CONCAT:				case CALL:				case TAILCALL:				case SELF:				case EQ:				case LT:				case LE:				case TEST:				case TESTSET:				case TFORLOOP:				case NEWTABLE:				case SETLIST:					result.c = instruction & 0x1FF;					instruction = instruction >> 9;					result.b = instruction & 0x1FF;					//					trace("Inst: "+instruction+" a="+result.a+" b="+result.b+" c="+result.c);					break;				case JMP:	// Signed B				case FORPREP:				case FORLOOP:				//					trace("Inst: "+instruction+" a="+result.a+" b="+result.b);					result.b = instruction & 0x3FFFF;					result.b -= 131071;					break;			}					return result;		}				public function get a() : int		{			return _a;		}				public function set a(a : int) : void		{			_a = a;		}				public function get b() : int		{			return _b;		}				public function set b(b : int) : void		{			_b = b;		}				public function get c() : int		{			return _c;		}				public function set c(c : int) : void		{			_c = c;		}				public function get opcode() : uint		{			return _opcode;		}				public function set opcode(opcode : uint) : void		{			_opcode = opcode;		}	}}