/**
 * @description       : Batch pour générer les ordres de paiements du Crédit du Nord
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 25-06-2022
 * @last modified by  : Michaël Cabaraux
**/

global class CV_GenerateBankPaymentOrderBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    private static final String CONFIGURATION_NAME = 'Payment_Order_Batch';

    private CV_Batch_Settings__mdt batchSettings;


    global Database.querylocator start(Database.BatchableContext bc) {

        this.batchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c, Default_Sender_Address_Id__c,
                        Email_Template_Id__c, Paid_Email_Template_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];

        String query = CV_BankPaymentOrderService.getSelectionQuery(false);

//        query += ' AND id in (\'a3Y0D000000d6LoUAI\')';
//        query += ' LIMIT 1';

        System.debug('============================ CV_GenerateBankPaymentOrderBatch start query : ' + query);

        Database.QueryLocator queryLocator = Database.getQueryLocator(query);

        return queryLocator;
    }


    global void execute(Database.BatchableContext bc, List<blng__Invoice__c> invoices) {

        //Send 50 per 50 --> 100 callout per transaction

        CV_BankPaymentOrderService.generatePaymentOrderIds(invoices);

    }

    global void finish(Database.BatchableContext bc) {

        System.debug('============================ CV_GenerateBankPaymentOrderBatch FINISHED');

    }


    global void execute(SchedulableContext sc) {

        CV_Batch_Settings__mdt BatchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];


        CV_GenerateBankPaymentOrderBatch batch = new CV_GenerateBankPaymentOrderBatch();
        Database.executeBatch(batch,Integer.valueOf(batchSettings.Batch_Scope_Size__c));

    }


    global static String scheduleThis(String schedule) {

        CV_GenerateBankPaymentOrderBatch job = new CV_GenerateBankPaymentOrderBatch();
        String batchName = 'CV_GenerateBankPaymentOrderBatch - ' + DateTime.now().format('YYYYMMDDHHmmss');
        String jobId = System.schedule(batchName, schedule, job);
        return jobId;

    }
}