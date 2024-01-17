/**
 * Created by Michael on 11-07-22.
 */

global class CV_Intf_WebserviceMock implements HttpCalloutMock {
    public static Integer status;
    public static String interfaceToTest;

    global HTTPResponse respond(HTTPRequest request) {

        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if (interfaceToTest == 'ECV') {
            response.setStatusCode(status);

        } else if (interfaceToTest == 'CDN') {

            if (status == 200) {
                CV_Intf_CreditDuNordSchemaBuilder.ResponsePaymentOrder responsePaymentOrder = new CV_Intf_CreditDuNordSchemaBuilder.ResponsePaymentOrder();
                responsePaymentOrder.status = 'SUCCESS';

                CV_Intf_CreditDuNordSchemaBuilder.ResponseAnswer answer = new CV_Intf_CreditDuNordSchemaBuilder.ResponseAnswer();
                answer.paymentOrderStatus = 'RUNNING';
                answer.paymentOrderId = 'dflsmfsfm-dfjfosf-12324';
                answer.paymentURL = 'https://www.test.com';
                answer.orderId = 'orderId';
                responsePaymentOrder.answer = answer;

                response.setStatusCode(status);
                response.setBody(JSON.serialize(responsePaymentOrder));

            } else {

                CV_Intf_CreditDuNordSchemaBuilder.ResponsePaymentOrder responsePaymentOrder = new CV_Intf_CreditDuNordSchemaBuilder.ResponsePaymentOrder();
                responsePaymentOrder.status = 'ERROR';

                CV_Intf_CreditDuNordSchemaBuilder.ResponseAnswer answer = new CV_Intf_CreditDuNordSchemaBuilder.ResponseAnswer();
                answer.errorCode = '222';
                answer.detailedErrorMessage = 'detailed Error';
                answer.errorMessage = 'error message';
                responsePaymentOrder.answer = answer;

                response.setStatusCode(500);
                response.setBody(JSON.serialize(responsePaymentOrder));
            }
        } else if (interfaceToTest == 'CDNCHECK') {

            CV_Intf_CreditDuNordSchemaBuilder.ResponsePaymentOrder responsePaymentOrder = new CV_Intf_CreditDuNordSchemaBuilder.ResponsePaymentOrder();
            responsePaymentOrder.status = 'SUCCESS';

            CV_Intf_CreditDuNordSchemaBuilder.ResponseAnswer answer = new CV_Intf_CreditDuNordSchemaBuilder.ResponseAnswer();
            answer.paymentOrderStatus = 'PAID';
            answer.paymentOrderId = 'dflsmfsfm-dfjfosf-12324';
            answer.paymentURL = 'https://www.test.com';
            answer.orderId = 'orderId';
            responsePaymentOrder.answer = answer;

            response.setStatusCode(status);
            response.setBody(JSON.serialize(responsePaymentOrder));


        } else if(interfaceToTest == 'GETSECURITYTOKEN'){
            String responseBody = '{"Paytweak-Security-Token": "6497e10218946dd24a61407c009b00c7381832b1f719b452"}';
            response.setHeader('Content-Type', 'application/json');
            response.setBody(responseBody);
            response.setStatusCode(200);
            
        }  else if(interfaceToTest == 'GETTOKEN'){
            String responseBody = '{"Paytweak-Work-Token": "0M0ATl0YI4OY"}';
            response.setHeader('Content-Type', 'application/json');
            response.setBody(responseBody);
            response.setStatusCode(200);

        } else if (status == 403) {
            response.setStatusCode(403);

            CalloutException e = (CalloutException)CalloutException.class.newInstance();
            e.setMessage('Unauthorized endpoint');
            throw e;

        } else {

            response.setStatusCode(200);
            response.setBody('OK');
        }

        return response;

    }
}