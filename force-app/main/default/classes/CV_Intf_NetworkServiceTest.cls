/**
 * Created by Michael on 11-07-22.
 */

@IsTest
private class CV_Intf_NetworkServiceTest {
    @IsTest
    static void testBehaviorGet() {

        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new CV_Intf_WebserviceMock());

        CV_Intf_RequestInput rq = new CV_Intf_RequestInput('URL', 'GET', 'PARAM');

        CV_Intf_NetworkService ns = new CV_Intf_NetworkService();

        CV_Intf_ServiceResult sr = ns.execute(rq);

        Test.stopTest();

    }
    @IsTest
    static void testBehaviorPost() {

        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new CV_Intf_WebserviceMock());

        CV_Intf_RequestInput rq = new CV_Intf_RequestInput('URL', 'POST', '{"test":"PARAM"}');

        CV_Intf_NetworkService ns = new CV_Intf_NetworkService();

        CV_Intf_ServiceResult sr = ns.execute(rq);

        Test.stopTest();

    }

}