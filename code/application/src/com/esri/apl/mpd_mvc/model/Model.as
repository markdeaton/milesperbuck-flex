package com.esri.apl.mpd_mvc.model
{
	import com.esri.ags.geometry.Extent;
	
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;

	[Bindable]
	public class Model
	{
		private const numVehicles				: uint = 2;

		// Columns for PADD zones in the DOE gas price Excel spreadsheet
		public static const COL_PADD_IA			: uint = 2;
		public static const COL_PADD_IB			: uint = 3;
		public static const COL_PADD_IC			: uint = 4;
		public static const COL_PADD_II			: uint = 5;
		public static const COL_PADD_III		: uint = 6;
		public static const COL_PADD_IV			: uint = 7;
		public static const COL_PADD_V			: uint = 8;
		
		public static const COL_GASPRICEDATE	: uint = 3;
		public static const ROW_GASPRICEDATE	: uint = 11;

		// Application states
//		private var _currentState				: uint = STATE_LOADING;
		public static const STATE_LOADING		: uint = 0;
		public static const STATE_NOVEHICLESELECTED: uint = 1;
		public static const STATE_VEHICLESELECTED: uint = 2;
		public static const STATE_FINDINGZONES	: uint = 3;
		public static const STATE_FOUNDZONES	: uint = 4;
		
		private static var _instance			: Model;
		
		private var _atLeastOneVehicleSelected	: Boolean = false;
		public var findingDriveZones			: Boolean = false;
		
		public var baseMapUrl					: String;
		public var vehicles						: ArrayCollection;
		public var selectedRegion				: String;
		public var selectedGasPrice				: Number;
		public var gasPriceDataAsOf				: String; // How current the gas price data is
		
		public var clickLocGraphicProvider		: ArrayCollection = new ArrayCollection();
		
		// 3 datafiles that are loaded at startup:
		// Gas prices in PADD areas
		public var paddPrices					: ArrayCollection;
		// What states are in each PADD area
		public var state2PADD					: XML;
		// Vehicle fuel economy info
		public var vehiclesXML					: XML;

		public var mapExtent					: Extent = new Extent( -124.915, 32.278, -109.973, 44.143 );
		
		public function Model() {
			vehicles = new ArrayCollection();
			for ( var i:int = 0; i < numVehicles; i++ ) {
				var v:Vehicle = new Vehicle( i );
				vehicles.addItem( v );
				v.addEventListener( "vehicleSelectionChanged", vehicleSelectionChanged );
			}
		}

		public static function get instance():Model {
			if( _instance == null ) {
				_instance = new Model();
			}
			return _instance;
		}

		public function get atLeastOneVehicleSelected():Boolean
		{
			return _atLeastOneVehicleSelected;
		}

		public function set atLeastOneVehicleSelected(value:Boolean):void
		{
			_atLeastOneVehicleSelected = value;
		}

		private function vehicleSelectionChanged( event:Event ):void {
			atLeastOneVehicleSelected = vehicles.source.some( function( v:Vehicle, i:int, a:Array ):Boolean {
				return v.vehicleSelected;
			} );
		}

	}
}