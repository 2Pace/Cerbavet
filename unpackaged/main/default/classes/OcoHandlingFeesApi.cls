@RestResource(urlMapping='/oco/handling-fees')
global with sharing class OcoHandlingFeesApi {
  
    global class HandlingFeeItem {      
        public String PricebookId { get; set; }
        public String PricebookName { get; set; }
        public Double UnitPrice { get; set; }
        public String ExamCode { get; set; }
        public String ExamName { get; set; }
    }
    
    // Endpoint to get all handling fees
    @HttpGet
    global static List<HandlingFeeItem> getHandlingFees() {       
        // Get handling fees items from Salesforce table
        List<PricebookEntry> result = [SELECT Pricebook2.Id, Pricebook2.Name, UnitPrice, 
                                       Product2.ProductCode, Product2.Name FROM PricebookEntry 
                                       WHERE Pricebook2.IsActive = true 
                                       AND Product2.ProductCode like 'FDD8%'];
        
        // Create custom HandlingFeeItem object list
        List<HandlingFeeItem> handlingFeeItemList = new List<HandlingFeeItem>();
        
        // Fill list with Salesforce data
        for (Integer index = 0; index < result.size(); index++) {
            // Create custom HandlingFeeItem model
	        HandlingFeeItem handlingFeeItem = new HandlingFeeItem();
            
            // Fill the model data
			handlingFeeItem.PricebookId = result[index].Pricebook2.Id;
			handlingFeeItem.PricebookName = result[index].Pricebook2.Name;
			handlingFeeItem.UnitPrice = result[index].UnitPrice;
			handlingFeeItem.ExamCode = result[index].Product2.ProductCode;
			handlingFeeItem.ExamName = result[index].Product2.Name;

            // Add handlingFeeItem model to the list
            handlingFeeItemList.add(handlingFeeItem);
        }
        
        // Return the created list
        return handlingFeeItemList;
    }
}