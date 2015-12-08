package com.esri.apl.mpd_mvc.events
{
	import com.esri.ags.Graphic;
	import com.esri.ags.geometry.MapPoint;
	
	import flash.events.Event;
	
	public class LocationSelectedEvent extends Event
	{
		public static const LOCATION_SELECTED:String = "driveZonesLocationSelected";
		
		private var _location:Graphic;
		
		public function LocationSelectedEvent(type:String, ptLocation:Graphic, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.location = ptLocation;
		}

		public function get location():Graphic
		{
			return _location;
		}

		public function set location(value:Graphic):void
		{
			_location = value;
		}

	}
}