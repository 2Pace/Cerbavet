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
        } else if (interfaceToTest == 'PAYTWEAK') {
            if (request.getHeader('Paytweak-API-KEY') != null){
                String responseBody = '{"Paytweak-Security-Token": "PAYTWEAK-0M0ATl0YI4OY"}';
                response.setHeader('Content-Type', 'application/json');
                response.setBody(responseBody);
                response.setStatusCode(200);
                System.debug('*** IMA Response PAYTWEAK 1 post order getbody() value == ' + response.getBody());
            } else if (request.getHeader('Paytweak-USER-TOKEN') != null){
                String responseBody = '{"Paytweak-Work-Token": "PAYTWEAK-0M0ATl0YI4OY"}';
                response.setHeader('Content-Type', 'application/json');
                response.setBody(responseBody);
                response.setStatusCode(200);
                System.debug('*** IMA Response PAYTWEAK 2 post order getbody() value == ' + response.getBody());
            } else {
                if (status == 200) {
                    CV_Intf_PaytweakSchemaBuilder.ResponsePaymentOrder responsePaymentOrderPK = new CV_Intf_PaytweakSchemaBuilder.ResponsePaymentOrder();
    
                    responsePaymentOrderPK.url = 'https://paiement-factures.cerballiance.fr/1ei7W';
                    responsePaymentOrderPK.order_Id = 'FACCV-20240118-0003';
                    responsePaymentOrderPK.qrcode = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMQAAADEAQMAAAD6aBwoAAAABlBMVEX///8AAABVwtN+AAAACXBIWXMAAA7EAAAOxAGVKw4bAAABvUlEQVRYhe2XQY7EMAgE/YP+/y/5AUs1SXZ==';
                    responsePaymentOrderPK.code = 'OK';
                    responsePaymentOrderPK.message = 'Process Succeeded';
    
                    response.setStatusCode(status);
                    response.setBody(JSON.serialize(responsePaymentOrderPK));
                    //response.setHeader('Paytweak-Token', 'TOKEN');
    
                    System.debug('*** IMA Response PAYTWEAK post order getbody() value == ' + response.getBody());
    
                } else {
    
                    CV_Intf_PaytweakSchemaBuilder.BodyError paytweakError = new CV_Intf_PaytweakSchemaBuilder.BodyError ();
                    paytweakError.code = '409';
                    paytweakError.message = 'CONFLICT : [FACCV-20240118-0003] :  is already used in an active link.';
    
                    response.setStatusCode(409);
                    response.setBody(JSON.serialize(paytweakError));
                    
                }
            }
        } else if (interfaceToTest == 'PAYTWEAKCHECK') {

            if (status == 200) {
                CV_Intf_PaytweakSchemaBuilder.ResponseCheckPaymentOrder responsePaymentOrder = new CV_Intf_PaytweakSchemaBuilder.ResponseCheckPaymentOrder();

                responsePaymentOrder.attributes.id = '1ei7W';
                responsePaymentOrder.attributes.dateT = '18/01/2024';
                responsePaymentOrder.attributes.name = '';
                responsePaymentOrder.attributes.email = '';
                responsePaymentOrder.attributes.order_id = 'FACCV-20240118-0003';
                responsePaymentOrder.attributes.amount = '14600';
                responsePaymentOrder.attributes.monthly = '';
                responsePaymentOrder.attributes.link_url = 'https://paiement-factures.cerballiance.fr/1ei7W';
                responsePaymentOrder.attributes.msg_type = 'IC';
                responsePaymentOrder.attributes.phone = '';
                responsePaymentOrder.attributes.subject = '';
                responsePaymentOrder.attributes.message_text = '';
                responsePaymentOrder.attributes.message_html = '';
                responsePaymentOrder.attributes.user = '';
                responsePaymentOrder.attributes.groupT = '';
                responsePaymentOrder.attributes.scenario = 'default';
                responsePaymentOrder.attributes.freetext = '';
                responsePaymentOrder.attributes.clics = '1';
                responsePaymentOrder.attributes.paid = '1';
                responsePaymentOrder.attributes.active = '1';
                responsePaymentOrder.code = 'OK';
                responsePaymentOrder.message = 'Process Succeeded';

                response.setStatusCode(status);
                response.setBody(JSON.serialize(responsePaymentOrder));
                System.debug('*** IMA Response PAYTWEAKCHECK get body value == ' + response.getBody());

            } else {

                CV_Intf_PaytweakSchemaBuilder.BodyError paytweakError = new CV_Intf_PaytweakSchemaBuilder.BodyError ();
                paytweakError.code = '409';
                paytweakError.message = '{CONFLICT : [order_id] :  is already used in an active link.}';

                response.setStatusCode(409);
                response.setBody(JSON.serialize(paytweakError));
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
            if (request.getHeader('Paytweak-API-KEY') != null){
                String responseBody = '{"Paytweak-Security-Token": "PAYTWEAK-0M0ATl0YI4OY"}';
                response.setHeader('Content-Type', 'application/json');
                response.setBody(responseBody);
                response.setStatusCode(200);
                System.debug('*** IMA Response PAYTWEAK 1 post order getbody() value == ' + response.getBody());
            } else {
                String responseBody = '{"Paytweak-Work-Token": "0M0ATl0YI4OY"}';
                response.setHeader('Content-Type', 'application/json');
                response.setBody(responseBody);
                response.setStatusCode(200);
            }
        } else if (status == 403) {
            response.setStatusCode(403);

            CalloutException e = (CalloutException)CalloutException.class.newInstance();
            e.setMessage('Unauthorized endpoint');
            throw e;

        } else {

            response.setStatusCode(200);
            response.setBody('OK');
        }
        System.debug('**** IMA Response Value == ' + response);
        System.debug('**** IMA Response Value == ' + response.getBody());

        return response;

    }
}