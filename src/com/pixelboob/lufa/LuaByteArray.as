package com.pixelboob.lufa {	import flash.utils.ByteArray;	/**	 * @author moj	 */	public class LuaByteArray extends ByteArray	{		private var state : LuaState;		public function LuaByteArray(state : LuaState)		{			super();			this.state = state;		}		/*********************************		 * Data structures		 */		public function readString() : String		{			var size_t : uint = this.readUnsignedInt();			return this.readMultiByte(size_t, "iso-8859-1");		}				public function readNumber() : Number		{			return this.readDouble();		}		public function readInteger() : int		{			return this.readUnsignedInt();		}	}}