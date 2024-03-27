@RestResource(urlMapping='/oco/species')
global with sharing class OcoSpeciesApi {
    
    global class Specie {
        public String Name { get; set; }
        public String HexalisCode { get; set; }
    }
    
    @HttpGet
    global static List<Specie> getSpecies() {
        
        // Setup the multipick list name according along with its parent object
        String strObjectName = 'Product2';
        String strPicklistField = 'Espece__c';
        
        // Get multipick list value map
        Map<String, String> mapPickListValues = new Map<String, String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(strPicklistField).getDescribe().getPickListValues();
        
        // Create OCO Species list from value map
        List<Specie> speciesList = new List<Specie>();
        for (Schema.PicklistEntry objPickList : lstPickListValues) {
            // Split string to get 'specie,code'
            List<String> splittedString = objPickList.getValue().split(',');
            
            // Error handling
            if (splittedString.size() > 0) {
                Specie specie = new Specie();
                specie.Name = splittedString[0]; 
                specie.HexalisCode = (splittedString.size() > 1) ? splittedString[1] : ''; 
                speciesList.add(specie);                
            }
        }

        // Return list
        return speciesList;
    }
}