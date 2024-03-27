@isTest
private class OcoTransportsApiTest {

    @isTest static void testGetTransportTypes() {
        // Perform test
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/oco/transport-types';  
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

		// Get transportsList        
        List<OcoTransportsApi.Transport> transportsList = OcoTransportsApi.getTransportTypes();
        Test.stopTest();
        
        // Serialize transportsList into JSON
        String jsonString = JSON.serialize(transportsList);

        // Parse JSON string to get species names
        List<Object> transportsData = (List<Object>) JSON.deserializeUntyped(jsonString);
        List<String> transportsNames = new List<String>();
        for(Object transportObject : transportsData) {
            Map<String, Object> transportData = (Map<String, Object>) transportObject;
            transportsNames.add((String)transportData.get('Name'));
        }

        // Assert result
        System.assertEquals(200, res.statusCode, 'Status code should be 200 for valid code');
		System.assert(transportsNames.size() >= 3, 'There should be at least 3 transport returned');
    }
   
    @isTest
    static void testTransportClass() {
        // Create a new instance of the Transport class
        OcoTransportsApi.Transport transport = new OcoTransportsApi.Transport();
        transport.Name = 'Test Transport';
        transport.Code = 'TRANS';
        transport.Price = 6.3;

        // Verify the getter methods
        System.assertEquals('Test Transport', transport.Name, 'Name should be set correctly');
        System.assertEquals('TRANS', transport.Code, 'Code should be set correctly');
        System.assertEquals(6.3, transport.Price, 'Price should be set correctly');
    }
}