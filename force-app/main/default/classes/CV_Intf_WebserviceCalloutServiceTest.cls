/**
 * Created by Michael on 11-07-22.
 */

@IsTest
private class CV_Intf_WebserviceCalloutServiceTest {
    @IsTest
    static void testPositiveCallout() {

        String interfaceName = 'TEST';
        String caller = 'CV_Intf_WebserviceCalloutDummy';
        String payload = JSON.serialize(new List<String>{'TESTString'});
        String namedCredential = 'testCallout';

        CV_Intf_WebserviceMock.status = 200;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new CV_Intf_WebserviceMock());

        CV_Intf_WebserviceCalloutService.calloutWebservice(payload, namedCredential, caller, interfaceName, new Map<String, String>(), 'POST');
        List<CV_Intf_WebserviceCalloutService.ResponseModel> responses = CV_Intf_WebserviceCalloutService.calloutWebserviceBatch(payload, namedCredential, caller, interfaceName, new Map<String, String>(), 'POST');
        System.debug('============================= TEST TEST responses: ' + responses);

        CV_Intf_WebserviceCalloutService.fireFutureCallout(payload, namedCredential, caller, interfaceName, new Map<String, String>(), new Map<String, String>{'TESTString' => 'PAYLOADSTring'}, 'POST');

        System.debug('============================= TEST TEST Interface Monitoring: ' + [SELECT Id, Response_Message__c FROM Interface_Monitoring__c]);

        Test.stopTest();

        Interface_Monitoring__c interfaceMonitoring = [SELECT Id, Response_Message__c FROM Interface_Monitoring__c];
        System.assertEquals('OK', interfaceMonitoring.Response_Message__c);

    }

    @IsTest
    static void testNegativeCallout() {

        String interfaceName = 'TEST';
        String caller = 'CV_Intf_WebserviceCalloutDummy';
        String payload = JSON.serialize(new List<String>{'TESTString'});
        String namedCredential = 'testCallout';
        CV_Intf_WebserviceMock.status = 403;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new CV_Intf_WebserviceMock());

        try {
            CV_Intf_WebserviceCalloutService.calloutWebservice(payload, namedCredential, caller, interfaceName, new Map<String, String>(), 'POST');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Unauthorized'));
        }

        Test.stopTest();

    }
}