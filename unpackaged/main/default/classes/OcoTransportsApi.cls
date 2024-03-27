@RestResource(urlMapping='/oco/transport-types')
global with sharing class OcoTransportsApi {
    
    global class Transport {
        public String Name { get; set; }
        public String Code { get; set; }
        public Double Price { get; set; }
    }
    
    @HttpGet
    global static List<Transport> getTransportTypes() {

        // Setup the multipick list name according along with its parent object
        String strObjectName = 'Account';
        String strPicklistField = 'Type_de_Transport_oco__c';
        
        // Get multipick list value map
        Map<String, String> mapPickListValues = new Map<String, String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(strPicklistField).getDescribe().getPickListValues();
        
        // Create OCO Transport type list from value map
        List<Transport> transportsList = new List<Transport>();
        for (Schema.PicklistEntry objPickList : lstPickListValues) {
            // Split string to get 'name,code,price'
            List<String> splittedString = objPickList.getValue().split(',');
            // Create transport object
            Transport transport = new Transport();
			transport.Code = splittedString[0];  
			transport.Name = splittedString[1];
			transport.Price = (splittedString[2].isNumeric() || splittedString[2] == '-1') ? Double.valueOf(splittedString[2]) : 0.0;  
            transportsList.add(transport);
        }
        
        // Set http response
        RestResponse response = RestContext.response;
        response.statusCode = 200;

        // Return list
        return transportsList;
    }
}