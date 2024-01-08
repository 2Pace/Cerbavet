/**
 * Created by Michael on 20-07-22.
 */

public with sharing class InvoiceTriggerHandler {

//    private static final Map<String, String> INVOICEPREFIX_BY_TYPES = new Map<String, String> {
//            'Cerbavet' => 'FACCV',
//            'Cerbavet Suisse' => 'FACCH',
//            'Cerbavet College' => 'FACCC'
//    };


    public static void calculateInvoiceNumber(List<blng__Invoice__c> invoices) {


        Set<Id> invoiceRunIds = new Set<Id>();
        for (blng__Invoice__c invoice : invoices) {
            invoiceRunIds.add(invoice.blng__InvoiceRunCreatedBy__c);
        }

        Map<Id, blng__InvoiceRun__c> invoiceRunMap = new Map<Id, blng__InvoiceRun__c>([SELECT Id, Name FROM blng__InvoiceRun__c WHERE Id in :invoiceRunIds]);

        Map<String, Integer> invoiceIndexByRunNames = new Map<String, Integer>();
//        List<blng__Invoice__c> invoicesProprio = new List<blng__Invoice__c>();

        for (AggregateResult aggregateResult : [
                SELECT count(id) index, blng__InvoiceRunCreatedBy__r.Name
                FROM blng__Invoice__c
                WHERE CreatedDate = TODAY Group By blng__InvoiceRunCreatedBy__r.Name]) {

            String runName = (String)aggregateResult.get('Name');
            Integer index = (Integer)aggregateResult.get('index');

            invoiceIndexByRunNames.put(CV_InvoiceService.getInvoiceType(runName), index);

        }
        System.debug('============================ InvoiceTriggerHandler CalculateInvoiceNumber invoiceIndexByRunNames ' + invoiceIndexByRunNames);

        Date currentDate = Date.today();
        String currentDateFormatted = '' + currentDate.year() + String.valueOf(currentDate.month()).leftPad(2, '0') + String.valueOf(currentDate.day()).leftPad(2, '0');

        for (blng__Invoice__c invoice : invoices) {
            if (invoiceRunMap.containsKey(invoice.blng__InvoiceRunCreatedBy__c)) {

                String runName = invoiceRunMap.get(invoice.blng__InvoiceRunCreatedBy__c).Name;
                String invoiceType = CV_InvoiceService.getInvoiceType(runName);
                System.debug('============================ InvoiceTriggerHandler CalculateInvoiceNumber invoiceType ' + invoiceType);

                if (!invoiceIndexByRunNames.containsKey(invoiceType)) {
                    invoiceIndexByRunNames.put(invoiceType, 0);
                }

                Integer tmpIndex = invoiceIndexByRunNames.get(invoiceType) + 1;

                if (invoiceType != 'Inconnu') {

                    invoice.Numero_Facturation_Cerbavet__c = CV_InvoiceService.INVOICEPREFIX_BY_TYPES.get(invoiceType) + '-' + currentDateFormatted + '-' + String.valueOf(tmpIndex).leftPad(4, '0');
                    invoiceIndexByRunNames.put(invoiceType, tmpIndex);

                    System.debug('============================ InvoiceTriggerHandler CalculateInvoiceNumber Invoice Number ' + invoice.Numero_Facturation_Cerbavet__c);

                }

            }
        }

    }

//    private static String getInvoiceType(String runName) {
//
//        String invoiceType = 'Inconnu';
//
//        switch on runName {
//            when 'Cerbavet Clinics Monthly', 'Cerbavet Proprio', 'Cerbavet Proprio2', 'Cerbavet Clinics Monthly Adhoc' {
//                invoiceType = 'Cerbavet';
//            }
//
//            when 'Cerbavet Clinics Monthly Suisse', 'Cerbavet Proprio Suisse', 'Cerbavet Clinics Monthly Suisse Adhoc', 'Cerbavet Proprio Suisse2' {
//                invoiceType = 'Cerbavet Suisse';
//            }
//            when 'Cerbavet College' {
//                invoiceType = 'Cerbavet College';
//            }
//        }
//
//        return invoiceType;
//
//    }
}