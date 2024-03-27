@RestResource(urlMapping='/oco/billing-countries')
global with sharing class OcoBillingCountriesApi {
    
    global class BillingCountry {
        public String Name { get; set; }
        public Decimal VAT { get; set; }
        public String LegalEntityName { get; set; }
        public String LegalEntityNumber { get; set; }
    }
    
    @HttpGet
    global static List<BillingCountry> getBillingCountries() 
    {
        // Get data from blng__TaxRate__c
        List<blng__TaxRate__c> result = [SELECT blng__Country__c, blng__Rate__c FROM blng__TaxRate__c];                                            
        
        // Fill list of custom BillingCountry
        List<BillingCountry> countryList = new List<BillingCountry>();
        for (Integer index = 0; index < result.size(); index++) 
        {
            // Create new BillingCountry and fill its properties
            BillingCountry obj = new BillingCountry();
            obj.Name = result[index].blng__Country__c;
            obj.VAT = result[index].blng__Rate__c;
            //obj.LegalEntityName = blng__LegalEntity__r.name;
            //obj.LegalEntityNumber = blng__LegalEntity__r.LEgalEntityNumber__c;
            // Add it to the list
            countryList.add(obj);
        }
        
        // Return list
        return countryList;
    }
}