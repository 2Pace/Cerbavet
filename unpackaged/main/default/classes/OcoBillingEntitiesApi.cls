@RestResource(urlMapping='/oco/billing-entities')
global with sharing class OcoBillingEntitiesApi {
    
    global class BillingEntity {
        public String BillingCountry { get; set; }
        public String LegalEntityNumber { get; set; }
        public String Name { get; set; }
        public String CurrencyIsoCode { get; set; }
        public String Street1 { get; set; }
        public String Street2 { get; set; }
        public String City { get; set; }
        public String PostalCode { get; set; }
        public String County { get; set; }
        public String State { get; set; }
        public String PhoneNumber { get; set; }
        public String Email { get; set; }
    }
    
    @HttpGet
    global static List<BillingEntity> getBillingEntities() 
    {
        // Get data from 
        List<blng__LegalEntity__c> result = [SELECT blng__Country__c, blng__LegalEntityNumber__c, Name, CurrencyIsoCode, blng__Street1__c, 
                                             blng__Street2__c, blng__City__c, blng__ZipPostalCode__c, blng__County__c, blng__State__c 
                                             FROM blng__LegalEntity__c];   
                                             //PhoneNumber__c, Email__c FROM blng__LegalEntity__c];   
        
        // Fill list of custom BillingEntity
        List<BillingEntity> entityList = new List<BillingEntity>();
        for (Integer index = 0; index < result.size(); index++) 
        {
            // Create new BillingEntity
            BillingEntity entity = new BillingEntity();

            // Update its fields
            entity.BillingCountry = result[index].blng__Country__c;
            entity.LegalEntityNumber = result[index].blng__LegalEntityNumber__c;
            entity.Name = result[index].Name;
            entity.CurrencyIsoCode = result[index].CurrencyIsoCode;
            entity.Street1 = result[index].blng__Street1__c;
            entity.Street2 = result[index].blng__Street2__c;
            entity.City = result[index].blng__City__c;
            entity.PostalCode = result[index].blng__ZipPostalCode__c;
            entity.County = result[index].blng__County__c;
            entity.State = result[index].blng__State__c;
            entity.PhoneNumber = '';//result[index].PhoneNumber__c;
            entity.Email = '';//result[index].Email__c;
            
            // Add it to the list
            entityList.add(entity);
        }

        // Return the list
        return entityList;
    }
}