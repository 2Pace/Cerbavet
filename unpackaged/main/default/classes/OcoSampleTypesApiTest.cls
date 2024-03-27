@isTest
public class OcoSampleTypesApiTest {
    static testMethod void testSampleType() {
        // Arrange
        OcoSampleTypesApi.SampleType sample = new OcoSampleTypesApi.SampleType();
        
        // Act
        sample.Name = 'Plasma';
        
        // Assert
        System.assertEquals('Plasma', sample.Name, 'Name should be set correctly');
    }
    
    @IsTest 
    static void testGetSampleTypes() {
        // Perform test
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/oco/samples';  
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

    	// Get transportsList        
        List<OcoSampleTypesApi.SampleType> samplesList = OcoSampleTypesApi.getSampleTypes();
        Test.stopTest();
        
        // Serialize samplesList into JSON
        String jsonString = JSON.serialize(samplesList);

        // Parse JSON string to get species names
        List<Object> samplesData = (List<Object>) JSON.deserializeUntyped(jsonString);
        List<String> samplesNames = new List<String>();
        for(Object sampleObject : samplesData) {
            Map<String, Object> sampleData = (Map<String, Object>) sampleObject;
            samplesNames.add((String)sampleData.get('Name'));
        }

        // Assert result
    	System.assert(samplesNames.size() >= 3, 'There should be at least 3 samples returned');
        System.assert(samplesNames.contains('Sang'), 'Transports list should contain "Sang"');
    }
}