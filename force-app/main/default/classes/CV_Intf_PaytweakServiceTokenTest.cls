@isTest
public with sharing class CV_Intf_PaytweakServiceTokenTest {      
    @isTest
    static void testGetWorkToken() {
        Test.startTest();
        CV_Intf_PaytweakServiceToken.securityToken = '6497e10218946dd24a61407c009b00c7381832b1f719b452';    
        // Set up test data 
        CV_Intf_WebserviceMock.status = 200;
        CV_Intf_WebserviceMock.interfaceToTest = 'GETTOKEN';
        Test.setMock(HttpCalloutMock.class, new CV_Intf_WebserviceMock());
                
        // Call the method to test
        String workToken = CV_Intf_PaytweakServiceToken.getWorkToken();
        System.debug('*** WorktokenValue == ' + workToken);
                
        // Add assertions to verify the results
        System.assertEquals(workToken, '0M0ATl0YI4OY');
                
        Test.stopTest();
    }
}