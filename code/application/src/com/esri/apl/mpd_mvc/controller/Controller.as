package com.esri.apl.mpd_mvc.controller
{
	// NOTE: This component must NOT be placed in the declarations section of its parent; place
	// it somewhere in the standard MXML portion instead, so it can be added to the stage.
	
	//TODO Import the usa-checking logic from Nissan version of the app
	
	import com.as3xls.xls.Cell;
	import com.as3xls.xls.ExcelFile;
	import com.as3xls.xls.Sheet;
	import com.esri.ags.FeatureSet;
	import com.esri.ags.Graphic;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.tasks.Geoprocessor;
	import com.esri.ags.tasks.QueryTask;
	import com.esri.ags.tasks.supportClasses.Query;
	import com.esri.apl.mpd_mvc.UI.Processing;
	import com.esri.apl.mpd_mvc.events.LocationSelectedEvent;
	import com.esri.apl.mpd_mvc.events.VehicleParameterSelectedEvent;
	import com.esri.apl.mpd_mvc.model.Model;
	import com.esri.apl.mpd_mvc.model.PADDPrice;
	import com.esri.apl.mpd_mvc.model.Vehicle;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	import mx.rpc.AsyncResponder;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.utils.StringUtil;
	
	import spark.components.Application;
	import spark.effects.Fade;
	
	public class Controller extends UIComponent
	{
		private const model			: Model = Model.instance;
		private const METERS_PER_MILE:Number = 1609.344;
		private const CONFIG_FILE	: String = "com/esri/apl/mpd_mvc/assets/config/config.xml";
		private const STATE2PADD_FILE:String = "com/esri/apl/mpd_mvc/assets/data/States2PADD.xml";
		

		[Bindable]
		private var config			: XML;
		
		// Esri services: the urls will be taken from the config file once it's read
		private var qryState		: Query = new Query();
		private var qtState			: QueryTask = new QueryTask();
		private var gpDriveZones	: Geoprocessor = new Geoprocessor();

		private var processingWnd	: Processing;
		
		public function Controller()
		{
			super();

			addEventListener( Event.ADDED_TO_STAGE, setEventListeners );
//			setEventListeners( new Event( "test" ) );
			
			// Load State-PADD mapping
			var htsPADD:HTTPService = new HTTPService();
			htsPADD.url = STATE2PADD_FILE;
			htsPADD.resultFormat = HTTPService.RESULT_FORMAT_E4X;
			htsPADD.addEventListener( FaultEvent.FAULT, genericHTSFault );
			htsPADD.addEventListener( ResultEvent.RESULT, function( event:ResultEvent ):void {
				model.state2PADD = XML(event.result);
			});
			htsPADD.send();
			
			// Load config data; continue initialization in init() routine
			var htsConfig:HTTPService = new HTTPService();
			htsConfig.url = CONFIG_FILE;
			htsConfig.addEventListener( ResultEvent.RESULT, init );
			htsConfig.addEventListener( FaultEvent.FAULT, genericHTSFault );
			htsConfig.resultFormat = HTTPService.RESULT_FORMAT_E4X;
			htsConfig.send();
		}
		
		private function genericHTSFault( event:FaultEvent ):void {
			Alert.show( event.fault.message.toString() );
		}
	
		/**
		 * Initialization that depends on the availability of config-file information.
		 **/
		private function init( event:ResultEvent ):void {
			config = XML(event.result);
			
			qtState.url = config.gasRegionQuery;
			gpDriveZones.url = config.svcAreaGP;
			model.baseMapUrl = config.baseMap;
			
			// Load gas prices XML
			var ulGasPrices:URLLoader = new URLLoader();
			ulGasPrices.dataFormat = URLLoaderDataFormat.BINARY;
			ulGasPrices.addEventListener( Event.COMPLETE, loadGasPrices );
			ulGasPrices.addEventListener( IOErrorEvent.IO_ERROR, function( event:IOErrorEvent ):void {
				hideProcessingWindow();
				Alert.show("Error loading gas prices:\n" + event.text);
			});
			
			showProcessingWindow( "Loading gas price data..." );
			ulGasPrices.load( new URLRequest( config.gasPriceData.toString() ) );
			
			// Load vehicle XML
			var htsVehicles:HTTPService = new HTTPService(); htsVehicles.url = config.vehicleEconomyData;
			htsVehicles.resultFormat = HTTPService.RESULT_FORMAT_E4X;
			htsVehicles.addEventListener( ResultEvent.RESULT, function( event:ResultEvent ):void {
				model.vehiclesXML = XML(event.result);
				// Set model year list; it shouldn't change
				for each ( var v:Vehicle in model.vehicles ) {
					var vehiclesXML:XML = model.vehiclesXML.copy();
					var uniqueYears:Object = {};
					v.availableYears.source = vehiclesXML.vehicle.( uniqueYears[ @year ] == undefined ? uniqueYears[ @year ] = @year : false ).@year;
/*					var srt:Sort = new Sort();
					srt.fields = [ new SortField() ];
					v.availableYears.sort = srt;
					v.availableYears.refresh();*/
				}
			});
			htsVehicles.send();
		}

		private function setEventListeners( event:Event ):void {
			// Combo selection events
			systemManager.addEventListener( VehicleParameterSelectedEvent.YEAR, onYearSelected );
			systemManager.addEventListener( VehicleParameterSelectedEvent.MAKE, onMakeSelected );
			systemManager.addEventListener( VehicleParameterSelectedEvent.MODEL, onModelSelected );
			systemManager.addEventListener( VehicleParameterSelectedEvent.ENGINE, onEngineSelected );
			// Clear-vehicle event
			systemManager.addEventListener( VehicleParameterSelectedEvent.CLEARSELECTION, onVehicleCleared );
			// Location-clicked event
			systemManager.addEventListener( LocationSelectedEvent.LOCATION_SELECTED, onLocationSelected );
		}
		
		/**
		 * Special code to parse the Department of Energy's Excel spreadsheet on U.S. gas prices.
		 **/
		private function loadGasPrices( event:Event ):void {
			hideProcessingWindow();

			var data:ByteArray = URLLoader(event.target).data;
			var excGasPrices:ExcelFile = new ExcelFile();
			excGasPrices.loadFromByteArray( data );
			var sheet:Sheet = excGasPrices.sheets[ 2 ];
			var nLastRow:uint = sheet.rows - 2;
			
			model.paddPrices = new ArrayCollection();
			model.paddPrices.addItem( new PADDPrice( "I-A", sheet.getCell( nLastRow, Model.COL_PADD_IA ).value ) );
			model.paddPrices.addItem( new PADDPrice( "I-B", sheet.getCell( nLastRow, Model.COL_PADD_IB ).value ) );
			model.paddPrices.addItem( new PADDPrice( "I-C", sheet.getCell( nLastRow, Model.COL_PADD_IC ).value ) );
			model.paddPrices.addItem( new PADDPrice( "II", sheet.getCell( nLastRow, Model.COL_PADD_II ).value ) );
			model.paddPrices.addItem( new PADDPrice( "III", sheet.getCell( nLastRow, Model.COL_PADD_III ).value ) );
			model.paddPrices.addItem( new PADDPrice( "IV", sheet.getCell( nLastRow, Model.COL_PADD_IV ).value ) );
			model.paddPrices.addItem( new PADDPrice( "V", sheet.getCell( nLastRow, Model.COL_PADD_V ).value ) );
			
//			model.gasPriceDataAsOf = Sheet(excGasPrices.sheets[ 0 ]).getCell( Model.ROW_GASPRICEDATE, Model.COL_GASPRICEDATE ).value;
//			var genInfoSheet:Sheet = excGasPrices.sheets[ 0 ];
//			var cell:Cell = genInfoSheet.getCell( 10, 2 );
//			var sVal:String = cell.toString();
		}
		
		/*== UI event handlers ==*/

		private function onVehicleCleared( event:VehicleParameterSelectedEvent ):void {
			var v:Vehicle = model.vehicles[ event.vehicleIndex ] as Vehicle;
			v.clear();			
		}
		
		private function onYearSelected( event:VehicleParameterSelectedEvent ):void {
			if ( event.valueSelected == null ) return;

			var v:Vehicle = model.vehicles[ event.vehicleIndex ] as Vehicle;
			
			v.selectedYear = event.valueSelected;
			// Clear selected and available makes, models, engines
			v.selectedMake = v.selectedModel = v.selectedEngine = null;
			v.availableMakes.source = v.availableModels.source = v.availableEngines.source = null;
			// Filter available makes
			var uniqueMakes:Object = {};
			v.availableMakes.source = model.vehiclesXML.vehicle.(
				@year == v.selectedYear && 
				uniqueMakes[@make] == undefined ? uniqueMakes[@make] = @make : false 
				).@make;
		}
		private function onMakeSelected( event:VehicleParameterSelectedEvent ):void {
			if ( event.valueSelected == null ) return;

			var v:Vehicle = model.vehicles[ event.vehicleIndex ] as Vehicle;
			v.selectedMake = event.valueSelected;
			// Clear selected and available models and engines
			v.selectedModel = v.selectedEngine = null;
			v.availableModels.source = v.availableEngines.source = null;
			// Filter available models
			var uniqueModels:Object = {};
			v.availableModels.source = model.vehiclesXML.vehicle.(
				@year == v.selectedYear &&
				@make == v.selectedMake &&
				uniqueModels[@model] == undefined ? uniqueModels[@model] = @model : false 
				).@model;
		}
		private function onModelSelected( event:VehicleParameterSelectedEvent ):void {
			if ( event.valueSelected == null ) return;

			var v:Vehicle = model.vehicles[ event.vehicleIndex ] as Vehicle;
			v.selectedModel = event.valueSelected;
			// Clear selected and available engines
			v.selectedEngine = null;
			v.availableEngines.source = null;			
			// Filter available engines
			var uniqueEngines:Object = {};
			v.availableEngines.source = model.vehiclesXML.vehicle.(
				@year == v.selectedYear &&
				@make == v.selectedMake &&
				@model == v.selectedModel &&
				uniqueEngines[@engine] == undefined ? uniqueEngines[@engine] = @engine : false
				).@engine;
			// Select the first one if there's only one choice
//			if ( v.availableEngines.length == 1 )
//				systemManager.dispatchEvent( new VehicleParameterSelectedEvent( event.vehicleIndex, v.availableEngines[ 0 ], VehicleParameterSelectedEvent.ENGINE ) );
		}
		private function onEngineSelected( event:VehicleParameterSelectedEvent ):void {
			if ( event.valueSelected == null ) return;

			var v:Vehicle = model.vehicles[ event.vehicleIndex ] as Vehicle;
			v.selectedEngine = event.valueSelected;
			
			// Find and note the vehicle's fuel economy.
			v.selectedGasMileage = model.vehiclesXML.vehicle.(
				@year == v.selectedYear.valueOf() &&
				@make == v.selectedMake.valueOf() &&
				@model == v.selectedModel.valueOf() &&
				@engine == v.selectedEngine.valueOf()
				)[ 0 ].@mpg;
		}
		
		private function onLocationSelected( event:LocationSelectedEvent ):void {
			model.findingDriveZones = true;
			findSelectedState( event.location );
			
			model.clickLocGraphicProvider.removeAll();
			model.clickLocGraphicProvider.addItem( event.location );
		}
	
		private function findSelectedState( location:Graphic ):void {
			qryState.outFields = [ "*" ];
			qryState.returnGeometry = false;			
			qryState.geometry = location.geometry;
			qtState.execute( qryState, new AsyncResponder( findDriveZones, onTaskFault, location ) );
			showProcessingWindow( "Processing..." );
		}

		private function onTaskFault( fault:Fault, token:Object ):void {
			hideProcessingWindow();
			Alert.show( "Error #" + fault.errorID + " finding results: " + fault.message );
		}
		
		private function findDriveZones( state:FeatureSet, token:Graphic ):void {
			// Get point geometry into featureset GP parameter
			var fs:FeatureSet = new FeatureSet( [ token ] );
			
			// Get cost per gallon: look up PADD price from selected state
			var sState:String = state.attributes[ 0 ].STATE;
			var sRegion:String = model.state2PADD.state.( @name == sState ).@padd[ 0 ].toString();
			var matchingPADD:PADDPrice = model.paddPrices.source.filter( function( o:PADDPrice, i:int, a:Array ):Boolean {
				return ( o.padd == this );
			}, sRegion )[ 0 ];
			
			var nPrice:Number = matchingPADD.gasPrice;
			model.selectedRegion = "PADD Region " + matchingPADD.padd;
			model.selectedGasPrice = nPrice;

			// Get driving distances for all vehicles 
			var arySelVehicles:Array = model.vehicles.source.filter( function( v:Vehicle, i:int, a:Array ):Boolean {
				return v.vehicleSelected;
			});
			var aDists:Array = arySelVehicles.map( function( v:Vehicle, i:int, a:Array ):Object {
				// miles per dollar = (miles/gal) * (1 / (cost / gal))
				return v.milesPerDollar( nPrice );
			});		
			var sDists:String = aDists.join( " " );
			
			// Invoke the GP model
			var params:Object = { "Start_Location":fs , "Distances":StringUtil.trim( sDists ) };
			gpDriveZones.useAMF = false;
			gpDriveZones.execute( params, new AsyncResponder( onDriveZonesFound, onTaskFault, token ) ); 
			
			// Invoke the NA service
			// Set params for new, improved service
/* 			saDriveZonesParams.impedanceAttribute = "Length";
			var aDists:Array = [];
			for ( var nVehicle:Number = 0; nVehicle < _VehicleSelected.length; nVehicle++ ) { 
			if ( _VehicleSelected[ nVehicle ] ) 
			aDists.push( Number(m_VehicleInfo[ nVehicle ][ "txtMPG" ].text) );
			}
			
			// Solve for an answer
			saDriveZonesParams.facilities = fs;
			saDriveZonesParams.defaultBreaks = aDists;
			saDriveZones.solve( saDriveZonesParams );*/	
		}
	
		private function onDriveZonesFound( event:Object, chosenLocation:Graphic ):void {
			try {
				var fsDriveZones:FeatureSet = null;
//				if ( event is ExecuteResult )
				fsDriveZones = event.results[ 0 ].value;
//				else if ( event is ServiceAreaEvent )
//					fsDriveZones = new FeatureSet( ServiceAreaEvent(event).serviceAreaSolveResult.serviceAreaPolygons );
				
				// Need to find the right vehicle with which to associate each result polygon.
				// The GP service returns polygons in order from largest to smallest.
				// So we'll split the vehicles into selected and non-selected buckets.
				// Non-selected vehicles get their data provider set to null and don't show on the map.
				// The number of selected vehicles should match the number of results. We'll sort 
				// the selected vehicles by drive distance; we'll sort the results by area. Then vehicles
				// should match up with results.
				var arySelVehicles:Array = model.vehicles.source.filter( function( v:Vehicle, i:int, a:Array ):Boolean {
					return v.vehicleSelected;
				});
				var aryUnselVehicles:Array = model.vehicles.source.filter( function( v:Vehicle, i:int, a:Array ):Boolean {
					return !v.vehicleSelected;
				});
				
				for each ( var v:Vehicle in aryUnselVehicles ) {
					model.vehicles.getItemAt( v.vehicleIndex ).graphicProvider = null;
				}
				
				// Should properly sort on miles per dollar, but MPG will return the same results
				var arySelVehiclesSorted:Array = arySelVehicles.sortOn( "selectedGasMileage", Array.NUMERIC );
				
				var aryResultsSorted:Array = fsDriveZones.features.sort( 
					function( a:Graphic, b:Graphic ):int {
						var nExtentAreaA:Number = a.geometry.extent.width * a.geometry.extent.height;
						var nExtentAreaB:Number = b.geometry.extent.width * b.geometry.extent.height;
						if ( nExtentAreaA < nExtentAreaB ) return -1;
						else if ( nExtentAreaA > nExtentAreaB ) return 1;
						else return 0;
					});
				for ( var i:int = 0; i < arySelVehiclesSorted.length; i++ ) {
					var g:Graphic = Graphic(aryResultsSorted[ i ]);	
					
					// Set effect to play
//					var fxT:RadarTrace_Percent_Effect = new RadarTrace_Percent_Effect();// fxT.duration = 1500;
					var fxF:Fade = new Fade(); fxF.alphaFrom = 0; fxF.alphaTo = 1; fxF.duration = 750;
//					fxF.easer = new Power( 1.0, 2 );
//					var fxP:Parallel = new Parallel(); fxP.duration = 2000;
//					fxP.addChild( fxT ); fxP.addChild( fxF );
					g.setStyle( "addedEffect", fxF );
					
					Vehicle(model.vehicles.getItemAt( Vehicle(arySelVehiclesSorted[ i ]).vehicleIndex )).graphicProvider = 
						new ArrayCollection( [ g ] );
					
				}
				
				// Set the map extent to the results
				model.mapExtent = Extent(aryResultsSorted[ aryResultsSorted.length - 1 ].geometry.extent).expand( 1.25 );
				
			}
			finally {
				hideProcessingWindow();
			}
		}  
	
		private function showProcessingWindow( sMessage:String = null ):void {
			processingWnd = Processing(PopUpManager.createPopUp( Application(FlexGlobals.topLevelApplication), Processing, true ));
			processingWnd.message = sMessage;
			PopUpManager.centerPopUp( processingWnd );	
		}
		private function hideProcessingWindow():void {
			PopUpManager.removePopUp( processingWnd );
		}
	}
}