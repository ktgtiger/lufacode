package com.pixelboob.lufa {	import com.pixelboob.lufa.lib.IO;	import com.pixelboob.lufa.lib.Maths;	import com.pixelboob.lufa.lib.MetaTable;	import com.pixelboob.lufa.lib.OS;	import com.pixelboob.lufa.lib.Utils;		import org.spicefactory.lib.logging.LogContext;	import org.spicefactory.lib.logging.Logger;		import flash.events.EventDispatcher;	import flash.events.TimerEvent;	import flash.utils.Timer;	import flash.utils.describeType;		/**	 * @author moj	 */	public class Interpreter extends EventDispatcher 	{		private var logger : Logger = LogContext.getLogger(Interpreter);		private var stack : Array;		private var funcs : Array;		private var _globals : Table;		private var frame : Frame;		private var func : LuaFunction;		private var timer : Timer;		private var inst : Instruction;		public function Interpreter() 		{			this.timer = new Timer(5);		}				public function callInternal(functionName : String, ...args) : void		{			// Decompose the path to the function			var pieces : Array = functionName.split(".");			var currPos : Table = this.globals;			var funcName : String = pieces.pop();			for each(var piece : String in pieces)			{				if(!currPos[piece])				{					logger.error("Invalid function: "+functionName);					return;				}								currPos = currPos[piece];			}						if(!currPos[funcName])			{				logger.error("Invalid function: "+functionName);				return;			}						call(currPos[funcName], args);						if(!this.timer.running)			{				cont();			}		}		public function run(func : LuaFunction, startPaused : Boolean = false) : void 		{			stack = [];			funcs = [];			setupLibraries();			var frame : Frame = new Frame();			stack.push(frame);			funcs.push(func);					if(!startPaused) 			{				cont();			} 			else 			{				step();			}		}		private function setupLibraries() : void 		{			globals = new Table();			injectClass(IO);			injectClass(OS);			injectClass(Maths);			injectClass(MetaTable);			injectClass(Utils);		}		public function cont() : void 		{			this.timer.addEventListener(TimerEvent.TIMER, this.handleTick);			this.timer.start();		}		public function pause() : void 		{			this.timer.stop();		}		private function handleTick(event : TimerEvent) : void 		{			if(funcs.length != 0) 			{				this.step();			} 			else 			{				this.pause();				this.dispatchEvent(new InterpreterEvent(InterpreterEvent.COMPLETE));			}		}		private function injectClass(clazz : Class) : void 		{			var typeXML : XML = describeType(clazz);						var className : String = typeXML.factory.metadata.arg.(@key == "className").@value;			var packageName : String = typeXML.factory.metadata.arg.(@key == "packageName").@value;						var currPos : Table = globals;						if(packageName != "")			{				var packageElements : Array = packageName.split(".");				for each(var packageElement : String in packageElements)				{					if(!currPos[packageElement])					{						currPos[packageElement] = new Table();					}										currPos = currPos[packageElement];				}			}						if(className)			{				if(!currPos[className])				{					currPos[className] = new Table();				}				currPos = currPos[className];			}						for each(var method:XML in typeXML..method)			{				var methodName : String = method.metadata.arg.(@key == "methodName").@value;				currPos[methodName] = clazz[method.@name];			}						for each(var variable:XML in typeXML..variable)			{				var variableName : String = variable.@name;				currPos[variableName] = clazz[variableName];			}		}		public function step() : void 		{			this.frame = (stack[stack.length - 1] as Frame);			this.func = (funcs[funcs.length - 1] as LuaFunction);					this.inst = func.instructions[frame.pc];					switch(inst.opcode) 			{				case Instruction.MOVE:					log("MOVE\t\t\tR[" + inst.a + "] = R[" + inst.b + "]");					frame.vars[inst.a] = frame.vars[inst.b];					break;									case Instruction.LOADK:					log("LOADK\t\t\tR[" + inst.a + "] = " + func.constants[inst.b]);					frame.vars[inst.a] = func.constants[inst.b];					break;									case Instruction.LOADBOOL:					log("LOADBOOL\t\t\tR[" + inst.a + "] = " + inst.b + " (skip flag: " + inst.c + ")");					frame.vars[inst.a] = (inst.b == 1 ? true : false);										// Support the skip flag					if(inst.c != 0) 					{						frame.pc++;					}					break;									case Instruction.LOADNIL:					log("LOADNIL\t\t\tR[" + inst.a + "], R[" + inst.b + "]");					for(var nilreg : uint = inst.a;nilreg <= inst.b; nilreg++) 					{						frame.vars[nilreg] = null;					}					break;									case Instruction.GETUPVAL:					log("GETUPVAL\t\tR[" + inst.a + "] = UpValue[" + inst.b + "]");					frame.vars[inst.a] = func.upvalues[inst.b];					break;									case Instruction.GETGLOBAL:					log("GETGLOBAL\t\tR[" + inst.a + "] = G[" + func.constants[inst.b] + "]");					if(!globals[func.constants[inst.b]]) 					{						logger.warn(func.constants[inst.b] + " does not exist!");					}					frame.vars[inst.a] = globals[func.constants[inst.b]];					break;									case Instruction.GETTABLE:										var key : Object = (inst.c & 0x100 ? func.constants[inst.c - 0x100] : frame.vars[inst.c]);					var table : Object = frame.vars[inst.b];					log("GETTABLE\t\tR[" + inst.a + "] = R[" + inst.b + "][" + key + "]");					getTableEvent("__index", inst.a, table, key);					break;									case Instruction.SETGLOBAL:					log("SETGLOBAL\t\tG[" + func.constants[inst.b] + "] = R[" + inst.a + "]");					globals[func.constants[inst.b]] = frame.vars[inst.a];					break;								case Instruction.SETUPVAL:					log("SETUPVAL\t\tUpValue[" + inst.b + "] = R[" + inst.a + "]");					func.upvalues[inst.b] = frame.vars[inst.a];					break;								case Instruction.SETTABLE:					var index : Object = (inst.b & 0x100 ? func.constants[inst.b - 0x100] : frame.vars[inst.b]);					var value : Object = (inst.c & 0x100 ? func.constants[inst.c - 0x100] : frame.vars[inst.c]);										log("SETTABLE\t\tR[" + inst.a + "][" + index + "]=" + value);					frame.vars[inst.a][index] = value;					break;									case Instruction.NEWTABLE:					log("NEWTABLE\t\tR[" + inst.a + "] = {} (size=" + inst.b + "," + inst.c + ")");					frame.vars[inst.a] = new Table();					break;								case Instruction.SELF:					var tableconst : Object = (inst.c & 0x100 ? func.constants[inst.c - 0x100] : frame.vars[inst.c]);					log("SELF\t\t\tR[" + (inst.a + 1) + "] = R[" + inst.b + "]; R[" + (inst.a + 1) + "] = R[" + inst.b + "][" + tableconst + "]");									/*	if(frame.vars[inst.b] == null) 					{						logger.warn("R[" + inst.b + "] does not exist!");					}					else if(frame.vars[inst.b][tableconst] == null) 					{						logger.warn(tableconst + " does not exist in R[" + inst.b + "]");					} 					else 					{*/						frame.vars[inst.a + 1] = frame.vars[inst.b];						getTableEvent("__index", inst.a, frame.vars[inst.b], tableconst);				//		frame.vars[inst.a] = frame.vars[inst.b][tableconst];				//	}										break;								// Maths Operations				case Instruction.ADD:				case Instruction.SUB:				case Instruction.MUL:				case Instruction.DIV:				case Instruction.MOD:				case Instruction.POW:								var a : Object = (inst.b & 0x100 ? func.constants[inst.b - 0x100] : frame.vars[inst.b]);					var b : Object = (inst.c & 0x100 ? func.constants[inst.c - 0x100] : frame.vars[inst.c]);										var aNum : Number = parseInt(a + "");					var bNum : Number = parseInt(b + "");															if(inst.opcode == Instruction.ADD) 					{ 						log("ADD\t\t\tR[" + inst.a + "] = " + a + " + " + b);												if(!isNaN(aNum) && !isNaN(bNum))						{							frame.vars[inst.a] = aNum + bNum; 						}						else						{							handleEvent("__add", inst.a, a, b);						}					}					if(inst.opcode == Instruction.DIV) 					{ 						log("DIV\t\t\tR[" + inst.a + "] = " + a + " / " + b);												if(!isNaN(aNum) && !isNaN(bNum))						{							frame.vars[inst.a] = aNum / bNum; 						}						else						{							handleEvent("__div", inst.a, a, b);						}					}					if(inst.opcode == Instruction.SUB) 					{ 						log("SUB\t\t\tR[" + inst.a + "] = " + a + " - " + b);												if(!isNaN(aNum) && !isNaN(bNum))						{							frame.vars[inst.a] = aNum - bNum; 						}						else						{							handleEvent("__sub", inst.a, a, b);						}					}					if(inst.opcode == Instruction.MUL) 					{ 						log("MUL\t\t\tR[" + inst.a + "] = " + a + " * " + b);												if(!isNaN(aNum) && !isNaN(bNum))						{							frame.vars[inst.a] = aNum * bNum; 						}						else						{							handleEvent("__mul", inst.a, a, b);						}					}					if(inst.opcode == Instruction.POW) 					{ 						log("POW\t\t\tR[" + inst.a + "] = " + a + " ^ " + b);						if(!isNaN(aNum) && !isNaN(bNum))						{							frame.vars[inst.a] = Math.pow(aNum, bNum);						}						else						{							handleEvent("__pow", inst.a, a, b);						}					}					if(inst.opcode == Instruction.MOD) 					{ 						log("MOD\t\t\tR[" + inst.a + "] = " + a + " % " + b);						if(!isNaN(aNum) && !isNaN(bNum))						{							frame.vars[inst.a] = aNum % bNum;						}						else						{							handleEvent("__mod", inst.a, a, b);						}					}										break;									case Instruction.UNM:					log("UNM\t\t\tR[" + inst.a + "] = -R[" + inst.b + "]");										var bUnmNum : Number = parseInt(frame.vars[inst.b]);										if(!isNaN(bUnmNum))					{						frame.vars[inst.a] = -bUnmNum;					}					else					{						handleEvent("__unm", inst.a, frame.vars[inst.b]);					}					break;									case Instruction.NOT:					// TODO : Check on inst.b here...					log("NOT\t\t\tR[" + inst.a + "] = !R[" + inst.b + "]");					frame.vars[inst.a] = !frame.vars[inst.b];					break;								case Instruction.LEN:					log("LEN\t\t\tR[" + inst.a + "] = length of R[" + inst.b + "]");					var val : Object = frame.vars[inst.b];										if(val is String) 					{						frame.vars[inst.a] = (val as String).length;					}					else if(val is Table) 					{						frame.vars[inst.a] = (val as Table).length;						logger.debug("Get table size");					}					else					{						// TODO : Metatable handling					}					break;								case Instruction.CONCAT:					log("CONCAT\t\t\tR[" + inst.a + "] = R[" + inst.b + " to " + inst.c + "]");										var catstr : String = "";															for(var catreg : uint = inst.b;catreg <= inst.c; catreg++) 					{						catstr += frame.vars[catreg];					}					frame.vars[inst.a] = catstr;										// TODO : Metatable handling					break;								case Instruction.JMP:					log("JMP " + inst.b);					frame.pc += inst.b;					break;				case Instruction.EQ:				case Instruction.LT:				case Instruction.LE:					var op1 : Object = (inst.b & 0x100 ? func.constants[inst.b - 0x100] : frame.vars[inst.b]);					var op2 : Object = (inst.c & 0x100 ? func.constants[inst.c - 0x100] : frame.vars[inst.c]);					var test : Boolean = (inst.a == 1);										if(inst.opcode == Instruction.EQ) 					{ 						log("EQ\t\t\t" + op1 + " == " + op2 + " == " + test);																		if(handleEqEvent(op1, op2) != test) 						{							log("JMP");							frame.pc++;						}					}					else if(inst.opcode == Instruction.LT) 					{						log("LT\t\t\t " + op1 + " < " + op2 + " == " + test);						if(handleLtEvent(op1, op2) != test) 						{							log("JMP");							frame.pc++;						}					}					else if(inst.opcode == Instruction.LE) 					{						log("LE\t\t\t " + op1 + " <= " + op2 + " == " + test);						if(handleLeEvent(op1, op2)  != test) 						{							log("JMP");							frame.pc++;						}					}					break;								case Instruction.TEST:										log("TEST\t\t\t " + frame.vars[inst.a] + " == " + inst.c);										if(frame.vars[inst.a] == inst.c) 					{						frame.pc++;					}										break;				case Instruction.TESTSET:										log("TESTSET\t\t\t " + frame.vars[inst.b] + " != " + inst.c);										if(frame.vars[inst.b] != inst.c) 					{						frame.vars[inst.a] = frame.vars[inst.b];					} 					else 					{						frame.pc++;					}										break;								case Instruction.TAILCALL:					log("TAILCALL " + inst.a);				case Instruction.CALL:									var functionRef : Object = frame.vars[inst.a];					var numParams : int = inst.b - 1;					var numReturns : int = inst.c - 1;															// Sort out the parameters for our function					var params : Array = [];					if(numParams == -1) 					{						// Take everything from A+1 to the top of the stack						params = frame.vars.slice(inst.a + 1);					}					else if(numParams == 0) 					{						// No params						params = [];					} 					else 					{						// Take a+1 to a+1+numParams						params = frame.vars.slice(inst.a + 1, inst.a + 1 + numParams);					}										frame.return_reg = inst.a;					frame.returns = numReturns;										logger.debug("Num params: " + numParams);					logger.debug("Num returns: " + numReturns);					logger.debug("Params: " + params.join(","));					logger.debug("Return reg: " + frame.return_reg);										log("CALL\t\t\tR[" + inst.a + "] (" + params.join(",") + ") : " + frame.returns); 										if(functionRef is LuaFunction || functionRef is Function)					{						call(functionRef, params, inst);					}					else 					{						var metatable : Table = MetaTable.getMetaTable(functionRef);						if(metatable["__call"])						{							functionRef = metatable["__call"];							if(functionRef)							{								call(functionRef, params, inst);							}							else							{								logger.error("R[" + inst.a + "] is not a valid function: " + functionRef);							}						}					}										frame.pc++;										return;					break;								case Instruction.RETURN:										log("RETURN\t\t\tRETURN");										var numReturnVals : int = inst.b - 1;					var returns : Array = [];					if(numReturnVals == -1) 					{						// Take everything from A to the top of the stack						returns = frame.vars.slice(inst.a);					}					else if(numReturnVals == 0) 					{						// No returns						returns = [];					} 					else 					{						// Take a to a+numReturns						returns = frame.vars.slice(inst.a, inst.a + numReturnVals);					}										stack.pop();					funcs.pop();										if(!stack.length) 					{						return;					}										frame = (stack[stack.length - 1] as Frame);										for(var regpos : uint = frame.return_reg;regpos < frame.return_reg + returns.length; regpos++) 					{						frame.vars[regpos] = returns[regpos - frame.return_reg];					}										return;					break;								case Instruction.FORLOOP:					log("FORLOOP init=" + frame.vars[inst.a] + ";limit=" + frame.vars[inst.a + 1] + ";step=" + frame.vars[inst.a + 2] + ";counter=" + frame.vars[inst.a + 3]);					frame.vars[inst.a] += frame.vars[inst.a + 2];					var step : int = frame.vars[inst.a + 2];					if((step < 0 && frame.vars[inst.a] >= frame.vars[inst.a + 1]) || (step > 0 && frame.vars[inst.a] <= frame.vars[inst.a + 1])) 					{						frame.pc += inst.b;						frame.vars[inst.a + 3] = frame.vars[inst.a];						}									break;									case Instruction.FORPREP:					log("FORPREP init=" + frame.vars[inst.a] + ";limit=" + frame.vars[inst.a + 1] + ";step=" + frame.vars[inst.a + 2] + ";counter=" + frame.vars[inst.a + 3]);					frame.vars[inst.a] -= frame.vars[inst.a + 2];					frame.pc += inst.b;					break;									case Instruction.TFORLOOP:					log("TFORLOOP " + inst.a + " " + inst.c);					break;								case Instruction.SETLIST:					var FPF : uint = 50;					log("SETLIST R[" + inst.a + "][" + (inst.c - 1) * FPF + "+i] = R[" + inst.a + "+i]");										for(var listi : uint = 1;listi <= inst.b; listi++) 					{						frame.vars[inst.a][(inst.c - 1) * FPF + listi] = frame.vars[inst.a + listi];					//	logger.debug("R[" + inst.a + "][" + ((inst.c - 1) * FPF + i) + "] = " + frame.vars[inst.a + i]);					}															break;								case Instruction.CLOSE:					log("TODO: CLOSE");					break;									case Instruction.CLOSURE:					log("CLOSURE\t\t\tR[" + inst.a + "] = func " + func.functions[inst.b] + "");					frame.vars[inst.a] = (func.functions[inst.b] as LuaFunction).instantiate();					break;												case Instruction.VARARG:						log("VARAG\t\t\tR[" + inst.a + "]... = varag");										for(var i : uint = inst.a;i < (inst.a + inst.b); i++)					{						frame.vars[inst.a + i] = inst.a + i;					}										break;													default:					logger.warn("Unhandled: " + inst.opcode + " " + inst.a + " " + inst.b + " " + inst.c);			}							frame.pc++;		}		private function getTableEvent(event : String, targetRegister : int, table : Object, key : Object) : void		{			logger.debug("Get table event: "+key);			var handler : Object;			if(table is Table)			{				// First check in the standard place in the table				var val : Object = MetaTable.rawGet(table as Table, key);				if(val != null)				{					logger.trace("Found "+key+" in table: "+val);					frame.vars[targetRegister] = val;					return;				}								// Not there, so have a check in the metatable				var meta : Table = MetaTable.getMetaTable(table);								if(meta == null)				{					logger.trace("Not in the table, and no metatable");					return;				}								handler = meta["__index"];				if(handler == null)				{					logger.trace("Not in the table, and no metatable handler");					return;				}			}			else			{				logger.trace("This path shouldn't be possible...");				// We don't have a dictionary as an operand - try to grab the metatable				var meta2 : Table = MetaTable.getMetaTable(table);								if(meta2 == null)				{					logger.error("Invalid table index");					return;				}								handler = meta2["__index"];				if(handler == null)				{					logger.error("Invalid table index");					return;				}			}						if(handler is Function || handler is LuaFunction)			{				// Call up the function				frame.return_reg = targetRegister;				frame.returns = -1;				call(handler, [table, key], inst);			}			else			{				// Recurse!				logger.debug("Recursing on "+key);				getTableEvent(event, targetRegister, handler, key);			}		}		private function handleEvent(event : String, targetRegister : uint, op1 : Object, op2 : Object = null) : void		{			logger.debug("Handle event: " + event);						// Get the relevant handler			var metaOp1 : Table = MetaTable.getMetaTable(op1);			var metaOp2 : Table = MetaTable.getMetaTable(op2);					var handler : Object;			if(metaOp1 != null && metaOp1[event])			{				handler = metaOp1[event];			}			else if(metaOp2 != null && metaOp2[event])			{				handler = metaOp2[event];			}						if(handler == null)			{				logger.error("No handler for " + event);			}			else			{				frame.return_reg = targetRegister;				frame.returns = -1;								var params : Array;				if(op2 == null)				{					params = [op1];				}				else				{					params = [op1, op2];				}								call(handler, params, inst);				return;			}		}		public function call(functionRef : Object, params : Array, instruction : Instruction = null) : void		{			if(functionRef is LuaFunction) 			{				var newFrame : Frame = new Frame();				newFrame.vars = params;													if(instruction)				{								newFrame.a = instruction.a;					newFrame.b = instruction.b;					newFrame.c = instruction.c;				}								stack.push(newFrame);				funcs.push(functionRef as LuaFunction);			}			else if(functionRef is Function) 			{				var nativeFunc : Function = (functionRef as Function);										var nativeReturnValues : Array = nativeFunc(params);				if(nativeReturnValues == null) 				{					nativeReturnValues = [];				}										for(var i : uint = 0;i < nativeReturnValues.length; i++) 				{					frame.vars[frame.return_reg + i] = nativeReturnValues[i];				}									} 		}		private function log(message : String) : void 		{			message = message.replace("\n", " ");			logger.info("* " + frame.pc + "\t" + message + "\t" + frame.vars.join(","));		}				public function get globals() : Table		{			return _globals;		}				public function set globals(globals : Table) : void		{			_globals = globals;		}			// Conditionals				public function handleEqEvent(op1 : Object, op2 : Object) : Boolean		{			if(Utils.type(op1) != Utils.type(op2))			{				return false;			}						if(op1 == op2)			{				return true;			}						return false;		}				private function handleLeEvent(op1 : Object, op2 : Object) : Boolean		{			if(Utils.type(op1) == "number" && Utils.type(op2) == "number")			{				return (op1 as Number) <= (op2 as Number);			}			else if(Utils.type(op1) == "string" && Utils.type(op2) == "string")			{				var str1 : String = (op1 as String);				var str2 : String = (op2 as String);				return (str1.localeCompare(str2) <= 0);			}						return false;		}		private function handleLtEvent(op1 : Object, op2 : Object) : Boolean		{			if(Utils.type(op1) == "number" && Utils.type(op2) == "number")			{				return (op1 as Number) < (op2 as Number);			}			else if(Utils.type(op1) == "string" && Utils.type(op2) == "string")			{				var str1 : String = (op1 as String);				var str2 : String = (op2 as String);				return (str1.localeCompare(str2) < 0);			}						return false;		}				public function getCompHandler(op1 : Object, op2 : Object, event : String) : Object		{			if(Utils.type(op1) != Utils.type(op2))			{				return null;			}						var mm1 : Object;			var mm2 : Object;						var mt1 : Table = MetaTable.getMetaTable(op1);			if(mt1 != null)			{				mm1 = mt1[event];			}						var mt2 : Table = MetaTable.getMetaTable(op2);			if(mt2 != null)			{				mm2 = mt2[event];			}						if(mm1 == mm2)			{				return mm1;			}			else			{				return null;			}					}	}}