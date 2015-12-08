package com.esri.apl.mpd_mvc.events
{
	import flash.events.Event;
	
	public class VehicleParameterSelectedEvent extends Event {
		public static const YEAR:String = "vehicleParameterSelectedYear";
		public static const MAKE:String = "vehicleParameterSelectedMake";
		public static const MODEL:String = "vehicleParameterSelectedModel";
		public static const ENGINE:String = "vehicleParameterSelectedEngine";
		public static const CLEARSELECTION:String = "vehicleParameterClearSelection";
		
		public var vehicleIndex:uint;
		public var valueSelected:Object;
		
		public function VehicleParameterSelectedEvent( vehicleIndex:uint, type:String, value:Object=null, bubbles:Boolean=true, cancelable:Boolean=false ) {
			super( type, bubbles, cancelable );
			this.vehicleIndex = vehicleIndex;
			this.valueSelected = value;
		}
	}
}