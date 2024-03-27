/**
 * @description       : Incoming Webservice appelé par ECV pour spécifier qu'un compte rendu est dispo
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 20-7-2023
 * @last modified by  : Thibaut BENTZ
**/

@RestResource(urlMapping='/v1/ecvreport/*')
global with sharing class CV_CompteRenduInWSController {

    private static final String NON_PAYER = 'Non Régleur';
    private static final String PAYMENT_STATUS_PAID = 'PAID';
    private static final String PAYMENT_STATUS_UNPAID = 'UNPAID';
    private static final String REPORT_STATUS_BLOCk = 'BLOCK';
    private static final String REPORT_STATUS_UNBLOCK = 'UNBLOCK';
    private static final String BANQUE_PAID = 'Payé';
    private static final String BANQUE_RUNNING = 'En Cours';

    @HttpPost
    global static void processCompteRenduFromECV(){

		// Get parameters from parameters
		RestRequest request = RestContext.request;
        String recordNumber = request.params.get('recordNumber');
        String correspondantId = request.params.get('correspondantId');
  
        // Error handling
        if (recordNumber == null || recordNumber == '' || recordNumber == ' ' || correspondantId == null || correspondantId == '' || correspondantId == ' ') {
            RestContext.response.statusCode = 400;
            CV_SalesforceIntegrationError[] errs = new CV_SalesforceIntegrationError[]{
                new CV_SalesforceIntegrationError('Body error', 'Invalid body')
            };
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(errs));
            return;
        }

        CompteRenduECVRequest compteRenduECVRequest = new CompteRenduECVRequest();
        compteRenduECVRequest.recordNumber = recordNumber.ToUpperCase();
        compteRenduECVRequest.correspondantId = correspondantId.ToUpperCase();
        
        try {

            List<Order> orders = new List<Order>([
                    SELECT Id, Account.Code_compte_metier__c, Conditions_de_Reglement_Cerbavet__c, Statut_Compte_Rendu__c,
                    (SELECT Id, blng__PaymentStatus__c, Lien_Paiement__c, Lien_Paiement_CDN__c, Statut_Banque__c,Statut_Banque_CDN__c, Facture_Proprio__c FROM blng__OrderInvoices__r Order By CreatedDate desc)
                    FROM Order
                    WHERE Numero__c = :compteRenduECVRequest.recordNumber
                    LIMIT 1
            ]);

            if (!orders.isEmpty()) {

                Order orderToTreat = orders[0];

                if (orderToTreat.Account.Code_compte_metier__c == compteRenduECVRequest.correspondantId) {

                    CompteRenduECVResponse renduECVResponse = new CompteRenduECVResponse();

                    Boolean isPayer = orderToTreat.Conditions_de_Reglement_Cerbavet__c != NON_PAYER ? true : false;
                    String paymentStatus = PAYMENT_STATUS_UNPAID;
                    String banqueStatus = BANQUE_RUNNING;
                    blng__Invoice__c invoice;

                    if (orderToTreat.blng__OrderInvoices__r != null && !orderToTreat.blng__OrderInvoices__r.isEmpty()) {
                        invoice = orderToTreat.blng__OrderInvoices__r[0];

                        paymentStatus = invoice.blng__PaymentStatus__c == PAYMENT_STATUS_PAID ? PAYMENT_STATUS_PAID : PAYMENT_STATUS_UNPAID;
                        banqueStatus = invoice.Statut_Banque__c == BANQUE_PAID ? BANQUE_PAID : BANQUE_RUNNING;

                    }

                    if (isPayer || (paymentStatus == PAYMENT_STATUS_PAID) || (banqueStatus == BANQUE_PAID)) {
                        renduECVResponse.paymentStatus = paymentStatus;
                        renduECVResponse.reportStatus = REPORT_STATUS_UNBLOCK;

                    } else if ((invoice != null) && (invoice.Facture_Proprio__c) && (banqueStatus == BANQUE_RUNNING)){

                        CV_BankPaymentOrderService.checkPaymentForECVCall(invoice.Id);

                        blng__Invoice__c invoiceChecked = [SELECT Id, Statut_Banque__c FROM blng__Invoice__c WHERE Id = :invoice.Id];

                        renduECVResponse.paymentStatus = invoiceChecked.Statut_Banque__c == BANQUE_PAID ? PAYMENT_STATUS_PAID : PAYMENT_STATUS_UNPAID;
                        renduECVResponse.reportStatus = invoiceChecked.Statut_Banque__c == BANQUE_PAID ? REPORT_STATUS_UNBLOCK : REPORT_STATUS_BLOCk;

                    } else {
                        renduECVResponse.paymentStatus = PAYMENT_STATUS_UNPAID;
                        renduECVResponse.reportStatus = REPORT_STATUS_BLOCk;
                    }

                    RestContext.response.statusCode = 200;
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(renduECVResponse));

                    if (orderToTreat.blng__OrderInvoices__r != null && !orderToTreat.blng__OrderInvoices__r.isEmpty()) {
                        invoice = orderToTreat.blng__OrderInvoices__r[0];

                        invoice.Statut_Compte_Rendu__c = 'Oui';
                        update invoice;
                    }


                    orderToTreat.Statut_Compte_Rendu__c = 'Oui';   //TODO --> passer la commande en activée pour les cliniques si pas d'ATEL && status not activated !!
                    update orderToTreat;


                } else {
                    RestContext.response.statusCode = 409;

                    CV_SalesforceIntegrationError[] errs = new CV_SalesforceIntegrationError[]{
                            new CV_SalesforceIntegrationError('Mismatch', 'Le code correspondant ne correspondant pas à cette commande')
                    };
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(errs));
                }

            } else {
                RestContext.response.statusCode = 404;
                CV_SalesforceIntegrationError[] errs = new CV_SalesforceIntegrationError[]{
                        new CV_SalesforceIntegrationError('Record not found', 'Dossier non trouvé')
                };
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(errs));
            }

        } catch (Exception e) {

            RestContext.response.statusCode = 500;
            CV_SalesforceIntegrationError[] errs = new CV_SalesforceIntegrationError[]{
                    new CV_SalesforceIntegrationError('Internal Error', e.getMessage())
            };
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(errs));
        }

        SBQQ.TriggerControl.enable();
    }

    public class CompteRenduECVRequest {

        public String recordNumber { get; set; }
        public String correspondantId { get; set; }

    }

    public class CompteRenduECVResponse {

        public String paymentStatus { get; set; }
        public String reportStatus { get; set; } //block - unblock

    }

    /** static final string getters **/
    public static String getNON_PAYER() {
        return NON_PAYER;
    }

    public static String getPAYMENT_STATUS_PAID() {
        return PAYMENT_STATUS_PAID;
    }

    public static String getPAYMENT_STATUS_UNPAID() {
        return PAYMENT_STATUS_UNPAID;
    }

    public static String getREPORT_STATUS_BLOCK() {
        return REPORT_STATUS_BLOCK;
    }

    public static String getREPORT_STATUS_UNBLOCK() {
        return REPORT_STATUS_UNBLOCK;
    }

    public static String getBANQUE_PAID() {
        return BANQUE_PAID;
    }

    public static String getBANQUE_RUNNING() {
        return BANQUE_RUNNING;
    }
}