/**
 * @description       : Batch de Génération des PDFs de la facture'
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 31-05-2022
 * @last modified by  : Michaël Cabaraux
**/

global class CV_InvoicePDFCreatorBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    private static final String CONFIGURATION_NAME = 'Invoice_PDF_Creator';

    private static final String INVOICE_STATUS_PAID = 'Paid';
//    private static final Integer DEFAULT_BATCH_SIZE = 20;

    private Boolean isMonthly;
    private string additionnalWhereClause = '';

    public CV_InvoicePDFCreatorBatch (Boolean isMonthlyBatchRun) {

        this.isMonthly = isMonthlyBatchRun;

        if (isMonthlyBatchRun) {
            additionnalWhereClause = 'AND Facture_Proprio__c = false';

        } else {
            additionnalWhereClause = 'AND Facture_Proprio__c = true';
        }
    }

    global Database.querylocator start(Database.BatchableContext bc) {


        String query = 'SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('blng__Invoice__c').getDescribe().fields.getMap().keySet()), ',') + ' ';
        query += ' FROM blng__Invoice__c';
        query += ' WHERE ((Document_genere__c = false AND blng__PaymentStatus__c <> :INVOICE_STATUS_PAID) OR (Document_Facture_Acquittee__c = false AND blng__PaymentStatus__c = :INVOICE_STATUS_PAID))';
        query += ' AND blng__InvoiceStatus__c = \'Posted\'';
        query += additionnalWhereClause;
//        query += ' LIMIT 25';
//        query += ' AND Id = \'a3Y0D000000ctD4UAI\'';

        System.debug('============================ CV_InvoicePDFCreatorBatch start query : ' + query);

        Database.QueryLocator queryLocator = Database.getQueryLocator(query);

        return queryLocator;
    }

    global void execute(Database.BatchableContext bc, List<blng__Invoice__c> invoices) {

        List<blng__Invoice__c> invoicesToUpdate = CV_PDFManagementService.generatePDFDocuments(invoices);

        System.debug('================================ CV_InvoicePDFCreatorBatch invoicesToUpdate: ' + invoicesToUpdate);
        if (!invoicesToUpdate.isEmpty()) {
            update invoicesToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {

        System.debug('================================ CV_InvoicePDFCreatorBatch BATCH FINISHED');
    }

    global void execute(SchedulableContext sc) {

        System.debug('================================ CV_InvoicePDFCreatorBatch Schedulable Execute isMonthly: ' + isMonthly);

        CV_Batch_Settings__mdt BatchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];


        CV_InvoicePDFCreatorBatch batch = new CV_InvoicePDFCreatorBatch(isMonthly);
        Database.executeBatch(batch,Integer.valueOf(batchSettings.Batch_Scope_Size__c));

    }

    global static String scheduleThis(String schedule, Boolean isMonthly) {

        CV_InvoicePDFCreatorBatch job = new CV_InvoicePDFCreatorBatch(isMonthly);
        String batchName = 'CV_InvoicePDFCreatorBatch - ' + DateTime.now().format('YYYYMMDDHHmmss');
        String jobId = System.schedule(batchName, schedule, job);
        return jobId;
    }

}