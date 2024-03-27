@RestResource(urlMapping='/oco/degressive-pricing')
global with sharing class  OcoDegressivePricingApi {
    
    global class DegressivePrice {
        public String Name { get; set; }
        public Double Discount { get; set; }
        public Integer LowerBound { get; set; }
        public Integer UpperBound { get; set; }
    }

    public static Integer decimalToInt(Decimal d) {
        try {
            return d.round().intValue();
        } 
        catch (Exception e) {
            System.debug('An error happened : ' + e.getMessage());
            return 0;
        }
    }

    @HttpGet
    global static List<DegressivePrice> getDegressivePrices() {
        
        // Get price reductions from metadata
        List<CV_Prix_Degressif__mdt> result = [SELECT DeveloperName, Discount__c, LowerBound__c, UpperBound__c 
                                        FROM CV_Prix_Degressif__mdt];

        // Create custom DegressivePrice object list
        List<DegressivePrice> degressivePriceList = new List<DegressivePrice>();
        
        // Fill list with Salesforce data
        for (Integer index = 0; index < result.size(); index++) {
            // Create custom DegressivePrice model
	        DegressivePrice degressivePrice = new DegressivePrice();
            
            // Fill informations
			degressivePrice.Name = result[index].DeveloperName;
			degressivePrice.Discount = result[index].Discount__c;
			degressivePrice.LowerBound = decimalToInt(result[index].LowerBound__c);
			degressivePrice.UpperBound = decimalToInt(result[index].UpperBound__c);
            
            // Add DegressivePrice model to the list
            degressivePriceList.add(degressivePrice);
        }

        // Return the created list
        return degressivePriceList;        
    }
}