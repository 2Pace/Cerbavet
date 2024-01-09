/**
 * @description       : Schema class useful to model the Paytweak JSON 
 * @author            : Ingrid OMAR
 * @last modified on  : 02/01/2024
 * @last modified by  : Ingrid OMAR
 * Ver   Date         Author          Modification
 * 1.0   02/01/2024   Ingrid OMAR   Initial Version
**/

@SuppressWarnings('PMD.VariableNamingConventions, PMD.ExcessivePublicCount,PMD.TooManyFields')
public abstract class CV_Intf_PaytweakJSONSchemBuilder {

	public class PaymentOrder {
		public Items items 	         			{ get; set; }
        public Decimal amount 	         	    { get; set; }
        public String address_customer          { get; set; }
        public String city                      { get; set; }
        public String cur                       { get; set; } // Currency
        public String email                     { get; set; }
        public String phone                     { get; set; }
        public String reference                 { get; set; } // Votre Numéro de facture
        public String zip                       { get; set; }
        public String date                      { get; set; } // Date de création de la facture
        public String due                       { get; set; } // Date échéance facture
        public String order_id                  { get; set; }
        public String salesforceId              { get; set; }
        public Boolean isPaymentCheck           { get; set; }
        public String expirationDate            { get; set; }          
        public String company                   { get; set; }
	}

	public class Items {
		public List<ItemItem> items { get; set; }
	}

	public class ItemItem {
        public String vat                      { get; set; }
        public String desc                     { get; set; }
        public String ref                      { get; set; }
        public String quantity                 { get; set; }
        public String price                    { get; set; }
	}
}