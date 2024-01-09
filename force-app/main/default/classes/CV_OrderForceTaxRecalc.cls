/**
 * Created by Michael on 24-08-22.
 */

global class CV_OrderForceTaxRecalc implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    private static final String CONFIGURATION_NAME = 'Force_Tax_Recalc';

    private CV_Batch_Settings__mdt batchSettings;

    global Database.querylocator start(Database.BatchableContext bc) {

        this.batchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c, Default_Sender_Address_Id__c,
                        Email_Template_Id__c, Paid_Email_Template_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];

        String query = 'SELECT Id, blng__TaxStatus__c FROM OrderItem WHERE blng__TaxStatus__c = \'Queued\' AND blng__InvoiceRunProcessingStatus__c = \'Pending Billing\'';

        System.debug('============================ CV_OrderForceTaxRecalc start query : ' + query);

        Database.QueryLocator queryLocator = Database.getQueryLocator(query);

        return queryLocator;
    }

    global void execute(Database.BatchableContext bc, List<OrderItem> orderItems) {

        for (OrderItem orderItem : orderItems) {
            orderItem.blng__TaxStatus__c = 'Queued';
        }

        update orderItems;

    }

    global void finish(Database.BatchableContext bc) {

        System.debug('============================ CV_OrderForceTaxRecalc FINISHED');

    }

    global void execute(SchedulableContext sc) {

        CV_Batch_Settings__mdt BatchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];


        CV_OrderForceTaxRecalc batch = new CV_OrderForceTaxRecalc();
        Database.executeBatch(batch,Integer.valueOf(batchSettings.Batch_Scope_Size__c));

    }


    global static String scheduleThis(String schedule) {

        CV_OrderForceTaxRecalc job = new CV_OrderForceTaxRecalc();
        String batchName = 'CV_OrderForceTaxRecalc - ' + DateTime.now().format('YYYYMMDDHHmmss');
        String jobId = System.schedule(batchName, schedule, job);
        return jobId;

    }

}