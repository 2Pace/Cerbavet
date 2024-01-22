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


    public static String getSelectionQuery(Boolean isCheckPayments, Boolean isPaytweak) {

        String query = 'SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('blng__Invoice__c').getDescribe().fields.getMap().keySet()), ',') + ' ';
        query += ' ,blng__Order__r.Email_Patient__c, blng__Order__r.Lib_Espece_Patient__c,blng__Account__r.TECH_InterfacePaytweak__c,blng__Account__r.BillingStreet,blng__Account__r.BillingCity,blng__Account__r.BillingPostalCode,blng__Account__r.Phone, blng__Account__r.Code_compte_metier__c, blng__Order__r.IDDossier__c';
        query += ',blng__Order__r.Animal_Owner_Name__c,blng__Order__r.Animal_Name__c, blng__Order__r.Prenom_Patient__c';
        query += ' FROM blng__Invoice__c';
        query += ' WHERE Facture_Proprio__c = true';
        
        if (isCheckPayments && isPaytweak ) {
            query += ' AND Statut_Banque__c in (\'En Cours\', \'Refusé\') AND Payment_Order_Id__c <> null AND blng__PaymentStatus__c <> \'Paid\' ';
        } else if (isCheckPayments && !isPaytweak ){
            query += ' AND Statut_Banque__c in (\'En Cours\', \'Refusé\') AND Payment_Order_Id_CDN__c <> null AND blng__PaymentStatus__c <> \'Paid\'';
        } else if (isPaytweak) {
            query += ' AND Payment_Order_Id__c = null AND Numero_Facturation_Cerbavet__c != null AND blng__TotalAmount__c > 0';
        } else {
            query += ' AND Payment_Order_Id_CDN__c = null AND Numero_Facturation_Cerbavet__c != null AND blng__TotalAmount__c > 0';
        }
        System.debug('**** IMA Query == '+query);
        return query;

    }

    public static void checkPaymentForECVCall(String invoiceId) {

        String query = getSelectionQuery(true, false);
        query += ' AND Id = :invoiceId';

        List<blng__Invoice__c> invoices = (List<blng__Invoice__c>)Database.query(query);
        checkPaymentOrders(invoices, false);

    }


    public static void checkPaymentOrders(List<blng__Invoice__c> invoices, Boolean isPaytweak) {
        CV_Intf_WebserviceCalloutCDN.isPaymentCheck = true;
        System.debug('***** IMA CV_Intf_WebserviceCalloutCDN.isPaymentCheck == '+CV_Intf_WebserviceCalloutCDN.isPaymentCheck + ' / isPaytweak value = ' + isPaytweak);
        List<Intf_Sync_Field__mdt> syncFields;
        List<Intf_Sync_Field__mdt> syncFieldsPaytweak;

        if(isPaytweak){
            // Paytweak
            CV_Intf_Service.loadMDWTransformationsMap(INTERFACE_PAYTWEAK);
            syncFieldsPaytweak = CV_Intf_Service.getActiveSyncFields(TARGET_SYSTEM_PAYTWEAK);
            system.debug('*** IMA Paytweak syncFields in CV_BankPaymentOrderService L54 == ' + syncFieldsPaytweak);
        } else {
            // Crédit du Nord
            CV_Intf_Service.loadMDWTransformationsMap(INTERFACE_CDN);
            syncFields = CV_Intf_Service.getActiveSyncFields(TARGET_SYSTEM_CDN);
            system.debug('*** IMA Paytweak syncFields in CV_BankPaymentOrderService L54 == ' + syncFields);
        }
        
        List<Object> bodyRequestMapList = new List<Object>();
        List<String> bodyPaytweak = new List<String>();
        for (blng__Invoice__c invoice : invoices) {
            CV_Intf_CreditDuNordSchemaBuilder.GetPaymentOrder bodyPayload;
            String bodyPayloadPAytweak;

            if(!isPaytweak){
                bodyPayload  = new CV_Intf_CreditDuNordSchemaBuilder.GetPaymentOrder(invoice);
                bodyRequestMapList.add(bodyPayload);
            } else {
                bodyPayloadPAytweak  = CV_Intf_PaytweakSchemaBuilder.getInvoicePayload(invoice, CV_Intf_WebserviceCalloutCDN.isPaymentCheck);
                System.debug('bodyPayloadPAytweak value == '+bodyPayloadPAytweak);
                bodyPaytweak.add(bodyPayloadPAytweak);
            } 
        }
        
        if(isPaytweak && !bodyPaytweak.isEmpty()){
            // Paytweak
            System.debug('**** IMA CDN bodyPaytweak  L78 == ' + bodyPaytweak);
            CV_Intf_WebserviceCalloutPAYTWEAK wsPAYTWEAKCallout = new CV_Intf_WebserviceCalloutPAYTWEAK();  
            wsPAYTWEAKCallout.sendStructuresToPaytweak(bodyPaytweak);
        } else if (!bodyRequestMapList.isEmpty()){
            // Crédit du Nord
            System.debug('**** IMA CDN bodyRequestMapList CDN L77 == ' + bodyRequestMapList);
            CV_Intf_WebserviceCalloutCDN wsCDNCallout = new CV_Intf_WebserviceCalloutCDN();
            wsCDNCallout.sendStructuresToCDN(bodyRequestMapList);
        }
    }

    public static void generatePaymentOrderIds(List<blng__Invoice__c> invoices, Boolean isPaytweak) {
        // Init Vars 
        String paytweakPayload;
        CV_Intf_CreditDuNordSchemaBuilder.PaymentOrder bodyPayload;
        List<Object> bodyRequestMapList = new List<Object>();
        List<String> bodyPaytweak = new List<String>();
        
        if(!isPaytweak){
            // Crédit du Nord
            CV_Intf_Service.loadMDWTransformationsMap(INTERFACE_CDN);
            List<Intf_Sync_Field__mdt> syncFields = CV_Intf_Service.getActiveSyncFields(TARGET_SYSTEM_CDN);
            system.debug('*** IMA CDN syncFields in CV_BankPaymentOrderService L105 == ' + syncFields);
        } else {
            // Paytweak
            CV_Intf_Service.loadMDWTransformationsMap(INTERFACE_PAYTWEAK);
            List<Intf_Sync_Field__mdt> syncFieldsPaytweak = CV_Intf_Service.getActiveSyncFields(TARGET_SYSTEM_PAYTWEAK);
            system.debug('*** IMA Paytweak syncFieldsPaytweak in CV_BankPaymentOrderService L110 == ' + syncFieldsPaytweak);
        }
        
        // Loop on invoice list to assign correct format for each record
        for (blng__Invoice__c invoice : invoices) {
            if(isPaytweak){
                // PAYTWEAK
                paytweakPayload = CV_Intf_PaytweakSchemaBuilder.getInvoicePayload(invoice, false);
                System.debug('======================= CV_GenerateBankPaymentOrderService generatePaymentOrderIds paytweakPayload: ' + paytweakPayload);
                bodyPaytweak.add(paytweakPayload);
                System.debug('**** IMA bodyPaytweak list == '+bodyPaytweak);
            } else {
                // CREDIT DU NORD
                bodyPayload  = new CV_Intf_CreditDuNordSchemaBuilder.PaymentOrder(invoice, false);
                System.debug('======================= CV_GenerateBankPaymentOrderService generatePaymentOrderIds bodyPayload: ' + bodyPayload);
                bodyRequestMapList.add(bodyPayload);
                System.debug('**** IMA CDN bodyRequestMapList L98 == ' + bodyRequestMapList);
            }
        }
        
        
        
        if(isPaytweak){
            // PAYTWEAK
            CV_Intf_WebserviceCalloutPAYTWEAK.isPaymentCheck = false;
            CV_Intf_WebserviceCalloutPAYTWEAK wsPKCallout = new CV_Intf_WebserviceCalloutPAYTWEAK();
            if(!bodyPaytweak.isEmpty()){
                wsPKCallout.sendStructuresToPaytweak(bodyPaytweak);
            }
        } else {
            //Credit du nord
            CV_Intf_WebserviceCalloutCDN.isPaymentCheck = false;
            CV_Intf_WebserviceCalloutCDN wsCDNCallout = new CV_Intf_WebserviceCalloutCDN();
            if(!bodyRequestMapList.isEmpty()){
                wsCDNCallout.sendStructuresToCDN(bodyRequestMapList);
            }
        }
       
    }   

}