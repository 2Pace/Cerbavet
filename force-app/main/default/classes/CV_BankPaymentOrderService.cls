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
    private static final String TARGET_SYSTEM_PAYTWEAK= 'PAYTWEAK';
    private static final String INTERFACE_PAYTWEAK = 'GeneratePayment';


    public static String getSelectionQuery(Boolean isCheckPayments) {

        String query = 'SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('blng__Invoice__c').getDescribe().fields.getMap().keySet()), ',') + ' ';
        query += ' ,blng__Order__r.Email_Patient__c, blng__Order__r.Lib_Espece_Patient__c,blng__Account__r.TECH_InterfacePaytweak__c,blng__Account__r.BillingStreet,blng__Account__r.BillingCity,blng__Account__r.BillingPostalCode,blng__Account__r.Phone, blng__Account__r.Code_compte_metier__c, blng__Order__r.IDDossier__c';
        query += ',blng__Order__r.Animal_Owner_Name__c,blng__Order__r.Animal_Name__c, blng__Order__r.Prenom_Patient__c';
        query += ' FROM blng__Invoice__c';
        query += ' WHERE Facture_Proprio__c = true AND blng__Account__r.TECH_InterfacePaytweak__c = true';
        
        if (isCheckPayments) {
            query += ' AND Statut_Banque__c in (\'En Cours\', \'Refusé\') AND Payment_Order_Id__c <> null AND blng__PaymentStatus__c <> \'Paid\' LIMIT 10';
        } else {
            query += ' AND Payment_Order_Id__c = null AND Numero_Facturation_Cerbavet__c != null LIMIT 10';
        }
        System.debug('**** IMA Query == '+query);
        return query;

    }

    public static void checkPaymentForECVCall(String invoiceId) {

        String query = getSelectionQuery(true);
        query += ' AND Id = :invoiceId';

        List<blng__Invoice__c> invoices = (List<blng__Invoice__c>)Database.query(query);
        checkPaymentOrders(invoices, false);

    }


    public static void checkPaymentOrders(List<blng__Invoice__c> invoices, Boolean isPaytweak) {
        if(isPaytweak){
            // Paytweak
            CV_Intf_Service.loadMDWTransformationsMap(INTERFACE_PAYTWEAK);
            List<Intf_Sync_Field__mdt> syncFieldsPaytweak = CV_Intf_Service.getActiveSyncFields(TARGET_SYSTEM_PAYTWEAK);
            system.debug('*** IMA Paytweak syncFields in CV_BankPaymentOrderService L54 == ' + syncFieldsPaytweak);
        } else {
            // Crédit du Nord
            CV_Intf_Service.loadMDWTransformationsMap(INTERFACE_CDN);
            List<Intf_Sync_Field__mdt> syncFields = CV_Intf_Service.getActiveSyncFields(TARGET_SYSTEM_CDN);
        }
        

        List<Object> bodyRequestMapList = new List<Object>();
        List<String> bodyPaytweak = new List<String>();
        for (blng__Invoice__c invoice : invoices) {

            CV_Intf_CreditDuNordSchemaBuilder.GetPaymentOrder bodyPayload  = new CV_Intf_CreditDuNordSchemaBuilder.GetPaymentOrder(invoice);
            System.debug('======================= CV_GenerateBankPaymentOrderService checkPaymentOrders bodyPayload: ' + bodyPayload);

            bodyRequestMapList.add(bodyPayload);
        }
        
        System.debug('**** IMA CDN bodyRequestMapList L65 == ' + bodyRequestMapList);
        CV_Intf_WebserviceCalloutCDN.isPaymentCheck = true;
        CV_Intf_WebserviceCalloutCDN wsCDNCallout = new CV_Intf_WebserviceCalloutCDN();

        wsCDNCallout.sendStructuresToCDN(bodyRequestMapList);

    }

    public static void generatePaymentOrderIds(List<blng__Invoice__c> invoices) {
        String paytweakPayload;
        CV_Intf_CreditDuNordSchemaBuilder.PaymentOrder bodyPayload;
    
        // Crédit du Nord
        CV_Intf_Service.loadMDWTransformationsMap(INTERFACE_CDN);
        List<Intf_Sync_Field__mdt> syncFields = CV_Intf_Service.getActiveSyncFields(TARGET_SYSTEM_CDN);
        
        // Paytweak
        CV_Intf_Service.loadMDWTransformationsMap(INTERFACE_PAYTWEAK);
        List<Intf_Sync_Field__mdt> syncFieldsPaytweak = CV_Intf_Service.getActiveSyncFields(TARGET_SYSTEM_PAYTWEAK);
        system.debug('*** IMA Paytweak syncFields in CV_BankPaymentOrderService L79 == ' + syncFieldsPaytweak);

        List<Object> bodyRequestMapList = new List<Object>();
        List<String> bodyPaytweak = new List<String>();
        for (blng__Invoice__c invoice : invoices) {
            String isPaytweak = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'PAYTWEAK_InterfacePaytweak');
            System.debug('IMA is Paytweak == ' + isPaytweak);

            // PAYTWEAK
            paytweakPayload = CV_Intf_PaytweakSchemaBuilder.getInvoicePayload(invoice, false);
            System.debug('======================= CV_GenerateBankPaymentOrderService generatePaymentOrderIds paytweakPayload: ' + paytweakPayload);
            bodyPaytweak.add(paytweakPayload);
            
            // CREDIT DU NORD
            bodyPayload  = new CV_Intf_CreditDuNordSchemaBuilder.PaymentOrder(invoice, false);
            System.debug('======================= CV_GenerateBankPaymentOrderService generatePaymentOrderIds bodyPayload: ' + bodyPayload);
            bodyRequestMapList.add(bodyPayload);

            System.debug('**** IMA bodyRequestMapList == '+bodyRequestMapList);
            System.debug('**** IMA bodyPaytweak list == '+bodyPaytweak);

        }

        System.debug('**** IMA CDN bodyRequestMapList L98 == ' + bodyRequestMapList);
        //Credit du nord
        //CV_Intf_WebserviceCalloutCDN.isPaymentCheck = false;
        //CV_Intf_WebserviceCalloutCDN wsCDNCallout = new CV_Intf_WebserviceCalloutCDN();
        //if(!bodyRequestMapList.isEmpty()){
        //    wsCDNCallout.sendStructuresToCDN(bodyRequestMapList);
        //}

        //Paytweak
        CV_Intf_WebserviceCalloutPAYTWEAK.isPaymentCheck = false;
        CV_Intf_WebserviceCalloutPAYTWEAK wsPKCallout = new CV_Intf_WebserviceCalloutPAYTWEAK();
        if(!bodyPaytweak.isEmpty()){
            wsPKCallout.sendStructuresToPaytweak(bodyPaytweak);
        }
       
    }   

}