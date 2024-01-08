/**
 * @description       : Class de service pour les appels vers ECV
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 21-06-2022
 * @last modified by  : Michaël Cabaraux
**/

public with sharing class CV_InvoiceECVSendingService {

    private static final String TARGET_SYSTEM_ECV = 'ECV';
    private static final String INTERFACE_ECV = 'Invoice';
    private static final String DOCUMENT_PAID = 'PAYE';

    @InvocableMethod(label='CV_SendInvoicesToECV' description='Envoi des factures à ECV')
    public static void sendInvoiceToECV(List<Request> requestList) {

        if (System.isBatch() || System.isFuture()) {
            // Discard sending if not coming from manual trigger invoke
            return;
        }

        System.debug('=============================================== CV_SendInvoicesToECV requestList: ' + requestList);

        Set<Id> invoiceIds = new Set<ID>();
        for (Request request : requestList) {
            invoiceIds.add(request.invoiceId);
        }

        System.debug('=============================================== CV_SendInvoicesToECV invoiceIds: ' + invoiceIds);
        if (invoiceIds.isEmpty()) { return; }

        String query = getSelectionQuery(false, true);
        query += ' WHERE Id in :invoiceIds';

        List<blng__Invoice__c> invoicesToSend = Database.query(query);

        Map<Id, blng__Invoice__c> invoicesByIds = new Map<Id, blng__Invoice__c>();
        for (blng__Invoice__c invoice : invoicesToSend) {
            invoicesByIds.put(invoice.Id, invoice);
        }

        Map<Id, ContentVersion> contentVersionsByEntityIds = CV_PDFManagementService.getPDFsByInvoiceIds(invoiceIds, invoicesByIds, false);
        List<blng__Invoice__c> invoicesWithNoPaidDoc = new List<blng__Invoice__c>();

        for (String invoiceId : invoiceIds) {
            ContentVersion contentVersion = contentVersionsByEntityIds.get(invoiceId);

            if (contentVersion == null || !contentVersion.Title.contains(DOCUMENT_PAID)) {
                invoicesWithNoPaidDoc.add(invoicesByIds.get(invoiceId));
            }
        }
        System.debug('=============================================== CV_SendInvoicesToECV sendInvoicesToECVFromFlow invoicesWithNoPaidDoc: ' + invoicesWithNoPaidDoc);

        if (!invoicesWithNoPaidDoc.isEmpty()) {
            List<blng__Invoice__c> invoicesToUpdate = CV_PDFManagementService.generatePDFDocuments(invoicesWithNoPaidDoc);

            System.debug('================================ CV_SendInvoicesToECV sendInvoicesToECVFromFlow invoicesToUpdate: ' + invoicesToUpdate);
            if (!invoicesToUpdate.isEmpty()) {
                update invoicesToUpdate;
            }
        }

        sendInvoicesToECVFromFlow(invoiceIds);
    }

    public static String getSelectionQuery(Boolean resendErrors, Boolean fromFlow) {

        String query = 'SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('blng__Invoice__c').getDescribe().fields.getMap().keySet()), ',') + ' ';
        query += ' ,blng__Order__r.Email_Patient__c, blng__Order__r.Lib_Espece_Patient__c, blng__Account__r.Code_compte_metier__c, blng__Order__r.IDDossier__c';
        query += ',blng__Order__r.Animal_Owner_Name__c,blng__Order__r.Animal_Name__c, blng__Order__r.Numero__c';
        query += ' FROM blng__Invoice__c';

        if (!fromFlow) {
            if (resendErrors) {
                query += ' WHERE Statut_Integration_ECV__c in (\'A Envoyer\', \'Erreur\')';
            } else {
                query += ' WHERE Statut_Integration_ECV__c = \'A Envoyer\'';
            }
        }

        return query;

    }

    @Future (callout=true)
    public static void sendInvoicesToECVFromFlow(Set<Id> invoiceIds) {

        String query = getSelectionQuery(false, true);
        query += ' WHERE Id in :invoiceIds';

        List<blng__Invoice__c> invoicesToSend = Database.query(query);

        sendInvoicesToECV(invoicesToSend, false);

    }

    public static void sendInvoicesToECV(List<blng__Invoice__c> invoices, Boolean isECVBatch) {

        Set<Id> invoiceIds = new Set<Id>();
//        Set<Id> monthlyInvoiceIds = new Set<Id>();
        Map<Id, blng__Invoice__c> invoicesByIds = new Map<Id, blng__Invoice__c>();

        CV_Intf_Service.loadMDWTransformationsMap(INTERFACE_ECV);
        List<Intf_Sync_Field__mdt> syncFields = CV_Intf_Service.getActiveSyncFields(TARGET_SYSTEM_ECV);

        for (blng__Invoice__c invoice : invoices) {
            invoiceIds.add(invoice.Id);
            invoicesByIds.put(invoice.Id, invoice);

//            if (!invoice.Facture_Proprio__c) {
//                monthlyInvoiceIds.add(invoice.Id);
//            }
        }

//        Map<Id, List<String>> dossierIdsByInvoiceIds = CV_InvoiceECVSendingService.getDossierIdsByInvoiceIds(monthlyInvoiceIds);
//        System.debug('============================ CV_InvoiceECVSendingBatch DossierIdsByInvoiceIds: ' + DossierIdsByInvoiceIds);

        Map<Id, ContentVersion> contentVersionsByEntityIds = CV_PDFManagementService.getPDFsByInvoiceIds(invoiceIds, invoicesByIds, isECVBatch);
        System.debug('============================ CV_InvoiceECVSendingBatch contentVersionsByEntityIds: ' + contentVersionsByEntityIds);

        List<Object> bodyRequestMapListProprio = new List<Object>();
//        List<CV_Intf_InvoiceSchemaBuilder> bodyRequestMapListClinic = new List<CV_Intf_InvoiceSchemaBuilder>();
        CV_Intf_InvoiceSchemaBuilder bodyPayload;

        for (blng__Invoice__c invoice : invoices) {
//            if (!invoice.Facture_Proprio__c) {
//                for (String dossierId : dossierIdsByInvoiceIds.get(invoice.Id)) {
//                    bodyPayload  = new CV_Intf_InvoiceSchemaBuilder(invoice, contentVersionsByEntityIds.get(invoice.Id), dossierId, false);
////                    System.debug('======================= CV_InvoiceECVSendingService clinic bodyPayload: ' + bodyPayload);
//                    bodyRequestMapListClinic.add(bodyPayload);
//                }
//            } else {
//                bodyPayload  = new CV_Intf_InvoiceSchemaBuilder(invoice, contentVersionsByEntityIds.get(invoice.Id), null, true);
////                System.debug('======================= CV_InvoiceECVSendingService proprio bodyPayload: ' + bodyPayload);
//                bodyRequestMapListProprio.add(bodyPayload);
//            }
            bodyPayload  = new CV_Intf_InvoiceSchemaBuilder(invoice, contentVersionsByEntityIds.get(invoice.Id), null, invoice.Facture_Proprio__c);
            bodyRequestMapListProprio.add(bodyPayload);
        }

        System.debug('======================= CV_InvoiceECVSendingService bodyRequestMapListProprio #: ' + bodyRequestMapListProprio.size());
        if (!bodyRequestMapListProprio.isEmpty()) {
            CV_Intf_WebserviceCalloutECV wsECVCallout = new CV_Intf_WebserviceCalloutECV();
            wsECVCallout.sendStructuresToECV(bodyRequestMapListProprio);
        }

//        System.debug('======================= CV_InvoiceECVSendingService bodyRequestMapListClinic #: ' + bodyRequestMapListClinic.size());
//        if (!bodyRequestMapListClinic.isEmpty()) {
//            System.enqueueJob(new CV_InvoiceECVQueue(bodyRequestMapListClinic));
//        }

    }




//    public static Map<Id, List<String>> getDossierIdsByInvoiceIds(Set<Id> invoiceIds) {
//
//        Map<Id, List<String>> dossierIdsByInvoiceIds = new Map<Id, List<String>>();
//
//        for (blng__InvoiceLine__c invoiceLine : [
//                SELECT Id, Numero_de_Dossier__c, blng__Invoice__c
//                FROM blng__InvoiceLine__c
//                WHERE blng__Invoice__c in :invoiceIds
//                ORDER BY blng__Invoice__c
//        ]) {
//
//            if (!dossierIdsByInvoiceIds.containsKey(invoiceLine.blng__Invoice__c)) {
//                dossierIdsByInvoiceIds.put(invoiceLine.blng__Invoice__c, new List<String>());
//            }
//
//            List<String> dossierIds = dossierIdsByInvoiceIds.get(invoiceLine.blng__Invoice__c);
//
//            if (!dossierIds.contains(invoiceLine.Numero_de_Dossier__c)) {
//                dossierIds.add(invoiceLine.Numero_de_Dossier__c);
//            }
//        }
//
//        System.debug('========================== CV_InvoiceECVSendingService getDossierIdsByInvoiceIds dossierIdsByInvoiceIds: ' + dossierIdsByInvoiceIds);
//
//        return dossierIdsByInvoiceIds;
//    }



    public class Request {
        @InvocableVariable(label='Invoice Ids' description='Facturer à envoyer à ECV')
        public String invoiceId;
    }
}