/**
 * Created by Michael on 11-07-22.
 */

@IsTest
private class CV_SalesforceIntegrationErrorTest {
    @IsTest
    static void testBehavior() {

        CV_SalesforceIntegrationError cvSalesforceIntegrationError = new CV_SalesforceIntegrationError('ERRORCODE', 'Message');
        System.assertEquals('ERRORCODE', cvSalesforceIntegrationError.errorCode);
        System.assertEquals('Message', cvSalesforceIntegrationError.message);

    }
}