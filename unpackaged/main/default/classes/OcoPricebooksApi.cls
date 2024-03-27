@RestResource(urlMapping='/oco/pricebooks')
global with sharing class OcoPricebooksApi {
  
    global class PricebookItem {      
        public String PricebookId { get; set; }
        public String PricebookName { get; set; }
        public String CurrencyIsoCode { get; set; }
        public Double UnitPrice { get; set; }
        public String ExamCode { get; set; }
    }
    
    // Endpoint to get all pricebook data
    @HttpGet
    global static List<PricebookItem> getPricebookEntries() {       
        // Get exams from Salesforce table
        List<PricebookEntry> result = [SELECT Pricebook2.Name, Pricebook2.Id, UnitPrice, Pricebook2.CurrencyIsoCode, Product2.ProductCode 
                                 FROM PricebookEntry WHERE Pricebook2.IsActive = true];
        
        // Create custom PricebookEntry object list
        List<PricebookItem> pricebookItemsList = new List<PricebookItem>();
        
        // Fill list with Salesforce data
        for (Integer index = 0; index < result.size(); index++) {
            // Create custom PricebookItem model
	        PricebookItem pricebookItem = new PricebookItem();
            
            // Fill the model data
			PricebookItem.PricebookId = result[index].Pricebook2.Id;
			PricebookItem.PricebookName = result[index].Pricebook2.Name;
			PricebookItem.CurrencyIsoCode = result[index].Pricebook2.CurrencyIsoCode;
			PricebookItem.UnitPrice = result[index].UnitPrice;
			PricebookItem.ExamCode = result[index].Product2.ProductCode;

            // Add PricebookItem model to the list
            pricebookItemsList.add(pricebookItem);
        }
        
        // Return the created list
        return pricebookItemsList;
    }
}