/**
 * @description       : Batch pour générer les ordres de paiements de Paytweak
 * @author            : Ingrid OMAR
 * @group             :
 * @last modified on  : 02-01-2024
 * @last modified by  : Ingrid OMAR
**/

global class CV_GenerateBankPaymentOrderBatchPAYTWEAK implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    private static final String CONFIGURATION_NAME = 'Payment_Order_Batch';

    private CV_Batch_Settings__mdt batchSettings;


    global Database.querylocator start(Database.BatchableContext bc) {

        this.batchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c, Default_Sender_Address_Id__c,
                        Email_Template_Id__c, Paid_Email_Template_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];

        String query = CV_BankPaymentOrderService.getSelectionQuery(false,true);

        System.debug('============================ CV_GenerateBankPaymentOrderBatchPAYTWEAK start query : ' + query);

        Database.QueryLocator queryLocator = Database.getQueryLocator(query);

        return queryLocator;
    }


    global void execute(Database.BatchableContext bc, List<blng__Invoice__c> invoices) {

        //Send 50 per 50 --> 100 callout per transaction
        System.debug('Send 50 per 50 --> 100 callout per transaction' + invoices);
        CV_BankPaymentOrderService.generatePaymentOrderIds(invoices, true);

    }

    global void finish(Database.BatchableContext bc) {

        System.debug('============================ CV_GenerateBankPaymentOrderBatchPAYTWEAK FINISHED');

    }


    global void execute(SchedulableContext sc) {

        CV_Batch_Settings__mdt BatchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];


        CV_GenerateBankPaymentOrderBatchPAYTWEAK batch = new CV_GenerateBankPaymentOrderBatchPAYTWEAK();
        Database.executeBatch(batch,Integer.valueOf(batchSettings.Batch_Scope_Size__c));

    }


    global static String scheduleThis(String schedule) {

        CV_GenerateBankPaymentOrderBatchPAYTWEAK job = new CV_GenerateBankPaymentOrderBatchPAYTWEAK();
        String batchName = 'CV_GenerateBankPaymentOrderBatchPAYTWEAK - ' + DateTime.now().format('YYYYMMDDHHmmss');
        String jobId = System.schedule(batchName, schedule, job);
        return jobId;

    }
}