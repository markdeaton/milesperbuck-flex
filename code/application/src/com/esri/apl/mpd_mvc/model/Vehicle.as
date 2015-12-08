package com.esri.apl.mpd_mvc.model
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	import mx.controls.ColorPicker;
	import mx.utils.ColorUtil;
	
	import spark.collections.Sort;

	[Bindable]
	public class Vehicle extends EventDispatcher {
		private const DESC_DELIMTER		: String = ">";
		private const DESC_UNSELECTED	: String = "Select a Vehicle";
		
		// XMLListCollections are used for available choices, since they can be data-bound
		// to list boxes. Due to quirks (bugs?) in list control databinding, it's important
		// never to set these variables to new instances of XMLListCollection. Instead, set
		// XMLListCollection.source to the result of an XML query.
		private var _availableYears		: XMLListCollection = new XMLListCollection();
		private var _selectedYear		: Object;
		private var _availableMakes		: XMLListCollection = new XMLListCollection();
		private var _selectedMake		: Object;
		private var _availableModels	: XMLListCollection = new XMLListCollection();
		private var _selectedModel		: Object;
		private var _availableEngines	: XMLListCollection = new XMLListCollection();
		private var _selectedEngine		: Object;
		private var _selectedGasMileage	: Number;
		private var _graphicProvider	: ArrayCollection;
		private var _vehicleIndex		: Number = NaN;
		
		public var label				: String = DESC_UNSELECTED;
		
		public function Vehicle( vehicleIndex:Number = NaN ) {
			super();
			_vehicleIndex = vehicleIndex;
		}
		
		public function clear():void {
			selectedYear = null; selectedMake = null; selectedModel = null; selectedEngine = null;
			selectedGasMileage = NaN;
			label = DESC_UNSELECTED;
			dispatchEvent( new Event( "vehicleSelectionChanged", true ) );
		}
		
		public function get vehicleIndex():Number {
			return _vehicleIndex;
		}
		
		public function milesPerDollar( pricePerDollar:Number ):Number {
			var mpd:Number = ( this.vehicleSelected ) ? ( selectedGasMileage / pricePerDollar ) : NaN; 
			return mpd;
		}
		
		public function get availableYears():XMLListCollection
		{
			return _availableYears;
		}

		public function set availableYears(value:XMLListCollection):void
		{
			_availableYears = value;
		}

		public function get selectedYear():Object
		{
			return _selectedYear;
		}

		public function set selectedYear(value:Object):void
		{
			_selectedYear = value;
			
			if ( value ) label = value.toString();
		}

		public function get availableMakes():XMLListCollection
		{
			return _availableMakes;
		}

		public function set availableMakes(value:XMLListCollection):void
		{
			_availableMakes = value;
		}

		public function get selectedMake():Object
		{
			return _selectedMake;
		}

		public function set selectedMake(value:Object):void
		{
			_selectedMake = value;
			
			if ( value ) label += DESC_DELIMTER + value.toString();		
		}

		public function get availableModels():XMLListCollection
		{
			return _availableModels;
		}

		public function set availableModels(value:XMLListCollection):void
		{
			_availableModels = value;
		}

		public function get selectedModel():Object
		{
			return _selectedModel;
		}

		public function set selectedModel(value:Object):void
		{
			_selectedModel = value;
			
			if ( value ) label += DESC_DELIMTER + value.toString();		
		}

		public function get availableEngines():XMLListCollection
		{
			return _availableEngines;
		}

		public function set availableEngines(value:XMLListCollection):void
		{
			_availableEngines = value;
		}

		public function get selectedEngine():Object
		{
			return _selectedEngine;
		}

		public function set selectedEngine(value:Object):void
		{
			var oldValue:Object = _selectedEngine;
			_selectedEngine = value;
			
			if ( value ) label += DESC_DELIMTER + value.toString();

			// Only notify of vehicle selection change if engine has changed from
			// null to a value or vice-versa
			if ( 
				(((oldValue == null) && (value != null)) || ((oldValue != null) && (value == null))) 
				&& (oldValue != value) 
			) 
				dispatchEvent( new Event( "vehicleSelectionChanged", true ) );
		}

		public function get selectedGasMileage():Number
		{
			return _selectedGasMileage;
		}

		public function set selectedGasMileage(value:Number):void
		{
			_selectedGasMileage = value;
		}


		public function get vehicleSelected():Boolean {
			return (
				selectedYear != null &&
				selectedMake != null &&
				selectedModel != null &&
				selectedEngine != null
			);
		}

		public function get graphicProvider():ArrayCollection
		{
			return _graphicProvider;
		}

		public function set graphicProvider(value:ArrayCollection):void
		{
			_graphicProvider = value;
		}

//		public override function toString():String {
//			var s:String = "Select a Vehicle";
//			if ( selectedYear ) s = selectedYear.toString();
//			if ( selectedMake ) s += " " + selectedMake.toString();
//			if ( selectedModel ) s += " " + selectedModel.toString();
//			if ( selectedEngine ) s+= " " + selectedEngine.toString();
//			
//			return s;
//		}
	}
}