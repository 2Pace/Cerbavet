/**
 * @description       : Batch permettant l'envoi des factures à ECV'
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 16-06-2022
 * @last modified by  : Michaël Cabaraux
**/


global class CV_InvoiceECVSendingBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Schedulable {

    private static final String CONFIGURATION_NAME = 'Invoice_ECV_Sender';
    private static final String TARGET_SYSTEM_ECV = 'ECV';
    private static final String INTERFACE_ECV = 'Invoice';

    private CV_Batch_Settings__mdt batchSettings;
    private Boolean resendErrors;

    public CV_InvoiceECVSendingBatch(Boolean resendErrors) {
        this.resendErrors = resendErrors;

    }

    global Database.querylocator start(Database.BatchableContext bc) {

        this.batchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c, Default_Sender_Address_Id__c,
                        Email_Template_Id__c, Paid_Email_Template_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];

        String query = CV_InvoiceECVSendingService.getSelectionQuery(resendErrors, false);

//        query += ' AND id in (\'a3Z1j000000qEreEAE\')';

        System.debug('============================ CV_InvoiceECVSendingBatch start query : ' + query);

        Database.QueryLocator queryLocator = Database.getQueryLocator(query);

        return queryLocator;
    }


    global void execute(Database.BatchableContext bc, List<blng__Invoice__c> invoices) {

        //Send 50 per 50 --> 100 callout per transaction

        CV_InvoiceECVSendingService.sendInvoicesToECV(invoices, true);

    }

    global void finish(Database.BatchableContext bc) {

        System.debug('============================ CV_InvoiceECVSendingBatch FINISHED');

    }


    global void execute(SchedulableContext sc) {

        CV_Batch_Settings__mdt BatchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];


        CV_InvoiceECVSendingBatch batch = new CV_InvoiceECVSendingBatch(false);
        Database.executeBatch(batch,Integer.valueOf(batchSettings.Batch_Scope_Size__c));

    }


    global static String scheduleThis(String schedule) {

        CV_InvoiceECVSendingBatch job = new CV_InvoiceECVSendingBatch(false);
        String batchName = 'CV_InvoiceECVSendingBatch - ' + DateTime.now().format('YYYYMMDDHHmmss');
        String jobId = System.schedule(batchName, schedule, job);
        return jobId;

    }

}