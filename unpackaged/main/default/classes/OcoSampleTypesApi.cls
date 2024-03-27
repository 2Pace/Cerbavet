@RestResource(urlMapping='/oco/samples')
global with sharing class OcoSampleTypesApi {
    
    global class SampleType {
        public String Name { get; set; }
    }
    
    @HttpGet
    global static List<SampleType> getSampleTypes() {
        
        // Setup the multipick list name according along with its parent object
        String strObjectName = 'Product2';
        String strPicklistField = 'Nature_des_prelevements__c';
        
        // Get multipick list value map
        Map<String, String> mapPickListValues = new Map<String, String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(strPicklistField).getDescribe().getPickListValues();
        
        // Create OCO SampleType list from value map
        List<SampleType> sampleTypesList = new List<SampleType>();
        for (Schema.PicklistEntry objPickList : lstPickListValues) 
        {
            // Create SampleType object and add it to list  
            SampleType sampleType = new SampleType();
            sampleType.Name = objPickList.getValue(); 
            sampleTypesList.add(sampleType);                
        }

        // Return list
        return sampleTypesList;
    }
}