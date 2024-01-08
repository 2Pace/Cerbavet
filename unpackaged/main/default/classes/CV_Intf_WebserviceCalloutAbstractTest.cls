/**
 * Created by Michael on 11-07-22.
 */

@IsTest
private class CV_Intf_WebserviceCalloutAbstractTest {
    @IsTest
    static void testMode1() {

        CV_Intf_WebserviceCalloutDummy.mode = 1;

        Test.startTest();

        Test.setMock(HttpCalloutMock.class,new CV_Intf_WebserviceMock());
        CV_Intf_WebserviceCalloutDummy webserviceDummyCallout = new CV_Intf_WebserviceCalloutDummy();
        webserviceDummyCallout.executeCallout(new List<String>{'Test'});

        Test.stopTest();

        List<Interface_Monitoring__c> interfaceMonitorings = new List<Interface_Monitoring__c>([SELECT Id, Message_Id__c, Outgoing_Message__c, Response_Message__c FROM Interface_Monitoring__c]);
        System.assert(!interfaceMonitorings.isEmpty());

    }

    @IsTest
    static void testMode2() {

        CV_Intf_WebserviceCalloutDummy.mode = 2;

        List<String> payload = new List<String>();
        for (Integer i = 0; i < 95 ; i++) {
            payload.add('Test' + 1);
        }

        Test.startTest();

        Test.setMock(HttpCalloutMock.class,new CV_Intf_WebserviceMock());
        CV_Intf_WebserviceCalloutDummy webserviceDummyCallout = new CV_Intf_WebserviceCalloutDummy();
        webserviceDummyCallout.executeCallout(payload);

        Test.stopTest();

        List<Interface_Monitoring__c> interfaceMonitorings = new List<Interface_Monitoring__c>([SELECT Id, Message_Id__c, Outgoing_Message__c, Response_Message__c FROM Interface_Monitoring__c]);
        System.assert(!interfaceMonitorings.isEmpty());

    }

    @IsTest
    static void testRegisteringMonitoringMessage() {

        Test.startTest();

        CV_Intf_WebserviceCalloutDummy webserviceDummyCallout = new CV_Intf_WebserviceCalloutDummy();
        webserviceDummyCallout.registerMonitoningMessage('Test', null, 'TEST', 200, false, '123456789ab', false);

        webserviceDummyCallout.registerMonitoningMessage('Test', 'ResponseOK', 'TEST', 200, false, '123456789ab', true);

        Test.stopTest();

        Interface_Monitoring__c interfaceMonitoring = [SELECT Id, Message_Id__c, Outgoing_Message__c, Response_Message__c FROM Interface_Monitoring__c WHERE Message_Id__c = '123456789ab'];
        System.assertEquals('Test', interfaceMonitoring.Outgoing_Message__c);
        System.assertEquals('ResponseOK', interfaceMonitoring.Response_Message__c);

    }
}