/**
 * @description       : Classe de service pour les Ordres de paiement bancaires
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 25-06-2022
 * @last modified by  : Michaël Cabaraux
**/

public with sharing class CV_BankPaymentOrderService {

    private static final String TARGET_SYSTEM_CDN= 'CDN';
    private static final String INTERFACE_CDN = 'GeneratePayment';


    public static String getSelectionQuery(Boolean isCheckPayments) {

        String query = 'SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('blng__Invoice__c').getDescribe().fields.getMap().keySet()), ',') + ' ';
        query += ' ,blng__Order__r.Email_Patient__c, blng__Order__r.Lib_Espece_Patient__c, blng__Account__r.Code_compte_metier__c, blng__Order__r.IDDossier__c';
        query += ',blng__Order__r.Animal_Owner_Name__c,blng__Order__r.Animal_Name__c, blng__Order__r.Prenom_Patient__c';
        query += ' FROM blng__Invoice__c';
        query += ' WHERE Facture_Proprio__c = true';

        if (isCheckPayments) {
            query += ' AND Statut_Banque__c in (\'En Cours\', \'Refusé\') AND Payment_Order_Id__c <> null AND blng__PaymentStatus__c <> \'Paid\'';
        } else {
            query += ' AND Payment_Order_Id__c = null';
        }

        return query;

    }

    public static void checkPaymentForECVCall(String invoiceId) {

        String query = getSelectionQuery(true);
        query += ' AND Id = :invoiceId';

        List<blng__Invoice__c> invoices = (List<blng__Invoice__c>)Database.query(query);
        checkPaymentOrders(invoices);

    }


    public static void checkPaymentOrders(List<blng__Invoice__c> invoices) {

        CV_Intf_Service.loadMDWTransformationsMap(INTERFACE_CDN);
        List<Intf_Sync_Field__mdt> syncFields = CV_Intf_Service.getActiveSyncFields(TARGET_SYSTEM_CDN);

        List<Object> bodyRequestMapList = new List<Object>();
        for (blng__Invoice__c invoice : invoices) {

            CV_Intf_CreditDuNordSchemaBuilder.GetPaymentOrder bodyPayload  = new CV_Intf_CreditDuNordSchemaBuilder.GetPaymentOrder(invoice);
            System.debug('======================= CV_GenerateBankPaymentOrderService checkPaymentOrders bodyPayload: ' + bodyPayload);

            bodyRequestMapList.add(bodyPayload);
        }

        CV_Intf_WebserviceCalloutCDN.isPaymentCheck = true;
        CV_Intf_WebserviceCalloutCDN wsCDNCallout = new CV_Intf_WebserviceCalloutCDN();

        wsCDNCallout.sendStructuresToCDN(bodyRequestMapList);

    }

    public static void generatePaymentOrderIds(List<blng__Invoice__c> invoices) {

        CV_Intf_Service.loadMDWTransformationsMap(INTERFACE_CDN);
        List<Intf_Sync_Field__mdt> syncFields = CV_Intf_Service.getActiveSyncFields(TARGET_SYSTEM_CDN);

        List<Object> bodyRequestMapList = new List<Object>();
        for (blng__Invoice__c invoice : invoices) {

            CV_Intf_CreditDuNordSchemaBuilder.PaymentOrder bodyPayload  = new CV_Intf_CreditDuNordSchemaBuilder.PaymentOrder(invoice, false);
            System.debug('======================= CV_GenerateBankPaymentOrderService generatePaymentOrderIds bodyPayload: ' + bodyPayload);

            bodyRequestMapList.add(bodyPayload);
        }

        CV_Intf_WebserviceCalloutCDN.isPaymentCheck = false;
        CV_Intf_WebserviceCalloutCDN wsCDNCallout = new CV_Intf_WebserviceCalloutCDN();

        wsCDNCallout.sendStructuresToCDN(bodyRequestMapList);
    }

}