package com.pixelboob.lufa {	import flash.events.Event;		/**	 * @author mikej	 */	public class InterpreterEvent extends Event 	{		public static const COMPLETE : String = "complete";				public function InterpreterEvent(type : String, bubbles : Boolean = false, cancelable : Boolean = false)		{			super(type, bubbles, cancelable);		}	}}