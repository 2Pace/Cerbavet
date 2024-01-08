/**
 * Created by Michael on 09-11-23.
 */

public with sharing class InvoiceRunTriggerHandler {

    public static void calculateInvoiceNumber(Map<Id, blng__InvoiceRun__c> invoiceRunMap, Map<Id, blng__InvoiceRun__c> oldInvoiceRunMap) {

        Set<Id> invoiceRunIds = new Set<Id>();
        Map<Id, Integer> invoiceIndexInvoiceRunIds = new Map<Id, Integer>();

        for (Id id : invoiceRunMap.keySet()) {
            blng__InvoiceRun__c invoiceRun = invoiceRunMap.get(id);
            blng__InvoiceRun__c oldInvoiceRun = oldInvoiceRunMap.get(id);

            if ((invoiceRun.blng__Status__c == 'Completed' || invoiceRun.blng__Status__c == 'Completed with errors') && oldInvoiceRun.blng__Status__c != invoiceRun.blng__Status__c) {
                invoiceRunIds.add(id);
                invoiceIndexInvoiceRunIds.put(id, 0);
            }
        }

        List<blng__Invoice__c> invoicesToUpdate = new List<blng__Invoice__c>();
        Date currentDate = Date.today();
        String currentDateFormatted = '' + currentDate.year() + String.valueOf(currentDate.month()).leftPad(2, '0') + String.valueOf(currentDate.day()).leftPad(2, '0');

        for (blng__Invoice__c invoice : [
                SELECT Id, blng__InvoiceRunCreatedBy__r.Name, blng__InvoiceRunCreatedBy__c, Numero_Facturation_Cerbavet__c
                FROM blng__Invoice__c
                WHERE blng__InvoiceRunCreatedBy__c in :invoiceRunIds
        ]) {

            String invoiceType = CV_InvoiceService.getInvoiceType(invoice.blng__InvoiceRunCreatedBy__r.Name);
            System.debug('============================ InvoiceTriggerHandler CalculateInvoiceNumber invoiceType ' + invoiceType);

            Integer tmpIndex = invoiceIndexInvoiceRunIds.get(invoice.blng__InvoiceRunCreatedBy__c) + 1;

            if (invoiceType != 'Inconnu') {

                invoice.Numero_Facturation_Cerbavet__c = CV_InvoiceService.INVOICEPREFIX_BY_TYPES.get(invoiceType) + '-' + currentDateFormatted + '-' + String.valueOf(tmpIndex).leftPad(4, '0');
                invoiceIndexInvoiceRunIds.put(invoice.blng__InvoiceRunCreatedBy__c, tmpIndex);

                System.debug('============================ InvoiceTriggerHandler CalculateInvoiceNumber Invoice Number ' + invoice.Numero_Facturation_Cerbavet__c);

                invoicesToUpdate.add(invoice);
            }
        }

        if (!invoicesToUpdate.isEmpty()) {
            SBQQ.TriggerControl.disable();
            update invoicesToUpdate;
            SBQQ.TriggerControl.enable();
        }
    }
}