@RestResource(urlMapping='/oco/correspondent/*')
global with sharing class OcoCorrespondentApi {
       
    global class Correspondent {
        public String Code { get; set; }
        public String Name { get; set; }
        public Boolean NonBillable { get; set; }
        public String BillingCountry { get; set; }
        public String BillingCountryCode { get; set; }
        public String Siret { get; set; }
        public String PricebookId { get; set; }
        public String PricebookName { get; set; }
        public Double VAT { get; set; }
        public String CurrencyIsoCode { get; set; }
        public string BillingEntityId { get; set; }
        public string BillingEntityName { get; set; }
        public string Email { get ;set; }
        public string Address { get; set; }
        public string ZipCode { get; set; }
        public string City { get; set; }
        public Double CourierPrice { get; set; }
        public Double ReducedCourierPrice { get; set; }
        // TODO: marché
    }
    
    public static String getContentAfterTwoFirstHyphens(String inputString) {
        List<String> parts = inputString.split('-', 4);
        if (parts.size() >= 4) {
            return parts[3];
        }
        return '';
    }
    
    public static Correspondent getCorrespondentBillingInformations(Correspondent correspondent) {       
        // Get pricebooks
        Pricebook2 cerbaVetPricebook = [SELECT Id, Name from Pricebook2 WHERE Name LIKE 'CerbaVet' LIMIT 1];
        Pricebook2 DOMPricebook = [SELECT Id, Name from Pricebook2 WHERE Name LIKE 'CerbaVet DOM' LIMIT 1];
        Pricebook2 TOMExportPricebook = [SELECT Id, Name from Pricebook2 WHERE Name LIKE 'Cerbavet TOM et Export' LIMIT 1];

        // Get billing entities
        blng__LegalEntity__c swissLegalEntity = [SELECT Id, Name FROM blng__LegalEntity__c WHERE Name LIKE 'Cerbavet Suisse%' LIMIT 1];
        blng__LegalEntity__c franceLegalEntity = [SELECT Id, Name FROM blng__LegalEntity__c WHERE Name LIKE 'Cerbavet France%' LIMIT 1];
        
        // Get VAT
        blng__TaxRate__c franceVAT = [SELECT blng__Rate__c FROM blng__TaxRate__c WHERE blng__TaxCode__c like 'TRFM' LIMIT 1];   
        blng__TaxRate__c swissVAT = [SELECT blng__Rate__c FROM blng__TaxRate__c WHERE blng__TaxCode__c like 'TRCH' LIMIT 1];   
        blng__TaxRate__c domVAT = [SELECT blng__Rate__c FROM blng__TaxRate__c WHERE blng__TaxCode__c like 'TRDOM' LIMIT 1];   
        blng__TaxRate__c exportVAT = [SELECT blng__Rate__c FROM blng__TaxRate__c WHERE blng__TaxCode__c like 'TRE' LIMIT 1];   
        
        // Correspondent is from Swiss
        if (correspondent.Code.substring(0, 2).toUpperCase() == 'CH') {
            // Set billing entity
            correspondent.BillingEntityId = swissLegalEntity.Id;
            correspondent.BillingEntityName = swissLegalEntity.Name;
            // Set pricebook
			correspondent.PricebookId = cerbaVetPricebook.Id;         
			correspondent.PricebookName = cerbaVetPricebook.Name;         
            // Set VAT
			correspondent.VAT = swissVAT.blng__Rate__c;         
        }
        // Correspondent is from France
        else {
            // Set billing entity
            correspondent.BillingEntityId = franceLegalEntity.Id;
            correspondent.BillingEntityName = franceLegalEntity.Name;

            // Correspondent is from DOM
            if (correspondent.Code.substring(0, 2).toUpperCase() == '97') {
                correspondent.PricebookId = DOMPricebook.Id;         
                correspondent.PricebookName = DOMPricebook.Name;         
                correspondent.VAT = domVAT.blng__Rate__c;    
            }
            // Correspondent is from France
            else if (correspondent.BillingCountryCode == 'FR' || correspondent.BillingCountry.toUpperCase() == 'FRANCE') {
				correspondent.PricebookId = cerbaVetPricebook.Id;         
                correspondent.PricebookName = cerbaVetPricebook.Name;         
                correspondent.VAT = franceVAT.blng__Rate__c;    
            }
            // Correspondent is TOM & Export
            else {
				correspondent.PricebookId = TOMExportPricebook.Id;         
                correspondent.PricebookName = TOMExportPricebook.Name;         
                correspondent.VAT = exportVAT.blng__Rate__c;   
            }
        }
        return correspondent;
    }
    
    @HttpGet
    global static Correspondent getCorrespondentData() {
		// Get code from parameters
		RestRequest request = RestContext.request;
        String code = request.params.get('code').ToUpperCase();
        RestResponse response = RestContext.response;
  
        // Error handling
        if (code == null || code == '' || code == ' ') {
            response.statusCode = 400;
            return null;
        }
    
        // Get account by code
        List<Account> accounts = [SELECT Code_compte_metier__c, Name, Conditions_de_Reglement_Cerbavet__c, BillingCountry, 
                                  BillingCountryCode, SIRET__c, CurrencyIsoCode,
                                  Adresse_Email__c, BillingStreet, BillingCity, BillingPostalCode,
                                  Facturation_coursier__c, Facturation_coursier_reduit__c
                                  FROM Account 
                                  WHERE Name LIKE 'hex-119%'
                                  AND Code_compte_metier__c LIKE :code
                                  LIMIT 1];
    
        // Error handling
        if (accounts.isEmpty()) {
            response.statusCode = 404;
            return null;
        }
    
		// Get the first account from the list
        Account account = accounts[0];
        
        // Create correspondent object with custom data
        Correspondent correspondent = new Correspondent();
        correspondent.Code = account.Code_compte_metier__c;
        correspondent.Name = getContentAfterTwoFirstHyphens(account.name);
        correspondent.NonBillable = (account.Conditions_de_Reglement_Cerbavet__c == 'Non Régleur') ? true : false;
        correspondent.BillingCountry = account.BillingCountry;
        correspondent.BillingCountryCode = account.BillingCountryCode;
        correspondent.Siret = string.ValueOf(account.SIRET__c);
        correspondent.CurrencyIsoCode = account.CurrencyIsoCode;
        correspondent.Email = account.Adresse_Email__c;
        correspondent.Address = account.BillingStreet;
        correspondent.ZipCode = account.BillingPostalCode;
        correspondent.City = account.BillingCity;
        correspondent.CourierPrice = account.Facturation_coursier__c;
        correspondent.ReducedCourierPrice = account.Facturation_coursier_reduit__c;

        
        // Get billing informations
        correspondent = getCorrespondentBillingInformations(correspondent);
        
        // Build response
        response.statusCode = 200;
        return correspondent;
    }
}