package com.pixelboob.lufa {	import flash.events.EventDispatcher;	import flash.events.TimerEvent;	import flash.utils.Dictionary;	import flash.utils.Timer;	import flash.utils.describeType;	import flash.utils.getQualifiedClassName;		/**	 * @author moj	 */	public class Interpreter extends EventDispatcher	{		private var stack : Array;		private var funcs : Array;		private var globals : Dictionary;		private var frame : Frame;		private var func : LuaFunction;		private var timer : Timer;		public function Interpreter()		{			this.timer = new Timer(5);		}		public function run(func : LuaFunction, startPaused : Boolean = false) : void		{			stack = [];			funcs = [];			setupLibraries();			var frame : Frame = new Frame();			stack.push(frame);			funcs.push(func);					if(!startPaused)			{				cont();			}			else			{				step();			}		}		private function setupLibraries() : void		{			globals = new Dictionary();									//		injectClass(AssetLoader);			globals["coroutine"] = {"wrap" : "foo"};			globals["io"] = {"write" : this.write};			globals["print"] = this.write;			globals["string"] = {"format" : this.format};			/*globals["lufa"] = {				"assets" : { "load" : this.loadAsset },				"control" : { "ready" : this.controlReady }			};*/		}		public function cont() : void		{			this.timer.addEventListener(TimerEvent.TIMER, this.handleTick);			this.timer.start();		}		public function pause() : void		{			this.timer.stop();		}		private function handleTick(event : TimerEvent) : void		{			if(funcs.length != 0)			{				this.step();			}			else			{				this.pause();				this.dispatchEvent(new InterpreterEvent(InterpreterEvent.COMPLETE));			}		}		private function injectClass(clazz : Class) : void		{			var qualClassName : String = getQualifiedClassName(clazz);			var pieces : Array = className.split("::");			var packagePath : Array = (pieces[0].split("."));			var className : String = pieces[1];						// Build up the package hierarchy			var currentPos : Dictionary = globals;			for each(var packageElement : String in packagePath)			{				if(!globals[packageElement])				{					globals[packageElement] = new Dictionary;				}				currentPos = globals[packageElement];			}						trace(getQualifiedClassName(clazz));			trace(describeType(clazz));		}		public function step() : void		{			this.frame = (stack[stack.length - 1] as Frame);			this.func = (funcs[funcs.length - 1] as LuaFunction);					var inst : Instruction = func.instructions[frame.pc];					switch(inst.opcode)			{				case Instruction.MOVE:					log("MOVE\t\t\tR[" + inst.a + "] = R[" + inst.b + "]");					frame.vars[inst.a] = frame.vars[inst.b];					break;									case Instruction.LOADK:					log("LOADK\t\t\tR[" + inst.a + "] = " + func.constants[inst.b]);					frame.vars[inst.a] = func.constants[inst.b];					break;									case Instruction.LOADBOOL:					log("LOADBOOL\t\t\tR[" + inst.a + "] = " + inst.b + " (skip flag: " + inst.c + ")");					frame.vars[inst.a] = (inst.b == 1 ? true : false);										// Support the skip flag					if(inst.c != 0)					{						frame.pc++;					}					break;									case Instruction.LOADNIL:					log("LOADNIL\t\t\tR[" + inst.a + "], R[" + inst.b + "]");					for(var nilreg : uint = inst.a;nilreg <= inst.b; nilreg++)					{						frame.vars[nilreg] = null;					}					break;									case Instruction.GETUPVAL:					log("TODO: GETUPVAL");					break;									case Instruction.GETGLOBAL:					log("GETGLOBAL\t\tR[" + inst.a + "] = G[" + func.constants[inst.b] + "]");					if(!globals[func.constants[inst.b]])					{						log("WARNING: " + func.constants[inst.b] + " does not exist!");					}					frame.vars[inst.a] = globals[func.constants[inst.b]];					break;									case Instruction.GETTABLE:										var key : Object = (inst.c & 0x100 ? func.constants[inst.c - 0x100] : frame.vars[inst.c]);					log("GETTABLE\t\tR[" + inst.a + "] = R[" + inst.b + "][" + key + "]");					frame.vars[inst.a] = frame.vars[inst.b][key];					break;									case Instruction.SETGLOBAL:					log("SETGLOBAL\t\tG[" + func.constants[inst.b] + "] = R[" + inst.a + "]");					globals[func.constants[inst.b]] = frame.vars[inst.a];					break;								case Instruction.SETUPVAL:					log("TODO: SETUPVAL");					break;								case Instruction.SETTABLE:					var index : Object = (inst.b & 0x100 ? func.constants[inst.b - 0x100] : frame.vars[inst.b]);					var value : Object = (inst.c & 0x100 ? func.constants[inst.c - 0x100] : frame.vars[inst.c]);										log("SETTABLE\t\tR[" + inst.a + "][" + index + "]=" + value);					frame.vars[inst.a][index] = value;					break;									case Instruction.NEWTABLE:					log("NEWTABLE\t\tR[" + inst.a + "] = {} (size=" + inst.b + "," + inst.c + ")");					frame.vars[inst.a] = new Dictionary();					break;								case Instruction.SELF:					var tableconst : Object = (inst.c & 0x100 ? func.constants[inst.c - 0x100] : frame.vars[inst.c]);					log("SELF\t\t\tR[" + (inst.a + 1) + "] = R[" + inst.b + "]; R[" + (inst.a + 1) + "] = R[" + inst.b + "][" + tableconst + "]");										if(frame.vars[inst.b] == null)					{						log("WARNING: R[" + inst.b + "] does not exist!");					}					else if(frame.vars[inst.b][tableconst] == null)					{						log("WARNING: " + tableconst + " does not exist in R[" + inst.b + "]");					}					else					{						frame.vars[inst.a + 1] = frame.vars[inst.b];						frame.vars[inst.a] = frame.vars[inst.b][tableconst];					}										break;								// Maths Operations				case Instruction.ADD:				case Instruction.SUB:				case Instruction.MUL:				case Instruction.DIV:				case Instruction.MOD:				case Instruction.POW:								var a : Number = (inst.b & 0x100 ? parseInt(func.constants[inst.b - 0x100] + "") : frame.vars[inst.b]);					var b : Number = (inst.c & 0x100 ? parseInt(func.constants[inst.c - 0x100] + "") : frame.vars[inst.c]);										var c : Number = 0;										if(inst.opcode == Instruction.ADD) 					{ 						log("ADD\t\t\tR[" + inst.a + "] = " + a + " + " + b);						c = a + b; 					}					if(inst.opcode == Instruction.DIV) 					{ 						log("DIV\t\t\tR[" + inst.a + "] = " + a + " / " + b);						c = a / b; 					}					if(inst.opcode == Instruction.SUB) 					{ 						log("SUB\t\t\tR[" + inst.a + "] = " + a + " - " + b);						c = a - b; 					}					if(inst.opcode == Instruction.MUL) 					{ 						log("MUL\t\t\tR[" + inst.a + "] = " + a + " * " + b);						c = a * b; 					}					if(inst.opcode == Instruction.POW) 					{ 						log("POW\t\t\tR[" + inst.a + "] = " + a + " ^ " + b);						c = Math.pow(a, b); 					}					if(inst.opcode == Instruction.MOD) 					{ 						log("MOD\t\t\tR[" + inst.a + "] = " + a + " % " + b);						c = a % b; 					}										frame.vars[inst.a] = c;										break;									case Instruction.UNM:					log("UNM\t\t\tR[" + inst.a + "] = -R[" + inst.b + "]");					frame.vars[inst.a] = -frame.vars[inst.b];					break;									case Instruction.NOT:					// TODO : Check on inst.b here...					log("NOT\t\t\tR[" + inst.a + "] = !R[" + inst.b + "]");					frame.vars[inst.a] = !frame.vars[inst.b];					break;								case Instruction.LEN:					log("LEN\t\t\tR[" + inst.a + "] = length of R[" + inst.b + "]");					var val : Object = frame.vars[inst.b];					trace("val: " + val);					if(val is String)					{						frame.vars[inst.a] = (val as String).length;					}					else if(val is Dictionary)					{						trace("Get table size");					}					else					{						// Call metamethod here					}					break;								case Instruction.CONCAT:					log("CONCAT\t\t\tR[" + inst.a + "] = R[" + inst.b + " to " + inst.c + "]");										var catstr : String = "";					for(var catreg : uint = inst.b;catreg <= inst.c; catreg++)					{						catstr += frame.vars[catreg];					}					frame.vars[inst.a] = catstr;										break;								case Instruction.JMP:					log("JMP " + inst.b);					frame.pc += inst.b;					break;				case Instruction.EQ:				case Instruction.LT:				case Instruction.LE:					var aval : Number = (inst.b & 0x100 ? parseInt(func.constants[inst.b - 0x100] + "") : frame.vars[inst.b]);					var bval : Number = (inst.c & 0x100 ? parseInt(func.constants[inst.c - 0x100] + "") : frame.vars[inst.c]);					var test : Boolean = (inst.a == 1);										if(inst.opcode == Instruction.EQ) 					{ 						log("EQ\t\t\t" + aval + " == " + bval + " == " + test);												if((aval == bval) != test)						{							log("JMP");							frame.pc++;						}					}					else if(inst.opcode == Instruction.LT)					{						log("LT\t\t\t " + aval + " < " + bval + " == " + test);						if((aval < bval) != test)						{							log("JMP");							frame.pc++;						}					}					else if(inst.opcode == Instruction.LE)					{						log("LE\t\t\t " + aval + " <= " + bval + " == " + test);						if((aval <= bval) != test)						{							log("JMP");							frame.pc++;						}					}					break;								case Instruction.TEST:					log("TODO: TEST");					break;				case Instruction.TESTSET:					log("TODO: TESTSET");					break;								case Instruction.TAILCALL:					log("TAILCALL " + inst.a);				case Instruction.CALL:					var params : Array = [];					if(inst.b == 0)					{						params = frame.vars.slice(inst.a + 1);					}					else if(inst.b == 1)					{						params = [];					}					else					{						params = frame.vars.slice(inst.a + 1, inst.a + inst.b);					}										var numReturns : int;					var return_reg : uint;										if(inst.c == 0)					{						numReturns = -1;					}					else					{						numReturns = inst.c - 1;					}										return_reg = inst.a;										if(frame.vars[inst.a] is LuaFunction)					{											var newFrame : Frame = new Frame();						newFrame.vars = params;												frame.returns = numReturns;						frame.return_reg = return_reg;												newFrame.a = inst.a;						newFrame.b = inst.b;						newFrame.c = inst.c;												log("CALL\t\t\tR[" + inst.a + "] (" + params.join(",") + ") : " + frame.returns); 						trace(inst.b);						trace(inst.c);						stack.push(newFrame);						funcs.push(frame.vars[inst.a] as LuaFunction);					}					else if(frame.vars[inst.a] is Function)					{						log("CALL\t\t\tR[" + inst.a + "] (" + params.join(",") + ") : " + frame.returns); 						trace(inst.b);						trace(inst.c);						var nativeFunc : Function = (frame.vars[inst.a] as Function);						var nativeReturnValues : Array = nativeFunc(params);						if(nativeReturnValues == null)						{							nativeReturnValues = [];						}						if(numReturns == -1) 						{ 							numReturns = nativeReturnValues.length; 						}											trace("Returns: " + numReturns);						if(nativeReturnValues.length > 0)						{							for(var i : uint = 0;i < numReturns; i++)							{								trace("Val: " + nativeReturnValues[i]);								frame.vars[frame.return_reg + i] = nativeReturnValues[i];							}						}					}					else					{						log("WARNING: R["+inst.a+"] is not a valid function");					}					frame.pc++;					return;					break;								case Instruction.RETURN:										log("RETURN\t\t\tRETURN");																				var oldRegs : Array = frame.vars;					var oldFrame : Frame = stack.pop();										funcs.pop();										trace("Stack length: " + stack.length);					if(!stack.length)					{						return;					}										var k : uint = inst.a;										var fa : uint = oldFrame.a;					var fc : uint = oldFrame.c;										var j : uint = (!fc ? this.func.maxStack : fa + fc - 1);										trace(this.func);					trace("fa: " + fa);					trace("fc: " + fc);					trace("max stack: " + this.func.maxStack);					trace("j: " + j);					trace("k: " + k);										frame = (stack[stack.length - 1] as Frame);					for(;fa < j; fa++)					{						trace("Return value: " + oldRegs[k]);						frame.vars[fa] = oldRegs[k];						k++;					}										return;					break;								case Instruction.FORLOOP:					log("FORLOOP init=" + frame.vars[inst.a] + ";limit=" + frame.vars[inst.a + 1] + ";step=" + frame.vars[inst.a + 2] + ";counter=" + frame.vars[inst.a + 3]);					frame.vars[inst.a] += frame.vars[inst.a + 2];					var step : int = frame.vars[inst.a + 2];					if((step < 0 && frame.vars[inst.a] >= frame.vars[inst.a + 1]) || (step > 0 && frame.vars[inst.a] <= frame.vars[inst.a + 1]))					{						frame.pc += inst.b;						frame.vars[inst.a + 3] = frame.vars[inst.a];						}									break;									case Instruction.FORPREP:					log("FORPREP init=" + frame.vars[inst.a] + ";limit=" + frame.vars[inst.a + 1] + ";step=" + frame.vars[inst.a + 2] + ";counter=" + frame.vars[inst.a + 3]);					frame.vars[inst.a] -= frame.vars[inst.a + 2];					frame.pc += inst.b;					break;									case Instruction.TFORLOOP:					log("TFORLOOP " + inst.a + " " + inst.c);					break;								case Instruction.SETLIST:					log("TODO: SETLIST");					break;								case Instruction.CLOSE:					log("TODO: CLOSE");					break;									case Instruction.CLOSURE:					log("CLOSURE\t\t\tR[" + inst.a + "] = func " + func.functions[inst.b] + "");					frame.vars[inst.a] = (func.functions[inst.b] as LuaFunction).instantiate();					break;												case Instruction.VARARG:						log("TODO: VARARG");					break;													default:					log("Unhandled: " + inst.opcode + " " + inst.a + " " + inst.b + " " + inst.c);			}							frame.pc++;		}		public function write(args : Array) : Array		{			trace("IO: " + args.join(",").replace("\n", ""));			return [true];		}		public function format(args : Array) : Array		{			return [args.join(",")];		}		private function log(message : String) : void		{			message = message.replace("\n", " ");			trace("* " + frame.pc + "\t" + message + "\t" + frame.vars.join(","));		}	}}