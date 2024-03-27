/**
 * @description       : Class gérant le callout vers ECV
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 21-06-2022
 * @last modified by  : Michaël Cabaraux
**/

public with sharing class CV_Intf_WebserviceCalloutECV extends CV_Intf_WebserviceCalloutAbstract implements CV_Intf_WebserviceCallout {


    public void sendStructuresToECV(List<Object> mdwStructures) {
        System.debug(' --------------------------   executeCallout: ' +mdwStructures);
        executeCallout(mdwStructures);
    }

    public static void handleResponse(CV_Intf_ServiceResult serviceResult, String payload, Boolean technicalError) {

        System.debug('======================== CV_Intf_WebserviceCalloutECV handleResponse serviceResult: ' + serviceResult);
        System.debug('======================== CV_Intf_WebserviceCalloutECV handleResponse payload: ' + payload);

        updateInvoiceSyncStatus(payload, serviceResult, technicalError);
    }

    /**
    * @description Updates the Invoice ECV Sync Status field of the Invoice in the callout Payload received
    * @param payload The Account JSON payload to obtain the CRM Number and so find the Invoice in SFDC
    * @param serviceResult The service result of the callout
    */
    private static void updateInvoiceSyncStatus(String payload, CV_Intf_ServiceResult serviceResult, Boolean technicalError) {

//        Map<String, Object> invoiceMsg = (Map<String, Object>)JSON.deserializeUntyped(payload);

        CV_Intf_InvoiceSchemaBuilder invoiceSchemaBuilder =
                (CV_Intf_InvoiceSchemaBuilder)JSON.deserialize(
                        payload,
                        CV_Intf_InvoiceSchemaBuilder.class
                );

        System.debug('========================  OUTGOING invoiceSchemaBuilder: ' + invoiceSchemaBuilder);
        String invoiceId = invoiceSchemaBuilder.salesforceId;

        String integratioStatus;
        String errorMessage;
        if (!serviceResult.isSuccess || technicalError || (serviceResult.statusCode != 200 && serviceResult.statusCode != 201)) {
            integratioStatus = 'Erreur';
            errorMessage = serviceResult.body;
        } else {
            integratioStatus = 'Intégrée';
        }

        blng__Invoice__c invoice = new blng__Invoice__c(
                Id = invoiceId,
                Statut_Integration_ECV__c = integratioStatus,
                Message_d_erreur__c = errorMessage
        );

        SBQQ.TriggerControl.disable();
        update invoice;
        SBQQ.TriggerControl.enable();
    }

    public void executeCallout(List<Object> MDWObjects) {

        super.doCallout(MDWObjects);
    }

    private String setInterfaceType() {
        return 'ECV';
    }

    private String setNamedCredential() {
        return 'ECV';
    }

    private String setCaller() {
        return 'CV_Intf_WebserviceCalloutECV';
    }

    private Map<String, String> setHeaders() {

        return new Map<String, String> {
                'Ocp-Apim-Subscription-Key' => '{!$Credential.Password}',
                'Content-Type' => 'application/json'
        };

    }

    private String setMethod() {

        return 'POST';

    }

    private Map<String, String> setTagRemap() {

        return new Map<String, String>();

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
}