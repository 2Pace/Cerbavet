/**
 * @description       : Class gérant le callout vers le Crédit Du Nord
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 24-06-2022
 * @last modified by  : Michaël Cabaraux
**/

public with sharing class CV_Intf_WebserviceCalloutCDN extends CV_Intf_WebserviceCalloutAbstract implements CV_Intf_WebserviceCallout {

    private static final String WEBSERVICE_CREATE_ORDER = 'Charge/CreatePaymentOrder';
    private static final String WEBSERVICE_CHECK_ORDER = 'Charge/PaymentOrder/Get';
//    public static String method;
    public static Boolean isPaymentCheck;

    private static Map<String, String> statusMapping = new Map<String, String> {
            'RUNNING' => 'En Cours',
            'PAID' => 'Payé',
            'EXPIRED' => 'Expiré',
            'REFUSED' => 'Refusé',
            'TREATED' => 'Traité',
            'CANCELLED' => 'Annulé'
    };


    public void sendStructuresToCDN(List< Object> mdwStructures) {

        executeCallout(mdwStructures);
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


        CV_Intf_CreditDuNordSchemaBuilder.PaymentOrder paymentOrder = (CV_Intf_CreditDuNordSchemaBuilder.PaymentOrder) JSON.deserialize(payload, CV_Intf_CreditDuNordSchemaBuilder.PaymentOrder.class);

        String invoiceId = paymentOrder.salesforceId;


        System.debug('=================================== CV_Intf_WebserviceCalloutCDN updateInvoiceSyncStatus invoiceId: ' + invoiceId);

        String integratioStatus;
        String errorMessage;
        String paymentLink;
        String paymentOrderId;
        Boolean paymentAllocation = false;

        if (!serviceResult.isSuccess || technicalError || (serviceResult.statusCode != 200 && serviceResult.statusCode != 201)) {
            integratioStatus = 'Erreur';
            errorMessage = serviceResult.body;

        } else {

            CV_Intf_CreditDuNordSchemaBuilder.ResponsePaymentOrder cdnAnswer = (CV_Intf_CreditDuNordSchemaBuilder.ResponsePaymentOrder) JSON.deserialize(serviceResult.body, CV_Intf_CreditDuNordSchemaBuilder.ResponsePaymentOrder.class);
            Map<String, Object> cdnAnswerUntype = (Map<String, Object>)JSON.deserializeUntyped(serviceResult.body);
            String answerWebService = (String)cdnAnswerUntype.get('webService');

            System.debug('=================================== CV_Intf_WebserviceCalloutCDN updateInvoiceSyncStatus cdnAnswer: ' + cdnAnswer);
            System.debug('=================================== CV_Intf_WebserviceCalloutCDN updateInvoiceSyncStatus answerWebService: ' + answerWebService);

            if (cdnAnswer.status == 'SUCCESS') {
                integratioStatus = statusMapping.get(cdnAnswer.answer.paymentOrderStatus);
                paymentOrderId = cdnAnswer.answer.paymentOrderId;
                paymentLink = cdnAnswer.answer.paymentURL;

                System.debug('=================================== CV_Intf_WebserviceCalloutCDN updateInvoiceSyncStatus integratioStatus: ' + integratioStatus);
                if (isPaymentCheck && integratioStatus == 'Payé') {
                    registerPaiement(invoiceId);
                    paymentAllocation = Test.isRunningTest() ? false : true;
                }

            } else {
                integratioStatus = 'Erreur';
                errorMessage = cdnAnswer.answer.detailedErrorMessage;
            }
        }

        blng__Invoice__c invoice = new blng__Invoice__c(
                Id = invoiceId,
                Statut_Banque__c = integratioStatus,
                Message_d_erreur__c = errorMessage,
                Lien_Paiement__c = paymentLink,
                Payment_Order_Id__c = paymentOrderId,
                Allocation_lignes_de_factures__c = paymentAllocation
        );

        SBQQ.TriggerControl.disable();
        update invoice;
        SBQQ.TriggerControl.enable();
    }

    public void executeCallout(List<Object> MDWObjects) {
        super.doCallout(MDWObjects);
    }

    private String setInterfaceType() {
        return 'CDN';
    }

    private String setNamedCredential() {
        return isPaymentCheck ? 'CDN_Check_Payement' : 'CDN_Create_Order';
    }

    private String setCaller() {
        return 'CV_Intf_WebserviceCalloutCDN';
    }

    private Map<String, String> setHeaders() {

        return new Map<String, String> {
                'Content-Type' => 'application/json'
        };

    }

    private Map<String, String> setTagRemap() {

        return new Map<String, String> {
                '"currencyCode"' => '"currency"'
        };

    }

    private String setMethod() {

        return 'POST';

    }

    private Integer setMode() {

        if (System.isBatch() || System.isFuture()) {
            return CV_intf_WebserviceCalloutAbstract.MODE_DIRECT;
        } else {
            return CV_Intf_WebserviceCalloutAbstract.MODE_FUTURE;
        }
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

}