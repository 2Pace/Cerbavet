public with sharing class CV_Intf_WebserviceCalloutPAYTWEAK extends CV_Intf_WebserviceCalloutAbstract implements CV_Intf_WebserviceCallout {

    public static Boolean isPaymentCheck = CV_Intf_WebserviceCalloutCDN.isPaymentCheck;

    private static Map<String, String> statusMapping = new Map<String, String> {
        '0' => 'En Cours',
        '1' => 'Payé'
    };

    public void executeCallout(List<Object> MDWObjects) {
        super.doCallout(MDWObjects);
    }

    public void sendStructuresToPaytweak(List<String> bodyStructurePaytweak) {
        System.debug('**** IMA bodyStructurePaytweak value == ' + bodyStructurePaytweak);
        executePaytweakCallout(bodyStructurePaytweak);
    }

    public void executePaytweakCallout(List<String> bodyPayloadPaytweak) {
        super.doCalloutPaytweak(bodyPayloadPaytweak);
        System.debug('**** IMA bodyPayloadPaytweak == ' +bodyPayloadPaytweak);
    }

    private String setInterfaceType() {
        return 'PAYTWEAK';
    }

    private String setNamedCredential() {
        return 'PAYTWEAK_Create_Order';
    }
    private String setCaller() {
        return 'CV_Intf_WebserviceCalloutPAYTWEAK';
    }

    private Map<String, String> setHeaders() {
        String token = CV_Intf_PaytweakServiceToken.getWorkToken();
        String contentType = CV_Intf_HttpHexFormBuilder.GetContentType();
        String boundaryVal = CV_Intf_HttpHexFormBuilder.getBoundary();
        System.debug('**** IMA token value == ' +token);
        if(isPaymentCheck){
            return new Map<String, String> {
                'Paytweak-Token' => token
            };
        } else {
            return new Map<String, String> {
                'Content-Type' => contentType+boundaryVal ,
                'Paytweak-Token' => token
            };
        }   
    }

    private String setMethod() {
        String method = isPaymentCheck ? 'GET' : 'POST';
        System.debug('**** METHOD = ' + method);
        return isPaymentCheck ? 'GET' : 'POST';
    }

    private Map<String, String> setTagRemap() {

        return new Map<String, String> {
                '"currencyCode"' => '"cur"'
        };

    }

    private Integer setMode() {
        if (System.isBatch() || System.isFuture()) {
            return CV_intf_WebserviceCalloutAbstract.MODE_DIRECT;
        } else {
            return CV_Intf_WebserviceCalloutAbstract.MODE_FUTURE;
        }
    }

    public static void handleResponse(CV_Intf_ServiceResult serviceResult, String payload, Boolean technicalError) {

        System.debug('======================== CV_Intf_WebserviceCalloutECV handleResponse serviceResult: ' + serviceResult);
        System.debug('======================== CV_Intf_WebserviceCalloutECV handleResponse serviceResult body: ' + serviceResult.body);

        updateInvoiceSyncStatus(payload, serviceResult, technicalError);
    }

     /**
    * @description Updates the Invoice ECV Sync Status field of the Invoice in the callout Payload received
    * @param payload The Account JSON payload to obtain the CRM Number and so find the Invoice in SFDC
    * @param serviceResult The service result of the callout
    */
    private static void updateInvoiceSyncStatus(String payload, CV_Intf_ServiceResult serviceResult, Boolean technicalError) {
        String invoiceExtId = getInvoiceExtId(payload);
        System.debug('***** invoiceExtId ' + invoiceExtId);

        blng__Invoice__c getInvoice = [SELECT Id, Lien_Paiement__c FROM blng__Invoice__c WHERE Numero_Facturation_Cerbavet__c = :invoiceExtId];
        String invoiceId = getInvoice.Id ;
        String linkId = getInvoice.Lien_Paiement__c;
        linkId = linkId.replace('https://paiement-factures.cerballiance.fr/', '');
        System.debug('=================================== CV_Intf_WebserviceCalloutCDN updateInvoiceSyncStatus invoiceId: ' + invoiceId + '/ invoiceExtId == '+invoiceExtId +serviceResult + '/ Linkid == ' + linkId);

        String integratioStatus;
        String errorMessage;
        String paymentLink;
        String paymentOrderId;
        Boolean paymentAllocation = false;
        System.debug('**** IMA serviceResult.body == '+serviceResult.body);
        CV_Intf_PaytweakSchemaBuilder.BodyError paytweakError = (CV_Intf_PaytweakSchemaBuilder.BodyError) JSON.deserialize(serviceResult.body, CV_Intf_PaytweakSchemaBuilder.BodyError.class);
        System.debug('**** IMA paytweakError = '+ paytweakError);
        if (!serviceResult.isSuccess && (paytweakError.code != '200' && paytweakError.code != '201')) {
            integratioStatus = 'Erreur';
            errorMessage = serviceResult.body;
        } else {

            CV_Intf_PaytweakSchemaBuilder.ResponsePaymentOrder paytweakAnswer = (CV_Intf_PaytweakSchemaBuilder.ResponsePaymentOrder) JSON.deserialize(serviceResult.body, CV_Intf_PaytweakSchemaBuilder.ResponsePaymentOrder.class);
            String body = serviceResult.body.replace('"date"','"dateT"');
            body = body.replace('"group"','"groupT"');
            body = body.replace(linkId, 'attributes');

            CV_Intf_PaytweakSchemaBuilder.ResponseCheckPaymentOrder paytweakGetAnswer = (CV_Intf_PaytweakSchemaBuilder.ResponseCheckPaymentOrder) JSON.deserialize(body, CV_Intf_PaytweakSchemaBuilder.ResponseCheckPaymentOrder.class);
            Map<String, Object> paytweakAnswerUntype = (Map<String, Object>)JSON.deserializeUntyped(serviceResult.body);
            String answerWebService = (String)paytweakAnswerUntype.get('webService');

            System.debug('=================================== CV_Intf_WebserviceCalloutCDN updateInvoiceSyncStatus paytweakAnswer: ' + paytweakAnswer);
            System.debug('=================================== CV_Intf_WebserviceCalloutCDN updateInvoiceSyncStatus answerWebService: ' + answerWebService);
            System.debug('=================================== CV_Intf_WebserviceCalloutCDN updateInvoiceSyncStatus paytweakGetAnswer: ' + paytweakGetAnswer);
            if (paytweakAnswer.code == 'OK') {
                
                paymentOrderId = paytweakAnswer.order_id;
                paymentLink = paytweakAnswer.url;
                integratioStatus = 'En Cours';

                System.debug('=================================== CV_Intf_WebserviceCalloutCDN updateInvoiceSyncStatus integratioStatus: ' + integratioStatus);
                System.debug('**** IMA statusMapping.get(paytweakGetAnswer.paid) == ' + statusMapping.get(paytweakGetAnswer.attributes.paid));
                System.debug('**** IMA paytweakGetAnswer.active == ' + paytweakGetAnswer.attributes.active);
                if (isPaymentCheck) {
                    integratioStatus = paytweakGetAnswer.attributes.active == '0' ? 'Expiré' : statusMapping.get(paytweakGetAnswer.attributes.paid);
                    System.debug('**** IMA integratioStatus checkpayment = '+ integratioStatus);
                    if(integratioStatus == 'Payé'){
                        registerPaiement(invoiceId);
                        paymentAllocation = Test.isRunningTest() ? false : true;
                    }
                    
                }

            } else {
                integratioStatus = 'Erreur';
                errorMessage = paytweakAnswer.message;
            }
        }

        blng__Invoice__c invoice = new blng__Invoice__c(
                Id = invoiceId,
                Statut_Banque__c = integratioStatus ,
                Message_d_erreur__c = errorMessage,
                Allocation_lignes_de_factures__c = paymentAllocation
        );

        if(!isPaymentCheck) {
            invoice.Lien_Paiement__c = paymentLink;
            invoice.Payment_Order_Id__c = paymentOrderId;
        }

        SBQQ.TriggerControl.disable();
        update invoice;
        SBQQ.TriggerControl.enable();
    }


    public void registerMonitoningMessage(String outgoingMessage, String responseMessage, String interfaceName, Integer statusCode, Boolean isError, Boolean isReponse) {

        String messageId = CV_Intf_Service.getUMessageId();

        super.registerMonitoningMessage(outgoingMessage, responseMessage, interfaceName, statusCode, isError, messageId, isReponse);
    }

    private static void registerPaiement(String invoiceId) {

        System.debug('=================================== CV_Intf_WebserviceCalloutCDN registerPaiement invoiceId: ' + invoiceId);

        List<blng__Invoice__c> invoices = new List<blng__Invoice__c>([SELECT Id, blng__Order__c, blng__Account__c, blng__TotalAmount__c FROM blng__Invoice__c WHERE Id = :invoiceId]);
        System.debug('=================================== CV_Intf_WebserviceCalloutCDN registerPaiement invoices: ' + invoices);

        if (!invoices.isEmpty()) {
            blng__Invoice__c invoice = invoices[0];

            blng__Payment__c payment = new blng__Payment__c(
                    blng__Account__c = invoice.blng__Account__c,
                    blng__Amount__c = invoice.blng__TotalAmount__c != null ? invoice.blng__TotalAmount__c : 0,
                    Dossier__c = invoice.blng__Order__c,
                    blng__PaymentDate__c = Date.today(),
                    blng__PaymentType__c = 'Credit Card',
                    blng__Invoice__c = invoiceId,
                    blng__Status__c = 'Posted'
            );
            insert payment;
        }
    }

    private static string getInvoiceExtId(String payload) {
        String[] playloadList = payload.split('----------------------------533330745817455354437071');
        System.debug('***** IMA playloadList value == '+ playloadList);
        String s1 = playloadList[1].replace('\r\n', '&');
        System.debug('S1 Value == '+ s1);
        playloadList = s1.split('&&');
        System.debug('***** IMA playloadList value == '+ playloadList);
        String orderIdKey = playloadList[0];
        String orderIdValue = playloadList[1];
        orderIdValue = orderIdValue.replace('&','');
        orderIdValue = orderIdValue.replace('=','');
        Map<String, String> mapOrderId = new Map<String, String>();
        mapOrderId.put(orderIdKey,orderIdValue);
        String extId = mapOrderId.get('Content-Disposition: form-data; name="order_id";');
        System.debug('***** IMA mapOrderId value == '+ mapOrderId + ' / orderIdKey =' + orderIdKey + '/orderIdValue == ' +orderIdValue);
        return orderIdValue;
    }
}