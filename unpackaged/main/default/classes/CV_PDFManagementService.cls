/**
 * @description       : Classe de service autour des PDFs de facture
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 19-06-2022
 * @last modified by  : Michaël Cabaraux
**/

public with sharing class CV_PDFManagementService {

    private static final String DOCUMENT_PAID = 'PAYE';
    private static final String INVOICE_STATUS_PAID = 'Paid';

    public static Map<Id, ContentVersion> getPDFsByInvoiceIds(Set<Id> invoiceIds, Map<Id, blng__Invoice__c> invoicesByIds, Boolean isECVBatch) {

        return getPDFsByInvoiceIds(invoiceIds, invoicesByIds, isECVBatch, false);
    }

    public static Map<Id, ContentVersion> getPDFsByInvoiceIds(Set<Id> invoiceIds, Map<Id, blng__Invoice__c> invoicesByIds, Boolean isECVBatch, Boolean isClinic) {

        Map<Id, ContentVersion> contentVersionsByEntityIds = new Map<Id, ContentVersion>();
        Map<Id, Id> entityIdsByDocumentLinkIds = new Map<Id, Id>();

        for (ContentDocumentLink documentLink :[SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in :invoiceIds]) {
            entityIdsByDocumentLinkIds.put(documentLink.ContentDocumentId, documentLink.LinkedEntityId);
        }
        System.debug('============================ CV_PDFManagementService getPDFsByInvoiceIds entityIdsByDocumentLinkIds: ' + entityIdsByDocumentLinkIds);

        if (!entityIdsByDocumentLinkIds.isEmpty()) {
            for (ContentVersion contentVersion : [
                    SELECT Id, PathOnClient, FileType, Title, VersionData, ContentDocumentId
                    FROM ContentVersion
                    WHERE ContentDocumentId in :entityIdsByDocumentLinkIds.keySet()
                    AND IsLatest = true
                    AND FileType = 'PDF']) {

                blng__Invoice__c invoiceToTreat = invoicesByIds.get(entityIdsByDocumentLinkIds.get(contentVersion.ContentDocumentId));

                if (!isClinic && (!isECVBatch && invoiceToTreat.Document_Facture_Acquittee__c && !invoiceToTreat.Document_Facture_Acquittee_Envoye__c && invoiceToTreat.blng__PaymentStatus__c == 'Paid')
                        || (isECVBatch && invoiceToTreat.Document_Facture_Acquittee__c && invoiceToTreat.blng__PaymentStatus__c == 'Paid')) {
                    if (contentVersion.Title.contains(DOCUMENT_PAID)) {
                        contentVersionsByEntityIds.put(invoiceToTreat.Id, contentVersion);
                    }

                } else if ((!isECVBatch && invoiceToTreat.Document_genere__c && !invoiceToTreat.Document_envoye__c && !invoiceToTreat.Document_Facture_Acquittee_Envoye__c)
                        || (isECVBatch && invoiceToTreat.Document_genere__c)) {
                    if (!contentVersion.Title.contains(DOCUMENT_PAID)) {
                        contentVersionsByEntityIds.put(invoiceToTreat.Id, contentVersion);
                    }
                }
            }
        }


        System.debug('============================ CV_PDFManagementService getPDFsByInvoiceIds contentVersionsByEntityIds: ' + contentVersionsByEntityIds);

        return contentVersionsByEntityIds;
    }

    public static List<blng__Invoice__c> generatePDFDocuments(List<blng__Invoice__c> invoices) {

        Blob strPdfBody = null;

        List<blng__Invoice__c> invoicesToUpdate = new List<blng__Invoice__c>();

        for (blng__Invoice__c invoice : invoices) {

            String invoiceNameSuffix = INVOICE_STATUS_PAID.equalsIgnoreCase(invoice.blng__PaymentStatus__c) ? '_PAYE' : '';
//            String invoiceName = invoice.Numero_Facture_Cerba__c + invoiceNameSuffix;
            String invoiceName = invoice.Numero_Facturation_Cerbavet__c + invoiceNameSuffix;

            try {

//                PageReference objPagePdf = Page.InvoiceTemplateMain;
                PageReference objPagePdf = Page.InvoiceTemplateMain2PACE;
                objPagePdf.getParameters().put('id', invoice.Id);

                if(Test.isRunningTest()) {
                    strPdfBody = blob.valueOf('Unit.Test');
                } else {
                    strPdfBody =  objPagePdf.getContent();
                }

                ContentVersion objVersion = new ContentVersion();
                objVersion.ContentLocation = 'S';
                objVersion.PathOnClient = invoiceName +'.pdf';
                objVersion.Title = invoiceName;
                objVersion.VersionData = strPdfBody;
                insert objVersion;

                Id objDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:objVersion.Id].ContentDocumentId;
                ContentDocumentLink objDocumentLink = New ContentDocumentLink();
                objDocumentLink.LinkedEntityId = invoice.Id;
                objDocumentLink.ContentDocumentId = objDocId;
                objDocumentLink.shareType = 'V';
                insert objDocumentLink;

                blng__Invoice__c invoiceToUpate = new blng__Invoice__c(Id = invoice.Id);

                if (INVOICE_STATUS_PAID.equalsIgnoreCase(invoice.blng__PaymentStatus__c)) {
                    invoiceToUpate.Document_Facture_Acquittee__c = true;
                } else {
                    invoiceToUpate.Document_genere__c = true;
                }
                invoiceToUpate.Statut_Integration_ECV__c = 'A Envoyer';
                invoicesToUpdate.add(invoiceToUpate);

            } catch (Exception e) {
                System.debug('================================ CV_PDFManagementService generatePDFDocuments ERREUR: ' + e.getMessage());

                invoicesToUpdate.add(new blng__Invoice__c(Id = invoice.Id, Message_d_erreur__c = e.getMessage()));

            }
        }

        System.debug('================================ CV_PDFManagementService generatePDFDocuments invoicesToUpdate: ' + invoicesToUpdate);
        return invoicesToUpdate;

    }


}