package com.esri.apl.mpd_mvc.model
{
	public class PADDPrice
	{
		public function PADDPrice( padd:String=null, gasPrice:Number=NaN )
		{
			if ( padd ) this.padd = padd;
			if ( gasPrice ) this.gasPrice = gasPrice;
		}
		
		private var _padd		: String;
		private var _gasPrice	: Number;

		public function get gasPrice():Number
		{
			return _gasPrice;
		}

		public function set gasPrice(value:Number):void
		{
			_gasPrice = value;
		}

		public function get padd():String
		{
			return _padd;
		}

		public function set padd(value:String):void
		{
			_padd = value;
		}

	}
}